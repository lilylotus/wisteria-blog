#!/bin/bash
set -e

# 设置 cookie 文件权限
if [ -f /var/lib/rabbitmq/.erlang.cookie ]; then
    chmod 600 /var/lib/rabbitmq/.erlang.cookie
    chown rabbitmq:rabbitmq /var/lib/rabbitmq/.erlang.cookie
fi

# 启动 RabbitMQ
exec docker-entrypoint.sh rabbitmq-server "$@"