#!/bin/bash

# 设置安装目录
NATS_HOME="/home/nats"
CONFIG_FILE="${NATS_HOME}/nats-server.conf"
LOCAL_IP=$(hostname -I | awk '{print $1}')

# 创建 NATS 安装目录
if [ ! -d "$NATS_HOME" ]; then
    echo "正在创建 NATS 安装目录: $NATS_HOME"
    mkdir -p "$NATS_HOME"
fi

# 确定系统架构，并选择对应的 NATS 服务器下载链接
ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    NATS_URL="https://github.com/nats-io/nats-server/releases/download/v2.10.20/nats-server-v2.10.20-linux-amd64.tar.gz"
elif [[ "$ARCH" == "aarch64" ]]; then
    NATS_URL="https://github.com/nats-io/nats-server/releases/download/v2.10.20/nats-server-v2.10.20-linux-arm64.tar.gz"
else
    echo "不支持的系统架构: $ARCH"
    exit 1
fi

# 下载并安装 NATS 服务器
echo "正在下载并安装 NATS 服务器到 $NATS_HOME ..."
curl -Lo /tmp/nats-server.tar.gz "$NATS_URL" || { echo "NATS 服务器下载失败"; exit 1; }
tar -xzvf /tmp/nats-server.tar.gz -C "$NATS_HOME" --strip-components=1 || { echo "NATS 服务器解压失败"; exit 1; }

# 检查 NATS 服务器文件是否存在
if [ ! -f "${NATS_HOME}/nats-server" ]; then
    echo "NATS 服务器安装失败"
    exit 1
fi

# 创建简化的 NATS 配置文件
echo "正在创建 NATS 配置文件..."
cat > "$CONFIG_FILE" <<EOF
net: $LOCAL_IP
port: 4222
max_payload: 3MB
EOF

# 创建 NATS systemd 服务文件
SERVICE_FILE="/etc/systemd/system/nats-server.service"
echo "正在配置 NATS 开机自启动服务..."

cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=NATS Server
After=network.target

[Service]
ExecStart=${NATS_HOME}/nats-server -c $CONFIG_FILE
Restart=on-failure
User=nats
Group=nats

[Install]
WantedBy=multi-user.target
EOF

# 创建 nats 用户
if ! id -u nats &>/dev/null; then
    useradd -r -s /bin/false nats
fi

# 设置文件权限
chown -R nats:nats "$NATS_HOME"

# 重新加载 systemd 服务并启动 NATS 服务
echo "正在启动 NATS 服务器并启用自启动..."
systemctl daemon-reload
systemctl enable nats-server
systemctl start nats-server

# 检查是否启动成功
if systemctl is-active --quiet nats-server; then
    echo "NATS 服务器启动成功！"
else
    echo "NATS 服务器启动失败"
    exit 1
fi

# 输出 NATS 进程ID、局域网地址和端口
PID=$(pgrep -f "${NATS_HOME}/nats-server")
echo "NATS 服务器进程ID: $PID"
echo "NATS 服务器监听地址: $LOCAL_IP:4222"
echo "输入下面的指令查看Nats状态"
echo "systemctl status nats-server"
