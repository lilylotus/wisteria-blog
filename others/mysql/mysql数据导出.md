
## mysql 导出表结构

```bash
# 导出整个数据库的表结构（不包含数据）
mysqldump -u username -p -d database_name > database_structure.sql

# 导出指定表的表结构
mysqldump -u username -p -d database_name table1 table2 > tables_structure.sql

# 导出多个数据库的表结构
mysqldump -u username -p -d --databases db1 db2 db3 > multiple_dbs_structure.sql

# 导出所有数据库的表结构
mysqldump -u username -p -d --all-databases > all_databases_structure.sql
```

### mysql 导出表数据

```bash
# 导出整个数据库（包含结构和数据）
mysqldump -u username -p database_name > database_backup.sql

# 只导出数据，不导出结构
mysqldump -u username -p --no-create-info database_name > data_only.sql

# 导出指定表的数据
mysqldump -u username -p --no-create-info database_name table1 table2 > tables_data.sql

# 导出数据，忽略某些表
mysqldump -u username -p --ignore-table=database_name.table1 database_name > data_exclude.sql
```

### mysqldump 基础用法

#### 创建备份账号

```sql
-- 创建备份专用用户
CREATE USER 'backup'@'localhost' IDENTIFIED BY 'Backup@123456';

-- mysqldump所需权限
GRANT PROCESS, REPLICATION CLIENT, SELECT, SHOW VIEW, TRIGGER, LOCK TABLES, EVENT ON *.* TO 'backup'@'localhost';

-- XtraBackup所需权限
GRANT RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON *.* TO 'backup'@'localhost';
GRANT BACKUP_ADMIN ON *.* TO 'backup'@'localhost';  -- MySQL 8.0+
GRANT SELECT ON performance_schema.log_status TO 'backup'@'localhost';
GRANT SELECT ON performance_schema.keyring_component_status TO 'backup'@'localhost';

FLUSH PRIVILEGES;
```

#### mysqldump 基础用法

```bash
# 备份单个数据库
mysqldump -u backup -pBackup@123456 \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --default-character-set=utf8mb4 \
    mydb > mydb_$(date +%Y%m%d).sql

# 备份多个数据库
mysqldump -u backup -pBackup@123456 \
    --single-transaction \
    --routines \
    --triggers \
    --databases db1 db2 db3 > multi_db_$(date +%Y%m%d).sql

# 备份所有数据库
mysqldump -u backup -pBackup@123456 \
    --single-transaction \
    --routines \
    --triggers \
    --events \
    --all-databases > all_db_$(date +%Y%m%d).sql

# 备份单个表
mysqldump -u backup -pBackup@123456 \
    --single-transaction \
    mydb users > mydb_users_$(date +%Y%m%d).sql

# 只备份表结构
mysqldump -u backup -pBackup@123456 \
    --no-data \
    mydb > mydb_schema_$(date +%Y%m%d).sql

# 只备份数据
mysqldump -u backup -pBackup@123456 \
    --no-create-info \
    --single-transaction \
    mydb > mydb_data_$(date +%Y%m%d).sql
```

#### 关键参数说明

```bash
# 生产环境推荐参数组合
mysqldump -u backup -p 'Backup@123456' \
    --single-transaction \          # InnoDB一致性读，不锁表
    --master-data=2 \               # 记录binlog位置（注释形式）
    --routines \                    # 包含存储过程和函数
    --triggers \                    # 包含触发器
    --events \                      # 包含事件调度器
    --set-gtid-purged=AUTO \        # GTID处理（自动判断）
    --hex-blob \                    # 二进制数据使用十六进制
    --quick \                       # 逐行读取，减少内存使用
    --max-allowed-packet=512M \     # 大数据包支持
    --default-character-set=utf8mb4 \  # 字符集
    --all-databases \
    | gzip > /backup/mysql/full/all_db_$(date +%Y%m%d).sql.gz

# MySQL 8.0.26+ 使用新参数名
# --master-data 改为 --source-data
mysqldump -u backup -p 'Backup@123456' \
    --single-transaction \
    --source-data=2 \               # 新参数名
    --all-databases \
    | gzip > /backup/mysql/full/all_db_$(date +%Y%m%d).sql.gz
```