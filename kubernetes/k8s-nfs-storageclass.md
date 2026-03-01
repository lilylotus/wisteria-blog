---
title: "kubernetes storageclass 动态 pvc"
subtitle: "kubernetes storageclass 动态 pvc"
description: "kubernetes storageclass 动态 pvc"
date: 2025-03-17T23:36:09+08:00
lastmod: 2025-03-17T23:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["kubernetes"]
categories: ["kubernetes"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1221.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# k8s NFS 动态配置pvc

## 创建 sc rbac 资源

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  # replace with namespace where provisioner is deployed
  namespace: default
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    # replace with namespace where provisioner is deployed
    namespace: default
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
```

## 配置 NFS 子目录外部配置程序

```yaml
kind: Deployment
apiVersion: apps/v1
metadata:
  name: nfs-client-provisioner
spec:
  replicas: 1
  selector:
    matchLabels:
      app: nfs-client-provisioner
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          # https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner?tab=readme-ov-file#manually
          # image: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          image: registry.cn-hangzhou.aliyuncs.com/k8s_study_rfb/nfs-subdir-external-provisioner:v4.0.0
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: k8s-sigs.io/nfs-subdir-external-provisioner
            - name: NFS_SERVER
              # value: <YOUR NFS SERVER HOSTNAME>
              value: 192.168.10.10
            - name: NFS_PATH
              # value: NFS_PATH
              value: /data/nfs
      volumes:
        - name: nfs-client-root
          nfs:
            # server: <YOUR NFS SERVER HOSTNAME>
            server: 192.168.10.10
            path: /data/nfs
```

## 创建NFS storeageClass

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-sc-client
# or choose another name, must match deployment's env PROVISIONER_NAME
provisioner: k8s-sigs.io/nfs-subdir-external-provisioner
parameters:
  # 此处也可以使用 "${.PVC.namespace}/${.PVC.name}" 来使用 pvc 的名称作为 nfs 中真实目录名称
  # "${.PVC.namespace}/${.PVC.annotations.nfs.io/storage-path}"
  pathPattern: "${.PVC.namespace}/${.PVC.annotations.nfs.io/storage-path}"
  # delete / retain
  onDelete: delete
  # false -> delete the directory, onDelete exists ignored
  # archiveOnDelete: false
```

## 创建测试 pvc

```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-sc-claim
  annotations:
    # not required, depending on whether this annotation was shown in the storage class description
    nfs.io/storage-path: "test-path"
spec:
  storageClassName: nfs-client
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 1Mi
```

## nginx 测试 sc

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nginx-pvc
  annotations:
    # not required, depending on whether this annotation was shown in the storage class description
    nfs.io/storage-path: "nfs-test-nginx-pvc"
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: "nfs-sc-client"
  resources:
    requests:
      storage: 50Mi

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
            # 和创建的 pvc 名称一致
            claimName: nginx-pvc
  replicas: 2
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

