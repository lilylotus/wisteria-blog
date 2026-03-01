# MySQL主从配置

## MySQL 5.7 与 8.x 主从复制配置差异详解

MySQL 8.0 在主从复制方面引入了多项重要改进，与 5.7 版本存在显著差异。

### 认证差异

#### MySQL 5.7

```bash
CREATE USER 'repl'@'%' IDENTIFIED BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
```

#### MySQL 5.8

```bash
CREATE USER 'repl'@'%' IDENTIFIED WITH mysql_native_password BY 'password';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
```

*必须指定 `mysql_native_password` 插件，因为 8.0 默认使用 caching_sha2_password*

### 复制命令

#### MySQL 5.7

```bash
CHANGE MASTER TO
  MASTER_HOST='master_host',
  MASTER_USER='repl',
  MASTER_PASSWORD='password',
  MASTER_LOG_FILE='mysql-bin.000001',
  MASTER_LOG_POS=154;
START SLAVE;
```

#### MySQL 5.8（推荐）

```bash
CHANGE REPLICATION SOURCE TO
  SOURCE_HOST='master_host',
  SOURCE_USER='repl',
  SOURCE_PASSWORD='password',
  SOURCE_AUTO_POSITION=1;
START REPLICA;
```

*注意：`SLAVE` 改为 `REPLICA`，`MASTER` 改为 `SOURCE` 的新语法*



## MySQL 5.7 优化参数配置

### 基础配置

#### 内存参数

```ini
[mysqld]
# 缓冲池大小（通常设为物理内存的 50-70%）
innodb_buffer_pool_size = 4G
# 缓冲池实例数（建议每1GB配1个实例）
innodb_buffer_pool_instances = 4
# 日志缓冲区大小
innodb_log_buffer_size = 16M
# 排序缓冲区大小
sort_buffer_size = 2M
join_buffer_size = 2M
read_buffer_size = 2M
read_rnd_buffer_size = 2M
```

#### 连接和会话

```ini
# 最大连接数
max_connections = 500
# 连接超时时间
wait_timeout = 300
interactive_timeout = 300
# 临时表大小
tmp_table_size = 64M
max_heap_table_size = 64M
```

### InnoDB 引擎优化

```ini
# 日志文件大小（建议每组256M-2G）
innodb_log_file_size = 512M
innodb_log_files_in_group = 2
# 刷盘策略（平衡安全与性能）
innodb_flush_method = O_DIRECT
innodb_flush_log_at_trx_commit = 1  # 重要数据用 1，可容忍丢失用 2
sync_binlog = 1                     # 主库用 1，从库可设 0
# 事务隔离级别
transaction_isolation = READ-COMMITTED

# I/O
# I/O线程数
innodb_read_io_threads = 8
innodb_write_io_threads = 8
# 预读设置
innodb_flush_neighbors = 1      # HDD建议1，SSD建议0
innodb_random_read_ahead = OFF
# 异步I/O
innodb_use_native_aio = ON
```

```ini
innodb_buffer_pool_size = 8G
innodb_io_capacity = 1000
innodb_io_capacity_max = 2000
innodb_lru_scan_depth = 2000
```

**缓冲池大小**：逐步增加`innodb_buffer_pool_size`直到命中率稳定在95%以上

```sql
SHOW STATUS LIKE 'Innodb_buffer_pool_read%';

SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_reads';
SHOW GLOBAL STATUS LIKE 'Innodb_buffer_pool_read_requests';

-- 命中率计算公式：
-- 命中率 = (1 - (Innodb_buffer_pool_reads / Innodb_buffer_pool_read_requests)) * 100
```

### 查询优化

```ini
# 查询缓存（通常建议禁用）
query_cache_type = 0
query_cache_size = 0

# 统计信息
innodb_stats_on_metadata = OFF
innodb_stats_persistent = ON
innodb_stats_auto_recalc = ON
```



