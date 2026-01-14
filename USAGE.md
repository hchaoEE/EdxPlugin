# EDX Plugin 启动脚本使用说明

## Linux/Mac 启动脚本

### 文件名
- `start_server.sh` - Linux/Mac 启动脚本

### 权限设置
首次使用前需要给脚本赋予执行权限：
```bash
chmod +x start_server.sh
```

### 基本用法
```bash
./start_server.sh
```

### 参数说明
- `-h, --host HOST` - 指定服务器监听的主机地址，默认为 `0.0.0.0`
- `-p, --port PORT` - 指定服务器监听的端口，默认为 `5000`
- `-d, --debug` - 启用调试模式
- `--help` - 显示帮助信息

### 使用示例

1. 启动默认服务：
   ```bash
   ./start_server.sh
   ```

2. 指定主机和端口：
   ```bash
   ./start_server.sh --host 127.0.0.1 --port 8080
   ```

3. 启用调试模式：
   ```bash
   ./start_server.sh --debug
   ```

4. 组合参数：
   ```bash
   ./start_server.sh --host 0.0.0.0 --port 9000 --debug
   ```

## 启动EDA工具并加载Design
当插件部署和启动完成后，需要进入case目录启动EDA工具并加载design。默认的case目录是：`/data/casese/top_ASAP7`。

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
   ln -sf ${EdxPluginPath}/leapr_api/apicommon .
   ```
4. 创建符号链接到asap7_scr目录：
   ```bash
   ln -sf ${EdxPluginPath}/leapr_api/asap7_scr scr
   ```
5. 启动EDA工具：
   ```bash
   cd scr
   source run.csh
   ```
完成以上步骤后，您就可以在EDA环境中使用本插件提供的功能了。


## API 接口测试脚本

### 文件名
- `test_api_curl.sh` - Linux/Mac API接口测试脚本

### 权限设置
首次使用前需要给脚本赋予执行权限：
```bash
chmod +x test_api_curl.sh
```

### 基本用法
```bash
./test_api_curl.sh
```

### 参数说明
- `--host HOST` - 指定服务器主机地址，默认为 `localhost`
- `--port PORT` - 指定服务器端口，默认为 `5000`
- `--help` - 显示帮助信息

### 使用示例

1. 测试默认服务：
   ```bash
   ./test_api_curl.sh
   ```

2. 测试指定主机的服务：
   ```bash
   ./test_api_curl.sh --host 192.168.1.100
   ```

3. 测试指定端口的服务：
   ```bash
   ./test_api_curl.sh --port 8080
   ```

4. 组合参数：
   ```bash
   ./test_api_curl.sh --host 192.168.1.100 --port 8080
   ```

### 测试内容
脚本会自动测试以下API端点：
- 主页面接口 (`GET /`)
- 加载网表接口 (`POST /leapr/load_netlist`)
- 获取时序信息接口 (`GET /leapr/get_timing`) - 包括不同topn参数的测试
- 执行TCL命令接口 (`POST /leapr/execute_tcl`)
- 执行cell摆放接口 (`POST /leapr/place_cells`)

## 脚本功能特点

1. **自动环境检测** - 自动检测系统中的 Python 版本
2. **依赖管理** - 自动安装所需的依赖包
3. **虚拟环境** - 自动创建和管理 Python 虚拟环境
4. **彩色日志** - 使用彩色输出显示不同类型的信息
5. **错误处理** - 包含完善的错误处理和提示信息
6. **优雅退出** - 支持使用 Ctrl+C 优雅地停止服务

## 服务访问

服务启动后，默认可以通过以下地址访问：
- API 文档: `http://localhost:5000/`
- 各功能端点: `http://localhost:5000/<tool_name>/<endpoint>`

## 日志文件

服务运行过程中会在 `tmp/` 目录下生成以下日志文件：
- `tmp/edx_plugin.log` - 主要服务日志
- `tmp/server_startup.log` - 服务启动日志
- `tmp/tcl_sender.log` - TCL发送器日志

## 故障排除

如果遇到问题，请检查：
1. Python 3.7+ 是否已正确安装
2. `requirements.txt` 中的依赖是否已安装
3. 端口是否被其他服务占用
4. `tmp/` 目录下的日志文件中的错误信息