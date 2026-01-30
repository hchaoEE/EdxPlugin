# EDA芯片布局可视化工具使用说明

## 功能概述

本工具提供EDA芯片布局的可视化功能，能够：
- 显示所有cell在芯片核心区域中的位置分布
- 生成高质量的PNG格式布局图片
- **支持每个cell自定义颜色显示**
- 提供密度热力图分析
- 输出详细的布局统计信息

## 安装依赖

```bash
pip install matplotlib numpy
```

## 核心特性

### Cell颜色自定义
每个cell可以指定自己的颜色属性：
- 在Cell对象中添加`color`属性（默认为'blue'）
- 可视化时自动使用每个cell的颜色
- 支持所有matplotlib认可的颜色名称和十六进制颜色码

## 基本使用方法

### 1. 导入和初始化

```python
from visualization import Visualization

# 创建可视化实例
vis = Visualization()
vis.cluster = "你的芯片名称"

# 设置芯片核心尺寸（单位：微米）
vis.set_core_dimensions(width=100.0, height=80.0)
```

### 2. 添加带颜色的布局数据

```python
# 添加单个带颜色的cell
vis.add_cell("inv_001", 25.123, 30.456, "red")      # 红色反相器
vis.add_cell("buf_002", 45.789, 60.234, "green")    # 绿色缓冲器
vis.add_cell("nand2_003", 12.345, 78.901, "blue")   # 蓝色与非门

# 批量添加带颜色的cells
cells_data = [
    ("inv_001", 25.123, 30.456, "red"),
    ("buf_002", 45.789, 60.234, "green"), 
    ("nand2_003", 12.345, 78.901, "blue"),
    ("sram_001", 50.000, 40.000, "gold"),   # 金色存储器
    ("io_pad_001", 5.000, 5.000, "#FF6B35"), # 自定义橙色IO
    # ... 更多cell数据
]
vis.add_cells(cells_data)
```

### 3. 生成可视化图片

```python
# 生成布局图（自动使用每个cell的颜色）
vis.visualize_placement(
    figsize=(12, 10),    # 图片尺寸
    dpi=200,             # 分辨率
    show_labels=False,   # 是否显示cell标签
    output_file="colored_layout.png"  # 输出文件名
)

# 生成综合可视化报告
vis.generate_comprehensive_visualization("my_chip")
```

## Cell数据格式

### 带颜色的Cell数据格式
每个cell需要提供四个信息：
- `name` (str): cell名称
- `x` (float): X坐标（微米，精度到小数点后3位）
- `y` (float): Y坐标（微米，精度到小数点后3位）
- `color` (str): 颜色（支持颜色名称或十六进制码）

### 支持的颜色格式
```python
# 颜色名称
colors = ['red', 'blue', 'green', 'orange', 'purple', 'brown', 
          'pink', 'gray', 'olive', 'cyan', 'gold', 'navy', 'maroon']

# 十六进制颜色码
hex_colors = ['#FF0000', '#0000FF', '#00FF00', '#FFA500', '#800080']

# RGB元组 (0-1范围)
rgb_colors = [(1.0, 0.0, 0.0), (0.0, 0.0, 1.0), (0.0, 1.0, 0.0)]
```

### 示例数据
```python
# 按功能类型分配颜色
logic_cells = [
    ("inv_x1_001", 10.5, 20.3, "red"),      # 反相器 - 红色
    ("buf_x2_002", 15.2, 25.1, "green"),    # 缓冲器 - 绿色
    ("nand2_x1_003", 12.8, 30.7, "blue"),   # 与非门 - 蓝色
]

memory_cells = [
    ("sram_bank0_row0_col0", 50.0, 40.0, "gold"),    # SRAM - 金色
    ("sram_bank0_row0_col1", 55.0, 40.0, "gold"),
]

io_cells = [
    ("io_input_pad_001", 5.0, 5.0, "magenta"),  # 输入IO - 洋红色
    ("io_output_pad_002", 95.0, 75.0, "cyan"),  # 输出IO - 青色
]
```

## 输出文件说明

### 1. 布局图 (placement.png)
- 显示芯片核心区域边界
- **每个cell按其指定颜色显示**
- 包含坐标轴、图例和统计信息
- 分辨率可调（建议150-300 DPI）

### 2. 密度图 (density.png)
- 彩色热力图显示cell分布密度
- 红色区域表示高密度，黄色表示低密度
- 帮助识别布局热点区域

### 3. 统计信息增强
新增颜色分布统计：
```
=== 布局统计报告 ===
芯片簇: Test_Chip
核心尺寸: 100.000 × 80.000 μm
总面积: 8000.000 μm²
Cell总数: 150

颜色分布:
  blue: 50 (33.3%)
  red: 30 (20.0%)
  green: 25 (16.7%)
  gold: 20 (13.3%)
  purple: 15 (10.0%)
  orange: 10 (6.7%)
```

## 高级功能

### 1. 从Design对象转换
```python
# 从网表解析得到的Design对象转换为可视化数据
def convert_design_to_visualization_data(design):
    vis_cells = []
    for cell_name, cell_obj in design.cells.items():
        x = float(cell_obj.x)
        y = float(cell_obj.y)
        color = getattr(cell_obj, 'color', 'blue')  # 获取颜色属性，缺省为蓝色
        vis_cells.append((cell_name, x, y, color))
    return vis_cells

# 使用示例
design = load_netlist_from_tcl("get_netlist.tcl")
vis_data = convert_design_to_visualization_data(design)

vis = Visualization()
vis.set_core_dimensions(design.core_width, design.core_height)
vis.add_cells(vis_data)
vis.generate_comprehensive_visualization("netlist_visualization")
```

### 2. 动态颜色分配
```python
# 根据cell类型动态分配颜色
def assign_colors_by_type(cell_name):
    type_colors = {
        'inv': 'red',
        'buf': 'green', 
        'nand': 'blue',
        'nor': 'orange',
        'dff': 'purple',
        'sram': 'gold',
        'io': 'magenta'
    }
    
    for type_prefix, color in type_colors.items():
        if cell_name.startswith(type_prefix):
            return color
    return 'gray'  # 默认颜色

# 应用到数据
colored_cells = []
for name, x, y in original_cells:
    color = assign_colors_by_type(name)
    colored_cells.append((name, x, y, color))
```

### 3. 区域颜色编码
```python
# 根据位置区域分配颜色
def get_region_color(x, y, core_width, core_height):
    # 将芯片划分为4个象限
    if x < core_width/2 and y < core_height/2:
        return 'red'      # 左下
    elif x >= core_width/2 and y < core_height/2:
        return 'blue'     # 右下
    elif x < core_width/2 and y >= core_height/2:
        return 'green'    # 左上
    else:
        return 'orange'   # 右上

# 应用到数据
colored_cells = []
for name, x, y in cells:
    color = get_region_color(x, y, core_width, core_height)
    colored_cells.append((name, x, y, color))
```

## 实际应用示例

### 示例1：层次化设计可视化
```python
from visualization import Visualization

# 不同层级使用不同颜色
hierarchical_colors = {
    'top_level': 'red',
    'sub_module_a': 'blue', 
    'sub_module_b': 'green',
    'memory_block': 'gold',
    'io_interface': 'magenta'
}

vis = Visualization()
vis.cluster = "hierarchical_design"
vis.set_core_dimensions(200.0, 150.0)

# 添加不同层级的cells
for module_name, cells in design_modules.items():
    color = hierarchical_colors.get(module_name, 'gray')
    for cell_data in cells:
        name, x, y = cell_data
        vis.add_cell(name, x, y, color)

vis.generate_comprehensive_visualization("hierarchical_layout")
```

### 示例2：时序违例可视化
```python
# 将时序违例的cells标记为红色，正常cells为蓝色
def visualize_timing_violations(cells_with_slack):
    vis = Visualization()
    vis.cluster = "timing_analysis"
    vis.set_core_dimensions(100.0, 80.0)
    
    for cell_name, x, y, slack in cells_with_slack:
        if slack < 0:  # 违例
            color = 'red'
        elif slack < 0.1:  # 接近违例
            color = 'orange'
        else:  # 正常
            color = 'blue'
        vis.add_cell(cell_name, x, y, color)
    
    vis.generate_comprehensive_visualization("timing_violations")
```

## 注意事项

1. **颜色一致性**: 建议同一类型的cell使用相同颜色以便识别
2. **颜色对比度**: 确保相邻区域的颜色有足够的对比度
3. **坐标精度**: 保持3位小数精度
4. **文件大小**: 高DPI设置会产生较大的PNG文件
5. **内存使用**: 大规模设计（>10000 cells）可能需要较多内存

## 故障排除

### 常见问题

1. **颜色显示异常**
   - 检查颜色字符串格式是否正确
   - 确认使用的颜色名称被matplotlib支持

2. **所有cell显示为蓝色**
   - 检查是否正确传递了颜色参数
   - 确认cell数据格式为 (name, x, y, color)

3. **颜色分布统计不准确**
   - 检查是否有重复的cell名称
   - 确认颜色属性正确设置

## 测试验证

运行专门的颜色测试脚本：
```bash
# 测试基本颜色功能
python test_cell_colors.py

# 测试综合功能
python test_visualization.py

# 测试网表解析集成
python test_netlist_parsing.py
```

## 扩展功能建议

1. **渐变色彩**: 根据cell属性（如功耗、面积）使用颜色渐变
2. **透明度控制**: 根据重要性调整cell的透明度
3. **形状区分**: 不同类型的cell使用不同形状
4. **交互式查看**: 添加点击查看详情的功能
5. **动画展示**: 展示布局优化过程的动画