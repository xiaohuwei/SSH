#!/bin/bash

EXT_CONTROL_FILE="/usr/pgsql-14/share/extension/postgres_fdw.control"

# 检查并安装 postgres_fdw 扩展
if [ -f "$EXT_CONTROL_FILE" ]; then
    echo "✅ 已检测到 $EXT_CONTROL_FILE 文件，postgres_fdw 扩展可用。"
else
    yum install -y postgresql14-contrib || (echo "❌ 无法通过yum安装postgresql14-contrib，请手动安装后重试。"; exit 1)

    # 安装完成后再次检查
    if [ -f "$EXT_CONTROL_FILE" ]; then
        echo "✅ postgresql14-contrib 安装完成，并检测到 $EXT_CONTROL_FILE 文件。"
    else
        echo "❌ 安装完成后仍未找到 $EXT_CONTROL_FILE 文件，请手动检查。"
        exit 1
    fi
fi

# 获取本机IP地址
IP_ADDR=$(hostname -i | awk '{print $1}')

# 添加 pg_hba.conf 规则，允许局域网服务器连接
echo "host    all             all             172.16.0.0/12         trust" >> /var/lib/pgsql/14/data/pg_hba.conf

# 修改 postgresql.conf 中的 listen_addresses 配置
if grep -E "^[#]*listen_addresses\s*=" /var/lib/pgsql/14/data/postgresql.conf > /dev/null; then
    sed -i "s/^[#]*listen_addresses\s*=.*/listen_addresses = '127.0.0.1,::1,$IP_ADDR'/g" /var/lib/pgsql/14/data/postgresql.conf
else
    echo "listen_addresses = '127.0.0.1,::1,$IP_ADDR'" >> /var/lib/pgsql/14/data/postgresql.conf
fi

# 重启 PostgreSQL 服务
systemctl restart postgresql-14
echo "PostgreSQL 已成功重启✅"
