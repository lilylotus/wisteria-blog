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

## nginx容器启动

### 部署脚本

```bash
#!/bin/bash

mkdir -p ./nginx/{conf.d,html}

echo '<h1>hello</h1>' > nginx/html/index.html

cat <<EOF > nginx/conf.d/default.conf
server {
    listen       80;
    server_name  localhost;

    location / {
        root   /usr/share/nginx/html;
        index  index.html index.htm;
    }

    error_page   500 502 503 504  /50x.html;
    location = /50x.html {
        root   /usr/share/nginx/html;
    }
}
EOF
```

### docker-compose.yaml

```yaml
networks:
  nginx-network:
    driver: bridge

volumes:
  nginx_log:

services:
  nginx:
    image: nginx:1.28
    container_name: nginx
    restart: unless-stopped
    ports:
      - "80:80"
    volumes:
      - ./nginx/conf.d:/etc/nginx/conf.d:ro
      - ./nginx/html:/usr/share/nginx/html
      - nginx_log:/var/log/nginx
    environment:
      - TZ=Asia/Shanghai
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

脚本用法

```bash
# 参数可重复使用
bash gen_nginx_certs.sh --domain example.com --ip 192.168.1.100
bash gen_nginx_certs.sh -d example.com -d www.example.com -i 192.168.1.100
bash gen_nginx_certs.sh -d "*.example.com" --no-client
```

`gen_nginx_certs.sh` openssl 自签脚本

```bash
#!/bin/bash
#
# gen_nginx_certs.sh - 自签 Nginx 证书生成脚本
# 功能：生成 CA、服务端证书（支持 IP 或域名）、客户端证书
# 特性：导入 CA 到浏览器信任后，不再报安全问题
#       每次签发的 CA 名称为 "Self-Signed CA + 随机字符串"，避免与已导入的旧 CA 重名
#
# 用法:
#   ./gen_nginx_certs.sh --domain example.com [--ip 192.168.1.100] [--client] [--no-ca-password]
#
# 依赖: openssl
#

set -euo pipefail
set -o errtrace   # 让 ERR trap 在函数内也生效

# 错误追踪：在退出时打印出错的函数和行号
trap 'log_error "脚本在 ${FUNCNAME:-main} 函数第 $LINENO 行出错（返回值 $?），请检查上方错误信息"' ERR

# ======================== 默认配置 ========================
CA_DAYS=3650          # CA 有效期（10年）
SERVER_DAYS=3650      # 服务端证书有效期（10年）
CLIENT_DAYS=3650      # 客户端证书有效期（10年）
KEY_SIZE=2048         # RSA 密钥长度
CA_PASSWORD=""        # CA 私钥密码（默认空，可选设置）
CA_NAME_PREFIX="Self-Signed CA"   # CA 名称前缀
CA_NAME=""            # 本次签发的 CA 名称（运行时生成：前缀 + 随机字符串）
OUTPUT_DIR="output"   # 输出目录

# SAN 配置
DOMAINS=()
IPS=()

# 是否生成客户端证书（默认生成）
GEN_CLIENT=true

# ======================== 函数定义 ========================
usage() {
    cat <<EOF
用法: $0 [选项]

选项:
  -d, --domain <域名>    服务端域名（可重复指定）
  -i, --ip <IP地址>      服务端 IP 地址（可重复指定）
  -c, --client           包含客户端证书（默认已包含）
      --no-client        跳过客户端证书生成
  -o, --output <目录>    输出目录（默认: $OUTPUT_DIR）
      --ca-password      设置 CA 私钥密码
      --no-ca-password   不设置 CA 私钥密码（默认）
  -h, --help             显示帮助

示例:
  $0 --domain example.com --ip 192.168.1.100
  $0 -d example.com -d www.example.com -i 192.168.1.100
  $0 -d "*.example.com" --no-client

注意：浏览器信任自签证书需手动导入 CA 证书（ca.crt）到"受信任的根证书颁发机构"。
EOF
    exit 0
}

log_info()  { echo -e "[INFO]  $*"; }
log_warn()  { echo -e "[WARN]  $*" >&2; }
log_error() { echo -e "[ERROR] $*" >&2; }

# 检测 openssl 是否可用
check_deps() {
    if ! command -v openssl &>/dev/null; then
        log_error "未找到 openssl，请先安装："
        log_error "  Ubuntu/Debian: apt install openssl"
        log_error "  CentOS/RHEL:   yum install openssl"
        log_error "  macOS:         brew install openssl"
        exit 1
    fi
}

# 生成本次签发使用的 CA 名称：Self-Signed CA + 随机字符串
gen_ca_name() {
    local suffix=""
    suffix=$(openssl rand -hex 4 2>/dev/null) || suffix=""
    if [ -z "$suffix" ]; then
        suffix=$(printf "%04x%04x" "$RANDOM" "$RANDOM")
    fi
    CA_NAME="$CA_NAME_PREFIX $suffix"
    log_info "本次 CA 名称: $CA_NAME"
}

gen_ca() {
    local ca_dir="$OUTPUT_DIR/ca"
    local ca_key="$ca_dir/ca.key"
    local ca_crt="$ca_dir/ca.crt"
    local ca_cnf="$ca_dir/ca.cnf"

    log_info "=== 生成 CA 根证书 ==="

    # 每次签发生成新的随机 CA 名称
    gen_ca_name

    mkdir -p "$ca_dir"

    # CA 配置文件
    cat > "$ca_cnf" <<CNF
[ req ]
prompt                  = no
distinguished_name      = req_distinguished_name
x509_extensions         = v3_ca

[ req_distinguished_name ]
countryName             = CN
stateOrProvinceName     = Beijing
localityName            = Beijing
organizationName        = ${CA_NAME}
organizationalUnitName  = Development
commonName              = ${CA_NAME}

[ v3_ca ]
basicConstraints        = critical, CA:TRUE
keyUsage                = critical, keyCertSign, cRLSign, digitalSignature
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer
nsComment               = "${CA_NAME} - DO NOT TRUST IN PRODUCTION"
CNF

    # 生成 CA 私钥和自签名证书
    openssl genrsa -out "$ca_key" "$KEY_SIZE"
    log_info "CA 私钥已生成: $ca_key"

    if [ -n "$CA_PASSWORD" ]; then
        openssl req -x509 -new -key "$ca_key" \
            -sha256 -days "$CA_DAYS" \
            -config "$ca_cnf" \
            -out "$ca_crt" \
            -passout "pass:$CA_PASSWORD"
    else
        openssl req -x509 -new -key "$ca_key" \
            -sha256 -days "$CA_DAYS" \
            -config "$ca_cnf" \
            -out "$ca_crt"
    fi
    log_info "CA 证书已生成: $ca_crt"

    # 显示指纹
    log_info "CA 证书指纹 (SHA256):"
    openssl x509 -in "$ca_crt" -fingerprint -sha256 -noout | cut -d= -f2
}

# 生成服务端证书
gen_server_cert() {
    local server_dir="$OUTPUT_DIR/server"
    local server_key="$server_dir/server.key"
    local server_csr="$server_dir/server.csr"
    local server_crt="$server_dir/server.crt"
    local server_cnf="$server_dir/server.cnf"
    local ca_crt="$OUTPUT_DIR/ca/ca.crt"
    local ca_key="$OUTPUT_DIR/ca/ca.key"

    log_info "=== 生成服务端证书 ==="

    mkdir -p "$server_dir"

    # 构建 SAN 列表
    local san_list=""
    local idx=0
    for d in "${DOMAINS[@]}"; do
        san_list+="DNS.$idx = $d"$'\n'
        idx=$((idx + 1))
    done
    for ip in "${IPS[@]}"; do
        san_list+="IP.$idx = $ip"$'\n'
        idx=$((idx + 1))
    done

    if [ -z "$san_list" ]; then
        log_error "请至少指定一个域名或 IP（使用 --domain 或 --ip）"
        exit 1
    fi

    # 服务端证书配置文件（带 SAN）
    cat > "$server_cnf" <<CNF
[ req ]
prompt                  = no
distinguished_name      = req_distinguished_name
req_extensions          = req_ext
x509_extensions         = server_ext

[ req_distinguished_name ]
countryName             = CN
stateOrProvinceName     = Beijing
localityName            = Beijing
organizationName        = Self-Signed Server
organizationalUnitName  = Development
commonName              = ${DOMAINS[0]:-${IPS[0]}}

[ req_ext ]
subjectAltName          = @san

[ server_ext ]
basicConstraints        = critical, CA:FALSE
keyUsage                = critical, digitalSignature, keyEncipherment
extendedKeyUsage        = serverAuth, clientAuth
subjectAltName          = @san
authorityKeyIdentifier  = keyid:always, issuer

[ san ]
${san_list}
CNF

    # 生成服务端私钥
    openssl genrsa -out "$server_key" "$KEY_SIZE"
    log_info "服务端私钥已生成: $server_key"

    # 生成 CSR
    openssl req -new -key "$server_key" \
        -config "$server_cnf" \
        -sha256 -out "$server_csr"
    log_info "服务端 CSR 已生成: $server_csr"

    # 使用 CA 签发服务端证书
    local ca_serial="$OUTPUT_DIR/ca/ca.srl"
    [ -f "$ca_serial" ] || echo "$(openssl rand -hex 16)" > "$ca_serial"

    if [ -n "$CA_PASSWORD" ]; then
        openssl x509 -req \
            -CA "$ca_crt" \
            -CAkey "$ca_key" \
            -CAserial "$ca_serial" \
            -extfile "$server_cnf" \
            -extensions server_ext \
            -days "$SERVER_DAYS" \
            -sha256 \
            -in "$server_csr" \
            -out "$server_crt" \
            -passin "pass:$CA_PASSWORD"
    else
        openssl x509 -req \
            -CA "$ca_crt" \
            -CAkey "$ca_key" \
            -CAserial "$ca_serial" \
            -extfile "$server_cnf" \
            -extensions server_ext \
            -days "$SERVER_DAYS" \
            -sha256 \
            -in "$server_csr" \
            -out "$server_crt"
    fi
    log_info "服务端证书已生成: $server_crt"

    # 生成全链证书（服务端证书 + CA 证书）
    cat "$server_crt" "$ca_crt" > "$server_dir/fullchain.crt"
    log_info "全链证书已生成: $server_dir/fullchain.crt"

    # 验证证书
    log_info "验证服务端证书..."
    openssl verify -CAfile "$ca_crt" "$server_crt" || log_warn "证书验证失败"
}

# 生成客户端证书
gen_client_cert() {
    local client_dir="$OUTPUT_DIR/client"
    local client_key="$client_dir/client.key"
    local client_csr="$client_dir/client.csr"
    local client_crt="$client_dir/client.crt"
    local client_pfx="$client_dir/client.pfx"
    local client_cnf="$client_dir/client.cnf"
    local ca_crt="$OUTPUT_DIR/ca/ca.crt"
    local ca_key="$OUTPUT_DIR/ca/ca.key"

    log_info "=== 生成客户端证书 ==="

    mkdir -p "$client_dir"

    # 客户端证书配置文件
    cat > "$client_cnf" <<'CNF'
[ req ]
prompt                  = no
distinguished_name      = req_distinguished_name
req_extensions          = req_ext

[ req_distinguished_name ]
countryName             = CN
stateOrProvinceName     = Beijing
localityName            = Beijing
organizationName        = Self-Signed Client
organizationalUnitName  = Development
commonName              = Client Certificate

[ req_ext ]
subjectAltName          = @san

[ san ]
DNS.0                   = client.local
CNF

    # 生成客户端私钥
    openssl genrsa -out "$client_key" "$KEY_SIZE"
    log_info "客户端私钥已生成: $client_key"

    # 生成 CSR
    openssl req -new -key "$client_key" \
        -config "$client_cnf" \
        -sha256 -out "$client_csr"
    log_info "客户端 CSR 已生成: $client_csr"

    # 使用 CA 签发客户端证书
    local ca_serial="$OUTPUT_DIR/ca/ca.srl"
    [ -f "$ca_serial" ] || echo "$(openssl rand -hex 16)" > "$ca_serial"

    if [ -n "$CA_PASSWORD" ]; then
        openssl x509 -req \
            -CA "$ca_crt" \
            -CAkey "$ca_key" \
            -CAserial "$ca_serial" \
            -days "$CLIENT_DAYS" \
            -sha256 \
            -in "$client_csr" \
            -out "$client_crt" \
            -passin "pass:$CA_PASSWORD"
    else
        openssl x509 -req \
            -CA "$ca_crt" \
            -CAkey "$ca_key" \
            -CAserial "$ca_serial" \
            -days "$CLIENT_DAYS" \
            -sha256 \
            -in "$client_csr" \
            -out "$client_crt"
    fi
    log_info "客户端证书已生成: $client_crt"

    # 生成 PKCS#12 格式（用于浏览器导入）
    local pfx_pass_args=(-passout pass:)
    openssl pkcs12 -export \
        -inkey "$client_key" \
        -in "$client_crt" \
        -certfile "$ca_crt" \
        -out "$client_pfx" \
        "${pfx_pass_args[@]}"
    log_info "客户端 PKCS#12 已生成: $client_pfx（无密码）"

    # 验证证书
    log_info "验证客户端证书..."
    openssl verify -CAfile "$ca_crt" "$client_crt" || log_warn "客户端证书验证失败"
}

# 生成 Nginx 配置示例
gen_nginx_example() {
    local nginx_conf="$OUTPUT_DIR/nginx-ssl-example.conf"
    local first_domain="${DOMAINS[0]:-}"
    local server_name="$first_domain"
    for d in "${DOMAINS[@]:1}"; do server_name+=" $d"; done
    for ip in "${IPS[@]}"; do server_name+=" $ip"; done

    cat > "$nginx_conf" <<CONF
# Nginx SSL 配置示例
# 请将此文件内容复制到你的 nginx 配置中

server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name ${server_name:-localhost};

    # 服务端证书（使用全链证书）
    ssl_certificate     $(pwd)/$OUTPUT_DIR/server/fullchain.crt;
    ssl_certificate_key $(pwd)/$OUTPUT_DIR/server/server.key;

    # 可选：客户端证书验证（双向 TLS）
    # ssl_client_certificate $(pwd)/$OUTPUT_DIR/ca/ca.crt;
    # ssl_verify_client on;
    # ssl_verify_depth 2;

    # SSL 安全配置
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # HSTS（建议开启）
    # add_header Strict-Transport-Security "max-age=63072000" always;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
CONF
    log_info "Nginx 配置示例已生成: $nginx_conf"
}

# 生成使用说明
gen_readme() {
    local readme="$OUTPUT_DIR/README.txt"

    cat > "$readme" <<TXT
============================================
  自签 Nginx SSL 证书 - 使用说明
============================================

本次签发的 CA 名称: ${CA_NAME}
（每次运行都会生成新的随机 CA 名称，导入浏览器时可据此区分）

证书文件说明:
├── ca/
│   ├── ca.crt          # CA 根证书（需导入浏览器信任）
│   └── ca.key          # CA 私钥（妥善保管）
├── server/
│   ├── server.key      # 服务端私钥
│   ├── server.crt      # 服务端证书
│   ├── fullchain.crt   # 全链证书（server.crt + ca.crt）
│   └── server.csr      # 证书签名请求（可忽略）
TXT

    if [ "$GEN_CLIENT" = true ]; then
        cat >> "$readme" <<'TXT'
├── client/
│   ├── client.key      # 客户端私钥
│   ├── client.crt      # 客户端证书
│   ├── client.csr      # 证书签名请求（可忽略）
│   └── client.pfx      # 客户端 PKCS#12（可导入浏览器/系统）
TXT
    fi

    cat >> "$readme" <<TXT
│
└── nginx-ssl-example.conf  # Nginx 配置示例

============================================
  浏览器信任 CA 证书（消除安全警告）
============================================

方法一（推荐）：自动安装（仅限当前系统用户）
  双击打开 ca.crt，选择"安装证书" -> "当前用户" -> "受信任的根证书颁发机构"

方法二：命令行安装（需管理员/root 权限）
  Windows:
    certutil -addstore Root ca/ca.crt

  macOS:
    sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain ca/ca.crt

  Linux (Ubuntu/Debian):
    sudo cp ca/ca.crt /usr/local/share/ca-certificates/self-signed-ca.crt
    sudo update-ca-certificates

  Linux (CentOS/RHEL):
    sudo cp ca/ca.crt /etc/pki/ca-trust/source/anchors/
    sudo update-ca-trust

============================================
  服务端配置
============================================
1. 将 server/fullchain.crt 和 server/server.key 配置到 Nginx
2. 参考 nginx-ssl-example.conf 中的配置
3. 重启 Nginx: nginx -s reload

============================================
  注意事项
============================================
- 此证书仅适用于开发/测试环境，请勿用于生产环境
- CA 私钥（ca.key）请妥善保管，泄露后他人可签发伪造证书
- 证书默认有效期 10 年，可通过脚本参数调整
- 若使用客户端证书，需在 Nginx 中配置 ssl_verify_client on
TXT
    log_info "使用说明已生成: $readme"
}

# 打印证书信息摘要
print_summary() {
    log_info ""
    log_info "============================================"
    log_info "  证书生成完成！"
    log_info "============================================"
    log_info ""
    log_info "输出目录: $(pwd)/$OUTPUT_DIR/"
    log_info ""
    log_info "CA 名称:       $CA_NAME"
    log_info "CA 证书:       $OUTPUT_DIR/ca/ca.crt"
    log_info "服务端证书:     $OUTPUT_DIR/server/fullchain.crt"
    log_info "服务端私钥:     $OUTPUT_DIR/server/server.key"
    log_info "Nginx 配置示例:  $OUTPUT_DIR/nginx-ssl-example.conf"
    if [ "$GEN_CLIENT" = true ]; then
        log_info "客户端证书:     $OUTPUT_DIR/client/client.crt"
        log_info "客户端 PKCS#12: $OUTPUT_DIR/client/client.pfx"
    fi
    log_info ""
    log_info "重要提示:"
    log_info "  将 ca/ca.crt 导入浏览器受信任根证书颁发机构后，"
    log_info "  浏览器将不再显示安全警告。"
    log_info ""

    log_info "CA 证书指纹 (SHA256):"
    openssl x509 -in "$OUTPUT_DIR/ca/ca.crt" -fingerprint -sha256 -noout | cut -d= -f2
}

# ======================== 主流程 ========================
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--domain)
                DOMAINS+=("$2")
                shift 2
                ;;
            -i|--ip)
                IPS+=("$2")
                shift 2
                ;;
            -c|--client)
                # 默认已包含客户端证书，此选项保留兼容
                shift
                ;;
            --no-client)
                GEN_CLIENT=false
                shift
                ;;
            -o|--output)
                OUTPUT_DIR="$2"
                shift 2
                ;;
            --ca-password)
                CA_PASSWORD="$2"
                shift 2
                ;;
            --no-ca-password)
                CA_PASSWORD=""
                shift
                ;;
            -h|--help)
                usage
                ;;
            *)
                log_error "未知选项: $1"
                usage
                ;;
        esac
    done

    # 检查依赖
    check_deps

    # 验证参数：至少需要一个域名或 IP
    if [ ${#DOMAINS[@]} -eq 0 ] && [ ${#IPS[@]} -eq 0 ]; then
        log_error "请至少指定一个域名或 IP 地址"
        log_error "  使用 --domain <域名> 或 --ip <IP地址>"
        usage
    fi

    # 清理并创建输出目录
    rm -rf "$OUTPUT_DIR"

    # 生成 CA
    gen_ca

    # 生成服务端证书
    gen_server_cert

    # 生成客户端证书（可选）
    if [ "$GEN_CLIENT" = true ]; then
        gen_client_cert
    fi

    # 生成 Nginx 配置示例
    gen_nginx_example

    # 生成使用说明
    gen_readme

    # 打印摘要
    print_summary
}

main "$@"



```

