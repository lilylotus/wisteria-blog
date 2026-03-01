# Containerd 和 Kubernetes 环境部署

## 主机环境准备

### 环境说明

- 服务器系统：[Centos 7](http://isoredirect.centos.org/centos/7/isos/x86_64/)
- Kubernetes 版本：1.28.2
- Containerd 版本：1.6.28

### 服务简单配置

升级更新 Centos 7 并安装常用软件

```bash
wget -O /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
# 升级到最新包
yum clean all && yum makecache faste && yum -y upgrade
# 安装其它常用软件
yum install -y gcc gcc-c++ make automake vim tree yum-utils iptables iptables-services iptables-utils firewalld net-tools openssh-server openssh-clients
yum install -y epel-release && yum install -y htop
```

关闭防火墙和调整其它配置

```bash
# 关闭防火墙
systemctl stop firewalld.service ; systemctl disable firewalld.service
# 禁用 Selinux
sed -ri '/^SELINUX=/s/^(.*)$/SELINUX=disabled/' /etc/selinux/config
# 禁用其它服务
systemctl stop postfix ; systemctl disable postfix
```

常用服务器参数配置

```bash
# 配置 vim 参数
cat <<EOF >> /etc/vimrc
syntax on
set tabstop=4
set autoindent
EOF
```

安装 Centos 7 Linux 新版内核，[Centos7 kernel 下载链接](https://elrepo.org/linux/kernel/el7/x86_64/RPMS/)，选择 kernel-lt （长期支持分支）版本。

```bash
# 安装 kernel rpm 包
yum install -y kernel-lt-*.rpm
# 设置 grub 启动项
grub2-set-default 0 && grub2-mkconfig -o /etc/grub2.cfg
grubby --args="user_namespace.enable=1" --update-kernel="$(grubby --default-kernel)"
```



## 容器部署

### 内核参数调整

```bash
echo "user.max_user_namespaces=15000" >> /etc/sysctl.conf

# 设置系统打开文件最大数
cat >> /etc/security/limits.conf <<EOF
    * soft nofile 65535
    * hard nofile 65535
EOF

cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

# 修改 swap 虚拟内存的使用规则，设置为 10 说明当内存使用量超过 90% 才会使用 swap 空间
echo "10" > /proc/sys/vm/swappiness
```

### Containerd 部署

Containerd 容器安装

```bash
#!/bin/bash

ContainerdVersion=1.6.28-3.1.el7

# containerd 容器依赖和服务安装
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y yum-utils device-mapper-persistent-data lvm2
yum install -y containerd.io-${ContainerdVersion}
# 配置开启自启
systemctl enable containerd

# containerd 配置
mkdir -p /etc/containerd/
containerd config default > /etc/containerd/config.toml
sed -i '/SystemdCgroup/s/false/true/' /etc/containerd/config.toml
```

Containerd 相关工具安装

```bash
# nerdctl 工具 https://github.com/containerd/nerdctl/releases
rm -rf nerdctl ; mkdir nerdctl
tar -zxf nerdctl-1.7.4-linux-amd64.tar.gz -C nerdctl
mv -f nerdctl/nerdctl /usr/local/bin/ && rm -rf nerdctl

# CNI 容器网络接口 https://github.com/containernetworking/plugins/releases
mkdir -p /opt/cni/bin/
tar -zxf cni-plugins-linux-amd64-v1.4.1.tgz -C /opt/cni/bin/

# buildkit 构建镜像工具包 https://github.com/moby/buildkit/releases
rm -rf buildkit ; mkdir buildkit
tar -zxf buildkit-v0.13.0.linux-amd64.tar.gz -C buildkit
cp buildkit/bin/buildctl buildkit/bin/buildkitd buildkit/bin/buildkit-runc buildkit/bin/buildkit-cni-* /usr/local/bin/ && rm -rf buildkit

cat <<EOF > /usr/lib/systemd/system/buildkitd.service
[Unit]
Description=BuildKit
After=network.target
Documentation=https://github.com/moby/buildkit

[Service]
ExecStartPre=-/sbin/modprobe overlay
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true
Type=notify
Delegate=yes
KillMode=process
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload ; systemctl enable buildkitd

# CRI 工具 https://github.com/kubernetes-sigs/cri-tools/releases
tar -zxf crictl-v1.29.0-linux-amd64.tar.gz -C /usr/local/bin/
tar -zxf critest-v1.29.0-linux-amd64.tar.gz -C /usr/local/bin/

```

测试 Containerd.io 安装

```bash
systemctl restart containerd ; nerdctl run hello-world
```

### k8s 部署

内核参数调整

```bash
# 关闭 swap 分区
sed -i '/ swap /s/^\(.*\)$/#\1/' /etc/fstab
swapoff -a

# 配置内核模块
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

# 支持 IPVS needs module - package ipset
cat <<EOF | tee /etc/modules-load.d/ipvs.conf
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack

# package ipset，网络工具
yum install -y ipset ipvsadm

```

k8s 安装

```bash
# 添加 k8s 仓库
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF

# 安装 k8s
yum install -y kubelet-1.28.2-0 kubeadm-1.28.2-0 kubectl-1.28.2-0
```

k8s master 初始化

```

```

