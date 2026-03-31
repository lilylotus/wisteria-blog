---
title: "Java运行容器镜像构建"
subtitle: "Java运行容器镜像构建"
description: "JDK基础镜像构建|Java运行容器推荐镜像选择"
date: 2026-03-26T22:00:00+08:00
lastmod: 2026-03-26T22:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["containerd","Java"]
categories: ["container"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2630.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Java运行容器镜像构建

## 主流 Java 镜像比较

选择 Java 运行镜像的核心原则是：**使用官方推荐的、持续更新的 OpenJDK 发行版镜像，并尽可能选择只包含运行时(JRE)的精简版本**。官方 `openjdk` 镜像已停止维护，强烈不建议在生产环境使用。

| 镜像类型             | 推荐产品              | 体积 (约)     | 特点与适用场景                                               | 选择建议                                               |
| :------------------- | :-------------------- | :------------ | :----------------------------------------------------------- | :----------------------------------------------------- |
| **企业级通用首选**   | **Eclipse Temurin**   | 200–400MB     | 经过 TCK 认证，社区活跃，兼容性最好，是企业级应用最稳妥的选择。 | **推荐绝大多数项目使用**，特别是当你不确定选什么时。   |
| **云原生与极致轻量** | **Alpine Linux 变体** | 50–150MB      | 体积极小，但使用 `musl libc` 替代 `glibc`，可能带来兼容性问题。 | 对镜像体积有极致要求，且经过充分测试确认兼容性后选用。 |
| **AWS 生态集成**     | **Amazon Corretto**   | 250–450MB     | 由 AWS 提供长期支持，免费，与 AWS 服务集成好。 | 如果你的应用深度部署在 AWS 上，Corretto 是绝佳选择。   |
| **超低内存占用**     | **IBM Semeru**        | 150–250MB     | 基于 OpenJ9 虚拟机，内存占用比 HotSpot 低 30%-50%。 | 适用于内存敏感、需极致弹性的微服务场景。               |
| **SAP 系统配套**     | **SAP Machine**       | 与Temurin相近 | 由 SAP 维护，为 SAP 企业软件优化。 | 仅在运行 SAP 相关技术栈时选用。                        |
| **极高安全性**       | **Chainguard**        | 80–180MB      | 每日重建以修补漏洞，提供完整的软件物料清单(SBOM)和签名。 | 对安全合规有极致要求，且预算充足的项目。               |


选定了镜像类型后，如何挑对具体的标签（Tag）和使用它，同样重要。

- **锁定具体版本，慎用 `latest` 标签**：生产环境务必使用如 `eclipse-temurin:17.0.14-jre` 这样的**具体版本号**标签，而不是 `latest`。这可以确保每次构建镜像时基础环境的一致性，避免因 `latest` 指向的版本发生意外更新而导致上线失败。
- **运行时选择 JRE 而非 JDK**：生产环境只需要运行程序，应优先选择带有 `-jre` 后缀的镜像，如 `eclipse-temurin:17-jre-jammy`。它不包含编译器、调试工具等，体积更小，攻击面也更小，是更安全的选择。

## Eclipse Temurin 基础镜像构建

基于 `eclipse-temurin` 基础 Java 容器适配。

### Dockerfile 编写

```dockerfile
FROM eclipse-temurin:17.0.18_8-jdk-noble

# ubuntu 24.04 (Noble) ; ubuntu 22.04 (Jammy) ; ubuntu 20.04 (Focal) ; ubuntu 18.04 (Bionic)
# eclipse-temurin:17-jre-jammy / eclipse-temurin:17-jdk-jammy
# eclipse-temurin:eclipse-temurin:17.0.18_8-jre-noble / eclipse-temurin:17.0.18_8-jdk-noble

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends wget tree curl vim iputils-ping locales procps htop telnet tzdata \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd -r eclipse && useradd -G eclipse app \
    && mkdir /data/ && chown app:app /data/

ENV TERM=xterm
ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8

WORKDIR /data/

# 使用非root用户运行，提升安全性
#RUN groupadd -r app && useradd -G app app
USER app

# jhsdb jmap 无权限 ERROR: ptrace(PTRACE_ATTACH, ..) failed for 1: Operation not permitted
# docker run --cap-add=SYS_PTRACE myapp # 添加权限
# jcmd 1 GC.heap_dump heap.hprof
# jcmd 1 GC.heap_info

ENTRYPOINT ["java", "-version"]
```

### 运行时资源限制

```bash
# 限制内存 4g，CPU 1.5 核
docker run --memory 4g --cpus 1.5 -e JAVA_OPTS="-XX:MaxRAMPercentage=80.0" java-app
```

### 启动脚本编写

entrypoint.sh

```bash
#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

# exec "$@" 确保信号传递
exec java -jar app.jar
```

dockerfile

```dockerfile
ENTRYPOINT ["bash", "entrypoint.sh"]
```

