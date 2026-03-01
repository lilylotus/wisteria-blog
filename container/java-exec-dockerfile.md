---
title: "Java程序运行镜像构建"
subtitle: "Java程序运行镜像构建|Java程序镜像Dockerfile"
description: "Java程序运行镜像构建|Java程序镜像Dockerfile"
date: 2025-04-01T22:36:09+08:00
lastmod: 2025-05-19T23:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["containerd","Java"]
categories: ["container"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1567.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# Java程序镜像构建

## Dockerfile编写

### Java程序启动脚本

Java 程序启动脚本 `startup.sh`

```bash
#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]"
echo "JAVA_OPTS = [${JAVA_OPTS}]"
cd ${SCRIPT_DIR}

# exec 把终端信号传递给自线程处理
# -Xms4g -Xmx4g -Xmn1512m -server -Xss256k
java -Xms500m -Xmx500m -Xmn300m -Xss1m \
-XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m \
-XX:ParallelGCThreads=2 -XX:ConcGCThreads=1 \
-XX:+UseConcMarkSweepGC -XX:+UseParNewGC \
-XX:CMSInitiatingOccupancyFraction=75.0 -XX:+UseCMSInitiatingOccupancyOnly \
-XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 \
-XX:+CMSScavengeBeforeRemark \
#-XX:+CMSClassUnloadingEnabled \
#-XX:+ScavengeBeforeFullGC \
#-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/heap_dump_%t.hprof \
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${SCRIPT_DIR}/gc.log \
#-XX:+TieredCompilation -XX:+ExplicitGCInvokesConcurrentAndUnloadsClasses \
${JAVA_OPTS} -jar ${SCRIPT_DIR}/boot.jar

```

推荐使用 `exec java`  来运行 java 程序（这样可以处理 KILL 信号），这样 shell 可以把 SIGTERM 信号传递给 java。

常见 ExitCode：

- ExitCode: 143 -128 = 15
  - 表明容器收到了 SIGTERM 信号，终端关闭，对应 `kill -15`，一般对应 `docker stop` 命令
- ExitCode: 137 - 128 = 9
  - 表明容器收到了 SIGKILL 信号，进程被杀掉，对应 `kill -9`
  - 引发 SIGKILL 的是 `docker kill`，可能用户或 docker 守护程序来发起，执行 `docker kill` 命令
  - 如果 pod 中的 limit 资源设置较小，会运行内存不足导致 OOM Killed，此时 state 中的 OOMKilled 值为true，可以在系统的 dmesg 中看到 oom 日志

### 镜像Dockerfile

[dockerhub OpenJDK 镜像选择](https://hub.docker.com/_/openjdk)

debian版本：

- debian 12：[Bookworm](https://www.debian.org/releases/bookworm/) [2023-06-10/2026-06-10]
- debian 11：[Bullseye](https://www.debian.org/releases/bullseye/) [2021-08-14/2024-08-14]
- debian 10：[Buster](https://www.debian.org/releases/buster/) [2019-07-06/2022-09-10]

opendjdk：

- openjdk:8-jdk-slim (debian 11 - bullseye)
- openjdk:11-jdk-slim (debian 11 - bullseye)
- openjdk:17-jdk-slim (debian 11 - bullseye)
- openjdk:21-jdk-slim / openjdk:21-jdk-slim-bookworm

```dockerfile
FROM openjdk:8-jdk-slim
WORKDIR /opt/
COPY boot.jar /opt/
COPY startup.sh /opt/
EXPOSE 31808
ENTRYPOINT ["bash","startup.sh"]
```

- 也等同于这样写法：`ENTRYPOINT ["sh", "-c", "exec java -jar /app.jar"]`

### Dockerfile镜像构建命令

```bash
nerdctl --debug build -t app:v1 .
```

### 容器运行命令

```bash
nerdctl run -d -p 31808:31808 --name app app:v1
```

### 容器运行资源

查看运行容器运行资源占用情况：列出了每个容器的ID、名称、CPU使用百分比、内存使用量及限制、网络I/O和磁盘I/O等信息

```
nerdctl stats <id_or_name>
```

## 常用 jdk 工具命令

**`jstack`** 分析线程

```
top -Hp <pid>
```

```bash
#!/bin/bash
PID=$1
SPID=$2
jstack $PID | grep '0x'$(printf %x ${SPID}) -C 5 --color
```

**`jinfo`** 查看 JVM 配置

```bash
jinfo <pid>
# 查看 jvm 运行参数
jinfo -flags <pid>
```

**`jmap`** 堆内存

```bash
# 堆内存dump
jmap -dump:live,format=b,file=heap.hprof <pid>

# 查看运行内存
jmap -heap <pid>

# jdk11
jhsdb jmap --heap --pid <pid>
```

**`jcmd`** 工具

```bash
jcmd <pid> VM.native_memory
jcmd <pid> GC.heap_info
```

**`jstat`** gc 日志 （内存统计）

```bash
# 获取 GC 日志
jstat -gcutil <pid> 1000 10

# 每 1 秒一次，共 5 次
jstat -gcutil <pid> 1000 5
```

## jdk1.8

[JDK 1.8 GC 参数配置参考博客](https://blog.verysu.com/aritcle/java/2022)，若有冒犯，请联系修改调整（写的好，情不自禁就引用了）。

jdk 1.8 对容器化特性的支持：

- CMS适用场景：中小规模堆内存（<6GB）、对延迟敏感、允许偶尔的Full GC停顿（如电商交易系统）。
- 从 8u191 开始引入了 java10+ 上的 `UseContainerSupport` 选项，而且是默认启用的，不用设置。

jdk 1.8 CMS 垃圾回收器参数配置说明：

- 通过 JVM 的参数 `-Xmx` 和 `-Xms` 可以设置 JVM 的堆大小，但是此时操作系统分配的只是虚拟内存，只有 JVM 真正要使用该内存时，才会被分配物理内存。**一般将可用物理内存的 50%-70% 分配给 JVM**

- 老年代回收阈值：`-XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly`
  - **这个阈值表示老年代(Old Generation)堆空间的占用百分比**
  - 申明年轻代和老年代的大小，由于采用的 CMS+ParNew，建议堆大小不要超过 8G，最好 6G 以内，因为 CMS+ParNew 组合情况下发生的 FGC 是采用 CMS 算法且单线程回收，如果堆内存很大，FGC 时 STW 时间会非常恐怖。
  - 是指设定 CMS 在对内存占用率达到 75% 的时候开始 GC(因为 CMS 会有浮动垃圾, 所以一般都较早启动 GC)
  - **通常，这种设置是在对应用程序的内存使用模式有深入了解的情况下才会使用，以确保垃圾回收发生在最合适的时间点，避免过早或过晚的垃圾回收导致的性能问题。**
- CMS 压缩：`-XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0`
  - -XX:+UseCMSCompactAtFullCollection ：作用就是用来做内存碎片整理。具体就是CMS 完成Full GC后，再次进行stop the world，然后将存活对象挪到一起，空出来一片连续内存，避免内存碎片。
  - -XX:CMSFullGCsBeforeCompaction=0：CMS垃圾回收器Full GC多少次后才开始做内存碎片整理，默认就是 0，意味着每次FGC后都整理碎片。
- CMS的重新标记阶段也是会 Stop the world ：`-XX:+CMSScavengeBeforeRemark`
  - 在 CMS GC 前启动一次 ygc，目的在于减少 old gen 对 ygc gen 的引用，降低 remark 时的开销-----一般 CMS 的 GC 耗时 80% 都在 remark 阶段
  - “remark”阶段是一个重要的步骤，其主要任务是对存活的对象进行重新标记，以确保在垃圾回收过程中没有遗漏可回收的对象。
- `-XX:ParallelGCThreads=2 -XX:ConcGCThreads=1`
  - -XX:ParallelGCThreads=m // STW 暂停时使用的 GC 线程数，一般用满 CPU（指定年轻代垃圾回收的线程数量）
    -XX:ConcGCThreads=n // GC 线程和业务线程并发执行时使用的 GC 线程数，一般较小
  - 2C4G：-XX:ParallelGCThreads=2 -XX:ConcGCThreads=1
  - 4C8G：-XX:ParallelGCThreads=4 -XX:ConcGCThreads=1
  - 8C16G：-XX:ParallelGCThreads=8 -XX:ConcGCThreads=2
- `-XX:+ScavengeBeforeFullGC`
  - 它会在 Full GC 开始前先尝试进行一次年轻代的垃圾回收。这样做的主要目的是尽可能减少 Full GC 的工作量
- `-XX:HeapDumpPath`
  - %t 是一个占位符，表示JVM会自动添加一个时间戳到文件名中，以便区分不同时间生成的堆转储文件。

我们知道在【并发清理】这个期间，程序是可以正常运行的。原因是老年代在回收碎片，程序依然可以继续往里面放新对象。此时如果系统要往老年代放新对象，放不下（为啥会往老年代放新对象？有些对象是可以直接进老年代的），这时候会发生 Concurrent  mode failure，而不是 OOM。这时候 JVM 自动使用 Serial Old 垃圾回收器替换 CMS 回收器，强行让程序 stop the word，程序暂停运行，不允许新对象生成。直到 GC 完成后再恢复。

### 显式 CMS GC

年轻代采用的是 ParNew，老年代采用的是 CMS（concurrent mark-sweep）垃圾回收

```
-XX:+UseConcMarkSweepGC -XX:+UseParNewGC
```

### 堆大小

申明年轻代和老年代的大小，由于采用的 CMS+ParNew，建议堆大小不要超过 8G，最好 6G 以内，因为 CMS+ParNew 组合情况下发生的 FGC 是采用 CMS 算法且单线程回收，如果堆内存很大，FGC 时 STW 时间会非常恐怖。

```
-Xmx4g -Xms4g -Xmn1512m
```

### 线程栈

JDK8 默认的线程栈大小为 1M，有点偏大，以经验绝大部分微服务项目是可以调整为 512k，甚至 256k 的（项目 256k，运行的棒棒哒）：

```
-Xss256k
```

### 老年代回收阈值

既然配置的是CMS，那么如下两个参数一定要加上。为什么要加上这两个JVM参数呢？这是因为 CMS 回收条件非常复杂，如果不通过`CMSInitiatingOccupancyFraction`和 `UseCMSInitiatingOccupancyOnly` 限制只在老年代达到 75% 才回收的话（这个阈值可以根据具体情况适当调整），当线上碰到一些 CMS GC 时，是很难搞清楚原因的：

```
-XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly
```

### 元数据空间

如果是微服务架构，那么对于绝大部分应用来说，128M 的元数据完全够用。不过，JDK8 的元数据空间并不是指定多少就初始化多大的空间。而是按需扩展元数据空间。所以，我们可以设置 256M。如果不设置这两个参数的话，元数据空间默认初始化只有 20M 出头，那么就会在应用启动过程中，Metaspace 扩容发生 FGC：

```
-XX:MaxMetaspaceSize=256m -XX:MetaspaceSize=256M
```

### dump路径

设定如下两个参数（需要说明的是，HeapDumpPath 参数指定的路径需要提前创建好，JVM 没办法在生成 dump 文件时创建该目录），当 JVM 内存导致导致 JVM 进程退出时能自动在该目录下生成 dump 文件：

```
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/log/jvmdump/
```

### GC日志

```
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/data/log/gclog/gc.log
```

### 压缩

CMS GC 是并发的垃圾回收器，它采用的是标记清除算法，而不是压缩算法。意味着随着时间的推移，碎片会越来越多，JVM 终究会触发内存整理这个动作。那么，什么时候整理内存碎片呢？跟下面两个参数有很大的关系。第一个参数是开启这个能力，第二个参数表示在压缩（compaction）内存之前需要发生多少次不压缩内存的FGC。CMS GC不是FGC，在CMS GC搞不定的时候（比如：concurrent mode failure），会触发完全STW但不压缩内存的FGC（假定命名为NoCompactFGC），或者触发完全STW并且压缩内存的FGC（假定命名为CompactFGC）。所以，这个参数的意思就是，连续多少次NoCompactFGC后触发CompactFGC。如果中间出现了CMS GC，那么又需要重新计数NoCompactFGC发生的次数：

```
-XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0
```

### 容器化运行

启动 **`entrypoint.sh`** 脚本

```bash
#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

MEM_OPTS=${MEM_OPTS:-"-XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=75.0 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=192m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseConcMarkSweepGC -XX:+UseParNewGC"}
JVM_OPTS=${JVM_OPTS:-"-XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+CMSScavengeBeforeRemark -XX:+ScavengeBeforeFullGC -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0"}
OTHER_OPTS=${OTHER_OPTS:-""}

echo "JVM MEM_OPTS [${MEM_OPTS}]" | tee -a startup.log
echo "JVM GC_OPTS [${GC_OPTS}]" | tee -a startup.log
echo "JVM JVM_OPTS [${JVM_OPTS}]" | tee -a startup.log
echo "JVM OTHER_OPTS [${OTHER_OPTS}]" | tee -a startup.log

exec java \
${MEM_OPTS} \
${GC_OPTS} \
${JVM_OPTS} \
${OTHER_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/heapdump_%p_%t.hprof \
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${SCRIPT_DIR}/gc-%t.log \
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=7 -XX:GCLogFileSize=50m \
-jar ${SCRIPT_DIR}/app.jar
```

容器 **`Dockerfile`**

```dockerfile
FROM jdk-8u421-debian-12.10:v1
WORKDIR /opt/
COPY app.jar /opt/app.jar
COPY entrypoint.sh /opt/
ENTRYPOINT ["bash","entrypoint.sh"]
```

## jdk 11

jdk 11 启动脚本

```bash
#!/bin/bash

SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]"
cd ${SCRIPT_DIR}

java -Xms8g -Xmx8g -Xss1m \
-XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m \
-XX:+UseG1GC \
-XX:G1HeapRegionSize=8m \
-XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 \
-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0 \
#-XX:ParallelGCThreads=4 -XX:ConcGCThreads=2 \
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/heap_dump_%t.hprof \
-Xlog:gc*:file=${SCRIPT_DIR}/gc.log:time,level:filecount=5,filesize=20M \
-jar ${SCRIPT_DIR}/boot.jar
```

### jdk 容器化参数

可以通过设置 `-Xms` 和 `-Xmx` 来限制堆大小，但该方式在容器运行时存在以下两个问题：

- 当规格大小调整后，需要重新设置堆大小参数。
- 当参数设置不合理时，会出现应用堆大小未达到阈值但容器OOM被强制关闭的情况。

| 内存规格大小 | JVM堆大小 |
| :----------: | :-------: |
|     1 GB     |  600 MB   |
|     2 GB     |  1434 MB  |
|     4 GB     |  2867 MB  |
|     8 GB     |  5734 MB  |

```bash
# 内存管理
# 必须设置（避免JVM使用宿主机内存）
-XX:+UseContainerSupport           # 启用容器支持（JDK8u191+默认启用）
-XX:MaxRAMPercentage=75.0          # 使用容器内存的75%（推荐值）
-XX:InitialRAMPercentage=50.0      # 初始内存占比

# 替代传统方案（不推荐在容器中使用）
# -Xmx 和 -Xms 在容器中可能导致问题

# CPU资源适配
-XX:ActiveProcessorCount=<N>       # 显式设置CPU核数（覆盖自动检测）
-XX:ParallelGCThreads=<N>          # 并行GC线程数（建议=CPU核数）
-XX:ConcGCThreads=<M>              # 并发GC线程数（建议=ParallelGCThreads/4）
```

- `-XX:MaxRAMPercentage=75.0`: 限制JVM最多使用系统内存的75%。

- 考虑添加容器化支持`-XX:+UseContainerSupport`（虽然默认已启用）

- 容器控制
  - `-XX:InitialRAMPercentage` / [`-Xms`]、`-XX:MaxRAMPercentage`（25.0）、`-XX:MinRAMPercentage`（50.0） （仅限制堆内存大小）
  - `MaxRAMPercentage`、`MinRAMPercentage`(内存小于 250 MB) / [`-Xmx`]以上两个参数主要用于配置堆的最大内存大小
  - `-XX:MaxRAMPercentage` ：设置JVM使用容器内存的最大百分比。由于存在系统组件开销，建议最大不超过75.0，推荐设置为70.0。

docker 运行资源限制

```bash
docker run -m 4g --cpus=2 \
-e JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+UseG1GC" \
my-java-app
```

kubernetes 资源限制

```yaml
resources:
  limits:
    memory: "4Gi"
    cpu: "2"
  requests:
    memory: "3Gi"
    cpu: "1.5"
env:
- name: JAVA_OPTS
  value: "-XX:MaxRAMPercentage=75.0 -XX:ActiveProcessorCount=2"
```

### 容器化运行

启动 **`entrypoint.sh`** 脚本

```bash
#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

MEM_OPTS=${MEM_OPTS:-"-XX:+UseContainerSupport -XX:InitialRAMPercentage=50.0 -XX:MaxRAMPercentage=75.0 -XX:MetaspaceSize=128m -XX:MaxMetaspaceSize=192m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseG1GC"}
# 默认低延迟配置，小堆(<4G)：1-2m / 中堆(4-32G)：4m / 大堆(>32G)：8m
# -XX:ConcGCThreads=4
JVM_OPTS=${JVM_OPTS:-"-XX:G1HeapRegionSize=2m -XX:MaxGCPauseMillis=100 -XX:InitiatingHeapOccupancyPercent=35 -XX:G1ReservePercent=20 -XX:+ParallelRefProcEnabled -XX:+PerfDisableSharedMem"}
OTHER_OPTS=${OTHER_OPTS:-""}

echo "JVM MEM_OPTS [${MEM_OPTS}]" | tee -a startup.log
echo "JVM GC_OPTS [${GC_OPTS}]" | tee -a startup.log
echo "JVM JVM_OPTS [${JVM_OPTS}]" | tee -a startup.log
echo "JVM OTHER_OPTS [${OTHER_OPTS}]" | tee -a startup.log

exec java \
${MEM_OPTS} \
${GC_OPTS} \
${JVM_OPTS} \
${OTHER_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/heapdump_%p_%t.hprof \
-Xlog:gc*=info:file=${SCRIPT_DIR}/gc-%t.log:time,uptime,level,tags:filecount=7,filesize=50m \
-jar ${SCRIPT_DIR}/app.jar
```

容器 **`Dockerfile`**

```dockerfile
FROM jdk-11024-debian-12.10:v1
WORKDIR /opt/
COPY app.jar /opt/app.jar
COPY entrypoint.sh /opt/
ENTRYPOINT ["bash","entrypoint.sh"]
```

