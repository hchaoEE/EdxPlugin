###########################################################################################################
######  2018/08/23  Start to track script change in header 
###########################################################################################################

#func_WorstLT_cworst_CCworst_T
create_library_set -name WorstLT \
-timing  $design_config(WorstLT_cworst_CCworst_T,${design},lib)

create_rc_corner -name cworst_CCworst_T \
	-temperature -40 \
	-pre_route_res_factor 1.1 \
	-post_route_res_factor 1.1 \
	-pre_route_cap_factor 1.1 \
	-post_route_cap_factor 1.1 \
	-post_route_coupling_cap_factor 1.1 \
	-pre_route_clk_res_factor 1.1 \
	-pre_route_clk_cap_factor 1.1 \
	-rc_table $design_config(rc,${design},cworst_CCworst_T)

create_delay_corner -name WorstLT_cworst_CCworst_T \
	-library_set WorstLT \
	-rc_corner cworst_CCworst_T

create_constraint_mode -name func \
	-sdc_file $design_config(${design},sdc)

create_analysis_scenario -name func_WorstLT_cworst_CCworst_T -constraint_mode func -delay_corner WorstLT_cworst_CCworst_T

#func_TTLT_typical
create_library_set -name TTLT \
-timing  $design_config(TTLT_typical,${design},lib)

create_rc_corner -name typical \
	-temperature 25 \
	-pre_route_res_factor 1.1 \
	-post_route_res_factor 1.1 \
	-pre_route_cap_factor 1.1 \
	-post_route_cap_factor 1.1 \
	-post_route_coupling_cap_factor 1.1 \
	-pre_route_clk_res_factor 1.1 \
	-pre_route_clk_cap_factor 1.1 \
	-rc_table $design_config(rc,${design},typical)

create_delay_corner -name TTLT_typical \
	-library_set TTLT \
	-rc_corner typical

create_constraint_mode -name func \
	-sdc_file $design_config(${design},sdc)

create_analysis_scenario -name func_TTLT_typical -constraint_mode func -delay_corner TTLT_typical

#######################################################################
set_analysis_scenario -setup $setup_scenario -hold $hold_scenario
