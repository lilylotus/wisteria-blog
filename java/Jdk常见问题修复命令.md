# JDK 常见问题排查与修复命令手册

适用场景：Spring Boot / Java 服务出现接口无响应、CPU 飙高、内存溢出、频繁 Full GC 等问题。
按 JDK 8 与 JDK 11+ 分别整理 jstack、内存 dump 的命令差异，并给出通用排查流程。

---

## 一、通用前置准备

```bash
# 1. 找到 Java 进程 pid
jps -lv
ps -ef | grep java | grep -v grep

# 2. 确认 JDK 版本（决定后面用哪套命令）
java -version
# 容器内：docker exec <容器> java -version

# 3. 保证执行用户与目标进程一致（否则 attach 失败）
ps -o user= -p <pid>
sudo -u <该用户> jstack <pid>
```

**注意事项**
- jstack / jmap / jcmd 走的是 attach 机制，必须与目标进程**同一用户**，且 `/tmp` 可写。
- 容器里通常只有 JRE，没有 jstack。可用 `docker exec` 进入带 JDK 的镜像，或使用 [jattach](https://github.com/jattach/jattach)、Arthas。
- 容器内 Java 进程 pid 常常是 1 或很小的数字（如本次的 19）。宿主机上看到的 pid 不同，命令要在**容器内**执行，或用 `nsenter`。
- dump 文件输出路径是**目标 JVM 进程所在的文件系统**，磁盘要留够空间（堆 dump ≈ 堆已用大小）。

---

## 二、线程栈（jstack）

### 2.1 JDK 8

```bash
# 基本用法（含锁信息，推荐加 -l）
jstack -l <pid> > /tmp/jstack_$(date +%Y%m%d_%H%M%S).txt

# 连续采样 3 次，间隔 5 秒（判断线程是否持续卡在同一位置）
for i in 1 2 3; do jstack -l <pid> > /tmp/jstack_$i.txt; sleep 5; done

# 进程无响应，jstack 挂住时，强制模式（会暂停进程，慎用）
jstack -F <pid> > /tmp/jstack_force.txt

# 替代方案：向进程发信号，线程栈输出到进程的 stdout（不需要 attach）
kill -3 <pid>

# 用 jcmd（JDK 7+ 也可用）
jcmd <pid> Thread.print -l > /tmp/jstack.txt
```

### 2.2 JDK 11+

```bash
# jstack 用法基本一致
jstack -l <pid> > /tmp/jstack_$(date +%Y%m%d_%H%M%S).txt

# 推荐用 jcmd（官方更推荐，功能更全）
jcmd <pid> Thread.print -l > /tmp/jstack.txt

# JDK 17+ 可输出 JSON 格式线程 dump（含虚拟线程信息，JDK 21+）
jcmd <pid> Thread.dump_to_file -format=json /tmp/threads.json

# 进程无响应时使用 jhsdb（JDK 9+ 取代了 jstack -F）
jhsdb jstack --pid <pid>
jhsdb jstack --mixed --pid <pid>       # 含 native 帧
```

### 2.3 差异速查

| 项目 | JDK 8 | JDK 11+ |
|---|---|---|
| 常规线程栈 | `jstack -l` / `jcmd Thread.print` | 相同 |
| 强制 dump | `jstack -F` | `jhsdb jstack --pid`（`-F` 已移除或不推荐） |
| 死锁检测 | jstack 输出末尾自带 `Found one Java-level deadlock` | 相同 |
| 无需 attach 的方式 | `kill -3 <pid>`（输出到 stdout） | 相同 |
| JSON 格式 | 不支持 | JDK 21+ 支持 `Thread.dump_to_file` |

> 提醒：`kill -3` 的输出会写到进程 stdout。如果 stdout 已经被堵住（见本手册第七节的案例），这个输出会丢或卡住，要优先用 jstack / jcmd。

---

## 三、内存 dump 与堆分析

### 3.1 JDK 8

```bash
# 导出堆 dump（live 只导存活对象，会触发一次 Full GC）
jmap -dump:live,format=b,file=/tmp/heap_$(date +%Y%m%d_%H%M%S).hprof <pid>

# 不触发 Full GC，导出全部对象（进程已经很卡时用）
jmap -dump:format=b,file=/tmp/heap.hprof <pid>

# 对象直方图（快速定位哪类对象占内存，不需要落盘大文件）
jmap -histo:live <pid> | head -30
jmap -histo <pid> | head -30           # 不触发 Full GC

# 堆配置与使用概况
jmap -heap <pid>

# 类加载器统计（怀疑元空间/类泄漏）
jmap -clstats <pid>

# 进程无响应时的强制模式
jmap -F -dump:format=b,file=/tmp/heap.hprof <pid>
```

### 3.2 JDK 11+

```bash
# 推荐用 jcmd（jmap -dump 仍可用，但官方推荐 jcmd）
jcmd <pid> GC.heap_dump /tmp/heap.hprof                # 默认只导存活对象，会触发 Full GC
jcmd <pid> GC.heap_dump -all /tmp/heap.hprof           # 导出全部对象，不触发 Full GC

# 对象直方图
jcmd <pid> GC.class_histogram | head -30
jmap -histo:live <pid> | head -30

# 堆概况（JDK 9+ 已移除 jmap -heap，改用 jhsdb 或 jcmd）
jcmd <pid> GC.heap_info
jhsdb jmap --heap --pid <pid>

# 元空间 / 类加载器
jcmd <pid> VM.classloader_stats
jcmd <pid> VM.metaspace

# 进程无响应时用 jhsdb（会暂停进程）
jhsdb jmap --binaryheap --pid <pid>
```

### 3.3 差异速查

| 项目 | JDK 8 | JDK 11+ |
|---|---|---|
| 堆 dump | `jmap -dump:live,format=b,file=` | `jcmd <pid> GC.heap_dump [-all] <文件>` |
| 堆概况 | `jmap -heap` | `jcmd GC.heap_info` 或 `jhsdb jmap --heap` |
| 强制 dump | `jmap -F` | `jhsdb jmap --binaryheap` |
| 直方图 | `jmap -histo` | `jcmd GC.class_histogram` |
| dump 文件路径 | jmap 由**执行命令的进程**创建文件 | jcmd 由**目标 JVM**创建文件，路径在目标进程所在环境 |

### 3.4 自动导出堆 dump（强烈建议加到启动参数）

```bash
# JDK 8 / 11+ 通用
-XX:+HeapDumpOnOutOfMemoryError
-XX:HeapDumpPath=/data/dump/          # 目录要提前创建，且有足够空间；容器需挂载卷
-XX:+ExitOnOutOfMemoryError           # 可选：OOM 后直接退出，交给容器/进程管理器重启，避免半死状态
```

### 3.5 分析工具

- **Eclipse MAT**：看 Leak Suspects、Dominator Tree、支配集大小。大 dump 需调大 `MemoryAnalyzer.ini` 里的 `-Xmx`。
- **VisualVM / JProfiler / IDEA Profiler**：小堆快速看。
- 传输大文件先压缩：`gzip heap.hprof` 或 `tar czf`。

---

## 四、CPU 飙高排查

```bash
# 1. 找出 CPU 最高的线程
top -H -p <pid>
# 记下最高的线程 id（十进制），例如 27440

# 2. 转成十六进制
printf "%x\n" 27440       # 输出 6b30

# 3. 在 jstack 里找该线程（nid=0x6b30）
jstack -l <pid> | grep -A 30 "nid=0x6b30"
```

- 若最高的线程是 `GC task thread` / `Gang worker`：说明在频繁 GC，转到第五节。
- 若是业务线程：看栈定位死循环、正则回溯、大量计算等。
- 若是 `C2 CompilerThread`：多为 JIT 编译热点，通常是瞬时现象。

---

## 五、GC 与内存问题排查

### 5.1 实时查看 GC 情况

```bash
# JDK 8 / 11+ 通用：每 1 秒输出一次，共 10 次
jstat -gcutil <pid> 1000 10
jstat -gc <pid> 1000 10
```

关键指标：`FGC`（Full GC 次数）持续增长且 `O`（老年代使用率）居高不下，说明堆不够或有内存泄漏。

### 5.2 GC 日志参数

```bash
# JDK 8
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -XX:+PrintGCTimeStamps
-Xloggc:/data/logs/gc.log
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=50M

# JDK 11+（统一日志框架，JDK 8 的参数在 11+ 中已移除或废弃）
-Xlog:gc*:file=/data/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=50m
```

### 5.3 常见 OOM 类型与处理

| 异常信息 | 含义 | 处理 |
|---|---|---|
| `java.lang.OutOfMemoryError: Java heap space` | 堆溢出 | 导出 heap dump，用 MAT 找大对象；临时调大 `-Xmx` |
| `GC overhead limit exceeded` | 几乎全部时间在 GC | 同上 |
| `Metaspace`（JDK 8+）/ `PermGen space`（JDK 7 及以前） | 类加载过多 | 检查动态代理、热部署、类加载器泄漏；调大 `-XX:MaxMetaspaceSize` |
| `unable to create new native thread` | 线程数达到系统上限 | 查 `ulimit -u`、`/proc/<pid>/status` 的 Threads、线程池是否泄漏 |
| `Direct buffer memory` | 堆外内存溢出（Netty 常见） | 调大 `-XX:MaxDirectMemorySize`，排查未释放的 ByteBuf |
| `Requested array size exceeds VM limit` | 申请了超大数组 | 检查业务代码 |

### 5.4 堆外内存排查（NMT）

```bash
# 启动参数（有约 5%~10% 性能损耗，仅排查时开启）
-XX:NativeMemoryTracking=summary

# 运行时查看
jcmd <pid> VM.native_memory summary
jcmd <pid> VM.native_memory baseline
jcmd <pid> VM.native_memory summary.diff       # 与 baseline 对比增长
```

---

## 六、容器环境（Docker / K8s）注意事项

```bash
# JDK 8：8u191 之前不识别容器内存限制，必须手动指定 -Xmx
# 8u191+ 及 JDK 11+ 默认开启容器感知
-XX:+UseContainerSupport
-XX:MaxRAMPercentage=70.0      # 按容器内存比例设置堆上限（8u191+ / 11+）

# 在容器内执行命令
docker exec -it <容器> jstack -l 1 > /tmp/jstack.txt      # 注意 pid 是容器内的 pid
docker cp <容器>:/tmp/heap.hprof ./heap.hprof             # 把 dump 拷到宿主机

# 容器里没有 JDK 时：使用 jattach（单个二进制文件）
docker cp jattach <容器>:/tmp/
docker exec <容器> /tmp/jattach 1 threaddump
docker exec <容器> /tmp/jattach 1 dumpheap /tmp/heap.hprof

# 容器 OOMKilled 判断（进程被内核杀掉，JVM 里没有 OOM 日志）
docker inspect <容器> --format '{{.State.OOMKilled}}'
kubectl describe pod <pod> | grep -i -A3 "last state"
dmesg -T | grep -i -E "oom|killed process"
```

- 容器内存限制 = 堆 + 元空间 + 线程栈 + 堆外 + JVM 自身。**`-Xmx` 不要设成与容器限制相同**，一般留 25%~30% 余量。
- dump 文件写到容器可写层会占满节点磁盘，务必挂载卷，并清理旧 dump。

---

## 七、案例：所有请求阻塞（日志写 stdout 卡死）

**现象**：所有接口无响应，进程存活，CPU 不高。

**排查流程**

```bash
# 1. 抓线程栈（间隔几秒抓两次，确认是持续卡住）
jstack -l <pid> > /tmp/jstack1.txt; sleep 5; jstack -l <pid> > /tmp/jstack2.txt

# 2. 统计线程状态分布
grep -o 'java.lang.Thread.State: [A-Z_]*' /tmp/jstack1.txt | sort | uniq -c

# 3. 统计 BLOCKED 线程都在等哪把锁
grep -o 'waiting to lock <0x[0-9a-f]*> ([^)]*)' /tmp/jstack1.txt | sort | uniq -c | sort -rn

# 4. 找持锁线程，看它卡在哪
grep -B2 -A30 "locked <0x00000000aab5b408>" /tmp/jstack1.txt

# 5. 看业务线程是从哪里进入被阻塞的
grep -A40 'waiting to lock <0x...>' /tmp/jstack1.txt | grep -E 'at (你的包名)\.' | sort | uniq -c | sort -rn | head

# 6. 是否死锁
grep -i deadlock /tmp/jstack1.txt
```

**判断标准**
- 大量线程 BLOCKED 在**同一把锁**上，持锁线程停在 `FileOutputStream.writeBytes`（native）：说明卡在 IO 写。
- 持锁线程栈里有 `ConsoleAppender` / `CloseShieldOutputStream` / `PrintStream`：写的是 stdout。
- 用 `ls -l /proc/<pid>/fd/1` 确认 stdout 去向：`pipe:`（管道对端不读）、`/dev/pts/N`（终端被堵，容器 `-t` 模式常见）、普通文件（磁盘问题）。
- 内核层看阻塞位置：`cat /proc/<pid>/task/<线程十进制id>/wchan`。

**修复**
1. 止血：`docker restart <容器>`；卡住则 `docker kill` 后再 `docker start`，最后才是 `systemctl restart docker`（先确认 live-restore）。
2. 生产环境去掉 log4j2 的 `<Console>` appender，只写 RollingFile 到挂载卷。
3. 容器去掉 tty（`tty: false` / 去掉 `-t`）。
4. 日志队列满时丢弃而不是阻塞：
   ```
   -Dlog4j2.asyncQueueFullPolicy=Discard
   -Dlog4j2.discardThreshold=INFO
   ```
5. 降低高频接口的 INFO 日志量。
6. 排查日志组件被反复重新初始化（线程名序号 `-501` 之类持续增长）：检查 `monitorInterval` 和配置中心的动态刷新逻辑。

---

## 八、常见问题速查流程

```
服务异常
  │
  ├─ 接口无响应 ──► jstack ×2~3 次
  │                  ├─ 大量 BLOCKED 同一把锁 ─► 看持锁线程（IO？死锁？慢 SQL？）
  │                  ├─ 大量线程 WAITING 在连接池 ─► 查数据库/Redis/HTTP 连接池是否耗尽、下游是否超时
  │                  └─ 线程池满 / 队列堆积 ─► 查线程池参数与下游耗时
  │
  ├─ CPU 高 ──► top -H → printf %x → jstack 定位线程
  │              ├─ GC 线程 ─► jstat -gcutil，查 Full GC / 内存泄漏
  │              └─ 业务线程 ─► 查死循环、正则、序列化、大对象计算
  │
  ├─ 内存高 / OOM ──► jstat → jmap -histo → 导出 dump → MAT 分析
  │                    └─ 堆内正常但进程 RSS 高 ─► 查堆外（NMT、Netty、DirectBuffer）
  │
  ├─ 进程消失 ──► 查 OOMKilled / dmesg / hs_err_pid.log / 是否 ExitOnOutOfMemoryError
  │
  └─ 重启前务必留现场：jstack、heap dump / histo、GC 日志、dmesg、应用日志
```

### 重启前留现场清单（脚本）

```bash
#!/bin/bash
PID=$1
D=/data/dump/$(date +%Y%m%d_%H%M%S); mkdir -p $D
jstack -l $PID > $D/jstack1.txt; sleep 3; jstack -l $PID > $D/jstack2.txt
jmap -histo $PID | head -100 > $D/histo.txt
jstat -gcutil $PID 1000 5 > $D/gcutil.txt
top -H -b -n 1 -p $PID | head -50 > $D/top_threads.txt
ls -l /proc/$PID/fd | wc -l > $D/fd_count.txt
ls -l /proc/$PID/fd/1 /proc/$PID/fd/2 > $D/stdout_fd.txt
grep -E "Threads|VmRSS" /proc/$PID/status > $D/proc_status.txt
dmesg -T | tail -100 > $D/dmesg.txt
# 堆 dump 较大、耗时长，按需执行：
# jcmd $PID GC.heap_dump -all $D/heap.hprof      # JDK 11+
# jmap -dump:format=b,file=$D/heap.hprof $PID    # JDK 8
echo "saved to $D"
```

---

## 九、推荐的通用 JVM 启动参数

```bash
# JDK 8
-Xms2g -Xmx2g -XX:MetaspaceSize=256m -XX:MaxMetaspaceSize=256m
-XX:+UseG1GC -XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/dump/
-XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:/data/logs/gc.log
-XX:+UseGCLogFileRotation -XX:NumberOfGCLogFiles=5 -XX:GCLogFileSize=50M
-Dlog4j2.asyncQueueFullPolicy=Discard -Dlog4j2.discardThreshold=INFO

# JDK 11+
-XX:MaxRAMPercentage=70.0
-XX:+UseG1GC -XX:MaxGCPauseMillis=200
-XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=/data/dump/
-Xlog:gc*:file=/data/logs/gc.log:time,uptime,level,tags:filecount=5,filesize=50m
-Dlog4j2.asyncQueueFullPolicy=Discard -Dlog4j2.discardThreshold=INFO
```

> 参数需按实际机器内存和业务特点调整，上线前在测试环境验证。
