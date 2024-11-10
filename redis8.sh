#!/bin/bash

# 设置 Redis 的本地监听 IP 和随机生成的密码
LOCAL_IP=$(hostname -I | awk '{print $1}')
REDIS_PASSWORD=$(openssl rand -base64 12)

# 安装 EPEL 和 Remi 仓库
echo "正在安装 EPEL 和 Remi 仓库..."
yum install -y epel-release yum-utils
yum-config-manager --enable epel
yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
yum-config-manager --enable remi

# 安装 Redis
echo "正在安装 Redis ..."
yum --enablerepo=remi install -y redis

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
    sed -i "s/^bind .*/bind 127.0.0.1 $LOCAL_IP/" "$REDIS_CONF_FILE"
    sed -i "s/^# requirepass .*/requirepass $REDIS_PASSWORD/" "$REDIS_CONF_FILE"
    sed -i "s/^protected-mode .*/protected-mode yes/" "$REDIS_CONF_FILE"
else
    echo "Redis 配置文件 $REDIS_CONF_FILE 不存在，可能安装未成功"
    exit 1
fi

# 修改 systemd 服务文件，确保 Redis 使用配置文件启动
echo "正在配置 Redis 服务文件..."
REDIS_SERVICE_FILE="/usr/lib/systemd/system/redis.service"
if [ -f "$REDIS_SERVICE_FILE" ]; then
    sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/redis-server /etc/redis.conf|" "$REDIS_SERVICE_FILE"
else
    echo "Redis 服务文件 $REDIS_SERVICE_FILE 不存在，可能安装未成功"
    exit 1
fi

# 重新加载 systemd 配置并重启 Redis 服务
echo "正在启动 Redis 服务并设置开机自启动..."
systemctl daemon-reload
systemctl enable redis
systemctl restart redis

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
