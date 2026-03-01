---
title: "kubernetes pod 推荐配置"
subtitle: "kubernetes pod|pod 推荐配置"
description: "kubernetes pod 推荐配置|pod 常用配置"
date: 2025-03-28T22:36:09+08:00
lastmod: 2025-04-11T22:10:09+08:00
draft: false

authors: ["yzx"]
tags: ["kubernetes"]
categories: ["kubernetes"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_0997.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Kubernetes pod推荐写法


## pod推荐配置示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: node-nginx-pod
  labels:
    app: node-nginx
spec:
  volumes:
  - name: node-nginx-volume
    emptyDir:
      # 使用tmpfs
      medium: Memory
      # 必须设置容量限制
      sizeLimit: 1Gi
  containers:
  - name: node
    image: node:v1
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    # 存活探针和就绪探针在启动探针成功之前不会启动
    # 启动探针，保护启动期的"婴儿阶段"，触发容器重启，Java/Python 等慢启动语言
    startupProbe:
      httpGet:
        path: /info
        port: 8080
      failureThreshold: 30     # 最长等待 30*5=150 秒
      periodSeconds: 5
    # 就绪探针，决定是否接收流量，从 Service 摘除流量，慢启动服务、依赖预热
    # 存活/就绪探针必须同时配置
    readinessProbe:
      httpGet:
        path: /info
        port: 8080
      initialDelaySeconds: 5   # 等待时间（冷启动保护），启动 3 秒后开始检测
      periodSeconds: 1         # 检测间隔（频率控制），每隔 1 秒检测
      successThreshold: 3      # 成功确认次数（防误判），连续 3 次成功才标记就绪
    # 存活探针，判断是否该"安乐死"，杀死容器并重启，死锁检测、僵尸进程
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30  # 避免冷启动误杀
      periodSeconds: 5         # 检测间隔（频率控制）
      failureThreshold: 3      # 失败容忍度（防抖动），连续 3 次失败才判定死亡
    resources:
      requests:          # 最低保障资源
        cpu: "500m"      # 0.5 核
        memory: "500Mi"  # 500M 内存
      limits:            # 资源使用天花板
        cpu: "1"         # 1 核 
        memory: "1Gi"    # 1GB 内存
    volumeMounts:
    - name: node-nginx-volume
      mountPath: /opt/share/
  - name: nginx
    image: nginx:1.26.2-alpine-perl
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 80
    resources:
      requests:          # 最低保障资源
        cpu: "500m"      # 0.5 核
        memory: "500Mi"  # 500M 内存
      limits:            # 资源使用天花板
        cpu: "1"         # 1 核 
        memory: "1Gi"    # 1GB 内存
    volumeMounts:
    - name: node-nginx-volume
      mountPath: /opt/share/

---

# headerless Service
apiVersion: v1
kind: Service
metadata:
  name: node-nginx-service
spec:
  #type: NodePort
  # headerless
  clusterIP: None
  selector:
    app: node-nginx
  ports:
    - name: node
      protocol: TCP
      port: 8080         # Service端口
      targetPort: 8080   # Pod端口
      #nodePort: 38080   # 手动指定端口（可选）
    - name: nginx
      protocol: TCP
      port: 80            # Service端口
      targetPort: 80      # Pod端口
      # nodePort: 38080   # 手动指定端口（可选）

# Pod DNS命名规则
# <pod-name>.<service-name>.<namespace>.svc.cluster.local
# node-nginx-service.default.svc.cluster.local

```

## pod资源限制

参考 [Kubernetes生产级资源管理指南：从QoS到成本优化](https://www.cnblogs.com/leojazz/p/18785677) 博客，若有冒犯或认为侵权，请联系删除更正（写得好，都不需要改）。

```yaml
    resources:
      requests:          # 最低保障资源
        cpu: "500m"      # 0.5 核
        memory: "500Mi"  # 500M 内存
      limits:            # 资源使用天花板
        cpu: "1"         # 1 核 
        memory: "1Gi"    # 1GB 内存
```

| 资源类型 | 单位格式       | 示例   | 实际含义     |
| -------- | -------------- | ------ | ------------ |
| CPU      | 毫核(m)        | 500m   | 0.5个CPU核心 |
| 内存     | 二进制单位(Mi) | 4096Mi | 4GB内存      |

**QoS三级管控体系**

等级对比矩阵：

| QoS等级                | 配置特征               | 调度优先级 | 驱逐顺序 | 适用场景        |
| ---------------------- | ---------------------- | ---------- | -------- | --------------- |
| Guaranteed（专用区）   | requests == limits     | 最高       | 最后     | 数据库/支付核心 |
| Burstable（共享池）    | requests < limits      | 中等       | 中间     | 业务应用        |
| BestEffort（剩余空间） | 未设置 requests/limits | 最低       | 最先     | 日志收集        |

**常见问题排查**

```bash
# 查看资源使用情况
kubectl top pods --sort-by=memory

# 检查Pod驱逐原因
kubectl get events --field-selector=reason=Evicted

# 诊断OOM事件
journalctl -k | grep -i 'oom'
```

**资源优化公式**

```x86asm
理想requests = 第95百分位用量 × 1.2
合理limits = requests × 2 (内存), requests × 3 (CPU)
```

**关键服务配置**

```yaml
# 数据库 Pod 示例
# Guaranteed 等级
resources:
  requests:
    cpu: "4"
    memory: "16Gi"
  limits:
    cpu: "4" 
    memory: "16Gi"
```

**弹性应用配置**

```yaml
# Web 服务 Pod 示例
# Burstable 等级
resources:
  requests:
    cpu: "500m"
    memory: "2Gi"
  limits:
    cpu: "2"
    memory: "4Gi"
```

**批量任务配置**

```yaml
# 日志处理 Job 示例
# BestEffort 等级
resources: {}
```



## pod节点探针[porbe]

这块儿也是参考大佬 [Kubernetes探针全解](https://www.cnblogs.com/leojazz/p/18786641) 博客讲解，若有冒犯或认为侵权，请联系删除更正（写得好，都不需要改）。

**注意：** 存活探针和就绪探针在**启动探针**成功之前不会启动

```yaml
    # 存活探针和就绪探针在启动探针成功之前不会启动
    # 启动探针，保护启动期的"婴儿阶段"，触发容器重启，Java/Python 等慢启动语言
    startupProbe:
      httpGet:
        path: /info
        port: 8080
      failureThreshold: 30     # 最长等待 30*5=150 秒
      periodSeconds: 5
    # 就绪探针，决定是否接收流量，从 Service 摘除流量，慢启动服务、依赖预热
    # 存活/就绪探针必须同时配置
    readinessProbe:
      httpGet:
        path: /info
        port: 8080
      initialDelaySeconds: 5   # 等待时间（冷启动保护），启动 3 秒后开始检测
      periodSeconds: 1         # 检测间隔（频率控制），每隔 1 秒检测
      successThreshold: 3      # 成功确认次数（防误判），连续 3 次成功才标记就绪
    # 存活探针，判断是否该"安乐死"，杀死容器并重启，死锁检测、僵尸进程
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30  # 避免冷启动误杀
      periodSeconds: 5         # 检测间隔（频率控制）
      failureThreshold: 3      # 失败容忍度（防抖动），连续 3 次失败才判定死亡
```

## pod hpa（弹性水平伸缩）

### metrics-server部署

[github 下载链接](https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)，[加速下载链接](https://ghfile.geekertao.top/https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml)，[自提本地下载链接](https://www.nihility.cn/files/k8s/metric-server_v0.7.2.yaml)

修改镜像 [`registry.k8s.io/metrics-server/metrics-server:v0.7.2`] 为加速镜像 [*`swr.cn-north-4.myhuaweicloud.com/ddn-k8s/registry.k8s.io/metrics-server/metrics-server:v0.7.2`*]

添加/编辑参数：

```yaml
- --kubelet-insecure-tls
- --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname,InternalDNS,ExternalDNS
```

- `- --kubelet-insecure-tls` 添加参数，不验证 https 证书

- `- --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname,InternalDNS,ExternalDNS` 修改此参数，metrics 按照指定的顺序连接 kubelet
- `InternalIP`: Kubelet 的内部 IP 地址
  
- `Hostname`: Kubelet 的主机名
  
- `InternalDNS`: Kubelet 的内部 DNS 名称
  
- `ExternalDNS`: Kubelet 的外部 DNS 名称
  
- `ExternalIP`: Kubelet 的外部 IP 地址

部署 [metrics server](https://github.com/kubernetes-sigs/metrics-server)

```bash
kubectl create -f metrics-server_v0.7.2.yaml
```

验证 metrics 服务是否部署成功

```bash
kubectl get pods -n kube-system -l k8s-app=metrics-server
```

查看 pod 和 node 的资源使用情况

```bash
# 查看节点资源使用情况
kubectl top node
# 查看Pod资源使用情况
kubectl top pod
# 查看指定命名空间的 pod 资源使用情况
kubectl top pod -n kube-system
```

### pod水平弹性伸缩

[参考 Kubernetes 水平自动扩缩参考文档](https://kubernetes.io/zh-cn/docs/tasks/run-application/horizontal-pod-autoscale/#default-behavior)

合理设置冷却时间：避免频繁扩缩容

```yaml
# 调整扩缩容延迟
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300  # 缩容冷却 5 分钟
  scaleUp:
    stabilizationWindowSeconds: 60   # 扩容冷却 1 分钟
```

在 HPA Spec 下 `behavior` 字段，下面有 `scaleUp` 和 `scaleDown` 两个字段分别控制扩容和缩容的行为

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  minReplicas: 2
  maxReplicas: 10
  # 监控的指标数组，支持多种类型的指标共存
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  # HPA 伸缩对象描述，HPA 会动态修改该对象的 Pod 数量
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  behavior: # 这里是重点
    scaleDown:
      stabilizationWindowSeconds: 300 # 需要缩容时，先观察 5 分钟，如果一直持续需要缩容才执行缩容
      policies:
      - type: Percent
        value: 100 # 允许全部缩掉
        periodSeconds: 15
    scaleUp:
      stabilizationWindowSeconds: 0 # 需要扩容时，立即扩容，扩容前等待的时间窗口
      selectPolicy: Max # 使用以上两种扩容策略中算出来扩容 Pod 数量最大的
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15 # 每 15s 最大允许扩容当前 1 倍数量的 Pod
      - type: Pods
        value: 4
        periodSeconds: 15 # 每 15s 最大允许扩容 4 个 Pod
```

- 以上 `behavior` 配置是默认的，即如果不配置，会默认加上。
- `scaleUp` 和 `scaleDown` 都可以配置1个或多个策略，最终扩缩时用哪个策略，取决于 `selectPolicy`。
- `selectPolicy` 默认是 `Max`，即扩缩时，评估多个策略算出来的结果，最终选取扩缩 Pod 数量最多的那个策略的结果。
- `stabilizationWindowSeconds` 是稳定窗口时长，即需要指标高于或低于阈值，并持续这个窗口的时长才会真正执行扩缩，以防止抖动导致频繁扩缩容。扩容时，稳定窗口默认为0，即立即扩容；缩容时，稳定窗口默认为5分钟。
- `policies` 中定义扩容或缩容策略，`type` 的值可以是 `Pods` 或 `Percent`，表示每 `periodSeconds` 时间范围内，允许扩缩容的最大副本数或比例。

### hpa 示例

pod 配置示例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: jdk-app-deployment
  labels:
    app: jdk-app
spec:
  selector:
    matchLabels:
      app: jdk-app
  replicas: 2
  template:
    metadata:
      name: jdk-app
      labels:
        app: jdk-app
    spec:
      containers:
      - name: jdk-app-pod
        image: app-jdk-8u421-debian-12.10:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 31808
        resources:
          requests:
            cpu: "500m"
            memory: "500Mi"
          limits:
            cpu: "500m"
            memory: "500Mi"
        # 存活探针和就绪探针在启动探针成功之前不会启动
        # 启动探针，保护启动期的"婴儿阶段"，触发容器重启，Java/Python 等慢启动语言
        startupProbe:
          httpGet:
            path: /ip
            port: 31808
          # 最长等待 30*5=150 秒
          failureThreshold: 30
          periodSeconds: 5
        # 就绪探针，决定是否接收流量，从 Service 摘除流量，慢启动服务、依赖预热
        # 存活/就绪探针必须同时配置
        readinessProbe:
          httpGet:
            path: /ip
            port: 31808
          initialDelaySeconds: 10   # 等待时间（冷启动保护），启动 3 秒后开始检测
          periodSeconds: 1         # 检测间隔（频率控制），每隔 1 秒检测
          successThreshold: 3      # 成功确认次数（防误判），连续 3 次成功才标记就绪
        # 存活探针，判断是否该"安乐死"，杀死容器并重启，死锁检测、僵尸进程
        livenessProbe:
          httpGet:
            path: /ip
            port: 31808
          initialDelaySeconds: 30  # 避免冷启动误杀
          periodSeconds: 5         # 检测间隔（频率控制）
          failureThreshold: 3      # 失败容忍度（防抖动），连续 3 次失败才判定死亡
---

apiVersion: v1
kind: Service
metadata:
  name: jdk-app-service
spec:
  #clusterIP: None
  type: NodePort
  selector:
    app: jdk-app
    release: v1
  ports:
    - name: jdk-app-port
      protocol: TCP
      port: 31808
      targetPort: 31808
```

hpa 配置示例

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: jdk-app-hpa
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: jdk-app-deployment
  behavior:
    scaleDown:
      # 需要缩容时，先观察 5 分钟，如果一直持续需要缩容才执行缩容
      stabilizationWindowSeconds: 30
      policies:
      - type: Percent
        # 允许全部缩掉
        value: 100
        periodSeconds: 15
    scaleUp:
      # 需要扩容时，立即扩容，扩容前等待的时间窗口
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        # 每 15s 最大允许扩容当前 1 倍数量的 Pod
        periodSeconds: 15
      - type: Pods
        value: 2
        # 每 15s 最大允许扩容 4 个 Pod
        periodSeconds: 15
      # 使用以上两种扩容策略中算出来扩容 Pod 数量最大的
      selectPolicy: Max
```

## 节点亲和度

查看节点标签

```bash
# 查看节点标签
kubectl get nodes --show-labels

# 给指定节点打上标签
kubectl label nodes <your-node-name> disktype=ssd
```

### 亲和性配置

亲和性调度POD：节点亲和性配置  `requiredDuringSchedulingIgnoredDuringExecution`， 这意味着 pod 只会被调度到具有 `disktype=ssd` 标签的节点上。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd            
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

### 推荐亲和性

节点亲和性调度 Pod：节点亲和性设置 `preferredDuringSchedulingIgnoredDuringExecution` ，这意味着 Pod 将首选具有 `disktype=ssd` 标签的节点。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  affinity:
    nodeAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: disktype
            operator: In
            values:
            - ssd          
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

### 反亲和性

Pod 会被调度到标签为 role 不等于 database 的节点上。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - matchExpressions:
        - key: role
          operator: In
          values:
          - database
```

