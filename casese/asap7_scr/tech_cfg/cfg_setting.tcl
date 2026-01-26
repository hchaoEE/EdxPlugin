set_cfg -reset design_mode
set_cfg -reset place
set_cfg -reset route

set_cfg udm.design_effort_flow medium
set_cfg udm.design_process 7
set_cfg udm.design_bottom_routing_layer "M2"
set_cfg udm.design_top_routing_layer "M7"
set_cfg rcx.enable_layer_independent_extraction 1
set_cfg rcx.enable_consider_def_via_cap true
set_cfg opt.enable_opt_all_end_points true
set_cfg sta.clock_prop_mode sdc_ctrl
set_cfg sta.enable_clock_gating_check true
set_cfg opt.max_wire_length 300
set_cfg plan.drc_region_object "macro hard_blkg macro_halo min_gap core_spacing"
set_cfg	opt.max_density 0.65
set_cfg	opt.max_local_density 0.7
set_cfg place.enable_auto_padding true
set_cfg opt.area_opt_mode true
set_cfg opt.mbff_mode false
set_cfg place.gp_skip_scan_net true
set_cfg sta.crpr_analysis_mode both
set_cfg sta.op_analysis_type on_chip_variation
set_cfg sta.delay_with_si true
set_cfg cts.max_skew 100
set_cfg cts.max_top_trunk_trans 100
set_cfg cts.enable_route_clock_net true
set_cfg route.min_shield_layer_num 3
set_cfg droute.max_iteration_num 20
set_cfg route.via_in_pin true
set_cfg route.std_cell_pin_via_only true
set_cfg rcx.flow pre_route
set_cfg	opt.report_timing_path_number 1000

