#!/bin/bash

# 检查是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
  echo "请以 root 用户运行此脚本。"
  exit 1
fi

echo "正在生成随机 root 密码..."

# 生成随机密码
ROOT_PASSWORD=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 16)

# 设置 root 用户密码
echo "root:$ROOT_PASSWORD" | chpasswd

echo "已为 root 用户设置新的随机密码。"

echo "正在修改 SSH 配置以允许 root 登录..."

# 修改 /etc/ssh/sshd_config
SSH_CONFIG="/etc/ssh/sshd_config"

# 备份原始配置文件
if [ ! -f "${SSH_CONFIG}.bak" ]; then
  cp $SSH_CONFIG ${SSH_CONFIG}.bak
  echo "已备份原始 SSH 配置文件为 ${SSH_CONFIG}.bak"
fi

# 修改 sshd_config
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' $SSH_CONFIG
sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' $SSH_CONFIG
sed -i 's/^#*UsePAM.*/UsePAM yes/g' $SSH_CONFIG

echo "已修改 $SSH_CONFIG"

# 检查 /etc/ssh/sshd_config.d 目录下的所有配置文件
SSH_CONFIG_D="/etc/ssh/sshd_config.d"

if [ -d "$SSH_CONFIG_D" ]; then
  echo "正在检查 $SSH_CONFIG_D 目录下的配置文件..."
  for config_file in $SSH_CONFIG_D/*.conf; do
    if [ -f "$config_file" ]; then
      echo "正在处理 $config_file"

      # 备份配置文件
      if [ ! -f "${config_file}.bak" ]; then
        cp $config_file ${config_file}.bak
        echo "已备份原始配置文件为 ${config_file}.bak"
      fi

      # 修改配置文件中的参数
      sed -i 's/^#*PermitRootLogin.*/PermitRootLogin yes/g' "$config_file"
      sed -i 's/^PermitRootLogin no/PermitRootLogin yes/g' "$config_file"
      sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication yes/g' "$config_file"
      sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/g' "$config_file"
      sed -i 's/^#*UsePAM.*/UsePAM yes/g' "$config_file"
      sed -i 's/^UsePAM no/UsePAM yes/g' "$config_file"

    fi
  done
else
  echo "$SSH_CONFIG_D 目录不存在，跳过此步骤。"
fi

echo "正在重启 SSH 服务..."

# 重启 SSH 服务
if command -v systemctl >/dev/null 2>&1; then
  systemctl restart sshd
  echo "已使用 systemctl 重启 sshd 服务。"
elif command -v service >/dev/null 2>&1; then
  service sshd restart
  echo "已使用 service 重启 sshd 服务。"
else
  echo "无法重启 sshd 服务，请手动重启。"
fi

# 获取公网 IP
PUBLIC_IP=$(curl -s https://checkip.amazonaws.com)

echo "所有操作已完成！"
echo "--------------------------------------------"
echo "您的 root 用户新密码为：$ROOT_PASSWORD"
echo "请妥善保管，并尽快登录测试。"
echo "出于安全考虑，建议您在登录后立即更改密码。"
echo ""
echo "使用以下命令登录服务器："
echo "ssh root@$PUBLIC_IP"
echo "--------------------------------------------"
