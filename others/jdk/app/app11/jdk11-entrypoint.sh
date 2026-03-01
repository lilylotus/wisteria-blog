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

MEM_OPTS=${MEM_OPTS:-"-XX:+UseContainerSupport -XX:InitialRAMPercentage=75.0 -XX:MaxRAMPercentage=75.0 -Xss512k -XX:MaxMetaspaceSize=256m -XX:MaxDirectMemorySize=512m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseG1GC"}
# 默认低延迟配置，小堆(<4G)：1-2m / 中堆(4-32G)：4m / 大堆(>32G)：8m
JVM_OPTS=${JVM_OPTS:-"-XX:G1HeapRegionSize=2m -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 -XX:G1ReservePercent=10 -Dfile.encoding=UTF-8 -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
# -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}
OTHER_OPTS=${OTHER_OPTS:-""}

# (IHOP) 是 G1 垃圾回收器中控制并发标记周期启动时机的关键参数。
# // 简化的触发逻辑 if (当前老年代使用率 ≥ 堆总大小 × IHOP%) { // 启动并发标记周期 startConcurrentMarkingCycle(); }
# 30-40% 降低阈值，提前标记，减少Full GC 发生概率，但可能增加标记开销
# 延迟敏感   40-50% 减少不必要的并发标记开销
# 吞吐量优先 25-35% 积极回收，避免停顿时间过长
# 默认/通用场景 45% G1默认值，平衡各种因素
# -XX:InitiatingHeapOccupancyPercent=45 # 启动并发标记的堆占用率阈值（默认45%），老年代占用率达到此百分比时启动并发标记

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
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError \
-XX:HeapDumpPath=${SCRIPT_DIR}/logs/heap/heapdump_%p_%t.hprof \
-Xlog:gc*=info:file=${SCRIPT_DIR}/logs/gc/gc-%t.log:time,uptime,level,tid,tags:filecount=10,filesize=50M \
-jar ${SCRIPT_DIR}/app.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/{gc,heap}
exec ${EXEC_CMD}
