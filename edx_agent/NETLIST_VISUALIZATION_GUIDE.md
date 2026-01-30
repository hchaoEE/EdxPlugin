# EDA网表可视化使用指南

## 功能概述

本工具可以从TCL脚本读取网表数据，并将其可视化为芯片布局图和密度分布图。

## 核心组件

### 1. 网表解析功能
- **文件**: `test_visualization.py`
- **核心函数**: `parse_netlist_result()` 和 `load_netlist_from_tcl()`
- **功能**: 解析TCL脚本返回的网表数据，转换为Design对象

### 2. 可视化功能
- **文件**: `visualization.py`
- **核心类**: `Visualization`
- **功能**: 生成PNG格式的布局图和密度图

## 使用方法

### 方法一：直接调用vis_del函数（推荐）

```python
# 在test_visualization.py中已经实现了vis_del函数
# 直接运行即可
python test_visualization.py
```

该函数会：
1. 自动查找网表脚本文件（`../edx_server/apicommon/get_netlist.tcl`）
2. 执行TCL脚本获取网表数据
3. 解析网表数据为Design对象
4. 转换为可视化所需的格式
5. 生成布局图和密度图

### 方法二：手动调用解析函数

```python
from test_visualization import load_netlist_from_tcl, parse_netlist_result

# 方式1：直接从TCL脚本加载
script_path = "../edx_server/apicommon/get_netlist.tcl"
design = load_netlist_from_tcl(script_path)

# 方式2：如果有TCL执行结果，直接解析
# result = tcl_sender.send_tcl_file(script_path)
# design = parse_netlist_result(result)
```

## 数据格式说明

### 输入格式（TCL脚本返回）
```
=======design_info=======
core_size: {78.12 69.192}
=======cell_info=======
cell_name_1
width,height,orient,place_status,x,y
pin1|pin2|pin3
cell_name_2
width,height,orient,place_status,x,y
pin1|pin2
=======net_info=======
net1,load_pin1|load_pin2,driver_pin1
net2,load_pin3,driver_pin2|driver_pin3
```

### 输出格式（Design对象）
- `core_width`, `core_height`: 芯片核心尺寸
- `cells`: 字典，键为cell名称，值为Cell对象
- `nets`: 字典，键为网络名称，值为[load_pins, driver_pins]列表
- `pin_to_cell`: 字典，键为引脚名称，值为所属cell名称

## 生成的文件

运行成功后会生成两个PNG文件：
- `test_chip_layout_placement.png`: 芯片布局图
- `test_chip_layout_density.png`: 密度分布热力图

## 环境要求

1. **Python依赖**:
   ```bash
   pip install matplotlib numpy
   ```

2. **EDA环境变量**:
   - `EDX_TMP_BASE`: 临时文件目录
   - `EDX_INSTANCE_ID`: 实例ID

3. **文件结构**:
   ```
   project/
   ├── edx_server/
   │   ├── apicommon/
   │   │   └── get_netlist.tcl  # 网表脚本
   │   ├── plugin_data.py       # 数据结构定义
   │   └── tcl_sender.py        # TCL执行器
   └── edx_agent/
       ├── visualization.py      # 可视化类
       └── test_visualization.py # 测试脚本
   ```

## 故障排除

### 常见问题

1. **找不到TCL脚本文件**
   - 检查文件路径是否正确
   - 确认`get_netlist.tcl`存在于正确位置

2. **TCL执行失败**
   - 检查EDA环境变量是否设置
   - 确认TCL脚本语法正确

3. **解析数据格式错误**
   - 检查TCL脚本输出格式是否符合预期
   - 确认返回数据包含完整的设计信息

4. **可视化生成失败**
   - 检查matplotlib是否正确安装
   - 确认有足够的磁盘空间保存图片

### 调试建议

```python
# 启用详细日志
import logging
logging.basicConfig(level=logging.DEBUG)

# 测试单个功能
from test_netlist_parsing import test_netlist_parsing
test_netlist_parsing()
```

## 扩展功能

可以根据需要扩展以下功能：
- 支持不同的网表格式
- 添加更多可视化选项（颜色编码、标签显示等）
- 支持批量处理多个设计
- 集成到更大的EDA工作流中