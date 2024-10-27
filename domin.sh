#!/bin/bash

# 检查参数是否提供
if [ $# -ne 1 ]; then
    echo "用法: $0 新域名"
    exit 1
fi

NEW_DOMAIN=$1
CONF_FILE=$(ls /etc/nginx/conf.d/*.conf | head -n 1)

# 备份配置文件
cp "$CONF_FILE" "${CONF_FILE}.bak"

# 编辑配置文件，找到第一个 server_name 并添加新域名
sed -i "0,/server_name/s/server_name \(.*\);/server_name \1 $NEW_DOMAIN;/" "$CONF_FILE"

# 重新加载Nginx配置
nginx -s reload

# 读取并打印当前绑定的所有域名
echo "已在 $CONF_FILE 中添加域名 $NEW_DOMAIN 并重新加载Nginx。当前绑定的域名列表："
grep -oP "(?<=server_name\s).+;" "$CONF_FILE" | sed 's/;$//'
