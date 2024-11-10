#!/bin/bash

# 设置 Redis 版本
REDIS_VERSION="6"
LOCAL_IP=$(hostname -I | awk '{print $1}')
REDIS_PASSWORD=$(openssl rand -base64 12)

# 配置 Redis YUM 仓库
echo "正在配置 Redis YUM 仓库..."
yum install -y yum-utils
yum-config-manager --add-repo http://download.redis.io/releases/redis.repo

# 安装指定版本的 Redis
echo "正在安装 Redis $REDIS_VERSION ..."
yum install -y redis

# 检查 Redis 是否安装成功
if ! command -v redis-server &> /dev/null; then
    echo "Redis 安装失败"
    exit 1
fi

# 修改 Redis 配置文件
echo "正在配置 Redis ..."
REDIS_CONF_FILE="/etc/redis.conf"
if [ -f "$REDIS_CONF_FILE" ]; then
    # 设置监听地址和密码
    sed -i "s/^bind .*/bind $LOCAL_IP/" "$REDIS_CONF_FILE"
    sed -i "s/^# requirepass .*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF_FILE"
    sed -i "s/^protected-mode .*/protected-mode yes/" "$REDIS_CONF_FILE"
else
    echo "Redis 配置文件 $REDIS_CONF_FILE 不存在，可能安装未成功"
    exit 1
fi

# 启动并启用 Redis 服务
echo "正在启动 Redis 服务并设置开机自启动..."
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
echo "Redis 监听地址: $LOCAL_IP:6379"
echo "Redis 密码: $REDIS_PASSWORD"
echo
echo "请妥善保管 Redis 密码。您可以使用以下命令连接 Redis："
echo "redis-cli -h $LOCAL_IP -p 6379 -a '$REDIS_PASSWORD'"
