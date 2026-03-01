#!/bin/bash

# K8S_VERSION=1.28.14
# K8S_VERSION=1.29.12
# K8S_VERSION=1.30.8
K8S_VERSION=1.31.4

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

# package ipset，网络工具
yum clean all && yum makecache && yum install -y ipset ipvsadm

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

# linux 内核配置参数
cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

echo "k8s version is [${K8S_VERSION}]"

if [[ ${K8S_VERSION} == 1.28.* ]]; then

# Kubernetes 1.28.14
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.28/rpm/repodata/repomd.xml.key
EOF

# kubernetes v1.28.14 pause -> 3.9
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.9/' /etc/containerd/config.toml

elif [[ ${K8S_VERSION} == 1.29.* ]]; then

# Kubernetes 1.29.12
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/repodata/repomd.xml.key
EOF

# kubernetes v1.29.12 pause -> 3.9
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.9/' /etc/containerd/config.toml

elif [[ ${K8S_VERSION} == 1.30.* ]]; then

# Kubernetes 1.30.8
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/repodata/repomd.xml.key
EOF

# kubernetes v1.30.8 pause -> 3.9
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.9/' /etc/containerd/config.toml

elif [[ ${K8S_VERSION} == 1.31.* ]]; then

# Kubernetes 1.31.4
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
enabled=1
gpgcheck=1
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/repodata/repomd.xml.key
EOF

# kubernetes v1.31.4 pause -> 3.10
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.10/' /etc/containerd/config.toml

else

echo "default k8s version v1.31.4"
# Kubernetes 1.31.4
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
enabled=1
gpgcheck=1
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.31/rpm/repodata/repomd.xml.key
EOF

# kubernetes v1.31.4 pause -> 3.10
sed -i '/sandbox_image/s/3.[0-9]\{1,2\}/3.10/' /etc/containerd/config.toml

fi

yum remove -y kubelet kubeadm kubectl kubernetes-cni

yum clean all && yum makecache

# 安装 k8s
yum install -y kubelet-${K8S_VERSION} kubeadm-${K8S_VERSION} kubectl-${K8S_VERSION}

# kubelet 开机自启
systemctl enable kubelet.service
