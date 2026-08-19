# RocketMQ相关问题排查

## RocketMQ消费问题排查

### 先列出集群里全部消费者组
```bash
sh mqadmin clusterList -n localhost:9876
```

输出示例

```
#Cluster Name  #Broker Name  #BID  #Addr               #Version  #InTPS(LOAD)  #OutTPS(LOAD)  #Timer(Progress)    #PCWait(ms)  #Hour    #SPACE  #ACTIVATED
DefaultCluster  broker-a     0     10.4.100.123:10911  V5_1_2    0.00(0,0ms)    0.00(0,0ms)   0-0(0.0w, 0.0, 0.0)  0            504.50  0.4600   true
```

### 查看Broker消费者信息

```bash
# sh mqadmin brokerConsumeStats -n localhost:9876 -b 10.4.100.123:10911

sh mqadmin brokerConsumeStats -n localhost:9876 -b 10.4.100.123:10911 | grep 'topic.id-res'
```

输出示例

```
#Topic     #Group         #Broker Name  #QID  #Broker Offset  #Consumer Offset  #Diff   #LastTime
topic-id   topic-id-res   broker-a       0     8                8                0       2026-08-18 14:52:30
```

这条命令会拉取 Broker 上所有消费者组的消费统计数据（对应之前查到的Broker地址 10.4.100.123:10911）

输出里能看到每个消费者组、对应Topic、消费进度等信息，相当于间接实现了"查看有哪些消费者组"的效果。

### 查看消费者组当前有哪些客户端实例在线

```bash
# sh mqadmin consumerConnection -n localhost:9876 -g <你的消费者组名>
sh mqadmin consumerConnection -n localhost:9876 -g topic-id-res
```

输出示例

```
#ClientId                                           #ClientAddr           #Language  #Version
10.4.100.123@10.4.100.123:9876@20@1245146303493722 10.4.100.123:43588     JAVA       V4_9_7

Below is subscription:
#Topic                      #SubExpression
%RETRY%topic-id-res         *
topic-id-restopicExchange   *

ConsumeType: CONSUME_PASSIVELY
MessageModel: CLUSTERING
ConsumeFromWhere: CONSUME_FROM_LAST_OFFSET
```

输出会列出当前连接到这个消费者组的所有客户端实例（IP、客户端ID、版本号等），这是判断"消费者到底有没有成功注册上"最直接的命令，如果这里返回空或者报错"找不到消费者组"，说明消费者压根没连上。

### 消费者组客户端消费进度和堆积情况

```bash
sh mqadmin consumerProgress -n localhost:9876 -g <你的消费者组名>

sh mqadmin consumerProgress -n localhost:9876 -g topic-id-res
```

输出示例

```
#Topic       #Broker Name  #QID  #Broker Offset  #Consumer Offset  #Diff  #Inflight  #LastTime
%RETRY%topic  broker-a     0     0               0                 0      0          N/A
topic-id-res  broker-a     0     8               8                 0      0          2026-08-18 14:52:30
topic-id-res  broker-a     1     14              14                0      0          2026-08-18 14:52:30
topic-id-res  broker-a     2     14              14                0      0          2026-08-18 12:01:40
topic-id-res  broker-a     3     9               9                 0      0          2026-08-18 12:01:40

Consume TPS: 0.00
Consume Diff Total: 0
Consume Inflight Total: 0
```

看输出里的 `Diff` 列——这个值代表"生产的消息数 - 已消费的消息数"，也就是堆积量：

- `Diff` 一直是0或很小 → 消费很正常，之前"没看到消费"可能是你排查的方式有问题（比如日志级别没打印出来，或者查的不是实际消费到的Topic）
- `Diff` 持续增长、数值很大 → 消息在堆积，消费者要么处理速度跟不上，要么消费逻辑内部卡住了

*n关键验证：隔几分钟再跑一次同样的命令，对比 `Diff` 和 `LastTime` 有没有变化**

- **如果 `LastTime` 在往前推进、`Diff` 在减少甚至归零** → 完全正常，只是消费有一点点延迟（正常，消费不可能做到绝对零延迟）

- **如果 `LastTime` 和 `Diff` 长时间纹丝不动**（比如你等了5-10分钟再查还是这几个数字）→ 说明消费者**确实卡住了**，这时候才需要真正排查消费者内部逻辑

检查消费者线程是否卡在某个阻塞操作上

```bash
jstack <你的应用进程pid> | grep -A 30 "ConsumeMessageThread"
```

看消费线程当前的调用栈，是不是卡在某个网络调用/数据库操作上迟迟不返回（结合你之前配置过的Feign/Redis/MySQL连接池场景，如果消费逻辑里调用了这些下游依赖，某个连接池耗尽或者下游服务响应慢，都可能导致消费线程被长期占用）。

### 查看Topic本身有没有消息真正写进去

```bash
# sh mqadmin topicStatus -n localhost:9876 -t <你的topic名>
sh mqadmin topicStatus -n localhost:9876 -t topic-id-restopicExchange
```

输出示例

```
#Broker Name    #QID  #Min Offset           #Max Offset            #Last Updated
broker-a        0     0                     8                      2026-08-18 14:52:30,830
broker-a        1     0                     14                     2026-08-18 14:52:30,811
broker-a        2     0                     14                     2026-08-18 12:01:40,944
broker-a        3     0                     9                      2026-08-18 12:01:40,944
```

直接查这个真正的Topic有没有消息，顺便查一下Topic本身有没有消息真正写进去，看 maxOffset 这个值是不是在持续增长