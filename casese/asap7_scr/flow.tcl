source ../scr/flow_setup.tcl

set EDX_INSTANCE_ID $env(EDX_INSTANCE_ID)
set EDX_PLUGIN_HOME $env(EDX_PLUGIN_HOME)
set EDX_TMP_BASE $env(EDX_TMP_BASE)
set EDX_TMP $EDX_TMP_BASE/tmp_$EDX_INSTANCE_ID
set EDX_HTTP_PORT $env(EDX_HTTP_PORT)

read_checkpoint /data/wskyp/cases/top_ASAP7_tool/dbs/top_place_opt.db

#source ${data_dir}/scr/init.tcl
#source ${data_dir}/scr/place.tcl
source ${EDX_PLUGIN_HOME}/edx_server/apicommon/eda_command_listener.tcl
#source ${data_dir}/scr/cts.tcl
#source ${data_dir}/scr/route.tcl
#source ${data_dir}/scr/add_filler.tcl
#source ${data_dir}/scr/output_data.tcl
