---
title: "redis安装和简单配置说明"
subtitle: "redis安装|redis简单配置说明"
description: "redis安装|redis简单使用"
date: 2025-01-07T22:36:09+08:00
lastmod: 2025-01-07T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["redis","中间件"]
categories: ["redis","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/20250107.png"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# redis中间件

## redis 有关参考文档

[redis 最新文档版本下载链接](https://download.redis.io/redis-stable.tar.gz)

[redis 稳定版本下载链接](https://download.redis.io/releases/) 

[redis 源码安装官方参考文档](https://redis.io/docs/latest/operate/oss_and_stack/install/install-redis/install-redis-from-source/)

[redis 命令官方参考文档](https://redis.io/docs/latest/commands/)

## redis 源码安装

redis 源码安装步骤（本次在 Centos7.9 服务版本安装）

1. 下载/解压 redis 源码包

```bash
wget https://download.redis.io/releases/redis-6.2.8.tar.gz
tar -zxf redis-6.2.8.tar.gz
```

2. 安装源码编译依赖 gcc / gcc-c++ / make

```bash
yum install -y gcc gcc-g++ make
```

3. 编译/安装 redis 源码包

```bash
cd redis-6.2.8
make && make install
```

4. 检查安装结果

```bash
ll /usr/local/bin/
```

> -rwxr-xr-x  1 root root  4.7M Jan  7 22:13 redis-benchmark
>
> lrwxrwxrwx  1 root root    12 Jan  7 22:13 redis-check-aof -> redis-server
>
> lrwxrwxrwx  1 root root    12 Jan  7 22:13 redis-check-rdb -> redis-server
>
> -rwxr-xr-x  1 root root  4.8M Jan  7 22:13 redis-cli
>
> lrwxrwxrwx  1 root root    12 Jan  7 22:13 redis-sentinel -> redis-server
>
> -rwxr-xr-x  1 root root  9.2M Jan  7 22:13 redis-server

5. 启动 redis 服务

```bash
redis-server redis.conf
```

6. 把 redis 做成 systemed 服务

   参照源码包 `./redis-6.2.8/utils/systemd-redis_server.service`

   编辑 redis 做 systemed 服务文件：`/usr/lib/systemd/system/redis.service`

   编辑 redis 配置文件：`cp ./redis-6.2.8/redis.conf /etc/redis.conf`，简单配置

   ```properties
   # 注释掉 bind 让任意客户端可以连接
   #bind 127.0.0.1 -::1
   # 允许以守护进程后台运行
   daemonize yes
   # 配置密码
   requirepass redis
   ```

```bash
[Unit]
Description=Redis data structure server
Documentation=https://redis.io/documentation
#Before=your_application.service another_example_application.service
#AssertPathExists=/var/lib/redis
Wants=network.target
After=network.target

[Service]
#ExecStart=/usr/local/bin/redis-server --supervised systemd --daemonize no
# Alternatively, have redis-server load a configuration file:
#ExecStart=/usr/local/bin/redis-server /path/to/your/redis.conf
ExecStart=/usr/local/bin/redis-server /etc/redis.conf
LimitNOFILE=10032
NoNewPrivileges=yes
#OOMScoreAdjust=-900
# 给服务分配独立的临时空间
PrivateTmp=yes
Type=forking
TimeoutStartSec=infinity
TimeoutStopSec=infinity
UMask=0077
#User=redis
#Group=redis
#WorkingDirectory=/var/lib/redis

[Install]
WantedBy=multi-user.target
```

```bash
# 启用 redis 服务
systemctl start redis
```

## redis 配置文件

### 网络

- 默认是仅监听本地回环接口，也就是客户端实例仅能通过本地回环接口地址访问。

- 若是需要允许监听任意接口地址，仅需注释掉 bind 选项。

- 如配置了 bind 地址 `bind 127.0.0.1 -::1` ，服务端就仅允许从 127.0.0.1 过来的连接请求。

```properties
bind 127.0.0.1 -::1
```

### 保护模式

默认开启

- 当 bind 没有显示配置，还没配置密码时保护模式启动，仅能通过 127.0.0.1 本机地址访问。

```properties
protected-mode yes
```

### 监听端口

默认监听 6379 端口

```properties
port 6379
```

### 密码配置

默认为空，没有密码

```properties
requirepass redis
```

### 守护进程方式运行

默认 redis 不以守护进程方式运行，当以守护进程运行是会写如 pid 文件到 /var/run/redis.pid

当 redis 以 systemd 启用时此参数没有影响。

```properties
daemonize no
```

### 日志记录

默认为空，强制 redis 将日志输出到标准输出（控制台），当 redis 以守护进程 (daemonize yes) 方式运行日志会输出到 /dev/null。

```properties
logfile ""
```

### 快照

默认是没有配置的，若要配置则放开注释。

配置格式： `save <seconds> <changes>` 指在 <seconds> 秒内有 <changes> 多 key 变更就会生成快照记录。

快照可以完全禁用通过配置： `save ""` ，配置空字符串。

```properties
save 3600 1
save 300 100
save 60 10000
```

配置快照文件名称：

```properties
dbfilename dump.rdb
```

### 持久化

APPEND ONLY MODE（AOF）

默认关闭（no），yes 开启 AOF 持久化。 appendfilename：自定义持久化 AOF 文件名称。

```
appendonly no
appendfilename "appendonly.aof"
```

持久化时间，默认每秒钟记录一次

```properties
appendfsync everysec
```

### 内存管理

默认到达最大内存时 key 驱逐策略是不做操作，拒绝 key 写入操作。

支持配置：LRU（Least Recently Used：最近最少使用），LFU（Least Frequently Used：最不经常使用算法）
* volatile-lru -> Evict using approximated LRU, only keys with an expire set.
* allkeys-lru -> Evict any key using approximated LRU
* volatile-lfu -> Evict using approximated LFU, only keys with an expire set.
* allkeys-lfu -> Evict any key using approximated LFU.
* volatile-random -> Remove a random key having an expire set.
* allkeys-random -> Remove a random key, any key.
* volatile-ttl -> Remove the key with the nearest expire time (minor TTL)
* noeviction -> Don't evict anything, just return an error on write operations.

```properties
maxmemory-policy noeviction
```

### 主从复制

```properties
replicaof <masterip> <masterport>
masterauth <master-password>
```

示例：

```properties
slaveof 192.168.1.10 6379
masterauth redis
```

或在从节点执行命令：

```bash
redis-server --slaveof <master-ip> <master-port> --masterauth <master-password>
```

参考主从信息：

```bash
127.0.0.1:16379> info replication
```

### 集群模式

默认集成模式未开启

```properties
cluster-enabled yes
cluster-config-file nodes.conf
```

在任意节点创建集群命令：

```bash
/bin/redis-cli -a <password> --cluster create --cluster-replicas 1 \
192.168.100.101:8001 192.168.100.101:8002 192.168.100.102:8003 \
192.168.100.102:8004 192.168.100.103:8005 192.168.100.103:8006
```

集群操作命令：

```bash
# 连接集群
redis-cli -c -h 10.0.248.73 -p 16381
# 查看集群
redis1:16383> cluster info
# 查看节点
redis1:16383> cluster nodes
```