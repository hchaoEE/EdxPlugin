"""
EDA工具配置文件
定义不同EDA工具的默认参数和配置
"""
import os

# 默认配置
# EDX_TMP根据环境变量instance_id设置
edx_tmp = os.environ.get('EDX_TMP_BASE', '')
if edx_tmp == '':
    raise Exception('EDX_TMP环境变量未设置')
DEFAULT_CONFIG = {
    'edx_tmp': f'{edx_tmp}/tmp_{os.environ.get("EDX_INSTANCE_ID", "1")}',
}
os.makedirs(edx_tmp, exist_ok=True)
os.makedirs(DEFAULT_CONFIG.get('edx_tmp'), exist_ok=True)