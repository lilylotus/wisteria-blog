#!/bin/bash

mkdir -p ./rabbitmq/{data,logs,plugins,conf}

chown -R 999:999 ./rabbitmq

# 生成随机 cookie
echo "my_secret_cookie_$(openssl rand -hex 12)" > rabbitmq/data/.erlang.cookie

# 设置严格的权限
chmod 600 rabbitmq/data/.erlang.cookie
chown 999:999 rabbitmq/data/.erlang.cookie

