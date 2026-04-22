#!/bin/bash

# 安装 PostgreSQL 官方 APT 仓库
echo "正在配置 PostgreSQL 官方 APT 仓库..."
apt install -y curl ca-certificates postgresql-common

# 自动配置 PGDG 官方源（自动识别 Ubuntu 版本）
/usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y

# 安装 PostgreSQL 18（当前最新稳定版）
echo "正在安装 PostgreSQL 18..."
apt install -y postgresql-18

# Ubuntu 安装后会自动完成初始化，无需手动 initdb

# 启动 PostgreSQL 并设置开机启动
echo "正在启动 PostgreSQL 服务并设置为开机自启..."
systemctl enable postgresql
systemctl start postgresql

# 修改 pg_hba.conf 配置，允许本地和 127.0.0.1 免密连接
echo "正在配置 PostgreSQL 以允许本地和 127.0.0.1 免密连接..."
PG_HBA_FILE="/etc/postgresql/18/main/pg_hba.conf"

# 备份原始 pg_hba.conf 文件
cp "$PG_HBA_FILE" "${PG_HBA_FILE}.bak"

# 修改本地 Unix socket 连接为 trust
if grep -q "^local\s\+all\s\+all\s\+peer" "$PG_HBA_FILE"; then
  sed -i "s/^local\s\+all\s\+all\s\+peer/local all all trust/" "$PG_HBA_FILE"
  echo "本地 Unix socket 连接已设置为 trust。"
fi

# 修改 127.0.0.1 的连接为 trust
if grep -q "^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+scram-sha-256" "$PG_HBA_FILE"; then
  sed -i "s/^host\s\+all\s\+all\s\+127\.0\.0\.1\/32\s\+scram-sha-256/host all all 127.0.0.1\/32 trust/" "$PG_HBA_FILE"
  echo "127.0.0.1 的连接方式已更新为 trust。"
fi

# 修改 ::1 的连接为 trust
if grep -q "^host\s\+all\s\+all\s\+::1\/128\s\+scram-sha-256" "$PG_HBA_FILE"; then
  sed -i "s/^host\s\+all\s\+all\s\+::1\/128\s\+scram-sha-256/host all all ::1\/128 trust/" "$PG_HBA_FILE"
  echo "::1 的连接方式已更新为 trust。"
fi

# 修改 postgresql.conf 的 max_connections 参数为 500
POSTGRESQL_CONF="/etc/postgresql/18/main/postgresql.conf"
cp "$POSTGRESQL_CONF" "${POSTGRESQL_CONF}.bak"

if grep -q "^[#]*\s*max_connections\s*=" "$POSTGRESQL_CONF"; then
  sed -i "s/^[#]*\s*max_connections\s*=.*/max_connections = 500/" "$POSTGRESQL_CONF"
else
  echo "max_connections = 500" >> "$POSTGRESQL_CONF"
fi
echo "max_connections 参数已修改为 500。"

# 重启 PostgreSQL 服务以应用配置
echo "正在重启 PostgreSQL 服务以应用新的配置..."
systemctl restart postgresql

# 创建数据库 ws
echo "正在创建数据库 'ws'..."
sudo -i -u postgres psql -c "CREATE DATABASE ws;"

# 提示信息
echo "PostgreSQL 安装和配置已完成。"
echo "可使用下面的命令检查连接是否成功："
echo ""
echo 'psql "postgres://postgres@localhost:5432/ws"'
echo ""
echo "或者使用 127.0.0.1 地址："
echo ""
echo 'psql "postgres://postgres@127.0.0.1:5432/ws"'
