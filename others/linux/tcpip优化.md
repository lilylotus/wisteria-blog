
[Linux TCP/IP调优](https://mp.weixin.qq.com/s/gf6-ZUMuFTTtJPkYVrB5-A)

## TCP 协议栈核心参数优化

### 1. TCP 连接管理优化

```bash
# /etc/sysctl.conf 配置文件

# TCP连接队列长度优化
net.core.somaxconn = 65535                    # 增加监听队列长度
net.core.netdev_max_backlog = 30000           # 网卡接收队列长度
net.ipv4.tcp_max_syn_backlog = 65535          # SYN队列长度

# TIME_WAIT状态优化
net.ipv4.tcp_tw_reuse = 1                     # 允许重用TIME_WAIT socket
net.ipv4.tcp_fin_timeout = 30                 # 减少FIN_WAIT_2状态时间
net.ipv4.tcp_max_tw_buckets = 10000           # 限制TIME_WAIT数量

# 连接保活机制
net.ipv4.tcp_keepalive_time = 600             # 开始发送keepalive探测包的时间
net.ipv4.tcp_keepalive_probes = 3             # keepalive探测包数量  
net.ipv4.tcp_keepalive_intvl = 15             # 探测包发送间隔
```

### 2. TCP 缓冲区优化

```bash
# TCP接收/发送缓冲区优化
net.core.rmem_default = 262144                # 默认接收缓冲区大小
net.core.rmem_max = 16777216                  # 最大接收缓冲区大小
net.core.wmem_default = 262144                # 默认发送缓冲区大小
net.core.wmem_max = 16777216                  # 最大发送缓冲区大小

# TCP套接字缓冲区自动调节
net.ipv4.tcp_rmem = 4096 87380 16777216       # TCP读取缓冲区 min default max
net.ipv4.tcp_wmem = 4096 65536 16777216       # TCP写入缓冲区 min default max
net.ipv4.tcp_mem = 94500000 915000000 927000000 # TCP内存分配 low pressure high

# 启用TCP窗口缩放
net.ipv4.tcp_window_scaling = 1               # 支持更大的TCP窗口
```

### 3. TCP 拥塞控制优化

```bash
# 拥塞控制算法选择
net.ipv4.tcp_congestion_control = bbr          # 使用BBR算法（推荐）
# 其他选项：cubic, reno, bic

# 快速重传和恢复
net.ipv4.tcp_frto = 2                          # F-RTO算法检测虚假超时
net.ipv4.tcp_dsack = 1                         # 启用DSACK支持
net.ipv4.tcp_fack = 1                          # 启用FACK拥塞避免

# TCP慢启动阈值
net.ipv4.tcp_slow_start_after_idle = 0         # 禁用空闲后慢启动
```

## 高并发服务的内核参数调优配置

```bash
# 统计各状态连接数
netstat -ant | awk '/^tcp/ {++state[$NF]} END {for(k in state) print k, state[k]}' | sort -k2 -rn

# 使用ss命令（更快）
ss -ant | awk 'NR>1 {++state[$1]} END {for(k in state) print k, state[k]}' | sort -k2 -rn
```

```bash
# https://mp.weixin.qq.com/s/5Ok19ZwSFOk-7HL_KKQNPA
# /etc/sysctl.d/99-tcp-tuning.conf

# 文件描述符
fs.file-max = 2000000
fs.nr_open = 2000000

# 连接跟踪（如果用iptables）
net.netfilter.nf_conntrack_max = 2000000
net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30
net.netfilter.nf_conntrack_tcp_timeout_established = 1200

# 队列大小
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535

# TIME_WAIT
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_max_tw_buckets = 200000
net.ipv4.tcp_fin_timeout = 15

# 端口范围
net.ipv4.ip_local_port_range = 1024 65535

# 缓冲区
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_mem = 786432 1048576 1572864

# TCP选项
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 2
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_keepalive_probes = 3

# 路由缓存
net.ipv4.route.gc_timeout = 100

# 窗口缩放
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
```