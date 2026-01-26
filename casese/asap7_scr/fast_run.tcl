source ../scr/flow_setup.tcl

read_checkpoint ../dbs/${design}_place.db

source ${data_dir}/scr/tech_cfg/cfg_setting.tcl

#source ${data_dir}/scr/init_plan.tcl
#source ${data_dir}/scr/place.tcl
source ${data_dir}/scr/cts.tcl
source ${data_dir}/scr/route.tcl
#source ${data_dir}/scr/add_filler.tcl
#source ${data_dir}/scr/export_gds.tcl
#exit
