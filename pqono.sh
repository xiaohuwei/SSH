#!/bin/bash

EXT_CONTROL_FILE="/usr/pgsql-14/share/extension/postgres_fdw.control"

# 检查 postgres_fdw.control 文件是否存在
if [ -f "$EXT_CONTROL_FILE" ]; then
    echo "✅ 已检测到 $EXT_CONTROL_FILE 文件，postgres_fdw 扩展可用。"
    echo "已安装，无需再次执行后续步骤。脚本结束。"
    exit 0
else
    echo "❌ 未检测到 $EXT_CONTROL_FILE 文件，说明 postgres_fdw 扩展未安装或不完整，正在尝试安装 postgresql14-contrib..."
    yum install -y postgresql14-contrib || (echo "❌ 无法通过yum安装postgresql14-contrib，请手动安装后重试。"; exit 1)

    # 安装完成后再次检查
    if [ -f "$EXT_CONTROL_FILE" ]; then
        echo "✅ postgresql14-contrib 安装完成，并检测到 $EXT_CONTROL_FILE 文件。"
    else
        echo "❌ 安装完成后仍未找到 $EXT_CONTROL_FILE 文件，请手动检查。"
        exit 1
    fi
fi

echo "开始获取本机IP地址...😊"
IP_ADDR=$(hostname -i | awk '{print $1}')
echo "本机IP地址为: $IP_ADDR 😎"

echo "添加 pg_hba.conf 规则，允许局域网服务器连接...✏"
echo "host    all             all             172.30.224.0/20         trust" >> /var/lib/pgsql/14/data/pg_hba.conf
echo "规则添加完成✅"

echo "开始修改 postgresql.conf 中的 listen_addresses 配置...✏"

# 检查 postgresql.conf 中是否存在 listen_addresses 配置（无论是否注释）
if grep -E "^[#]*listen_addresses\s*=" /var/lib/pgsql/14/data/postgresql.conf > /dev/null; then
    # 如果存在（可能是注释状态），进行替换
    sed -i "s/^[#]*listen_addresses\s*=.*/listen_addresses = '127.0.0.1,::1,$IP_ADDR'/g" /var/lib/pgsql/14/data/postgresql.conf
else
    # 如果不存在，则追加一行
    echo "listen_addresses = '127.0.0.1,::1,$IP_ADDR'" >> /var/lib/pgsql/14/data/postgresql.conf
fi

echo "配置修改完成✅"

echo "重启 PostgreSQL 服务...🔄"
systemctl restart postgresql-14
echo "PostgreSQL 已成功重启✅"
