#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

ncpu=$(nproc)
ConcGCThreads=$(expr $ncpu / 4)
ConcGCThreads=$(( $ConcGCThreads > 1 ? $ConcGCThreads : 1 ))
echo "cpu [${ncpu}] nthread [${ConcGCThreads}]"

# https://blog.gceasy.io/java-cms-gc-tuning/

# 字节转换函数
bytes_to_human() {
    local bytes=$1
    local units=('B' 'KB' 'm' 'g' 'TB')
    local unit=0
    
    while [ $bytes -ge 1024 ] && [ $unit -lt 4 ]; do
        bytes=$((bytes / 1024))
        unit=$((unit + 1))
    done
    
    echo "${bytes}${units[$unit]}"
}

# 获取容器内存限制
get_memory_limit() {
    local cgroup_file="/sys/fs/cgroup/memory/memory.limit_in_bytes"
    local max_limit="9223372036854771712"  # 0x7FFFFFFFFFFFF000 无限制的标识
    
    if [ -f "$cgroup_file" ]; then
        local limit=$(cat "$cgroup_file")
        
        # 如果 limit 是最大值，表示没有限制或限制在系统级别
        if [ "$limit" -ge "$max_limit" ]; then
            # 尝试从/proc/meminfo获取（如果有lxcfs）
            if [ -f "/proc/meminfo" ]; then
                local mem_kb=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
                echo $((mem_kb * 1024))
            else
                # 默认 2 GB
                echo $((2048 * 1024 * 1024))
            fi
        else
            echo "$limit"
        fi
    else
        # 尝试从/proc/meminfo获取（如果有lxcfs）
        if [ -f "/proc/meminfo" ]; then
            local mem_kb=$(grep 'MemTotal:' /proc/meminfo | awk '{print $2}')
            echo $((mem_kb * 1024))
        else
            echo $((2048 * 1024 * 1024))
        fi
    fi
}

# 计算可用内存的80%（考虑容器开销）
calculate_percent_memory() {
    local total_bytes=$1
    local percent=${2:-80}  # 默认80%

    local result=$((total_bytes * percent / 100))
    # 调整为偶数（某些JVM优化）
    result=$(( (result + 1) & ~1 ))

    echo $result
}

TOTAL_MEM=$(bytes_to_human $(get_total_memory_bytes))
TOTAL_MEM_LIMIT=$(bytes_to_human $(get_memory_limit))
CALC_PERCENT_MEM=$(bytes_to_human $(calculate_percent_memory $(get_memory_limit) 50))
echo "Total System Memory: $TOTAL_MEM" | tee -a startup.log
echo "Container Memory Limit: $TOTAL_MEM_LIMIT" | tee -a startup.log
echo "Calculated Percent Memory: $CALC_PERCENT_MEM" | tee -a startup.log

MEM_OPTS=${MEM_OPTS:-"-XX:+UseContainerSupport -XX:InitialRAMPercentage=75.0 -XX:MaxRAMPercentage=75.0 -Xmn${CALC_PERCENT_MEM} -XX:MaxMetaspaceSize=256m -XX:MaxDirectMemorySize=512m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseConcMarkSweepGC -XX:+UseParNewGC"}
# -XX:NewRatio=3 新生代:老年代 = 1:3 即老年代占整个堆空间的 3 / (1 + 3)
JVM_OPTS=${JVM_OPTS:-"-XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:+CMSScavengeBeforeRemark -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
OTHER_OPTS=${OTHER_OPTS:-""}
INF_OPTS=${INF_OPTS:-"-XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+PrintReferenceGC"}

# -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly # 限制只在老年代达到 75% 才回收
# -XX:+CMSScavengeBeforeRemark # 在重新标记前执行 Young GC （Minor GC），在过程中提前触发一次 Young GC，防止后续晋升过多对象。
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
${INF_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError \
-XX:HeapDumpPath=${SCRIPT_DIR}/logs/heap/heapdump_%p_%t.hprof \
-XX:+PrintGCDetails -XX:+PrintGCDateStamps \
-Xloggc:${SCRIPT_DIR}/logs/gc/gc-%t.log -XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=50m \
-jar ${SCRIPT_DIR}/app.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/{gc,heap}
exec ${EXEC_CMD}
