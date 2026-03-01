## nginx 源码安装

[Nginx 下载地址](https://nginx.org/en/download.html)， [nginx v1.24.0 下载链接](https://nginx.org/download/nginx-1.24.0.tar.gz)，[nginx 源码编译配置文档](https://nginx.org/en/docs/configure.html)

注：安装环境为 Centos 7

- 下载 [nginx](https://nginx.org/) 源码，解压源码包

```bash
wget https://nginx.org/download/nginx-1.24.0.tar.gz
tar -zxf nginx-1.24.0.tar.gz
```

- 创建 nginx 运行账户

```bash
useradd -M -s /sbin/nologin nginx
```

- 安装编译依赖

  > gcc 编译时依赖 gcc 环境，pcre 提供 nginx 支持重写功能
  >
  > zlib 压缩 / 解压工具，openssl 安全套接字层密码库，通信加密

```bash
yum install -y gcc gcc-c++ automake make openssl openssl-devel pcre pcre-devel zlib zlib-devel
```

- 检查安装环境，编译，安装

```bash
# 进入 nginx 源码解压目录
cd nginx-1.24.0

# 检查安装环境
./configure --prefix=/usr/local/nginx --with-http_ssl_module --with-http_stub_status_module

# 编译 nginx 源码
make

# 安装
make install
```

参数说明：

| 参数                           | 说明                                            |
| ------------------------------ | ----------------------------------------------- |
| --prefix=*path*                | 定义保存服务文件目录，默认目录 /usr/local/nginx |
| --with-http_ssl_module         | 构建时添加 HTTPS 模块支持                       |
| --with-http_stub_status_module | 该模块提供 nginx 基本状态信息的访问             |

## 创建 nginx 服务

编辑 nginx systemd 服务配置 `/usr/lib/systemd/system/nginx.service`

```
[Unit]
Description=nginx - high performance web server
After=network.target

[Service]
Type=forking
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

注：默认 nginx 配置文件路径为 `prefix/conf/nginx.conf` ，这里就是 /usr/local/nginx/conf/nginx.conf

## nginx 简单配置

[nginx 配置生成网站](https://www.digitalocean.com/community/tools/nginx)

主配置文件 *config/nginx.conf*

```
#user  nobody;
worker_processes  1;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';


    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;
    gzip  on;

    server {
        listen       80;
        server_name  localhost;

        charset utf-8;

        access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page  404              /404.html;

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

}
```



## nginx 命令

默认配置文件名为 *nginx.conf*，放置在目录 */usr/local/nginx/conf*、*/etc/nginx* 或 */usr/local/etc/nginx* 中。

指定具体配置文件启动：

```bash
nginx -c /config/path/nginx.conf
```

启动、停止和重新加载配置。 nginx 启动后，可以通过使用 *-s* 参数调用可执行文件来控制。

```bash
nginx -s signal
```

singal （信号）参数列表：

- `stop` — 快速关闭 （fast shutdown）
- `quit` — 优雅的关闭（graceful shutdown）
- `reload` — 重新加载配置文件（reloading the configuration file）
- `reopen` — reopening the log files

示例：要停止 nginx 进程并等待工作进程完成当前请求的服务，可以执行以下命令：

```bash
nginx -s quit
```

> 该命令应在启动 nginx 的同一用户下执行

