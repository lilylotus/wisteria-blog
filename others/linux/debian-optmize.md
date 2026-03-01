
## Debian 安装优化

[镜像下载](https://cdimage.debian.org/cdimage/archive/)

### 使用国内源

[清华镜像源](https://mirrors.tuna.tsinghua.edu.cn/help/debian/)

[腾讯镜像源](https://mirrors.cloud.tencent.com/help/debian.html)

[中科大USTC镜像源](https://mirrors.ustc.edu.cn/help/debian.html)

传统格式 （`/etc/apt/sources.list`）

```bash
# /etc/apt/sources.list : debian 13 (trixie)
cat <<EOF > /etc/apt/sources.list
# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
deb http://mirrors.tencent.com/debian/ trixie main contrib non-free non-free-firmware
# deb-src http://mirrors.tencent.com/debian/ trixie main contrib non-free non-free-firmware

deb http://mirrors.tencent.com/debian/ trixie-updates main contrib non-free non-free-firmware
# deb-src http://mirrors.tencent.com/debian/ trixie-updates main contrib non-free non-free-firmware

deb http://mirrors.tencent.com/debian/ trixie-backports main contrib non-free non-free-firmware
# deb-src http://mirrors.tencent.com/debian/ trixie-backports main contrib non-free non-free-firmware

# 以下安全更新软件源包含了官方源与镜像站配置，如有需要可自行修改注释切换
deb https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
# deb-src https://security.debian.org/debian-security trixie-security main contrib non-free non-free-firmware
EOF
```

DEB822 格式（`/etc/apt/sources.list.d/debian.sources`）

```bash
# /etc/apt/sources.list.d/debian.sources : debian 13 (trixie)
cat <<EOF > /etc/apt/sources.list.d/debian.sources
Types: deb
URIs: http://mirrors.tencent.com/debian/
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://security.debian.org/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
```

### 静态 IP 配置

Debian 的 `networking` 服务的 `/etc/network/interfaces` 网络配置文件

- `allow-hotplug`：按需激活 (设备可用时)，不能使用重启服务的方式触发
- `auto`：auto 可以用重启服务的方式触发

```bash
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto ens32
# face ens32 inet dhcp
iface ens32 inet static
    address 192.168.99.8
    netmask 255.255.255.0
    gateway 192.168.99.2
```

配置 DNS 解析

```bash
cat <<EOF >> /etc/resolv.conf
nameserver 223.5.5.5
EOF
```

重启网络服务

```bash
# 重启网络服务
systemctl restart networking

# 或重启特定接口
ifdown eth0 && ifup eth0

# 设置时区（可选）
timedatectl set-timezone Asia/Shanghai
```

`Netplan` 方式配置静态 IP

```bash
# /etc/netplan/01-netcfg.yaml
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
```

### Debian Docker 安装

卸载旧版本

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc podman-docker containerd runc | cut -f1)
```

配置 Docker 官方源

```bash
# Add Docker's official GPG key:
apt update
apt install -y ca-certificates curl gpg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.tuna.tsinghua.edu.cn/docker-ce/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Add the repository to Apt sources:
tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

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

配置 Docker 镜像加速器及存储位置

```bash
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

### 内核参数优化

```bash
# 更新内核网络参数
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

# linux 内核配置参数
cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

# 修改 swap 虚拟内存的使用规则，设置为 10 说明当内存使用量超过 90% 才会使用 swap 空间
echo "10" > /proc/sys/vm/swappiness

# 设置系统打开文件最大数
cat >> /etc/security/limits.conf <<EOF
* soft nofile 65535
* hard nofile 65535
EOF
```

