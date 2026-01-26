#!/bin/bash

# EDX Plugin EDA工具REST API服务启动脚本 (Linux)

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 函数：打印带颜色的信息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${CYAN}$1${NC}"
}

# 用于存储后台进程PID
SERVER_PID=""

# 显示标题
print_header "========================================="
print_header "  EDX Plugin EDA工具REST API服务启动脚本"
print_header "========================================="
echo

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查是否在正确的目录
if [ ! -f "$SCRIPT_DIR/main.py" ]; then
    print_error "未在EDX Plugin项目目录中找到main.py文件"
    print_error "请在EDX Plugin项目根目录下运行此脚本"
    exit 1
fi

# 检查Python是否可用
PYTHON_CMD=""
if command -v python3.9 &> /dev/null; then
    PYTHON_CMD="python3.9"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
else
    print_error "未找到Python解释器，请确保已安装Python 3.7+"
    exit 1
fi

print_info "使用的Python解释器: $($PYTHON_CMD --version 2>&1)"

# 检查依赖
if [ -f "$SCRIPT_DIR/requirements.txt" ]; then
    print_info "检查并安装依赖包..."

    # 检查是否需要安装虚拟环境
    if [ ! -d "$SCRIPT_DIR/.venv" ]; then
        print_info "创建Python虚拟环境..."
        if ! $PYTHON_CMD -m venv .venv; then
            print_warning "创建虚拟环境失败，将继续使用系统Python环境"
            USE_VENV=0
        else
            print_success "虚拟环境创建成功"
            # 激活虚拟环境
            source .venv/bin/activate
            USE_VENV=1
        fi
    else
        print_info "激活现有虚拟环境..."
        source .venv/bin/activate
        USE_VENV=1
    fi

    # 安装依赖
    if [ $USE_VENV -eq 1 ]; then
        if ! pip install -r requirements.txt; then
            print_warning "安装依赖时出现问题，继续尝试启动服务..."
        else
            print_success "依赖安装完成"
        fi
    else
        if ! $PYTHON_CMD -m pip install -r requirements.txt; then
            print_warning "安装依赖时出现问题，继续尝试启动服务..."
        else
            print_success "依赖安装完成"
        fi
    fi
else
    print_warning "未找到requirements.txt文件"
fi

# 解析命令行参数
HOST="0.0.0.0"
PORT=5000
DEBUG=false
DETACH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--host)
            HOST="$2"
            if [[ -z "$HOST" ]]; then
                print_error "错误: --host 参数需要指定值"
                exit 1
            fi
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            if [[ -z "$PORT" ]] || ! [[ "$PORT" =~ ^[0-9]+$ ]]; then
                print_error "错误: --port 参数需要指定有效的数字"
                exit 1
            fi
            shift 2
            ;;
        -d|--debug)
            DEBUG=true
            shift
            ;;
        --detach)
            DETACH=true
            shift
            ;;
        --help)
            echo "用法: $0 [选项]"
            echo "选项:"
            echo "  -h, --host HOST    服务器主机地址 (默认: 0.0.0.0)"
            echo "  -p, --port PORT    服务器端口 (默认: 5000)"
            echo "  -d, --debug       启用调试模式"
            echo "  --detach          以分离模式启动（非阻塞）"
            echo "  --help            显示此帮助信息"
            echo
            echo "示例:"
            echo "  $0                                    # 使用默认设置启动"
            echo "  $0 --host 127.0.0.1 --port 8080       # 指定主机和端口"
            echo "  $0 --debug                            # 启用调试模式"
            echo "  $0 --detach                           # 以非阻塞模式启动"
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            echo "使用 $0 --help 查看可用选项"
            exit 1
            ;;
    esac
done

# 检查端口是否被占用
if command -v lsof &> /dev/null; then
    if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
        print_warning "警告: 端口 $PORT 似乎已被占用"
        read -p "是否继续？(y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "取消启动服务"
            exit 0
        fi
    fi
fi

# 启动服务器
print_info "开始启动EDX Plugin服务..."
print_info "服务器地址: http://$HOST:$PORT"
if [ "$DEBUG" = true ]; then
    print_info "调试模式: 已启用"
else
    print_info "调试模式: 已禁用"
fi

if [ "$DETACH" = true ]; then
    print_info "分离模式: 已启用（非阻塞）"
else
    print_info "分离模式: 已禁用（阻塞）"
fi

echo
print_header "服务启动中..."
if [ "$DETACH" = true ]; then
    print_info "服务器将在后台启动"
    print_info "访问 http://$HOST:$PORT 查看API服务状态"
    print_info "PID文件: $SCRIPT_DIR/server.pid"
else
    print_info "访问 http://$HOST:$PORT 查看API服务状态"
    print_info "按 Ctrl+C 可停止服务"
fi
echo

# 启动Python Flask应用
if [ "$DETACH" = true ]; then
    # 以分离模式启动，但仍作为子进程
    if [ "$DEBUG" = true ]; then
        $PYTHON_CMD run_server.py --host "$HOST" --port "$PORT" --debug --log-level INFO &
    else
        $PYTHON_CMD run_server.py --host "$HOST" --port "$PORT" --log-level INFO &
    fi

    SERVER_PID=$!
    echo $SERVER_PID > server.pid  # 保存进程ID到文件
    print_success "服务器已在后台启动，PID: $SERVER_PID"
    print_info "服务器正在后台持续运行..."
else
    # 非分离模式，前台运行
    if [ "$DEBUG" = true ]; then
        $PYTHON_CMD run_server.py --host "$HOST" --port "$PORT" --debug --log-level INFO
    else
        $PYTHON_CMD run_server.py --host "$HOST" --port "$PORT" --log-level INFO
    fi

    # 检查服务退出状态
    EXIT_CODE=$?
    if [ $EXIT_CODE -ne 0 ]; then
        print_error "服务意外退出，退出码: $EXIT_CODE"
    else
        print_success "服务已正常停止"
    fi
fi

# 如果虚拟环境被激活，退出它
if [ $USE_VENV -eq 1 ] && [ -n "$VIRTUAL_ENV" ]; then
    deactivate
    print_info "虚拟环境已停用"
fi

exit 0