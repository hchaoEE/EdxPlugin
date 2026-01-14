set data_dir [file dirname [pwd]]
set design top
set out_dir ${data_dir}/output
set rpt_dir ${data_dir}/reports
set apicommon ${data_dir}/apicommon
set edx_plugin_dir $env(EdxPluginPath)
set api_dir ${edx_plugin_dir}/tmp
set enable_debug 0

set design_config(${design},netlist) "${data_dir}/input/NETLIST/${design}.v"
set design_config(${design},def) "${data_dir}/input/DEF/${design}.def"
set design_config(${design},sdc) "${data_dir}/input/SDC/${design}.sdc"

source ${data_dir}/scr/init_set.tcl

set_multi_threads -local_threads 8

