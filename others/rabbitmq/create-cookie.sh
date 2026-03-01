# 创建目录
mkdir -p rabbitmq/data

# 生成随机 cookie
echo "my_secret_cookie_$(openssl rand -hex 12)" > rabbitmq/data/.erlang.cookie

# 设置严格的权限
chmod 600 rabbitmq/data/.erlang.cookie
sudo chown 999:999 rabbitmq/data/.erlang.cookie
