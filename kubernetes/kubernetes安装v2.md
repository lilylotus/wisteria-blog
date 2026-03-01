---
title: "kubernetes安装"
subtitle: "kubernetes安装"
description: "kubernetes安装"
date: 2024-10-14T22:36:09+08:00
lastmod: 2024-10-14T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["kubernetes"]
categories: ["kubernetes"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1906.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# kubernetes安装

[Kubernetes安装参考文档](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

安装 kubeadm, kubelet and kubectl

- `kubeadm`: 引导集群的命令。
- `kubelet`: 在集群中的所有机器上运行并执行诸如启动 pod 和容器之类的操作的组件。
- `kubectl`: 命令行实用程序与集群交互。

## Kubernetes安装步骤

以下 [Kubernetes](https://kubernetes.io/docs/home/) 安装基于 [centos7](https://mirrors.aliyun.com/centos/7/isos/x86_64/) 操作系统。

### 内核参数调整

- 关闭 swap 分区

```bash
# 关闭 swap 分区
sed -i '/ swap /s/^\(.*\)$/#\1/' /etc/fstab
swapoff -a
```

- 配置内核模块

```bash
cat <<EOF | tee /etc/modules-load.d/optimize.conf
overlay
br_netfilter
EOF

modprobe overlay
modprobe br_netfilter
```

- 网络工具和模块

```bash
# package ipset，网络工具
yum install -y ipset ipvsadm

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
```

- 网络内核配置参数

```bash

cat <<EOF > /etc/sysctl.d/optimize.conf
vm.overcommit_memory = 1
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl -p /etc/sysctl.d/optimize.conf

```

### Kubernetes安装

- 配置安装源（需要安装 Kubernetes 版本就修改下面的版本号 [v1.30 / v1.29]）

```bash
cat <<EOF | tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.30/rpm/repodata/repomd.xml.key
EOF
```

- kubeadm/kubelet/kubectl安装

```bash
# 移除已经安装
yum remove -y kubelet kubeadm kubectl
# 加载镜像源
yum clean all && yum makecache
# 安装 kubelet / kubeadm / kubectl
yum install -y kubelet-1.30.4 kubeadm-1.30.4 kubectl-1.30.4
# 开机自启
systemctl enable kubelet
```

### Kubernetes镜像拉取

由于国内无法直接拉取 *registry.k8s.io* 镜像，需要切换国内阿里 k8s 镜像源。

- 拉取镜像，注意：拉取镜像需和安装的 kubeadm 版本一致，不然可能导致拉取镜像版本不一致

```bash
# 采用阿里 k8s 镜像源拉取镜像
kubeadm config images pull \
    --kubernetes-version=1.30.4 \
    --image-repository=registry.aliyuncs.com/google_containers \
    | tee kubeadm-images-1.30.4.txt

# 变更镜像 tag 为 k8s 原始 tag，注意 coredns 需特殊处理
# registry.aliyuncs.com/google_containers/coredns:v1.11.1
# registry.k8s.io/coredns/coredns:v1.11.1
sed -i 's/registry.aliyuncs.com\/google_containers//' kubeadm-images-1.30.4.txt
sed -i 's/\[config\/images\] Pulled //' kubeadm-images-1.30.4.txt

for line in $( cat kubeadm-images-1.30.4.txt )
do
    result=$(echo ${line} | grep coredns)
    if [[ "${result}" == "" ]]
    then
        k8s_img="registry.k8s.io${line}"
    else
        k8s_img="registry.k8s.io/coredns${line}"
    fi
    ali_img="registry.aliyuncs.com/google_containers${line}"
    echo "nerdctl -n k8s.io tag ${ali_img} ${k8s_img}"
done

# 删除镜像文档
rm -f kubeadm-images-1.30.4.txt
```

### kubernetes初始化

#### 初始化配置参数调整

- 生成默认初始化配置

```bash
kubeadm config print init-defaults > kubeadm-init.yaml
```

- kubeadm-init.yaml

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  # 配置 k8s master 主节点地址
  advertiseAddress: 10.10.10.111
  bindPort: 6443
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
  imagePullPolicy: IfNotPresent
  # k8s 主节点访问域名
  name: master
  taints: null

---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
imageRepository: registry.k8s.io
kind: ClusterConfiguration
# k8s 版本
kubernetesVersion: 1.30.4
networking:
  dnsDomain: cluster.local
  # k8s pod 节点子网
  # serviceSubnet: 10.96.0.0/12
  serviceSubnet: 10.66.0.0/16
scheduler: {}

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
```

#### 执行初始化命令

```bash
kubeadm init -v5 --config=kubeadm-init.yaml --upload-certs | tee kubeadm-init.log
```

- 安装成功后执行初始化命令（为了开始使用集群，运行一下初始化命令作为普通用户）

```bash
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config
```

- 其他 k8s 节点加入主节点

```bash
kubeadm join 10.10.10.111:6443 \
	--token abcdef.0123456789abcdef \
	--discovery-token-ca-cert-hash sha256:21f7e156d57a1882eef6afcff7f30570a371da0061e979e9762828f2d7a4dc0a
```

- 节点加入完成后查看个节点状态

```bash
kubectl get nodes [-o wide]

# NAME     STATUS   ROLES           AGE   VERSION
# master   Ready    control-plane   3d    v1.30.4
# slave1   Ready    <none>          3d    v1.30.4
# slave2   Ready    <none>          3d    v1.30.4
# slave3   Ready    <none>          3d    v1.30.4
```



## kubernetes插件安装

Kubernetes 安装完成后还不能正常方便使用，还需安装网络和别的插件

### Calico网络插件

[Calico kubernetes 安装参考文档](https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart#install-calico)

Calico 安装资源 yaml 文件：

- git 仓库下载：[git v3.28.2 tigera-operator.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/tigera-operator.yaml), [git v3.28.2 custom-resources.yaml](https://raw.githubusercontent.com/projectcalico/calico/v3.28.2/manifests/custom-resources.yaml)
- 自地址下载：[blog v3.28.1 tigera-operator.yaml](https://www.nihility.cn/files/k8s/calico-tigera-operator-v3.28.1.yaml)，[blog v3.28.1 custom-resources.yaml](https://www.nihility.cn/files/k8s/calico-custom-resources-v3.28.1.yaml)

> 修改 **custom-resources.yaml** 中 CIDR ip 地址池为 kubernetes pod ip 地址池

```bash
kubectl create -f calico-tigera-operator-v3.28.1.yaml
kubectl create -f calico-custom-resources-v3.28.1.yaml
```

- 查询 calico 安装后状态，若是状态不对可重启各个节点服务器

```bash
kubectl get pod -n calico-system [-o wide]

# NAME                                       READY   STATUS    RESTARTS      AGE
# calico-kube-controllers-79f66946bc-265lk   1/1     Running   2 (61m ago)   3d
# calico-node-9wzbl                          1/1     Running   2 (61m ago)   3d
# calico-node-fsqmn                          1/1     Running   5 (61m ago)   3d
# calico-node-mnbq2                          1/1     Running   4 (61m ago)   3d
# calico-node-rgv7w                          1/1     Running   4 (62m ago)   3d
# calico-typha-5988f7786d-5kll5              1/1     Running   2 (61m ago)   3d
# calico-typha-5988f7786d-k6wzl              1/1     Running   2 (61m ago)   3d
# csi-node-driver-4wfzg                      2/2     Running   4 (62m ago)   3d
# csi-node-driver-7dktt                      2/2     Running   4 (61m ago)   3d
# csi-node-driver-dkbwp                      2/2     Running   4 (61m ago)   3d
# csi-node-driver-zfx6v                      2/2     Running   4 (61m ago)   3d

```

#### pod测试

node-js 测试镜像构建，基于 node-js 创建 http 服务, [node-server.js 下载链接](https://www.nihility.cn/files/k8s/node-server.js)

- 创建 Dockerfile

```dockerfile
FROM node:22.3.0-alpine3.20
COPY node-server.js /node/server.js
WORKDIR /node/
EXPOSE 8080
ENTRYPOINT ["node", "/node/server.js"]
```

- 构建镜像

```bash
nerdctl -n k8s.io build -t node:v1 .
```

- 测试 pod 和 service -> node-test.yaml

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: node-deployment
  labels:
    app: node
spec:
  selector:
    matchLabels:
      app: node
  template:
    metadata:
      name: node
      labels:
        app: node
    spec:
      containers:
      - name: node-pod
        image: node:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
  replicas: 4

---
apiVersion: v1
kind: Service
metadata:
  name: node-service
spec:
  type: NodePort
  selector:
    app: node
  ports:
    - protocol: TCP
      port: 8080
      targetPort: 8080
```

- k8s 创建测试节点

```bash
kubectl create -f node-test.yaml

# 查看 pod 运行状态
kubectl get pod [-o wide]

> NAME                               READY   STATUS    RESTARTS      AGE   IP              NODE
> node-deployment-75dfd6489d-2jr8b   1/1     Running   1 (72m ago)   3d    10.66.140.200   slave1
> node-deployment-75dfd6489d-8kccz   1/1     Running   1 (72m ago)   3d    10.66.140.70    slave2
> node-deployment-75dfd6489d-cr9qm   1/1     Running   1 (72m ago)   3d    10.66.77.7      slave3
> node-deployment-75dfd6489d-zdtbp   1/1     Running   1 (72m ago)   3d    10.66.140.69    slave2

# curl 访问 pod 服务
curl 10.66.140.200:8080/ip
curl 10.66.140.70:8080/interfaces

# 查看 service 运行状态
kubectl get svc

> NAME           TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)          AGE
> node-service   NodePort    10.96.85.241   <none>        8080:31666/TCP   3d

# curl 通过 service 访问服务
curl 10.96.85.241:8080/ip （通过内部 cluster ip 访问）
curl 10.10.10.111:31666/ip （通过阶段 ip 访问）

```

### ingress-nginx插件

[ingress-nginx git 仓库](https://github.com/kubernetes/ingress-nginx)，[ingress-nginx v1.10.4 deploy.yaml git 链接](https://github.com/kubernetes/ingress-nginx/blob/controller-v1.10.4/deploy/static/provider/baremetal/deploy.yaml)，[ingress-nginx v1.11.2 deploy.yaml git 链接](https://github.com/kubernetes/ingress-nginx/blob/controller-v1.11.2/deploy/static/provider/baremetal/deploy.yaml)

[本地 ingress-nginx v1.10.2 下载链接](https://www.nihility.cn/files/k8s/ingress-nginx-deploy-v1.10.2.yaml)

```bash
kubectl create -f ingress-nginx-deploy-v1.10.2.yaml

# 查看 pod 安装状态
kubectl get pod -n ingress-nginx

> NAME                                        READY   STATUS      RESTARTS      AGE
> ingress-nginx-admission-create-tgphn        0/1     Completed   0             3d
> ingress-nginx-admission-patch-z5kw6         0/1     Completed   0             3d
> ingress-nginx-controller-56c555fcb7-7svr4   1/1     Running     1 (90m ago)   3d

# 查看 ingress-nginx 对应 service
kubectl get svc -n ingress-nginx

> NAME                                 TYPE        CLUSTER-IP       PORT(S)                      AGE
> ingress-nginx-controller             NodePort    10.108.44.190    80:30924/TCP,443:30365/TCP   3d
> ingress-nginx-controller-admission   ClusterIP   10.111.3.204     443/TCP                      3d

# 访问 curl
curl node.ingress.labs.yzx:30365/ip
```

- ingress-nginx pod 测试 yaml

```yaml
# node-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: node-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: node.ingress.labs.yzx
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: node-service
            port:
              number: 8080
```

- 测试 ingress 访问

```bash
# 访问 curl , 配置 hosts 域名映射
# 10.10.10.11 node.ingress.labs.yzx
curl node.ingress.labs.yzx:30365/ip
```

### dashboard插件安装

[kubernetes dashboard v2.7.0 部署 yaml - git](https://github.com/kubernetes/dashboard/blob/v2.7.0/aio/deploy/recommended.yaml)， [本 dashboard v2.7.0 下载链接](https://www.nihility.cn/files/k8s/dashboard-v2.7.0.yaml)

```bash
kubectl create -f https://www.nihility.cn/files/k8s/dashboard-v2.7.0.yaml

# 查看 pod 节点创建状态
kubectl get pod -n kubernetes-dashboard [-o wide]

> NAME                                         READY   STATUS    RESTARTS      AGE
> dashboard-metrics-scraper-795895d745-xxds7   1/1     Running   1 (99m ago)   3d
> kubernetes-dashboard-78f95ff46f-4gk6l        1/1     Running   1 (99m ago)   3d

# 查看 dashboard service 状态
kubectl get svc -n kubernetes-dashboard

> NAME                        TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
> dashboard-metrics-scraper   ClusterIP   10.96.77.252   <none>        8000/TCP        3d
> kubernetes-dashboard        NodePort    10.98.62.229   <none>        443:30541/TCP   3d

# 编辑 dashboard service 类型为 NodePort
kubectl edit svc -n kubernetes-dashboard kubernetes-dashboard
> type: NodePort

# 访问地址
https://10.10.10.111:30541
```

- 创建 token

```bash

cat <<EOF > dashboard-adminuser.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF

# 创建管理员用户
kubectl apply -f dashboard-adminuser.yaml

# 创建角色
cat <<EOF > cluster-role-authorization.yml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

kubectl apply -f cluster-role-authorization.yml

# 创建 token
kubectl -n kubernetes-dashboard create token admin-user | tee dashboard-token.txt
```

- 长期 token

```bash
cat <<EOF > dashboard-long-live-bearer-token.yaml
apiVersion: v1
kind: Secret
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/service-account.name: "admin-user"   
type: kubernetes.io/service-account-token 
EOF

kubectl apply -f dashboard-long-live-bearer-token.yaml

kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d  | tee dashboard-lt-token.txt
```

#### ingress域名映射

```yaml
# ingress-dashboard.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    # 开启 use-regex，启用 path 的正则匹配
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /
    # 默认为 true，启用 TLS 时，http请求会 308 重定向到 https
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    # 默认为 http，开启后端服务使用 proxy_pass https://协议
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  ingressClassName: nginx
  rules:
  - host: dashboard.ingress.labs.yzx
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: kubernetes-dashboard
            port:
              number: 443
```

