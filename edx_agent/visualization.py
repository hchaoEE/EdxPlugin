# 这个类提供placement各种可视化展示
import matplotlib.pyplot as plt
import matplotlib.patches as patches
from typing import List, Tuple, Dict, Optional, Callable
import numpy as np
import os
import random

class Visualization:
    def __init__(self):
        self.cells: List[Tuple[str, float, float, str]] = []  # (name, x, y, color)
        self.core_width: float = 0.0
        self.core_height: float = 0.0
        self.cluster: str = ""
        # 设置中文字体支持
        plt.rcParams['font.sans-serif'] = ['SimHei', 'Arial Unicode MS', 'DejaVu Sans']
        plt.rcParams['axes.unicode_minus'] = False
    
    def set_core_dimensions(self, width: float, height: float):
        """设置芯片核心区域的尺寸"""
        self.core_width = width
        self.core_height = height
    
    def add_cell(self, name: str, x: float, y: float, color: str = 'blue'):
        """添加单个cell"""
        self.cells.append((name, x, y, color))
    
    def add_cells(self, cells: List[Tuple[str, float, float, str]]):
        """批量添加cells"""
        self.cells.extend(cells)
    
    def clear_cells(self):
        """清空所有cells"""
        self.cells.clear()
    
    def visualize_placement(self, figsize=(12, 10), dpi=150, show_labels=False, 
                          output_file=None):
        """
        可视化cell布局并生成PNG图片，使用cell自带的颜色属性
        
        参数:
        figsize: 图形大小 (宽度, 高度)
        dpi: 图形分辨率
        show_labels: 是否显示cell标签
        output_file: 输出文件名，如果为None则显示图形
        """
        if not self.cells:
            print("警告: 没有cell数据可供可视化")
            return None
        
        if self.core_width <= 0 or self.core_height <= 0:
            print("警告: 芯片核心尺寸未设置或无效")
            return None
        
        # 提取坐标和颜色数据
        cell_positions = [(x, y) for _, x, y, _ in self.cells]
        cell_colors = [color for _, _, _, color in self.cells]
        x_coords, y_coords = zip(*cell_positions)
        
        # 创建图形和轴
        fig, ax = plt.subplots(1, 1, figsize=figsize, dpi=dpi)
        
        # 绘制芯片核心区域边界
        core_rect = patches.Rectangle((0, 0), self.core_width, self.core_height, 
                                    linewidth=2, edgecolor='black', facecolor='none', 
                                    label='Core Boundary')
        ax.add_patch(core_rect)
        
        # 绘制所有cells（使用cell自带的颜色）
        scatter = ax.scatter(x_coords, y_coords, c=cell_colors, s=30, alpha=0.7, 
                           marker='o', label=f'Cells ({len(self.cells)})')
        
        # 如果需要显示标签（只显示前100个避免过于拥挤）
        if show_labels and len(self.cells) <= 100:
            for i, (name, x, y, _) in enumerate(self.cells[:100]):
                ax.annotate(name, (x, y), xytext=(3, 3), textcoords='offset points', 
                          fontsize=6, alpha=0.8, color='darkblue')
        
        # 设置图形属性
        margin_x = self.core_width * 0.05
        margin_y = self.core_height * 0.05
        ax.set_xlim(-margin_x, self.core_width + margin_x)
        ax.set_ylim(-margin_y, self.core_height + margin_y)
        ax.set_aspect('equal')
        ax.set_xlabel('X坐标 (μm)', fontsize=12)
        ax.set_ylabel('Y坐标 (μm)', fontsize=12)
        ax.set_title(f'芯片布局可视化 - {self.cluster}\n'
                    f'核心尺寸: {self.core_width:.3f} × {self.core_height:.3f} μm\n'
                    f'Cell数量: {len(self.cells)}', fontsize=14, pad=20)
        ax.grid(True, alpha=0.3)
        ax.legend()
        
        # 添加统计信息文本框
        stats_text = f'布局统计:\n'
        stats_text += f'• 总cell数: {len(self.cells)}\n'
        stats_text += f'• X范围: {min(x_coords):.3f} ~ {max(x_coords):.3f} μm\n'
        stats_text += f'• Y范围: {min(y_coords):.3f} ~ {max(y_coords):.3f} μm\n'
        stats_text += f'• 密度: {len(self.cells)/(self.core_width*self.core_height):.2f} cells/μm²'
        
        ax.text(0.02, 0.98, stats_text, transform=ax.transAxes, 
                verticalalignment='top', bbox=dict(boxstyle='round,pad=0.5', 
                facecolor='lightblue', alpha=0.8), fontsize=9)
        
        plt.tight_layout()
        
        # 保存或显示图形
        if output_file:
            plt.savefig(output_file, dpi=dpi, bbox_inches='tight', 
                       facecolor='white', edgecolor='none')
            print(f"布局图已保存到: {output_file}")
            plt.close(fig)
            return output_file
        else:
            plt.show()
            return fig
    
    def visualize_density_heatmap(self, grid_size=50, figsize=(10, 8), dpi=150, output_file=None):
        """
        生成密度热力图并保存为PNG
        
        参数:
        grid_size: 网格划分数量
        figsize: 图形大小
        dpi: 分辨率
        output_file: 输出文件名
        """
        if not self.cells or self.core_width <= 0 or self.core_height <= 0:
            print("无法生成密度图：缺少必要数据")
            return None
        
        # 创建网格统计
        x_edges = np.linspace(0, self.core_width, grid_size + 1)
        y_edges = np.linspace(0, self.core_height, grid_size + 1)
        
        # 统计每个网格中的cell数量
        density_matrix = np.zeros((grid_size, grid_size))
        
        for _, x, y, _ in self.cells:
            if 0 <= x <= self.core_width and 0 <= y <= self.core_height:
                x_idx = min(int(x / self.core_width * grid_size), grid_size - 1)
                y_idx = min(int(y / self.core_height * grid_size), grid_size - 1)
                density_matrix[y_idx, x_idx] += 1
        
        # 创建图形
        fig, ax = plt.subplots(figsize=figsize, dpi=dpi)
        
        # 绘制热力图
        im = ax.imshow(density_matrix, cmap='YlOrRd', aspect='equal', 
                      extent=[0, self.core_width, 0, self.core_height], 
                      origin='lower', interpolation='nearest')
        
        # 添加颜色条
        cbar = plt.colorbar(im, ax=ax, shrink=0.8)
        cbar.set_label('Cell密度 (cells per grid)', fontsize=12)
        
        # 绘制核心区域边界
        core_rect = patches.Rectangle((0, 0), self.core_width, self.core_height, 
                                    linewidth=2, edgecolor='black', facecolor='none')
        ax.add_patch(core_rect)
        
        # 设置标签
        ax.set_xlabel('X坐标 (μm)', fontsize=12)
        ax.set_ylabel('Y坐标 (μm)', fontsize=12)
        ax.set_title(f'布局密度分布图 - {self.cluster}\n'
                    f'网格大小: {grid_size}×{grid_size}', fontsize=14, pad=20)
        
        plt.tight_layout()
        
        # 保存或显示
        if output_file:
            plt.savefig(output_file, dpi=dpi, bbox_inches='tight')
            print(f"密度图已保存到: {output_file}")
            plt.close(fig)
            return output_file
        else:
            plt.show()
            return fig
    
    def generate_comprehensive_visualization(self, base_filename="chip_layout"):
        """
        生成综合可视化报告，包括布局图和密度图
        
        参数:
        base_filename: 基础文件名
        """
        if not self.cells:
            print("没有数据可供可视化")
            return []
        
        output_files = []
        
        # 生成主布局图
        layout_file = f"{base_filename}_placement.png"
        result = self.visualize_placement(figsize=(12, 10), dpi=200, 
                                        show_labels=False, output_file=layout_file)
        if result:
            output_files.append(layout_file)
        
        # 生成密度热力图
        density_file = f"{base_filename}_density.png"
        result = self.visualize_density_heatmap(grid_size=40, figsize=(10, 8), 
                                              dpi=200, output_file=density_file)
        if result:
            output_files.append(density_file)
        
        print(f"\n综合可视化完成!")
        print(f"生成的文件:")
        for file in output_files:
            if os.path.exists(file):
                size = os.path.getsize(file) / 1024  # KB
                print(f"  - {file} ({size:.1f} KB)")
        
        return output_files
    
    def get_layout_statistics(self):
        """获取详细的布局统计信息"""
        if not self.cells:
            return {}
        
        x_coords = [x for _, x, y, _ in self.cells]
        y_coords = [y for _, x, y, _ in self.cells]
        colors = [color for _, _, _, color in self.cells]
        
        # 统计颜色分布
        color_counts = {}
        for color in colors:
            color_counts[color] = color_counts.get(color, 0) + 1
        
        stats = {
            'total_cells': len(self.cells),
            'x_min': min(x_coords),
            'x_max': max(x_coords),
            'y_min': min(y_coords),
            'y_max': max(y_coords),
            'x_mean': np.mean(x_coords),
            'y_mean': np.mean(y_coords),
            'x_std': np.std(x_coords),
            'y_std': np.std(y_coords),
            'core_area': self.core_width * self.core_height,
            'utilization': len(self.cells) / (self.core_width * self.core_height) if self.core_width > 0 and self.core_height > 0 else 0,
            'color_distribution': color_counts
        }
        
        return stats
    
    def print_statistics(self):
        """打印布局统计信息"""
        stats = self.get_layout_statistics()
        if not stats:
            print("没有统计数据")
            return
        
        print(f"\n=== 布局统计报告 ===")
        print(f"芯片簇: {self.cluster}")
        print(f"核心尺寸: {self.core_width:.3f} × {self.core_height:.3f} μm")
        print(f"总面积: {stats['core_area']:.3f} μm²")
        print(f"Cell总数: {stats['total_cells']}")
        print(f"布局密度: {stats['utilization']:.4f} cells/μm²")
        print(f"\n坐标统计:")
        print(f"  X坐标: [{stats['x_min']:.3f}, {stats['x_max']:.3f}] μm (均值: {stats['x_mean']:.3f}, 标准差: {stats['x_std']:.3f})")
        print(f"  Y坐标: [{stats['y_min']:.3f}, {stats['y_max']:.3f}] μm (均值: {stats['y_mean']:.3f}, 标准差: {stats['y_std']:.3f})")
        print(f"\n颜色分布:")
        for color, count in sorted(stats['color_distribution'].items()):
            percentage = count / stats['total_cells'] * 100
            print(f"  {color}: {count} ({percentage:.1f}%)")
