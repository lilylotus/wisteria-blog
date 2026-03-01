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

#### SSL 自签证书生成

```bash
#!/bin/bash

BASE_DIR=ssl
SERVER_DOMAIN=*.labs.yzx

rm -rf ${BASE_DIR} ; mkdir -p ${BASE_DIR} ; cd ${BASE_DIR}

# create root CA
openssl genrsa -out ca.key 4096

cat <<EOF > v3_ca
[v3_ca]
basicConstraints=CA:FALSE
keyUsage=critical,keyCertSign,cRLSign
EOF

# /C=US/ST=California/L=San Francisco/O=My Root CA/CN=My Root CA
# C=国家/ST=地区或省份/L=地区局部名/O=机构名称/OU=组织单位名称/CN=网站域名/emailAddress=邮箱
openssl req -x509 -new -nodes -sha512 -days 3650 \
 -subj "/C=CN/ST=Shanghai/L=Shanghai/O=Self/OU=Self/CN=Ssl Self Sign Root CA" \
 -extensions v3_ca \
 -key ca.key \
 -out ca.pem

openssl x509 -outform der -in ca.pem -out ca.crt

# domain cert
cat <<EOF > server_ext_file 
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage=digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName=@alt_names

[alt_names]
DNS.1=${SERVER_DOMAIN}
EOF

openssl genrsa -out server.key 4096

openssl req -sha512 -new -nodes \
    -subj "/C=CN/ST=Shanghai/L=Shanghai/O=SelfServer/OU=SelfServer/CN=${SERVER_DOMAIN}" \
    -key server.key \
    -out server.csr

openssl x509 -req -sha512 -days 3650 \
    -extfile server_ext_file \
    -CA ca.pem -CAkey ca.key -CAcreateserial \
    -in server.csr \
    -out server.crt

openssl pkcs12 -export -clcerts -out server.p12 -inkey server.key -in server.crt

openssl x509 -inform PEM -in server.crt -out server.pem

# 需要导入 ca.crt / server.crt 到 “受信任的根证书颁发机构”
```

