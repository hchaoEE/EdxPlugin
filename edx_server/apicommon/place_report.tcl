set incr_arg ""
set unplaced_counter 0
proc place_report {} {
    global incr_arg
    set cell_names [udm_get_prop [udm_get_obj -type cell] name]
    global unplaced_counter
    set cell_num  [llength $cell_names]
    set no_pin_cell_num 0
    foreach cell_name $cell_names {
         # 如果cell_name包含WELLTAP,GATE等，则跳过
        if {[string first "WELLTAP" $cell_name] != -1} {
          incr no_pin_cell_num
          continue
        }
        if {[string first "ENDCAP" $cell_name] != -1} {
         incr no_pin_cell_num
         continue
        }
        set pin_count [get_attribute [get_cells $cell_name] pin_count]
        # 如果pin_count <=0，跳过
        if {$pin_count <= 0} {
            incr no_pin_cell_num
            continue
        }
        set cell_name [string trim $cell_name]
        set status [udm_get_prop [get_obj_by_name $cell_name] place_status]
        if {$status == "unplaced"} {
            incr unplaced_counter
            log_info "cell $cell_name is unplaced"
            # 拼接到incr_arg中
            set incr_arg "$incr_arg,$cell_name"
        }
    }
    log_info "all cells: $cell_num"
    log_info "unplaced cells: $unplaced_counter"
    log_info "no pin cells: $no_pin_cell_num"
    log_info "incr_arg: $incr_arg"
}
place_report
