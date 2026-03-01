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

MEM_OPTS=${MEM_OPTS:-"-Xms4g -Xmx4g -Xss512k -XX:MaxMetaspaceSize=256m -XX:MaxDirectMemorySize=512m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseG1GC"}
JVM_OPTS=${JVM_OPTS:-"-XX:G1HeapRegionSize=4m -XX:MaxGCPauseMillis=200 -XX:InitiatingHeapOccupancyPercent=45 -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
OTHER_OPTS=${OTHER_OPTS:-""}

echo "JVM MEM_OPTS [${MEM_OPTS}]" | tee -a startup.log
echo "JVM GC_OPTS [${GC_OPTS}]" | tee -a startup.log
echo "JVM JVM_OPTS [${JVM_OPTS}]" | tee -a startup.log
echo "JVM OTHER_OPTS [${OTHER_OPTS}]" | tee -a startup.log

EXEC_CMD="/usr/local/src/jdk-11.0.25/bin/java \
${MEM_OPTS} \
${GC_OPTS} \
${JVM_OPTS} \
${OTHER_OPTS} \
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError \
-XX:HeapDumpPath=${SCRIPT_DIR}/logs/heap/heapdump_%p_%t.hprof \
-Xlog:gc*=info:file=${SCRIPT_DIR}/logs/gc/gc-%t.log:time,uptime,level,tid,tags:filecount=10,filesize=50M \
-jar ${SCRIPT_DIR}/app.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/{heap,gc}
nohup ${EXEC_CMD} > startexec.log 2>&1 &
