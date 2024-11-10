#!/bin/bash

# 检测是否以 root 用户运行
if [ "$EUID" -ne 0 ]; then
    echo "请以 root 用户权限运行此脚本。"
    exit 1
fi

# 检测操作系统及版本
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION_ID=$VERSION_ID
else
    echo "无法检测操作系统版本。"
    exit 1
fi

# 根据不同的操作系统选择安装方法
if [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
    echo "检测到操作系统为 CentOS/RHEL $VERSION_ID，开始安装 Nginx..."

    # 安装 EPEL 仓库（如有必要）
    if ! yum repolist | grep -q "epel/"; then
        echo "安装 EPEL 仓库..."
        yum install -y epel-release
    fi

    # 更新软件包列表并安装 Nginx
    yum update -y
    yum install -y nginx

    # 启动并设置 Nginx 开机自启
    systemctl start nginx
    systemctl enable nginx

elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    echo "检测到操作系统为 $OS $VERSION_ID，开始安装 Nginx..."

    # 更新软件包列表
    apt-get update -y

    # 安装 Nginx
    apt-get install -y nginx

    # 启动并设置 Nginx 开机自启
    systemctl start nginx
    systemctl enable nginx

else
    echo "不支持的操作系统：$OS"
    exit 1
fi

# 检查 Nginx 服务状态
if systemctl is-active --quiet nginx; then
    echo "Nginx 已成功安装并启动，并已设置为开机自启。"
    echo "您可以在浏览器中访问服务器的 IP 地址以查看 Nginx 欢迎页面。"
else
    echo "Nginx 启动失败，请检查。"
    exit 1
fi
