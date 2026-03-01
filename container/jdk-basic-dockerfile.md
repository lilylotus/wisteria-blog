---
title: "jdk 镜像推荐构建"
subtitle: "jdk镜像构建"
description: "jdk镜像构建|jdk推荐容器镜像构建"
date: 2025-03-31T22:36:09+08:00
lastmod: 2025-04-11T22:30:09+08:00
draft: false

authors: ["yzx"]
tags: ["containerd"]
categories: ["container"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1203.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# jdk镜像构建

## openjdk

### jdk1.8

```dockerfile
FROM openjdk:8-jdk
CMD ["java", "-version"]
```

```bash
nerdctl --debug build -t openjdk:v8 .
```

### jdk11

```dockerfile
FROM openjdk:11-jdk-slim
CMD ["java", "-version"]
```

```bash
nerdctl --debug build -t openjdk:v11 .
```

### jdk17

```dockerfile
FROM openjdk:17-jdk-slim
CMD ["java", "-version"]
```

```bash
nerdctl --debug build -t openjdk:v17 .
```

## oracle jdk自行构建

**注意：** [Oracle Java Jdk](https://www.oracle.com/java/technologies/downloads/) 各版本的使用授权许可。

### nerdctl build

这里使用 [containerd](https://containerd.io/) 配合使用的镜像构建工具 [buildkitd](https://github.com/moby/buildkit), [使用 `nerdctl build` 配置 Buildkit](https://github.com/containerd/nerdctl/blob/main/docs/build.md#setting-up-nerdctl-build-with-buildkit)

**注意：** Buildkit 在 OCI worker 模式下是由 Buildkit 自己来管理容器和镜像的，不能使用 nerdctl 操作的镜像。

配置 Buildkit 文件 `/etc/buildkit/buildkitd.toml` 启用 containerd worker。

```toml
[worker.oci]
  enabled = false

[worker.containerd]
  enabled = true
  # namespace should be "k8s.io" for Kubernetes (including Rancher Desktop)
  # blank default namespace is 'buildkit' not 'default'
  namespace = "default"
```

重启 buildkitd 服务

```bashs
systemctl daemon-reload && systemctl restart buildkitd
```

测试构建 Dockerfile

```dockerfile
FROM ubuntu:24.04
CMD ["uname", "-a"]
```

构建命令

```bash
# 先用 nerdctl 拉取镜像
nerdctl pull ubuntu:24.04
# 在构建使用本地镜像时时
nerdctl --debug build -t ubuntu-24.04:v1 .
```

### jdk1.8-ubuntu-24.04

ubuntu 24.04 国内阿里源：ubuntu.sources

```
Types: deb
URIs: http://mirrors.aliyun.com/ubuntu/
Suites: noble noble-updates noble-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
```

构建 Dockerfile

```dockerfile
FROM ubuntu:24.04

ENV LANG=en_US.UTF-8
ENV TZ=Asia/Shanghai

COPY ./ubuntu.sources /etc/apt/sources.list.d/ubuntu.sources

RUN apt-get update -y \ 
    && apt-get upgrade -y \
    && apt-get install -y tzdata curl vim iputils-ping locales \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD jdk-8u421-linux-x64.tar.gz /usr/local/src/

ENV JAVA_HOME=/usr/local/src/jdk1.8.0_421
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]
```

构建命令，构建后镜像大小在 216.1 MiB 左右

```bash
nerdctl --debug build -t jdk-8u421-ubuntu-24.04:v1 .
```

测试运行

```bash
nerdctl run -it --rm jdk-8u421-ubuntu-24.04:v1 bash
```

### jdk1.8-debian-12.10

debian 国内镜像源：[debian 12 镜像源选择](https://www.debian.org/mirror/list)，[debian 12 源](https://mirrors.ustc.edu.cn/help/debian.html#__tabbed_3_2)

debian.sources -> /etc/apt/sources.list.d/debian.sources

```
Types: deb
URIs: http://mirrors.ustc.edu.cn/debian
Suites: bookworm bookworm-updates
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://mirrors.ustc.edu.cn/debian-security
Suites: bookworm-security
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

构建 Dockerfile

```dockerfile
FROM debian:12.10

ENV LANG=en_US.UTF-8
ENV TERM=xterm

COPY ./debian.sources /etc/apt/sources.list.d/debian.sources

RUN apt-get update -y \ 
    && apt-get upgrade -y \
    && apt-get install -y curl vim iputils-ping locales procps htop \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD jdk-8u421-linux-x64.tar.gz /usr/local/src/

ENV JAVA_HOME=/usr/local/src/jdk1.8.0_421
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]
```

构建镜像，大小在 217.8 MiB 左右

```bash
nerdctl --debug build -t jdk-8u421-debian-12.10:v1 .
```

测试运行

```bash
nerdctl run -it --rm jdk-8u421-debian-12.10:v1 bash
```

### jdk1.8-centos-7.9.2009

Centos-7.9.2009 国内阿里源：centos7-ali.repo

```bash
curl -o centos7.repo https://mirrors.aliyun.com/repo/Centos-7.repo
sed -i -e '/mirrors.cloud.aliyuncs.com/d' -e '/mirrors.aliyuncs.com/d' centos7.repo
```

构建 Dockerfile

```dockerfile
FROM centos:7.9.2009

ENV LANG=en_US.UTF-8
RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

ADD jdk-8u421-linux-x64.tar.gz /usr/local/src/

ENV JAVA_HOME=/usr/local/src/jdk1.8.0_421
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]
```

构建镜像，大小在 214.4 MiB 左右

```bash
nerdctl --debug build -t jdk-8u421-centos-7.9.2009:v1 .
```

测试运行

```bash
nerdctl run -it --rm jdk-8u421-centos-7.9.2009:v1 bash
```