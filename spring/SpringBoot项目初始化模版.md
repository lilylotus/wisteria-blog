---
title: "SpringBoot项目初始化模版"
subtitle: "SpringBoot项目初始化模版|SpringBoot项目初始化配置"
description: "SpringBoot项目初始化模版|SpringBoot项目初始化配置"
date: 2026-08-114T20:00:00+08:00
lastmod: 2026-08-14T20:00:00+08:00
draft: false

authors: ["yzx"]
tags: ["SpringBoot"]
categories: ["SpringBoot"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_2675.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# SpringBoot项目初始化

[SpringBoot 更新版本列表](https://spring.io/projects/spring-boot#learn)

## SpringBoot 3.x 版本初始化

整理 SpringBoot 项目创建初始化时对应的 SpringBoot 版本为 `3.5.16`

### 创建SpringBoot项目

[SpringBoot官方项目创建链接](https://start.spring.io/)

#### 项目依赖选择

| 名称            |                             依赖                             |
| --------------- | :----------------------------------------------------------: |
| web             |       org.springframework.boot:spring-boot-starter-web       |
| 服务监控        |    org.springframework.boot:spring-boot-starter-actuator     |
| redis           |   org.springframework.boot:spring-boot-starter-data-redis    |
| 数据库          |    com.baomidou:mybatis-plus-spring-boot3-starter:3.5.16     |
| springdoc       |   org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.17   |
| 参数校验        |   org.springframework.boot:spring-boot-starter-validation    |
| dto/vo转换      |                org.mapstruct:mapstruct:1.6.3                 |
| feign           |   org.springframework.cloud:spring-cloud-starter-openfeign   |
| nacos-discovery | com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery:2025.0.0.0 |
| nacos-config    | com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-config:2025.0.0.0 |

#### 项目基础版本选择

- SpringBoot ： 3.5.16
- SpringCloud：2025.0.3
- Jdk：21
- Gradle：8.14.4

### 基础配置文件

#### gradle.properties

配置 JDK 目录后面 `gradlew` 执行命令，若是全局安装的 JDK 也是 21 就可以不用单独配置。

```properties
org.gradle.jvmargs=-Dfile.encoding=UTF-8
org.gradle.warning.mode=summary
org.gradle.java.home=D:/kits/java/jdk-21.0.5

```

#### .editorconfig

全局文件编码规范

```properties
# EditorConfig 帮助多人协作时保持一致的编码风格
# 官网: https://editorconfig.org
# IntelliJ IDEA 原生支持；VS Code需装 EditorConfig for VS Code 插件

# 表示这是根配置文件，工具会停止向上级目录查找
root = true

# ========================================
# 所有文件通用的默认规则
# ========================================
[*]
charset = utf-8
end_of_line = lf
insert_final_newline = true
trim_trailing_whitespace = true
indent_style = space
indent_size = 4

# ========================================
# Java 源码文件
# ========================================
[*.java]
max_line_length = 120

# ========================================
# XML 配置文件 (Maven pom.xml、旧式Spring xml配置、MyBatis mapper等)
# ========================================
[*.xml]
indent_style = space
indent_size = 4

# ========================================
# YAML 配置文件 (application.yml 等，Spring Boot主流配置格式)
# ========================================
[*.{yml,yaml}]
indent_style = space
indent_size = 2

# ========================================
# Properties 配置文件 (application.properties)
# ========================================
[*.properties]
indent_style = space
indent_size = 4

# ========================================
# JSON 文件
# ========================================
[*.json]
indent_style = space
indent_size = 2

# ========================================
# SQL 文件 (数据库迁移脚本、建表语句等)
# ========================================
[*.sql]
indent_style = space
indent_size = 4

# ========================================
# Markdown 文档：不清理行尾空格
# 因为Markdown语法里"行尾两个空格"表示强制换行，是有意义的语法，不能当垃圾清掉
# ========================================
[*.md]
indent_style = tab
trim_trailing_whitespace = false
max_line_length = off

# ========================================
# Shell 脚本
# ========================================
[*.sh]
indent_style = space
indent_size = 2
end_of_line = lf

# ========================================
# Makefile: 必须用Tab缩进，这是Makefile语法的硬性要求，不能用空格
# ========================================
[Makefile]
indent_style = tab

# ========================================
# Windows批处理文件：保留CRLF换行符(Windows原生习惯)
# ========================================
[*.{bat,cmd}]
end_of_line = crlf

```

### 中间件配置

#### nacos

##### gradle 依赖

```groovy
    implementation 'org.springframework.cloud:spring-cloud-starter'
    implementation 'org.springframework.cloud:spring-cloud-starter-openfeign'
    implementation "com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-config:2025.0.0.0"
    implementation "com.alibaba.cloud:spring-cloud-starter-alibaba-nacos-discovery:2025.0.0.0"
```

##### Nacos Spring Cloud 配置

[Spring Boot 3x 使用 Nacos 官方说明文档](https://nacos.io/docs/next/ecology/use-nacos-with-spring-boot3/)

```yaml
spring:
  application:
    name: SpringBootTemplate
  profiles:
    active: prod
  config:
    import:
      - optional:nacos:${spring.application.name}.yml
      - optional:nacos:${spring.application.name}-${spring.profiles.active}.yml
  cloud:
    inetutils:
      preferredNetworks:
        - 127.0
    nacos:
      server-addr: 127.0.0.1:8848
#      username: nacos
#      password: nacos
      config:
        enabled: true
        file-extension: yml
      discovery:
        enabled: true
```

##### `spring.config.import` 配置说明

`spring.config.import` 是 Spring Boot 2.4+ 引入的**统一外部配置导入机制**，用来替代老版本 `bootstrap.yml` 那套加载方式，为什么会有这个机制，为了解决 `bootstrap.yml` 的历史包袱。Spring Boot 2.4 之前，Spring Cloud 生态（Nacos/Consul/Config Server）想要"在应用启动早期就从远程拉配置"，只能靠 `bootstrap.yml` 这套独立的、优先级更高的引导上下文机制，这套机制**不是Spring Boot原生支持的**，而是 Spring Cloud Context 额外加的一层，长期以来被社区诟病"概念复杂、两套配置文件容易搞混、启动流程不透明"。

**Spring Boot 2.4 引入的 `spring.config.import`，让"导入外部配置源"变成了Spring Boot原生统一支持的能力**，不再需要额外的bootstrap 阶段，逻辑更清晰，官方也逐步在推动生态往这个方向迁移。

**关键区别**：老版本 `bootstrap.yml` 是**隐式**的（只要类路径下有 `spring-cloud-starter-alibaba-nacos-config` 依赖，Spring Cloud就自动去连Nacos拉配置）；新版本用 `spring.config.import` 是**显式**的（必须明确写出"要导入哪个配置文件"），这样的好处是配置来源一目了然，不用去翻文档才知道"这个应用到底从哪读的配置"。

`spring.config.import` 支持的几种常见配置源，`optional:` 前缀——避免配置源不存在时启动失败（有则用，没有也不影响启动）

```yaml
spring:
  config:
    import:
      # 导入类路径下的另一个配置文件
      - "optional:classpath:extra-config.yml"
      # 导入文件系统路径下的配置文件
      - "optional:file:/etc/myapp/config.yml"
      # 导入Nacos配置
      - "optional:nacos:my-service.yaml"
      # 导入Spring Cloud Config Server配置
      - "optional:configserver:http://config-server:8888"
      # 导入Consul配置
      - "optional:consul:my-service"
      # 导入Vault配置(密钥管理场景)
      - "optional:vault://secret/my-service"
```

这几个配置源会按顺序合并，**后面的会覆盖前面的同名配置项**（数组是有顺序意义的），跟之前bootstrap.yml里 `extension-configs` 列表的合并逻辑思路一致，只是写法更统一。

#### Redis

##### 连接池配置

```yaml
spring:
  data:
    redis:
      host: ${REDIS_HOST:localhost}
      port: ${REDIS_PORT:6379}
      password: ${REDIS_PASSWORD:}
      database: ${REDIS_DATABASE:0}

      # 连接建立超时时间
      connect-timeout: 3000ms
      # 单条命令执行超时时间
      timeout: 3000ms

      # Lettuce连接池配置(默认客户端就是lettuce，不用额外指定client-type)
      lettuce:
        pool:
          enabled: true
          # 连接池最大连接数，负数表示不限制(不建议用负数，容易在异常场景下把Redis连接打爆)
          # max-active = (应用实例数 * 最大并发线程数) * 1.2
          # 例如：2个实例，每个实例最大线程数（如 tomcat.threads.max）为 50
          # 则可设置为 (2 * 50) * 1.2 ≈ 120
          # 但最终值绝不能超过 Redis 服务器端的 maxclients 配置，并要为其预留一部分。
          max-active: 20
          # 连接池最大空闲连接数，建议是 max-active 的 1/2 到 2/3
          max-idle: 10
          # 连接池最小空闲连接数(保持一定数量的热连接，避免每次现建连接的开销)，用于维持 warm-up，避免突发流量
          min-idle: 5
          # 连接池最大阻塞等待时间，超过这个时间还拿不到连接就抛异常，而不是无限等待
          max-wait: 3000ms
          # 连接空闲多久后被回收判定的检测周期
          time-between-eviction-runs: 30000ms
        # 关闭连接池时的超时时间(优雅关闭用，配合你之前问的容器优雅关闭场景)
        shutdown-timeout: 200ms

        # 读写分离场景才需要(比如Redis主从/Cluster模式，只有查询操作允许读从节点)
        # read-from: replica-preferred
```

关键参数说明

| 参数              | 说明                                                         |
| :---------------- | :----------------------------------------------------------- |
| `max-active`      | 连接池最大连接总数，这是最核心的容量控制参数，需要结合你的实际并发量压测调整，不是越大越好——过大的连接池反而会给Redis服务端造成压力 |
| `min-idle`        | 保持的最小空闲连接数，避免高并发瞬间大量"现建连接"导致延迟毛刺，相当于预热了一批连接常驻 |
| `max-wait`        | **生产环境务必设置一个合理的正数值，不要用默认的`-1ms`(无限等待)**——如果Redis服务端故障或连接池耗尽，无限等待会导致你的应用线程被大量卡死拖垮，设置超时能让请求快速失败，配合熔断/降级机制处理，比无限期挂起更可控 |
| `connect-timeout` | 建连阶段的超时，网络异常/Redis服务不可达时能快速失败         |
| `timeout`         | 单条命令执行的超时(不是建连而是命令本身)，防止某条慢查询/网络抖动拖死调用方线程 |

##### Actuator连接池监控

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,prometheus,metrics
  metrics:
    enable:
      lettuce: true
```

开启后能通过 `/actuator/prometheus` 采集到Lettuce连接池的实时指标（活跃连接数、空闲连接数等），配合搭建的Prometheus + Grafana监控体系，可以对连接池使用情况做可视化观察，及时发现连接池耗尽等异常。

#### 数据库

##### 连接池配置

```yaml
spring:
  datasource:
    type: com.zaxxer.hikari.HikariDataSource
    driver-class-name: com.mysql.cj.jdbc.Driver
    url: jdbc:mysql://127.0.0.1:3306/test?useUnicode=true&characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
    username: root
    password: mysql
    hikari:
      # 连接池名称，多数据源场景下方便区分日志/监控指标
      pool-name: HikariPool-TemplateService
      # 最大连接数：核心参数，需要结合数据库最大连接数、应用实例数一起算
      # 经验公式: ((core_count * 2) + effective_spindle_count)，简单场景可以从10开始压测调整
      maximum-pool-size: 20
      # 最小空闲连接数：保持的常驻连接，避免高峰期现建连接的延迟开销
      # HikariCP官方建议：如果没有明确理由，minimum-idle应该跟maximum-pool-size保持一致
      # 固定大小的连接池在生产环境表现更稳定、更可预测，波动连接池反而容易引发性能抖动
      minimum-idle: 20
      # 从连接池获取连接的最大等待时间，超时抛异常而不是无限期卡住
      connection-timeout: 30000
      # 连接在池中最大空闲时间，超过这个时间空闲连接会被回收(前提是连接数依然大于minimum-idle)
      idle-timeout: 600000
      # 连接的最大生命周期，到期后即使正在使用也会被安全地关闭重建
      # 这个值必须比MySQL自身的wait_timeout(默认8小时)小，
      # 否则MySQL端会先把"看起来还在池子里"的连接断开，
      # 应用这边却不知道，下次用到时才发现连接已经失效，抛异常
      max-lifetime: 1800000
      # 连接泄漏检测：超过这个时间连接还没被归还，会打印警告日志(排查连接泄漏问题的利器)
      # 生产环境建议开启，设为比正常业务SQL执行时间稍长的值
      leak-detection-threshold: 60000
      # 连接有效性检测查询(MySQL 5.6+建议用JDBC4的isValid()方法，不需要手动写这个)
      # connection-test-query: SELECT 1
      # 是否在连接归还池中之前自动提交，一般保持默认true即可(除非你手动管理事务)
      auto-commit: true
```

核心参数说明

| 参数                       | 推荐值                      | 说明                                                         |
| -------------------------- | --------------------------- | ------------------------------------------------------------ |
| `maximum-pool-size`        | 根据压测调整，起点10-20     | **不是越大越好**，连接数过多反而会因为数据库端上下文切换开销导致性能下降，HikariCP官方文档明确指出这一点，连接池不是越大吞吐量越高 |
| `minimum-idle`             | 建议等于`maximum-pool-size` | 官方推荐固定大小的连接池，而不是动态伸缩，生产环境表现更稳定 |
| `connection-timeout`       | 30000ms(30秒)               | 获取连接的超时时间，太短容易在瞬时高峰误杀正常请求，太长会导致请求堆积 |
| `max-lifetime`             | 1800000ms(30分钟)           | **必须小于数据库的`wait_timeout`**，这是最容易被忽视但很关键的一点 |
| `leak-detection-threshold` | 60000ms(60秒)               | 生产环境建议开启，能帮你快速定位"连接用完忘记关闭"这类代码bug |

确认MySQL的 `wait_timeout` 配置（避免连接失效问题）

```sql
SHOW VARIABLES LIKE 'wait_timeout'; // 28800
```

如果MySQL的 `wait_timeout` 是默认的28800秒（8小时），而你的HikariCP `max-lifetime` 设置的比这个值大，就可能出现"连接池认为连接还活着，但MySQL端已经主动断开了"的情况，导致业务代码偶发遇到 `Communications link failure` 这类异常。**保证 `max-lifetime` 略小于MySQL的 `wait_timeout`（官方建议至少短30秒）**，让连接在MySQL主动断开之前，由连接池主动、优雅地完成重建。

##### Actuator 监控连接池状态

```yaml
management:
  endpoints:
    web:
      exposure:
        include: health,prometheus,metrics
  metrics:
    enable:
      hikaricp: true
```

开启后能通过 `/actuator/prometheus` 采集到HikariCP连接池的实时指标（活跃连接数、等待连接的线程数、连接获取耗时等），是排查"连接池耗尽导致接口变慢"这类问题最直接的数据来源，配合搭建的Prometheus + Grafana监控体系可以做可视化告警。

##### 容器化场景补充

如果这个应用部署在K8s里、多副本运行，注意 `maximum-pool-size` 要考虑**总连接数**是否超过数据库的 `max_connections` 限制：

```
应用副本数 × maximum-pool-size ≤ 数据库max_connections × 安全系数(建议0.8左右，留给其他客户端/管理连接)
```

比如数据库 `max_connections=500`，你有5个应用副本，每个 `maximum-pool-size=20`，总共占用100个连接，还比较安全；但如果副本数扩容到20个，同样的单实例配置就会占用400个连接，逼近数据库上限，这种场景需要重新压测调整单实例的连接池大小，而不是保持"每个实例都用同一份配置"不做区分。