---
title: "kubernetes节点负载资源使用示例"
subtitle: "kubernetes节点负载"
description: "kubernetes节点负载资源使用示例|Deployment|StatefulSet|Services"
date: 2024-11-09T22:36:09+08:00
lastmod: 2024-11-09T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["kubernetes"]
categories: ["kubernetes"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1967.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# k8s节点负载资源使用示例

## 节点负载管理

[参考 Kubernetes 官方文档](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/)

应用是以容器的形式在 [Pod](https://kubernetes.io/zh-cn/docs/concepts/workloads/pods/)（节点）中运行，但是直接管理 Pod 的工作量将会非常繁琐， Kubernetes 提供内置的 API 来创建工作负载对象，这些对象是比 Pod 更高级别的抽象概念。

用于管理 [工作负载](https://kubernetes.io/zh-cn/docs/concepts/workloads/)（WorkLoad）的内置 API 包括：

[Deployments](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/) 是在集群上运行应用的最常见方式。 Deployment 适合在集群上管理无状态应用工作负载，其中 Deployment 中的任何 Pod 都是在需要时可互换的。

[StatefulSet](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/statefulset/)  允许管理一个或多个运行相同应用代码、但具有不同身份标识的 Pod。 StatefulSet 与 Deployment 不同。Deployment 中的 Pod 预期是可互换的。 StatefulSet 最常见的用途是能够建立其 Pod 与其持久化存储之间的关联。如果该 StatefulSet 中的一个 Pod 失败了，Kubernetes 将创建一个新的 Pod， 并连接到相同的 PersistentVolume。[StatefulSet 运行一组 Pod，并为每个 Pod 保留一个稳定的标识。 这可用于管理需要持久化存储或稳定、唯一网络标识的应用。]

### Deployments

[参考 Kubernetes Deployments 规范文档](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/deployment/)

Deployment 用于管理运行一个应用负载的一组 Pod，通常适用于不保持状态的负载。

[Deployment 负载资源 API 规范文档](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/)

示例：

```yaml
# deployment-node.yaml
apiVersion: apps/v1
kind: Deployment
# 元数据声明
metadata:
  namespace: k8s-demo
  name: deployment-node
  labels:
    app: node
    release: v1
spec:
  # 选择器，选择 template 下符合标签的的 pod
  selector:
    matchLabels:
      # 必须匹配 .spec.template.metadata.labels
      app: node
      release: v1
  # Pod 模版，定义创建 pod 所需的数据
  template:
    # 元数据
    metadata:
      # 必须匹配 .spec.selector.matchLabels
      labels:
        app: node
        release: v1
    spec:
      containers:
      # 容器名称，同一 pod 中容器名称必须唯一，名称还会被用来做 DNS 标签
      - name: node-pod
        image: node:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
  replicas: 4 # 默认值是 1
  # 用于用新的 Pod 替换现有 Pod 的部署策略。
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
```

#### 字段说明

- **apiVersion**: apps/v1
- **kind**: Deployment



[metadata](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/object-meta/#ObjectMeta)：所有持久化资源都必须包含的元数据，包含了用户必须创建的所有对象。

- **name**（string）：名称必须是当前 namespace（命名空间）唯一的，当创建资源时需要，不能被更新。

  [RFC 1123 规范](https://datatracker.ietf.org/doc/html/rfc1123)

  - 不超过 253 字符
  - 仅包含小写字母数字字符或 '-' 
  - 以字符数字开头
  - 以字母数字结尾

- **namespace**（string）：定义了每个名称都必须唯一的空间，空值等同于默认的 "default" 命名空间。命名空间是对象被细分为的 DNS 兼容标签。

- **labels**（map[string]string）：使用来组织和分类对象的键和值的映射。可匹配 selectors 。



[spec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/#DeploymentSpec)：是描述 Deployment 行为的规范

- **selector** ([LabelSelector](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/label-selector/#LabelSelector)) 必须：节点标签选择器。必须和 pod 模版的标签匹配。
  - matchLabels (map[string]string)
- **template** ([PodTemplateSpec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-template-v1/#PodTemplateSpec))：描述了从模版创建 pod 是应具有的数据。
  - [metadata](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/object-meta/#ObjectMeta)：标准的对象元数据。
  - [spec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#PodSpec)：一个 pod 的规范定义，指定 pod 的行为。
    - **containers** ([] [Container](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#Container)) ：必须，容器数组。一个容器就是需要在 pod 内运行的应用程序容器。
      - **name** (string)，必须：容器的名称同时指定为 DNS_LABEL，在 pod 中每个容器的名称必须唯一且不能被更新。
      - **image** (string)：容器镜像定义
      - **[imagePullPolicy](https://kubernetes.io/docs/concepts/containers/images/#image-pull-policy)** (string)：容器镜像拉取策略，默认是 Always 。**IfNotPresent** ：仅当本地不存在镜像才拉取。**Always** ：每次 kubelet 启动容器需要解析名称为镜像摘要（ubuntu@sha256:2e863c44b718727c860746568e1d54afd13b2fa71b160f5cd9058fc436217b30），有就用缓存，没有就拉取。**Never**：从不会拉取镜像，仅用本地镜像。
      - **command**  ([]string)：Entrypoint array. 不在 shell 中执行。
      - **args** ([]string)：
      - **ports** ([]ContainerPort)：
        - **ports.containerPort** (int32), 必须：在 pod 的 IP 地址上保留的端口号，（0 < port < 65536）
        - **ports.hostIP** (string)：将外部端口绑定到哪个主机 IP。
        - **ports.name** (string)：如果指定，则必须是 IANA_SVC_NAME 【alphanumeric (a-z, and 0-9) string，最大 15 字符】，并且在 Pod 内是唯一的。Pod 中的每个命名端口都必须具有唯一的名称。
        - **ports.protocol** (string)：端口协议，UDP, TCP, or SCTP， 默认 "TCP"
      - **volumeMounts** ([]VolumeMount)：逻辑卷挂载，[参考文档](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#volumes-1)
- **replicas** (int32)：描述节点（pod）的数量。默认是 1。区分显示的 0 和未指定。
- **strategy** (DeploymentStrategy)： 用于用新的 Pod 替换现有 Pod 的部署策略。
  - **strategy.type** (string)：部署类型。 "Recreate" or "RollingUpdate"，默认是 "RollingUpdate"
  - **strategy.rollingUpdate** (RollingUpdateDeployment)：

- **status** ([DeploymentStatus](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/deployment-v1/#DeploymentStatus))

#### 部署命令

- 部署

```bash
kubectl create -f deployment-node.yaml

kubectl apply -f deployment-node.yaml
```

> deployment.apps/deployment-node created
> service/node-service created

- 查看 pod 运行状态

```bash
kubectl get pod [-o wide]
```

- 删除 pod

```bash
kubectl delete -f deployment-node.yaml
```

- 更新 pod

```bash
kubectl apply -f deployment-node.yaml
```



### StatefulSet

[Kubernetes 关于 statefulset 参考文档](https://kubernetes.io/zh-cn/docs/concepts/workloads/controllers/statefulset/)

StatefulSet 运行一组 Pod，并为每个 Pod 保留一个稳定的标识。 这可用于管理需要持久化存储或稳定、唯一网络标识的应用。StatefulSet 是用来管理有状态应用的工作负载 API 对象。

StatefulSet 对于需要满足以下一个或多个需求的应用程序很有价值：

- 稳定的、唯一的网络标识符。
- 稳定的、持久的存储。
- 有序的、优雅的部署和扩缩。
- 有序的、自动的滚动更新。

示例：

```yaml
kind: StatefulSet
metadata:
  name: statefulset-node
  labels:
    app: node
    release: v1
spec:
  selector:
    matchLabels:
      # 必须匹配 .spec.template.metadata.labels
      app: node
      release: v1
  replicas: 4
  template:
    metadata:
      # 必须匹配 .spec.selector.matchLabels
      labels:
        app: node
        release: v1
    spec:
      containers:
      - name: node-pod
        image: node:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 8080
```

#### 字段说明

[参考 Kubernetes 负载 API StatefulSet 规范说明](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/stateful-set-v1/)

- **apiVersion**: apps/v1
- **kind**: StatefulSet
- **metadata** ([ObjectMeta](https://kubernetes.io/docs/reference/kubernetes-api/common-definitions/object-meta/#ObjectMeta))
- **spec** ([StatefulSetSpec](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/stateful-set-v1/#StatefulSetSpec))
- **status** ([StatefulSetStatus](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/stateful-set-v1/#StatefulSetStatus))

### Services

[参考 Kubernetes service 规范说明文档](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)

将在集群中运行的应用通过同一个面向外界的端点公开出去，即使工作负载分散于多个后端也完全可行。

Service API 是 Kubernetes 的组成部分，它是一种抽象，帮助你将 Pod 集合在网络上公开出去。 每个 Service 对象定义端点的一个逻辑集合（通常这些端点就是 Pod）以及如何访问到这些 Pod 的策略。

定义 service 示例：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: node-service
spec:
  selector:
    app: node
    release: v1
  type: NodePort
  ports:
    - name: http
      protocol: TCP
      port: 8080
      targetPort: 8080
```

> Service 能够将**任意**入站 `port` 映射到某个 `targetPort`。 默认情况下，出于方便考虑，`targetPort` 会被设置为与 `port` 字段相同的值。
>
> 与一般的 Kubernetes 名称一样，端口名称只能包含小写字母、数字和 `-`。 端口名称还必须以字母或数字开头和结尾。

通过 Pod 中端口名称与 `targetPort` 关联：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app.kubernetes.io/name: proxy
spec:
  containers:
  - name: nginx
    image: nginx:stable
    ports:
      - containerPort: 80
        name: http-web-svc
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app.kubernetes.io/name: proxy
  ports:
  - name: name-of-service-port
    protocol: TCP
    port: 80
    targetPort: http-web-svc
```

可以在同一 Service 中配置多个端口定义。为 Service 使用多个端口时，必须为所有端口提供名称，以使它们无歧义。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app.kubernetes.io/name: MyApp
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 9376
    - name: https
      protocol: TCP
      port: 443
      targetPort: 9377
```

#### 服务类型

对一些应用的某些部分（如前端），你可能希望将其公开于某外部 IP 地址， 也就是可以从集群外部访问的某个地址。Kubernetes Service 类型允许指定你所需要的 Service 类型。

可用的 `type` 值及说明：

- **`ClusterIP`**：通过集群的内部 IP 公开 Service，选择该值时 Service 只能够在集群内部访问。 这也是你没有为 Service 显式指定 `type` 时使用的默认值。 你可以使用 [Ingress](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/) 或者 [Gateway API](https://gateway-api.sigs.k8s.io/) 向公共互联网公开服务。
- [`NodePort`](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#type-nodeport)：指定的范围内分配端口（默认值：30000-32767），通过每个节点上的 IP 和静态端口（`NodePort`）公开 Service。 为了让 Service 可通过节点端口访问，Kubernetes 会为 Service 配置集群 IP 地址， 相当于你请求了 `type: ClusterIP` 的 Service。

#### 无头服务

[无头服务（Headless Services）](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/#headless-services)

有时你并不需要负载均衡，也不需要单独的 Service IP。遇到这种情况，可以通过显式设置 集群 IP（`spec.clusterIP`）的值为 `"None"` 来创建 **无头服务（Headless Service）**。

你可以使用无头 Service 与其他服务发现机制交互，而不必绑定到 Kubernetes 的实现。

无头 Service 不会获得集群 IP，kube-proxy 不会处理这类 Service， 而且平台也不会为它们提供负载均衡或路由支持。

### Ingress

[参考 Kubernetes Ingress 规范说明文档](https://kubernetes.io/zh-cn/docs/concepts/services-networking/ingress/)

[Ingress](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.31/#ingress-v1-networking-k8s-io) 提供从集群外部到集群内[服务](https://kubernetes.io/zh-cn/docs/concepts/services-networking/service/)的 HTTP 和 HTTPS 路由。 流量路由由 Ingress 资源所定义的规则来控制。

#### 简单示例：

```yaml
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

HTTPS 代理示例（代理 dashboard）：

```yaml
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

#### 路径类型

Ingress 中的每个路径都需要有对应的路径类型（Path Type）。未明确设置 `pathType` 的路径无法通过合法性检查。当前支持的路径类型有三种：

- `ImplementationSpecific`：对于这种路径类型，匹配方法取决于 IngressClass。 具体实现可以将其作为单独的 `pathType` 处理或者作与 `Prefix` 或 `Exact` 类型相同的处理。

- `Exact`：精确匹配 URL 路径，且区分大小写。

- `Prefix`：基于以 `/` 分隔的 URL 路径前缀匹配。匹配区分大小写， 并且对路径中各个元素逐个执行匹配操作。 路径元素指的是由 `/` 分隔符分隔的路径中的标签列表。 如果每个 *p* 都是请求路径 *p* 的元素前缀，则请求与路径 *p* 匹配。

说明：如果路径的最后一个元素是请求路径中最后一个元素的子字符串，则不会被视为匹配 （例如：`/foo/bar` 匹配 `/foo/bar/baz`, 但不匹配 `/foo/barbaz`）。

| 类型   | 路径                            | 请求路径        | 匹配与否？               |
| ------ | ------------------------------- | --------------- | ------------------------ |
| Prefix | `/`                             | （所有路径）    | 是                       |
| Exact  | `/foo`                          | `/foo`          | 是                       |
| Exact  | `/foo`                          | `/bar`          | 否                       |
| Exact  | `/foo`                          | `/foo/`         | 否                       |
| Exact  | `/foo/`                         | `/foo`          | 否                       |
| Prefix | `/foo`                          | `/foo`, `/foo/` | 是                       |
| Prefix | `/foo/`                         | `/foo`, `/foo/` | 是                       |
| Prefix | `/aaa/bb`                       | `/aaa/bbb`      | 否                       |
| Prefix | `/aaa/bbb`                      | `/aaa/bbb`      | 是                       |
| Prefix | `/aaa/bbb/`                     | `/aaa/bbb`      | 是，忽略尾部斜线         |
| Prefix | `/aaa/bbb`                      | `/aaa/bbb/`     | 是，匹配尾部斜线         |
| Prefix | `/aaa/bbb`                      | `/aaa/bbb/ccc`  | 是，匹配子路径           |
| Prefix | `/aaa/bbb`                      | `/aaa/bbbxyz`   | 否，字符串前缀不匹配     |
| Prefix | `/`, `/aaa`                     | `/aaa/ccc`      | 是，匹配 `/aaa` 前缀     |
| Prefix | `/`, `/aaa`, `/aaa/bbb`         | `/aaa/bbb`      | 是，匹配 `/aaa/bbb` 前缀 |
| Prefix | `/`, `/aaa`, `/aaa/bbb`         | `/ccc`          | 是，匹配 `/` 前缀        |
| Prefix | `/aaa`                          | `/ccc`          | 否，使用默认后端         |
| 混合   | `/foo` (Prefix), `/foo` (Exact) | `/foo`          | 是，优选 Exact 类型      |

多重匹配：在某些情况下，Ingress 中会有多条路径与同一个请求匹配。这时匹配路径最长者优先。 如果仍然有两条同等的匹配路径，则精确路径类型优先于前缀路径类型。

#### 主机名通配符

主机名可以是精确匹配（例如 “`foo.bar.com`”）或者使用通配符来匹配 （例如 “`*.foo.com`”）。 

精确匹配要求 HTTP `host` 头部字段与 `host` 字段值完全匹配。 

通配符匹配则要求 HTTP `host` 头部字段与通配符规则中的后缀部分相同。

| 主机        | host 头部         | 匹配与否？                          |
| ----------- | ----------------- | ----------------------------------- |
| `*.foo.com` | `bar.foo.com`     | 基于相同的后缀匹配                  |
| `*.foo.com` | `baz.bar.foo.com` | 不匹配，通配符仅覆盖了一个 DNS 标签 |
| `*.foo.com` | `foo.com`         | 不匹配，通配符仅覆盖了一个 DNS 标签 |

#### TLS

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: testsecret-tls
  namespace: default
data:
  tls.crt: base64 编码的证书
  tls.key: base64 编码的私钥
type: kubernetes.io/tls
```

> 注意，不能针对默认规则使用 TLS，因为这样做需要为所有可能的子域名签发证书。 因此，`tls` 字段中的 `hosts` 的取值需要与 `rules` 字段中的 `host` 完全匹配

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-example-ingress
spec:
  tls:
  - hosts:
      - https-example.foo.com
    secretName: testsecret-tls
  rules:
  - host: https-example.foo.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: service1
            port:
              number: 80
```

### 持久化存储卷

[参考 Kubernetes 持久卷规范说明文档](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/)

描述 Kubernetes 中的**持久卷（Persistent Volumes）**， 建议先熟悉[卷（volume）](https://kubernetes.io/zh-cn/docs/concepts/storage/volumes/)、 [存储类（StorageClass）](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/)和 [卷属性类（VolumeAttributesClass）](https://kubernetes.io/zh-cn/docs/concepts/storage/volume-attributes-classes/)。

**持久卷（PersistentVolume，PV）** 是集群中的一块存储，可以由管理员事先制备， 或者使用[存储类（Storage Class）](https://kubernetes.io/zh-cn/docs/concepts/storage/storage-classes/)来动态制备。 持久卷是集群资源，就像节点也是集群资源一样。

**持久卷申领（PersistentVolumeClaim，PVC）** 表达的是用户对存储的请求。概念上与 Pod 类似。 Pod 会耗用节点资源，而 PVC 申领会耗用 PV 资源。Pod 可以请求特定数量的资源（CPU 和内存）。同样 PVC 申领也可以请求特定的大小和访问模式 （例如，可以挂载为 ReadWriteOnce、ReadOnlyMany、ReadWriteMany 或 ReadWriteOncePod， 请参阅[访问模式](https://kubernetes.io/zh-cn/docs/concepts/storage/persistent-volumes/#access-modes)）。



示例：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nginx-pv
  labels:
    type: nfs
spec:
  capacity:
    storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteMany
  nfs:
    path: /data/nfs/nginx/
    server: 10.10.10.111

---

apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  resources:
    requests:
      storage: 1Gi
  selector: 
    matchLabels:
      type: nfs

---

apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx-pod
        image: nginx:1.26.2-alpine-perl
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 80
        volumeMounts:
        - mountPath: "/usr/share/nginx/html"
          name: nginx-volume
      volumes:
        - name: nginx-volume
          persistentVolumeClaim:
            claimName: nginx-pvc
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1

---

apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```



## 容器探针

[参考 Kubernetes 探针规范说明文档](https://kubernetes.io/zh-cn/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)

[kubelet](https://kubernetes.io/zh-cn/docs/reference/command-line-tools-reference/kubelet/) 使用存活探针来确定什么时候要重启容器。重启这种状态下的容器有助于提高应用的可用性，即使其中存在缺陷。

kubelet 使用启动探针来了解应用容器何时启动。

> 注意：存活探针是一种从应用故障中恢复的强劲方式，但应谨慎使用。 你必须仔细配置存活探针，确保它能真正标示出不可恢复的应用故障，例如死锁。

kubernetes 探针 [Probes] 分为：活动/活性（Liveness）、就绪（Readiness）和启动（Startup）探针。

Kubernetes（通常简称为 K8s）中的探针是一种用于监测容器内部应用程序状态的机制。

探针有助于确保容器中的应用程序正常运行，并可以在应用程序出现问题时采取适当的措施，如重新启动容器或将流量切换到其它实例。

Kubernetes支持以下类型的探针：

1. **Liveness Probe（存活探针）**：Liveness 探针用于检测应用程序是否仍然在运行。如果 Liveness 探针检测到应用程序崩溃或无响应，Kubernetes 将重新启动容器。这有助于确保应用程序的高可用性。
2. **Readiness Probe（就绪探针）**：Readiness 探针用于确定应用程序是否已准备好接受流量。如果 Readiness 探针失败，Kubernetes 将不会将流量路由到该容器，直到应用程序准备好为止。这有助于确保在应用程序启动或重启时不会向其发送流量。
3. **Startup Probe（启动探针）**：Startup 探针是一种相对较新的探针类型，用于确定应用程序是否已经启动。它与 Liveness Probe 的主要区别在于，它只在容器启动后的初始一段时间内运行。这有助于处理应用程序启动期间的特定问题。

探针的类型、检查方式和配置选项可以根据应用程序的需求进行调整，以确保容器的可用性和稳定性。

### 活性/存活（Liveness）探针

#### 活性 Command 探针

Kubernetes 提供了活性探针来检测和修复服务长时间运行最终转换为不可用状态情况，重启服务。

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-exec
spec:
  containers:
  - name: liveness
    image: busybox:1.36
    args:
    - /bin/sh
    - -c
    - touch /tmp/healthy; sleep 30; rm -f /tmp/healthy; sleep 600
    livenessProbe:
      exec:
        command:
        - cat
        - /tmp/healthy
      initialDelaySeconds: 5
      periodSeconds: 5
```

- `periodSeconds` ：kubelet 应每 5 秒执行一次活性探测。
- `initialDelaySeconds`： kubelet 在执行第一次探测之前应该等待 5 秒。

**注意：** 命令返回 0 表示容器存活，非 0 表示节点损坏不可访问。

启动等待 5s 执行活性探针检测，在每 5s 检测一次服务活性状态，检测失败重启容器。

```bash
Warning  Unhealthy  43s (x6 over 2m8s)   kubelet  Liveness probe failed: cat: can't open '/tmp/healthy': No such file or directory
Normal   Killing    43s (x2 over 118s)   kubelet  Container liveness failed liveness probe, will be restarted
Normal   Created    13s (x3 over 2m39s)  kubelet  Created container liveness
Normal   Started    13s (x3 over 2m39s)  kubelet  Started container liveness
```

#### 活性 HTTP 探针

另一种活性探测使用 HTTP GET 请求。 pod-liveness-http.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    test: liveness
  name: liveness-http
spec:
  containers:
  - name: liveness
    image: harbor.nihility.cn/library/porbe-server:v1
    args:
    - /server
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
        httpHeaders:
        - name: Custom-Header
          value: Awesome
      initialDelaySeconds: 3
      periodSeconds: 3
```

- `periodSeconds`： kubelet 每 3s 执行一次活性探针检测。
- `initialDelaySeconds`： 告诉 kubelet 在执行首次活性探针检测时需先等待 3s 。

kubelet 发起 HTTP GET 请求，任何大于或等于 200 且小于 400 的状态码都表示成功。其它状态码表示失败。

```
Normal   Created    11s (x2 over 74s)  kubelet Created container liveness
Warning  Unhealthy  11s (x3 over 17s)  kubelet Liveness probe failed: HTTP probe failed with statuscode: 500
Normal   Killing    11s                kubelet Container liveness failed liveness probe, will be restarted
```

#### 活性 TCP 探针

第三种类型的活性探测使用 TCP 套接字。通过此配置，kubelet 将尝试在指定端口上打开容器的套接字。如果可以建立连接，则容器被认为是健康的，如果不能建立连接，则被认为是失败的。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: goproxy
  labels:
    app: goproxy
spec:
  containers:
  - name: goproxy
    image: harbor.nihility.cn/library/porbe-server:v1
    ports:
    - containerPort: 8080
    readinessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
    livenessProbe:
      tcpSocket:
        port: 8080
      initialDelaySeconds: 15
      periodSeconds: 10
```

这个配置文件同时使用了 readiness 和 liveness 探针。

- readiness：kubelet 将在容器启动后 15 秒发送第一个就绪探测。将尝试连接到 goproxy 容器上 8080 端口，当探针成功，这个 Pod 将会标记为准备。kubelet 将继续每 10 秒运行一次此检查。
- liveness：同就绪探针一样，如果活性探测失败，容器将重新启动。

### 配置探针

探针有许多字段，您可以使用它们来更精确地控制启动、活动和就绪检查的行为：

- `initialDelaySeconds`：在容器运行之后，启动、活动或就绪探测已初始化前的延迟秒数。如果定义了启动探测，则在启动探测成功之前，活动性和就绪性探测延迟不会开始。如果 periodSeconds 的值大于 initialDelaySeconds，则 initialDelaySeconds 将被忽略。默认为 0 秒，最小值为 0。
- `periodSeconds`：执行探测的频率（以秒为单位）。默认为 10 秒。最小值为 1。
- `timeoutSeconds`: 探测超时后的秒数。默认为 1 秒。最小值为 1。
- `successThreshold`: 探测失败后被视为成功的最小连续成功次数。默认为 1。活性和启动探针必须为 1。最小值为 1。
- `failureThreshold`:  当探测连续失败failureThreshold次后，Kubernetes认为整体检查失败：容器未 就绪/健康/存活。对于启动或活性探测的情况，如果至少 failureThreshold 探测失败，Kubernetes 会将容器视为不健康并触发该特定容器的重新启动。

### HTTP 探针

[http-porbes 参考文档](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#http-probes)

可以在 `HttpGet` 请求中配置额外参数：

- `path`:  HTTP 服务器上的访问路径，默认为“/”。
- `httpHeaders`: 要在请求中设置的自定义标头，HTTP 允许重复标头。
- `port`:  容器上要访问的端口的名称或编号，数字必须在 1 到 65535 范围内。

### 使用启动探针保护慢启动容器

[参考文档](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-startup-probes)

诀窍是使用相同的命令、HTTP 或 TCP 检查来设置启动探测，并使用足够长的 `failureThreshold * periodSeconds` 来涵盖最坏情况的启动时间。

```yaml
ports:
- name: liveness-port
  containerPort: 8080
  hostPort: 8080

livenessProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 1
  periodSeconds: 10

startupProbe:
  httpGet:
    path: /healthz
    port: liveness-port
  failureThreshold: 30
  periodSeconds: 10
```

由于启动探针的存在，应用程序将有最多 5 分钟 (30 * 10 = 300 秒) 的时间来完成启动。

一旦启动探针成功一次，活性探针就会接管以提供对容器死锁的快速响应。

如果启动探测从未成功，容器将在 300 秒后被终止，并受 pod 的 restartPolicy 约束。

## 拉取私有仓库镜像

[拉取私服镜像参考文档](https://kubernetes.io/docs/tasks/configure-pod-container/pull-image-private-registry/#registry-secret-existing-credentials)

### 示例 yaml 配置

```yaml
# pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg
spec:
  containers:
  - name: private-reg-container
    image: <your-private-image>
  # 指定拉取镜像的凭证
  imagePullSecrets:
    - name: myregistrykey
```

### 基于已有凭据创建 Secret

已经 `docker login` 或者 `nerdctl login` 登陆过，会在 `${HOME}/.docker/config.json` 中存下凭证。

```bash
kubectl create secret generic <secret-name> \
    --from-file=.dockerconfigjson=<path/to/.docker/config.json> \
    --type=kubernetes.io/dockerconfigjson

# 示例
kubectl create secret generic registry-secret-cm \
    --from-file=.dockerconfigjson=/root/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson

kubectl create secret generic harbor-secret \
    --from-file=.dockerconfigjson=/root/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson
```

如果需要一些标记或自定义参数：

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: harbor-secret-yaml
  namespace: default
type: kubernetes.io/dockerconfigjson
data:
  # 对 config.json 配置文件进行 base64 编码
  # base64 /root/.docker/config.json
  .dockerconfigjson: ewoJImF1dGhzIjogewoJCSJoYXJib3IubmloaWxpdHkuY24iOiB7CgkJCSJhdXRoIjogImFHRnlZbTl5T2toaGNtSnZjaU14TWpNPSIKCQl9Cgl9Cn0=
```

执行命令：`kubelet create -f secret.yaml`

### 命令行输入凭证创建

```bash
kubectl create secret docker-registry <secret-name> \
  --docker-server=<your-registry-server> \
  --docker-username=<your-name> \
  --docker-password=<your-pword> \
  --docker-email=<your-email>

# 示例
kubectl create secret docker-registry registry-secret-manual-cm \
  --docker-server=harbor.nihility.cn \
  --docker-username=harbor \
  --docker-password=Harbor#123 \
  --docker-email=a@a.com

kubectl create secret docker-registry harbor-manual-secret \
  --docker-server=harbor.k8s.labs.yzx \
  --docker-username=harbor \
  --docker-password=Harbor#123456 \
  --docker-email=a@a.com
```

- `<your-registry-server>` 是你的私有 Docker 仓库全限定域名（FQDN）。 DockerHub 使用 `https://index.docker.io/v1/`。
- `<your-name>` 是 Docker 用户名。
- `<your-pword>` 是 Docker 密码。
- `<your-email>` 是 Docker 邮箱。

查看 secret：

```bash
# 查看生成的 secret 列表
kubectl get secret
# 详细信息,查看所有
kubectl get secret --output=yaml
# 指定某个 secret
kubectl get secret registry-secret-manual-cm --output=yaml
```

解码 `dockerconfigjson` 字段中内容：

```bash
kubectl get secret regcred --output="jsonpath={.data.\.dockerconfigjson}" | base64 --decode
```

