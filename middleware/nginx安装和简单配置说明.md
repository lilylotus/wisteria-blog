---
title: "nginx安装和简单配置说明"
subtitle: "nginx安装|nginx简单配置说明"
description: "nginx安装|nginx简单使用"
date: 2025-01-13T22:36:09+08:00
lastmod: 2025-01-13T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["nginx","中间件"]
categories: ["nginx","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1661.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# nginx

## nginx 有关参考文档 

[nginx 下载链接](https://nginx.org/en/download.html)

[nginx 稳定版本 github 链接](https://github.com/nginx/nginx/tags)

[nginx 源码安装 make 配置参数](https://nginx.org/en/docs/configure.html)

[nginx 核心模块配置参数参考文档](https://nginx.org/en/docs/http/ngx_http_core_module.html)

## nginx 源码安装

**注意：**  本次安装测试环境为 Centos7.9

### 源码下载

```bash
wget https://nginx.org/download/nginx-1.26.2.tar.gz
```

### 安装所需依赖

```bash
yum install -y gcc gcc-c++ make pcre-devel pcre2-devel zlib-devel openssl-devel
```

### 源码编译

nginx 源码安装配置：[nginx 源码安装配置参数参考文档](https://nginx.org/en/docs/configure.html)

#### 隐藏版本号

修改文件 `src/http/ngx_http_header_filter_module.c`   大概 49-51 行：

```cpp
static u_char ngx_http_server_string[] = "Server: nginx" CRLF;
static u_char ngx_http_server_full_string[] = "Server: " NGINX_VER CRLF;
static u_char ngx_http_server_build_string[] = "Server: " NGINX_VER_BUILD CRLF;
```

改为自定义服务和版本：

```cpp
static u_char ngx_http_server_string[] = "Server: nginx" CRLF;
static u_char ngx_http_server_full_string[] = "Server: nginx/x.x.x" CRLF;
static u_char ngx_http_server_build_string[] = "Server: nginx/x.x.x" CRLF;
```

在修改文件 `src/core/nginx.h`  大概 ：

```cpp
#define nginx_version      1026002
#define NGINX_VERSION      "1.26.2"
#define NGINX_VER          "nginx/" NGINX_VERSION

#define NGINX_VAR          "NGINX"
```

改为自定义版本：

```cpp
#define nginx_version      1234567
#define NGINX_VERSION      "x.x.x"
#define NGINX_VER          "nginx/" NGINX_VERSION

#define NGINX_VAR          "NGINX"
```

#### 编辑配置文件生成

nginx 功能类参数：

|                             参数 | 说明                                             |
| -------------------------------: | :----------------------------------------------- |
|                  `--prefix=path` | 默认是 /usr/local/nginx                          |
|         `--with-http_ssl_module` | SSL 支持                                         |
|          `--with-http_v2_module` | HTTP2 支持                                       |
|      `--with-http_realip_module` | Nginx 反向代理时，该模块可让 Nginx 知晓真正的 IP |
|      `--with-http_gunzip_module` | 对不支持 gzip 编码的客户端解压缩响应。           |
| `--with-http_gzip_static_module` | gzip 静态资源                                    |

nginx 编译需先配置生成 Makefile 文件，有关配置参数：

```bash
tar -zxf nginx-1.26.2.tar.gz
cd nginx-1.26.2

./configure \
  --with-stream \
  --with-pcre \
  --with-http_ssl_module \
  --with-http_v2_module \
  --with-http_realip_module \
  --with-http_gzip_static_module \
  --with-stream_ssl_module \
  --with-stream_realip_module \
  --with-stream_realip_module \
  --with-http_stub_status_module
  
```

#### nginx 编译安装

默认会把 nginx 安装到 `/usr/local/nginx`  目录

```bash
# 编译
make
# 安装
make install
```

### 常用命令

```bash
nginx -s signal
```

singal 信号参数如下：

- `stop` ：快速关闭
- `quit` ：优雅关闭
- `reload` ：重新加载配置，默认 `/usr/local/nginx/conf/nginx.conf`
- `reopen` ：重新打开日志文件

### 简单启动校验

**注意：**  默认 nginx 配置文件路径 `/usr/local/nginx/conf/nginx.conf`

启动 nginx ：

```bash
/usr/local/nginx/sbin/nginx
```

测试访问：

```
curl -I http://10.10.10.90/
```

> HTTP/1.1 200 OK
> Server: **nginx/x.x.x**
> Date: Mon, 13 Jan 2025 16:31:05 GMT
> Content-Type: text/html
> Content-Length: 615
> Last-Modified: Mon, 13 Jan 2025 16:26:05 GMT
> Connection: keep-alive
> ETag: "67853e9d-267"
> Accept-Ranges: bytes

### systemed 服务

nginx systemed 服务配置：`/usr/lib/systemd/system/nginx.service`

默认 nginx 配置文件：`/usr/local/nginx/conf/nginx.conf`

```properties
[Unit]
Description=Nginx HTTP Server
After=network.target
Wants=network.target

[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
Restart=on-failure
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

重新加载 nginx.service 服务配置：

```bash
systemctl daemon-reload
```

nginx 服务管理：

```bash
systemctl status nginx
systemctl start nginx
```

## nginx 配置文件

### 在线配置生成链接

[nginx 配置文件自动生成配置链接](https://www.digitalocean.com/community/tools/nginx?global.app.lang=zhCN)

[nginx 配置文件自动生成配置链接1](https://www.serverion.com/nginx-config/)

[nginx 配置文件自动生成配置链接2](https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=intermediate&openssl=3.4.0&guideline=5.7)

### 默认基础配置

```properties
#user  nobody;
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }  
    }
    
    include  /usr/local/nginx/conf/conf.d/*.conf;
}
```



### 指定 nginx 用户

创建 nginx 工作线程系统用户：

```bash
useradd -s /sbin/nologin -r nginx
```

nginx 配置：

```properties
user  nginx;
```

### https/ssl配置

默认配置：

```properties
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name example.com;

    # logging
    access_log  /var/log/nginx/access.log combined buffer=512k flush=1m;
    error_log   /var/log/nginx/error.log warn;

    # gzip
    gzip on;
    gzip_vary on;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types text/plain text/css text/xml application/json application/javascript;

    # SSL
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;
    ssl_session_tickets off;

    # Mozilla Intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;

    # SSL
    ssl_certificate /usr/local/nginx/ssl/ssl/server.pem;
    ssl_certificate_key /usr/local/nginx/ssl/ssl/server.key;

    location / {
        root   html;
        index  index.html index.htm;
    }
}

# HTTP redirect
server {
    listen      80;
    listen      [::]:80;
    server_name .labs.com;

    location / {
        return 301 https://ssl.labs.com$request_uri;
    }
}
```

#### SSL 自签证书脚本

自签生成服务端、客户端证书

```bash
#!/bin/bash
# ========================================
# 自签HTTPS证书生成脚本 (服务端证书 + 客户端证书，支持mTLS双向认证)
#
# 原理: 自建一个本地CA，用这个CA分别签发:
#   1. 服务端证书 -> 配置到Nginx/Web服务器，浏览器访问时验证服务端身份
#   2. 客户端证书 -> 导入浏览器个人证书库，服务端验证客户端身份(双向认证)
#   浏览器只需信任这一个CA根证书，之后CA签发的服务端证书就不会有警告；
#   如果服务端开启了mTLS强制校验客户端证书，浏览器还需导入客户端证书
#   才能正常访问(访问时浏览器会弹窗要求选择用哪个客户端证书)。
#
# 用法: ./make-cert.sh <域名或IP> [域名或IP2] ...
# 示例: ./make-cert.sh example.local 10.4.100.123 127.0.0.1
# ========================================
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
echo "Script directory: [$SCRIPT_DIR]"
cd ${SCRIPT_DIR}

if [ $# -eq 0 ]; then
    echo "用法: $0 <域名或IP> [域名或IP2] ..."
    echo "示例: $0 example.local 10.4.100.123 127.0.0.1"
    exit 1
fi

WORK_DIR=./certs

rm -rf ${WORK_DIR} ; mkdir -p ${WORK_DIR}/{ca,server,client}

CA_KEY="$WORK_DIR/ca/ca.key"
CA_CRT="$WORK_DIR/ca/ca.crt"
# /C=US/ST=California/L=San Francisco/O=My Root CA/CN=My Root CA
# C=国家/ST=地区或省份/L=地区局部名/O=机构名称/OU=组织单位名称/CN=网站域名/emailAddress=邮箱
CA_SUBJECT="/C=CN/ST=Shanghai/L=Shanghai/O=Local Dev CA/OU=Sign/CN=Local Development Root CA"

SERVER_KEY="$WORK_DIR/server/server.key"
SERVER_CSR="$WORK_DIR/server/server.csr"
SERVER_CRT="$WORK_DIR/server/server.crt"
SERVER_EXT="$WORK_DIR/server/server.ext"

CLIENT_KEY="$WORK_DIR/client/client.key"
CLIENT_CSR="$WORK_DIR/client/client.csr"
CLIENT_CRT="$WORK_DIR/client/client.crt"
CLIENT_EXT="$WORK_DIR/client/client.ext"
CLIENT_P12="$WORK_DIR/client/client.p12"

CLIENT_P12_PASSWORD="123456"   # 客户端p12证书导入密码，可自行修改

DAYS_CA=3650      # CA证书有效期10年
DAYS_SERVER=825   # 服务器证书有效期约2年(苹果/Chrome对自签证书有效期上限限制)
DAYS_CLIENT=825   # 客户端证书有效期

echo "========================================"
echo "步骤1: 检查/生成本地根CA"
echo "========================================"
if [ -f "$CA_KEY" ] && [ -f "$CA_CRT" ]; then
    echo "[提示] 检测到已有CA，复用现有CA(如需重新生成CA请先删除 $WORK_DIR 目录)"
else
    echo "生成CA私钥..."
    openssl genrsa -out "$CA_KEY" 4096

    echo "生成CA自签根证书..."
    openssl req -x509 -new -nodes \
        -key "$CA_KEY" \
        -sha256 \
        -days "$DAYS_CA" \
        -subj "$CA_SUBJECT" \
        -out "$CA_CRT"

    echo "[OK] CA根证书生成完成: $CA_CRT"
fi

echo ""
echo "========================================"
echo "步骤2: 解析传入参数，区分域名和IP"
echo "========================================"

SAN_ENTRIES=""
DNS_INDEX=1
IP_INDEX=1
FIRST_NAME="$1"   # 第一个参数作为证书CN和文件命名依据

is_ip() {
    local input="$1"
    if [[ "$input" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    if [[ "$input" =~ : ]]; then
        return 0
    fi
    return 1
}

for ARG in "$@"; do
    if is_ip "$ARG"; then
        SAN_ENTRIES="${SAN_ENTRIES}IP.${IP_INDEX} = ${ARG}\n"
        IP_INDEX=$((IP_INDEX + 1))
        echo "  识别为IP:   $ARG"
    else
        SAN_ENTRIES="${SAN_ENTRIES}DNS.${DNS_INDEX} = ${ARG}\n"
        DNS_INDEX=$((DNS_INDEX + 1))
        echo "  识别为域名: $ARG"
    fi
done

echo ""
echo "========================================"
echo "步骤3: 生成服务端私钥、CSR、证书"
echo "========================================"

openssl genrsa -out "$SERVER_KEY" 2048

openssl req -new \
    -key "$SERVER_KEY" \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Local Dev/OU=Sign/CN=${FIRST_NAME}" \
    -out "$SERVER_CSR"

cat > "$SERVER_EXT" << EOF
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
$(echo -e "$SAN_ENTRIES")
EOF

openssl x509 -req \
    -in "$SERVER_CSR" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$SERVER_CRT" \
    -days "$DAYS_SERVER" \
    -sha256 \
    -extfile "$SERVER_EXT"

echo "[OK] 服务端证书签发完成: $SERVER_CRT"

echo ""
echo "========================================"
echo "步骤4: 生成客户端私钥、CSR、证书(用于mTLS双向认证)"
echo "========================================"

openssl genrsa -out "$CLIENT_KEY" 2048

openssl req -new \
    -key "$CLIENT_KEY" \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Local Dev Client/OU=Sign/CN=${FIRST_NAME}-client" \
    -out "$CLIENT_CSR"

# 客户端证书的关键区别: extendedKeyUsage 是 clientAuth 而不是 serverAuth
cat > "$CLIENT_EXT" << EOF
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
EOF

openssl x509 -req \
    -in "$CLIENT_CSR" \
    -CA "$CA_CRT" \
    -CAkey "$CA_KEY" \
    -CAcreateserial \
    -out "$CLIENT_CRT" \
    -days "$DAYS_CLIENT" \
    -sha256 \
    -extfile "$CLIENT_EXT"

echo "[OK] 客户端证书签发完成: $CLIENT_CRT"

echo ""
echo "========================================"
echo "步骤5: 把客户端证书打包成 .p12 (浏览器只能导入p12/pfx格式的客户端证书)"
echo "========================================"

openssl pkcs12 -export \
    -inkey "$CLIENT_KEY" \
    -in "$CLIENT_CRT" \
    -certfile "$CA_CRT" \
    -out "$CLIENT_P12" \
    -passout "pass:${CLIENT_P12_PASSWORD}"

echo "[OK] 客户端p12证书生成完成: $CLIENT_P12 (导入密码: ${CLIENT_P12_PASSWORD})"

echo ""
echo "========================================"
echo "生成完成，文件清单"
echo "========================================"
echo "CA根证书(需要导入到浏览器/系统信任列表，用于信任服务端证书):"
echo "  $CA_CRT"
echo ""
echo "服务端证书和私钥(配置到Nginx/Web服务器):"
echo "  证书: $SERVER_CRT"
echo "  私钥: $SERVER_KEY"
echo ""
echo "客户端证书(仅当服务端开启mTLS强制双向认证时才需要):"
echo "  p12证书(导入浏览器用): $CLIENT_P12  (密码: ${CLIENT_P12_PASSWORD})"
echo "  原始证书: $CLIENT_CRT"
echo "  原始私钥: $CLIENT_KEY"

echo ""
echo "========================================"
echo "下一步1: 让浏览器信任CA(这一步必做，否则服务端证书依然会有警告)"
echo "========================================"
echo ""
echo "【macOS】"
echo "  sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $CA_CRT"
echo ""
echo "【Windows(用管理员PowerShell)】"
echo "  Import-Certificate -FilePath \"$CA_CRT\" -CertStoreLocation Cert:\\LocalMachine\\Root"
echo ""
echo "【Linux (Ubuntu/Debian)】"
echo "  sudo cp $CA_CRT /usr/local/share/ca-certificates/local-dev-ca.crt"
echo "  sudo update-ca-certificates"
echo ""
echo "【Linux (CentOS/RHEL)】"
echo "  sudo cp $CA_CRT /etc/pki/ca-trust/source/anchors/local-dev-ca.crt"
echo "  sudo update-ca-trust"
echo ""
echo "【Firefox(独立证书库，需单独导入)】"
echo "  设置 → 隐私与安全 → 证书 → 查看证书 → 颁发机构 → 导入 → 选择 $CA_CRT → 勾选信任用于识别网站"
echo ""
echo "========================================"
echo "下一步2(可选，仅mTLS场景需要): 把客户端证书导入浏览器个人证书库"
echo "========================================"
echo ""
echo "【macOS】双击 $CLIENT_P12，用钥匙串访问App导入，输入密码: ${CLIENT_P12_PASSWORD}"
echo ""
echo "【Windows】双击 $CLIENT_P12，走证书导入向导，输入密码: ${CLIENT_P12_PASSWORD}"
echo "          存储位置选择\"个人\"证书存储"
echo ""
echo "【Chrome/Edge(Windows/Linux)】"
echo "  设置 → 隐私设置和安全性 → 安全 → 管理证书 → 您的证书 → 导入 → 选择 $CLIENT_P12"
echo ""
echo "【Firefox】"
echo "  设置 → 隐私与安全 → 证书 → 查看证书 → 您的证书 → 导入 → 选择 $CLIENT_P12"
echo ""
echo "导入完成后重启浏览器。如果服务端开启了mTLS强制校验，访问时浏览器会"
echo "弹窗要求选择使用哪个客户端证书，选择刚导入的这个即可。"
echo "========================================"

```

