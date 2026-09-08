# Redis哨兵、集群部署

## Redis哨兵部署

### 容器部署脚本

```bash
#!/bin/bash

# init
mkdir -p redis-sentinel/{master,slave1,slave2,sentinel1,sentinel2,sentinel3}
mkdir -p redis-sentinel/{master,slave1,slave2}/data
touch redis-sentinel/{master,slave1,slave2}/redis.conf
touch redis-sentinel/{sentinel1,sentinel2,sentinel3}/sentinel.conf
chmod 666 sentinel1/sentinel.conf sentinel2/sentinel.conf sentinel3/sentinel.conf

cd redis-sentinel
# redis config
HOST_IP=10.4.100.125

# master/redis.conf
cat > ./master/redis.conf <<EOF
port 6379
bind 0.0.0.0
protected-mode no
requirepass redis
masterauth redis
appendonly yes
dir /data
EOF

# slave1/redis.conf
cat > ./slave1/redis.conf <<EOF
port 6379
bind 0.0.0.0
protected-mode no
requirepass redis
masterauth redis
replicaof ${HOST_IP} 16379
replica-announce-ip ${HOST_IP}
replica-announce-port 26379
appendonly yes
dir /data
EOF

# slave2/redis.conf
cat > ./slave2/redis.conf <<EOF
port 6379
bind 0.0.0.0
protected-mode no
requirepass redis
masterauth redis
replicaof ${HOST_IP} 16379
replica-announce-ip ${HOST_IP}
replica-announce-port 36379
appendonly yes
dir /data
EOF

# sentinel config

# sentinel1/sentinel.conf
cat > ./sentinel1/sentinel.conf <<EOF
port 26379
sentinel monitor mymaster ${HOST_IP} 16379 2
sentinel auth-pass mymaster redis
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel announce-ip ${HOST_IP}
sentinel announce-port 46379
EOF

# sentinel2/sentinel.conf
cat > ./sentinel2/sentinel.conf <<EOF
port 26379
sentinel monitor mymaster ${HOST_IP} 16379 2
sentinel auth-pass mymaster redis
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel announce-ip ${HOST_IP}
sentinel announce-port 46479
EOF

# sentinel3/sentinel.conf
cat > ./sentinel3/sentinel.conf <<EOF
port 26379
sentinel monitor mymaster ${HOST_IP} 16379 2
sentinel auth-pass mymaster redis
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel announce-ip ${HOST_IP}
sentinel announce-port 46579
EOF
```

#### redis配置

```
port 6380
bind 0.0.0.0
protected-mode no
requirepass redis
masterauth redis
replicaof <宿主机IP> <宿主机主redis节点映射端口>
replica-announce-ip <宿主机IP>
replica-announce-port <宿主机当前redis节点映射端口>
appendonly yes
dir /data
```



#### 哨兵配置

`sentinel.conf`

```
port 26379
# 客户端不在 docker 网络内 → 关掉 hostname 通告，改回IP模式
# sentinel resolve-hostnames yes
# sentinel announce-hostnames yes
# sentinel monitor mymaster redis-master 6379 2
sentinel monitor mymaster <宿主机IP> <宿主机主redis节点映射端口> 2
sentinel auth-pass mymaster redis
sentinel down-after-milliseconds mymaster 5000
sentinel failover-timeout mymaster 60000
sentinel parallel-syncs mymaster 1
sentinel announce-ip <宿主机IP>
sentinel announce-port <宿主机当前哨兵redis节点映射端口>
```

要点说明：

- 2 是 quorum（3 个哨兵中至少 2 个认为主库挂了才会发起故障转移）
- `resolve-hostnames yes` + `announce-hostnames yes`：让哨兵用容器服务名而不是 IP 来记录/通告节点，这是 Redis 6.2+ 之后专门为容器场景加的能力，省去手工配置固定 IP 的麻烦
- 重要坑：故障转移发生后，Sentinel 会重写自己的配置文件（把新 master 地址等信息写回去），所以这个 `sentinel.conf` 文件在容器里必须是可写的，不能用只读挂载
- 这样不管客户端在不在 docker 网络里，只要能路由到这个 IP 段（比如宿主机上，容器网络默认是能从宿主机访问的），就不存在 DNS 解析问题。

### docker-compose.yaml配置

```yaml
networks:
  redis-sentinel:
    driver: bridge

services:
  redis-master:
    image: redis:7.4.10
    container_name: redis-master
    restart: always
    ports:
      - "16379:6379"
    volumes:
      - ./master/redis.conf:/etc/redis/redis.conf
      - ./master/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-sentinel

  redis-slave1:
    image: redis:7.4.10
    container_name: redis-slave1
    restart: always
    ports:
      - "26379:6379"
    volumes:
      - ./slave1/redis.conf:/etc/redis/redis.conf
      - ./slave1/data:/data
    command: redis-server /etc/redis/redis.conf
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  redis-slave2:
    image: redis:7.4.10
    container_name: redis-slave2
    restart: always
    ports:
      - "36379:6379"
    volumes:
      - ./slave2/redis.conf:/etc/redis/redis.conf
      - ./slave2/data:/data
    command: redis-server /etc/redis/redis.conf
    depends_on:
      - redis-master
    networks:
      - redis-sentinel

  sentinel1:
    image: redis:7.4.10
    container_name: sentinel1
    restart: always
    ports:
      - "46379:26379"
    volumes:
      - ./sentinel1/sentinel.conf:/etc/redis/sentinel.conf
    command: redis-sentinel /etc/redis/sentinel.conf
    depends_on:
      - redis-master
      - redis-slave1
      - redis-slave2
    networks:
      - redis-sentinel

  sentinel2:
    image: redis:7.4.10
    container_name: sentinel2
    restart: always
    ports:
      - "46479:26379"
    volumes:
      - ./sentinel2/sentinel.conf:/etc/redis/sentinel.conf
    command: redis-sentinel /etc/redis/sentinel.conf
    depends_on:
      - redis-master
      - redis-slave1
      - redis-slave2
    networks:
      - redis-sentinel

  sentinel3:
    image: redis:7.4.10
    container_name: sentinel3
    restart: always
    ports:
      - "46579:26379"
    volumes:
      - ./sentinel3/sentinel.conf:/etc/redis/sentinel.conf
    command: redis-sentinel /etc/redis/sentinel.conf
    depends_on:
      - redis-master
      - redis-slave1
      - redis-slave2
    networks:
      - redis-sentinel

```

### 启动 & 验证

```bash
docker-compose up -d

# 查看主从复制状态
docker exec -it redis-master redis-cli -a redis info replication

# 查看哨兵视角
docker exec -it sentinel1 redis-cli -p 26379 sentinel master mymaster
docker exec -it sentinel1 redis-cli -p 26379 sentinel replicas mymaster
docker exec -it sentinel1 redis-cli -p 26379 sentinel sentinels mymaster

# 模拟主库故障，观察自动切换
docker stop redis-master
docker exec -it sentinel2 redis-cli -p 26379 sentinel master mymaster   # 几秒后应显示新 master
```

宿主机验证

```bash
# 从slave1容器内部，测试能不能通过"宿主机IP"连回同一台机器的master端口
$ docker exec -it redis-slave1 redis-cli -h <宿主机IP> -p 6379 -a redis ping
docker exec -it redis-slave1 redis-cli -h 10.4.100.125 -p 6379 -a redis ping
# 应该返回 PONG

# 从sentinel1容器内部同样测试
$ docker exec -it sentinel1 redis-cli -h <宿主机IP> -p 6379 -a redis ping
docker exec -it sentinel1 redis-cli -h 10.4.100.125 -p 6379 -a redis ping

# 1. 主从复制是否正常
docker exec -it redis-master redis-cli -a redis info replication
# 应看到 connected_slaves:2，并且两个slave的ip字段显示的是宿主机IP，不是容器内部IP

# 2. sentinel看到的master地址
docker exec -it sentinel1 redis-cli -h 10.4.100.125 -p 46379 sentinel get-master-addr-by-name mymaster
# 应返回 <宿主机IP> 6379，而不是172.x.x.x这种内部地址

# 3. sentinel看到的从库地址
docker exec -it sentinel1 redis-cli -h 10.4.100.125 -p 46379 sentinel replicas mymaster
# 检查每个slave的ip/port字段，应该也是宿主机IP + 6380/6381
```

## Redis集群部署

### 容器部署脚本

```bash
#!/bin/bash

# redis-cluster
mkdir -p ./{node1,node2,node3,node4,node5,node6}/data

HOST_IP=10.4.100.125

# node1-6 : port 7001-7006, cluster bus port 17001-17006
for i in {1..6}; do

cat > ./node${i}/redis.conf <<EOF
port 700${i}
bind 0.0.0.0
protected-mode no
requirepass redis
masterauth redis

cluster-enabled yes
cluster-config-file nodes.conf
cluster-node-timeout 5000
cluster-announce-ip ${HOST_IP}
cluster-announce-port 700${i}
cluster-announce-bus-port 1700${i}

appendonly yes
dir /data
EOF

done
```

### docker-compose.yaml配置

关键点：**数据端口和总线端口都要 1:1 映射**（容器内端口 = 宿主机端口），否则 `cluster-announce-port`/`cluster-announce-bus-port` 和实际映射对不上，节点间握手会失败。

```yaml
services:
  redis-node1:
    image: redis:7.4.10
    container_name: redis-node1
    restart: always
    ports:
      - "7001:7001"
      - "17001:17001"
    volumes:
      - ./node1/redis.conf:/etc/redis/redis.conf
      - ./node1/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

  redis-node2:
    image: redis:7.4.10
    container_name: redis-node2
    restart: always
    ports:
      - "7002:7002"
      - "17002:17002"
    volumes:
      - ./node2/redis.conf:/etc/redis/redis.conf
      - ./node2/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

  redis-node3:
    image: redis:7.4.10
    container_name: redis-node3
    restart: always
    ports:
      - "7003:7003"
      - "17003:17003"
    volumes:
      - ./node3/redis.conf:/etc/redis/redis.conf
      - ./node3/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

  redis-node4:
    image: redis:7.4.10
    container_name: redis-node4
    restart: always
    ports:
      - "7004:7004"
      - "17004:17004"
    volumes:
      - ./node4/redis.conf:/etc/redis/redis.conf
      - ./node4/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

  redis-node5:
    image: redis:7.4.10
    container_name: redis-node5
    restart: always
    ports:
      - "7005:7005"
      - "17005:17005"
    volumes:
      - ./node5/redis.conf:/etc/redis/redis.conf
      - ./node5/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

  redis-node6:
    image: redis:7.4.10
    container_name: redis-node6
    restart: always
    ports:
      - "7006:7006"
      - "17006:17006"
    volumes:
      - ./node6/redis.conf:/etc/redis/redis.conf
      - ./node6/data:/data
    command: redis-server /etc/redis/redis.conf
    networks:
      - redis-cluster-net

networks:
  redis-cluster-net:
    driver: bridge
```

### 启动&验证

#### 启动

```bash
docker-compose up -d
docker ps   # 确认6个容器都Up
```

#### 必做：先验证 NAT hairpin 通不通

因为每个节点要通过"宿主机IP:端口"去连接其他节点（对外宣称的地址就是这个），这条路径要绕一圈回到宿主机再回到另一个容器，不是所有 Docker 环境都默认支持：

bash

```bash
# 从node1容器内部，测试能不能通过"宿主机IP"连到node2
docker exec -it redis-node1 redis-cli -h <宿主机IP> -p 7002 -a redis ping
# 期望返回 PONG
```

**如果返回 PONG**：继续下一步创建集群。

**如果超时/拒绝连接**：说明这台机器的 Docker 网络不支持 hairpin，需要开启内核参数：

```bash
# 找到bridge网络对应的网卡（通常是docker0或自定义bridge对应的veth）
docker network inspect redis-cluster_redis-cluster-net | grep -i "com.docker.network.bridge.name"

# 对该网桥开启 route_localnet（如果网桥名是br-xxxxx）
sudo sysctl -w net.ipv4.conf.br-xxxxxxxxxxxx.route_localnet=1

# 或者更通用地对docker0尝试（如果用的是默认bridge）
sudo sysctl -w net.ipv4.conf.docker0.route_localnet=1
```

如果调整内核参数后依然不通，最稳妥的退路是把这一台机器改回 **host 网络模式**（上一条回复里的方案一），bridge+hairpin 在部分云主机/精简内核环境下确实不总能保证生效。

#### 创建集群

hairpin 验证通过后：

```bash
docker exec -it redis-node1 redis-cli -a redis --cluster create \
  <宿主机IP>:7001 <宿主机IP>:7002 <宿主机IP>:7003 \
  <宿主机IP>:7004 <宿主机IP>:7005 <宿主机IP>:7006 \
  --cluster-replicas 1
```

会打印类似这样的分配方案，确认无误后输入 `yes`：

```
Master[0] -> Slots 0 - 5460
Master[1] -> Slots 5461 - 10922
Master[2] -> Slots 10923 - 16383
Adding replica <IP>:7005 to <IP>:7001
Adding replica <IP>:7006 to <IP>:7002
Adding replica <IP>:7004 to <IP>:7003
```

#### 验证

```bash
# 集群状态
docker exec -it redis-node1 redis-cli -a redis -c -h <宿主机IP> -p 7001 CLUSTER INFO
docker exec -it redis-node1 redis-cli -a redis -c -h <宿主机IP> -p 7001 CLUSTER NODES

# 官方巡检
docker exec -it redis-node1 redis-cli -a redis --cluster check <宿主机IP>:7001

# 读写测试（-c 参数让客户端自动跟随MOVED重定向）
docker exec -it redis-node1 redis-cli -a redis -c -h <宿主机IP> -p 7001
> set foo bar
> get foo
```

`CLUSTER NODES` 里每一行应该显示的都是**宿主机IP**而不是172.x的内部IP，如果还看到内部IP，说明某个节点的 `cluster-announce-ip` 没生效，检查对应conf文件是否正确挂载，`docker-compose restart` 对应节点重新加载。