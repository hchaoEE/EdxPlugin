set design_config(${design},tech_gdsmap) "${data_dir}/input/ASAP7/gds/asap7_fromAPR_08b.layermap"

set design_config(${design},apr_tech) "${data_dir}/input/ASAP7/tech/asap7_tech_4x_201209.tech"
set design_config(${design},lef_std) "
${data_dir}/input/ASAP7/lef/asap7sc7p5t_28_SL_4x_220121a.lef
${data_dir}/input/ASAP7/lef/asap7sc7p5t_28_R_4x_220121a.lef
${data_dir}/input/ASAP7/lef/asap7sc7p5t_28_L_4x_220121a.lef
"

set design_config(${design},gds_list) [list \
${data_dir}/input/ASAP7/gds/asap7sc7p5t_28_SL_220121a.gds \
${data_dir}/input/ASAP7/gds/asap7sc7p5t_28_R_220121a.gds \
${data_dir}/input/ASAP7/gds/asap7sc7p5t_28_L_220121a.gds \
]

set design_config(${design},lef_mem) "
"

set design_config(WorstLT_cworst_CCworst_T,${design},lib_std) "
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_SLVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_RVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_LVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_SLVT_SS_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_RVT_SS_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_LVT_SS_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_SLVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_RVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_LVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_SLVT_SS_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_RVT_SS_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_LVT_SS_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_SLVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_RVT_SS_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_LVT_SS_ccsn_211120.lib
"

set design_config(WorstLT_cworst_CCworst_T,${design},lib_mem) "
"

set design_config(TTLT_typical,${design},lib_std) "
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_SLVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_RVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SIMPLE_LVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_SLVT_TT_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_RVT_TT_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_SEQ_LVT_TT_ccsn_220123.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_SLVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_RVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_OA_LVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_SLVT_TT_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_RVT_TT_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_INVBUF_LVT_TT_ccsn_220122.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_SLVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_RVT_TT_ccsn_211120.lib
${data_dir}/input/ASAP7/lib/asap7sc7p5t_AO_LVT_TT_ccsn_211120.lib
"
set design_config(TTLT_typical,${design},lib_mem) "
"

set design_config(${design},activeSCN) "func_WorstLT_cworst_CCworst_T func_TTLT_typical"

set design_config(rc,${design},cworst_CCworst_T) "${data_dir}/input/ASAP7/Rctable/ASAP7_ss_40.rctbl.LedaEncrypt"
set design_config(rc,${design},typical) "${data_dir}/input/ASAP7/Rctable/ASAP7_tt_25.rctbl.LedaEncrypt"

set vars(apr,cts_icg)  "ICGx4_ASAP7_75t_L ICGx5_ASAP7_75t_L"
set vars(apr,cts_logic)  ""
set vars(apr,cts_ckinv)  "INVx6_ASAP7_75t_L INVx8_ASAP7_75t_L" 
set vars(apr,cts_driver_buf)  "INVx12_ASAP7_75t_L"
set vars(apr,cts_ckbuf)  "BUFx6f_ASAP7_75t_L BUFx8_ASAP7_75t_L BUFx10_ASAP7_75t_L BUFx12_ASAP7_75t_L"
set vars(apr,tie_cell)  "TIELOx1_ASAP7_75t_L TIEHIx1_ASAP7_75t_L"

set setup_scenario "func_WorstLT_cworst_CCworst_T func_TTLT_typical"
set hold_scenario "func_WorstLT_cworst_CCworst_T func_TTLT_typical"


set design_config(${design},lef) "$design_config(${design},lef_std)"
set design_config(WorstLT_cworst_CCworst_T,${design},lib) "$design_config(WorstLT_cworst_CCworst_T,${design},lib_std)"
set design_config(TTLT_typical,${design},lib) "$design_config(TTLT_typical,${design},lib_std)"

