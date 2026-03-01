---
title: "MySQL安装和简单配置说明"
subtitle: "MySQL安装|MySQL简单配置说明"
description: "MySQL安装|MySQL简单配置说明"
date: 2025-01-15T23:36:09+08:00
lastmod: 2025-01-15T23:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["MySQL"]
categories: ["MySQL","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1544.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# MySQL

## MySQL参考文档

[MySQL 安装包下载链接](https://downloads.mysql.com/archives/community/)

[MySQL Yum 仓库源下载链接](https://dev.mysql.com/downloads/repo/yum/)

[MySQL Windows 5.7.44 下载链接](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-winx64.zip)，[MySQL Windows 8.4.2 下载链接](https://downloads.mysql.com/archives/get/p/23/file/mysql-8.4.2-winx64.zip)

[MySQL Red Hat 7 5.7.44  安装包下载链接](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-1.el7.x86_64.rpm-bundle.tar)，[MySQL Red Hat 7 8.4.2 安装包下载链接](https://downloads.mysql.com/archives/get/p/23/file/mysql-8.4.2-1.el7.aarch64.rpm-bundle.tar)

## MySQL常用命令和配置

### 修改密码

```mysql
use mysql ;
update user set authentication_string=password('mysql') where user='root';
commit;
```

### 允许远程访问

```mysql
use mysql ;
select user, host from user ;
update user set host = '%' where user = 'root';
commit ;
```

### 创建用户

新建用户

```mysql
create user 'test'@'%' identified by 'mysql';
```

创建数据库并授权

```mysql
-- 创建 test 数据库
create database test default charset utf8mb4 ;
-- 授权数据库 test 的所有权限给用户 test 并拥有在分配权限的能力
grant all privileges on test.* to 'test'@'%' with grant option;
-- 刷新权限
flush privileges ;
-- 提交
commit ;
```

### 表区分大小写配置

默认 Windows 不区分大小写，Linux 下区分大小写。

查看 MySQL 区分大小写参数

```mysql
show variables like '%case%' ;
```

|          Variable_name | Value | 说明                                                   |
| ---------------------: | :---: | :----------------------------------------------------- |
| lower_case_file_system |  ON   | windwos: ON<br />Linux：OFF                            |
| lower_case_table_names |   1   | 0：区分大小写（Linux）<br />1：不区分大小写（Windows） |

修改配置文件 `my.ini` 或 `my.cnf`

```properties
[mysqld]
# 设置 mysql 是否区分大小写
lower_case_table_names=0
```

## MySQL安装

### Windows二进制包安装

本次使用写文档是最新的 [MySQL 5.7.44](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-winx64.zip) 安装。

#### 环境变量配置

变量名：MYSQL_HOME
变量值：E:\mysql5.7.23
在 path 里添加 MySQL bin 命令工具目录：%MYSQL_HOME%\bin

改环境变量 bat 脚本，也可以手动配置

```bat
setx /M MYSQL_HOME "C:\mysql\mysql-5.7.44"
setx /M Path "%Path%;%MYSQL_HOME%\bin"
```

加 `/M` 参数设置系统环境变量，不加 `/M` 参数设置用户环境变量

**注意：** 在设置 `path` 环境变量时需要添加原有的 `path`  参数 `%path%`

#### MySQL 配置

在 MySQL 安装包解压目录中添加 MySQL 配置参数文件 `my.ini`

```properties
[default]
default-character-set=utf8mb4

[mysqld]
port=3306
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
init-connect='SET NAMES utf8mb4'

# 安装 MySQL 目录 / 数据目录
basedir=C:\install\mysql
datadir=C:\install\mysql\data

[client]
default-character-set=utf8mb4
```

#### 初始化数据库

**注意：** 以管理员身份运行 `CMD` 控制台，进入 MySQL bin 目录执行以下命令

```bat
mysqld --initialize --user=mysql --console
```

或者

```bat
mysqld --initialize-insecure
```

![MySQL Windows 安装](https://www.nihility.cn/files/images/tools/mysql-windows-install.png)

注意记住最后的临时 root 密码。

#### 注册为服务

注册服务

```bat
mysqld -install MySQL
```

启动服务

```
net start MySQL
```

删除服务

```bat
sc delete MySQL
```

#### 初始化修改密码

登录 MySQL

```bat
mysql -u root -p
> 输入初始化临时密码
```

初始化首次登录修改密码（使用 `ALTER` 命令）

```mysql
ALTER USER root@localhost IDENTIFIED  BY '123456';
```

当忘记密码时修改密码

```mysql
use mysql ;
update user set authentication_string = password('mysql') where user = 'root';
commit ;
```

查询初始化用户数据

```mysql
-- 切换到 mysql 数据库
use mysql ;
-- 查看初始化用户数据
select user, host from user ;
```

### Centos7 RPM 安装

先下载适配 Centos7 的 [MySQL 5.7.44（mysql-5.7.44-1.el7.x86_64.rpm-bundle.tar）](https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.44-1.el7.x86_64.rpm-bundle.tar) 安装包。

#### 安装 MySQL

解压 MySQL 集成安装包

```bash
tar xf mysql-5.7.44-1.el7.x86_64.rpm-bundle.tar
```

卸载 Centos7 默认安装的 `mariadb`

```bash
yum remove mariadb-libs
```

安装 MySQL，在解压包后的 rpm 目录中执行安装命令

```bash
yum install -y *.rpm
```

#### 初始化配置

Linux 下 MySQL 默认配置文件 `/etc/my.cnf`，简单配置默认编码格式

```properties
[default]
default-character-set=utf8mb4

[mysqld]
port=3306
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
init-connect='SETNAMESutf8mb4'

[client]
default-character-set=utf8mb4
```

#### 启动MySQL服务

启动 MySQL 服务

```bash
systemctl start mysqld
# 查看 mysql 服务是否正常启动
systemctl status mysqld
```

查询初始化启动临时 root 登录密码

```bash
grep 'temporary password' /var/log/mysqld.log
```

> A temporary password is generated for root@localhost: /Pb>V%dJ%5hm
