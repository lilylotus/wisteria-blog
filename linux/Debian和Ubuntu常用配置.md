# Debain/Ubuntu配置

## Ubuntu静态IP配置

Ubuntu 从 17.10 开始默认使用 **netplan** 管理网络配置，不再是传统的 `/etc/network/interfaces` 方式（那是 Debian/老版本 Ubuntu 的方式）。Ubuntu 26 同样遵循这套机制。

### netplan 管理网络配置

#### 确认网卡名

```bash
ip addr show
# 或
ip link show
```

记下网卡名（假设是 `ens18`，请替换成实际名称）。

#### 确认 netplan 配置文件位置

```bash
ls /etc/netplan/
```

通常会看到类似 `00-installer-config.yaml` 或 `50-cloud-init.yaml` 这样的文件。

#### 编辑配置文件

```bash
sudo vi /etc/netplan/00-installer-config.yaml
```

根据参数`255.255.255.0` 换算成 CIDR 是 **/24**（这里要注意，netplan 用的是 CIDR 表示法，不是子网掩码字符串）。

网卡名 `ens18` 要替换成你第一步查到的实际网卡名。

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: false
      addresses:
        - 10.10.10.10/24
      routes:
        - to: default
          via: 10.10.10.1
      nameservers:
        addresses:
          - 223.5.5.5
```

默认dhcp配置

```yaml
network:
  version: 2
  ethernets:
    ens18:
      set-name: ens18
      dhcp4: true
      dhcp6: true
      match:
        macaddress: bc:24:11:4e:d4:6b
```

如果你不放心换算是否正确，可以用命令验证：

```bash
ipcalc 10.10.10.10 255.255.255.0
```

如果没有 `ipcalc` 工具：

```bash
sudo apt install -y ipcalc
```

#### 检查配置文件语法

重要，避免直接 apply 后网络中断

```bash
sudo netplan try
```

这个命令会应用配置并倒计时等待确认，如果新配置导致网络不通，**120 秒后会自动回滚**，避免你因为配置错误被锁在服务器外面连不上（尤其是远程 SSH 操作时非常重要）。

看到提示后按 **Enter** 确认保留配置。

#### 正式应用配置

```bash
sudo netplan apply
```

#### 验证

```bash
ip addr show ens18
ip route show
ping -c 4 223.5.5.5
```

### 常见问题

#### 问题一：`Permission denied` 或文件权限告警

```bash
sudo chmod 600 /etc/netplan/00-installer-config.yaml
```

netplan 要求配置文件权限严格（避免明文密码类信息泄露风险），权限过于开放会有告警提示，不影响功能但建议按要求设置。

#### 问题二：`renderer` 该用 `networkd` 还是 `NetworkManager`

- **服务器版 Ubuntu**（无桌面）：默认用 `networkd`，用上面的配置即可
- **桌面版 Ubuntu**：默认用 `NetworkManager`，也可以用 netplan 配置，但建议改用图形界面的网络设置，或者确认 renderer 保持和系统默认一致，避免两者冲突

检查当前系统默认渲染器：

```bash
cat /etc/netplan/*.yaml | grep renderer
```

#### 问题三：如果只想临时测试网络连通，不想改配置文件

```bash
sudo ip addr add 10.4.100.124/18 dev eth0
sudo ip route add default via 10.4.64.1
```

这种方式重启后失效，仅用于临时验证网络参数是否正确，正式生效还是要走 netplan 配置文件方式。

#### 问题四：如果配置后 DNS 不生效

Ubuntu 服务器版默认用 `systemd-resolved` 管理 DNS，检查实际生效的 DNS：

```bash
resolvectl status
```

如果 `/etc/resolv.conf` 显示的不是你配置的 `223.5.5.5`，说明走的是 `systemd-resolved` 的解析链路，这是正常现象（`/etc/resolv.conf` 通常是指向 `127.0.0.53` 的 stub resolver），不代表配置没生效，`resolvectl status` 里能看到实际使用的上游 DNS 才是准确的验证方式。



## Debian静态ip配置

Debian 和 Ubuntu 不同，**默认不使用 netplan**（netplan 是 Ubuntu 专属）。Debian 传统上用 `ifupdown`（`/etc/network/interfaces`），但如果安装时选了桌面环境，通常默认走 **NetworkManager**。

所以要先确认你这台机器实际用的是哪套网络管理方式

```bash
# 查看是否安装并启用了 NetworkManager
systemctl status NetworkManager

# 查看 networking 服务（ifupdown）状态
systemctl status networking
```

- 如果 `NetworkManager` 是 `active (running)` → 走**桌面环境使用方案**
- 如果只有 `networking` 服务在管理网络（常见于 `Server` 版最小化安装） → 走**服务器安装使用方案**

### 桌面环境使用 NetworkManager（`nmcli`）

桌面环境

#### 查看网卡名和当前连接

```bash
nmcli device status
nmcli connection show
```

#### 配置静态 IP

```bash
sudo nmcli connection modify "有线连接 1" \
  ipv4.addresses 10.10.100.124/24 \
  ipv4.gateway 10.10.100.1 \
  ipv4.dns "223.5.5.5" \
  ipv4.method manual
```

`"有线连接 1"` 替换成 `nmcli connection show` 查出来的实际连接名（也可能是 `Wired connection 1` 或自定义名字）。

#### 重启连接使配置生效

```bash
sudo nmcli connection down "有线连接 1"
sudo nmcli connection up "有线连接 1"
```

#### 验证

```bash
ip addr show
ip route show
nmcli device show | grep -i dns
```

------

### 服务器安装使用传统 `ifupdown`（`/etc/network/interfaces`）

#### 查看网卡名

```bash
ip addr show
```

#### 编辑配置文件

```bash
sudo vi /etc/network/interfaces
```

写入（假设网卡是 `ens192`，替换成实际网卡名）：

```properties
source /etc/network/interfaces.d/*

# 回环接口
auto lo
iface lo inet loopback

# 静态IP配置
auto ens192
iface ens192 inet static
    address 10.10.88.31
    netmask 255.255.255.0
    gateway 10.10.88.1
    dns-nameservers 223.5.5.5
```

> 注意这里 Debian 传统写法用的是 `netmask`（子网掩码字符串格式），**不像 netplan 那样需要转成 CIDR**，直接写 `255.255.255.0` 即可，不用换算成 `/24`。

默认配置

```properties
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
allow-hotplug ens192
iface ens192 inet dhcp

```

#### 确认 DNS 配置生效方式

让 `dns-nameservers` 生效需要确认装了 `resolvconf`

```bash
dpkg -l | grep resolvconf
```

如果没装，DNS 配置不会自动写入 `/etc/resolv.conf`：

```bash
apt install resolvconf
```

最小化安装通常**没有** `resolvconf` 包，`dns-nameservers` 这行不会自动生效，直接手动写 `/etc/resolv.conf` 更省事：

```bash
sudo vi /etc/resolv.conf
nameserver 223.5.5.5
```

#### 重启网络服务使配置生效

```bash
systemctl restart networking
```

如果这条命令没反应或报错（部分 Debian 版本 `networking.service` 对某些网卡类型支持不完整），改用重启网卡接口的方式：

```bash
sudo ifdown eth0 && sudo ifup eth0
```

#### 验证

```bash
ip addr show eth0
ip route show
cat /etc/resolv.conf
```

------

### 通用验证（两种方案都适用）

```bash
ping -c 4 10.4.64.1      # 测试网关连通性
ping -c 4 223.5.5.5      # 测试 DNS 服务器连通性
ping -c 4 baidu.com       # 测试域名解析是否正常
```



## Ubuntu镜像源配置

默认官方镜像源：官方源通常同步最及时，尤其是刚发布的新版本，国内镜像站可能还没跟上，虽然速度可能比国内镜像慢，但胜在稳定可靠，适合新版本刚发布阶段使用。

```
http://archive.ubuntu.com/ubuntu
```

### 推荐国内镜像站

#### ustc中科大

[ustc中科大Ubuntu各版本镜像源配置链接](https://mirrors.ustc.edu.cn/help/ubuntu.html#_7)

DEB822 格式、Ubuntu 26.04 LTS (`/etc/apt/sources.list.d/ustc.sources`)

```properties
Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.ustc.edu.cn/ubuntu
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

#### 清华大学

[清华大学Ubuntu各版本镜像源配置链接](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu/)

DEB822 格式（`/etc/apt/sources.list.d/tsinghua.sources`）

```properties
cat <<EOF > /etc/apt/sources.list.d/tsinghua.sources
Types: deb
URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
Suites: resolute resolute-updates resolute-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 默认注释了源码镜像以提高 apt update 速度，如有需要可自行取消注释
# Types: deb-src
# URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu
# Suites: resolute resolute-updates resolute-backports
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# 以下安全更新软件源为官方源配置
Types: deb
URIs: http://security.ubuntu.com/ubuntu/
Suites: resolute-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

# Types: deb-src
# URIs: http://security.ubuntu.com/ubuntu/
# Suites: resolute-security
# Components: main restricted universe multiverse
# Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```

#### 阿里云

[阿里云Ubuntu各版本镜像源配置链接](https://developer.aliyun.com/mirror/ubuntu)

ubuntu 26.04 (resolute) DEB822 格式 (`/etc/apt/sources.list.d/aliyun.sources`)

```properties
cat <<EOF > /etc/apt/sources.list.d/aliyun.sources
Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: resolute resolute-updates resolute-backports
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: https://mirrors.aliyun.com/ubuntu
Suites: resolute-security
Components: main universe restricted multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
EOF
```

### 常见问题

#### apt-get update报连接异常

```
Reading from proxy failed - read (115: Operation now in progress) [IP: 91.189.91.82 443]
Reading from proxy failed - read (115: Operation now in progress) [IP: 185.125.190.82 443]
```

这里的报错信息明确写了 **"Reading from proxy failed"**——说明当前 apt 配置了一个 HTTP/HTTPS 代理，请求先发给这个代理，代理再转发出去，但这个代理连接**卡住了**（错误码 115 = `EINPROGRESS`，表示非阻塞连接一直没建立成功，处于"进行中但没完成"的状态，通俗说就是代理那头没响应/连不通）。

而且这几个 IP（`91.189.91.82`、`185.125.190.82`）实际上是 **Canonical 官方镜像网络段**的 IP，不是清华源自己的服务器——这说明请求其实已经被代理转发到了官方源那边，但代理本身网络状态异常，卡在半路，不是镜像站不可用的问题。

##### 排查可能原因一：安装程序在网络配置阶段填过代理地址

Ubuntu Server 安装向导（尤其是走 netinst/live installer）中，网络配置步骤通常会有一个可选的**"HTTP proxy"**填写项。如果这里填了代理地址（或者被答案文件/预置配置自动填了），apt 就会强制走这个代理，一旦代理服务本身有问题，所有 apt 操作都会卡死。

##### 排查可能原因二：系统环境变量里残留了代理设置

```bash
echo $http_proxy
echo $https_proxy
env | grep -i proxy
```

##### 排查可能原因三：apt 配置文件里写死了代理

```bash
cat /etc/apt/apt.conf.d/*proxy*
grep -r "Proxy" /etc/apt/apt.conf.d/
cat /etc/apt/apt.conf 2>/dev/null
```



##### 解决方案第一步：清除代理配置

如果找到了代理相关的 apt 配置文件

```bash
sudo rm /etc/apt/apt.conf.d/*proxy*
```

如果是环境变量导致的：

```bash
unset http_proxy
unset https_proxy
unset HTTP_PROXY
unset HTTPS_PROXY
```

**如果是安装程序界面里填的代理地址**：需要回到网络配置那一步，把 HTTP proxy 输入框**清空**，不要填任何内容，重新继续安装流程。

##### 解决方案第二步：清空后重新测试

```bash
sudo apt update
```

如果这次不再出现 "Reading from proxy failed"，问题就解决了。

## Debian镜像源配置

### 国内推荐镜像站

#### ustc中科大

[ustc中科大Debian各版本镜像配置链接](https://mirrors.ustc.edu.cn/help/debian.html)

/etc/apt/sources.list.d/debian.sources （**DEB822格式** ）Debian13

```
Types: deb
URIs: http://mirrors.ustc.edu.cn/debian
Suites: trixie trixie-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://mirrors.ustc.edu.cn/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

### 阿里云镜像站

Debian 13 （trixie）

```
sudo vi /etc/apt/sources.list.d/debian.sources
```

```bash
Types: deb
URIs: https://mirrors.aliyun.com/debian
Suites: trixie trixie-updates trixie-backports
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: https://mirrors.aliyun.com/debian-security
Suites: trixie-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```



## apt和apt-get推荐使用哪个

`apt` vs `apt-get`：日常使用推荐 `apt`

### 核心结论

**交互式命令行操作（人工敲命令）推荐用 `apt`**；**脚本/自动化场景（Dockerfile、CI/CD、Shell 脚本）推荐用 `apt-get`**。

------

### 为什么日常推荐 `apt`

`apt` 是 2014 年左右（Ubuntu 16.04/Debian 8 起）引入的命令，本质是把 `apt-get`、`apt-cache`、`apt-config` 等多个工具的常用功能**整合成一个更友好的命令**，专门为人工交互场景优化：

| 特性               | `apt`                              | `apt-get`                              |
| ------------------ | ---------------------------------- | -------------------------------------- |
| 彩色输出           | ✅ 有                               | ❌ 无                                   |
| 进度条             | ✅ 有（下载进度可视化）             | ❌ 无                                   |
| 命令更简洁         | ✅（`apt list`、`apt search` 内置） | 需要配合 `apt-cache search` 等其他命令 |
| 输出信息更精简易读 | ✅                                  | 信息更冗长                             |

#### 命令对比示例

```bash
# 更新软件包列表
apt update                  # 推荐
apt-get update              # 效果一样，输出更朴素

# 升级系统
apt upgrade
apt-get upgrade

# 安装软件
apt install nginx
apt-get install nginx

# 搜索软件包（apt 更方便，不需要额外命令）
apt search nginx            # apt 自带
apt-cache search nginx      # apt-get 时代需要用这个配套命令

# 查看软件包详情
apt show nginx
apt-cache show nginx
```

------

### 为什么脚本/自动化场景推荐 `apt-get`

```bash
# Dockerfile 里的典型写法
RUN apt-get update && apt-get install -y curl
```

原因很直接：**`apt` 命令的官方 man 手册和开发者明确声明，它的命令行接口（输出格式、参数细节）不保证跨版本稳定**，是为人类交互设计的，可能会在不同版本间调整展示效果。而 `apt-get` / `apt-cache` 是更底层、更稳定的老牌工具，接口行为长期保持一致，**适合写进脚本被程序解析或依赖**，不会因为系统升级导致脚本输出格式变化而出问题。

### 实际经验总结

| 场景                                           | 推荐                                                         |
| ---------------------------------------------- | ------------------------------------------------------------ |
| 你自己在终端手动敲命令装软件、查软件           | `apt`                                                        |
| 写 Dockerfile                                  | `apt-get`                                                    |
| 写 Shell 自动化脚本（尤其是要解析 apt 输出的） | `apt-get`                                                    |
| Ansible/Puppet 等运维工具里                    | 用工具自带的包管理模块（如 Ansible 的 `apt` 模块），不直接调命令行 |

------

### 底层关系说明

`apt`、`apt-get`、`apt-cache` 都是基于同一套底层库（libapt-pkg）实现的，功能上高度重叠，**装同一个包，效果完全一样**，只是命令行体验和使用场景定位不同，不存在谁"更强"的问题，纯粹是"面向人 vs 面向脚本"的分工。



## docker安装

### docker配置

`/etc/docker/daemon.json`

```bash
$ sudo vi /etc/docker/daemon.json
```

```json
{
  "registry-mirrors": [
    "https://docker.m.daocloud.io"
  ],
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  },
  "storage-driver": "overlay2",
  "live-restore": true,
  "max-concurrent-downloads": 10,
  "max-concurrent-uploads": 5,
  "default-address-pools": [
    {
      "base": "172.20.0.0/16",
      "size": 24
    }
  ]
}
```

```bash
systemctl daemon-reload && systemctl restart docker
```

调整用户组到 docker

```bash
# centos 可以使用此命令
$ sudo chgpasswd -a luck docker

# 1. 添加 luck 到 docker 组（作为附加组）
sudo usermod -aG docker luck
# 2. 切换当前用户组
# 立即切换当前 shell 会话的有效主组，不需要退出重新登录就能让新的组权限生效
$ newgrp docker
```

### ubuntu

#### 阿里云

```bash
# step 1: 安装必要的一些系统工具
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# step 2: 信任 Docker 的 GPG 公钥
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Step 3: 写入软件源信息
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://mirrors.aliyun.com/docker-ce/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
 
# Step 4: 安装Docker
sudo apt-get update
sudo apt-get install -y docker-ce

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
# apt-cache madison docker-ce
#   docker-ce | 17.03.1~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
#   docker-ce | 17.03.0~ce-0~ubuntu-xenial | https://mirrors.aliyun.com/docker-ce/linux/ubuntu xenial/stable amd64 Packages
# Step 2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.1~ce-0~ubuntu-xenial)
# sudo apt-get -y install docker-ce=[VERSION]
```

#### 官方源

##### 卸载旧版本

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-compose-v2 docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

##### 配置镜像仓库

```bash
# Add Docker's official GPG key:
sudo apt update
sudo apt install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt update
```

##### 安装最新版

```bash
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

##### 安装指定版本

```bash
$ apt list --all-versions docker-ce

docker-ce/bookworm 5:29.7.2-1~debian.12~bookworm <arch>
docker-ce/bookworm 5:29.7.1-1~debian.12~bookworm <arch>

docker-ce/resolute 5:29.7.2-1~ubuntu.26.04~resolute amd64
docker-ce/resolute 5:29.6.2-1~ubuntu.26.04~resolute amd64
...

$ VERSION_STRING=5:29.6.2-1~debian.13~trixie
$ sudo apt install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
$ apt install -y docker-ce=5:29.6.2-1~ubuntu.26.04~resolute
```



### Debian

#### 官方源安装

##### 卸载旧版本（如果有）

```bash
sudo apt remove $(dpkg --get-selections docker.io docker-compose docker-doc docker-buildx podman-docker containerd runc | cut -f1)
```

##### 安装依赖

```bash
apt update
apt install -y ca-certificates curl gnupg
```

##### 添加 Docker 官方 GPG 密钥

```bash
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

##### 添加软件源

```bash
# Add the repository to Apt sources:
sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
```

这条命令会**自动识别**当前系统的版本代号（Debian 13 应为 `trixie`）并写入配置。

##### 更新并安装

```bash
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

##### 安装指定版本

```bash
$ apt list --all-versions docker-ce

docker-ce/bookworm 5:29.7.2-1~debian.12~bookworm <arch>
docker-ce/bookworm 5:29.7.1-1~debian.12~bookworm <arch>

docker-ce/trixie 5:29.7.2-1~debian.13~trixie amd64
docker-ce/trixie 5:29.6.2-1~debian.13~trixie amd64
...

$ VERSION_STRING=5:29.6.2-1~debian.13~trixie
$ sudo apt install docker-ce=$VERSION_STRING docker-ce-cli=$VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin
$ apt install docker-ce=5:29.6.2-1~debian.13~trixie
```

## 时钟同步

### Debian/Ubuntu

Debian 默认使用 **systemd-timesyncd** 作为轻量级 NTP 客户端，最小化安装通常已经预装。下面给出完整配置流程。

Ubuntu 和 Debian 一样默认使用 **systemd-timesyncd**，配置方式基本一致。

#### 默认systemd-timesyncd配置

##### 确认时区正确（同步时间前先确认时区）

```bash
timedatectl status
```

如果时区不对（比如显示 UTC 但你需要中国时区）

```bash
sudo timedatectl set-timezone Asia/Shanghai
```

查看所有可用时区（如果不确定名称）：

```bash
timedatectl list-timezones | grep -i shanghai
```

##### 确认 `systemd-timesyncd` 是否已安装并运行

```bash
systemctl status systemd-timesyncd
```

如果没安装：

```bash
sudo apt install -y systemd-timesyncd
```

启用并启动：

```bash
sudo systemctl enable systemd-timesyncd --now
```

##### 配置 NTP 服务器（推荐用国内可用的时间源）

```bash
sudo vi /etc/systemd/timesyncd.conf
```

```ini
[Time]
NTP=ntp.aliyun.com ntp1.aliyun.com
FallbackNTP=cn.pool.ntp.org ntp.tencent.com
```

- `NTP=` 主要使用的时间服务器（可以填多个，空格分隔）
- `FallbackNTP=` 主服务器都连不上时的备用服务器

##### 常用国内时间源参考

```
ntp.aliyun.com          阿里云
ntp1.aliyun.com ~ ntp7.aliyun.com
ntp.tencent.com          腾讯云
cn.pool.ntp.org          NTP Pool 中国区
time.windows.com         微软（国际通用，国内也可用）
```

##### 重启服务使配置生效

```bash
sudo systemctl restart systemd-timesyncd
```

##### 启用自动同步开关

```bash
sudo timedatectl set-ntp true
```

##### 验证同步状态

```bash
timedatectl status
```

关键看这两行：

```
System clock synchronized: yes
              NTP service: active
```

`System clock synchronized: yes` 说明已经和 NTP 服务器对齐成功。

##### 更详细的同步日志

```bash
timedatectl timesync-status
```

会显示当前连接的服务器、时间偏差、上次同步时间等详细信息。

##### 查看服务日志（排查同步失败问题）

```bash
journalctl -u systemd-timesyncd -f
```

### 通用chrony时间同步配置

Debian 默认预装的是 `systemd-timesyncd`，不是 **chrony**，需要先手动安装并切换。

#### 安装 chrony 并禁用默认的 timesyncd

```bash
$ sudo apt update
$ sudo apt install -y chrony

$ sudo systemctl status chrony
# 应用配置
$ sudo systemctl restart chrony
$ sudo systemctl enable chrony

# 避免两者冲突，禁用系统默认的 timesyncd
$ sudo systemctl disable systemd-timesyncd --now
```

#### 编辑配置文件

```bash
sudo vi /etc/chrony/chrony.conf
```

Debian 默认配置文件里已经有 `pool 2.debian.pool.ntp.org iburst` 这类条目，国内访问不够稳定，替换成国内时间源：

```ini
# 注释或删除默认的 debian pool 源
# pool 2.debian.pool.ntp.org iburst

# 替换为国内时间源
server ntp.aliyun.com iburst prefer
server ntp1.aliyun.com iburst
server ntp.tencent.com iburst
server cn.pool.ntp.org iburst

# 时钟漂移文件
driftfile /var/lib/chrony/chrony.drift

# 时间步进策略：启动阶段允许最多3次瞬间跳变校正，之后只做平滑调整
makestep 1.0 3

# 硬件时钟同步
rtcsync

# 日志目录（Debian 默认路径）
logdir /var/log/chrony
```

#### 重启并启用服务

```bash
$ sudo systemctl restart chrony
$ sudo systemctl enable chrony
```

#### 验证

```bash
# 查看服务状态
systemctl status chrony

# 查看正在使用的时间源
chronyc sources -v

# 查看详细同步精度
chronyc tracking

# 确认整体同步状态
timedatectl status
```

`timedatectl status` 里看到：

```
System clock synchronized: yes
```

说明同步正常（即使系统实际用的是 chrony 而不是 timesyncd，`timedatectl` 依然能正确显示整体同步状态，因为它是通过 D-Bus 读取系统级的时间同步状态，不局限于哪个具体服务）。

#### chrony验证清单

##### 查看当前使用的时间源状态

```bash
chronyc sources -v
```

输出示例解读：

```
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* ntp.aliyun.com                 2   6   377    23    +120us[+180us] +/-   15ms
^+ ntp1.aliyun.com                2   6   377    45    +200us[+250us] +/-   18ms
```

- `^*` 表示当前**正在使用**的主时间源（最优选择）
- `^+` 表示候选源（也在正常同步，但不是当前首选）
- `Reach` 377（八进制，等于全 1）表示最近 8 次探测全部成功，源状态健康

##### 查看同步精度追踪信息

```bash
chronyc tracking
```

重点关注：

```
Leap status     : Normal
System time     : 0.000012345 seconds slow of NTP time
RMS offset      : 0.000234567 seconds
```

`System time` 偏差应该是毫秒甚至微秒级别，数值越小说明同步精度越高。

##### 检查是否真正处于"已同步"状态

```bash
timedatectl status
```

确认：

```
System clock synchronized: yes
```

#### Debian 和 Ubuntu 的差异点小结

|                     | Debian                    | Ubuntu                                     |
| ------------------- | ------------------------- | ------------------------------------------ |
| 默认时间同步服务    | systemd-timesyncd         | systemd-timesyncd（云镜像可能预装 chrony） |
| chrony 是否默认安装 | 否，需要手动装            | 视具体镜像而定，需要先检查                 |
| 配置文件路径        | `/etc/chrony/chrony.conf` | 相同                                       |
| 服务名              | `chrony`                  | 相同                                       |

#### 生产环境完整配置（含内网时间服务器场景）

如果这台机器就是你之前提到的 `10.10.88.124` 那台 Debian 13 服务器，且需要作为内网其他机器的统一时间基准：

```ini
server ntp.aliyun.com iburst prefer
server ntp1.aliyun.com iburst
server ntp.tencent.com iburst

driftfile /var/lib/chrony/chrony.drift
makestep 1.0 3
rtcsync
logdir /var/log/chrony

# 允许内网这个网段的机器向本机同步时间
allow 10.10.88.0/24
local stratum 10
```

其他内网机器指向这台机器即可：

```ini
server 10.10.88.124 iburst prefer
```

### 注意/提醒

#### Ubuntu 特有的一点提醒：可能存在 `chrony` 冲突

Ubuntu 某些镜像（尤其是云平台官方镜像，如阿里云/腾讯云 Ubuntu 镜像）会**默认预装并启用 `chrony`** 而不是 `systemd-timesyncd`，两者不能同时运行，否则会互相冲突导致同步异常。

##### 先检查是否已经在用 chrony

```bash
systemctl status chrony
```

如果 `chrony` 是 `active (running)` 状态，说明系统实际用的是 chrony，这种情况下推荐直接配置 chrony（如果已经在用，保持现状更简单）。

## Debian/Ubuntu初始化

### 系统更新与基础软件

```bash
sudo apt update
sudo apt upgrade -y
sudo apt install -y \
    vim curl wget git \
    net-tools htop iotop \
    unzip zip tar \
    sudo \
    ca-certificates gnupg lsb-release \
    tree lsof
```

------

### 安全加固（生产环境重点）

#### 1. 创建普通管理用户，禁止 root 直接远程登录

```bash
# 创建管理用户
sudo adduser opsadmin
sudo usermod -aG sudo opsadmin
```

编辑 SSH 配置：

```bash
sudo vi /etc/ssh/sshd_config
```

```bash
# 禁止 root 直接登录
PermitRootLogin no

# 修改默认端口（可选，减少扫描攻击噪音，非核心防护手段）
Port 50022

# 禁用密码登录，强制使用密钥（配好密钥后再开启，避免把自己锁在外面）
# PasswordAuthentication no

# 限制登录尝试
MaxAuthTries 3
LoginGraceTime 30

# 只允许指定用户/组登录
AllowUsers opsadmin
```

```bash
sudo systemctl restart sshd
```

⚠️ **重要**：修改 SSH 端口和 `PermitRootLogin` 之前，**先用新终端窗口测试新配置能否正常连接**，确认无误后再关闭旧的连接方式，避免把自己锁在服务器外面。

#### 2. 配置 SSH 密钥登录（推荐,替代密码登录）

bash

```bash
# 本地生成密钥对（在你的本机操作，不是服务器）
ssh-keygen -t ed25519 -C "opsadmin@server"

# 上传公钥到服务器
ssh-copy-id -p 50022 opsadmin@10.4.100.124
```

确认密钥登录正常后，再回服务器上启用 `PasswordAuthentication no`。

#### 3. 配置防火墙

Debian 默认没有像 CentOS 那样的 firewalld，推荐用 `ufw`（简化版 iptables 管理工具）：

```bash
sudo apt install -y ufw

# 设置默认策略
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 放行必要端口（按实际服务调整）
sudo ufw allow 22/tcp    # SSH（对应上面改的端口）
sudo ufw allow 80/tcp       # HTTP
sudo ufw allow 443/tcp      # HTTPS

sudo ufw enable
sudo ufw status verbose
```

#### 4. 内核安全参数调优

优先加载模块

```bash
# 检查模块是否已加载
lsmod | grep br_netfilter

# 如果没加载，手动加载
sudo modprobe br_netfilter

# 持久化，确保开机自动加载
echo 'br_netfilter' | sudo tee /etc/modules-load.d/container.conf

# 同时建议一并加载 overlay 模块（容器 overlay 文件系统需要）：

sudo modprobe overlay
echo -e 'overlay\nbr_netfilter' | sudo tee /etc/modules-load.d/container.conf
```

内核参数调优 `/etc/sysctl.d/99-container.conf`

```ini
# ============================================
# 网络转发（K8s Pod 间通信必需）
# ============================================
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# ============================================
# 桥接网络 iptables 生效（K8s 强制要求，非常关键）
# ============================================
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-arptables = 1

# ============================================
# 连接跟踪表（高并发容器场景必调，默认值太小）
# ============================================
net.netfilter.nf_conntrack_max = 1000000
net.nf_conntrack_max = 1000000
net.netfilter.nf_conntrack_tcp_timeout_established = 3600
net.netfilter.nf_conntrack_buckets = 250000

# ============================================
# TCP 连接优化
# ============================================
# 加快 TIME_WAIT 状态连接的回收
net.ipv4.tcp_tw_reuse = 1
# 缩短 FIN_WAIT2 超时时间
net.ipv4.tcp_fin_timeout = 15
# 增大半连接队列，应对突发连接请求
net.ipv4.tcp_max_syn_backlog = 8192
# SYN 洪水攻击防护
net.ipv4.tcp_syncookies = 1
# 增大 TCP 端口范围，容器高并发出站连接需要
net.ipv4.ip_local_port_range = 1024 65535
# keepalive 相关调优
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 30
net.ipv4.tcp_keepalive_probes = 10

# ============================================
# 网络缓冲区（容器网络吞吐优化）
# ============================================
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216

# ============================================
# 网络设备队列长度（应对高并发网络包）
# ============================================
net.core.netdev_max_backlog = 16384
net.core.somaxconn = 32768

# ============================================
# ARP 缓存（大规模集群/多网卡场景，Pod 数量多时容易 ARP 表溢出）
# ============================================
net.ipv4.neigh.default.gc_thresh1 = 4096
net.ipv4.neigh.default.gc_thresh2 = 8192
net.ipv4.neigh.default.gc_thresh3 = 16384

# ============================================
# inotify 监听限制（K8s/容器场景经常因为这个报错，非常重要）
# ============================================
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 8192
fs.inotify.max_queued_events = 16384

# ============================================
# 文件句柄数（高并发容器场景）
# ============================================
fs.file-max = 2097152
fs.nr_open = 2097152

# ============================================
# vm.max_map_count（Elasticsearch等内存映射密集型应用容器化部署必调）
# ============================================
vm.max_map_count = 262144

# ============================================
# 内存/Swap 相关
# ============================================
# 降低 swappiness，容器化场景应优先用物理内存
vm.swappiness = 0
# 降低脏页写回阈值，避免突发大量IO导致容器响应延迟
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
# overcommit 内存策略，K8s 场景通常建议允许一定程度的过量分配
vm.overcommit_memory = 1

# ============================================
# PID 数量上限（容器数量多时，进程数容易触顶）
# ============================================
kernel.pid_max = 4194304
kernel.threads-max = 4194304

# ============================================
# 内核 panic 后自动重启（生产环境建议开启，避免节点卡死无人处理）
# ============================================
kernel.panic = 10
kernel.panic_on_oops = 1
```

```bash
# 应用指定配置
sudo sysctl -p /etc/sysctl.d/99-container.conf

# 应用配置
sudo sysctl --system
```

验证参数已生效：

```bash
sysctl net.bridge.bridge-nf-call-iptables
sysctl net.ipv4.ip_forward
sysctl fs.inotify.max_user_watches
sysctl vm.max_map_count
```

##### 1. `net.bridge.bridge-nf-call-iptables`（最容易被忽略、K8s 强制要求）

这个参数默认可能是 0，导致 K8s 的 Service（基于 iptables/ipvs 实现的负载均衡）**无法正常工作**，Pod 之间、Pod 到 Service 的流量转发会出现异常。

##### 2. `net.netfilter.nf_conntrack_max`（高并发容器场景必调）

默认值通常只有几万，容器化环境下大量短连接、高并发出站请求，很容易把连接跟踪表打满，表现为**新连接建立失败、丢包**，日志里会看到 `nf_conntrack: table full, dropping packet`。

##### 3. `fs.inotify.max_user_watches`（K8s 场景排查率极高的坑）

kubelet、容器运行时、日志采集组件（如 Filebeat、Fluentd）都大量依赖 inotify 监听文件变化。默认值（通常 8192）在容器数量多、文件监听多的场景下极易耗尽，报错通常是 `too many open files` 或 `inotify_add_watch failed: No space left on device`（容易误判成磁盘空间问题，实际是 inotify watch 数量耗尽）。

##### 4. `vm.max_map_count`

如果集群里跑某些 JVM 应用（尤其是使用大量内存映射文件的场景），默认值（65530）经常不够，容器启动直接报错退出。

##### 5. `vm.swappiness = 0`

Kubernetes 官方明确要求**禁用或最小化 swap 使用**（部分 K8s 版本 kubelet 甚至会因为检测到 swap 开启而直接拒绝启动，除非显式配置允许）。设为 0 让系统尽量不用 swap，优先保证容器内存分配的可预测性。

### 系统资源限制调优（生产环境必配）

```bash
sudo vi /etc/security/limits.conf
* soft nofile 65535
* hard nofile 65535
* soft nproc 65535
* hard nproc 65535
```

如果使用 systemd 管理的服务，还需要额外配置（很多人只改 `limits.conf` 但服务不生效就是漏了这步）：

```bash
sudo vi /etc/systemd/system.conf
DefaultLimitNOFILE=65535
```

```bash
sudo systemctl daemon-reexec
```