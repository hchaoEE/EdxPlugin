# 这个脚本主要是EDA读取，用来后续AI工具给EDA工具喂命令的
# 设置脚本交互目录
puts "api dir is ${EDX_TMP}"

# 全局变量用于控制监听器状态
set listener_running 0
set listener_id ""

# 写一个异步过程，使用after命令不断检查目录下是否有client_result文件
proc monitor_client_result_async {} {
    global EDX_TMP listener_running listener_id
    if {!$listener_running} {
        return
    }

    set target_dir "${EDX_TMP}"
    
    set client_result_path [file join $target_dir "client_result_done"]
    # 检查 client_result 文件是否存在
    if {[file exists $client_result_path]} {
        puts "检测到 client_result_done 文件"

        # 执行目录下的 command.tcl
        set command_path [file join $target_dir "command.tcl"]
        if {[file exists $command_path]} {
            # 执行命令,添加异常保护
            try {
                puts "执行 command.tcl $command_path"
                source $command_path
            } on error {errorMsg options} {
                puts "execute failed: $errorMsg"
            } on ok {} {
                puts "execute success"
            }
        } else {
            puts "警告: command.tcl 文件不存在"
        }
        # 删除 client_result_done 文件
        if {[file exists $client_result_path]} {
            file delete $client_result_path
            puts "已删除 client_result_done 文件"
        } else {
            puts "client_result_done 文件不存在，无需删除"
        }
        # 写server_result_done文件，告诉AI工具脚本执行完成
        set server_result_path [file join $target_dir "server_result_done"]
        if {[file exists $server_result_path]} {
            puts "已存在 server_result_done 文件"
        } else {
            puts "创建 server_result_done 文件"
            set f [open $server_result_path w]
            puts $f "done"
            close $f
        }
    }
    # 检查如果有command_reader_stop文件，则退出
    set command_reader_stop_path [file join $target_dir "command_reader_stop"]
    if {[file exists $command_reader_stop_path]} {
        puts "检测到 command_reader_stop 文件"
        stop_command_listener
        return
    }
    
    # 使用after命令安排下次检查，避免阻塞
    set listener_id [after 100 monitor_client_result_async]
}

# 启动命令监听器
proc start_command_listener {} {
    global listener_running listener_id EDX_TMP EDX_PLUGIN_HOME EDX_HTTP_PORT
    
    if {$EDX_TMP eq ""} {
        puts "错误: EDX_TMP 未设置，请先设置全局变量 EDX_TMP"
        return
    }
    
    set listener_running 1
    puts "开始监控 client_result 文件..."
    puts "监控目录: $EDX_TMP"
    
    # 立即启动异步监控
    monitor_client_result_async
    cd ${EDX_PLUGIN_HOME}/edx_server
    exec ${EDX_PLUGIN_HOME}/edx_server/start_edx_server.sh --detach --port $EDX_HTTP_PORT &
    cd -
    puts "命令监听器已启动 (非阻塞模式)"
}

# 停止命令监听器
proc stop_command_listener {} {
    global listener_running listener_id EDX_PLUGIN_HOME
    
    set listener_running 0
    
    if {[info exists listener_id] && $listener_id ne ""} {
        catch {after cancel $listener_id}
        set listener_id ""
    }
    # 调用stop_edx_server.sh结束http server
    exec ${EDX_PLUGIN_HOME}/edx_server/stop_edx_server.sh
    puts "命令监听器已停止"
}

# 检查监听器状态
proc check_listener_status {} {
    global listener_running listener_id
    if {$listener_running} {
        puts "监听器正在运行"
    } else {
        puts "监听器未运行"
    }
}

# 提供使用说明
puts "EDA命令监听器已加载"
puts "使用方法:"
puts "  start_command_listener          ;# 启动监听器"
puts "  stop_command_listener           ;# 停止监听器"
puts "  check_listener_status           ;# 检查监听器状态"

# 检查是否直接运行此脚本，如果是则显示帮助信息而不是自动启动
if {[info exists argv0] && [file tail [info script]] eq [file tail $argv0]} {
    puts "\n注意: 此脚本已设计为非阻塞模式。"
    puts "要启动监听器，请在设置edx_tmp后调用start_command_listener"
} else {
    # 当被source时，仅定义过程而不自动执行
    puts "脚本已加载，等待手动启动..."
}