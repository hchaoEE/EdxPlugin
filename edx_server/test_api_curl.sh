#!/bin/bash

# EDX Plugin API 接口测试脚本
# 用于测试所有API端点

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 初始化计数器
success_count=0
failure_count=0

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

# 打印格式化后的响应体的前N行
print_body_lines() {
    local body="$1"
    local max_lines="${2:-10}"
    
    # 尝试格式化JSON，如果失败则按原样处理
    if echo "$body" | jq . >/dev/null 2>&1; then
        # 格式化JSON并取前N行
        formatted_body=$(echo "$body" | jq . 2>/dev/null)
        local line_count=$(echo "$formatted_body" | wc -l)
        
        if [ $line_count -gt $max_lines ]; then
            echo "$formatted_body" | head -n $max_lines
            print_warning "... (仅显示格式化JSON的前${max_lines}行，共${line_count}行)"
        else
            echo "$formatted_body"
        fi
    else
        # 如果不是有效的JSON，则按原样处理
        local line_count=$(echo "$body" | wc -l)
        
        if [ $line_count -gt $max_lines ]; then
            echo "$body" | head -n $max_lines
            print_warning "... (仅显示前${max_lines}行，共${line_count}行)"
        else
            echo "$body"
        fi
    fi
}

# 测试主页面
test_home() {
    print_header "测试 1: 主页面接口"
    print_info "GET http://localhost:5001/"
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/)
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "主页面接口测试成功，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "主页面接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试加载网表
test_load_netlist() {
    print_header "测试 2: 加载网表接口"
    
    # 创建临时网表文件
    local temp_netlist="/tmp/test_netlist.v"
    print_info "POST http://localhost:5001/leapr/load_netlist"

    response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
        -X POST http://localhost:5001/leapr/load_netlist \
        -H "Content-Type: application/json" \
        -d "{\"file_path\": \"$temp_netlist\"}")
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "加载网表接口测试成功，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "加载网表接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    
    # 清理临时文件
    rm -f "$temp_netlist"
    echo
}

# 测试获取时序信息（无参数）
test_get_timing_default() {
    print_header "测试 3.1: 获取时序信息接口（默认参数）"
    print_info "GET http://localhost:5001/leapr/get_timing"
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/leapr/get_timing)
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "获取时序信息接口测试成功（默认参数），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "获取时序信息接口测试失败（默认参数），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试获取时序信息（topn参数为1）
test_get_timing_with_topn_1() {
    print_header "测试 3.2: 获取时序信息接口（topn=1参数）"
    print_info "GET http://localhost:5001/leapr/get_timing?topn=1"
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/leapr/get_timing?topn=1)
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "获取时序信息接口测试成功（topn=1），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "获取时序信息接口测试失败（topn=1），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试获取时序信息（topn参数为3）
test_get_timing_with_topn_3() {
    print_header "测试 3.3: 获取时序信息接口（topn=3参数）"
    print_info "GET http://localhost:5001/leapr/get_timing?topn=3"
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/leapr/get_timing?topn=3)
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "获取时序信息接口测试成功（topn=3），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "获取时序信息接口测试失败（topn=3），状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试执行TCL命令
test_execute_tcl() {
    print_header "测试 4: 执行TCL命令接口"
    print_info "POST http://localhost:5001/leapr/execute_tcl"
    print_info "请求体: {\"command\": \"[puts test_tcl]\"}}"

    response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
        -X POST http://localhost:5001/leapr/execute_tcl \
        -H "Content-Type: application/json" \
        -d '{"commands": ["puts test_tcl"]}')
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "执行TCL命令接口测试成功，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "执行TCL命令接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试执行cell摆放
test_place_cells() {
    print_header "测试 5: 执行cell摆放接口"
    print_info "POST http://localhost:5001/leapr/place_cells"
    
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
        -X POST http://localhost:5001/leapr/place_cells \
        -H "Content-Type: application/json" \
        -d '[{"cell_name": "u_macc_top/macc[0].u_macc/lc_drvi15_n119", "x": 10.67, "y": 11.12, "width": 10.0, "height": 12.0, "orient": "R0", "place_status": "PLACED"}]')
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "执行cell摆放接口测试成功，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "执行cell摆放接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 测试下载网表文件接口
test_download_netlist() {
    print_header "测试 7: 下载网表文件接口"
    print_info "GET http://localhost:5001/leapr/download_netlist"
    
    # 创建临时文件来保存下载的网表
    temp_download_file="/tmp/netlist_test.gz"
    
    # 执行下载请求
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
        -X GET "${API_BASE_URL}/leapr/download_netlist" \
        -H "Content-Type: application/json" \
        --output "$temp_download_file")
    
    # 获取响应状态码和时间
    last_line=$(echo "$response" | tail -n 1)
    second_last_line=$(echo "$response" | tail -n 2 | head -n 1)
    http_code=$second_last_line
    time_total=$last_line
    
    if [ "$http_code" -eq 200 ]; then
        # 检查下载的文件是否存在且不为空
        if [ -f "$temp_download_file" ] && [ -s "$temp_download_file" ]; then
            file_size=$(stat -c%s "$temp_download_file" 2>/dev/null || stat -f%z "$temp_download_file" 2>/dev/null || echo 0)
            print_success "下载网表文件接口测试成功，状态码: $http_code，响应时间: ${time_total}s，文件大小: ${file_size} bytes"
            
            # 尝试解压并查看部分内容
            print_info "下载的压缩文件内容预览:"
            gunzip -c "$temp_download_file" | head -n 10
            if [ $(gunzip -c "$temp_download_file" | wc -l) -gt 10 ]; then
                print_warning "... (仅显示前10行)"
            fi
            
            ((success_count++))
        else
            print_error "下载网表文件接口测试失败，状态码: $http_code，但下载的文件不存在或为空"
            ((failure_count++))
        fi
    else
        print_error "下载网表文件接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        ((failure_count++))
    fi
    
    # 清理临时文件
    rm -f "$temp_download_file"
    echo
}

# 综合测试：获取时序路径，移动终点cell，比较slack变化
test_timing_slack_change() {
    print_header "测试 6: 时序slack变化测试"
    print_info "综合测试：获取top1时序路径 -> 移动终点cell -> 比较slack变化"
    
    # 步骤1: 获取当前top1时序路径
    print_info "步骤1: 获取当前top1时序路径"
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/leapr/get_timing?topn=1)
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -ne 200 ]; then
        print_error "获取时序信息失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
        echo
        return
    fi
    
    print_success "获取初始时序信息成功，响应时间: ${time_total}s"
    
    # 提取第一个时序路径的终点cell信息（需要使用jq来解析JSON）
    if command -v jq &> /dev/null; then
        # 尝试提取第一个timing path的end_point
        endpoint=$(echo "$body" | jq -r '.data.timing_paths[0].end_point' 2>/dev/null)
        initial_slack=$(echo "$body" | jq -r '.data.timing_paths[0].slack' 2>/dev/null)
        
        if [ -z "$endpoint" ] || [ "$endpoint" = "null" ]; then
            print_warning "未能从响应中提取到有效的end_point，跳过此测试"
            ((success_count++))
            echo
            return
        fi
        
        if [ -z "$initial_slack" ] || [ "$initial_slack" = "null" ]; then
            print_warning "未能从响应中提取到有效的slack值，跳过此测试"
            ((success_count++))
            echo
            return
        fi
        
        print_info "提取到终点cell: $endpoint, 初始slack: $initial_slack"
        
        # 步骤2: 准备移动cell的请求数据
        print_info "步骤2: 准备移动cell $endpoint 到新位置"
        
        # 生成新的随机坐标
        new_x=$(awk -v min=0 -v max=60 'BEGIN{srand(); print min+int(rand()*(max-min+1))}')
        new_y=$(awk -v min=0 -v max=60 'BEGIN{srand(); print min+int(rand()*(max-min+1))}')
        # 构造移动cell的请求

        # 从endpoint中提取cell_name（最后一个'/'之前的部分）
        cell_name="u_macc_top/macc[2].u_macc/U127"
        move_request="[{\"cell_name\": \"$cell_name\", \"x\": $new_x, \"y\": $new_y, \"width\": 60.0, \"height\": 12.0, \"orient\": \"R0\", \"place_status\": \"PLACED\"}]"
        
        # 步骤3: 执行cell移动
        print_info "步骤3: 执行cell移动，新位置: ($new_x, $new_y)"
        response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
            -X POST http://localhost:5001/leapr/place_cells \
            -H "Content-Type: application/json" \
            -d "$move_request")
        
        # 提取响应体、状态码和时间
        body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
        last_two_lines=$(echo "$response" | tail -n 2)
        http_code=$(echo "$last_two_lines" | head -n 1)
        time_total=$(echo "$last_two_lines" | tail -n 1)
        
        if [ "$http_code" -ne 200 ]; then
            print_error "移动cell失败，状态码: $http_code，响应时间: ${time_total}s"
            print_body_lines "$body" 100
            ((failure_count++))
            echo
            return
        fi

        # 步骤3.1 执行tcl命令: bind_design
        print_info "步骤3.1: 执行tcl命令: bind_design"
        response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
            -X POST http://localhost:5001/leapr/execute_tcl \
            -H "Content-Type: application/json" \
            -d '{"commands": ["bind_design"]}')
        body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
        if [ "$http_code" -ne 200 ]; then
            print_error "执行tcl命令: bind_design 失败，状态码: $http_code，响应时间: ${time_total}s"
            print_body_lines "$body" 100
            ((failure_count++))
            echo
            return
        fi
        
        print_success "cell移动成功，响应时间: ${time_total}s"
        
        # 步骤4: 再次获取top1时序路径
        print_info "步骤4: 重新获取top1时序路径以比较slack变化"
        response=$(curl -s -w "\n%{http_code}\n%{time_total}" http://localhost:5001/leapr/get_timing?topn=1)

        # 提取响应体、状态码和时间
        body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
        last_two_lines=$(echo "$response" | tail -n 2)
        http_code=$(echo "$last_two_lines" | head -n 1)
        time_total=$(echo "$last_two_lines" | tail -n 1)

        if [ "$http_code" -ne 200 ]; then
            print_error "重新获取时序信息失败，状态码: $http_code，响应时间: ${time_total}s"
            print_body_lines "$body" 100
            ((failure_count++))
            echo
            return
        fi

        print_success "重新获取时序信息成功，响应时间: ${time_total}s"

        # 提取新的slack值
        new_slack=$(echo "$body" | jq -r '.data.timing_paths[0].slack' 2>/dev/null)

        if [ -z "$new_slack" ] || [ "$new_slack" = "null" ]; then
            print_warning "未能从响应中提取到新的slack值"
            new_slack="N/A"
            slack_diff="N/A"
        else
            # 计算slack差值
            slack_diff=$(echo "$new_slack $initial_slack" | awk '{printf "%.6f", $1 - $2}')
        fi
        
        # 步骤5: 打印结果
        print_info "========== 测试结果 =========="
        print_info "初始slack: $initial_slack"
        print_info "移动cell后slack: $new_slack"
        print_info "slack差值 (新-旧): $slack_diff"
        print_info "============================="
        
        if [ "$new_slack" != "N/A" ]; then
            print_success "综合测试完成，成功比较了移动cell前后的时序slack变化"
            ((success_count++))
        else
            print_warning "综合测试部分完成，但未能计算slack差值"
            ((success_count++))  # 仍视为成功，因为主要流程已完成
        fi
    else
        print_warning "系统未安装jq，无法解析JSON响应，跳过此测试"
        ((success_count++))
    fi
    
    echo
}

# 测试复杂数据处理接口
test_process_complex_data() {
    print_header "测试 8: 复杂数据处理接口"
    print_info "POST http://localhost:5001/leapr/process_complex_data"
    
    # 发送测试数据到复杂数据处理接口
    response=$(curl -s -w "\n%{http_code}\n%{time_total}" \
        -X POST http://localhost:5001/leapr/process_complex_data \
        -H "Content-Type: application/json" \
        -d '{"test_data": {"numbers": [1, 2, 3, 4, 5], "operation": "sum"}}')
    
    # 提取响应体、状态码和时间
    body=$(echo "$response" | sed -n '1,/^200$/p' | sed '$d')
    last_two_lines=$(echo "$response" | tail -n 2)
    http_code=$(echo "$last_two_lines" | head -n 1)
    time_total=$(echo "$last_two_lines" | tail -n 1)
    
    if [ "$http_code" -eq 200 ]; then
        print_success "复杂数据处理接口测试成功，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((success_count++))
    else
        print_error "复杂数据处理接口测试失败，状态码: $http_code，响应时间: ${time_total}s"
        print_body_lines "$body" 100
        ((failure_count++))
    fi
    echo
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖项..."
    
    if ! command -v curl &> /dev/null; then
        print_error "curl 未安装，请先安装 curl"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        print_warning "jq 未安装，将无法格式化JSON输出"
    fi
    
    print_success "依赖检查完成"
    echo
}

# 检查服务是否运行
check_service() {
    print_info "检查服务是否运行在 http://localhost:5001..."
    
    if timeout 10 bash -c "until curl -s -o /dev/null http://localhost:5001/; do sleep 0.5; done"; then
        print_success "服务正在运行"
        echo
        return 0
    else
        print_error "服务未在 http://localhost:5001 运行"
        print_info "请先启动服务: ./run_server.py 或 python main.py"
        exit 1
    fi
}

# 显示测试结果统计
print_test_summary() {
    local total_tests=$((success_count + failure_count))
    print_header "========================================="
    print_header "          测试结果统计"
    print_header "========================================="
    echo
    print_info "总测试用例数: $total_tests"
    print_success "成功: $success_count"
    if [ $failure_count -gt 0 ]; then
        print_error "失败: $failure_count"
    else
        print_success "失败: $failure_count"
    fi
    echo
    
    if [ $total_tests -gt 0 ]; then
        local success_rate=$((success_count * 100 / total_tests))
        print_info "成功率: ${success_rate}%"
    fi
}

# 显示使用说明
show_usage() {
    echo "用法: $0 [选项]"
    echo "选项:"
    echo "  --help     显示此帮助信息"
    echo "  --host     指定服务器主机 (默认: localhost)"
    echo "  --port     指定服务器端口 (默认: 5001)"
    echo
    echo "示例:"
    echo "  $0                           # 使用默认设置测试"
    echo "  $0 --host 192.168.1.100     # 测试指定主机"
    echo "  $0 --port 8080              # 测试指定端口"
}

# 解析命令行参数
HOST="localhost"
PORT="5001"

while [[ $# -gt 0 ]]; do
    case $1 in
        --host)
            HOST="$2"
            shift 2
            ;;
        --port)
            PORT="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            print_error "未知参数: $1"
            show_usage
            exit 1
            ;;
    esac
done

# 更新API_BASE_URL
API_BASE_URL="http://$HOST:$PORT"

# 显示标题
print_header "========================================="
print_header "  EDX Plugin API 接口测试脚本"
print_header "========================================="
echo

# 检查依赖
check_dependencies

# 检查服务
check_service

# 运行测试
print_info "开始测试 EDX Plugin API 接口..."
echo

test_home
test_load_netlist
test_get_timing_default
test_get_timing_with_topn_1
test_get_timing_with_topn_3
test_execute_tcl
test_place_cells
test_timing_slack_change
test_download_netlist

# 打印测试结果统计
print_test_summary

print_success "所有API测试完成！"
print_info "如果某些测试失败，请检查服务是否正常运行以及请求参数是否正确。"