
## 容器内存限制

### 核心配置

```bash
# Kubernetes Pod 内存限制 4GB
JAVA_OPTS="
  -XX:+UseContainerSupport
  -XX:MaxRAMPercentage=75.0
  -Xmx3g -Xms3g
  -XX:MaxMetaspaceSize=256m
  -Xss512k
  -XX:MaxDirectMemorySize=512m
  -XX:+HeapDumpOnOutOfMemoryError
  -XX:HeapDumpPath=/tmp/heapdump.hprof
  -XX:+ExitOnOutOfMemoryError
"
```

内存分配策略：

```bash
容器总内存：4GB
├─ JVM 堆：3GB (75%)
├─ 元空间：256MB (6%)
├─ 线程栈：512MB (1000线程 × 512KB)
├─ Direct Memory：512MB (13%)
└─ Native/其他：剩余 ~200MB
```

- 容器 OOMKilled 从每天 5 次降到 0，通过精确内存分配避免超限。
- JVM 正确感知容器限制，堆大小自动适配，无需手动计算。
- Direct Memory 泄漏问题通过限制和监控及时发现，泄漏率从 10% 降到 0
- 容器内存使用率稳定在 85%，预留 15% 缓冲，避免突发内存需求导致被杀

### Native Memory 泄漏导致容器 OOM —— 从“堆外内存失控”到“全内存监控”

在容器化环境中，JVM 堆内存之外的 Native Memory 泄漏是导致容器 OOMKilled 的常见原因。传统上，我们关注堆内存使用，但忽视了 Direct Memory、线程栈等 Native 内存的增长。

高并发网关系统使用 Netty 处理百万级连接。堆内存稳定，但容器频繁 OOMKilled。排查发现 Native Memory（堆外内存）持续增长，最终耗尽容器内存。

问题：

- Native Memory 泄漏：Netty 的 DirectByteBuffer 未释放，Native Memory 从 1GB 增长到 4GB。
- 无监控手段：JVM 堆内存有监控，但 Native Memory 无监控，泄漏无法及时发现。
- 容器内存限制：容器限制 8GB，Native Memory 泄漏导致总内存超限，被 K8s 杀死。
- 排查困难： 只能看堆内存，Native Memory 需要使用 NMT（Native Memory Tracking）才能查看。jmap -heap

排查流程：

1. 启用 NMT：-XX:NativeMemoryTracking=detail
2. 基线记录：jcmd <pid> VM.native_memory baseline
3. 运行一段时间后对比：jcmd <pid> VM.native_memory summary.diff
4. 定位增长模块：查看哪个模块（Thread/Code/GC/Other）内存增长
5. 代码修复：修复泄漏点（如 DirectByteBuffer 未释放）

### Safepoint 导致长时间 STW

问题：

- Safepoint 阻塞：JVM 需要所有线程进入 Safepoint 才能执行 GC、偏向锁撤销等作。部分线程（如 JNI 调用、循环优化）长时间无法进入 Safepoint，导致其他线程等待。
- 偏向锁撤销：高并发场景下，偏向锁频繁撤销，需要进入 Safepoint，导致延迟。
- 循环优化：JIT 编译的循环被优化为可数循环，无法进入 Safepoint，长时间运行阻塞 GC。
- 无监控手段：Safepoint 相关指标无监控，问题定位困难。

```bash
JAVA_OPTS="
  -XX:-UseBiasedLocking
  -XX:+UseCountedLoopSafepoints
  -Xlog:safepoint*:file=/var/log/app/safepoint.log:time,level,tags
"
```

### 混合 GC

业务背景：推荐系统使用 G1 GC，堆大小 32GB。运行一段时间后，混合 GC（Mixed GC）频繁失败，退化为 Full GC，每小时触发一次，停顿 3~5 秒。

遇到的问题：

混合 GC 失败：G1 的混合 GC 无法回收足够的空间，退化为 Full GC。
并发标记失败：并发标记阶段耗时过长，超过  限制，标记失败。-XX:G1ConcMarkStepDurationMillis
晋升失败：对象晋升到老年代时，老年代空间不足，触发 Full GC。
碎片化严重：老年代碎片化，无法分配大对象，触发 Full GC。
解决方案：

调整混合 GC 参数：（增加混合 GC 次数），（降低浪费阈值）。-XX:G1MixedGCCountTarget=8-XX:G1HeapWastePercent=10
优化并发标记：（增加并发标记线程），（减少单步时长，增加标记频率）。-XX:ConcGCThreads=4-XX:G1ConcMarkStepDurationMillis=10
提前触发混合 GC：（降低存活对象阈值，提前触发）。-XX:G1MixedGCLiveThresholdPercent=85
监控混合 GC 成功率：通过 GC 日志分析混合 GC 和 Full GC 比例，调整参数。
核心配置示例：

```bash
JAVA_OPTS="
  -Xms32g -Xmx32g
  -XX:+UseG1GC
  -XX:MaxGCPauseMillis=200
  -XX:InitiatingHeapOccupancyPercent=45
  -XX:G1MixedGCCountTarget=8
  -XX:G1HeapWastePercent=10
  -XX:G1MixedGCLiveThresholdPercent=85
  -XX:ConcGCThreads=4
  -XX:G1ConcMarkStepDurationMillis=10
  -Xlog:gc*:file=/var/log/app/gc.log:time,level,tags
"
```

### jdk jmc

```properties
-Dcom.sun.management.jmxremote.port=${process_port} # JMX主端口
-Dcom.sun.management.jmxremote.rmi.port=${process_rmi_port}  # 固定RMI随机端口，如果有防火墙控制的话，随机到防火墙控制的端口就连接不上了
-Dcom.sun.management.jmxremote.authenticate=false  # 禁用认证（测试用）
-Dcom.sun.management.jmxremote.ssl=false           # 禁用 SSL（测试用）
-Dcom.sun.management.jmxremote.local.only=false    # 允许远程连接
-Djava.rmi.server.hostname=<服务器公网IP或内网IP>  # 关键！避免 RMI 回环问题

-Dcom.sun.management.jmxremote.port=7091
-Dcom.sun.management.jmxremote.rmi.port=17091
-Dcom.sun.management.jmxremote.authenticate=false
-Dcom.sun.management.jmxremote.ssl=false
-Dcom.sun.management.jmxremote.local.only=false
-Djava.rmi.server.hostname=10.4.100.122
```

