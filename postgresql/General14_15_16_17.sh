#!/bin/bash

# 定义日志文件
LOG_FILE="/var/log/pg_install_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /var/log

# 函数：记录日志并输出到屏幕
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a $LOG_FILE
}

# 函数：检查命令执行结果
check_result() {
    if [ $? -eq 0 ]; then
        log "SUCCESS: $1"
    else
        log "ERROR: $2"
        exit 1
    fi
}

# 函数：检查PostgreSQL是否正在运行
check_pg_running() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if ps -ef | grep -v 'grep' | grep 'postgres' > /dev/null; then
            log "PostgreSQL进程已启动"
            return 0
        fi
        
        log "等待PostgreSQL启动... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "ERROR: PostgreSQL进程未找到，启动可能失败"
    return 1
}

# 函数：检查PostgreSQL是否接受连接
check_pg_ready() {
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        # 使用pg_isready检查PostgreSQL是否准备好接受连接
        su - postgres -c "$PGHOME/bin/pg_isready -h 127.0.0.1 -p $PORT -d postgres" > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            log "PostgreSQL已准备好接受连接"
            return 0
        fi
        
        log "等待PostgreSQL准备就绪... ($attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log "ERROR: PostgreSQL未准备好接受连接"
    return 1
}

log "开始PG数据库安装"
log "安装日志文件: $LOG_FILE"

dir=$(pwd)
log "当前目录: $dir"

# 定义变量
BASEPATH=/pgdb
FILE_CONF=/pgdb/data/postgresql.conf
HBA_CONF=/pgdb/data/pg_hba.conf
PGDATA=/pgdb/data
PGHOME=/pgdb/pgsql
SCRIPTS_DIR=/pgdb/scripts
LOGPATH=/pgdb/data/log
PORT=5785
PASSWD="Lyh@1011"
cpu=$(cat /proc/cpuinfo | grep 'physical id' | sort | uniq | wc -l)

log "1. 开始系统参数配置"
log "1.1 添加sudo postgres权限"
sed -ri '/^root/a\postgres    ALL=(ALL)       NOPASSWD: ALL' /etc/sudoers
check_result "添加sudo postgres权限" "添加sudo postgres权限失败"

log "1.2 调整系统内核参数"
optimizeSystemConf() {
    conf_exist=$(cat /etc/sysctl.conf | grep postgres | wc -l)
    if [ $conf_exist -eq 0 ]; then
        log "优化系统内核参数"
        sed -ri '/net.ipv4.ip_forward/s#0#1#' /etc/sysctl.conf
        cat >> /etc/sysctl.conf <<EOF
# PostgreSQL优化参数
kernel.sysrq = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_keepalive_intvl =15
net.ipv4.tcp_retries1 = 3
net.ipv4.tcp_retries2 = 5
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_max_tw_buckets = 6000
# net.ipv4.tcp_tw_recycle 已在新内核中移除
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_mem = 94500000 915000000 927000000
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_orphans = 3276800
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_rmem = 4096 87380 4194304
net.ipv4.tcp_wmem = 4096 16384 4194304
net.core.wmem_default = 8388608
net.core.rmem_default = 8388608
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
fs.file-max = 1024000
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.route.gc_timeout = 100
net.core.somaxconn=1024
net.core.netdev_max_backlog = 262144
EOF
        # 应用sysctl配置，但忽略不存在的参数
        sysctl -p 2>/dev/null >> $LOG_FILE 2>&1
        # 检查是否有严重错误
        if [ $? -ne 0 ]; then
            log "WARNING: 部分内核参数可能未应用成功，但继续安装"
        else
            log "系统内核参数优化成功"
        fi
    else
        log "系统内核参数已优化，跳过此步骤"
    fi
}
optimizeSystemConf

log "1.3 调整系统资源限制"
optimizeLimitConf() {
    conf_exist=$(cat /etc/security/limits.conf | grep postgres | wc -l)
    if [ $conf_exist -eq 0 ]; then
        log "优化系统资源限制"
        cat >> /etc/security/limits.conf << "EOF"
# PostgreSQL资源限制
postgres    soft    nproc    16384
postgres    hard    nproc    16384
postgres    soft    nofile    65536
postgres    hard    nofile    65536
postgres    soft    stack    1024000
postgres    hard    stack    1024000
EOF
        check_result "系统资源限制优化" "系统资源限制优化失败"
    else
        log "系统资源限制已优化，跳过此步骤"
    fi
}
optimizeLimitConf

log "1.4 调整SELinux配置"
# 检查SELinux状态，如果已禁用则不执行setenforce命令
SELINUX_STATUS=$(getenforce 2>/dev/null)
if [ "$SELINUX_STATUS" = "Disabled" ]; then
    log "SELinux已禁用，跳过设置"
else
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
    setenforce 0 >> $LOG_FILE 2>&1
    check_result "SELinux配置" "SELinux配置失败"
fi

log "1.5 配置防火墙"
conf_firewall() {
    if [ $(systemctl status firewalld.service | grep -c running) -gt 0 ]; then  
        firewall-cmd --zone=public --add-port=$PORT/tcp --permanent >> $LOG_FILE 2>&1
        firewall-cmd --zone=public --add-port=22/tcp --permanent >> $LOG_FILE 2>&1
        firewall-cmd --reload >> $LOG_FILE 2>&1
        sed -i 's/^AllowZoneDrifting=yes/AllowZoneDrifting=no/' /etc/firewalld/firewalld.conf 
        check_result "防火墙配置" "防火墙配置失败"
    else
        log "防火墙未启用，跳过此步骤"
    fi
}
conf_firewall

log "1.6 配置IPC设置"
sed -i 's/#RemoveIPC=no/RemoveIPC=no/g' /etc/systemd/logind.conf
systemctl daemon-reload >> $LOG_FILE 2>&1
systemctl restart systemd-logind >> $LOG_FILE 2>&1
check_result "IPC配置" "IPC配置失败"

log "1.7 安装相关依赖"
current_dir=$(pwd)
log "当前目录: $current_dir"
target_dir="/soft"
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    log "已创建目录: $target_dir"
fi

if [ -f "$current_dir/deps.tar.gz" ]; then
    mv $current_dir/deps.tar.gz $target_dir >> $LOG_FILE 2>&1
    check_result "移动依赖包" "移动依赖包失败"

    cd /soft
    tar -xvf deps.tar.gz >> $LOG_FILE 2>&1
    check_result "解压依赖包" "解压依赖包失败"

    cd /soft/deps
    rpm -ivh *.rpm --nodeps --force >> $LOG_FILE 2>&1
    check_result "安装RPM依赖包" "安装RPM依赖包失败"
else
    log "WARNING: 未找到deps.tar.gz文件，跳过依赖安装"
fi

log "2. 检查postgres用户"
id postgres >> $LOG_FILE 2>&1
if [ $? -ne 0 ]; then
    log "创建postgres用户"
    groupadd postgres >> $LOG_FILE 2>&1
    useradd -g postgres postgres >> $LOG_FILE 2>&1
    echo "$PASSWD" | passwd --stdin postgres >> $LOG_FILE 2>&1
    sed -ri '/^root/a\postgres ALL=(ALL) ALL' /etc/sudoers >> $LOG_FILE 2>&1
    check_result "创建postgres用户" "创建postgres用户失败"
else
    log "postgres用户已存在，跳过此步骤"
fi

log "3. 创建数据库目录"
if [ ! -d $BASEPATH ]; then
    mkdir -p $BASEPATH/{data,pg_archive,pg_backup,scripts,tmp} >> $LOG_FILE 2>&1
    check_result "创建数据库目录" "创建数据库目录失败"
else
    log "数据库目录已存在，跳过此步骤"
fi

log "4. 解压PostgreSQL安装包"
if ls $dir/postgresql*.tar.gz 1> /dev/null 2>&1; then
    tar -zxf $dir/postgresql*.tar.gz -C $BASEPATH/ >> $LOG_FILE 2>&1
    check_result "解压PostgreSQL安装包" "解压PostgreSQL安装包失败"
else
    log "ERROR: 未找到PostgreSQL安装包"
    exit 1
fi

cd $BASEPATH
mv postgresql-14.12/ pgsql >> $LOG_FILE 2>&1
check_result "重命名目录" "重命名目录失败"

chown -R postgres:postgres $BASEPATH >> $LOG_FILE 2>&1
chmod -R 755 $BASEPATH >> $LOG_FILE 2>&1
check_result "设置目录权限" "设置目录权限失败"

log "5. 编译安装PostgreSQL"
cd $PGHOME
log "开始configure配置"
./configure --prefix=$PGHOME --with-pgport=$PORT --with-openssl --without-perl --with-python --with-blocksize=32 --with-readline --with-libxml --with-libxslt >> $LOG_FILE 2>&1
check_result "configure配置" "configure配置失败"

log "开始make编译"
gmake world -j $cpu >> $LOG_FILE 2>&1
check_result "make编译" "make编译失败"

log "开始make install安装"
gmake install-world -j $cpu >> $LOG_FILE 2>&1
check_result "make install安装" "make install安装失败"

log "6. 配置环境变量"
cd /home/postgres
postgresenvConf() {
    conf_exist=$(cat .bash_profile | grep postgres | wc -l)
    if [ $conf_exist -eq 0 ]; then
        log "配置postgres用户环境变量"
        cp .bash_profile .bash_profile.bak
        sed -i 's/^export PATH/#export PATH/' .bash_profile
        cat >> .bash_profile <<EOF
# PostgreSQL环境变量
export PGHOME=$PGHOME
export PGDATA=$PGDATA
export PGPORT=$PORT
export PGPASSWORD=$PASSWD
export PATH=\$PGHOME/bin:\$PATH
export MANPATH=\$PGHOME/share/man:\$MANPATH
export LD_LIBRARY_PATH=\$PGHOME/lib:\$LD_LIBRARY_PATH
export SCRIPTS_DIR=$SCRIPTS_DIR
export LANG="en_US.UTF-8"
export DATE=\`date +"%Y%m%d%H%M"\`
EOF
        source /home/postgres/.bash_profile >> $LOG_FILE 2>&1
        check_result "配置环境变量" "配置环境变量失败"
    else
        log "环境变量已配置，跳过此步骤"
    fi
}
postgresenvConf

log "7. 初始化数据库"
su - postgres -c "echo \"$PASSWD\" > .pgpass" >> $LOG_FILE 2>&1
su - postgres -c "chmod 0600 /home/postgres/.pgpass" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/initdb --username=postgres --pwfile=/home/postgres/.pgpass -D $PGDATA --encoding=UTF8 --lc-collate=en_US.UTF-8 --lc-ctype=en_US.UTF-8" >> $LOG_FILE 2>&1
check_result "初始化数据库" "初始化数据库失败"

chown -R postgres:postgres $BASEPATH >> $LOG_FILE 2>&1
chmod -R 755 $BASEPATH >> $LOG_FILE 2>&1
chmod -R 700 $PGDATA >> $LOG_FILE 2>&1
check_result "设置数据库目录权限" "设置数据库目录权限失败"

log "配置PostgreSQL参数"
cp $FILE_CONF $PGDATA/postgresql.conf.bak >> $LOG_FILE 2>&1

# 创建conf.d目录（如果不存在）
mkdir -p $PGDATA/conf.d
chown postgres:postgres $PGDATA/conf.d
chmod 755 $PGDATA/conf.d

# 使用更安全的方式配置PostgreSQL参数
# 先备份原始配置文件
cp $FILE_CONF ${FILE_CONF}.original

# 创建一个新的配置文件
cat > $FILE_CONF << EOF
# -----------------------------
# PostgreSQL configuration file
# -----------------------------
# Modified by installation script on $(date)

#------------------------------------------------------------------------------
# FILE LOCATIONS
#------------------------------------------------------------------------------

data_directory = '$PGDATA'
hba_file = '$HBA_CONF'
ident_file = '$PGDATA/pg_ident.conf'
external_pid_file = '$PGDATA/postmaster.pid'

#------------------------------------------------------------------------------
# CONNECTIONS AND AUTHENTICATION
#------------------------------------------------------------------------------

# - Connection Settings -

listen_addresses = '*'
port = $PORT
max_connections = 1000
superuser_reserved_connections = 10
unix_socket_directories = '/tmp'
unix_socket_permissions = 0777
tcp_keepalives_idle = 60
tcp_keepalives_interval = 10
tcp_keepalives_count = 10

# - Authentication -

authentication_timeout = 59s

#------------------------------------------------------------------------------
# RESOURCE USAGE (except WAL)
#------------------------------------------------------------------------------

# - Memory -

shared_buffers = 1024MB
work_mem = 30MB
maintenance_work_mem = 256MB
max_prepared_transactions = 500
temp_buffers = 256MB

# - Disk -

temp_file_limit = -1

#------------------------------------------------------------------------------
# WRITE-AHEAD LOG
#------------------------------------------------------------------------------

wal_level = replica
fsync = on
synchronous_commit = on
wal_sync_method = fsync
full_page_writes = on
wal_log_hints = off
wal_compression = on
wal_buffers = -1
wal_writer_delay = 200ms
wal_writer_flush_after = 1MB
wal_init_zero = on
wal_recycle = on

# - Checkpoints -

checkpoint_timeout = 10min
checkpoint_completion_target = 0.9
checkpoint_flush_after = 256kB
checkpoint_warning = 30s

# - Archiving -

archive_mode = on
archive_command = '/usr/bin/lz4 -q -z %p /pgdb/pg_archive/%f.lz4'

#------------------------------------------------------------------------------
# REPLICATION
#------------------------------------------------------------------------------

max_wal_senders = 10
wal_keep_size = 1024
max_slot_wal_keep_size = -1
wal_sender_timeout = 60s
track_commit_timestamp = off

#------------------------------------------------------------------------------
# QUERY TUNING
#------------------------------------------------------------------------------

# - Planner Cost Constants -

seq_page_cost = 1.0
random_page_cost = 4.0
cpu_tuple_cost = 0.01
cpu_index_tuple_cost = 0.005
cpu_operator_cost = 0.0025
parallel_tuple_cost = 0.1
parallel_setup_cost = 1000.0
min_parallel_table_scan_size = 8MB
min_parallel_index_scan_size = 512kB

# - Other Planner Options -

effective_cache_size = 3GB

#------------------------------------------------------------------------------
# ERROR REPORTING AND LOGGING
#------------------------------------------------------------------------------

# - Where to Log -

log_destination = 'csvlog'
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_file_mode = 0600
log_rotation_age = 1d
log_rotation_size = 100MB

# - When to Log -

log_connections = on
log_disconnections = on
log_error_verbosity = default
log_line_prefix = '%m [%p] '
log_timezone = 'GMT'

# - What to Log -

log_checkpoints = off
log_lock_waits = on
log_statement = 'none'
log_temp_files = -1

#------------------------------------------------------------------------------
# RUNTIME STATISTICS
#------------------------------------------------------------------------------

# - Query and Index Statistics Collector -

track_activities = on
track_counts = on
track_io_timing = off
track_functions = none
track_activity_query_size = 1024

# - Statistics Monitoring -

log_parser_stats = off
log_planner_stats = off
log_executor_stats = off

#------------------------------------------------------------------------------
# AUTOVACUUM PARAMETERS
#------------------------------------------------------------------------------

autovacuum = on
log_autovacuum_min_duration = -1
autovacuum_max_workers = 3
autovacuum_naptime = 1min
autovacuum_vacuum_threshold = 50
autovacuum_analyze_threshold = 50
autovacuum_vacuum_scale_factor = 0.2
autovacuum_analyze_scale_factor = 0.1
autovacuum_freeze_max_age = 200000000
autovacuum_multixact_freeze_max_age = 400000000
autovacuum_vacuum_cost_delay = 2ms
autovacuum_vacuum_cost_limit = -1

#------------------------------------------------------------------------------
# CLIENT CONNECTION DEFAULTS
#------------------------------------------------------------------------------

# - Locale and Formatting -

datestyle = 'iso, mdy'
timezone = 'GMT'
lc_messages = 'en_US.UTF-8'
lc_monetary = 'en_US.UTF-8'
lc_numeric = 'en_US.UTF-8'
lc_time = 'en_US.UTF-8'
default_text_search_config = 'pg_catalog.english'

#------------------------------------------------------------------------------
# LOCK MANAGEMENT
#------------------------------------------------------------------------------

deadlock_timeout = 1s
max_locks_per_transaction = 64

#------------------------------------------------------------------------------
# VERSION AND PLATFORM COMPATIBILITY
#------------------------------------------------------------------------------

# - Previous PostgreSQL Versions -

# - Other Platforms and Clients -

transform_null_equals = off

#------------------------------------------------------------------------------
# ERROR HANDLING
#------------------------------------------------------------------------------

exit_on_error = off
restart_after_crash = on

#------------------------------------------------------------------------------
# CONFIG FILE INCLUDES
#------------------------------------------------------------------------------

# include_dir = 'conf.d'  # 注释掉这一行，避免目录不存在导致启动失败

#------------------------------------------------------------------------------
# CUSTOMIZED OPTIONS
#------------------------------------------------------------------------------

# Add any custom parameters below this line
EOF

check_result "配置PostgreSQL参数" "配置PostgreSQL参数失败"

log "配置pg_hba.conf"
cp $HBA_CONF $PGDATA/pg_hba.conf.bak >> $LOG_FILE 2>&1
cat > $HBA_CONF << EOF
# PostgreSQL Client Authentication Configuration File
# ===================================================
#
# Refer to the "Client Authentication" section in the PostgreSQL
# documentation for a complete description of this file.

# TYPE  DATABASE        USER            ADDRESS                 METHOD

# "local" is for Unix domain socket connections only
local   all             all                                     trust
# IPv4 local connections:
host    all             all             127.0.0.1/32            trust
# IPv6 local connections:
host    all             all             ::1/128                 trust
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     trust
host    replication     all             127.0.0.1/32            trust
host    replication     all             ::1/128                 trust
# Allow all remote connections with password authentication
host    all             all             0.0.0.0/0               md5
EOF

check_result "配置pg_hba.conf" "配置pg_hba.conf失败"

log "8. 配置系统服务"
chmod +x /pgdb/pgsql/contrib/start-scripts/linux
cp /pgdb/pgsql/contrib/start-scripts/linux /etc/init.d/postgresql
# 替换 prefix 参数
sed -i 's/^prefix=.*/prefix=\/pgdb\/pgsql/' /etc/init.d/postgresql
# 替换 PGDATA 参数
sed -i 's/^PGDATA=.*/PGDATA="\/pgdb\/data"/' /etc/init.d/postgresql
systemctl daemon-reload >> $LOG_FILE 2>&1
systemctl start postgresql >> $LOG_FILE 2>&1
check_result "启动PostgreSQL服务" "启动PostgreSQL服务失败"

log "等待PostgreSQL服务完全启动"
check_pg_running
check_pg_ready

log "9. 切换归档日志"
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"select pg_switch_wal();\"" >> $LOG_FILE 2>&1
check_result "切换归档日志" "切换归档日志失败"

log "10. 配置备份脚本"
cat > $SCRIPTS_DIR/pg_backup.sh << EOF
#!/bin/bash
echo  "logical backup"  
PG_HOME=/pgdb
PG_HOST="127.0.0.1"
PG_PORT="5785"
PG_USER="postgres"
PG_PASSWD="123456"
DATE="\`date +%Y%m%d\`"
DIR_BACKUP="\${PG_HOME}/pg_backup"
DIR_LOG="\${DIR_BACKUP}/logs"
FILE_LOG="\${DIR_LOG}/db_backup.INFO.\`date +%F\`.log"
DAY=7
DAY_LOG="\`expr \${DAY} + 7\`"
DATABASES=("postgres" "test")
# 测试目录， 目录不存在则自动创建
test -d \${DIR_LOG} || mkdir -p \${DIR_LOG}
test -d \${DIR_BACKUP}/\${PG_USER}-\${DATE} || mkdir -p \${DIR_BACKUP}/\${PG_USER}-\${DATE}
# -------------------  Start -------------------
echo -e "\n----------------- \$(date +%F\ %T) Start -----------------"
echo -e "\n================= \$(date +%F\ %T) Start =================" >> \${FILE_LOG}
# 遍历数据库名
for database in "\${DATABASES[@]}"; do
    echo "---------- Current backup database: [ \${database} ] ----------"
    echo "----------- Backed-up database: [ \${database} ] -----------" >> \${FILE_LOG}
    # 执行备份命令 -b 包含大对象
    \${PG_HOME}/pgsql/bin/pg_dump -h \${PG_HOST} -p \${PG_PORT} -U \${PG_USER} -w -Fc -d \${database}  -b -f \${DIR_BACKUP}/\${PG_USER}-\${DATE}/db_\${database}_\${DATE}.dmp
done
# 压缩备份文件
cd \${DIR_BACKUP}
tar -czf \${PG_USER}-\${DATE}.tar.gz \${PG_USER}-\${DATE}/
echo "---------- Backup file created: [ \${PG_USER}-\${DATE}.tar.gz ]"
echo "Backup file created: \${DIR_BACKUP}/\${PG_USER}-\${DATE}.tar.gz" >> \${FILE_LOG}
# 压缩后, 删除压缩前的备份文件和目录
rm -f \${DIR_BACKUP}/\${PG_USER}-\${DATE}/*
rmdir \${DIR_BACKUP}/\${PG_USER}-\${DATE}/
# ---------------------------------------------------------------------------------
echo "--------------------- Deleted old files ---------------------" >> \${FILE_LOG}
echo "\`find \${DIR_BACKUP} -type f -mtime +\${DAY} -iname \${PG_USER}-\*.gz\`" >> \${FILE_LOG}
echo "\`find \${DIR_LOG} -type f -mtime +\${DAY_LOG} -iname db_backup.INFO.\*.log\`" >> \${FILE_LOG}
find \${DIR_BACKUP} -type f -mtime +\${DAY} -iname \${PG_USER}-\*.gz -exec rm -f {} \\;
find \${DIR_LOG} -type f -mtime +\${DAY_LOG} -iname db_backup.INFO.\*.log -exec rm -f {} \\;
echo -e "------------------ \$(date +%F\ %T) End ------------------\n"
echo -e "================== \$(date +%F\ %T) End ==================\n" >> \${FILE_LOG}
EOF

chown -R postgres:postgres $SCRIPTS_DIR >> $LOG_FILE 2>&1
chmod +x $SCRIPTS_DIR/*.sh >> $LOG_FILE 2>&1
check_result "配置备份脚本" "配置备份脚本失败"

log "11. 配置定时任务"
if [ ! -e /var/spool/cron/postgres ]; then
    touch /var/spool/cron/postgres
fi

cp /var/spool/cron/postgres /var/spool/cron/postgres.bak 2>/dev/null || true

cat >> /var/spool/cron/postgres << EOF
# PostgreSQL定时任务
30 00 * * * $SCRIPTS_DIR/pg_backup.sh > /dev/null 2>&1
10 00 * * * find /pgdb/data/pg_archive -type f -name "0000000*" -mtime +5 -exec rm {} \; > /pgdb/data/pg_archive/del_pgarchive_\`date +%F\`.log 2>&1
00 01 * * * find /pgdb/data/log -type f -name "postgresql*.log" -mtime +90 -exec rm {} \; > /pgdb/data/log/clean_log_\`date +%F\`.log 2>&1
00 01 * * * find /pgdb/data/log -type f -name "postgresql*.csv" -mtime +90 -exec rm {} \; > /pgdb/data/log/clean_csv_\`date +%F\`.log 2>&1
EOF

check_result "配置定时任务" "配置定时任务失败"

log "12. 创建业务数据库和用户"
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"create user test with superuser encrypted password '123456';\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"create database test owner test;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"grant all privileges on database test to test;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"grant all privileges on all tables in schema public to test;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"alter user postgres with valid until 'infinity';\"" >> $LOG_FILE 2>&1
check_result "创建业务数据库和用户" "创建业务数据库和用户失败"

log "13. 创建只读巡检用户"
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"create user zyjc_read with encrypted password 'postgres';\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"alter user zyjc_read set default_transaction_read_only=on;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"grant usage on schema public to zyjc_read;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"grant select on all tables in schema public to zyjc_read;\"" >> $LOG_FILE 2>&1
su - postgres -c "$PGHOME/bin/psql -d postgres -h 127.0.0.1 -p $PORT -c \"alter default privileges in schema public grant select on tables to zyjc_read;\"" >> $LOG_FILE 2>&1
check_result "创建只读巡检用户" "创建只读巡检用户失败"

log "-----------------------------PostgreSQL安装完成--------------------------------------"
log "数据库信息:"
log "操作系统用户: postgres"
log "操作系统密码: $PASSWD"
log "数据库用户: postgres"
log "数据库密码: $PASSWD"
log "数据库端口: $PORT"
log "安装日志: $LOG_FILE"
log "数据目录: $PGDATA"
log "安装目录: $PGHOME"

exit 0
