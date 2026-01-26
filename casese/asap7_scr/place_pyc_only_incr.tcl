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
puts "=======start do  place=========="
place_design
opt_design -file_prefix place_incr -pre_cts -incremental -expanded_scenario -output_file_dir $rpt_dir/place_incr

source ${data_dir}/scr/unplace_some_cells.tcl

#pyc_reset_only_increment
#pyc_increment_placement
#place_legal -cell {u_macc_top/macc[0].u_macc/adder_out_reg[15] u_macc_top/macc[0].u_macc/adder_out_reg[14] u_macc_top/macc[0].u_macc/adder_out_reg[13] u_macc_top/macc[0].u_macc/adder_out_reg[12] u_macc_top/macc[0].u_macc/adder_out_reg[11] u_macc_top/macc[0].u_macc/adder_out_reg[10] u_macc_top/macc[0].u_macc/adder_out_reg[9] u_macc_top/macc[0].u_macc/adder_out_reg[8] u_macc_top/macc[0].u_macc/adder_out_reg[7] u_macc_top/macc[0].u_macc/adder_out_reg[6] u_macc_top/macc[0].u_macc/adder_out_reg[5] u_macc_top/macc[0].u_macc/adder_out_reg[4] u_macc_top/macc[0].u_macc/adder_out_reg[3] u_macc_top/macc[0].u_macc/adder_out_reg[2] u_macc_top/macc[0].u_macc/adder_out_reg[1] u_macc_top/macc[0].u_macc/adder_out_reg[0] u_macc_top/macc[0].u_macc/a_reg_reg[3] u_macc_top/macc[0].u_macc/a_reg_reg[2] u_macc_top/macc[0].u_macc/a_reg_reg[1] u_macc_top/macc[0].u_macc/a_reg_reg[0] u_macc_top/macc[0].u_macc/b_reg_reg[3] u_macc_top/macc[0].u_macc/b_reg_reg[2] u_macc_top/macc[0].u_macc/b_reg_reg[1] u_macc_top/macc[0].u_macc/b_reg_reg[0] u_macc_top/macc[0].u_macc/diff_reg_reg[4] u_macc_top/macc[0].u_macc/diff_reg_reg[3] u_macc_top/macc[0].u_macc/m_reg_reg[8] u_macc_top/macc[0].u_macc/m_reg_reg[7] u_macc_top/macc[0].u_macc/m_reg_reg[6] u_macc_top/macc[0].u_macc/m_reg_reg[5] u_macc_top/macc[0].u_macc/m_reg_reg[4] u_macc_top/macc[0].u_macc/m_reg_reg[3] u_macc_top/macc[0].u_macc/m_reg_reg[2] u_macc_top/macc[0].u_macc/m_reg_reg[0] u_macc_top/macc[0].u_macc/sload_reg_reg u_macc_top/macc[0].u_macc/diff_reg_reg[2] u_macc_top/macc[0].u_macc/diff_reg_reg[1] u_macc_top/macc[0].u_macc/diff_reg_reg[0] u_macc_top/macc[0].u_macc/U2 u_macc_top/macc[0].u_macc/U3 u_macc_top/macc[0].u_macc/U4 u_macc_top/macc[0].u_macc/U5 u_macc_top/macc[0].u_macc/U6 u_macc_top/macc[0].u_macc/U7 u_macc_top/macc[0].u_macc/U8 u_macc_top/macc[0].u_macc/U9 u_macc_top/macc[0].u_macc/U10 u_macc_top/macc[0].u_macc/U11 u_macc_top/macc[0].u_macc/U12 u_macc_top/macc[0].u_macc/U13 u_macc_top/macc[0].u_macc/U14 u_macc_top/macc[0].u_macc/U15 u_macc_top/macc[0].u_macc/U16 u_macc_top/macc[0].u_macc/U17 u_macc_top/macc[0].u_macc/U18 u_macc_top/macc[0].u_macc/U19 u_macc_top/macc[0].u_macc/U20 u_macc_top/macc[0].u_macc/U21 u_macc_top/macc[0].u_macc/U22 u_macc_top/macc[0].u_macc/U23 u_macc_top/macc[0].u_macc/U24 u_macc_top/macc[0].u_macc/U25 u_macc_top/macc[0].u_macc/U26 u_macc_top/macc[0].u_macc/U27 u_macc_top/macc[0].u_macc/U28 u_macc_top/macc[0].u_macc/U29 u_macc_top/macc[0].u_macc/U30 u_macc_top/macc[0].u_macc/U31 u_macc_top/macc[0].u_macc/U32 u_macc_top/macc[0].u_macc/U33 u_macc_top/macc[0].u_macc/U34 u_macc_top/macc[0].u_macc/U35 u_macc_top/macc[0].u_macc/U36 u_macc_top/macc[0].u_macc/U37 u_macc_top/macc[0].u_macc/U38 u_macc_top/macc[0].u_macc/U39 u_macc_top/macc[0].u_macc/U40 u_macc_top/macc[0].u_macc/U41 u_macc_top/macc[0].u_macc/U42 u_macc_top/macc[0].u_macc/U43 u_macc_top/macc[0].u_macc/U44 u_macc_top/macc[0].u_macc/U45 u_macc_top/macc[0].u_macc/U46 u_macc_top/macc[0].u_macc/U47 u_macc_top/macc[0].u_macc/U48 u_macc_top/macc[0].u_macc/U49 u_macc_top/macc[0].u_macc/U50 u_macc_top/macc[0].u_macc/U51 u_macc_top/macc[0].u_macc/U52 u_macc_top/macc[0].u_macc/U53 u_macc_top/macc[0].u_macc/U54 u_macc_top/macc[0].u_macc/U55 u_macc_top/macc[0].u_macc/U56 u_macc_top/macc[0].u_macc/U57 u_macc_top/macc[0].u_macc/U58 u_macc_top/macc[0].u_macc/U59 u_macc_top/macc[0].u_macc/U60 u_macc_top/macc[0].u_macc/U61 u_macc_top/macc[0].u_macc/U62 u_macc_top/macc[0].u_macc/U63}
place_legal

write_checkpoint $data_dir/dbs/${design}_place
write_checkpoint $data_dir/dbs/${design}_place_opt
set end_timestamp [clock seconds]
puts "========>Place time: [expr $end_timestamp - $start_timestamp] seconds"
report_utilization
report_timing_summary

