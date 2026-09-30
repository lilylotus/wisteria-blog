# iptables 和 firewall-cmd 防火墙命令对照手册

> 说明:iptables 规则默认**不持久化**,重启失效,需配合 `iptables-save`/`netfilter-persistent` 等保存;firewall-cmd 默认操作是**运行时(runtime)**生效,加 `--permanent` 才写入配置文件,两者需配合使用(先 `--permanent` 写入,再 `firewall-cmd --reload` 或同时执行不带 `--permanent` 的命令使其立即生效)。

本文档分两大章节:**第一章 iptables**、**第二章 firewall-cmd**,每章内部按相同的五个小节组织,便于按需查阅同一工具的全部命令。

---

# 第一章 iptables 命令

## 1.1 放行端口(TCP/UDP、端口范围、指定主机 IP)

### 放行单个端口
```bash
# 放行 TCP 80 端口(INPUT 链,允许外部访问本机)
iptables -A INPUT -p tcp --dport 80 -j ACCEPT

# 放行 UDP 53 端口
iptables -A INPUT -p udp --dport 53 -j ACCEPT
```

### 放行端口范围
```bash
# 放行 TCP 8000-9000 范围
iptables -A INPUT -p tcp --dport 8000:9000 -j ACCEPT

# 放行 UDP 30000-31000 范围(常见于游戏服务器/流媒体)
iptables -A INPUT -p udp --dport 30000:31000 -j ACCEPT
```

### 只放行指定源 IP 访问某端口
```bash
# 仅允许 192.168.1.100 访问本机 TCP 22(SSH)
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 22 -j ACCEPT

# 仅允许某个网段访问 TCP 3306(MySQL)
iptables -A INPUT -p tcp -s 10.0.0.0/24 --dport 3306 -j ACCEPT

# 允许指定 IP 访问端口范围
iptables -A INPUT -p tcp -s 192.168.1.100 --dport 8000:9000 -j ACCEPT
```

## 1.2 拒绝放行端口(TCP/UDP、端口范围、指定主机 IP)

> **DROP**(直接丢弃,不响应)和 **REJECT**(拒绝并返回错误)的区别——安全场景通常用 DROP,不给探测者任何反馈。

### 拒绝单个端口
```bash
# 丢弃所有访问 TCP 23(Telnet)的请求
iptables -A INPUT -p tcp --dport 23 -j DROP

# 明确拒绝并返回 TCP RST(会告知对方端口关闭)
iptables -A INPUT -p tcp --dport 23 -j REJECT --reject-with tcp-reset
```

### 拒绝端口范围
```bash
iptables -A INPUT -p tcp --dport 6000:6100 -j DROP
iptables -A INPUT -p udp --dport 6000:6100 -j DROP
```

### 拒绝指定主机 IP 访问某端口
```bash
# 拒绝 192.168.1.200 访问本机 TCP 22
iptables -A INPUT -p tcp -s 192.168.1.200 --dport 22 -j DROP

# 拒绝某网段访问 80 端口
iptables -A INPUT -p tcp -s 172.16.0.0/16 --dport 80 -j DROP

# 完全拉黑某 IP 的所有流量(不限端口)
iptables -A INPUT -s 1.2.3.4 -j DROP
```

> **注意规则顺序**:iptables 规则按添加顺序从上到下匹配,想让"拒绝"规则先于"放行"规则生效,要用 `-I`(insert,插入到最前)而非 `-A`(append,追加到最后),或明确指定行号:
> ```bash
> iptables -I INPUT 1 -s 1.2.3.4 -j DROP   # 插入为第一条规则,优先匹配
> ```

## 1.3 端口转发

### 本机端口转发(如外部访问 8080 实际转发到本机 80)
```bash
# 开启内核 IP 转发(端口转发涉及转发功能建议开启,视场景而定)
echo 1 > /proc/sys/net/ipv4/ip_forward
# 永久生效: 编辑 /etc/sysctl.conf 添加 net.ipv4.ip_forward=1,然后 sysctl -p

# 将访问本机 8080 的流量转发到本机 80(本地端口重定向,用 REDIRECT)
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j REDIRECT --to-port 80

# 若来源是本机自身发起的流量(OUTPUT 链)也需要一条
iptables -t nat -A OUTPUT -p tcp --dport 8080 -j REDIRECT --to-port 80
```

### 转发到其他主机(端口转发到内网另一台服务器)
```bash
# 将访问本机(网关)8080 端口的流量转发到内网 192.168.1.50 的 80 端口
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to-destination 192.168.1.50:80

# 关键:必须配合 FORWARD 链放行,否则转发的包会被拦截
iptables -A FORWARD -p tcp -d 192.168.1.50 --dport 80 -j ACCEPT

# 通常还需要对回程流量做 MASQUERADE(见下方 SNAT 部分),否则目标主机的回包路由不回来
iptables -t nat -A POSTROUTING -p tcp -d 192.168.1.50 --dport 80 -j MASQUERADE
```

## 1.4 SNAT、DNAT 配置

### SNAT(源地址转换,常用于内网多台主机共享一个公网 IP 出网)
```bash
# 固定公网 IP 场景:内网 192.168.1.0/24 出网时统一转换为公网 IP 203.0.113.10
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j SNAT --to-source 203.0.113.10

# 动态公网 IP(如拨号上网,IP 不固定)场景:用 MASQUERADE 代替 SNAT
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
```

### DNAT(目标地址转换,常用于端口映射、将公网请求转发到内网服务器)
```bash
# 将访问本机公网 IP 的 80 端口的请求转发给内网 192.168.1.50 的 8080 端口
iptables -t nat -A PREROUTING -d 203.0.113.10 -p tcp --dport 80 -j DNAT --to-destination 192.168.1.50:8080

# 配合 FORWARD 放行
iptables -A FORWARD -p tcp -d 192.168.1.50 --dport 8080 -j ACCEPT

# 配合出网 SNAT/MASQUERADE,确保内网服务器的回包能正确路由
iptables -t nat -A POSTROUTING -d 192.168.1.50 -p tcp --dport 8080 -j MASQUERADE
```

### 查看当前 NAT 规则
```bash
iptables -t nat -L -n -v --line-numbers
```

## 1.5 其他常用命令

### 查看规则/状态
```bash
iptables -L -n -v --line-numbers        # 查看所有规则(带行号,便于删除)
iptables -S                              # 以命令行格式列出规则(便于复制修改)
iptables -t nat -L -n -v                 # 查看 NAT 表规则
service iptables status                  # 部分发行版(如已装 iptables-services)
```

### 删除规则
```bash
# 按规则内容精确删除(把 -A 改成 -D,其余参数不变)
iptables -D INPUT -p tcp --dport 80 -j ACCEPT

# 按链和行号删除(先用 -L --line-numbers 查看行号)
iptables -D INPUT 3

# 清空整个链(慎用)
iptables -F INPUT

# 清空所有规则(慎用,清空后默认策略生效)
iptables -F
iptables -t nat -F
```

### ICMP(ping)控制
```bash
# 禁止被 ping
iptables -A INPUT -p icmp --icmp-type echo-request -j DROP

# 允许 ping(通常默认允许,除非之前禁用过)
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
```

### 规则持久化 / 服务管理
```bash
# 保存当前规则(Debian/Ubuntu,需先安装 iptables-persistent)
iptables-save > /etc/iptables/rules.v4
netfilter-persistent save

# 保存当前规则(CentOS/RHEL 系,需先安装 iptables-services)
service iptables save
# 或
iptables-save > /etc/sysconfig/iptables

# 重启/开机自启(CentOS 系)
systemctl restart iptables
systemctl enable iptables
```

### 临时测试规则(不写入永久配置,验证效果用)
```bash
# iptables 本身操作默认就是"运行时立即生效",没有区分临时/永久
# 相当于"临时"用完手动 -D 删除即可
iptables -A INPUT -p tcp --dport 8888 -j ACCEPT
# 测试完删除
iptables -D INPUT -p tcp --dport 8888 -j ACCEPT
```

---

# 第二章 firewall-cmd 命令

## 2.1 放行端口(TCP/UDP、端口范围、指定主机 IP)

### 放行单个端口
```bash
# 放行 TCP 80 端口(永久 + 立即生效)
firewall-cmd --permanent --add-port=80/tcp
firewall-cmd --reload

# 放行 UDP 53 端口
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --reload
```

### 放行端口范围
```bash
# 放行 TCP 端口范围
firewall-cmd --permanent --add-port=8000-9000/tcp
firewall-cmd --reload

# 放行 UDP 端口范围
firewall-cmd --permanent --add-port=30000-31000/udp
firewall-cmd --reload
```

### 只放行指定源 IP 访问某端口
```bash
# 方式一:富规则(rich rule),仅允许指定 IP 访问端口(推荐,最直观)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.100" port protocol="tcp" port="22" accept'
firewall-cmd --reload

# 允许网段访问
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="10.0.0.0/24" port protocol="tcp" port="3306" accept'
firewall-cmd --reload

# 方式二:结合 zone,将指定 IP 单独划入一个信任 zone(适合大量规则场景)
firewall-cmd --permanent --new-zone=trusted-hosts
firewall-cmd --permanent --zone=trusted-hosts --add-source=192.168.1.100
firewall-cmd --permanent --zone=trusted-hosts --add-port=22/tcp
firewall-cmd --reload
```

## 2.2 拒绝放行端口(TCP/UDP、端口范围、指定主机 IP)

> firewall-cmd 没有直接的"拒绝端口"命令,常用富规则(rich-rule)实现;`drop` 静默丢弃,`reject` 返回错误。

### 拒绝单个端口
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port protocol="tcp" port="23" drop'
firewall-cmd --reload

# 明确拒绝(返回错误而非静默丢弃)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port protocol="tcp" port="23" reject'
firewall-cmd --reload
```

### 拒绝端口范围
```bash
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port protocol="tcp" port="6000-6100" drop'
firewall-cmd --reload
```

### 拒绝指定主机 IP 访问某端口
```bash
# 拒绝指定 IP 访问指定端口
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.200" port protocol="tcp" port="22" drop'
firewall-cmd --reload

# 完全拉黑某 IP(所有端口/协议)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="1.2.3.4" drop'
firewall-cmd --reload

# 也可用 ipset/黑名单方式(更适合大量 IP)
firewall-cmd --permanent --new-ipset=blacklist --type=hash:ip
firewall-cmd --permanent --ipset=blacklist --add-entry=1.2.3.4
firewall-cmd --permanent --add-rich-rule='rule source ipset="blacklist" drop'
firewall-cmd --reload
```

## 2.3 端口转发

### 本机端口转发(如外部访问 8080 实际转发到本机 80)
```bash
firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80
firewall-cmd --reload
```

### 转发到其他主机(端口转发到内网另一台服务器)
```bash
# 转发到内网其他主机的指定端口
firewall-cmd --permanent --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=192.168.1.50
firewall-cmd --reload

# 若目标 zone 非默认 zone,需确认该转发规则加在正确的 zone 上,例如指定 WAN 口所在 zone:
firewall-cmd --permanent --zone=external --add-forward-port=port=8080:proto=tcp:toport=80:toaddr=192.168.1.50
firewall-cmd --reload

# firewall-cmd 需要 zone 开启 masquerade 配合(见下方 SNAT/DNAT 部分)
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --reload
```

## 2.4 SNAT、DNAT 配置

### SNAT(源地址转换,常用于内网多台主机共享一个公网 IP 出网)
```bash
# firewall-cmd 的思路是给出口 zone 开启 masquerade(适用于动态/固定 IP 均可,底层自动处理)
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --reload

# 查看某 zone 是否已开启 masquerade
firewall-cmd --zone=external --query-masquerade

# firewall-cmd 若需要精确指定 SNAT 到某固定源地址,需用富规则(不常用,通常直接 masquerade 即可)
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" masquerade'
firewall-cmd --reload
```

### DNAT(目标地址转换,常用于端口映射、将公网请求转发到内网服务器)
```bash
# DNAT 本质就是 forward-port 加 toaddr(与端口转发到其他主机一致)
firewall-cmd --permanent --zone=external --add-forward-port=port=80:proto=tcp:toport=8080:toaddr=192.168.1.50
firewall-cmd --permanent --zone=external --add-masquerade
firewall-cmd --reload
```

### 查看当前 NAT 规则
```bash
firewall-cmd --zone=external --list-forward-ports
firewall-cmd --zone=external --query-masquerade
firewall-cmd --list-all-zones      # 查看所有 zone 及其规则概览
```

## 2.5 其他常用命令

### 查看规则/状态
```bash
firewall-cmd --state                     # 查看 firewalld 是否运行
firewall-cmd --list-all                  # 查看当前默认 zone 的全部规则
firewall-cmd --get-active-zones          # 查看当前生效的 zone 及绑定的网卡
firewall-cmd --get-default-zone          # 查看默认 zone
firewall-cmd --list-ports                # 查看当前 zone 放行的端口
firewall-cmd --list-services             # 查看当前 zone 放行的服务
```

### 删除规则
```bash
# 移除端口
firewall-cmd --permanent --remove-port=80/tcp
firewall-cmd --reload

# 移除富规则(需与添加时完全一致的字符串)
firewall-cmd --permanent --remove-rich-rule='rule family="ipv4" source address="192.168.1.200" port protocol="tcp" port="22" drop'
firewall-cmd --reload

# 移除端口转发
firewall-cmd --permanent --remove-forward-port=port=8080:proto=tcp:toport=80
firewall-cmd --reload
```

### 服务(service)管理(比端口更语义化的高层封装)
```bash
# 查看所有预定义服务
firewall-cmd --get-services

# 放行 ssh 服务(等价于放行其对应端口,自带端口定义)
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# 放行 http/https
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# 移除服务
firewall-cmd --permanent --remove-service=http
firewall-cmd --reload
```

### zone(区域)管理
```bash
# 查看所有 zone
firewall-cmd --get-zones

# 查看某网卡属于哪个 zone
firewall-cmd --get-zone-of-interface=eth0

# 把网卡划入指定 zone
firewall-cmd --permanent --zone=internal --change-interface=eth1
firewall-cmd --reload

# 设置默认 zone
firewall-cmd --set-default-zone=public
```

### ICMP(ping)控制
```bash
# 禁止被 ping
firewall-cmd --permanent --add-icmp-block=echo-request
firewall-cmd --reload

# 取消禁止(恢复允许 ping)
firewall-cmd --permanent --remove-icmp-block=echo-request
firewall-cmd --reload
```

### 规则持久化 / 服务管理
```bash
# firewall-cmd 天然区分 runtime 与 permanent,无需额外保存命令
# --permanent 写入配置文件(/etc/firewalld/),立即生效需 reload 或加 --runtime 同时执行

# 将当前 runtime 配置固化为 permanent(常用于临时测试通过后固化)
firewall-cmd --runtime-to-permanent

# 服务管理
systemctl restart firewalld
systemctl enable firewalld
systemctl status firewalld
```

### 临时测试规则(不写入永久配置,验证效果用)
```bash
# 不加 --permanent 即为临时规则,firewalld 重启或 reload 后失效,适合快速测试
firewall-cmd --add-port=8888/tcp
# 测试完可直接不管(重启服务/系统后自动消失),或手动移除
firewall-cmd --remove-port=8888/tcp
```

---

# 附:iptables vs firewall-cmd 关键概念对照表

| 概念 | iptables | firewall-cmd |
|---|---|---|
| 规则生效范围 | 立即生效,重启丢失(需手动 save) | 分 runtime(立即,重启丢失)和 permanent(写入配置,需 reload 生效) |
| 分组管理 | 无原生分组,靠链(chain)组织 | 按 zone(区域)分组,不同网卡/来源可属不同 zone,策略互不影响 |
| 端口拒绝 | 天然支持 DROP/REJECT | 需用富规则(rich-rule)实现,没有直接的 --remove-port 式拒绝命令 |
| 服务语义 | 无,纯端口/协议 | 内置 service 预定义(ssh/http等),语义化更强 |
| 底层实现 | 直接操作 netfilter 规则表 | 现代版本底层也是基于 nftables(或旧版 iptables),是更高层的管理工具 |
| 适用场景 | 需要精细控制规则顺序、复杂链式逻辑 | 日常运维快速配置,尤其多网卡/多信任域场景更直观 |

## 常见操作口诀总结

- **iptables**:改完记得 `save`,规则顺序从上到下,想优先生效用 `-I` 插入
- **firewall-cmd**:改完记得 `--reload`,永久配置记得加 `--permanent`,精细规则(限 IP、拒绝)首选富规则(rich-rule)
- **转发类操作(端口转发/DNAT)**:必须同时考虑 FORWARD 放行 + 回程 SNAT/MASQUERADE,否则单向不通
