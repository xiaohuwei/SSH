#!/bin/bash

# 设置MongoDB版本和安装信息
MONGO_VERSION="4.0.27"
MONGO_REPO_FILE="/etc/yum.repos.d/mongodb-org-4.0.repo"
LOCAL_IP=$(hostname -I | awk '{print $1}')
RANDOM_PASSWORD=$(openssl rand -base64 12 | tr -dc 'A-Za-z0-9')

# 创建MongoDB的YUM仓库文件
echo "正在配置 MongoDB YUM 仓库..."
cat > "$MONGO_REPO_FILE" <<EOF
[mongodb-org-4.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/4.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-4.0.asc
EOF

# 更新YUM缓存并安装指定版本的MongoDB
echo "正在更新 YUM 缓存并安装 MongoDB $MONGO_VERSION..."
yum clean all
yum makecache
yum install -y mongodb-org-$MONGO_VERSION mongodb-org-server-$MONGO_VERSION mongodb-org-shell-$MONGO_VERSION mongodb-org-mongos-$MONGO_VERSION mongodb-org-tools-$MONGO_VERSION

# 检查MongoDB是否安装成功
if ! command -v mongod &> /dev/null; then
    echo "MongoDB 安装失败"
    exit 1
fi

# 配置 MongoDB 仅监听本地局域网地址
echo "正在配置 MongoDB 仅监听本机局域网地址..."
MONGO_CONF_FILE="/etc/mongod.conf"
if [ -f "$MONGO_CONF_FILE" ]; then
    sed -i "s/^  bindIp: .*/  bindIp: 127.0.0.1,$LOCAL_IP/" "$MONGO_CONF_FILE"
    # 启用认证
    sed -i "/^#security:/a\security:\n  authorization: enabled" "$MONGO_CONF_FILE"
else
    echo "MongoDB 配置文件 $MONGO_CONF_FILE 不存在，可能安装未成功"
    exit 1
fi

# 启动并启用MongoDB服务
echo "正在启动 MongoDB 服务并设置开机自启动..."
systemctl enable mongod
systemctl restart mongod

# 检查MongoDB服务状态
if systemctl is-active --quiet mongod; then
    echo "MongoDB 服务已成功启动"
else
    echo "MongoDB 服务启动失败"
    exit 1
fi

# 暂停几秒等待 MongoDB 服务完全启动
sleep 5

# 创建MongoDB管理员用户并设置随机密码
echo "正在创建MongoDB管理员用户..."
mongo admin --eval "db.createUser({user: 'admin', pwd: '$RANDOM_PASSWORD', roles:[{role: 'root', db: 'admin'}]})"

# 输出最终安装信息
echo
echo "MongoDB 安装和配置完成！"
echo "MongoDB 版本: $MONGO_VERSION"
echo "MongoDB 监听地址: $LOCAL_IP:27017"
echo "MongoDB 管理员用户名: admin"
echo "MongoDB 管理员随机生成的密码: $RANDOM_PASSWORD"
echo
echo "请妥善保管管理员密码。您可以使用以下命令登录 MongoDB："
echo "mongo --host $LOCAL_IP -u admin -p '$RANDOM_PASSWORD' --authenticationDatabase 'admin'"
