#!/bin/bash

#一键安装oracle数据库
#修改主机名
hostnamectl set-hostname myoracle
#添加主机名与IP对应记
public_ip=$(hostname -I | grep -o -e '[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}.[0-9]\{1,3\}' | head -n 1)
node_name=$(hostname)
echo -e "${public_ip} ${node_name}" >>/etc/hosts
cat /etc/hosts
#关闭Selinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
setenforce 0
#关闭防火墙
systemctl stop firewalld
systemctl disable firewalld
systemctl status firewalld
# 获取当前所在目录位置
current_dir=$(pwd)
echo "当前所在目录位置: $current_dir"
# 目标路径
target_dir="/soft"
# 检查目标路径是否存在，如果不存在则创建
if [ ! -d "$target_dir" ]; then
    mkdir -p "$target_dir"
    echo "已创建目录: $target_dir"
fi
# 移动当前目录下的所有文件到目标路径
mv $current_dir/* $target_dir
echo "已将当前目录下所有文件移动至 $target_dir"
#添加离线yum源
cd /soft
tar -xvf oracle_repo.tar.gz
cd /soft/my_oracle_repo
rpm -ivh *.rpm --nodeps --force
#在线yum源
cd /etc/yum.repos.d/
rm -rf ./*
sleep 20
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
#添加用户组及用户
groupadd -g 54321 oinstall
groupadd -g 54322 dba
groupadd -g 54323 oper
groupadd -g 54324 backupdba
groupadd -g 54325 dgdba
groupadd -g 54326 kmdba
useradd -u 54321 -g oinstall -G dba,backupdba,dgdba,kmdba,oper oracle
echo "oracle" | passwd --stdin oracle
id oracle
chmod 644 /etc/sysctl.conf
#修改环境变量
cat <<EOF >>/etc/sysctl.conf
#ORACLE SETTING
fs.aio-max-nr = 1048576
fs.file-max = 6815744
kernel.sem = 250 32000 100 128
net.ipv4.ip_local_port_range = 9000 65500
net.core.rmem_default = 262144
net.core.rmem_max = 4194304
net.core.wmem_default = 262144
net.core.wmem_max = 1048586
kernel.panic_on_oops = 1
#(kernel.shmmax = 物理内存*1024*1024*1024-1)
kernel.shmmax = 2684354560
#控制共享内存页数(kernel.shmall = shmmax/4096)
kernel.shmall = 655360
#共享内存的最大数量
kernel.shmmni = 4096
#当系统内存使用90%的时候开始使用交换页面
vm.swappiness=10
#默认是100,增大这个参数设置了虚拟内存回收directory和i-node缓冲的倾向,这个值越大。越容易回收。
vm.vfs_cache_pressure=200
EOF
sysctl -p
chmod 644 /etc/security/limits.conf
cat <<EOF >>/etc/security/limits.conf
#ORACLE SETTING
#打开文件描述符大小
oracle soft nproc 16384
oracle hard nproc 16384
#单个用户可用的进程数
oracle soft nofile 16384
oracle hard nofile 65536
#进程堆栈段的大小
oracle soft stack 10240
oracle hard stack 32768
EOF
echo "none /dev/shm tmpfs defaults,size=3096m 0 0" >>/etc/fstab
mount -o remount /dev/shm
chmod 644 /etc/profile
cat <<EOF >>/etc/profile
if [ $USER = "oracle" ]; then
   if [ $SHELL = "/bin/ksh" ]; then
       ulimit -p 16384
       ulimit -n 65536
    else
       ulimit -u 16384 -n 65536
   fi
fi
EOF
source /etc/profile
mkdir -p /u01/app/oracle
mkdir -p /u01/app/oraInventory
mkdir -p /u01/app/oracle/product/19.0.0/dbhome_1
mkdir -p /soft
mkdir -p /u01/app/oracle/fast_recovery_area
chown -R oracle:oinstall /u01
chown -R oracle:oinstall /soft
chmod -R 775 /u01
chmod -R 775 /soft
cat <<EOF >>/home/oracle/.bash_profile
#for oracle
umask=022
export PS1
export TMP=/tmp
export LANG=en_US.UTF8
export TMPDIR=$TMP
export ORACLE_UNQNAME=cdb19c
export ORACLE_SID=cdb19c
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
export ORACLE_TERM=xterm
export NLS_DATE_FORMAT="yyyy-mm-dd HH24:MI:SS"
export NLS_LANG=AMERICAN_AMERICA.UTF8
#export PATH=.:$PATH:$HOME/.local/bin:$HOME/bin:$ORACLE_HOME/bin
export THREADS_FLAG=native
export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:/lib:/usr/lib
export CLASSPATH=\$ORACLE_HOME/JRE:\$ORACLE_HOME/jlib:\$ORACLE_HOME/rdbms/jlib
export ORACLE_OWNR=oracle
export PATH=\$PATH:\$ORACLE_HOME/bin
EOF
source /home/oracle/.bash_profile
mv /soft/*.zip /u01/app/oracle/product/19.0.0/dbhome_1
cd /u01/app/oracle/product/19.0.0/dbhome_1
#解压oracle安装包
unzip LINUX.X64_193000_db_home.zip
mkdir -p /home/oracle/etc
chown -R oracle.oinstall /home/oracle/etc
cp /u01/app/oracle/product/19.0.0/dbhome_1/install/response/* /soft/
chmod 777 /soft/*.rsp
chown -R oracle:oinstall /soft
cat <<EOF >/soft/db_install.rsp
#软件版本信息
oracle.install.responseFileVersion=/oracle/install/rspfmt_dbinstall_response_schema_v19.0.0
#安装选项-仅安装数据库软件
oracle.install.option=INSTALL_DB_SWONLY
#oracle用户用于安装软件的组名
UNIX_GROUP_NAME=oinstall
#oracle产品清单目录
INVENTORY_LOCATION=/u01/app/oraInventory
#oracle安装目录
ORACLE_HOME=/u01/app/oracle/product/19.0.0/dbhome_1
#oracle基础目录
ORACLE_BASE=/u01/app/oracle
#安装版本类型：企业版
oracle.install.db.InstallEdition=EE
#指定组信息
oracle.install.db.OSDBA_GROUP=dba
oracle.install.db.OSOPER_GROUP=oper
oracle.install.db.OSBACKUPDBA_GROUP=backupdba
oracle.install.db.OSKMDBA_GROUP=kmdba
oracle.install.db.OSRACDBA_GROUP=dba
oracle.install.db.OSDGDBA_GROUP=dgdba
EOF
chown -R oracle:oinstall /soft/db_install.rsp
chmod 660 /soft/db_install.rsp
chown -R oracle:oinstall /u01/app/oracle/product/19.0.0/dbhome_1
#开始安装oracle软件
su - oracle -c "/u01/app/oracle/product/19.0.0/dbhome_1/runInstaller -silent -responseFile /soft/db_install.rsp"
sleep 200
/u01/app/oraInventory/orainstRoot.sh
/u01/app/oracle/product/19.0.0/dbhome_1/root.sh
echo -e "\n\n****** start listener config  ******\n\n"
cp /u01/app/oracle/product/19.0.0/dbhome_1/assistants/netca/netca.rsp /soft/
chmod 644 /soft/netca.rsp
cat <<EOF >>/soft/netca.rsp
[GENERAL]
RESPONSEFILE_VERSION="19.0"
CREATE_TYPE="CUSTOM"
[oracle.net.ca]
INSTALLED_COMPONENTS={"server","net8","javavm"}
INSTALL_TYPE=""typical""
LISTENER_NUMBER=1
LISTENER_NAMES={"LISTENER"}
LISTENER_PROTOCOLS={"TCP;1521"}
LISTENER_START=""LISTENER""
NAMING_METHODS={"TNSNAMES","ONAMES","HOSTNAME"}
NSN_NUMBER=1
NSN_NAMES={"EXTPROC_CONNECTION_DATA"}
NSN_SERVICE={"PLSExtProc"}
NSN_PROTOCOLS={"TCP;HOSTNAME;1521"}
EOF
sleep 60
#开始安装监听
su - oracle -c "/u01/app/oracle/product/19.0.0/dbhome_1/bin/netca -silent -responsefile /soft/netca.rsp"
echo -e "\n\n****** listener config completed ******\n\n"
cp /u01/app/oracle/product/19.0.0/dbhome_1/assistants/dbca/dbca.rsp /soft
chmod 644 /soft/dbca.rsp
cat <<EOF >>/soft/dbca.rsp
#响应文件版本号
responseFileVersion=/oracle/assistants/rspfmt_dbca_response_schema_v19.0.0
templateName=General_Purpose.dbc
gdbName=cdb19c
sid=cdb19c
createAsContainerDatabase=TRUE
numberOfPDBs=1
pdbName=pdb19c
pdbAdminPassword=Systiger123
sysPassword=Systiger123
systemPassword=Systiger123
datafileDestination=/u01/app/oracle/oradata
recoveryAreaDestination=/u01/app/oracle/fast_recovery_area
storageType=FS
characterSet=AL32UTF8
nationalCharacterSet=AL16UTF16
sampleSchema=true
totalMemory=2048
databaseType=OLTP
emConfiguration=NONE
EOF
sleep 60
echo -e "\n\n****** start db instance create ******\n\n"
##开始建库
su - oracle -c "/u01/app/oracle/product/19.0.0/dbhome_1/bin/dbca 
-silent -createDatabase -templateName /u01/app/oracle/product/19.0.0/dbhome_1/assistants/dbca/templates/General_Purpose.dbc 
-responseFile NO_VALUE \
-gdbname cdb19c  -sid cdb19c \
-createAsContainerDatabase TRUE \
-numberOfPDBs 1 \
-pdbName pdb19c \
-pdbAdminPassword Systiger123 \
-sysPassword Systiger123 -systemPassword Systiger123 \
-datafileDestination '/u01/app/oracle/oradata' \
-redoLogFileSize 50 \
#-storageType FS \
-characterset AL32UTF8 -nationalCharacterSet AL16UTF16 \
-sampleSchema true \
-totalMemory 512 \
-databaseType OLTP  \
-emConfiguration NONE"
echo -e "\n\n****** db instance create complete ******\n\n"
