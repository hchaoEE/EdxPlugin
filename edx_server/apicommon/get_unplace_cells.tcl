set cell_names [udm_get_prop [udm_get_obj -type cell] name]
set net_map {}
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
        continue
    }
    set cell_width [udm_get_prop [get_obj_by_name $cell_name] bbox_x_length]
    set cell_height [udm_get_prop [get_obj_by_name $cell_name] bbox_y_length]
    set cell_orient [udm_get_prop [get_obj_by_name $cell_name] orient]
    set cell_place_status [udm_get_prop [get_obj_by_name $cell_name] place_status]
    if {$cell_place_status == "unplaced"} {
        log_info $cell_name
    }
}
