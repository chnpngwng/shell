#!/bin/bash

# 安装wget、vim
yum -y install wget vim
# 备份官方的原yum源的配置
mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup
# 下载Centos-7.repo文件,或者curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo，取决于你是否有wget的命令
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
# 清除yum缓存
yum clean all
# 缓存本地yum源
yum makecache
# 测试阿里云源
yum list
