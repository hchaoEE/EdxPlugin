set_multi_threads -local_threads 8

source ${data_dir}/scr/init_set.tcl

set_cfg udm.need_uniquify 1
set_rc_config -flow leda_rctbl
read_tech $design_config($design,apr_tech)
read_lef $design_config($design,lef)
read_mcmm ${data_dir}/scr/mmmc.tcl
read_verilog $design_config($design,netlist)
set_cfg udm.groud_net VSS
set_cfg udm.power_net VDD

bind_design

source ${data_dir}/scr/tech_cfg/cfg_setting.tcl

#group path
reset_path_group -all
create_path_groups -include_io_path

group_path -name reg2mem -from [get_all_registers] -to [get_cells -hier -filter "is_memory_cell ==true"]
group_path -name mem2reg -from [get_cells -hier -filter "is_memory_cell ==true"] -to [get_all_registers]
group_path -name in2clkgate  -from [all_inputs]  -to [filter_collection [get_all_registers] "is_integrated_clock_gating_cell == true"]
group_path -name REG2REG -from [get_cells [add_to_collection [get_all_registers -flops] [get_all_registers -latches]]] -to [get_cells [add_to_collection [get_all_registers -flops] [get_all_registers -latches]]]
set_path_group_configs reg2cgate  -effort high   -weight 5   -adjust_slack 0
set_path_group_configs in2clkgate -effort low    -weight 5   -adjust_slack 0
set_path_group_configs reg2mem    -effort high   -weight 5   -adjust_slack 0
set_path_group_configs mem2reg    -effort high   -weight 5   -adjust_slack 0
set_path_group_configs reg2reg    -effort high   -weight 5   -adjust_slack 0
set_path_group_configs REG2REG    -effort high   -weight 10  -adjust_slack 0
set_path_group_configs in2reg     -effort low    -weight 1   -adjust_slack 0
set_path_group_configs reg2out    -effort low    -weight 1   -adjust_slack 0
set_path_group_configs in2out     -effort low    -weight 1   -adjust_slack 0

write_checkpoint $data_dir/dbs/${design}_init

create_floorplan -core_margins_by die -site asap7sc7p5t -create_by_density {0.9 0.5 1.08 1.08 1.08 1.08}
modify_floorplan -core_to_die_edge 1.08 1.08 1.08 1.08
set_cfg plan.pin_assignment_batch_mode true
edit_pin -spread_mode CENTER -edge 1 -layer M5 -pins *
set_cfg plan.pin_assignment_batch_mode false

remove_halo -all_block
create_halo 1 1 1 1 -all_block

set_cfg plan.channel_blkgs_target_objects {macro macro_halo core fence hard_blkg soft_blkg partial_blkg}
set_cfg plan.channel_blkgs_direction xy
set_cfg plan.channel_blkgs_overwrite false
create_channel_blockage	-prefix FP_FILL_SOFT -create_place_blockage soft 20
create_channel_blockage	-prefix FP_FILL_PAR -create_place_blockage partial 50 -density 60

set_cfg plan.channel_blkgs_target_objects {macro macro_halo core hard_blkg}
set_cfg plan.channel_blkgs_direction y
create_channel_blockage	-prefix FP_FILL_HARD -create_place_blockage hard 5
set_cfg plan.channel_blkgs_direction x
create_channel_blockage	-prefix FP_FILL_HARD -create_place_blockage hard 5

set_cell_placement_status -all_hard_macros -status fixed
fix_all_ios

snap_floorplan -all
verify_floorplan

write_checkpoint $data_dir/dbs/${design}_fp

remove_filler -cells ENDCAP*
remove_filler -cells WELLTAP*

### add endcap/welltap
set_cfg phy_cell.boundary.left_edge [get_obj_prop [udm_get_obj -type libcell -filter "name=DECAP*_ASAP7_75t_R"] name]
set_cfg phy_cell.boundary.right_edge [get_obj_prop [udm_get_obj -type libcell -filter "name=DECAP*_ASAP7_75t_R"] name]
create_boundary -prefix ENDCAP

create_well_tap -cell [get_obj_prop [udm_get_obj -type libcell -filter "name=TAPCELL_ASAP7_75t_R"] name] -spacing 50 -offset 10.564 -prefix WELLTAP

connect_global_net VDD -type pg -pin VDD -cell *
connect_global_net VSS -type pg -pin VSS -cell *

source ${data_dir}/scr/tech_cfg/power.tcl

report_utilization
write_checkpoint $data_dir/dbs/${design}_pg

write_def $data_dir/output/${design}_init_pg.def
write_verilog $data_dir/output/${design}_init_pg.v

