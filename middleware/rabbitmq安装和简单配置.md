---
title: "RabbitMQ安装和简单配置说明"
subtitle: "RabbitMQ安装|RabbitMQ简单配置说明"
description: "RabbitMQ安装|RabbitMQ简单配置说明"
date: 2025-01-16T23:36:09+08:00
lastmod: 2025-01-18T23:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["RabbitMQ"]
categories: ["RabbitMQ","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1256.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# RabbitMQ

## RabbitMQ有关参数文档

[RabbitMQ 官网](https://www.rabbitmq.com/)

[RabbitMQ 下载 github 链接](https://github.com/rabbitmq/rabbitmq-server/tags)

[RabbitMQ 与 Erlang/OTP 兼容性矩阵链接](https://www.rabbitmq.com/docs/which-erlang#compatibility-matrix)

| [RabbitMQ 版本](https://www.rabbitmq.com/release-information) | **需要的 Erlang/OTP 最低版本** | **最大支持的 Erlang/OTP 版本** |
| :----------------------------------------------------------: | :----------------------------: | :----------------------------: |
|                        4.0.1 - 4.0.3                         |              26.2              |             26.2.x             |
|                            3.13.x                            |              26.0              |             26.2.x             |
|                      3.12.10 - 3.12.13                       |              25.0              |             26.2.x             |

[Erlang/OTP 官网](https://www.erlang.org/)

[Erlang/OTP  Windows下载链接](https://www.erlang.org/downloads)

[Erlang/OPT Centos 下载链接](https://binaries2.erlang-solutions.com/rockylinux/esl-erlang-26/esl-erlang_26.2.4_1~centos~8_x86_64.rpm)

## RabbitMQ安装

本次测试安装 RabbitMQ 版本为 3.13.6。

### Windows安装

先安装 [Erlang/OTP 26.2.4](https://github.com/erlang/otp/releases/download/OTP-26.2.4/otp_win64_26.2.4.exe) （不断下一步一下步完成安装），在安装 [RabbitMQ 3.13.6](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.6/rabbitmq-server-3.13.6.exe) （也是不断下一步一下不完成安装）。

### Centos7安装

#### OTP源码安装

[注意 RabbitMQ 和 Erlang 之间的版本关系](https://www.rabbitmq.com/docs/which-erlang)

先安装 [Erlang/OTP 26.2.4](https://github.com/erlang/otp/releases/download/OTP-26.2.4/otp_src_26.2.4.tar.gz) 源码安装，请自行下载源码先。

预先安装编译 otp 所需依赖

```bash
yum install -y gcc glibc-devel make ncurses-devel openssl-devel xmlto perl wget socat
```

解压 otp

```bash
tar -zxf otp_src_26.2.4.tar.gz
```

配置

```bash
cd otp_src_26.2.4

./configure --prefix=/usr/local/erlang

make && make install
```

添加配置环境变量，环境变量配置文件 `/etc/profile`

```bash
# 在 /etc/profile 文件末尾添加 erlang 可执行环境变量，具体路径按安装配置路径为准
ERLANG_HOME=/usr/local/erlang
PATH=$PATH:$ERLANG_HOME/bin
export $ERLANG_HOME $PATH
```

输入erl，出现版本号就说明成功。

#### RabbitMQ安装

在安装 [RabbitMQ 3.13.16](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.6/rabbitmq-server-3.13.6.tar.xz) 二进制安装安装，下载文件 [rabbitmq-server-3.13.6.tar.xz](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.6/rabbitmq-server-3.13.6.tar.xz)

解压配置环境变量

```bash
tar -Jxf rabbitmq-server-3.13.6.tar.xz
cd rabbitmq_server-3.13.6
```

把RabbitMQ添加到环境变量 `/etc/profile`

```bash
RABBITMQ_HOME=/usr/local/rabbitmq_server-3.13.6
PATH=$PATH:$RABBITMQ_HOME/sbin
export RABBITMQ_HOME PATH
```

输入命令行启动 rabbitmq 服务

```bash
rabbitmq-server
# 后台启动
rabbitmq-server -detached
```

关闭 rabbitmq 服务

```bash
rabbitmqctl stop
```

#### RabbitMQ配置

默认 RabbitMQ 配置文件路径 `$RABBITMQ_HOME/etc/rabbitmq/rabbitmq.conf`

基础配置

```properties
# 这是一个注释
listeners.tcp.default = 5673
# web 管理端口
management.tcp.port = 15672
# 或者
[{rabbit, [{tcp_listeners, [5673]}]}]
```

#### 添加一个管理员

默认 gust 仅能在本机上面登录，需要新建一个管理员账户支持远程访问。

注意：需在 RabbitMQ 启动后，新开一个 shell 窗口添加

```
rabbitmqctl add_user admin admin
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

启动一些插件

```bash
rabbitmq-plugins enable rabbitmq_management
rabbitmq-plugins enable rabbitmq_amqp1_0
rabbitmq-plugins enable rabbitmq_federation
rabbitmq-plugins enable rabbitmq_web_stomp
```

启用功能特性

```bash
# 列出所有功能特性
rabbitmqctl list_feature_flags

# 启用所有或指定功能特性
rabbitmqctl enable_feature_flag <all | name>
```

#### 制作systemed服务

systemed 服务文件 `/usr/lib/systemd/system/rabbitmq-server.service`

**注意：** 

- 需要把 erl 放到 `/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin` 这其中一个执行目录中。
- 或者在 `rabbitmq-server.service` 服务文件中添加 ERL 可执行文件的路径

```properties
[Unit]
Description=RabbitMQ broker
After=network.target
Wants=network.target

[Service]
# 配置 ERL 可执行目录，或者直接把 ERL 放到默认可执行目录中
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/usr/local/erlang/bin"
Type=forking
User=root
Group=root
NotifyAccess=all
TimeoutStartSec=600

Restart=on-failure
RestartSec=10
WorkingDirectory=/usr/local/rabbitmq
ExecStart=/usr/local/rabbitmq/sbin/rabbitmq-server -detached
ExecStop=/usr/local/rabbitmq/sbin/rabbitmqctl stop
# See rabbitmq/rabbitmq-server-release#51
SuccessExitStatus=69

[Install]
WantedBy=multi-user.target
```

查看 RabbitMQ 安装后状态

```bash
systemctl status rabbitmq-server
```

启动 RabbitMQ

```bash
systemctl start rabbitmq-server
```

### 容器化安装

#### 部署脚本

```bash
#!/bin/bash

mkdir -p ./rabbitmq/{data,logs,plugins,conf}

# ./rabbitmq/conf/rabbitmq.conf
cat <<EOF > ./rabbitmq/conf/rabbitmq.conf
# 网络设置
listeners.tcp.default = 5672
management.tcp.port = 15672
# 磁盘和内存限制
vm_memory_high_watermark.relative = 0.7
disk_free_limit.absolute = 2GB
# 策略设置
default_user = rabbitmq
default_pass = rabbitmq
# 日志设置
log.console.level = info
log.file.level = info
# 性能优化
channel_max = 2047
heartbeat = 60
frame_max = 131072
EOF

# ./rabbitmq/conf/definitions.json
cat <<EOF > ./rabbitmq/conf/definitions.json
{"users":[{"name":"rabbitmq","password":"rabbitmq","tags":"administrator"}],"vhosts":[{"name":"/"}],"permissions":[{"user":"rabbitmq","vhost":"/","configure":".*","write":".*","read":".*"}],"queues":[],"exchanges":[],"bindings":[]}
EOF

#groupadd -g 999 rabbitmq
#useradd -u 999 -g 999 rabbitmq
#chown -R 999:999 ./rabbitmq
```

#### rabbitmq3x docker-compose.yaml

```yaml
networks:
  rabbitmq-network:
    driver: bridge

# Failed to create cookie file '/var/lib/rabbitmq/.erlang.cookie': eacces
# 容器内 RabbitMQ 进程运行的用户（rabbitmq，通常 UID 999）不匹配
volumes:
  rabbitmq_data:
  rabbitmq_log:

services:
  rabbitmq-server:
    image: rabbitmq:3.13.7-management
    container_name: rabbitmq-server
    hostname: rabbitmq-server
    environment:
      # 默认用户名密码
      RABBITMQ_DEFAULT_USER: "rabbitmq"
      RABBITMQ_DEFAULT_PASS: "rabbitmq"
      # 启用管理插件
      RABBITMQ_DEFAULT_VHOST: "/"
      # Optional tuning
      RABBITMQ_ERLANG_COOKIE: "my_secret_cookie_618512cc090a990423207be5"
    ports:
      - "5672:5672"   # AMQP
      - "15672:15672" # Web UI
    volumes:
      # mkdir -p ./rabbitmq/{data,logs,plugins,conf}
      # chown -R 999:999 ./rabbitmq
      #- ./rabbitmq/init.sh:/init.sh
      # https://github.com/rabbitmq/rabbitmq-delayed-message-exchange 
      # 从 4.3+ 版本开始，RabbitMQ 官方已经内置了 rabbitmq_delayed_message_exchange 插件，无需单独安装。
      # rabbitmq-plugins enable rabbitmq_delayed_message_exchange
      #- ./rabbitmq/data:/var/lib/rabbitmq
      - rabbitmq_data:/var/lib/rabbitmq
      - rabbitmq_log:/var/log/rabbitmq
      #- ./rabbitmq/plugins/rabbitmq_delayed_message_exchange-3.13.0.ez:/opt/rabbitmq/plugins/rabbitmq_delayed_message_exchange-3.13.0.ez
      - ./rabbitmq/conf/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
      - ./rabbitmq/conf/definitions.json:/etc/rabbitmq/definitions.json
    user: "999:999"  # 指定 RabbitMQ 的用户 ID
    # /bin/sh /opt/rabbitmq/sbin/rabbitmq-server
    # command: /bin/bash -c "rabbitmq-plugins enable rabbitmq_delayed_message_exchange ; rabbitmq-server"
    command:
      - bash
      - -c
      - |
        #rabbitmq-plugins enable rabbitmq_delayed_message_exchange
        rabbitmq-server
    restart: always
    networks:
      - rabbitmq-network
```

#### rabbitmq4.x docker-compose.yml

```yaml
networks:
  rabbitmq-network:
    driver: bridge

volumes:
  rabbitmq_data:
  rabbitmq_log:

services:
  rabbitmq:
    image: rabbitmq:4.2.2-management
    container_name: rabbitmq
    hostname: rabbitmq-node1
    restart: always
    ports:
      - "5672:5672"      # AMQP
      - "15672:15672"    # Web UI
    environment:
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: rabbitmq
      RABBITMQ_DEFAULT_VHOST: /
      # Erlang cluster cookie (important)
      RABBITMQ_ERLANG_COOKIE: "my_secret_cookie_618512cc090a990423207be5"
    user: "999:999"
    volumes:
      # mkdir -p ./rabbitmq/{data,logs,plugins,conf}
      # chown -R 999:999 ./rabbitmq
      # - ./rabbitmq/data:/var/lib/rabbitmq
      # - ./rabbitmq/logs:/var/log/rabbitmq
      - rabbitmq_data:/var/lib/rabbitmq
      - rabbitmq_log:/var/log/rabbitmq
    networks:
      - rabbitmq-network
```



## RabbitMQ安装初始化操作

### 启用WEB管理界面

```bash
rabbitmq-plugins enable rabbitmq_management
```

默认端口 <font color="blue">4369、5672、15672、25672</font>

默认登录用户名和密码都是 gust ，注意仅能通过本机登录访问。

### 用户有关操作

#### 新增用户

`rabbitmqctl add_user <username> <password>`

```bash
# 新增用户名为 rabbitmq 密码为 rabbitmq 的账号
rabbitmqctl add_user rabbitmq rabbitmq
```

#### 查看用户列表

```bash
rabbitmqctl list_users
```

#### 修改用户权限

`rabbitmqctl set_user_tags <username> tag tag2 ...`

```bash
# tag 包含（gust, administrator，monitoring，policymaker，management）
# 设置 rabbitmq 账号有管理员权限
rabbitmqctl set_user_tags rabbitmq administrator
```

#### 其他用户相关操作

```bash
# 删除指定用户
rabbitmqctl delete_user <username>
# 修改指定用户密码
rabbitmqctl change_password <username> <newpassword>
# 清除指定用户密码
rabbitmqctl clear_password <username>
```

### vhosts 操作

#### vhost 编辑操作

```bash
# 添加 vhost
rabbitmqctl add_vhost <vhostpath>
# 删除指定 vhost
rabbitmqctl delete_vhost <vhostpath>
# 列出 vhost
rabbitmqctl list_vhosts [<vhostinfoitem> ...]
```

#### vhost 权限操作

```bash
# 设置指定用户对指定 vhost 有所有全选
rabbitmqctl set_permissions -p "/" <username> '.*' '.*' '.*'
# 列出用户权限
rabbitmqctl list_user_permissions username
```

```bash
# 针对一个 vhosts
rabbitmqctl set_permissions [-p <vhostpath>] <user> <conf> <write> <read>
rabbitmqctl clear_permissions [-p <vhostpath>] <username>
rabbitmqctl list_permissions [-p <vhostpath>]
rabbitmqctl list_user_permissions <username>
```

## 延迟消息插件安装

[RabbitMQ 延迟插件 github 下载链接](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases)

**注意：** RabbitMQ 版本若为 `3.13.x` 版本那么消息延迟插件也应该下载 `3.13.x` 版本的。

[RabbitMQ 延迟消息队列插件下载链接 v3.13.x 版本](https://github.com/rabbitmq/rabbitmq-delayed-message-exchange/releases/download/v3.13.0/rabbitmq_delayed_message_exchange-3.13.0.ez)

把消息延迟插件包上传到 `RabbitMQ` 安装目录 `plugins` 目录中。

查看插件列表

```bash
rabbitmq-plugins list
# 查询插件是否包含延迟消息队列插件
rabbitmq-plugins list | grep delayed_message_exchange
```

启用消息延迟队列插件

```bash
rabbitmq-plugins enable rabbitmq_delayed_message_exchange
```



## 初始化遇到错误解决

### 在管理端执行命令报错

当执行命令包如下错误时

```
Error: unable to perform an operation on node 'rabbit@DESKTOP-8RAHTPQ'. Please see diagnostics information and suggestions below.

Most common reasons for this are:

 * Target node is unreachable (e.g. due to hostname resolution, TCP connection or firewall issues)
 * CLI tool fails to authenticate with the server (e.g. due to CLI tool's Erlang cookie not matching that of the server) * Target node is not running

...

Current node details:
 * node name: 'rabbitmqcli-902-rabbit@DESKTOP-8RAHTPQ'
 * effective user's home directory: c:/Users/Administrator
 * Erlang cookie hash: JeehOyUyOJpBreAzs8thTA==
```

解决方法：复制 `C:\Windows\System32\config\systemprofile\.erlang.cookie` 文件到上面错误显示的用户目录 `c:/Users/Administrator` 下替换此文件。
