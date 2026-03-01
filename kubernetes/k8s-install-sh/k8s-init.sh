#!/bin/bash

# K8S_VERSION=1.28.14
# K8S_VERSION=1.29.12
# K8S_VERSION=1.30.8
K8S_VERSION=1.31.4
K8S_HOST_NAME=master
K8S_POD_SUBNET=10.66.0.0/16
K8S_HOST_IP=$(ip ad | grep ens | grep inet | awk '{print $2}' | cut -d/ -f1)

# default k8s configuration file
kubeadm config print init-defaults > kubeadm-init.yaml

sed -i 's%\(advertiseAddress: \)\(.*\)$%\1'${K8S_HOST_IP}'%' kubeadm-init.yaml
sed -i 's%\(name: \)\(.*\)$%\1'${K8S_HOST_NAME}'%' kubeadm-init.yaml
sed -i 's%\(kubernetesVersion: \)\(.*\)$%\1'${K8S_VERSION}'%' kubeadm-init.yaml
sed -i '/serviceSubnet:/a \ \ podSubnet: '${K8S_POD_SUBNET} kubeadm-init.yaml

cat <<EOF >> kubeadm-init.yaml
---
# 申明 cgroup 用 systemd
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
# cgroupfs
cgroupDriver: systemd
failSwapOn: false
---
# 启用 ipvs
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
EOF

# sed -i 's%\(sandbox_image = \)\(.*\)%\1"registry.k8s.io/pause:3.9"%' /etc/containerd/config.toml

# 初始集群
# kubeadm init -v5 --config=kubeadm-init.yaml --upload-certs | tee kubeadm-init.log

# k8s init
# mkdir -p $HOME/.kube
# cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
# chown $(id -u):$(id -g) $HOME/.kube/config

# 出问题后重置环境
# kubeadm reset -f
# ipvsadm --clear
# rm -rf $HOME/.kube
# rm -rf /etc/kubernetes/

# 问题 [ERROR CRI]: container runtime is not running:
# crictl -r unix:///var/run/containerd/containerd.sock info


