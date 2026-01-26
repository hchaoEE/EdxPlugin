#
edit_pg_via -bottom_layer M1 -create_via 1 -top_layer M2 -disable_parallel_connect 0 -ignore_pin follow_pin

write_checkpoint $data_dir/dbs/${design}_final

#
write_lef -version 5.8 -pg_pin {M8 M9} -top_layer M9 ../output/$design.lef
#
write_def -routing ../output/$design.def.gz
#
set_cfg udm.gds_virtual_connect false
set_cfg udm.gds_anotation_size 0.2

write_gds ../output/$design.gds.gz -map $design_config(${design},tech_gdsmap) -merge $design_config(${design},gds_list) -lib $design -full_name $design -units 1000 -mode all -only_die

set FILL [get_obj_prop [udm_get_obj -type libcell -filter "name=FILLER*_ASAP7_*_*"] name]
set TAP "TAPCELL_ASAP7_75t_R"

write_verilog -include_phys -exclude_leaf -unfold_bus -exclude_cell "$FILL $TAP" ../output/$design.pg.v

extract_rc
write_spef -rc_corner typical ../output/$design.TT25_typical.spef.gz
write_spef -rc_corner cworst_CCworst_T ../output/$design.cworst_CCworst_T_m40.spef.gz

extract_timing_model -scenario func_TTLT_typical -out ../output/$design.lib

write_sdc ../output/$design.sdc

