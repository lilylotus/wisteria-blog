---
title: "caddy安装和简单配置说明"
subtitle: "caddy安装|caddy简单配置说明"
description: "caddy安装|caddy简单使用"
date: 2025-01-20T22:36:09+08:00
lastmod: 2025-01-20T22:36:09+08:00
draft: false

authors: ["yzx"]
tags: ["caddy","中间件"]
categories: ["caddy","中间件"]
series: []

featuredImage: "https://www.nihility.cn/files/images/IMG_1428.JPG"
featuredImagePreview: ""

lightgallery: true
math:
  enable: true
---

# caddy

caddy 官网霸气概述：[终极服务]使您的网站比任何其他解决方案都更安全、更可靠、更具可扩展性。

## 相关参考链接

[caddyserver 官网链接](https://caddyserver.com/)

[caddyserver 安装参考文档链接](https://caddyserver.com/docs/install)

## 安装

[Ubuntu](https://caddyserver.com/docs/install#debian-ubuntu-raspbian) 可以试着通过命令安装包一键安装， centos7 通过静态二进制包方式安装。

### centos 安装

[caddy 静态二进制文件安装参考文档](https://caddyserver.com/docs/install#static-binaries)

[caddy 二进制包下载链接](https://github.com/caddyserver/caddy/releases/download/v2.9.1/caddy_2.9.1_linux_amd64.tar.gz)

解压安装包并安装

```bash
tar -zxf caddy_2.9.1_linux_amd64.tar.gz
mv caddy /usr/local/bin/
```

查看安装版本

```bash
caddy -v
```

> v2.9.1 h1:OEYiZ7DbCzAWVb6TNEkjRcSCRGHVoZsJinoDR/n9oaY=

添加 caddy 系统用户组和用户

```bash
groupadd --system caddy

useradd --system \
    --gid caddy \
    --create-home \
    --home-dir /var/lib/caddy \
    --shell /usr/sbin/nologin \
    --comment "Caddy web server" \
    caddy
```

配置 systemed 服务，[`caddy.service` 服务配置文件](https://github.com/caddyserver/dist/blob/master/init/caddy.service) 在 `/usr/lib/systemd/system/caddy.service`

```
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target network-online.target
Requires=network-online.target

[Service]
Type=notify
User=caddy
Group=caddy
ExecStart=/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
ExecReload=/usr/bin/caddy reload --config /etc/caddy/Caddyfile --force
TimeoutStopSec=5s
LimitNOFILE=1048576
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
```

加载 `caddy.service`

```bash
sudo systemctl daemon-reload
#  开机自启
sudo systemctl enable --now caddy
```

验证 caddy 服务运行状态

```bash
systemctl status caddy
```

### caddy配置文件

默认 caddy 启动配置文件 `/etc/caddy/Caddy`  [初始化默认配置](https://github.com/caddyserver/dist/blob/master/config/Caddyfile)

```bash
mkdir -p /etc/caddy
touch /etc/caddy/Caddy
```

```properties
# The Caddyfile is an easy way to configure your Caddy web server.
#
# Unless the file starts with a global options block, the first
# uncommented line is always the address of your site.
#
# To use your own domain name (with automatic HTTPS), first make
# sure your domain's A/AAAA DNS records are properly pointed to
# this machine's public IP, then replace ":80" below with your
# domain name.

:80 {
	# Set this path to your site's directory.
	root * /usr/share/caddy

	# Enable the static file server.
	file_server

	# Another common task is to set up a reverse proxy:
	# reverse_proxy localhost:8080

	# Or serve a PHP site through php-fpm:
	# php_fastcgi localhost:9000
}

# Refer to the Caddy docs for more information:
# https://caddyserver.com/docs/caddyfile
```

```properties
example.com www.example.com {

  root * /var/www/html
  
  file_server
  encode zstd gzip
  header {
    ?Cache-Control "max-age=1800"
  }
  log {
    output file /var/lib/caddy/access_log.log
  }
  
  handle /files/* {
    uri strip_prefix /files
    root /data/images
    header {
      ?Cache-Control "max-age=1800"
    }
    encode /* {
      gzip
      zstd
      match {
         header Content-Type text/*
         header Content-Type image/*
      }
    }
  }
}

proxy.nihility.cn {

  reverse_proxy /* http://api.example.com

  file_server
  encode zstd gzip
  header {
    ?Cache-Control "max-age=1800"
  }
  log {
    output file /var/lib/caddy/api_access_log.log
  }

}
```

