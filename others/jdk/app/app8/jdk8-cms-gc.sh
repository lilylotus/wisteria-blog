#!/bin/bash
SCRIPT_DIR=$(cd $(dirname $0); pwd)
echo "execution dir [${SCRIPT_DIR}}]" | tee -a startup.log
cd ${SCRIPT_DIR}

ncpu=$(nproc)
ConcGCThreads=$(expr $ncpu / 4)
ConcGCThreads=$(( $ConcGCThreads > 1 ? $ConcGCThreads : 1 ))
echo "cpu [${ncpu}] nthread [${ConcGCThreads}]"

MEM_OPTS=${MEM_OPTS:-"-Xms4g -Xmx4g -Xmn3g -Xss512k -XX:MaxMetaspaceSize=256m -XX:MaxDirectMemorySize=512m"}
GC_OPTS=${GC_OPTS:-"-XX:+UseConcMarkSweepGC -XX:+UseParNewGC"}
JVM_OPTS=${JVM_OPTS:-"-XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+UseCMSCompactAtFullCollection -XX:CMSFullGCsBeforeCompaction=0 -XX:+CMSScavengeBeforeRemark -XX:ParallelGCThreads=$(nproc) -XX:ConcGCThreads=${ConcGCThreads}"}
OTHER_OPTS=${OTHER_OPTS:-""}
INF_OPTS=${INF_OPTS:-"-XX:+PrintTenuringDistribution -XX:+PrintHeapAtGC -XX:+PrintReferenceGC"}

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
-XX:+HeapDumpOnOutOfMemoryError -XX:+CrashOnOutOfMemoryError -XX:HeapDumpPath=${SCRIPT_DIR}/logs/heap/heapdump_%p_%t.hprof \
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:${SCRIPT_DIR}/logs/gc/gc-%t.log \
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=10 -XX:GCLogFileSize=50m \
-jar ${SCRIPT_DIR}/app8.jar"

echo "exec [${EXEC_CMD}]" | tee -a startup.log
mkdir -p ${SCRIPT_DIR}/logs/{heap,gc}
nohup ${EXEC_CMD} > startexec.log 2>&1 &
