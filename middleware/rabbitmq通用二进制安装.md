---
title: "RabbitMQ通用unix二进制安装"
subtitle: "RabbitMQ安装|RabbitMQ通用unix二进制安装"
description: "RabbitMQ安装|RabbitMQ通用unix二进制安装"
date: 2025-05-19T22:36:09+08:00
lastmod: 2025-05-19T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["RabbitMQ"]
categories: ["RabbitMQ","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2318.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# RabbitMQ通用unix安装

[RabbitMQ 版本下载列表](https://github.com/rabbitmq/rabbitmq-server/releases)

[RabbitMQ 版本与 Erlang/OTP 兼容矩阵链接](https://www.rabbitmq.com/docs/next/which-erlang#compatibility-matrix)

[RabbitMQ 版本列表](https://www.rabbitmq.com/release-information#currently-supported)

## Erlang/OTP 安装

[Erlang/OTP 下载网页链接](https://www.erlang.org/downloads)

本次示例安装 RabbitMQ v3.13.6 版本二进制安装，[Erlang/OTP 26.2.5.2 源码下载链接](https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz),若是 [github](https://github.com/) 下载过慢，可以使用 [Github 代理加速](https://github.akams.cn/) 下载。

### Erlang/OTP 下载

```bash
wget https://gitproxy.click/https://github.com/erlang/otp/releases/download/OTP-26.2.5.2/otp_src_26.2.5.2.tar.gz

# 解压并进入 otp 源码目录
tar -zxf otp_src_26.2.5.2.tar.gz
cd otp_src_26.2.5.2
```

### 安装编译依赖

```bash
yum install -y gcc gcc-c++ make epel-release
yum install -y ncurses-devel openssl-devel unixODBC-devel wxGTK3-devel libxslt fop autoconf
```

### 配置编译选项

```bash
./configure \
  --prefix=/usr/local/erlang \
  --enable-threads \
  --enable-smp-support \
  --enable-kernel-poll \
  --enable-hipe \
  --with-ssl \
  --without-javac \
  --enable-dirty-schedulers \
  --enable-dynamic-ssl-lib
```

关键选项说明：

- `--prefix`：指定安装路径
- `--with-ssl`：启用 SSL 支持（RabbitMQ 必需）
- `--enable-kernel-poll`：提升网络性能
- `--without-javac`：跳过 Java 编译（减少依赖）

### 编译并安装

```bash
# 使用所有 CPU 核心加速编译
make -j$(nproc)
make install
```

### 配置环境变量

```bash
echo 'export PATH=$PATH:/usr/local/erlang/bin' | tee /etc/profile.d/erlang.sh
source /etc/profile.d/erlang.sh
```

验证安装：

```
erl -version
# Erlang (SMP,ASYNC_THREADS) (BEAM) emulator version 14.2.4
```

## RabbitMQ 通用 Unix 包安装（推荐）

RabbitMQ 仍提供跨 Linux 发行版的 **Generic UNIX** 压缩包，适用于 CentOS 7。

[RabbitMQ v3.13.6 各版本 github 下载链接](https://github.com/rabbitmq/rabbitmq-server/releases/tag/v3.13.6)

[RabbitMQ v3.13.6 通用 unix 版本下载链接](https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.6/rabbitmq-server-generic-unix-3.13.6.tar.xz)，若 github 下载过慢，可以通过 [gitbub 代理加速](https://github.akams.cn/) 下载。

### 下载 RabbitMQ 安装包

```bash
wget https://gitproxy.click/https://github.com/rabbitmq/rabbitmq-server/releases/download/v3.13.6/rabbitmq-server-generic-unix-3.13.6.tar.xz

# 解压到 /usr/local/ 目录
tar -Jxf rabbitmq-server-generic-unix-3.13.6.tar.xz -C /usr/local/
# 改名为 rabbitmq
mv /usr/local/rabbitmq_server-3.13.6/ /usr/local/rabbitmq

cd /usr/local/rabbitmq/
```

### 安装依赖

```bash
yum install -y socat logrotate openssl
```

### 配置环境变量

```bash
echo 'export PATH=$PATH:/usr/local/rabbitmq/sbin' | sudo tee /etc/profile.d/rabbitmq.sh
source /etc/profile.d/rabbitmq.sh
```

#### 创建专用用户和数据目录

```bash
sudo useradd -r -d /var/lib/rabbitmq -s /bin/false rabbitmq
sudo mkdir -p /var/{lib,log,run}/rabbitmq
sudo chown -R rabbitmq:rabbitmq /var/{lib,log,run}/rabbitmq
sudo chown -R rabbitmq:rabbitmq /usr/local/rabbitmq
```

#### 配置环境变量

创建配置文件 `/etc/rabbitmq/rabbitmq-env.conf`：

```bash
sudo mkdir -p /etc/rabbitmq

sudo tee /etc/rabbitmq/rabbitmq-env.conf << EOF
RABBITMQ_NODENAME=rabbit@$(hostname -s)
RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq/mnesia
RABBITMQ_LOG_BASE=/var/log/rabbitmq
RABBITMQ_PID_FILE=/var/run/rabbitmq/pid
RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf
ENABLED_PLUGINS_FILE=/etc/rabbitmq/enabled_plugins
EOF
```

#### 高级配置

```bash
sudo tee /etc/rabbitmq/rabbitmq.conf << EOF
# 监听地址和端口
listeners.tcp.default = 5672

# 管理界面配置
management.tcp.port = 15672
management.tcp.ip = 0.0.0.0

# 禁用 guest 用户远程访问（生产环境建议）
loopback_users.guest = false

# 内存和磁盘警告阈值
vm_memory_high_watermark.relative = 0.6
disk_free_limit.absolute = 2GB
EOF
```

### 配置 systemed 服务

```bash
sudo tee /etc/systemd/system/rabbitmq-server.service << EOF
[Unit]
Description=RabbitMQ Generic UNIX Service V3.13.6
After=network.target

[Service]
Type=forking
User=rabbitmq
Group=rabbitmq
UMask=0027
LimitNOFILE=65536
Environment="PATH=/usr/local/erlang/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin"
Environment="HOME=/var/lib/rabbitmq"
Environment="RABBITMQ_MNESIA_BASE=/var/lib/rabbitmq/mnesia"
Environment="RABBITMQ_LOG_BASE=/var/log/rabbitmq"
Environment="RABBITMQ_PID_FILE=/var/run/rabbitmq/pid"
Environment="RABBITMQ_CONFIG_FILE=/etc/rabbitmq/rabbitmq.conf"
Environment="RABBITMQ_CONF_ENV_FILE=/etc/rabbitmq/rabbitmq-env.conf"
ExecStart=/usr/local/rabbitmq/sbin/rabbitmq-server -detached
ExecStop=/usr/local/rabbitmq/sbin/rabbitmqctl stop
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
```

#### 重载 systemd 并启动服务

```bash
sudo systemctl daemon-reload
sudo systemctl start rabbitmq-server
sudo systemctl enable rabbitmq-server
```

#### 日志轮转

```bash
sudo tee /etc/logrotate.d/rabbitmq << EOF
/var/log/rabbitmq/*.log {
    daily
    rotate 7
    missingok
    notifempty
    compress
    delaycompress
    sharedscripts
    postrotate
        systemctl restart rabbitmq >/dev/null 2>&1 || true
    endscript
}
EOF
```

### 安装后需配置

#### 创建管理员用户

```bash
rabbitmqctl add_user admin yourpassword
rabbitmqctl set_user_tags admin administrator
rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
```

若是操作遇到如下问题：

```
Error: unable to perform an operation on node 'rabbit@localhost'. Please see diagnostics information and suggestions below.

DIAGNOSTICS
===========

attempted to contact: [rabbit@localhost]

rabbit@localhost:
  * connected to epmd (port 4369) on localhost
  * epmd reports: node 'rabbit' not running at all
                  no other nodes on localhost
  * suggestion: start the node

Current node details:
 * node name: 'rabbitmqcli-509-rabbit@localhost'
 * effective user's home directory: /var/lib/rabbitmq
 * Erlang cookie hash: 3mVoEeREVMiFlXrG74TIaQ==
```

执行如下命令：

```bash
# 停止 RabbitMQ 服务
sudo systemctl stop rabbitmq-server

# 清除旧有 Mnesia 数据库
sudo rm -rf /var/lib/rabbitmq/mnesia/
sudo systemctl start rabbitmq-server

# 修改 cookie（所有集群节点必须相同）
sudo openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' > /var/lib/rabbitmq/.erlang.cookie
sudo chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
sudo chmod 600 /var/lib/rabbitmq/.erlang.cookie

# 启动 RabbitMQ
sudo systemctl start rabbitmq-server
```

或者在家目录更新 cookie 值

```bash
cat /var/lib/rabbitmq/.erlang.cookie > .erlang.cookie
```

#### 启用管理插件

```bash
rabbitmq-plugins enable rabbitmq_management
```

#### 启用防火墙

```bash
sudo firewall-cmd --permanent --add-port={5672,15672}/tcp
sudo firewall-cmd --reload
```

#### 浏览器访问

```
http://10.10.10.90:15672
```

