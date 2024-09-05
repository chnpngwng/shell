#!/bin/bash

echo -e "\e[31m****一键安装mysql任何版本数据库***\e[0m"

echo -e "输入安装版本，如\e[31m8.0.27\e[0m"

read version

find / -name mysql | xargs rm -rf

port=$(netstat -antup | grep mysql | wc -l)

if [ $port != 0 ]; then
    echo "mysql进程存在,请先杀掉进程"

    ps -ef | grep mysqld

    exit 1

fi

echo "-------------------创建所需目录及用户并上传安装包-------------------"

mkdir -p /data/mysql

groupadd mysql

useradd -r -g mysql mysql

cd /opt/

tar -xvf mysql-$version-linux-glibc2.12-x86_64.tar.xz

mv mysql-$version-linux-glibc2.12-x86_64/ /usr/local/

cd /usr/local/

mv mysql-$version-linux-glibc2.12-x86_64/ mysql

chown -R mysql.mysql /usr/local/mysql/

echo "----------------卸载原有的mysql组件-------------------"

yum list installed | grep mariadb

yum -y remove mariadb*

yum remove mariadb*

chown mysql:mysql -R /data/mysql

touch /etc/my.cnf

chmod 644 /etc/my.cnf

MYSQL_ROOT_PASSWORD=12345678

cat <<EOF >/etc/my.cnf

[mysqld]

user=mysql

basedir=/usr/local/mysql

datadir=/data/mysql

socket=/tmp/mysql.sock

log-error=/data/mysql/mysql.err

pid-file=/data/mysql/mysql.pid

server_id=1

port=3306

character-set-server=utf8

innodb_rollback_on_timeout = ON

character-set-server = utf8

collation-server=utf8_general_ci

sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES

lower_case_table_names=1

max_connections=10000

sync_binlog=1

binlog_format=row

[mysql]

socket=/tmp/mysql.sock

default-character-set=utf8

[client]

EOF

echo "----------------启动MYSQL service-------------------"

echo "----------------初始化数据库-------------------"

cd /usr/local/mysql/bin

./mysqld --defaults-file=/etc/my.cnf --basedir=/usr/local/mysql/ --datadir=/data/mysql/ --user=mysql --initialize

cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysql

path=$(grep 'MYSQL_HOME' /etc/profile | wc -l)

if [ $path != 0 ]; then

    echo -e "\e[31m MYSQL_HOME路径存在\e[0m"

else

    echo "export MYSQL_HOME=/usr/local/mysql/bin" >>/etc/profile

    echo "export PATH=\$PATH:\$MYSQL_HOME" >>/etc/profile

    source /etc/profile

fi

service mysql start

echo 'export PATH=$PATH:/usr/local/mysql/bin:/usr/local/mysql/lib' >>/etc/profile

source /etc/profile

cat /data/mysql/mysql.err | grep password

chkconfig --add mysql

chkconfig mysql on

chkconfig --list mysql

MYSQL_OLDPASSWORD=$(awk '/A temporary password/{print $NF}' /data/mysql/mysql.err)

mysqladmin -uroot -p${MYSQL_OLDPASSWORD} password ${MYSQL_ROOT_PASSWORD}

mysql -uroot -p123456 -e "update mysql.user set host ='%' where user ='root';"

mysql -uroot -p123456 -e "flush privileges;"

mysql -uroot -p123456
