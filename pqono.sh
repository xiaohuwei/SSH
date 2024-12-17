#!/bin/bash

echo "开始获取本机IP地址...😊"
IP_ADDR=$(hostname -i | awk '{print $1}')
echo "本机IP地址为: $IP_ADDR 😎"

echo "开始安装 postgresql14-contrib...🔧"
yum install -y postgresql14-contrib
echo "安装完成✅"

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
