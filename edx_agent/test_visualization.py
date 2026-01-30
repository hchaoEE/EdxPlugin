#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
测试visualization.py的示例脚本（matplotlib版本）
"""

import sys
import os
import re
import random
sys.path.append(os.path.dirname(__file__))

# 添加对edx_server模块的引用路径
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'edx_server'))

from visualization import Visualization
import numpy as np

# 导入必要的类和函数
try:
    from plugin_data import Design, Cell
    from tcl_sender import TCLSender
    HAS_EDA_DEPS = True
except ImportError as e:
    print(f"警告: 无法导入EDA相关模块: {e}")
    HAS_EDA_DEPS = False

def parse_netlist_result(result_lines):
    """
    解析TCL脚本返回的网表数据，复用main.py中的解析逻辑
    参数:
        result_lines: TCL脚本执行返回的结果行列表
    返回:
        Design对象
    """
    if not result_lines:
        raise ValueError("网表数据为空")
    
    my_design = Design()
    
    '''
    result列表中第2行design的core长宽，格式为：core_size: {78.12 69.192}，之后每4行一组，格式为
    u_macc_top/macc[0].u_macc/adder_out_reg[15] --cell name
    4.32 -- cell width
    1.08 --cell height
    u_macc_top/macc[0].u_macc/adder_out_reg[15]/QN|u_macc_top/macc[0].u_macc/adder_out_reg[15]/D --- all pins join with,
    '''
    
    # 解析核心尺寸
    core_line = result_lines[1]  # "core_size: {78.12 69.192}"
    match = re.search(r'\{([\d.]+)\s+([\d.]+)\}', core_line)
    if match:
        my_design.core_width = float(match.group(1))
        my_design.core_height = float(match.group(2))
    
    row_counter = 3
    # 解析cell信息
    for row_index in range(3, len(result_lines), 3):
        row_counter = row_index
        cell_name = result_lines[row_index].strip()
        if '======' in cell_name:
            break
        prop = result_lines[row_index + 1].strip().split(",")
        cell_width = float(prop[0])
        cell_height = float(prop[1])
        cell_orient = prop[2]
        cell_place_status = prop[3]
        loc_x = prop[4]
        loc_y = prop[5]
        pin_str = result_lines[row_index + 2].strip()
        pins = pin_str.split('|')
        for pin in pins:
            pin = pin.strip()
            if pin:  # 确保不是空字符串
                my_design.pin_to_cell[pin] = cell_name
        my_design.cells[cell_name] = Cell(cell_name, loc_x, loc_y, cell_width, cell_height, cell_orient,
                                          place_status=cell_place_status)
    
    # 解析网络信息
    for i in range(row_counter + 1, len(result_lines)):
        # 读取net
        net_info = result_lines[i].strip()
        if len(net_info) < 1:
            continue
        split = net_info.split(',')
        if len(split) < 3:
            print(f"[警告] net {split[0]} 缺少负载引脚或驱动引脚")
            continue
        net_name = split[0]
        load_pins = split[1].split('|')
        driver_pins = split[2].split('|')
        my_design.nets[net_name] = [load_pins, driver_pins]
    
    return my_design

def load_netlist_from_tcl(script_path):
    """
    通过TCL脚本加载网表数据
    参数:
        script_path: TCL脚本文件路径
    返回:
        Design对象
    """
    if not HAS_EDA_DEPS:
        raise RuntimeError("缺少必要的EDA依赖模块")
    
    # 执行TCL脚本获取网表数据
    tcl_sender = TCLSender()
    result = tcl_sender.send_tcl_file(script_path)
    
    # 解析网表数据
    design = parse_netlist_result(result)
    return design

def generate_test_data_with_colors(num_cells=1000):
    """生成带有颜色属性的测试数据"""
    cells = []
    core_width = 120.0
    core_height = 90.0
    
    # 定义颜色列表
    color_list = ['red', 'blue', 'green', 'orange', 'purple', 'brown', 'pink', 'gray', 'olive', 'cyan']
    
    # 生成不同区域的cells，每个区域使用不同颜色
    regions = [
        {'x_range': (0, 30), 'y_range': (0, 30), 'color': 'red'},      # 左下角 - 红色
        {'x_range': (30, 60), 'y_range': (0, 30), 'color': 'blue'},     # 中下部 - 蓝色
        {'x_range': (60, 90), 'y_range': (0, 30), 'color': 'green'},    # 右下部 - 绿色
        {'x_range': (90, 120), 'y_range': (0, 30), 'color': 'orange'},  # 右下角 - 橙色
        {'x_range': (0, 30), 'y_range': (30, 60), 'color': 'purple'},   # 左中部 - 紫色
        {'x_range': (30, 60), 'y_range': (30, 60), 'color': 'brown'},   # 中心 - 棕色
        {'x_range': (60, 90), 'y_range': (30, 60), 'color': 'pink'},    # 右中部 - 粉色
        {'x_range': (90, 120), 'y_range': (30, 60), 'color': 'gray'},   # 右中部 - 灰色
        {'x_range': (0, 60), 'y_range': (60, 90), 'color': 'olive'},    # 上半部左 - 橄榄色
        {'x_range': (60, 120), 'y_range': (60, 90), 'color': 'cyan'}    # 上半部右 - 青色
    ]
    
    cells_per_region = num_cells // len(regions)
    
    for region in regions:
        for i in range(cells_per_region):
            x = random.uniform(region['x_range'][0], region['x_range'][1])
            y = random.uniform(region['y_range'][0], region['y_range'][1])
            name = f"cell_{region['color']}_{i:03d}"
            color = region['color']
            cells.append((name, round(x, 3), round(y, 3), color))
    
    # 添加一些随机颜色的cells
    remaining_cells = num_cells - len(cells)
    for i in range(remaining_cells):
        x = random.uniform(0, core_width)
        y = random.uniform(0, core_height)
        name = f"cell_random_{i:03d}"
        color = random.choice(color_list)
        cells.append((name, round(x, 3), round(y, 3), color))
    
    # 打乱顺序
    random.shuffle(cells)
    
    return cells[:num_cells], core_width, core_height

def main():
    print("EDA芯片布局可视化测试 (Matplotlib版本)")
    print("=" * 50)
    
    try:
        # 创建可视化实例
        vis = Visualization()
        vis.cluster = "ASAP7_12nm_Test_Chip"
        
        # 生成带颜色的测试数据
        print("生成带颜色属性的测试数据...")
        cells, width, height = generate_test_data_with_colors(1200)
        
        # 设置核心尺寸
        vis.set_core_dimensions(width, height)
        
        # 添加cells
        vis.add_cells(cells)
        
        print(f"数据生成完成:")
        print(f"  - 芯片核心尺寸: {width:.3f} × {height:.3f} μm")
        print(f"  - Cell数量: {len(cells)}")
        print(f"  - 坐标精度: 小数点后3位")
        
        # 打印统计信息
        vis.print_statistics()
        
        # 生成综合可视化
        print("\n生成可视化图片...")
        output_files = vis.generate_comprehensive_visualization("test_chip_layout")
        
        if output_files:
            print(f"\n✓ 可视化测试成功完成!")
            print(f"生成的文件保存在当前目录:")
            for file in output_files:
                if os.path.exists(file):
                    size_kb = os.path.getsize(file) / 1024
                    print(f"  - {file} ({size_kb:.1f} KB)")
        else:
            print("✗ 可视化生成失败")
            
    except ImportError as e:
        print(f"导入错误: {e}")
        print("请确保已安装matplotlib和numpy:")
        print("pip install matplotlib numpy")
    except Exception as e:
        print(f"运行时错误: {e}")
        import traceback
        traceback.print_exc()

def vis_netlist(netlist_file:str, design_name:str,color = 'blue', special_cell_color = dict()) -> Design:
    print(f"EDA芯片布局可视化测试 (Matplotlib版本)--10% {design_name}")
    print("=" * 50)

    try:
        # 创建可视化实例
        vis = Visualization()
        vis.cluster = f"ASAP7_{design_name}"

        # 读取网表
        # 假设网表文件在 ../edx_server/apicommon/get_netlist.tcl
        netlist_script_path = netlist_file
        
        if not os.path.exists(netlist_script_path):
            print(f"错误: 网表脚本文件不存在: {netlist_script_path}")
            return
            
        print(f"正在读取网表文件: {netlist_script_path}")
        
        # 加载网表数据
        v_data = []
        with open (netlist_script_path, "r") as f:
            v_data.extend(f.readlines())
        design = parse_netlist_result(v_data)
        
        print(f"网表加载完成:")
        print(f"  - 核心尺寸: {design.core_width:.3f} × {design.core_height:.3f} μm")
        print(f"  - Cell数量: {len(design.cells)}")
        
        # 转换为可视化需要的格式 (name, x, y, color)
        cells = []
        for cell_name, cell_obj in design.cells.items():
            # 从cell对象中提取坐标信息
            x = float(cell_obj.x) if isinstance(cell_obj.x, (int, float, str)) else 0.0
            y = float(cell_obj.y) if isinstance(cell_obj.y, (int, float, str)) else 0.0
            if 'TAP' in cell_name or 'CAP' in cell_name:
                continue
            # 使用cell对象的颜色属性，如果未设置则使用默认蓝色
            cells.append((cell_name, x, y, special_cell_color.get(cell_name, color)))

        # 设置核心尺寸
        vis.set_core_dimensions(design.core_width, design.core_height)

        # 添加cells
        vis.add_cells(cells)

        print(f"数据转换完成:")
        print(f"  - 芯片核心尺寸: {design.core_width:.3f} × {design.core_height:.3f} μm")
        print(f"  - Cell数量: {len(cells)}")
        print(f"  - 坐标精度: 小数点后3位")

        # 打印统计信息
        vis.print_statistics()

        # 生成综合可视化
        print("\n生成可视化图片...")
        output_files = vis.generate_comprehensive_visualization(design_name)

        if output_files:
            print(f"\n✓ 可视化测试成功完成!")
            print(f"生成的文件保存在当前目录:")
            for file in output_files:
                if os.path.exists(file):
                    size_kb = os.path.getsize(file) / 1024
                    print(f"  - {file} ({size_kb:.1f} KB)")
        else:
            print("✗ 可视化生成失败")
        return design
    except ImportError as e:
        print(f"导入错误: {e}")
        print("请确保已安装matplotlib和numpy:")
        print("pip install matplotlib numpy")
    except Exception as e:
        print(f"运行时错误: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    del_deign = vis_netlist('/tmp/server_result_del.txt','top_del', color='red')
    cell_color = dict()
    for cell in del_deign.cells:
        cell_color[cell] = 'red'
    vis_netlist('/tmp/server_result.txt', 'top_total', special_cell_color=cell_color)