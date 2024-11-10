#!/bin/bash

# 设置 Redis 版本和安装信息
REDIS_VERSION="6.2.12"
LOCAL_IP=$(hostname -I | awk '{print $1}')
REDIS_PASSWORD=$(openssl rand -base64 12)

# 更新YUM缓存并安装Redis
echo "正在安装 Redis $REDIS_VERSION ..."
yum install -y gcc tcl
curl -O http://download.redis.io/releases/redis-$REDIS_VERSION.tar.gz
tar xzf redis-$REDIS_VERSION.tar.gz
cd redis-$REDIS_VERSION
make && make install

# 检查 Redis 是否安装成功
if ! command -v redis-server &> /dev/null; then
    echo "Redis 安装失败"
    exit 1
fi

# 创建 Redis 配置目录和配置文件
echo "正在配置 Redis ..."
REDIS_CONF_FILE="/etc/redis.conf"
mkdir -p /etc/redis
cp redis.conf "$REDIS_CONF_FILE"

# 修改配置文件：设置监听IP和密码
sed -i "s/^bind .*/bind $LOCAL_IP/" "$REDIS_CONF_FILE"
sed -i "s/^# requirepass .*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF_FILE"
sed -i "s/^protected-mode .*/protected-mode yes/" "$REDIS_CONF_FILE"
sed -i "s/^supervised .*/supervised systemd/" "$REDIS_CONF_FILE"

# 创建 Redis systemd 服务文件
REDIS_SERVICE_FILE="/etc/systemd/system/redis.service"
echo "正在配置 Redis 开机自启动服务..."

cat > "$REDIS_SERVICE_FILE" <<EOF
[Unit]
Description=Redis In-Memory Data Store
After=network.target

[Service]
ExecStart=/usr/local/bin/redis-server $REDIS_CONF_FILE
ExecStop=/usr/local/bin/redis-cli shutdown
Restart=always
User=root
Group=root

[Install]
WantedBy=multi-user.target
EOF

# 启动并启用 Redis 服务
echo "正在启动 Redis 服务并设置开机自启动..."
systemctl daemon-reload
systemctl enable redis
systemctl start redis

# 检查 Redis 服务状态
if systemctl is-active --quiet redis; then
    echo "Redis 服务已成功启动"
else
    echo "Redis 服务启动失败"
    exit 1
fi

# 输出最终安装信息
echo
echo "Redis 安装和配置完成！"
echo "Redis 版本: $REDIS_VERSION"
echo "Redis 监听地址: $LOCAL_IP:6379"
echo "Redis 密码: $REDIS_PASSWORD"
echo
echo "请妥善保管 Redis 密码。您可以使用以下命令连接 Redis："
echo "redis-cli -h $LOCAL_IP -p 6379 -a '$REDIS_PASSWORD'"
