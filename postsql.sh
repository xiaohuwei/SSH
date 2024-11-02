#!/bin/bash

# 安装 PostgreSQL 官方仓库
echo "正在安装 PostgreSQL 官方仓库..."
yum install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# 安装 PostgreSQL 14 服务器
echo "正在安装 PostgreSQL 14..."
yum install -y postgresql14-server

# 初始化数据库
echo "正在初始化 PostgreSQL 数据库..."
/usr/pgsql-14/bin/postgresql-14-setup initdb

# 启动 PostgreSQL 并设置开机启动
echo "正在启动 PostgreSQL 服务并设置为开机自启..."
systemctl enable postgresql-14
systemctl start postgresql-14

# 修改 pg_hba.conf 配置，允许本地和 127.0.0.1 免密连接
echo "正在配置 PostgreSQL 以允许本地和 127.0.0.1 免密连接..."
PG_HBA_FILE="/var/lib/pgsql/14/data/pg_hba.conf"

# 备份原始 pg_hba.conf 文件
cp "$PG_HBA_FILE" "${PG_HBA_FILE}.bak"

# 设置本地 socket 连接为 trust
if grep -q "^local\s\+all\s\+all\s\+trust" "$PG_HBA_FILE"; then
    echo "本地 Unix socket 连接已经设置为免密 trust 模式。"
else
    sed -i "s/^local\s\+all\s\+all\s\+\S\+/local   all             all                                     trust/" "$PG_HBA_FILE"
fi

# 添加 127.0.0.1 的 trust 配置
if ! grep -q "^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+trust" "$PG_HBA_FILE"; then
    echo "host    all             all             127.0.0.1/32            trust" >> "$PG_HBA_FILE"
    echo "已为 127.0.0.1 添加 trust 免密连接配置。"
fi

# 重启 PostgreSQL 服务以应用配置
echo "正在重启 PostgreSQL 服务以应用新的配置..."
systemctl restart postgresql-14

# 使用 psql 创建数据库 ws
echo "正在创建数据库 'ws'..."
sudo -i -u postgres psql -c "CREATE DATABASE ws;"

echo "PostgreSQL 安装和配置已完成。"
echo "可使用下面的命令检查"
echo "psql "postgres://postgres@localhost:5432/ws"
