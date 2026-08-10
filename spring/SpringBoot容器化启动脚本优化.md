---
title: "容器化SpringBoot启动脚本"
subtitle: "容器化SpringBoot启动脚本|精心设计了容器化Spring Boot启动脚本与环境变量配置方案"
description: "精心设计了容器化Spring Boot启动脚本与环境变量配置方案"
date: 2026-08-10T20:00:00+08:00
lastmod: 2026-08-10T20:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["SpringBoot", "Container"]
categories: []
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2681.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# 容器化SpringBoot启动脚本

## 容器化相关脚本

### Dockerfile镜像文件

```dockerfile
# ========================================
# Spring Boot 生产级 Dockerfile 示例
# ========================================
FROM eclipse-temurin:17-jre-jammy

# 不用root跑Java进程，降低容器逃逸/被攻破后的风险面
RUN groupadd -r spring && useradd -r -g spring spring

WORKDIR /app

# 分层拷贝：先拷贝jar，方便利用Docker层缓存
# (如果jar内容不变，重新build时这一层能直接复用缓存)
COPY target/*.jar app.jar

# entrypoint脚本单独拷贝并赋权
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh && \
    mkdir -p /app/logs && \
    chown -R spring:spring /app

USER spring

# 默认Profile和JVM参数(可被K8s/docker run的环境变量覆盖)
ENV SPRING_PROFILES_ACTIVE=prod
ENV JAVA_OPTS=""

EXPOSE 8080

ENTRYPOINT ["/entrypoint.sh"]

```



### entrypoint.sh启动脚本

```bash
#!/bin/sh
# ========================================
# Spring Boot 容器启动脚本 entrypoint.sh
# 设计目标:
#   1. 支持通过环境变量灵活注入JVM参数、Spring Profile
#   2. 容器内优雅关闭(正确转发SIGTERM给java进程，配合K8s滚动更新不丢请求)
#   3. 自动感知容器CPU/内存限额，避免JVM读到宿主机资源导致OOM
#   4. 保留调试排查手段(可选开启远程调试、堆栈dump)
# ========================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "Script directory: [$SCRIPT_DIR]"
cd ${SCRIPT_DIR}

# ---------- 1. JAR包路径 ----------
# 约定：Dockerfile里统一把应用包命名为 app.jar，简化脚本逻辑
JAR_FILE="${JAR_FILE:-/app/app.jar}"

# ---------- 2. JVM基础参数 ----------
# UseContainerSupport 让JVM感知cgroup限制的CPU/内存，而不是读取宿主机物理资源
# (JDK10+默认已开启，这里显式声明是为了兼容老版本镜像/明确表达意图)
DEFAULT_JAVA_OPTS="-XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0"

# 允许外部覆盖或追加JVM参数，不覆盖默认值，而是拼接在后面
# 使用方式: docker run -e JAVA_OPTS="-Dfastjson.parser.safeMode=true"
JAVA_OPTS="${DEFAULT_JAVA_OPTS} ${JAVA_OPTS:-}"

# ---------- 3. Spring Profile ----------
# 约定：不写死在镜像里，由K8s/docker run时通过环境变量指定，同一镜像多环境复用
if [ -n "$SPRING_PROFILES_ACTIVE" ]; then
    JAVA_OPTS="${JAVA_OPTS} -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}"
fi

# ---------- 4. 可选: 远程调试端口(仅调试环境开启，生产不要开) ----------
# 使用方式: -e ENABLE_REMOTE_DEBUG=true -e DEBUG_PORT=5005
if [ "$ENABLE_REMOTE_DEBUG" = "true" ]; then
    DEBUG_PORT="${DEBUG_PORT:-5005}"
    JAVA_OPTS="${JAVA_OPTS} -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:${DEBUG_PORT}"
    echo "[entrypoint] 远程调试已开启，端口: ${DEBUG_PORT}"
fi

# ---------- 5. 可选: OOM时自动dump堆快照，方便事后排查 ----------
# 使用方式: -e ENABLE_HEAP_DUMP_ON_OOM=true
if [ "$ENABLE_HEAP_DUMP_ON_OOM" = "true" ]; then
    HEAP_DUMP_PATH="${HEAP_DUMP_PATH:-/app/logs/heapdump.hprof}"
    JAVA_OPTS="${JAVA_OPTS} -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=${HEAP_DUMP_PATH}"
fi

# ---------- 6. 应用自身参数(区别于JVM参数，透传给Spring Boot本身) ----------
# 使用方式: -e APP_ARGS="--server.port=8080 --logging.level.root=INFO"
APP_ARGS="${APP_ARGS:-}"

echo "========================================"
echo "[entrypoint] 启动配置"
echo "========================================"
echo "JAR文件:      $JAR_FILE"
echo "JAVA_OPTS:    $JAVA_OPTS"
echo "APP_ARGS:     $APP_ARGS"
echo "========================================"

# ---------- 7. 优雅关闭: 用exec替换shell进程，让java直接成为PID 1 ----------
# 关键点: 不用exec的话，java是sh的子进程，K8s发SIGTERM给PID1(sh)时，
# sh默认不会自动转发信号给子进程java，导致java收不到关闭信号，
# 只能等到K8s的terminationGracePeriodSeconds超时后被SIGKILL强杀，
# 请求可能被硬中断，达不到优雅关闭的效果。
# exec能让java直接接管PID 1，SIGTERM能被java正常捕获，
# Spring Boot会走完整的Bean销毁/连接池关闭/正在处理的请求排空流程。
exec java $JAVA_OPTS -jar "$JAR_FILE" $APP_ARGS

```

### k8s Deployment yaml文件

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-springboot-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-springboot-app
  template:
    metadata:
      labels:
        app: my-springboot-app
    spec:
      # 优雅关闭：给Spring Boot足够时间走完关闭流程(默认30s，按实际业务调整)
      # 需要 >= Spring Boot的 spring.lifecycle.timeout-per-shutdown-phase 配置值
      terminationGracePeriodSeconds: 45

      containers:
        - name: my-springboot-app
          image: my-registry/my-springboot-app:1.0.0

          ports:
            - containerPort: 8080

          env:
            # ---------- JVM参数：安全修复/性能调优相关 ----------
            - name: JAVA_OPTS
              value: >-
                -Dfastjson.parser.safeMode=true
                -XX:+UseG1GC

            # ---------- Spring Profile ----------
            - name: SPRING_PROFILES_ACTIVE
              value: "prod"

            # ---------- 应用自身参数(非JVM参数，直接透传给SpringBoot) ----------
            - name: APP_ARGS
              value: "--server.port=8080"

            # ---------- 敏感信息用Secret，不要明文写在这里 ----------
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: my-app-secret
                  key: db-password

          # ---------- 资源限制：配合entrypoint.sh里的UseContainerSupport生效 ----------
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "2Gi"

          # ---------- 存活探针：确认应用还活着，不活着就重启Pod ----------
          livenessProbe:
            httpGet:
              path: /actuator/health/liveness
              port: 8080
            initialDelaySeconds: 60
            periodSeconds: 10

          # ---------- 就绪探针：确认应用能对外服务了，才把流量转发过来 ----------
          readinessProbe:
            httpGet:
              path: /actuator/health/readiness
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 5

          # ---------- 优雅关闭配合: 给应用一点时间处理完飞行中的请求 ----------
          lifecycle:
            preStop:
              exec:
                command: ["sh", "-c", "sleep 5"]

```

## Java GC垃圾算法

### 物理机 java -jar 启动

按"响应时间优先"（也就是尽量降低GC停顿时间，可以适当牺牲一点吞吐量）来配置，默认 4G 内存。

#### jdk1.8 CMS

```properties
-server
-Xms4g -Xmx4g
-Xmn1600m
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=256m

# CMS核心参数
-XX:+UseConcMarkSweepGC
-XX:+UseParNewGC
-XX:CMSInitiatingOccupancyFraction=70
-XX:+UseCMSInitiatingOccupancyOnly
-XX:+CMSParallelRemarkEnabled
-XX:+CMSScavengeBeforeRemark
-XX:+ExplicitGCInvokesConcurrent
-XX:+CMSClassUnloadingEnabled

# 新生代Eden/Survivor比例，响应时间优先场景适当调大Eden减少晋升频率
-XX:SurvivorRatio=8
-XX:MaxTenuringThreshold=6

# 大对象直接进老年代的阈值(按业务实际情况调，默认单位字节)
# -XX:PretenureSizeThreshold=1m

# 内存碎片处理：CMS是不整理内存的算法，长期运行容易产生碎片
# 触发一定次数Full GC后强制做一次整理，避免碎片过多退化成Serial GC
-XX:CMSFullGCsBeforeCompaction=5
-XX:+UseCMSCompactAtFullCollection

# GC日志
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCApplicationStoppedTime
-XX:+PrintHeapAtGC
-Xloggc:/app/logs/gc.log
-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=10
-XX:GCLogFileSize=100M

# OOM时自动dump堆快照，排查内存问题必备
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/app/logs/heapdump.hprof

```

关键参数说明：

| 参数                                                         | 说明                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| `-Xmn1600m`                                                  | 新生代占堆的40%左右，响应时间优先场景可以适当调大新生代，减少对象晋升到老年代的频率，从而降低CMS老年代GC(停顿相对更长)的触发频率 |
| `CMSInitiatingOccupancyFraction=70`                          | 老年代使用率达到70%就提前触发CMS并发回收，留足够buffer防止并发失败退化成Serial GC(那个停顿时间会非常长) |
| `CMSScavengeBeforeRemark`                                    | Remark阶段前先做一次YoungGC，减少Remark阶段需要扫描的跨代引用，缩短这个阶段的STW时间 |
| `UseCMSCompactAtFullCollection` + `CMSFullGCsBeforeCompaction=5` | CMS本身不整理内存碎片，长期运行容易导致明明有空闲空间却分配失败提前触发GC，这两个参数控制"每5次FullGC强制整理一次" |

**4G内存这个体量用CMS的注意事项：** CMS本身更适合中大堆(8G+)，4G这个规格其实**响应时间优先场景下G1可能表现更好**(如果 JDK8 版本支持G1，JDK8u40+都支持)，如果你能选，同样是JDK8环境下可以考虑直接上G1，配置参考下面JDK11的G1部分，参数基本通用。

#### jdk11+ G1

```properties
-server
-Xms4g -Xmx4g
-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=256m

# G1核心参数
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=4m

# G1的堆区域占比控制，响应时间优先场景适当放宽Young区上限
-XX:G1NewSizePercent=20
-XX:G1MaxNewSizePercent=40

# 并发标记周期相关：提前启动并发标记，避免来不及回收触发Full GC
-XX:InitiatingHeapOccupancyPercent=45
-XX:G1MixedGCCountTarget=8
-XX:G1MixedGCLiveThresholdPercent=85

# 减少字符串重复对象占用的堆空间(JDK8u20+/JDK11都支持)
-XX:+UseStringDeduplication

# GC日志(JDK11统一日志框架，格式和JDK8不同)
-Xlog:gc*,gc+heap=debug,gc+age=trace:file=/app/logs/gc.log:time,uptime,level,tags:filecount=10,filesize=100M

# OOM时自动dump堆快照
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/app/logs/heapdump.hprof

```

**关键参数说明：**

| 参数                                | 说明                                                         |
| ----------------------------------- | ------------------------------------------------------------ |
| `MaxGCPauseMillis=200`              | 这是G1的核心目标参数，**响应时间优先的关键就是把这个值调低**。G1会根据这个目标动态调整每次回收的Region数量，尽量让每次停顿控制在200ms以内。如果你的业务对延迟要求更苛刻，可以尝试调到100甚至50，但调太低G1会更频繁地做小批量回收，可能导致吞吐量下降、年轻代GC更频繁，需要结合实际压测调整 |
| `InitiatingHeapOccupancyPercent=45` | 老年代占用达到45%就启动并发标记周期，比默认值(45%)略保守一点，提前介入避免来不及回收就触发代价高昂的Full GC(G1的FullGC是单线程Serial模式，停顿时间会非常长，是G1场景下最要极力避免的情况) |
| `G1MixedGCCountTarget=8`            | 混合回收阶段(回收老年代)分摊到8次GC里完成，而不是一次性回收完，进一步平摊停顿时间 |
| `UseStringDeduplication`            | 字符串去重，堆里有大量重复字符串内容的应用(比如日志密集、JSON处理多的应用)能有效降低内存占用，间接减少GC频率 |

------

#### 两个版本通用的调优建议

**1. 4G这个内存规格，新生代/整体比例不要生搬硬套**
 上面给的比例是通用起点，具体项目的对象生命周期分布差异很大（比如短命对象多的Web应用 vs 长期持有缓存的应用），**强烈建议先用默认配置压测跑一段时间，看GC日志里的实际晋升速率、Full GC频率，再针对性微调**，不要一开始就死抠参数。

**2. 一定要打开GC日志，没有日志的调优是盲调**
 不管选哪个GC，日志开销通常在1%以内可以忽略不计，但排查线上性能问题时是唯一的第一手证据，务必保留。

**3. G1的 `MaxGCPauseMillis` 是"目标"不是"保证"**
 如果堆里活跃对象暴增/内存分配速率突然飙升，G1依然可能打破这个目标值，出现比预期长的停顿，这个参数只是引导JVM的调优方向，不是硬性上限。

### 容器化

容器化环境和物理机/虚拟机相比，有几个额外要注意的点：

- **JVM要能感知cgroup限制而不是宿主机资源**
- **堆大小不能设置成跟容器limit一样大**（要给堆外内存、元空间、线程栈留出buffer，否则会被OOMKilled）
- **GC线程数不能读到宿主机核数**。

按JDK8和JDK11+分别整理 4G 容器规格，响应时间优先。

**通用原则：容器内存4G，堆内存不能设成4G**

这是最容易踩的坑——如果 `-Xmx` 直接设成容器limit的4G，JVM堆外还要占用**元空间、线程栈、直接内存、JIT编译缓存、GC自身数据结构**等开销，实际总内存占用会超过4G，触发 K8s 的 `OOMKilled`（这个是操作系统层面强杀，不会走 Java 的 OOM 异常处理逻辑，`HeapDumpOnOutOfMemoryError` 完全不会生效，排查起来更痛苦）。

**推荐比例**：堆内存设置为容器limit的 **65%~75%**，留出25%~35%给堆外开销。

#### jdk1.8 CMS

JDK8 容器感知参数的三个阶段

| JDK8版本区间                                                 | 支持的参数                                                   | 状态                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 8u131 ~ 8u190                                                | `-XX:+UseCGroupMemoryLimitForHeap` + `-XX:MaxRAMFraction`    | 已废弃，**不推荐用**，而且 `MaxRAMFraction` 是**分数**不是百分比（比如设成2表示堆=容器内存/2），精度很粗糙 |
| 8u191 及以上 [Merikan Blog](https://www.merikan.com/2019/04/jvm-in-a-container/) | `-XX:MaxRAMPercentage` / `-XX:MinRAMPercentage` / `-XX:InitialRAMPercentage` | **推荐使用**，和JDK11+是同一套参数，语义完全一致             |
| 8u131之前                                                    | 完全不支持容器感知                                           | 只能手动写死`-Xmx`                                           |

从 JDK 8u191 开始，官方明确建议直接用 `UseContainerSupport`（该特性默认已开启）配合百分比参数，不要再用 `UseCGroupMemoryLimitForHeap` 这个已废弃的实验特性。

```properties
-server

# 8u191+ 默认已开启容器感知，UseCGroupMemoryLimitForHeap不再需要
-XX:InitialRAMPercentage=70.0
-XX:MaxRAMPercentage=70.0
-XX:MinRAMPercentage=70.0

# 堆内存：4G容器，留出buffer，堆设置为2.8G左右(约70%)
# -Xms2800m -Xmx2800m
# -Xmn1100m

-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=256m

# 直接内存限制(Netty等框架会用，不限制的话可能超出容器限额)
-XX:MaxDirectMemorySize=512m

# GC线程数：必须手动指定，否则JDK8老版本会读取宿主机CPU核数
# 而不是容器分配的核数(比如容器limit是2核，JVM却按宿主机32核开线程)
-XX:ParallelGCThreads=2
-XX:ConcGCThreads=2

# CMS核心参数
-XX:+UseConcMarkSweepGC
-XX:+UseParNewGC
-XX:CMSInitiatingOccupancyFraction=70
-XX:+UseCMSInitiatingOccupancyOnly
-XX:+CMSParallelRemarkEnabled
-XX:+CMSScavengeBeforeRemark
-XX:+ExplicitGCInvokesConcurrent
-XX:+CMSClassUnloadingEnabled
-XX:+UseCMSCompactAtFullCollection
-XX:CMSFullGCsBeforeCompaction=5

-XX:SurvivorRatio=8
-XX:MaxTenuringThreshold=6

# GC日志：容器场景务必挂载到持久化Volume，容器重启日志不会丢
-XX:+PrintGCDetails
-XX:+PrintGCDateStamps
-XX:+PrintGCApplicationStoppedTime
-Xloggc:/app/logs/gc.log
-XX:+UseGCLogFileRotation
-XX:NumberOfGCLogFiles=5
-XX:GCLogFileSize=50M

# OOM时dump堆快照(同样要挂载持久化目录，否则容器重启后dump文件也没了)
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/data/logs/heapdump.hprof

# 容器场景常见需求：容器杀掉时能快速响应，缩短应用不健康的窗口期
-XX:+ExitOnOutOfMemoryError

```

**`-XX:+ExitOnOutOfMemoryError` 这个参数是容器场景特有的推荐项**：物理机部署时，OOM后让JVM"半死不活"地继续跑，人工能及时发现处理；但容器场景下，OOM后应该让进程**直接退出**，交给K8s按照健康检查/重启策略自动拉起新Pod，比让一个OOM后状态异常的进程继续占着流量入口更安全。

验证

```bash
docker run -m 4g your-image java -XX:+PrintFlagsFinal -version | grep -i maxheapsize
```

或者容器跑起来后：

```bash
jcmd <pid> VM.flags | grep MaxHeapSize
```



#### JDK 11+ - G1 容器化配置

```properties
-server

# JDK10+默认已开启容器感知，这里显式声明表达意图，兼容性更好
-XX:+UseContainerSupport

# 堆内存：用百分比而不是绝对值，是容器化场景更推荐的写法
# 好处：同一份启动参数，不同容器limit(比如从4G改成8G)不用改这行配置，自动适配
-XX:InitialRAMPercentage=70.0
-XX:MaxRAMPercentage=70.0
-XX:MinRAMPercentage=70.0

-XX:MetaspaceSize=256m
-XX:MaxMetaspaceSize=256m
-XX:MaxDirectMemorySize=512m

# GC线程数：JDK11+能自动根据容器CPU limit算出合理线程数，一般不需要手动指定
# 但如果容器CPU limit设置的是小数(比如500m/1.5核)，容器感知可能不够精确
# 遇到GC线程数异常，可以手动兜底指定
# -XX:ParallelGCThreads=2
# -XX:ConcGCThreads=2

# G1核心参数
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200
-XX:G1HeapRegionSize=4m
-XX:G1NewSizePercent=20
-XX:G1MaxNewSizePercent=40
-XX:InitiatingHeapOccupancyPercent=45
-XX:G1MixedGCCountTarget=8
-XX:G1MixedGCLiveThresholdPercent=85
-XX:+UseStringDeduplication

# GC日志(JDK11统一日志框架)
-Xlog:gc*,gc+heap=debug,gc+age=trace:file=/app/logs/gc.log:time,uptime,level,tags:filecount=10,filesize=50M

-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/app/logs/heapdump.hprof
-XX:+ExitOnOutOfMemoryError
```

**`MaxRAMPercentage` 相比 JDK8 的 `Xmx` 硬编码写法，是容器场景的最佳实践**：JDK11+ 能读取cgroup的内存限制，按百分比动态计算堆大小，好处是这份JVM参数可以**在不同规格的容器间直接复用**（比如K8s里通过HPA/VPA动态调整Pod的内存limit，JVM参数不用跟着改，重启后自动按新的limit重新计算堆大小）。

#### 配套 K8s Deployment 资源配置（容器limit要和JVM参数对齐）

```yaml
resources:
  requests:
    cpu: "1"
    memory: "4Gi"
  limits:
    cpu: "2"
    memory: "4Gi"     # 必须和上面JVM参数的"4G容器"假设一致，改这里要同步改JVM参数
```

**几个容易被忽视但很关键的对齐点：**

1. **`requests.memory` 和 `limits.memory` 建议设成相同值**（Guaranteed QoS等级），避免K8s在节点资源紧张时优先驱逐这个Pod，Java应用启动慢、驱逐后重建代价高，稳定性优先的场景不建议用Burstable等级。
2. **CPU limit 如果设置的不是整数核（比如 `1.5`）**，JDK8和部分JDK11版本的容器感知在计算GC线程数时可能出现"向上取整"或"向下取整"不一致的情况，导致实际GC线程数和预期有偏差，这种场景下手动指定 `ParallelGCThreads`/`ConcGCThreads` 会更可控。
3. **GC日志目录、heapdump目录记得配合K8s的 `volumeMounts` 挂载持久化存储或者至少是 `emptyDir`**，纯容器内文件系统的话，Pod重启/被驱逐后这些排查用的日志/dump文件会直接丢失，出问题时错过第一手证据。
