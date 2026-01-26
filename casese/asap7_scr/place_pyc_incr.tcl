set_active_constraint_modes [get_all_constraint_modes -active]
set_analysis_scenario -setup $setup_scenario -hold $hold_scenario

remove_clock_trees *
remove_clock_tree_buffers

if {[file exists $data_dir/input/${design}.scan.def]} {
    read_def $data_dir/input/${design}.scan.def
}

#dont use
#set_user_dont_use *SL true

#clock uncertainty
foreach_in_col clk [get_all_clocks] {
    set period [get_attr $clk period]
    set_clock_uncertainty -setup [expr $period*0.05+250] $clk
}
set_clock_uncertainty -hold 30 [get_all_clocks]
set_clock_gating_check -setup 200
set_clock_gating_check -setup 200 [get_pins -hier */E -filter "is_hierarchical == false"]
set_clock_gating_check -setup 200 [get_pins -hier */TE -filter "is_hierarchical == false"]

set start_timestamp [clock seconds]
puts "=======start pyc place, initial placement 91.7% cells=========="
pyc_reset
pyc_global_placement 0.92
place_legal
opt_design -file_prefix place_incr -pre_cts -incremental -expanded_scenario -output_file_dir $rpt_dir/place_incr


puts "======iter1 begin: place 8% cells=========="
source $apicommon/place_report.tcl
pyc_reset_only_increment
pyc_increment_placement
place_legal
puts "======iter1 end: place 8% cells,total placed 100%=========="

write_checkpoint $data_dir/dbs/${design}_place
write_checkpoint $data_dir/dbs/${design}_place_opt

set end_timestamp [clock seconds]
puts "========>Place time: [expr $end_timestamp - $start_timestamp] seconds"
report_utilization
report_timing_summary


