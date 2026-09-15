---
title: "RabbitMQ安装和简单配置说明"
subtitle: "RabbitMQ安装|RabbitMQ简单配置说明"
description: "RabbitMQ安装|RabbitMQ简单配置说明"
date: 2025-01-16T23:36:09+08:00
lastmod: 2026-09-15T22:36:09+08:00
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

### 集群容器化部署

高可用方案：

\- 方案A：经典镜像队列（Classic Mirrored Queues）—— 已废弃，不建议新项目用

\- 方案B：仲裁队列（Quorum Queue）—— 当前官方推荐方案：基于 Raft 协议的多副本 （本次使用这个集群方式）

\- 方案C：Streams（RabbitMQ Stream）—— 高吞吐场景的HA方案

#### 部署脚本

```bash
#!/bin/bash

mkdir -p {rabbitmq1,rabbitmq2,rabbitmq3}

for i in {1..3}; do

cat > ./rabbitmq${i}/enabled_plugins <<EOF
[rabbitmq_management,rabbitmq_peer_discovery_classic_config,rabbitmq_prometheus].
EOF

cat > ./rabbitmq${i}/rabbitmq.conf <<EOF
# 集群自动发现配置：启动时按下面列表自动组集群
cluster_formation.peer_discovery_backend = classic_config
cluster_formation.classic_config.nodes.1 = rabbit@rabbitmq1
cluster_formation.classic_config.nodes.2 = rabbit@rabbitmq2
cluster_formation.classic_config.nodes.3 = rabbit@rabbitmq3

# 网络分区处理策略：少数派自动暂停，避免脑裂
cluster_partition_handling = pause_minority

# 全局默认队列类型设为quorum（重点！）
# 有了这行，Spring Boot声明队列时可以不用每次都加 x-queue-type: quorum 参数
default_queue_type = quorum

# 管理界面监听
management.tcp.port = 15672

loopback_users.guest = false

# 策略设置
default_user = rabbitmq
default_pass = rabbitmq
EOF

done
```

`rabbitmq_management`：管理界面+HTTP API

`rabbitmq_peer_discovery_classic_config`：让节点启动时按配置文件里写死的节点列表自动组集群，不需要手动敲 `join_cluster`

`rabbitmq_prometheus`：可选，方便后续接入监控，不需要可以去掉

`default_queue_type = quorum` 是 RabbitMQ 3.11+ 引入的能力，等于在**服务端**统一兜底：如果Spring Boot那边声明队列时忘了加参数，也会默认建成Quorum Queue而不是Classic Queue。**这不代表可以不改代码**——如果你的Bean声明里已经显式写了别的类型（或者干脆没传`arguments`导致走了老版本客户端的默认行为），还是以代码里显式指定的为准，这行更多是"托底"而不是"替代显式声明"。

```java
@Bean
public Queue orderQueue() {
    Map<String, Object> args = new HashMap<>();
    // x-queue-type 可以省略（靠服务端default_queue_type兜底）
    // 必须加这一行，否则默认还是classic queue
    args.put("x-quorum-initial-group-size", 3);   // 这个没法省
    args.put("x-delivery-limit", 5);              // 这个也没法省
    args.put("x-dead-letter-exchange", DLX_EXCHANGE_NAME);
    return new Queue(QUEUE_NAME, true, false, false, args);
}
```

#### docker-compose.yaml

```yaml
services:
  rabbitmq1:
    image: rabbitmq:3.13.7-management
    container_name: rabbitmq1
    hostname: rabbitmq1
    restart: always
    environment:
      RABBITMQ_ERLANG_COOKIE: "my_secret_cookie_618512cc090a990423207be5"
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: rabbitmq
    ports:
      - "5672:5672"
      - "15672:15672"
    volumes:
      - ./rabbitmq1/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
      - ./rabbitmq1/enabled_plugins:/etc/rabbitmq/enabled_plugins
      - rabbitmq1-data:/var/lib/rabbitmq
    networks:
      - rabbitmq-net

  rabbitmq2:
    image: rabbitmq:3.13.7-management
    container_name: rabbitmq2
    hostname: rabbitmq2
    restart: always
    environment:
      RABBITMQ_ERLANG_COOKIE: "my_secret_cookie_618512cc090a990423207be5"
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: rabbitmq
    ports:
      - "5673:5672"
      - "15673:15672"
    volumes:
      - ./rabbitmq2/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
      - ./rabbitmq2/enabled_plugins:/etc/rabbitmq/enabled_plugins
      - rabbitmq2-data:/var/lib/rabbitmq
    networks:
      - rabbitmq-net
    depends_on:
      - rabbitmq1

  rabbitmq3:
    image: rabbitmq:3.13.7-management
    container_name: rabbitmq3
    hostname: rabbitmq3
    restart: always
    environment:
      RABBITMQ_ERLANG_COOKIE: "my_secret_cookie_618512cc090a990423207be5"
      RABBITMQ_DEFAULT_USER: rabbitmq
      RABBITMQ_DEFAULT_PASS: rabbitmq
    ports:
      - "5674:5672"
      - "15674:15672"
    volumes:
      - ./rabbitmq3/rabbitmq.conf:/etc/rabbitmq/rabbitmq.conf
      - ./rabbitmq3/enabled_plugins:/etc/rabbitmq/enabled_plugins
      - rabbitmq3-data:/var/lib/rabbitmq
    networks:
      - rabbitmq-net
    depends_on:
      - rabbitmq1

networks:
  rabbitmq-net:
    driver: bridge

volumes:
  rabbitmq1-data:
  rabbitmq2-data:
  rabbitmq3-data:
```

关键点说明：

- **`hostname` 必须显式指定**且和 `rabbitmq.conf` 里 `cluster_formation.classic_config.nodes.X` 写的节点名（`rabbit@rabbitmq1`）对应——RabbitMQ的节点名是 `rabbit@<hostname>`，容器内部靠Docker默认DNS能互相解析这些hostname，因为都在同一个自定义bridge网络里
- **`RABBITMQ_ERLANG_COOKIE` 三个节点必须完全一致**，这是Erlang集群节点互信的凭证，不一致会导致节点互相看不见，报 `Could not auto-cluster` 之类的错误
- 单机部署所以宿主机端口做了错位映射（5672/5673/5674，15672/15673/15674），避免端口冲突；容器内部统一还是5672/15672，集群内部节点间通信走的是容器网络+服务名，不受宿主机端口映射影响

#### 启动/验证

```bash
docker-compose up -d

# 等待几秒后检查集群状态
docker exec -it rabbitmq1 rabbitmqctl cluster_status
```

正常的话应该能看到 `rabbit@rabbitmq1`、`rabbit@rabbitmq2`、`rabbit@rabbitmq3` 都在 `running_nodes` 列表里。

```
Disk Nodes

rabbit@rabbitmq1
rabbit@rabbitmq2
rabbit@rabbitmq3

Running Nodes

rabbit@rabbitmq1
rabbit@rabbitmq2
rabbit@rabbitmq3
```

如果没有自动组成集群（比如启动顺序问题导致某个节点没赶上加入），手动补一下：

```bash
docker exec -it rabbitmq2 rabbitmqctl stop_app
docker exec -it rabbitmq2 rabbitmqctl join_cluster rabbit@rabbitmq1
docker exec -it rabbitmq2 rabbitmqctl start_app

docker exec -it rabbitmq3 rabbitmqctl stop_app
docker exec -it rabbitmq3 rabbitmqctl join_cluster rabbit@rabbitmq1
docker exec -it rabbitmq3 rabbitmqctl start_app
```

#### 验证集群健康 + 设置Quorum Queue策略兜底

```
# 集群状态
docker exec -it rabbitmq1 rabbitmqctl cluster_status

# 查看所有 binding（exchange和queue的绑定关系）
docker exec -it rabbitmq1 rabbitmqctl list_bindings

# 查看集群状态（这个才是我原本想让你核实的关键信息）
docker exec -it rabbitmq1 rabbitmqctl cluster_status

# 查看队列列表、类型、leader分布（这条更贴合我们之前的排查目的）
docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members

# 节点健康检查
# 最基础：进程是否存活、能否响应
docker exec -it rabbitmq1 rabbitmq-diagnostics ping

# 检查节点及其依赖的服务是否都在正常运行（相当于原来node_health_check的近似替代）
docker exec -it rabbitmq1 rabbitmq-diagnostics check_running

# 检查本地是否有内存/磁盘告警触发（触发后会拒绝写入,是排查"消息发不出去"的常见原因)
docker exec -it rabbitmq1 rabbitmq-diagnostics check_local_alarms

# 检查端口连通性(4369/25672/5672等关键端口有没有正常监听)
docker exec -it rabbitmq1 rabbitmq-diagnostics check_port_connectivity

# 检查虚拟主机是否都正常运行
docker exec -it rabbitmq1 rabbitmq-diagnostics check_virtual_hosts

# 一次性看节点整体状态(更全面,推荐日常用这个)
docker exec -it rabbitmq1 rabbitmq-diagnostics status
```

即便 `rabbitmq.conf` 里已经设了 `default_queue_type = quorum`，还是建议**再加一层 policy 保险**，对所有以后新建的队列强制指定quorum类型（针对那些Spring Boot代码里没显式声明类型、走了默认建队列路径的场景）：

```bash
docker exec -it rabbitmq1 rabbitmqctl set_policy quorum-default "^" \
  '{"queue-type":"quorum"}' --apply-to queues --priority 0
```

#### Spring Boot调整

```yaml
spring:
  rabbitmq:
    addresses: <宿主机IP>:5672,<宿主机IP>:5673,<宿主机IP>:5674
    username: rabbitmq
    password: rabbitmq
```

其余部分（`x-queue-type: quorum` 声明、Publisher Confirm、手动ACK等），这套代码和RabbitMQ集群到底是几台机器、什么网络模式，是解耦的。

#### 验证HA是否真正生效

```bash
# 1. 看某个队列的leader分布在哪个节点
docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members

# 2. 模拟leader所在节点故障（假设leader是rabbitmq1）
docker stop rabbitmq1

# 3. 从Spring Boot应用观察：
#    - confirmCallback是否短暂失败后恢复正常
#    - 重新查看leader是否已经切换到rabbitmq2或rabbitmq3
docker exec -it rabbitmq2 rabbitmqctl list_queues name type leader members

# 4. 恢复节点，确认它以follower身份重新加入
docker start rabbitmq1
docker exec -it rabbitmq1 rabbitmqctl cluster_status
```

```bash
# 看这个队列是什么时候、以什么参数被创建的（部分信息可以从policy应用情况反推）
docker exec -it rabbitmq1 rabbitmqctl list_queues name type arguments

# 1. 删除这两个队列（会清空队列里现存的所有消息，测试环境可以直接删）
docker exec -it rabbitmq1 rabbitmqctl delete_queue order.queue
docker exec -it rabbitmq1 rabbitmqctl delete_queue order.dlx.queue
```

#### 队列quorum没生效

验证一下现状，配置文件中 `default_queue_type=quorum` 没有生效

```bash
docker exec -it rabbitmq1 rabbitmqctl list_vhosts name default_queue_type
```

大概率会看到 `/` 这个vhost的 `default_queue_type` 是空的或者 `undefined`，而不是 `quorum`——这就证实了配置文件那行设置根本没被应用到这个已存在的vhost上。

```
Listing vhosts ...
name    default_queue_type
/       undefined
```

解决方式：用 CLI 命令显式更新这个已存在vhost的元数据

```bash
# 更新默认vhost的default_queue_type元数据...
docker exec rabbitmq1 rabbitmqctl update_vhost_metadata / --default-queue-type quorum
```

这样 `rabbitmq.conf` 里的 `default_queue_type = quorum` 配置项，实际上只在**全新集群、vhost是第一次被创建**的场景下才会自动生效；对于你这种"集群已经跑过一段时间，vhost早就存在"的情况，**必须靠这条 `update_vhost_metadata` 命令补一刀**，两者要配合用才稳妥。

这条命令是专门为"vhost已存在，事后要改默认队列类型"这个场景设计的，执行后再验证：

```bash
docker exec -it rabbitmq1 rabbitmqctl list_vhosts name default_queue_type

# 看某个队列的leader分布在哪个节点
docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members
```

应该能看到 `/` 对应的值变成了 `quorum`。

```bash
$ docker exec -it rabbitmq1 rabbitmqctl list_vhosts name default_queue_type
Listing vhosts ...
name    default_queue_type
/       quorum

$ docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members
Timeout: 60.0 seconds ...
Listing queues for vhost / ...
name    type    leader  members
order.dlx.queue quorum  rabbit@rabbitmq1        [rabbit@rabbitmq1, rabbit@rabbitmq2, rabbit@rabbitmq3]
order.queue     quorum  rabbit@rabbitmq1        [rabbit@rabbitmq1, rabbit@rabbitmq2, rabbit@rabbitmq3]
```



#### 故障演练验证真实HA效果

配置对了不等于HA真的能用，最好实际验证一次——毕竟这也是我们从最开始讨论到现在的核心目的：

```bash
# 查看 leader 所在节点
# leader 那一列就是当前这个队列的Raft leader所在节点，members 是全部副本分布的节点列表。
docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members

# 1. 当前leader都在rabbitmq1上，停掉这个节点
docker stop rabbitmq1
docker-compose stop rabbitmq1

# 2. 从存活节点查看leader是否自动切换
docker exec -it rabbitmq2 rabbitmqctl list_queues name type leader members
# 期望：leader应该已经自动变成 rabbitmq2 或 rabbitmq3

# 3. 这期间用Spring Boot应用发送/消费消息，确认：
#    - confirmCallback是否只是短暂失败/重试后恢复正常
#    - 消费者是否能继续正常处理（可能会有断线重连的日志，属正常现象）

# 4. 恢复节点，确认它以follower身份重新加入，不是又抢回leader（Raft不会因为老节点回来就强制切换leader）
docker start rabbitmq1
docker exec -it rabbitmq1 rabbitmqctl cluster_status
docker exec -it rabbitmq1 rabbitmqctl list_queues name type leader members
```

如果这一整套走下来，Spring Boot那边只是出现短暂的连接重试日志（类似我们之前分析过的`Channel shutdown`/`Restarting Consumer`），没有真正的消息丢失、服务在几秒内自动恢复，就说明整个方案——**从RabbitMQ集群本身的Quorum Queue机制,到Spring Boot侧的多节点连接配置+Publisher Confirm+手动ACK配合**——是真正端到端跑通了的。

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
