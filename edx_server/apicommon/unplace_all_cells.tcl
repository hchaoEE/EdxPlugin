# 将所有cell unplace掉
set cell_names [udm_get_prop [udm_get_obj -type cell] name]
set cell_num  [llength $cell_names]
foreach cell_name $cell_names {
    set_cell_placement_status -name $cell_name -status unplaced
}
log_info "set unplace cell number: $cell_num"