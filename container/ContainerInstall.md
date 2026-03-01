---
title: "容器（Containerd/Docker）安装"
subtitle: "轻量级虚拟化容器 Containerd/Docker 安装"
description: "虚拟化容器（Containerd/Docker）安装"
date: 2024-10-10T22:36:09+08:00
lastmod: 2024-10-10T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["containerd","docker"]
categories: ["container"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1925.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# docker

[Docker 参考文档](https://docs.docker.com/reference/)

## docker安装

[ali（阿里）docker 容器镜像](https://developer.aliyun.com/mirror/docker-ce)

```bash

# step 1: 安装必要的一些系统工具
yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Step 4: 更新并安装Docker-CE
yum makecache fast
yum -y install docker-ce
# Step 4: 开启Docker服务
systemctl enable docker && systemctl restart docker

```

- 安装指定版本的 docker


```bash

# 注意：
# 官方软件源默认启用了最新的软件，您可以通过编辑软件源的方式获取各个版本的软件包。例如官方并没有将测试版本的软件源置为可用，您可以通过以下方式开启。同理可以开启各种测试版本等。
# vim /etc/yum.repos.d/docker-ce.repo
#   将[docker-ce-test]下方的enabled=0修改为enabled=1

# 安装指定版本的Docker-CE:
# Step 1: 查找Docker-CE的版本:
yum list docker-ce --showduplicates | sort
#   Loading mirror speeds from cached hostfile
#   Loaded plugins: branch, fastestmirror, langpacks
#   docker-ce.x86_64            3:26.0.2-1.el7                      docker-ce-stable
#   docker-ce.x86_64            3:26.1.0-1.el7                      docker-ce-stable
#   docker-ce.x86_64            3:26.1.1-1.el7                      docker-ce-stable
#   docker-ce.x86_64            3:26.1.2-1.el7                      docker-ce-stable
#   docker-ce.x86_64            3:26.1.3-1.el7                      docker-ce-stable
#   docker-ce.x86_64            3:26.1.4-1.el7                      docker-ce-stable
#   Available Packages

# Step2: 安装指定版本的Docker-CE: (VERSION例如上面的17.03.0.ce.1-1.el7.centos)
# sudo yum -y install docker-ce-[VERSION]
yum install -y docker-ce-26.1.4-1

```

## docker配置

- 配置网络转发

```bash

cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter

cat <<EOF > /etc/sysctl.d/optimize.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

```

- 配置 docker 默认配置文件 `/etc/docker/daemon.json`
  - data-root： 自定义容器数据存放目录
  - registry-mirrors： 容器镜像下载站点

```bash

cat <<EOF > /etc/docker/daemon.json
{
    "registry-mirrors": ["https://docker.m.daocloud.io","https://docker.nju.edu.cn","https://docker.mirrors.sjtug.sjtu.edu.cn"],
    "data-root": "/data/docker",
    "exec-opts": ["native.cgroupdriver=systemd"],
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {"max-size": "100m"}
}
EOF

systemctl daemon-reload && systemctl restart docker

```



# containerd

[containerd官网](https://containerd.io/)， [containerd开始参考文档](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)

> 注意： Kubernetes 在 1.24 版本移除 dockershim 作为容器运行时支持，默认采用 containerd 作为运行是容器支持。

## 名词解释

|                             名称                             |                             描述                             |
| :----------------------------------------------------------: | :----------------------------------------------------------: |
| CRI（[Container Runtime Interface](https://github.com/kubernetes/kubernetes/blob/242a97307b34076d5d8f5bbeb154fa4d97c9ef1d/docs/devel/container-runtime-interface.md)） | 容器运行时接口，就是 Kubernetes 定义的一组与容器运行时进行交互的接口，只要实现了这套接口的容器运行时都可以对接到 Kubernetes 平台上来。 |
| OCI （[Open Container Initiative](https://opencontainers.org/about/overview/)） | 开放的容器运行时规范，目的在于定义一个容器运行时及镜像的相关标准和规范 |

## containerd安装

### containerd服务安装

```bash

# step 1: 安装必要的一些系统工具
yum install -y yum-utils device-mapper-persistent-data lvm2
# Step 2: 添加软件源信息
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
# Step 3
sed -i 's+download.docker.com+mirrors.aliyun.com/docker-ce+' /etc/yum.repos.d/docker-ce.repo
# Step 4 安装 containerd
yum install -y containerd.io

```

### containerd插件安装

[和 containerd 交换的命令行接口 （command line interface [CLI] ）](https://github.com/containerd/containerd/blob/main/docs/getting-started.md#interacting-with-containerd-via-cli)

#### nerdctl

[nerdctl 发版地址](https://github.com/containerd/nerdctl/tags)

```bash
tar -zxf $(ls nerdctl*.tar.gz) -C nerdctl
mv -f nerdctl/nerdctl /usr/local/bin/
rm -rf nerdctl
```

- 测试 `nerdctl run hello-world`

#### cni

[cni-plugins 发版地址](https://github.com/containernetworking/plugins/releases)

CNI（Container Network Interface）

```bash
mkdir -p /opt/cni/bin/
tar -zxf $(ls cni-plugins-linux-*.tgz) -C /opt/cni/bin/
```

#### buildkit

[buildkit 镜像构建工具发版地址](https://github.com/moby/buildkit/releases)

```bash

# https://github.com/moby/buildkit/releases
# Step1: 安装 buildkit
mkdir buildkit
tar -zxf $(ls buildkit-*.tar.gz) -C buildkit
cp -n buildkit/bin/buildkit-cni-* /usr/local/bin/
cp -n buildkit/bin/buildctl buildkit/bin/buildkitd buildkit/bin/buildkit-runc /usr/local/bin/
rm -rf buildkit

# Step2：添加 buildkit systemed 服务
cat <<EOF > /usr/lib/systemd/system/buildkitd.service
[Unit]
Description=BuildKit
After=network.target local-fs.target
Documentation=https://github.com/moby/buildkit

[Service]
#uncomment to enable the experimental sbservice (sandboxed) version of containerd/cri integration
#Environment="ENABLE_CRI_SANDBOXES=sandboxed"
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/buildkitd --oci-worker=true --containerd-worker=true

Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNPROC=infinity
LimitCORE=infinity
LimitNOFILE=infinity
# Comment TasksMax if your systemd version does not supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
OOMScoreAdjust=-999

[Install]
WantedBy=multi-user.target
EOF

# Step3：开机自启 buildkit 服务
systemctl daemon-reload
systemctl start buildkitd
systemctl enable buildkitd

```

#### crictl

[crictl / critest工具发版地址](https://github.com/kubernetes-sigs/cri-tools/releases)

```bash

# https://github.com/kubernetes-sigs/cri-tools/releases
tar -zxf $(ls crictl-*.tar.gz) -C /usr/local/bin/
tar -zxf $(ls critest-*.tar.gz) -C /usr/local/bin/

cat <<EOF > /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
pull-image-on-create: false
EOF

```



## containerd配置

### 开启网络转发

```bash

# 更新内核网络参数
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF

modprobe overlay && modprobe br_netfilter

# linux 内核配置参数
cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

```

### containerd运行配置参数调整

- 初始化 *containerd* 默认配置文件

```bash
containerd config default > /etc/containerd/config.toml
```

- 镜像源地址配置 [hosts配置参数文档](https://github.com/containerd/containerd/blob/main/docs/hosts.md#registry-configuration---examples)

```bash

sed -i '/config_path/s/""/"\/etc\/containerd\/certs.d"/' /etc/containerd/config.toml

mkdir -p /etc/containerd/certs.d
mkdir -p /etc/containerd/certs.d/docker.io

cat <<EOF > /etc/containerd/certs.d/docker.io/hosts.toml
server = "https://docker.io"
[host."https://docker.m.daocloud.io"]
  capabilities = ["pull", "resolve"]
[host."https://docker.nju.edu.cn"]
  capabilities = ["pull", "resolve"]
[host."https://docker.mirrors.sjtug.sjtu.edu.cn"]
  capabilities = ["pull", "resolve"]
EOF

```

- 使用 systemed

```bash
sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
```



## containerd基础命令

和  docker 用法大体一致

```bash
# 1. 运行容器
nerdctl [--debug] run hello-world

# 2. 拉取镜像
nerdctl [-n k8s.io] pull nginx

# 3. 保存镜像
nerdctl [-n k8s.io] save nginx | gzip > nginx.tar.gz

# 4. 加载镜像
nerdctl [-n k8s.io] load -i nginx.tar.gz

# 5. 构建镜像
nerdctl -n k8s.io build -t nginx:v1 .

```

