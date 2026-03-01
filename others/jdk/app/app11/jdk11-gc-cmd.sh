# 查看内存占用情况

# jcmd (推荐)

# 列出所有Java进程
jcmd -l

# 查看特定进程的内存使用（替换<pid>）
jcmd <pid> VM.native_memory
jcmd <pid> GC.heap_info
jcmd <pid> VM.info

# 显示堆内存摘要
jmap -heap <pid>
jhsdb jmap --heap --pid <pid>

# 生成堆内存直方图
jmap -histo <pid>

# 生成堆转储文件（谨慎使用，生产环境可能影响性能）
jmap -dump:format=b,file=heap.hprof <pid>


# 启动记录
jcmd <pid> JFR.start duration=60s filename=recording.jfr

# 生产环境推荐持续记录
java -XX:StartFlightRecording=dumponexit=true,filename=recording.jfr ...

# 1. jhsdb 使用
jhsdb jinfo --pid <PID>
jhsdb jstack --pid <PID>
jhsdb jmap --heap --pid <PID>

# 1.1 线程分析
# 生成线程转储
jhsdb jstack --pid <PID> > thread_dump.txt

# 带锁信息
jhsdb jstack --locks --pid <PID>

# 1.2 内存分析
# 堆内存直方图
jhsdb jmap --histo --pid <PID>

# 详细堆信息
jhsdb jmap --heap --pid <PID>

# 生成堆转储
jhsdb jmap --binaryheap --pid <PID> --file heap.bin

# 1.3 JVM信息查看
# 查看所有系统属性
jhsdb jinfo --sysprops --pid <PID>

# 查看所有JVM标志
jhsdb jinfo --flags --pid <PID>