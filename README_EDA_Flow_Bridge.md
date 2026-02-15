# EDX Plugin - EDA工具REST API接口

这是一个用于电子设计自动化(EDA)工具的REST API接口，支持多种EDA工具，提供网表处理、时序分析、TCL命令执行和单元摆放等功能。

## 功能特性

- 📁 **读取网表**: 加载和解析电路网表文件
- ⏱️ **时序分析**: 获取电路的时序信息
- 🔧 **TCL命令执行**: 执行EDA工具的TCL命令
- 📐 **Cell摆放**: 执行单元摆放算法
- 🔄 **多工具支持**: 支持Leapr等多种EDA工具
- 📝 **日志记录**: 详细的日志记录功能，便于问题定位
- 📊 **统一响应格式**: 所有API返回统一的响应格式，包含code、message和data字段
- 📤 **文件上传**: 支持将文件上传到EDA工具工作目录

## 新增：APR并行调度器（MVP）

项目已新增 `/scheduler/*` 接口用于APR批量调度与监控，支持：

- 多主机注册与心跳
- 单任务/批量任务提交
- 优先级+资源约束调度
- 任务日志查询与状态跟踪
- 任务控制（pause/resume/stop/rerun）

详细使用方式见：`edx_server/APR_SCHEDULER_USAGE.md`

## 支持的EDA工具

- **Leapr**: 物理设计工具，用于布局布线

## 安装与启动

### 环境要求

- Python 3.7+
- pip包管理器

### Linux/Mac安装步骤

1. 克隆或下载此项目到本地
2. 安装依赖：
   ```bash
   pip3.9 install -r requirements.txt
   ```
3. 启动服务：
   ```bash
   python3.9 main.py
   ```

或者使用启动脚本：
   ```bash
   chmod +x start_edx_server.sh
   ./start_edx_server.sh
   ```

服务器将在 http://localhost:5000 上运行。

### 启动EDA工具并加载Design

当插件部署和启动完成后，需要进入case目录启动EDA工具并加载design。默认的case目录是：`/data/casese/top_ASAP7`。插件部署目录是: `/data/EdxPlugin`

启动EDA的操作步骤如下：

1. 进入case目录：
   ```bash
   cd /data/casese/top_ASAP7
   ```
2. 设置环境变量指向EdxPlugin安装目录:
   ```bash
   export EdxPluginPath=插件部署目录
   ```
   实际使用时请将"插件部署目录"替换为实际的部署路径，例如：
   ```bash
   export EdxPluginPath=/data/EdxPlugin
   ```
3. 创建符号链接到插件的apicommon目录：
   ```bash
   ln -sf ${EdxPluginPath}/casese/apicommon .
   ```
4. 创建符号链接到asap7_scr目录：
   ```bash
   ln -sf ${EdxPluginPath}/casese/asap7_scr scr
   ```
5. 启动EDA工具：
   ```bash
   cd scr
   source run.csh
   ```
完成以上步骤后，您就可以在EDA环境中使用本插件提供的功能了。

### Linux启动脚本使用

我们提供了 `start_server.sh` 脚本来方便Linux用户启动服务：

1. 使脚本可执行：
   ```bash
   chmod +x start_edx_server.sh
   ```

2. 运行脚本：
   ```bash
   ./start_edx_server.sh
   ```

3. 自定义参数：
   ```bash
   # 指定主机和端口
   ./start_edx_server.sh --host 0.0.0.0 --port 8080
   
   # 启用调试模式
   ./start_edx_server.sh --debug
   
   # 同时指定多个参数
   ./start_edx_server.sh --host 127.0.0.1 --port 8080 --debug
   ```

脚本功能：
- 自动检测Python版本
- 自动创建虚拟环境（如果不存在）
- 自动安装依赖
- 彩色输出日志
- 参数化配置

## API接口测试

我们提供了 `test_api_curl.sh` 脚本来测试API接口：

1. 使脚本可执行：
   ```bash
   chmod +x test_api_curl.sh
   ```

2. 运行测试：
   ```bash
   ./test_api_curl.sh
   ```

3. 自定义参数：
   ```bash
   # 测试指定主机
   ./test_api_curl.sh --host 192.168.1.100
   
   # 测试指定端口
   ./test_api_curl.sh --port 8080
   ```

测试内容包括：
- 主页面接口
- 加载网表接口
- 获取时序信息接口（包括不同topn参数的测试）
- 执行TCL命令接口
- 执行cell摆放接口
- 文件上传接口

## 日志功能

系统会自动记录所有操作到 `tmp/` 目录下的日志文件中，包括：
- `tmp/edx_plugin.log` - 主要服务日志
- `tmp/server_startup.log` - 服务启动日志
- `tmp/tcl_sender.log` - TCL发送器日志

日志格式为：`时间戳 级别 工具名 信息`

## API端点

### 工具列表 (`GET /`)

获取支持的EDA工具列表和API端点信息。

#### 示例请求
```bash
curl -X GET http://localhost:5000/
```

### API端点列表

以下是可用的API端点：
- `/<tool_name>/load_netlist` - 读取网表（返回JSON数据）
- `/<tool_name>/download_netlist` - 下载压缩的网表文件
- `/<tool_name>/get_timing` - 获取时序信息
- `/<tool_name>/execute_tcl` - 执行TCL命令
- `/<tool_name>/place_cells` - 执行Cell摆放
- `/<tool_name>/upload_file` - 上传文件到EDA工作目录

### 1. 读取网表 (`POST /<tool_name>/load_netlist`)

为指定的EDA工具加载电路网表文件到内存中进行后续处理。

#### 支持的工具名称
- `leapr`

#### 请求参数
当前实现中，此接口不需要任何请求参数。Leapr工具会自动读取预设的 `leapr_api/apicommon/get_all_cell_info.tcl` 文件。

#### 示例请求 (Leapr)
```bash
curl -X POST http://localhost:5000/leapr/load_netlist \
  -H "Content-Type: application/json" \
  -d '{}'
```

#### 响应示例 (Leapr)
```json
{
  "status": 200,
  "message": "success",
  "data": {
    "cells": {
      "cell_name": {
        "cell_name": "INV_X1",
        "x": 100.5,
        "y": 200.3,
        "width": 1.2,
        "height": 2.4,
        "orient": "R0",
        "place_status": "placed"
      }
    },
    "name": "",
    "core_width": 78.12,
    "core_height": 69.192,
    "pin_to_cell": {
      "pin_name": "cell_name"
    },
    "nets": {
      "net_name": [["load_pin1", "load_pin2"], ["driver_pin"]]
    }
  }
}
```

> 注：响应中的data字段是Design对象，包含cells（单元格信息）、core_width和core_height（核心区域尺寸）、pin_to_cell（引脚到单元格的映射）和nets（网络连接信息）

### 1.1 下载网表文件 (`GET /<tool_name>/download_netlist`)

为指定的EDA工具下载压缩的网表文件，适用于大数据量的网表传输，避免通过HTTP响应体直接返回数据。

#### 支持的工具名称
- `leapr`

#### 示例请求 (Leapr)
```bash
# 下载默认命名的压缩网表文件
curl -X GET http://localhost:5000/leapr/download_netlist -O
```

#### 响应格式
返回gzip压缩的文本文件，解压后内容格式如下：

```
=======design_info=======
core_size: {core_width core_height}
=======cell_info=======
cell1
width,height,MY,placed,loc_x,loc_y
pin1|pin2|pinN
cell2
width,height,MY,placed,loc_x,loc_y
pin1|pin2|pinN
=======net_info=======
net1,loadpin1|loadpin2|loadpinN,driverpin1
net2,loadpin1|loadpin2|loadpinN,driverpin1
```

> 注：此接口用于优化大数据量传输性能，返回压缩的网表文件而非JSON响应

### 2. 获取时序信息 (`GET /<tool_name>/get_timing`)

获取指定EDA工具的时序分析结果。

#### 查询参数
- `topn`: 返回最差时序路径的数量 (可选)

#### 示例请求 (Leapr)
```bash
# 获取所有时序信息
curl -X GET http://localhost:5000/leapr/get_timing

# 只获取前2条最差时序路径
curl -X GET http://localhost:5000/leapr/get_timing?topn=2
```

#### 响应示例 (Leapr)
```json
{
  "status": 200,
  "message": "success",
  "data": {
    "timing_paths": [
      {
        "start_point": "u_startpoint",
        "end_point": "u_endpoint",
        "scenario": "func",
        "path_group": "REG2REG",
        "path_type": "setup",
        "path": [
          ["pin1", 0.1, 0.2],
          ["pin2", 0.15, 0.3]
        ],
        "data_required_time": 1.0,
        "data_arrival_time": 0.8,
        "slack": 0.2
      }
    ]
  }
}
```

### 3. 执行TCL命令 (`POST /<tool_name>/execute_tcl`)

为指定EDA工具执行TCL命令。

#### 请求参数
```json
{
  "commands": ["place_design", "route_design"]
}
```

> 注：commands 是一个包含多个TCL命令的数组，将按顺序执行这些命令

#### 示例请求 (Leapr)
```bash
curl -X POST http://localhost:5000/leapr/execute_tcl \
  -H "Content-Type: application/json" \
  -d '{"commands": ["place_design", "route_design"]}'
```

#### 响应示例
```json
{
  "status": 200,
  "message": "success",
  "data": []
}
```

> 注：data字段是TCL命令执行结果的字符串数组

### 4. 执行Cell摆放 (`POST /<tool_name>/place_cells`)

为指定EDA工具执行电路单元的摆放算法。

#### 请求参数
```json
[
  {
    "cell_name": "INV_X1",
    "x": 100.5,
    "y": 200.3,
    "orient": "R0"
  }
]
```

#### 示例请求 (Leapr)
```bash
curl -X POST http://localhost:5000/leapr/place_cells \
  -H "Content-Type: application/json" \
  -d '[{"cell_name": "u_macc_top/macc[0].u_macc/lc_drvi15_n119", "x": 10.67, "y": 11.12, "orient": "R0"}]
```

#### 响应示例 (Leapr)
```json
{
  "status": 200,
  "message": "success",
  "data": {}
}
```

> 注：data字段通常为空对象，表示cell摆放操作已完成

### 5. 上传文件 (`POST /<tool_name>/upload_file`)

为指定EDA工具上传文件到工作目录（edx_tmp目录）。

#### 请求参数
- 文件: 通过multipart/form-data格式上传，字段名为 "file"

#### 示例请求 (Leapr)
```bash
curl -X POST http://localhost:5000/leapr/upload_file \
  -H "Content-Type: multipart/form-data" \
  -F "file=@/path/to/your/file.txt"
```

#### 响应示例 (Leapr)
```json
{
  "status": 200,
  "message": "File uploaded successfully",
  "data": {
    "file_path": "/tmp/edx_server/tmp_1/filename.txt",
    "file_name": "filename.txt",
    "file_size": 1024
  }
}
```

> 注：data字段包含上传文件的路径、文件名和文件大小信息

### 6. 下载文件 (`GET /<tool_name>/download_file`)

为指定EDA工具执行TCL脚本并下载生成的文件。

#### 查询参数
- `script_name`: TCL脚本名称（必需），指定要执行的TCL脚本文件名（不含扩展名）

#### 示例请求 (Leapr)
```bash
# 执行get_netlist.tcl脚本并下载生成的get_netlist.tar.gz文件
curl -X GET "http://localhost:5000/leapr/download_file?script_name=get_netlist" -O
```

#### 响应格式
返回TCL脚本执行后在edx_tmp目录下生成的压缩文件（.tar.gz格式）。

> 注：此接口用于执行指定的TCL脚本并返回生成的文件，适用于需要执行特定脚本并获取结果文件的场景

## 错误处理

API会返回适当的HTTP状态码和错误信息：

- `400 Bad Request`: 请求参数错误或不支持的EDA工具
- `500 Internal Server Error`: 服务器内部错误

错误响应格式：
```json
{
  "status": 400,
  "message": "Error message",
  "data": null
}
```

## 数据模型

系统使用统一的数据模型来表示电路设计信息，主要包含：
- **Design**: 设计的主要容器，包含所有其他元素
- **Cell**: 电路单元（标准单元、宏单元等）
- **Net**: 网络连接
- **Port**: 设计端口
- **Clock**: 时钟定义
- **TimingArc**: 时序弧

## 使用场景

此API适用于：
- 集成多种EDA工具到Web应用
- 自动化IC设计流程
- 电路仿真和验证
- 设计数据可视化
- 远程EDA工具访问
- EDA工具间的协同工作流
- 上传设计文件到EDA工具环境

## 扩展支持

要添加新的EDA工具支持，请：
1. 创建继承自BaseEDA_Tool的新类
2. 实现load_netlist、get_timing_info、execute_tcl_command和place_cells方法
3. 在eda_tools字典中添加工具实例

## 许可证

请参阅项目许可证文件。