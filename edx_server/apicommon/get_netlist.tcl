# 性能优化版：获取所有cell信息
# 一次性批量获取cell信息，减少API调用次数，适用于百万级cell数量
# 添加进度显示功能

# 记录开始时间
set start_time [clock seconds]

# 获取所有cell对象（一次性获取，减少API调用）
set all_cells [udm_get_obj -type cell]

# 获取所有cell的基本属性（一次性批量获取）
set cell_names [udm_get_prop $all_cells name]
set cell_bbox_x_lengths [udm_get_prop $all_cells bbox_x_length]
set cell_bbox_y_lengths [udm_get_prop $all_cells bbox_y_length]
set cell_orients [udm_get_prop $all_cells orient]
set cell_place_statuses [udm_get_prop $all_cells place_status]
set cell_loc_xs [udm_get_prop $all_cells loc_x]
set cell_loc_ys [udm_get_prop $all_cells loc_y]

# 批量获取pin_count，处理可能的空值情况
set pin_counts [list]
set idx 0
set cell_count [llength $cell_names]
puts stderr "Getting pin counts for $cell_count cells..."

foreach cell_name $cell_names {
    set cell_obj [get_cells $cell_name]
    if {$cell_obj eq ""} {
        # 如果get_cells返回空，则pin_count设为0
        lappend pin_counts 0
    } else {
        if {[catch {set pin_count [get_attribute $cell_obj pin_count]} result]} {
            # 如果get_attribute出错，则pin_count设为0
            lappend pin_counts 0
        } else {
            # 检查返回值是否为数字，如果不是则设为0
            if {[string is integer $pin_count]} {
                lappend pin_counts $pin_count
            } else {
                lappend pin_counts 0
            }
        }
    }
    
    # 每处理10000个cell显示一次进度
    if {$idx % 10000 == 0 && $idx > 0} {
        puts stderr "$idx/$cell_count cells processed for pin counts..."
    }
    incr idx
}

# 获取核心尺寸
set core_size [udm_get_prop [udm_get_obj -type floorplan] core_box_size]

# 初始化变量
set net_map {}
set server_result_txt [file join $EDX_TMP "server_result.txt"]
set fp [open "${server_result_txt}" w]

puts $fp "=======design_info======="
puts $fp "core_size: $core_size"
puts $fp "=======cell_info======="

# 预先统计总数，用于进度显示（可选）
set total_cells [llength $cell_names]
puts stderr "Processing $total_cells cells..."
set start_process_time [clock seconds]

# 首先筛选有效的cells（跳过WELLTAP、ENDCAP等），并获取它们的pin信息
set valid_cell_indices [list]
set valid_cell_pins [list]

set idx 0
set processed_count 0
set skipped_count 0
set last_progress_time [clock seconds]

foreach cell_name $cell_names {
    # 检查是否为需要跳过的cell类型
    if {[string first "WELLTAP" $cell_name] != -1 || [string first "ENDCAP" $cell_name] != -1} {
        incr skipped_count
        incr idx
        continue
    }
    
    # 获取pin数量（现在已经预先计算好）
    set pin_count [lindex $pin_counts $idx]
    
    # 检查是否有引脚
    if {$pin_count <= 0} {
        incr skipped_count
        incr idx
        continue
    }
    # 获取当前cell对象
    set cell_obj [lindex $all_cells $idx]
    if {$cell_obj eq ""} {
        set cell_obj [get_cells $cell_name]
    }
    
    # 获取pins并添加到列表
    if {$cell_obj ne ""} {
        set pins_for_current_cell [get_pins -of_objects [get_cells $cell_name]]
        set pin_names [get_object_name $pins_for_current_cell]
    } else {
        set pin_names [list]
    }
    
    # 只有当有pin时才保留这个cell
    if {[llength $pin_names] > 0} {
        lappend valid_cell_indices $idx
        lappend valid_cell_pins $pin_names
    } else {
        incr skipped_count
    }
    
    incr idx
    incr processed_count
    if {$processed_count % 10000 == 0} {
        set current_time [clock seconds]
        set elapsed [expr $current_time - $last_progress_time]
        if {$elapsed > 0} {
            set rate [expr {round(double($processed_count - ($processed_count % 10000))/(max($current_time - $start_process_time, 1)))}]
            puts stderr "$processed_count cells processed... ($rate cells/sec)"
        }
        set last_progress_time $current_time
    }
}

# 输出有效cell的信息
set valid_count [llength $valid_cell_indices]
puts stderr "Found $valid_count valid cells out of $total_cells total cells (skipped $skipped_count)"

set idx 0
set output_count 0
set last_output_time [clock seconds]

foreach cell_idx $valid_cell_indices {
    set cell_name [lindex $cell_names $cell_idx]
    set cell_width [lindex $cell_bbox_x_lengths $cell_idx]
    set cell_height [lindex $cell_bbox_y_lengths $cell_idx]
    set cell_orient [lindex $cell_orients $cell_idx]
    set cell_place_status [lindex $cell_place_statuses $cell_idx]
    set loc_x [lindex $cell_loc_xs $cell_idx]
    set loc_y [lindex $cell_loc_ys $cell_idx]
    set pin_names [lindex $valid_cell_pins $idx]
    
    # 获取pin名称并格式化
    set pin_names_str [join $pin_names "|"]
    
    # 批量处理pin-net关系
    foreach pin_name $pin_names {
        set pin_obj [get_pin_by_full_name $pin_name]
        set pin_net_obj [get_pin_net $pin_obj]
        set pin_nets [udm_get_prop $pin_net_obj name]
        
        if {$pin_nets ne "" && ![dict exists $net_map $pin_nets]} {
            set load_pins [get_object_name [get_attribute [get_nets $pin_nets] load_pins]]
            set driver_pins [get_object_name [get_attribute [get_nets $pin_nets] driver_pins]]
            set load_pins_str [join $load_pins "|"]
            set driver_pins_str [join $driver_pins "|"]
            dict set net_map $pin_nets [list $load_pins_str $driver_pins_str]
        }
    }
    
    # 输出cell信息
    puts $fp $cell_name
    puts $fp "${cell_width},${cell_height},${cell_orient},${cell_place_status},${loc_x},${loc_y}"
    puts $fp $pin_names_str
    
    incr idx
    incr output_count
    if {$output_count % 10000 == 0} {
        set current_time [clock seconds]
        set elapsed [expr $current_time - $last_output_time]
        if {$elapsed > 0} {
            set rate [expr {round(10000.0/$elapsed)}]
            puts stderr "Output $output_count valid cells... ($rate cells/sec)"
        }
        set last_output_time $current_time
    }
}

puts $fp "=======net_info======="

# 输出网络信息
set net_count 0
set last_net_time [clock seconds]
set output_net_count 0

dict for {net_name net_info} $net_map {
    set load_pins [lindex $net_info 0]
    set driver_pins [lindex $net_info 1]
    puts $fp "${net_name},${load_pins},${driver_pins}"
    incr net_count
    incr output_net_count
    if {$output_net_count % 1000 == 0} {
        set current_time [clock seconds]
        set elapsed [expr $current_time - $last_net_time]
        if {$elapsed > 0} {
            set rate [expr {round(1000.0/$elapsed)}]
            puts stderr "Output $net_count nets... ($rate nets/sec)"
        }
        set last_net_time $current_time
    }
}
# 将server_result_txt压缩到get_netlist.tar.gz
set current_dir [file dirname [pwd]]
cd $EDX_TMP
exec tar -czf get_netlist.tar.gz server_result.txt
cd $current_dir
set end_time [clock seconds]
set total_elapsed [expr $end_time - $start_time]
puts stderr "Total nets processed: $net_count"
puts stderr "Total execution time: $total_elapsed seconds"
puts stderr "Overall rate: [expr {round(double($total_cells)/max($total_elapsed, 1))}] cells/sec"
puts stderr "Script completed."

close $fp