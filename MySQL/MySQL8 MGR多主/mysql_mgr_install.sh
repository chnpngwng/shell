#!/bin/bash

echo "-----------------------------开始MYSQL MGR搭建--------------------------------------"
start_time=$(date +%s)
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld
#配置yum源
cd /etc/yum.repos.d/
rm -rf ./*
cat >>/etc/yum.repos.d/centos.repo <<-EOF
[centos]
name=oracle
baseurl=file:///mnt
enabled=1
gpgcheck=0
EOF
cd
mount /dev/sr0 /mnt
yum clean all | wc -l
yum makecache
yum install expect* wget* -y
# Variables
HOSTS=("192.168.59.249" "192.168.59.250" "192.168.59.251")
USER="root"
PASSWORD="123123"
SSH_DIR="/root/.ssh"
# Function to generate SSH key pair on a remote host
generate_ssh_key() {
    local host=$1
    /usr/bin/expect <<EOF
    spawn ssh $USER@$host "mkdir -p $SSH_DIR && chmod 700 $SSH_DIR && \
                           ssh-keygen -t rsa -b 2048 -f $SSH_DIR/id_rsa -q -N ''"
    expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "$PASSWORD\r"; exp_continue }
    }
EOF
}
# Function to copy SSH public key to another host's authorized_keys
copy_ssh_key() {
    local src_host=$1
    local dest_host=$2
    local pub_key_file="/tmp/${src_host}_id_rsa.pub"
    # Fetch public key from source host
    /usr/bin/expect <<EOF
    log_user 0
    spawn ssh $USER@$src_host "cat $SSH_DIR/id_rsa.pub > $pub_key_file"
    expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "$PASSWORD\r"; exp_continue }
    }
    log_user 1
EOF
    # Transfer the public key file from source host to local machine
    /usr/bin/expect <<EOF
    spawn scp $USER@$src_host:$pub_key_file /tmp/
    expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "$PASSWORD\r"; exp_continue }
    }
EOF
    # Append the public key to destination host's authorized_keys
    pub_key=$(cat /tmp/${src_host}_id_rsa.pub)
    /usr/bin/expect <<EOF
    spawn ssh $USER@$dest_host "echo '$pub_key' >> $SSH_DIR/authorized_keys && chmod 600 $SSH_DIR/authorized_keys"
    expect {
      "*yes/no" { send "yes\r"; exp_continue }
      "*password:" { send "$PASSWORD\r"; exp_continue }
    }
EOF
    # Cleanup
    rm -f /tmp/${src_host}_id_rsa.pub
}
# Generate SSH key pairs on all hosts
for host in "${HOSTS[@]}"; do
    echo "Generating SSH key on $host..."
    generate_ssh_key $host
done
# Copy SSH keys to all hosts
for src_host in "${HOSTS[@]}"; do
    for dest_host in "${HOSTS[@]}"; do
        if [ "$src_host" != "$dest_host" ]; then
            echo "Copying SSH key from $src_host to $dest_host..."
            copy_ssh_key $src_host $dest_host
        fi
    done
done
echo "SSH key distribution completed. All hosts should be able to SSH into each other without a password."
hostnamectl set-hostname node1
cat <<EOF >>/etc/hosts
192.168.59.249 node1
192.168.59.250 node2
192.168.59.251 node3
EOF
#ssh 192.168.59.250 "hostnamectl set-hostname node2"
#cat <<EOF >> /etc/hosts
#192.168.59.249 node1
#192.168.59.240 node2
#192.168.59.251 node3
#EOF
#ssh 192.168.59.251
#hostnamectl set-hostname node2
#cat <<EOF >> /etc/hosts
#192.168.59.249 node1
#192.168.59.240 node2
#192.168.59.251 node3
#EOF
#ssh 192.168.59.249
echo "-----------------------------开始MYSQL安装--------------------------------------"
echo -e "\e[31m***************一键安装mysql任何版本数据库******************\e[0m"
find / -name mysql | xargs rm -rf
port=$(ss -anlp | grep mysql | wc -l)
if [ $port != 0 ]; then
    echo "mysql进程存在,请先杀掉进程"
    ps -ef | grep mysqld
    exit 1
fi
echo "-----------------创建所需目录及用户并上传安装包----------------------------"
# 获取当前所在目录位置
current_dir=$(pwd)
echo "当前所在目录位置: $current_dir"
# 目标路径
target_dir="/opt"
# 检查目标路径是否存在，如果不存在则创建
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    echo "已创建目录: $target_dir"
fi
# 移动当前目录下的所有文件到目标路径
mv $current_dir/* $target_dir
echo "已将当前目录下所有文件移动至 $target_dir"
mkdir -p /data/mysql
groupadd mysql
useradd -r -g mysql mysql
cd /opt/
tar -xvf mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.33-linux-glibc2.12-x86_64/ /usr/local/
cd /usr/local/
mv mysql-8.0.33-linux-glibc2.12-x86_64/ mysql
chown -R mysql.mysql /usr/local/mysql/
echo "-----------------------------卸载原有的mysql组件--------------------------"
yum list installed | grep mariadb
yum -y remove mariadb*
chown mysql:mysql -R /data/mysql
touch /etc/my.cnf
chmod 644 /etc/my.cnf
MYSQL_ROOT_PASSWORD=123456
cat <<EOF >/etc/my.cnf
[mysqld]
user=mysql
basedir=/usr/local/mysql
datadir=/data/mysql
socket=/tmp/mysql.sock
log-error=/data/mysql/mysql.err
pid-file=/data/mysql/mysql.pid
character-set-server=utf8
innodb_rollback_on_timeout = ON
collation-server=utf8_general_ci
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
lower_case_table_names=1
max_connections=10000
sync_binlog=1
binlog_format=row
########basic settings########
server-id =249
character_set_server=utf8
max_allowed_packet = 16M
lower_case_table_names=1
slow_query_log=1
slow_query_log_file=/data/mysql/slow.log
########replication settings########
#####replication 复制配置###############
log-bin = /data/mysql/mysql-bin
max_binlog_size=500M
binlog_format = row
sync_binlog=1
expire_logs_days=7
###group replication###########
gtid_mode=on
enforce_gtid_consistency= ON
master_info_repository = TABLE
relay_log_info_repository = TABLE
binlog_checksum = NONE
log_slave_updates = ON
#log_slave_updates是将从服务器从主服务器收到的更新记入到从服务器自己的二进制日志文件中。
transaction_write_set_extraction = XXHASH64
##server必须为每个事物收集写集合，使用XXHASH64哈希算法将其编码为散列
loose-group_replication_group_name ='51837954-2d8a-11ed-bc2d-000c29f511b3'
#组的名字可以随便起,但不能用主机的GTID
loose-group_replication_start_on_boot = off  # #插件在server启动时不自动启动组复制
loose-group_replication_bootstrap_group = off #同上
loose-group_replication_ip_whitelist="192.168.59.249,192.168.59.250,192.168.59.251"
report_host=192.168.59.249
report_port=3306
loose-group_replication_local_address = '192.168.59.249:33061'
loose-group_replication_group_seeds ='192.168.59.249:33061,192.168.59.250:33061,192.168.59.251:33061'
loose-group_replication_single_primary_mode = FALSE #关闭单主模式的参数
loose-group_replication_enforce_update_everywhere_checks = TRUE #开启多主模式的参数
########innodb settings########
innodb_flush_log_at_trx_commit = 1 
innodb_buffer_pool_size=128M
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
secure_file_priv="/tmp"
[mysql]
socket=/tmp/mysql.sock
default-character-set=utf8
[client]
EOF
echo "-----------------------------------初始化数据库-----------------------------------"
cd /usr/local/mysql/bin
./mysqld --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql/ --datadir=/data/mysql/ --user=mysql --initialize
cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql
path=$(grep 'basedir' /etc/profile | wc -l)
if [ $path != 0 ]; then
    echo -e "\e[31m MYSQL_HOME路径存在\e[0m"
else
    echo "export basedir=/usr/local/mysql/bin" >>/etc/profile
    echo "export PATH=\$PATH:\$basedir" >>/etc/profile
    source /etc/profile
fi
echo "---------------------------------启动MYSQL服务---------------------------------------"
service mysql start
echo 'export PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/lib' >>/etc/profile
sleep 3
source /etc/profile
cat /data/mysql/mysql.err | grep password
chkconfig --add mysql
chkconfig mysql on
chkconfig --list mysql
echo "-----------------------------恭喜！MYSQL安装成功--------------------------------------"
end_time=$(date +%s)
execution_time=$((end_time - start_time))
echo "脚本执行时间：${execution_time} 秒"
MYSQL_OLDPASSWORD=$(awk '/A temporary password/{print $NF}' /data/mysql/mysql.err)
mysqladmin -uroot -p${MYSQL_OLDPASSWORD} password ${MYSQL_ROOT_PASSWORD}
mysql -uroot -p123456 -e "update mysql.user set host ='%' where user ='root';flush privileges;"
mysql -uroot -p123456 -e "SET SQL_LOG_BIN=0;"
mysql -uroot -p123456 -e "create user repl@'%' identified with mysql_native_password by 'repl';"
mysql -uroot -p123456 -e "GRANT REPLICATION SLAVE ON *.* TO repl@'%';"
mysql -uroot -p123456 -e "GRANT CONNECTION_ADMIN ON *.* TO repl@'%';"
mysql -uroot -p123456 -e "GRANT BACKUP_ADMIN ON *.* TO repl@'%';"
mysql -uroot -p123456 -e "FLUSH PRIVILEGES;"
mysql -uroot -p123456 -e "SET SQL_LOG_BIN=1;"
mysql -uroot -p123456 -e "show plugins;"
mysql -uroot -p123456 -e "CHANGE MASTER TO MASTER_USER='repl', MASTER_PASSWORD='repl' FOR CHANNEL 'group_replication_recovery';INSTALL PLUGIN group_replication SONAME 'group_replication.so';"
mysql -uroot -p123456 -e "set  global group_replication_bootstrap_group=ON;set global group_replication_ip_whitelist='192.168.59.0/24';reset master;START GROUP_REPLICATION;SELECT * FROM performance_schema.replication_group_members;SET GLOBAL group_replication_bootstrap_group=OFF;"
mysql -uroot -p123456 <<EOF
exit
EOF
sleep 10
---------------开始安装MGR节点2-----------------------------------------
scp /opt/mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz root@192.168.59.250:/opt
scp /opt/mysql_mgr_2_install.sh root@192.168.59.250:/opt/
ssh -tt -p 22 root@192.168.59.250 "source /opt/mysql_mgr_2_install.sh"
ln -fs /usr/local/mysql/bin/mysql /usr/bin/
REMOTE_HOST="192.168.59.250"
ssh =$REMOTE_HOST <<EOF
if [ $? -eq 0 ]; then
    echo "MySQL 安装已成功完成."
else
    echo "MySQL 安装失败，请检查日志或手动排查问题."
fi
# 添加其他命令，如清理临时文件或重启服务
# 例如：rm /tmp/temp_file
exit
EOF
sleep 10
/usr/bin/expect <<EOF
set timeout 60
# 启动SSH命令
spawn ssh root@192.168.59.249
# 处理首次连接提示的 "yes/no" 和密码输入
expect {
    "Are you sure you want to continue connecting (yes/no)?" { send "yes\r"; exp_continue }
    "password:" { send "123123\r"; exp_continue }
    eof
}
EOF
sleep 10
---------------开始安装MGR节点3-----------------------------------------
scp /opt/mysql-8.0.33-linux-glibc2.12-x86_64.tar.xz root@192.168.59.251:/opt
scp /opt/mysql_mgr_3_install.sh root@192.168.59.251:/opt/
ssh -tt -p 22 root@192.168.59.251 "source /opt/mysql_mgr_3_install.sh"
ln -fs /usr/local/mysql/bin/mysql /usr/bin/
REMOTE_HOST="192.168.59.251"
ssh =$REMOTE_HOST <<EOF
if [ $? -eq 0 ]; then
    echo "MySQL 安装已成功完成."
else
    echo "MySQL 安装失败，请检查日志或手动排查问题."
fi
# 添加其他命令，如清理临时文件或重启服务
# 例如：rm /tmp/temp_file
exit
EOF
sleep 10
/usr/bin/expect <<EOF
set timeout 60
# 启动SSH命令
spawn ssh root@192.168.59.249
# 处理首次连接提示的 "yes/no" 和密码输入
expect {
    "Are you sure you want to continue connecting (yes/no)?" { send "yes\r"; exp_continue }
    "password:" { send "123123\r"; exp_continue }
    eof
}
EOF
sleep 10
mysql -uroot -p123456 -e "select * from performance_schema.replication_group_members; "
mysql -uroot -p123456 <<EOF
exit
EOF
---------------恭喜完成MYSQL MGR多主搭建-----------------------------------------
