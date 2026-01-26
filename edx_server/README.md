### API端点列表

以下是可用的API端点：
- `/<tool_name>/load_netlist` - 读取网表（返回JSON数据）
- `/<tool_name>/download_netlist` - 下载压缩的网表文件
- `/<tool_name>/get_timing` - 获取时序信息
- `/<tool_name>/execute_tcl` - 执行TCL命令
- `/<tool_name>/place_cells` - 执行Cell摆放
- `/<tool_name>/upload_file` - 上传文件到EDA工作目录
- `/<tool_name>/download_file` - 执行TCL脚本并下载生成的文件

### 1. 读取网表 (`GET /<tool_name>/load_netlist`)

读取指定EDA工具的网表文件并返回JSON数据。

#### 查询参数
- `netlist_name`: 网表文件名称（必需），指定要读取的网表文件名（不含扩展名）

#### 示例请求 (Leapr)
```
# 读取名为"design"的网表文件
curl -X GET "http://localhost:5000/leapr/load_netlist?netlist_name=design"
```

#### 响应格式
```

```

### 2. 下载网表 (`GET /<tool_name>/download_netlist`)

下载指定EDA工具的网表文件。

#### 查询参数
- `netlist_name`: 网表文件名称（必需），指定要下载的网表文件名（不含扩展名）

#### 示例请求 (Leapr)
```
# 下载名为"design"的网表文件
curl -X GET "http://localhost:5000/leapr/download_netlist?netlist_name=design" -O
```

#### 响应格式
```

```

### 3. 获取时序信息 (`GET /<tool_name>/get_timing`)

获取指定EDA工具的时序信息。

#### 示例请求 (Leapr)
```
# 获取时序信息
curl -X GET "http://localhost:5000/leapr/get_timing"
```

#### 响应格式
```

```

### 4. 执行TCL命令 (`POST /<tool_name>/execute_tcl`)

为指定EDA工具执行TCL命令。

#### 请求体
```

```

#### 示例请求 (Leapr)
```
# 执行TCL命令
curl -X POST "http://localhost:5000/leapr/execute_tcl"

```

#### 响应格式
```

```

### 5. 执行Cell摆放 (`POST /<tool_name>/place_cells`)

为指定EDA工具执行Cell摆放。

#### 请求体
```

```

#### 示例请求 (Leapr)
```
# 执行Cell摆放
curl -X POST "http://localhost:5000/leapr/place_cells"

```

#### 响应格式
```

```

### 6. 上传文件 (`POST /<tool_name>/upload_file`)

上传文件到指定EDA工具的工作目录。

#### 请求体
```

```

#### 示例请求 (Leapr)
```
# 上传文件
curl -X POST "http://localhost:5000/leapr/upload_file"

```

#### 响应格式
```

```

> 注：data字段包含上传文件的路径、文件名和文件大小信息

### 6. 下载文件 (`GET /<tool_name>/download_file`)

为指定EDA工具执行TCL脚本并下载生成的文件。

#### 查询参数
- `script_name`: TCL脚本名称（必需），指定要执行的TCL脚本文件名（不含扩展名）

#### 示例请求 (Leapr)
```
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

