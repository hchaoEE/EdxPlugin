# ASAP7填充单元添加脚本
# 该脚本用于在设计中添加填充单元

# 定义填充单元列表
set FILL "DECAPx10_ASAP7_75t_R DECAPx6_ASAP7_75t_R DECAPx4_ASAP7_75t_R FILLER_ASAP7_75t_R FILLERxp5_ASAP7_75t_R FILLER_ASAP7_75t_L FILLERxp5_ASAP7_75t_L FILLER_ASAP7_75t_SL FILLERxp5_ASAP7_75t_SL"

# 创建填充单元
create_filler -lib_cells $FILL -prefix add_fill_cell