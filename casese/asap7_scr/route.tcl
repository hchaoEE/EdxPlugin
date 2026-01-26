set_active_constraint_modes [get_all_constraint_modes -active]
set_analysis_scenario -setup $setup_scenario -hold $hold_scenario

foreach_in_col clk [get_all_clocks] {
    set period [get_attr $clk period]
    set_clock_uncertainty -setup [expr $period*0.05+50] $clk
}

delete_route_shape -type Special -layer VIA1

set_cfg -reset phy_cell.tie_cell
set_cfg phy_cell.tie_cell.name "$vars(apr,tie_cell)"
set_cfg phy_cell.tie_cell.max_distance 50
set_cfg phy_cell.tie_cell.max_fanout 3
set_cfg phy_cell.tie_cell.prefix add_TieCell
create_tie_cell


set_cfg droute.post_route_swap_via none
set_cfg droute.enable_adv_post_eco_via_swap false
set_cfg droute.multi_cut_strength default
set_cfg rcx.flow post_route
set_cfg sta.delay_with_si true

route_opt -file_prefix route_opt -output_dir $rpt_dir/route_opt

write_checkpoint $data_dir/dbs/${design}_route_opt

opt_design -post_route -incremental -rpt_file_prefix postroute_opt -expanded_scenario -output_file_dir $rpt_dir/postroute_opt

connect_global_net VDD -type pg -pin VDD -force -cell *
connect_global_net VSS -type pg -pin VSS -force -cell *
connect_global_net VSS -type tielo -cell *
connect_global_net VDD -type tiehi -cell *
connect_global_net VSS -type net -net VSS
connect_global_net VDD -type net -net VDD

report_utilization
write_checkpoint $data_dir/dbs/${design}_postroute_opt

