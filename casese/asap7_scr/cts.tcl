set_active_constraint_modes [get_all_constraint_modes -active]
set_analysis_scenario -setup $setup_scenario -hold $hold_scenario

foreach_in_col clk [get_all_clocks] {
    set period [get_attr $clk period]
    set_clock_uncertainty -setup [expr $period*0.05+150] $clk
}

remove_clock_tree_spec

#NDR Rule
create_ndr -width_scale {M3:M4 2} -name NDR_2W1S_rule
create_ndr -spacing_scale {M5:M7 2} -width_scale {M5:M7 2} -name NDR_2W2S_rule

set_clock_route_rule -ndr NDR_2W1S_rule -name trunk_ndr_route -prefer_min_metal M3 -prefer_max_metal M4 -prefer_metal_effort high
set_clock_route_rule -ndr NDR_2W2S_rule -name top_ndr_route -prefer_min_metal M5 -prefer_max_metal M7 -prefer_metal_effort high
set_clock_route_type trunk_ndr_route -trunk
set_clock_route_type top_ndr_route -top

#Clock Cells
set_cts_spec -attribute buffers $vars(apr,cts_ckbuf)
set_cts_spec -attribute inverters $vars(apr,cts_ckinv)
set_cts_spec -attribute clock_gates $vars(apr,cts_icg)

#foreach pin [get_object_name [get_pins -of_objects [get_cells -filter "is_memory_cell ==true" -hierarchical ] -filter is_clock]] {
#  set_cts_spec 0.1 -attribute pre_cts_delay -pin $pin
#}
#set_cts_spec -attribute sink_type -pin snps_occ_controller/fast_clk_clkgt/cg_latch_reg/EN ignore

set_cts_spec -attribute enable_use_inverter true
set_cts_spec -attribute max_fanout 24
set_cts_spec -attribute max_trans 150

create_clock_tree_spec

cts_opt -rpt_path $rpt_dir/cts

report_clock_tree_summary -delay_corners WorstLT_cworst_CCworst_T -file $rpt_dir/cts/clk_tree_info_func.rpt
report_cts_status -delay_corners WorstLT_cworst_CCworst_T -late -histogram -max_path 10  -file $rpt_dir/cts/clk_skew_group_func.rpt

set_clock_gating_check -setup 100
reset_clock_gating_check  [get_pins -hier */E -filter "is_hierarchical == false"]
reset_clock_gating_check  [get_pins -hier */TE -filter "is_hierarchical == false"]

opt_design -post_cts -incremental -file_prefix cts_incr -output_file_dir $rpt_dir/cts_incr

connect_global_net VDD -type pg -pin VDD -cell *
connect_global_net VSS -type pg -pin VSS -cell *

report_utilization
write_checkpoint $data_dir/dbs/${design}_cts

