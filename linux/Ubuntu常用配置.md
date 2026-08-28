# Ubuntu配置

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

/etc/docker/daemon.json

```json
{
    "registry-mirrors":
    [
        "https://docker.m.daocloud.io"
    ],
    "insecure-registries":
    [
        "docker.example.com"
    ],
    "data-root": "/data/docker/",
    "log-opts":
    {
        "max-size": "50m",
        "max-file": "5"
    }
}
```

```bash
systemctl daemon-reload && systemctl restart docker
```

### 阿里云

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

