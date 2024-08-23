#!/usr/bin/python

# -*- coding: UTF-8 -*-

import os
import time

def install():
    """
    postgresql14-14.2安装
    sudo yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
    yum install -y --downloadonly --downloaddir=./packages  postgresql14-server
    --
    rpm -Uvh --force --nodeps ./packages/*.rpm
    sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
    sudo systemctl enable postgresql-14
    sudo systemctl start postgresql-14
    sudo  -H  -u postgres psql -c "create user ceshi with password '123456';"
    sudo  -H  -u postgres psql -c "create database test_db owner ceshi;"
    sudo  -H  -u postgres psql -c "grant all privileges on database test_db to ceshi;"
    :return:
    """
    os.system("rpm -Uvh --force --nodeps ./packages/*.rpm")
    os.system("sudo /usr/pgsql-14/bin/postgresql-14-setup initdb")
    os.system("sudo systemctl enable postgresql-14")
    os.system("sudo systemctl start postgresql-14")
    os.system("sudo  -H  -u postgres psql -c \"create user ceshi with password '123456';\"")
    os.system("sudo  -H  -u postgres psql -c \"create database test_db owner ceshi;\"")
    os.system("sudo  -H  -u postgres psql -c \"grant all privileges on database test_db to ceshi;\"")
def config_postgresql():
    """
    配置postgresql14-14.2
    vi /var/lib/pgsql/14/data/postgresql.conf
    #listen_addresses = 'localhost'
    listen_addresses = '*'
    vi /var/lib/pgsql/14/data/pg_hba.conf
    host    all            all            0.0.0.0/0              md5
    :return:
    """
    with open("/var/lib/pgsql/14/data/postgresql.conf", "r+") as conf_file:
        file_context = conf_file.read()
        file_context = file_context.replace("daemonize no", "daemonize yes").replace("#listen_addresses = 'localhost'",
                                                                                    "listen_addresses = '*'")
        conf_file.write(file_context)
    with open("/var/lib/pgsql/14/data/pg_hba.conf", "a") as conf_file:
        conf_file.write("host    all            all            0.0.0.0/0              md5")
    os.system("sudo systemctl restart postgresql-14")
def detect():
    """
    检测是否安装成功
    :return:
    """
    time.sleep(5)
    return True if os.popen("systemctl status postgresql-14").read().find(
        "active (running)") > 0 else False
def prompt_fail():
    """
    安装失败后提示
    :return:
    """
    print """
    \033[5;31;40m 安装失败 \033[0m
    """
def prompt_success():
    """
    安装成功后提示
    :return:
    """
    print """
    \033[5;32;40m 恭喜postgresql14-14.2安装成功！\033[0m
    使用前注意：
        测试前可以先关闭防火墙：systemctl stop firewalld
      使用sudo权限的非root用户去执行，因为root用户不允许创建数据库账号和库。
        postgresql14 以添加默认账号、开启远程连接、并设置好开机自启：
        账号：ceshi
        密码：123456
        默认数据库：test_db
        端口：5432
        配置文件路径：/var/lib/pgsql/14/data/
    停止命令：systemctl stop postgresql-14
    启动命令：systemctl start postgresql-14
    重启命令：systemctl restart postgresql-14
    """
if __name__ == '__main__':
    install()
    config_postgresql()
    if detect():
        prompt_success()
    else:
        prompt_fail()