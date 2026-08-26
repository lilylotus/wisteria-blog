# Netty基础记录

## Netty Server option参数优化配置

Netty `ServerBootstrap` `childOption`/`option` 参数优化配置

### 基础参数概念区别

```java
ServerBootstrap bootstrap = new ServerBootstrap();
bootstrap.group(bossGroup, workerGroup)
    .channel(NioServerSocketChannel.class)
    .option(ChannelOption.XXX, value)        // 作用于服务端 Channel（监听 Socket）
    .childOption(ChannelOption.XXX, value);  // 作用于客户端连接 Channel（每个连接的 Socket）
```

|          | `option()`                        | `childOption()`                  |
| -------- | --------------------------------- | -------------------------------- |
| 作用对象 | ServerSocketChannel（父 Channel） | SocketChannel（每个客户端连接）  |
| 举例     | 连接监听队列大小                  | TCP_NODELAY、心跳、Buffer 大小等 |

### 完整推荐优化配置

```java
public class NettyServer {
    public void start() throws InterruptedException {
        EventLoopGroup bossGroup = new NioEventLoopGroup(1);
        EventLoopGroup workerGroup = new NioEventLoopGroup(); // 默认 CPU核数*2

        ServerBootstrap bootstrap = new ServerBootstrap();
        bootstrap.group(bossGroup, workerGroup)
            .channel(NioServerSocketChannel.class)
            // ============ option: 作用于父 Channel ============
            .option(ChannelOption.SO_BACKLOG, 1024)           // 全连接队列大小
            .option(ChannelOption.SO_REUSEADDR, true)         // 端口复用
            
            // ============ childOption: 作用于子 Channel ============
            .childOption(ChannelOption.TCP_NODELAY, true)             // 禁用 Nagle 算法
            .childOption(ChannelOption.SO_KEEPALIVE, true)            // TCP 保活
            .childOption(ChannelOption.SO_RCVBUF, 65536)              // 接收缓冲区
            .childOption(ChannelOption.SO_SNDBUF, 65536)              // 发送缓冲区
            .childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT) // 内存池
            .childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
                new WriteBufferWaterMark(32 * 1024, 64 * 1024))       // 写缓冲水位线
            .childOption(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)  // 连接超时
            .childHandler(new ChannelInitializer<SocketChannel>() {
                @Override
                protected void initChannel(SocketChannel ch) {
                    ch.pipeline().addLast(new YourHandler());
                }
            });

        ChannelFuture future = bootstrap.bind(8080).sync();
        future.channel().closeFuture().sync();
    }
}
```

#### `SO_BACKLOG`（用于 `option`，不是 childOption）

```java
.option(ChannelOption.SO_BACKLOG, 1024)
```

- 控制 TCP 三次握手完成后、应用层 `accept()` 之前的**全连接队列**大小

- 高并发短连接场景（如网关）建议调大到 1024~2048

- Linux 下还要注意 `/proc/sys/net/core/somaxconn` 系统参数需 >= 这个值，否则会被系统截断

---

#### `TCP_NODELAY`（强烈推荐开启）

```java
.childOption(ChannelOption.TCP_NODELAY, true)
```

- 禁用 **Nagle 算法**：默认 TCP 会攒够一定数据量或等待 ACK 才发送小包，会带来延迟

- 对于 RPC、游戏服务器、实时通信等**低延迟场景必须开启**

- 唯一代价：小包场景下网络包数量增多，但现代网络带宽下几乎可忽略

#### `SO_KEEPALIVE`

```java
.childOption(ChannelOption.SO_KEEPALIVE, true)
```

- 开启 TCP 层保活探测，检测死连接（默认 2 小时无数据才探测，周期较长）
- **注意**：这是操作系统级别的保活，间隔太长，实际业务中通常自己实现**应用层心跳**（如 IdleStateHandler）更靠谱，`SO_KEEPALIVE` 作为兜底即可

------

#### `SO_RCVBUF` / `SO_SNDBUF`

```java
.childOption(ChannelOption.SO_RCVBUF, 65536)  // 64KB
.childOption(ChannelOption.SO_SNDBUF, 65536)
```

- 操作系统 Socket 接收/发送缓冲区大小
- 高吞吐场景（大文件传输、视频流）适当调大（如 128KB~1MB）
- 高并发短连接场景不宜过大，避免内存浪费（连接数 × buffer大小 可能撑爆内存）

------

#### `ALLOCATOR`（内存分配器，性能关键项）

```java
.childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT)
```

- Netty 4.1+ 默认已经是 `PooledByteBufAllocator`（内存池化，减少 GC 压力）
- 高并发场景务必确认使用池化分配器，而不是 `UnpooledByteBufAllocator`
- 可进一步开启 direct memory：

```java
// true = 使用堆外内存
.childOption(ChannelOption.ALLOCATOR, new PooledByteBufAllocator(true))
```

------

#### `WRITE_BUFFER_WATER_MARK`（背压控制，重要）

```java
.childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
    new WriteBufferWaterMark(32 * 1024, 64 * 1024))
```

- 控制写缓冲区的**高低水位线**
- 低水位（32KB）：写缓冲区数据量低于此值时，`channel.isWritable()` 恢复为 `true`
- 高水位（64KB）：超过此值时，`isWritable()` 变为 `false`，提示应用层应该暂停写入，避免 OOM

```java
// 配合使用，防止发送速度过快压垮 Netty 内部队列
if (ctx.channel().isWritable()) {
    ctx.writeAndFlush(msg);
} else {
    // 触发限流/丢弃/缓存策略
}
```

------

#### `CONNECT_TIMEOUT_MILLIS`

```java
.childOption(ChannelOption.CONNECT_TIMEOUT_MILLIS, 5000)
```

- 严格来说这个更常用在客户端 `Bootstrap`（不是 ServerBootstrap），服务端场景意义不大，可省略

------

### 按场景推荐配置

#### 场景一：高并发短连接网关（如 API Gateway）

```java
.option(ChannelOption.SO_BACKLOG, 2048)
.childOption(ChannelOption.TCP_NODELAY, true)
.childOption(ChannelOption.SO_RCVBUF, 32 * 1024)
.childOption(ChannelOption.SO_SNDBUF, 32 * 1024)
.childOption(ChannelOption.ALLOCATOR, PooledByteBufAllocator.DEFAULT)
```

#### 场景二：长连接、大流量传输（文件服务器、视频流）

```java
.childOption(ChannelOption.TCP_NODELAY, true)
.childOption(ChannelOption.SO_KEEPALIVE, true)
.childOption(ChannelOption.SO_RCVBUF, 256 * 1024)
.childOption(ChannelOption.SO_SNDBUF, 256 * 1024)
.childOption(ChannelOption.WRITE_BUFFER_WATER_MARK, 
    new WriteBufferWaterMark(256 * 1024, 512 * 1024))
```

#### 场景三：IM / 长连接推送服务（大量空闲连接）

```java
.option(ChannelOption.SO_BACKLOG, 1024)
.childOption(ChannelOption.TCP_NODELAY, true)
.childOption(ChannelOption.SO_KEEPALIVE, true)
.childOption(ChannelOption.SO_RCVBUF, 16 * 1024)  // 小一点，节省内存
.childOption(ChannelOption.SO_SNDBUF, 16 * 1024)
// 配合应用层心跳
.childHandler(new ChannelInitializer<SocketChannel>() {
    protected void initChannel(SocketChannel ch) {
        ch.pipeline().addLast(new IdleStateHandler(60, 0, 0, TimeUnit.SECONDS));
        ch.pipeline().addLast(new HeartbeatHandler());
    }
});
```

------

### EventLoopGroup 配套优化（不是 childOption，但同样重要）

```java
// bossGroup 通常 1 个线程足够（只负责 accept）
EventLoopGroup bossGroup = new NioEventLoopGroup(1);

// workerGroup 线程数一般设为 CPU核数*2，IO密集型可适当增加
EventLoopGroup workerGroup = new NioEventLoopGroup(
    Runtime.getRuntime().availableProcessors() * 2);

// Linux 下推荐用 EpollEventLoopGroup 替代 NioEventLoopGroup，性能更优
if (Epoll.isAvailable()) {
    bossGroup = new EpollEventLoopGroup(1);
    workerGroup = new EpollEventLoopGroup();
    bootstrap.channel(EpollServerSocketChannel.class);
}
```

------

### 排查建议

| 现象                 | 优化方向                                                     |
| -------------------- | ------------------------------------------------------------ |
| 连接建立慢/拒绝连接  | 调大 `SO_BACKLOG`，同步调大系统 `somaxconn`                  |
| 消息延迟高           | 检查 `TCP_NODELAY` 是否开启                                  |
| 高并发下频繁 GC      | 确认 `ALLOCATOR` 是否为池化分配器，考虑 direct memory        |
| 内存暴涨/OOM         | 检查 `WRITE_BUFFER_WATER_MARK` 是否配置，是否有做 `isWritable()` 判断 |
| 大量连接但吞吐上不去 | 适当调大 `SO_RCVBUF`/`SO_SNDBUF`，检查 workerGroup 线程数    |

## Netty Pipeline常用Handler说明

### Pipeline 基本结构

```java
bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
    @Override
    protected void initChannel(SocketChannel ch) {
        ChannelPipeline pipeline = ch.pipeline();
        // 处理器按添加顺序形成责任链
        // Inbound（入站，如读取数据）：从上到下执行
        // Outbound（出站，如写数据）：从下到上执行
        pipeline.addLast("handler1", new Handler1());
        pipeline.addLast("handler2", new Handler2());
    }
});
```

### 编解码类处理器

#### 分隔符/定长解码器

```java
// 按换行符分割（常用于文本协议）
pipeline.addLast(new LineBasedFrameDecoder(1024)); // 最大长度1024

// 自定义分隔符
pipeline.addLast(new DelimiterBasedFrameDecoder(1024, Unpooled.copiedBuffer("$_$".getBytes())));

// 定长解码（每条消息固定长度）
pipeline.addLast(new FixedLengthFrameDecoder(100));
```

#### 长度字段解码器（TCP 粘包/拆包核心解决方案）

```java
// 最常用！根据消息头中的长度字段自动切分完整数据包
pipeline.addLast(new LengthFieldBasedFrameDecoder(
    1024 * 1024,  // maxFrameLength：最大帧长度
    0,            // lengthFieldOffset：长度字段偏移量
    4,            // lengthFieldLength：长度字段占用字节数
    0,            // lengthAdjustment：长度调整值
    4             // initialBytesToStrip：跳过的初始字节数（通常跳过长度字段本身）
));

// 编码端配合使用：自动在消息前添加长度字段
pipeline.addLast(new LengthFieldPrepender(4)); // 4字节表示长度
```

**这是自定义二进制协议最常用、最推荐的组合**，能彻底解决 TCP 粘包/拆包问题。

#### 字符串编解码器

```java
pipeline.addLast(new StringDecoder(CharsetUtil.UTF_8));
pipeline.addLast(new StringEncoder(CharsetUtil.UTF_8));
```

#### JSON 序列化（自定义示例）

```java
// 需自己实现或用第三方库（如 Jackson）
pipeline.addLast(new JsonObjectDecoder());  // 提取完整 JSON 对象
pipeline.addLast(new MyJsonMessageDecoder()); // 反序列化为业务对象
```

#### Protobuf 编解码器（RPC 场景常用）

```java
pipeline.addLast(new ProtobufVarint32FrameDecoder());
pipeline.addLast(new ProtobufDecoder(MyMessage.getDefaultInstance()));
pipeline.addLast(new ProtobufVarint32LengthFieldPrepender());
pipeline.addLast(new ProtobufEncoder());
```

------

### HTTP 协议处理器

```java
// HTTP 编解码，包含 HttpRequestDecoder + HttpResponseEncoder
pipeline.addLast(new HttpServerCodec());

// 将 HTTP 消息聚合为 FullHttpRequest/FullHttpResponse（避免分块处理）
pipeline.addLast(new HttpObjectAggregator(64 * 1024 * 1024)); // 最大64MB

// 支持大文件分块传输（配合 HttpObjectAggregator 使用）
pipeline.addLast(new ChunkedWriteHandler());

// gzip 压缩支持
pipeline.addLast(new HttpContentCompressor());
pipeline.addLast(new HttpContentDecompressor());

// WebSocket 升级支持
pipeline.addLast(new WebSocketServerProtocolHandler("/ws"));
```

------

### 心跳/空闲检测

```java
// 参数：读空闲时间、写空闲时间、读写空闲时间（秒）
pipeline.addLast(new IdleStateHandler(60, 0, 0, TimeUnit.SECONDS));

// 配合自定义 Handler 处理空闲事件
pipeline.addLast(new ChannelInboundHandlerAdapter() {
    @Override
    public void userEventTriggered(ChannelHandlerContext ctx, Object evt) {
        if (evt instanceof IdleStateEvent) {
            IdleStateEvent event = (IdleStateEvent) evt;
            if (event.state() == IdleState.READER_IDLE) {
                // 超过60秒没收到数据，判定为死连接，关闭
                System.out.println("连接空闲，关闭连接");
                ctx.close();
            }
        }
    }
});
```

**这是 IM、长连接推送服务的标配**，用于及时清理僵尸连接、释放资源。

------

### 安全相关

```java
// SSL/TLS 加密（必须放在 pipeline 最前面）
SslContext sslContext = SslContextBuilder.forServer(certFile, keyFile).build();
pipeline.addFirst(new SslHandler(sslContext.newEngine(ch.alloc())));
```

------

### 流量控制

```java
// 全局限流：所有 Channel 共享一个 GlobalTrafficShapingHandler
pipeline.addLast(new ChannelTrafficShapingHandler(
    1024 * 1024,  // 写限速 1MB/s
    1024 * 1024   // 读限速 1MB/s
));
```

------

### 业务处理器（自定义）

```java
public class BusinessHandler extends SimpleChannelInboundHandler<MyMessage> {
    @Override
    protected void channelRead0(ChannelHandlerContext ctx, MyMessage msg) {
        // 业务逻辑处理
        MyMessage response = process(msg);
        ctx.writeAndFlush(response);
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close(); // 异常统一关闭连接
    }
}
```

推荐用 **`SimpleChannelInboundHandler`** 而非 `ChannelInboundHandlerAdapter` ，前者会自动释放 `ByteBuf` 避免内存泄漏。

------

### 完整示例：自定义 TCP 协议服务器（常见组合）

```java
bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
    @Override
    protected void initChannel(SocketChannel ch) {
        ChannelPipeline pipeline = ch.pipeline();

        // 1. 空闲检测（心跳）
        pipeline.addLast(new IdleStateHandler(60, 30, 0, TimeUnit.SECONDS));

        // 2. 解决粘包/拆包
        pipeline.addLast(new LengthFieldBasedFrameDecoder(1024 * 1024, 0, 4, 0, 4));
        pipeline.addLast(new LengthFieldPrepender(4));

        // 3. 序列化/反序列化
        pipeline.addLast(new MyProtobufDecoder());
        pipeline.addLast(new MyProtobufEncoder());

        // 4. 心跳处理
        pipeline.addLast(new HeartbeatHandler());

        // 5. 业务处理
        pipeline.addLast(new BusinessHandler());

        // 6. 全局异常处理（放最后兜底）
        pipeline.addLast(new ExceptionHandler());
    }
});
```

### 完整示例：HTTP 服务器常见组合

```java
bootstrap.childHandler(new ChannelInitializer<SocketChannel>() {
    @Override
    protected void initChannel(SocketChannel ch) {
        ChannelPipeline pipeline = ch.pipeline();

        pipeline.addLast(new HttpServerCodec());
        pipeline.addLast(new HttpObjectAggregator(10 * 1024 * 1024));
        pipeline.addLast(new ChunkedWriteHandler());
        pipeline.addLast(new HttpContentCompressor());
        pipeline.addLast(new MyHttpBusinessHandler());
    }
});
```

------

### 关键注意事项

| 注意点           | 说明                                                         |
| ---------------- | ------------------------------------------------------------ |
| Handler 顺序敏感 | 解码器必须在业务 Handler 之前；编码器顺序理论上无所谓（Outbound 反向执行），但建议紧跟解码器放置便于维护 |
| SslHandler 位置  | 必须 `addFirst`，加密要在最外层                              |
| 状态共享问题     | 编解码器多为 `@Sharable` 无状态，可以单例复用；业务 Handler 若含状态需每次 `new` 新实例（因为每个连接对应新的 pipeline 实例） |
| 异常处理         | 建议在 pipeline 末尾加统一异常处理器，避免异常吞掉导致连接假死 |
| ByteBuf 释放     | 用 `SimpleChannelInboundHandler` 自动释放；手动用 `ChannelInboundHandlerAdapter` 时要记得 `ReferenceCountUtil.release()` |
