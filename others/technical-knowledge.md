## JAVA

### Tomcat 连接池配置优化

```yaml
server:
  tomcat:
    # 全连接队列长度（accept backlog）
    accept-count: 100
    # 最大同时连接数
    max-connections: 8192
    threads:
    # 启动即创建的最小线程数
    min-spare: 10
    # 最大工作线程数
    # IO 密集型 ≈ CPU * 10
    max: 200
    # 连接建立后等待请求的超时时间（毫秒）
    connection-timeout: 20000
    # Keep-Alive 空闲超时
    keep-alive-timeout: 20000
    # 单连接最大请求数
    max-keep-alive-requests: 100
```

### GC

(Java中9种常见的CMS GC问题分析与解决)[https://tech.meituan.com/2020/11/12/java-9-cms-gc.html]


## Redis

### 惰性删除（Lazy Deletion）

Redis 的惰性删除（Lazy Free/Lazy Eviction）是一种内存管理机制，它通过延迟删除操作来提高 Redis 的性能和响应速度。

惰性删除是指 Redis 不会立即删除过期的键或当内存不足时被淘汰的键，而是在以下两种情况下进行删除：

1. 访问时检查：当客户端尝试访问一个键时，Redis 会检查该键是否已过期，如果过期则立即删除
2. 定期删除：Redis 会定期随机检查并删除一部分过期键

惰性删除的优势

- 提高性能：避免在键过期时立即执行删除操作造成的性能抖动
- 减少阻塞：删除大键时不会阻塞主线程
- 更好的响应：客户端请求不会被删除操作阻塞

### 内存淘汰策略（Maxmemory Policy）

Redis 内存淘汰策略是当 Redis 内存使用达到配置的最大限制时，决定如何删除键以释放空间的机制。

- noeviction：不淘汰，当内存不足时，新写入操作会报错，读操作正常（默认策略）
- allkeys-lru：从所有键中淘汰最近最少使用的键，近似 LRU，通过采样选择
- volatile-lru： 只从设置了过期时间的键中淘汰最近最少使用的
- allkeys-lfu：从所有键中淘汰最不经常使用的键，基于访问频率，而非最近访问时间

选择矩阵：

| 场景                  | 推荐策略         | 理由                           |
| :-------------------- | :--------------- | :----------------------------- |
| 纯缓存系统            | `allkeys-lru`    | 所有数据都可淘汰，保留热点数据 |
| 混合系统（缓存+持久） | `volatile-lru`   | 只淘汰缓存数据，保护持久数据   |
| 数据访问均匀          | `allkeys-random` | 随机淘汰，公平性               |
| 热点数据明显          | `allkeys-lfu`    | 基于访问频率，保留热点         |
| 缓存分层              | `volatile-ttl`   | 优先淘汰即将过期的             |
| 关键业务数据          | `noeviction`     | 确保数据不丢失                 |

#### 优化

采样数量调整

```
# 增加采样数量提高LRU/LFU精度（但会增加CPU使用）
maxmemory-samples 10
```

结合惰性删除

```
# 启用惰性删除减少阻塞
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
```

### 缓存问题

### 缓存穿透（Cache Penetration）

缓存穿透是指查询一个不存在的数据时，缓存和数据库都没有命中，导致请求直接打到数据库，可能引发数据库压力过大。

解决方案：

- 布隆过滤器：在缓存层前增加布隆过滤器，快速判断数据是否存在
- 缓存空结果：对于不存在的数据，也在缓存中存储一个空结果，防止重复查询
- 参数校验：对请求参数进行严格校验，过滤掉非法请求

### 缓存击穿（Cache Breakdown）

缓存击穿是指某个热点数据在缓存过期的瞬间，大量并发请求同时查询该数据，导致请求直接打到数据库，可能引发数据库压力过大。

场景：

- 热点商品信息缓存过期
- 热门新闻缓存失效
- 秒杀活动商品信息缓存过期

解决方案：

- 互斥锁（Mutex Lock）：在缓存失效时，只有一个请求能查询数据库并更新缓存，其他请求等待
- 预热缓存（Cache Pre-warming）：在缓存过期前，提前更新缓存
- 永不过期（Never Expire）：对于热点数据，设置为永不过期，通过后台定时更新缓存

### 缓存雪崩（Cache Avalanche）

缓存雪崩是指大量缓存同时过期，导致大量请求直接打到数据库，可能引发数据库压力过大。

场景：
- 大量缓存设置了相同的过期时间
- 系统重启导致缓存全部失效

解决方案：
- 随机过期时间：为缓存设置随机的过期时间，避免大量缓存同时失效
- 多级缓存：使用本地缓存和分布式缓存结合，减少对数据库
- 限流降级（熔断机制）：在高并发情况下，对请求进行限流，保护数据库

## Docker 安装

### Centos7

```bash
# step 1: 安装必要的一些系统工具
sudo yum install -y yum-utils

# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo

# Step 3: 安装Docker
#sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
yum install containerd.io docker-ce-26.1.4-1.el7

# Step 4: 开启Docker服务
sudo service docker start

# 注意：
# 官方软件源默认启用了最新的软件，您可以通过编辑软件源的方式获取各个版本的软件包。例如官方并没有将测试版本的软件源置为可用，您可以通过以下方式开启。同理可以开启各种测试版本等。
# vim /etc/yum.repos.d/docker-ce.repo
#   将[docker-ce-test]下方的enabled=0修改为enabled=1
#
# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# yum list docker-ce.x86_64 --showduplicates | sort -r
#   Loading mirror speeds from cached hostfile
#   Loaded plugins: branch, fastestmirror, langpacks
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            docker-ce-stable
#   docker-ce.x86_64            17.03.1.ce-1.el7.centos            @docker-ce-stable
#   docker-ce.x86_64            17.03.0.ce-1.el7.centos            docker-ce-stable
#   Available Packages
# Step2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.0.ce.1-1.el7.centos)
# sudo yum -y install docker-ce-[VERSION]

# Step 5: 配置 docker
mkdir -p /etc/docker

cat <<EOF | tee /etc/docker/daemon.json
{
    "registry-mirrors": ["https://docker.m.daocloud.io"],
    "data-root": "/data/docker",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "300m",
        "max-file": "3"
    }
}
EOF

systemctl daemon-reload && systemctl restart docker

```

### Debian

```bash
# 添加 Docker 仓库
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | \
    tee /etc/apt/sources.list.d/docker.list > /dev/null

# 安装最新版本
apt-get install -y docker-ce containerd.io 

# 查看可用版本
# apt-cache madison docker-ce | head -5

# 安装特定版本
# apt-get install -y docker-ce=<VERSION> docker-ce-cli=<VERSION> containerd.io
apt-get install -y docker-ce=5:29.1.2-1~debian.13~trixie containerd.io
```

## Debian 静态 IP 配置

### Debian apt resource

```bash
cat <<EOF > /etc/apt/sources.list
deb http://ftp.cn.debian.org/debian/ trixie main non-free-firmware
deb-src http://ftp.cn.debian.org/debian/ trixie main non-free-firmware

deb http://security.debian.org/debian-security trixie-security main non-free-firmware
deb-src http://security.debian.org/debian-security trixie-security main non-free-firmware

# trixie-updates, to get updates before a point release is made;
# see https://www.debian.org/doc/manuals/debian-reference/ch02.en.html#_updates_and_backports
deb http://ftp.cn.debian.org/debian/ trixie-updates main non-free-firmware
deb-src http://ftp.cn.debian.org/debian/ trixie-updates main non-free-firmware
EOF

```

### 使用 Netplan

```bash

apt-get install -y netplan.io openvswitch-switch

# 备份原因的 interfaces
mv /etc/network/interfaces /etc/network/interfaces.bak

# /etc/netplan/01-netcfg.yaml
mkdir -p /etc/netplan

cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens32:
      dhcp4: no
      addresses:
      - 192.168.99.8/24
      routes:
        - to: default
          via: 192.168.99.2
          on-link: true
      nameservers:
        addresses:
          - 223.5.5.5
      dhcp6: no
EOF

# 修改文件权限，并允许 netplan 的组件服务 systemd-networkd 和 openvswitch-switch 启动
chmod 600 /etc/netplan/01-netcfg.yaml
systemctl enable systemd-networkd
systemctl enable openvswitch-switch

# 应用配置
netplan apply

```

### 传统 NetworkManager 方式

```bash
# /etc/network/interfaces 方式配置静态 IP
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
# allow-hotplug ens32
auto ens32
# iface ens32 inet dhcp
iface ens32 inet static
    address 192.168.99.8
    netmask 255.255.255.0
    gateway 192.168.99.2
    dns-nameservers 192.168.99.2

# 重启网络服务
sudo systemctl restart networking

# 或重启特定接口
sudo ifdown eth0 && sudo ifup eth0

# 设置时区（可选）
sudo timedatectl set-timezone Asia/Shanghai

# 安装防火墙（如果未安装）
sudo apt install -y ufw

# 配置防火墙
sudo ufw allow ssh
sudo ufw --force enable

```

### Netplan 方式配置静态 IP

```bash
# /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    eth0:
      # DHCP 配置
      dhcp4: true
      dhcp6: false
      optional: true
    ens32:
      # 静态 IP 配置
      dhcp4: no
      addresses:
        - 192.168.99.8/24
      gateway4: 192.168.99.2
      nameservers:
        addresses:
          - 192.168.99.2

# 应用配置
sudo netplan apply

```

