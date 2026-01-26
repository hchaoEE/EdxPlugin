#!/bin/sh
# 启动TCL服务器的shell脚本

TCLSH=tclsh
SERVER_SCRIPT="eda_server.tcl"
PORT=${1:-9999}

if [ $# -lt 1 ]; then
    echo "Usage: $0 <port> [background]"
    echo "Example: $0 9999          # Run in foreground"
    echo "         $0 9999 &        # Run in background using shell"
    echo "         $0 9999 background # Run using TCL's background mechanism"
    exit 1
fi

echo "Starting EDA Server on port $PORT..."

if [ "$2" = "background" ]; then
    # 使用TCL内部的后台机制
    $TCLSH $SERVER_SCRIPT $PORT background &
else
    if [ "$2" = "&" ]; then
        # 使用shell后台运行
        $TCLSH $SERVER_SCRIPT $PORT &
    else
        # 前台运行
        $TCLSH $SERVER_SCRIPT $PORT
    fi
fi