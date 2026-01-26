#!/bin/bash

# 从环境变量获取instance_id，如果没有设置则使用默认值1
INSTANCE_ID=${EDX_INSTANCE_ID:-1}

# 创建停止文件以通知服务器停止
STOP_FILE="/tmp/edx_server/tmp_${INSTANCE_ID}/command_reader_stop"

# 确保目录存在
mkdir -p "/tmp/edx_server/tmp_${INSTANCE_ID}"

# 创建停止文件
touch "$STOP_FILE"
echo "已创建停止文件: $STOP_FILE"

# 等待一段时间让服务器处理停止请求
sleep 3

# 清理停止文件
rm -f "$STOP_FILE"
echo "已清理停止文件: $STOP_FILE"

echo "停止命令已发送到HTTP服务器"