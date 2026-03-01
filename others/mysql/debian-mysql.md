
## Debian 12 安装 MySQL 

```bash
apt-get install -y libncurses5 libaio1 libnuma1 libtinfo6 libncurses6

# deb 安装依赖
apt-get install -y libcommon-sense-perl libjson-perl libjson-xs-perl libmecab2 libtypes-serialiser-perl mecab-ipadic mecab-ipadic-utf8 mecab-utils psmisc
# deb 安装
dpkg -i *.deb
apt --fix-broken install -y
```

```bash
sudo groupadd mysql
sudo useradd -r -g mysql -s /bin/false mysql
# 数据目录
sudo mkdir -p /var/lib/mysql /var/log/mysql /var/run/mysqld
sudo chown -R mysql:mysql /usr/local/mysql /var/lib/mysql /var/log/mysql /var/run/mysqld
```

删除

```bash
systemctl stop mysql && systemctl disable mysql
rm -rf /lib/systemd/system/mysql.service
rm -rf /etc/mysql /var/lib/mysql /var/log/mysql /var/run/mysqld /usr/local/mysql/
```

```bash
mkdir -p /etc/mysql/{conf.d,mysql.conf.d}

cat <<EOF > /etc/mysql/my.cnf
[client]
default-character-set = utf8mb4
socket = /var/run/mysqld/mysqld.sock

[mysql]
default-character-set = utf8mb4

[mysqld]
port = 3306
lower-case-table-names = 0
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci
init-connect = 'SET NAMES utf8mb4'

default-time-zone = '+08:00'
explicit-defaults-for-timestamp = true

pid-file  = /var/run/mysqld/mysqld.pid
socket    = /var/run/mysqld/mysqld.sock
datadir   = /var/lib/mysql
log-error = /var/log/mysql/error.log

!includedir /etc/mysql/conf.d/
!includedir /etc/mysql/mysql.conf.d/
EOF

```

初始化数据库：

```bash
cd /usr/local/mysql
sudo bin/mysqld --initialize --user=mysql
```

创建 MySQL service 服务

```bash
cat <<EOF > /lib/systemd/system/mysql.service
[Unit]
Description=MySQL Community Server
Documentation=man:mysqld(8)
Documentation=http://dev.mysql.com/doc/refman/en/using-systemd.html
After=network-online.target
Wants=network-online.target

[Install]
WantedBy=multi-user.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld
TimeoutSec=0
LimitNOFILE = 65535
Restart=on-failure
RestartPreventExitStatus=1

# Always restart when mysqld exits with exit code of 16. This special exit code
# is used by mysqld for RESTART SQL.
RestartForceExitStatus=16

# Set enviroment variable MYSQLD_PARENT_PID. This is required for restart.
Environment=MYSQLD_PARENT_PID=1
EOF
```

```bash
systemctl daemon-reload
systemctl start mysql
systemctl enable mysql
```

修复 root 初始化密码

```bash
ALTER USER 'root'@'localhost' IDENTIFIED BY 'mysql';
FLUSH PRIVILEGES;

CREATE USER 'mysql'@'%' IDENTIFIED BY 'mysql';
GRANT ALL PRIVILEGES ON *.* TO 'mysql'@'%';
FLUSH PRIVILEGES;

create database test default character set utf8mb4;
```

