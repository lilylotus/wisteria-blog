---
title: "Java JDK 镜像构建"
subtitle: "Java 镜像构建|JDK 镜像构建"
description: "Java JDK 镜像构建|JDK 镜像构建"
date: 2025-08-18T22:06:09+08:00
lastmod: 2025-08-20T22:06:09+08:00
draft: false

authors: ["yzx"]
tags: ["Java", "containerd"]
categories: ["Java"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2422.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Java镜像构建

## Java 镜像推荐

Java 应用程序容器化运行推荐使用 [OpenJDK](https://openjdk.org/) 镜像作为 Java 运行镜像。

推荐 OpenJDK 镜像有两个：

1. OpenJDK 官方镜像：openjdk:17-jdk 【标准镜像 (~300MB)】 / openjdk:17-jdk-slim 【Slim镜像 (~150MB) - 移除文档、调试工具等】，都是基于 debian bullseye （11） 系统
2. Eclipse Temurin（原 AdoptOpenJDK）是目前最受欢迎的 OpenJDK 发行版之一  **【推荐】**：eclipse-temurin:17-jdk-jammy （基于 Ubuntu 22.04）

## OpenJDK 发行版镜像

### OpenJDK 官方镜像

OpenJDK 官方镜像 Dockerfile 编写，添加运行工具和系统定制。

```dockerfile
FROM openjdk:8-jdk-slim

# openjdk:17-jdk         # 完整版(基于Debian)
# openjdk:17-jdk-slim    # 精简版(基于Debian Slim)

# openjdk:8-jdk -> debain 11(bullseye)
# openjdk:11-jdk -> debain 11(bullseye)
# openjdk:17-jdk -> debain 11(bullseye)

COPY ./debian11.sources /etc/apt/sources.list.d/debian.sources

RUN cp /etc/apt/sources.list /etc/apt/sources.list.backup \
    && echo "" > /etc/apt/sources.list \
    && apt-get update -y \
    && apt-get install -y curl vim iputils-ping locales procps htop telnet tzdata \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TERM=xterm
ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8

WORKDIR /opt/

CMD ["java", "-version"]
```

#### Debian 软件源

Debian 11 （bullseye）

```
Types: deb
URIs: http://mirrors.ustc.edu.cn/debian
Suites: bullseye bullseye-updates
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://mirrors.ustc.edu.cn/debian-security
Suites: bullseye-security
Components: main contrib non-free
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
```

Debian 12 （bookworm）

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

### Eclipse Temurin 镜像（推荐）

[Eclipse Temurin](https://adoptium.net/) 是目前最受欢迎的 OpenJDK 发行版之一

- 完全满足企业级 Java 应用的所有需求
- 在性能、稳定性和安全性上表现优异
- 拥有活跃的社区支持和商业可选服务

Eclipse Temurin 镜像 Dockerfile：

```dockerfile
FROM eclipse-temurin:8-jdk-jammy

# ubuntu 24.04 (Noble) ; ubuntu 22.04 (Jammy) ; ubuntu 20.04 (Focal) ; ubuntu 18.04 (Bionic)
# eclipse-temurin:17-jdk-noble / eclipse-temurin:17-jdk-jammy /

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends curl vim iputils-ping locales procps htop telnet tzdata \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV TERM=xterm
ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8

WORKDIR /opt/

CMD ["java", "-version"]
```

## Oracle JDK 镜像

### 基于 Debian 镜像

基于 Debian 镜像手动构建 Oracle JDK 镜像 Dockerfile：

```dockerfile
FROM debian:12.10

COPY ./sources.list /etc/apt/sources.list.d/debian.sources

RUN apt-get update -y \ 
    && apt-get install -y curl vim iputils-ping locales procps htop telnet tzdata \
    && sed -i 's/# zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/ ; s/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ADD jdk-8u431-linux-x64.tar.gz /usr/local/src/

ENV TERM=xterm
ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV JAVA_VERSION=8u431
ENV JAVA_HOME=/usr/local/src/jdk1.8.0_431
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]
```

debian 12（bookworm） 软件源 sources.list

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

### 基于 Centos7 镜像

基于 CentOS7 镜像构建 Oracle JDK 的 Dockerfile：

```dockerfile
FROM centos:7.9.2009

COPY ./Centos7.repo /opt/CentOS-Base.repo

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && mkdir -p /etc/yum.repos.d/backup \
    && mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/backup/ \
    && mv /opt/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo \
    && yum clean all \
    && yum makecache \
    && yum install -y curl wget telnet vim \
    && yum clean all 

ADD jdk-8u431-linux-x64.tar.gz /usr/local/src/

ENV TZ=Asia/Shanghai
ENV LANG=en_US.UTF-8
ENV JAVA_VERSION=8u431
ENV JAVA_HOME=/usr/local/src/jdk1.8.0_431
ENV CLASSPATH=.:${JAVA_HOME}/lib/dt.jar:${JAVA_HOME}/lib/tools.jar:${JAVA_HOME}/jre/lib/rt.jar
ENV PATH=${PATH}:${JAVA_HOME}/bin

WORKDIR /opt/

CMD ["java", "-version"]
```

CentOS7 软件镜像源 Centos7.repo

```properties
[base]
name=CentOS-$releasever - Base - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/os/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#released updates
[updates]
name=CentOS-$releasever - Updates - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/updates/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that may be useful
[extras]
name=CentOS-$releasever - Extras - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/extras/$basearch/
gpgcheck=1
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#additional packages that extend functionality of existing packages
[centosplus]
name=CentOS-$releasever - Plus - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/centosplus/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7

#contrib - packages by Centos Users
[contrib]
name=CentOS-$releasever - Contrib - mirrors.aliyun.com
failovermethod=priority
baseurl=http://mirrors.aliyun.com/centos/$releasever/contrib/$basearch/
gpgcheck=1
enabled=0
gpgkey=http://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7
```

## Java 应用运行镜像构建

### Dockerfile 编写

Java 应用运行镜像 Dockerfile 文件：

```dockerfile
FROM jdk8-8u431-debian-1210:v1
WORKDIR /opt/
COPY app.jar /opt/app.jar
COPY entrypoint.sh /opt/
ENTRYPOINT ["bash","/opt/entrypoint.sh"]
```

### entrypoint 运行脚本

#### jdk 1.8

jdk 1.8 应用运行 entrypoint 脚本：

```bash
#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

ncpu=$(nproc)
ConcGCThreads=$(expr $ncpu / 4)
ConcGCThreads=$(( $ConcGCThreads > 1 ? $ConcGCThreads : 1 ))
echo "cpu [${ncpu}] nthread [${ConcGCThreads}]"

# https://blog.gceasy.io/java-cms-gc-tuning/

MEM_OPTS=${MEM_OPTS:-"-XX:InitialRAMPercentage=90.0 -XX:MaxRAMPercentage=90.0 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=128m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseConcMarkSweepGC -XX:+UseParNewGC"}
# -XX:NewRatio=1
JVM_OPTS=${JVM_OPTS:-"-XX:CMSInitiatingOccupancyFraction=80 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:+CMSScavengeBeforeRemark -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
OTHER_OPTS=${OTHER_OPTS:-""}

# -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly # 限制只在老年代达到 75% 才回收
# -XX:+CMSScavengeBeforeRemark # 在重新标记前执行 Young GC
# -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 # 启用 Full GC 压缩，避免 Full GC 后内存碎片，第一个参数是开启这个能力，第二个参数表示在压缩

# -XX:+CMSClassUnloadingEnabled           # 启用类卸载
# -XX:+ExplicitGCInvokesConcurrent        # System.gc() 时使用 CMS 而非 Full GC
# -XX:+CMSParallelInitialMarkEnabled      # 初始标记阶段并行化
# -XX:+CMSParallelRemarkEnabled           # 重新标记阶段并行化

# JMX -> JMC 
JMX_OPTS="-XX:+UnlockCommercialFeatures -XX:+FlightRecorder -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=7091 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

echo "JVM MEM_OPTS [${MEM_OPTS}]" | tee -a startup.log
echo "JVM GC_OPTS [${GC_OPTS}]" | tee -a startup.log
echo "JVM JVM_OPTS [${JVM_OPTS}]" | tee -a startup.log
echo "JVM OTHER_OPTS [${OTHER_OPTS}]" | tee -a startup.log

EXEC_CMD="java \
${MEM_OPTS} \
${GC_OPTS} \
${JVM_OPTS} \
${OTHER_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/logs/heapdump_%p_%t.hprof \
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${SCRIPT_DIR}/logs/gc-%t.log \
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=50m \
-jar ${SCRIPT_DIR}/app.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/
exec ${EXEC_CMD}
```

#### jdk 11(+)

jdk 11 及以上版本运行脚本：

```bash
#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

ncpu=$(nproc)
ConcGCThreads=$(expr $ncpu / 4)
ConcGCThreads=$(( $ConcGCThreads > 1 ? $ConcGCThreads : 1 ))
echo "cpu [${ncpu}] nthread [${ConcGCThreads}]" | tee -a startup.log

# https://blog.gceasy.io/simple-effective-g1-gc-tuning-tips/
# -XX:+UseStringDeduplication

MEM_OPTS=${MEM_OPTS:-"-XX:+UseContainerSupport -XX:InitialRAMPercentage=90.0 -XX:MaxRAMPercentage=90.0 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=128m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseG1GC"}
# 默认低延迟配置，小堆(<4G)：1-2m / 中堆(4-32G)：4m / 大堆(>32G)：8m
JVM_OPTS=${JVM_OPTS:-"-XX:G1HeapRegionSize=2m -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 -XX:+UseStringDeduplication -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
OTHER_OPTS=${OTHER_OPTS:-""}

# -XX:G1ReservePercent=10 # 10-15%（默认值）指定了堆内存中应保留作为"空闲空间"的比例，主要作为 GC 过程中的临时内存缓冲区，确保有足够空间用于对象晋升（从年轻代到老年代）
# -XX:+PerfDisableSharedMem # 禁用 JVM 在共享内存中存储性能统计数据的机制

# -XX:ParallelGCThreads=8 # 并行GC线程数（建议等于CPU核心数）
# -XX:ConcGCThreads=2 # 并发标记线程数（通常为ParallelGCThreads的1/4）
# -XX:+ParallelRefProcEnabled # 开启并行引用处理

# -XX:G1NewSizePercent=20 # 年轻代初始占比（默认堆的5%）
# -XX:G1MaxNewSizePercent=60 # 年轻代最大占比（默认60%）[降低最大占比（减少GC停顿）]
# Error: VM option 'G1NewSizePercent' is experimental and must be enabled via -XX:+UnlockExperimentalVMOptions

# -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=512m # 元空间大小设置
#-XX:MaxDirectMemorySize=1g # 堆外内存限制（如果使用NIO等）

# -XX:InitiatingHeapOccupancyPercent=45 # 启动并发标记的堆占用率阈值（默认45%），老年代占用率达到此百分比时启动并发标记

# -XX:G1MixedGCLiveThresholdPercent=85 # 混合回收阈值，Region 中存活对象占比超过此值则不回收
# Error: VM option 'G1MixedGCLiveThresholdPercent' is experimental and must be enabled via -XX:+UnlockExperimentalVMOptions.

# JFR飞行记录（JDK11商业特性）
# -XX:StartFlightRecording=duration=60s,stackdepth=128,settings=profile,filename=recording.jfr

# JDK 11+需要显式启用JFR
JMX_OPTS="-XX:+FlightRecorder -XX:StartFlightRecording=disk=true,filename=${SCRIPT_DIR}/recording.jfr,maxsize=1024m,maxage=1d -Dcom.sun.management.jmxremote -Dcom.sun.management.jmxremote.port=7091 -Dcom.sun.management.jmxremote.ssl=false -Dcom.sun.management.jmxremote.authenticate=false"

echo "JVM MEM_OPTS [${MEM_OPTS}]" | tee -a startup.log
echo "JVM GC_OPTS [${GC_OPTS}]" | tee -a startup.log
echo "JVM JVM_OPTS [${JVM_OPTS}]" | tee -a startup.log
echo "JVM OTHER_OPTS [${OTHER_OPTS}]" | tee -a startup.log

EXEC_CMD="java \
${MEM_OPTS} \
${GC_OPTS} \
${JVM_OPTS} \
${OTHER_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/logs/heapdump_%p_%t.hprof \
-Xlog:gc*=info:file=${SCRIPT_DIR}/logs/gc-%t.log:time,uptime,level,tid,tags:filecount=10,filesize=50M \
-jar ${SCRIPT_DIR}/app.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/
exec ${EXEC_CMD}
```

### Java 常用监控命令

#### jdk 1.8

线程栈分析：

[Java 线程堆栈分析工具 （IBM Thread and Monitor Dump Analyzer for Java (TMDA)）](https://www.ibm.com/support/pages/ibm-thread-and-monitor-dump-analyzer-java-tmda)

1. 某个 Java 进程中最耗费 CPU 的 Java 线程 : `ps -ef | grep mrf-center | grep -v grep`
2. 线程 id 转 16 进制： `printf "%x\n" <pid>`
3. jstack 找出占用线程：`jstack <pid> | grep 54ee`

```bash
# 线程栈
jstack -l <pid> > jdk-stack.txt
```

堆内存分析：

[Java 内存 dump 分析工具 (Memory Analyzer (MAT))](https://www.eclipse.org/mat/)

```bash
$ jmap -dump:format=b,file=heap.hprof <pid>

jmap -dump:[live,]format=b,file=jmap.bin <pid>
```

- `live` 参数是可选的，如果指定，则只转储堆中的活动对象；如果没有指定，则转储堆中的所有对象。
- `format=b` 表示以hprof二进制格式转储Java堆的内存。
- `file=<filename>` 用于指定快照dump文件的文件名。

内存监控工具：

```bash
# 格式：jstat [option]  lvmid  interval  count
$ jstat -gc <pid> 250 20
# 每 250 毫秒查询一次进程垃圾收集状况，一共查询 20 次
```

#### jdk 11

jcmd (推荐)

```bash
# 列出所有 Java 进程
jcmd -l

# 查看特定进程的内存使用（替换 <pid>）
jcmd <pid> VM.native_memory
jcmd <pid> GC.heap_info
jcmd <pid> VM.info

# 显示堆内存摘要
jmap -heap <pid>

# 生成堆转储文件（谨慎使用，生产环境可能影响性能）
jmap -dump:live,format=b,file=heap.hprof <pid>
```

jhsdb 使用

```bash
# Java 运行信息
jhsdb jinfo --pid <PID>
# Java 运行栈
jhsdb jstack --pid <PID>
# Java 堆内存信息
jhsdb jmap --heap --pid <PID>

# 生成线程转储
jhsdb jstack --pid <PID> > thread_dump.txt
# 带锁信息
jhsdb jstack --locks --pid <PID>

# 详细堆信息
jhsdb jmap --heap --pid <PID>
# 生成堆转储
jhsdb jmap --binaryheap --pid <PID> --file heap.bin
# 堆内存直方图
jhsdb jmap --histo --pid <PID>

# 查看所有系统属性
jhsdb jinfo --sysprops --pid <PID>
# 查看所有 JVM 标志
jhsdb jinfo --flags --pid <PID>
```

