#!/bin/bash

# 检查是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
    echo "请以非root的sudo用户运行此脚本。"
    exit 1
fi
# 安装必要的依赖
echo "安装依赖包..."
yum install -y epel-release
yum install -y wget vim
# 下载并安装 PostgreSQL 官方YUM repository 配置包
echo "添加 PostgreSQL YUM repository..."
yum install -y --downloadonly --downloaddir=./packages postgresql14-server
# 安装 PostgreSQL
echo "安装 PostgreSQL 14"
rpm -Uvh --force --nodeps ./packages/*.rpm
# 初始化数据库集群
echo "初始化数据库..."
sudo /usr/pgsql-14/bin/postgresql-14-setup initdb
# 启动并启用 PostgreSQL 服务
echo "启动并启用 PostgreSQL 服务..."
sudo systemctl enable postgresql-14
sudo systemctl start postgresql-14
# 创建一个测试用户和数据库
echo "创建测试用户和数据库..."
sudo -u postgres psql -c "create user myuser with password 'mypassword';"
sudo -u postgres psql -c "create database mydb owner myuser;"
# 设置postgresql.conf 和 pg_hba.conf 的基本配置
echo "配置 postgresql.conf 和 pg_hba.conf..."
PG_CONF_DIR="/var/lib/pgsql/$PG_VERSION/data"
cat >>$PG_CONF_DIR/postgresql.conf <<EOL
listen_addresses = '*'
EOL
cat >>$PG_CONF_DIR/pg_hba.conf <<EOL
host    all            all            0.0.0.0/0              md5
EOL
# 重启 PostgreSQL 服务以应用配置更改
echo "重启 PostgreSQL 服务..."
systemctl restart postgresql-14
# 提示安装完成
echo "PostgreSQL $PG_VERSION 安装完成并已启动。"
echo "可以使用命令 'sudo -u postgres psql' 连接到 PostgreSQL 数据库。"
