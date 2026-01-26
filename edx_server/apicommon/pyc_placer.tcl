# 这个脚本主要是EDA读取，用来后续AI工具给EDA工具喂命令的
# 设置脚本交互目录
proc log_info {{args ""}} {
    set current_time [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts "\[LEAPR_PYCPLACER\]\[INFO\]\[${current_time}\] [lindex $args 0]"
}

proc log_debug {{args ""}} {
    global enable_debug
    if {[info exists enable_debug] && $enable_debug == 1} {
        set current_time [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        puts "\[LEAPR_PYCPLACER\]\[DEBUG\]\[${current_time}\] [lindex $args 0]"
    }
}

# 判断如果没有EDX_TMP变量,则报错，脚本执行结束
if {![info exists EDX_TMP]} {
    log_info "错误: EDX_TMP 变量未定义"
    exit 1
}

log_info "api dir is ${EDX_TMP}"
# 写一个死循环，不断读取目录下是否有client_result文件
proc monitor_client_result {} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    while {1} {
        set client_result_path [file join $target_dir "client_result_done"]
        # 检查 client_result 文件是否存在
        if {[file exists $client_result_path]} {
            # 执行目录下的 command.tcl
            set command_path [file join $target_dir "command.tcl"]
            if {[file exists $command_path]} {
                # 执行命令,添加异常保护
                try {
                    source $command_path
                } on error {errorMsg options} {
                    log_info "execute failed"
                } on ok {} {
                }
            } else {
                log_info "警告: command.tcl 文件不存在"
            }
            # 删除 client_result_done 文件
            if {[file exists $client_result_path]} {
                file delete $client_result_path
            } else {
                log_info "client_result_done 文件不存在，无需删除"
            }
            # 写server_result_done文件，告诉AI工具脚本执行完成
            set server_result_path [file join $target_dir "server_result_done"]
            if {[file exists $server_result_path]} {
                log_info "已存在 server_result_done 文件"
            } else {
                set f [open $server_result_path w]
                puts $f "done"
                close $f
            }
            # 如果EDX_TMP目录下有plugin_msg_done文件，则读取plugin_msg.txt文件,并将内容打印出来
            set plugin_msg_path [file join $target_dir "plugin_msg.txt"]
            set plugin_msg_done_path [file join $target_dir "plugin_msg_done"]
            if {[file exists $plugin_msg_path]} {
                if {[file exists $plugin_msg_done_path]} {
                    set f [open $plugin_msg_path r]
                    while {[gets $f line] >= 0} {
                        log_info $line
                    }
                    close $f
                }
            }
            break
        }
        # 短暂休眠，避免过度占用CPU
        after 1000  ;# 休眠1秒
    }
}

proc monitor_client_result_plugin {} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    while {1} {
        set client_result_path [file join $target_dir "client_result_done"]
        # 检查 client_result 文件是否存在
        if {[file exists $client_result_path]} {
            # 执行目录下的 command.tcl
            set command_path [file join $target_dir "command.tcl"]
            if {[file exists $command_path]} {
                # 执行命令,添加异常保护
                try {
                    source $command_path
                } on error {errorMsg options} {
                    log_info "execute failed"
                } on ok {} {
                }
            } else {
                log_info "警告: command.tcl 文件不存在"
            }
            # 删除 client_result_done 文件
            if {[file exists $client_result_path]} {
                file delete $client_result_path
            } else {
                log_info "client_result_done 文件不存在，无需删除"
            }
            # 写server_result_done文件，告诉AI工具脚本执行完成
            log_debug "write server_result_done"
            set server_result_path [file join $target_dir "server_result_done"]
            if {[file exists $server_result_path]} {
                log_info "已存在 server_result_done 文件"
            } else {
                set f [open $server_result_path w]
                puts $f "done"
                close $f
                log_debug "==========create server result done111 $server_result_path"
            }
        }
        # 短暂休眠，避免过度占用CPU
        after 1000  ;# 休眠1秒
        # 检测插件是否执行完
        log_debug "==========waiting plugin_msg_done"
        # 如果EDX_TMP目录下有plugin_msg_done文件，则读取plugin_msg.txt文件,并将内容打印出来
        set plugin_msg_path [file join $target_dir "plugin_msg.txt"]
        set plugin_msg_done_path [file join $target_dir "plugin_msg_done"]
        if {[file exists $plugin_msg_path]} {
            if {[file exists $plugin_msg_done_path]} {
                set f [open $plugin_msg_path r]
                while {[gets $f line] >= 0} {
                    puts $line
                }
                close $f
                file delete $plugin_msg_path
                file delete $plugin_msg_done_path
                break
            }
        }
    }
}

proc pyc_reset {} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_reset，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    puts $f "pyc_reset"
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_global_placement {{args ""}} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_global_placement，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    if {$args eq ""} {
        puts $f "pyc_global_placement"
    } else {
        puts $f "pyc_global_placement $args"
    }
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_increment_placement {{args ""}} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_increment_placement，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    if {$args eq ""} {
        puts $f "pyc_increment_placement"
    } else {
        puts $f "pyc_increment_placement $args"
    }
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_reset_only_increment {} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_reset_only_increment，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    puts $f "pyc_reset_only_increment"
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_get_cell {{args ""}} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_get_cell，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    if {$args eq ""} {
        puts $f "pyc_get_cell"
    } else {
        puts $f "pyc_get_cell $args"
    }
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_get_name {{args ""}} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_get_name，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    if {$args eq ""} {
        puts $f "pyc_get_name"
    } else {
        puts $f "pyc_get_name $args"
    }
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_refresh_timing {{args ""}} {
    global EDX_TMP
    report_timing -group REG2REG -max_paths $args -path_type full > $EDX_TMP/report
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_refresh_timing，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    puts $f "pyc_refresh_timing"
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}

proc pyc_report_timing {{args ""}} {
    global EDX_TMP
    set target_dir "${EDX_TMP}"
    # target_dir目录下plugin_cmd.txt文件中写入：pyc_report_timing，如果文件不存在则创建这个文件
    set plugin_cmd_path [file join $target_dir "plugin_cmd.txt"]
    if {[file exists $plugin_cmd_path]} {
       file delete $plugin_cmd_path
    }
    set f [open $plugin_cmd_path w]
    if {$args eq ""} {
        puts $f "pyc_report_timing"
    } else {
        puts $f "pyc_report_timing $args"
    }
    close $f
    # 写一个plugin_cmd_done文件，告诉AI工具脚本执行完成
    set plugin_cmd_done_path [file join $target_dir "plugin_cmd_done"]
    if {[file exists $plugin_cmd_done_path]} {
        log_info "已存在 plugin_cmd_done 文件"
    } else {
        set f [open $plugin_cmd_done_path w]
        puts $f "done"
        close $f
    }
    monitor_client_result_plugin
}