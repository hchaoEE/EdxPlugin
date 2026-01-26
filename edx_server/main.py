import re
from flask import Flask, request, jsonify
from plugin_data import *
from tcl_sender import *
import json

# 创建tmp目录
tmp_dir = os.path.join(os.path.dirname(__file__), 'tmp')
os.makedirs(tmp_dir, exist_ok=True)

# 配置日志
log_file_path = os.path.join(tmp_dir, 'edx_plugin.log')
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s %(levelname)s %(name)s [%(filename)s:%(lineno)d] %(message)s',
    handlers=[
        logging.FileHandler(log_file_path),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

app = Flask(__name__)


# 定义EDA工具抽象基类
class BaseEDA_Tool:
    def __init__(self, tool_name):
        self.tool_name = tool_name
        self.design_loaded = False
        self.current_design = None
        self.timing_data = {}
        self.cell_placement = {}
        self.config = DEFAULT_CONFIG.get(tool_name, {})
        logger.info(f"[{self.tool_name}] 初始化工具实例")

    def load_netlist(self) -> Design:
        raise NotImplementedError("Subclasses must implement this method")

    def download_netlist(self) -> str:
        raise NotImplementedError("Subclasses must implement this method")

    def get_timing_info(self, topn=10) -> STA:
        raise NotImplementedError("Subclasses must implement this method")

    def execute_tcl_command(self, tcl_commands) -> list[str]:
        raise NotImplementedError("Subclasses must implement this method")

    def place_cells(self, cells: list[Cell]) -> list[str]:
        raise NotImplementedError("Subclasses must implement this method")


# 不同EDA工具的具体实现
class Leapr_Tool(BaseEDA_Tool):
    def __init__(self):
        super().__init__("leapr")
        logger.info("[Leapr] Leapr begin init...")

    def load_netlist(self) -> Design:
        """
            Leapr特有的读取网表功能
            读取当前目录下 leapr_api/apicommon/get_all_cell_info.ctl脚本，发送给EDA执行，然后解析里面的网表
        """
        # 当前main.py文件的绝对路径
        current_dir = os.path.dirname(os.path.abspath(__file__))
        netlist_file_path = os.path.join(current_dir, "apicommon", "get_all_cell_info.tcl")
        tcl_sender = TCLSender()
        result = tcl_sender.send_tcl_file(netlist_file_path)
        my_design = Design()
        '''
            result列表中第2行design的core长宽，格式为：core_size: {78.12 69.192}，之后每4行一组，格式为
            u_macc_top/macc[0].u_macc/adder_out_reg[15] --cell name
            4.32 -- cell width
            1.08 --cell height
            u_macc_top/macc[0].u_macc/adder_out_reg[15]/QN|u_macc_top/macc[0].u_macc/adder_out_reg[15]/D --- all pins join with,
        '''
        core_line = result[1]  # "core_size: {78.12 69.192}"
        match = re.search(r'\{([\d.]+)\s+([\d.]+)\}', core_line)
        if match:
            my_design.core_width = float(match.group(1))
            my_design.core_height = float(match.group(2))
        row_counter = 3
        for row_index in range(3, len(result), 3):
            row_counter = row_index
            cell_name = result[row_index].strip()
            if '======' in cell_name:
                break
            prop = result[row_index + 1].strip().split(",")
            cell_width = float(prop[0])
            cell_height = float(prop[1])
            cell_orient = prop[2]
            cell_place_status = prop[3]
            loc_x = prop[4]
            loc_y = prop[5]
            pin_str = result[row_index + 2].strip()
            pins = pin_str.split('|')
            for pin in pins:
                pin = pin.strip()
                if pin:  # 确保不是空字符串
                    my_design.pin_to_cell[pin] = cell_name
            my_design.cells[cell_name] = Cell(cell_name, loc_x, loc_y, cell_width, cell_height, cell_orient,
                                              place_status=cell_place_status)
        for i in range(row_counter + 1, len(result)):
            # 读取net
            net_info = result[i].strip()
            if len(net_info) < 1:
                continue
            split = net_info.split(',')
            if len(split) < 3:
                logger.error(f"[Leapr] net {split[0]} dont has load pins or driver pins")
                continue
            net_name = split[0]
            load_pins = split[1].split('|')
            driver_pins = split[2].split('|')
            my_design.nets[net_name] = [load_pins, driver_pins]

        logger.info(f"[Leapr] begin loading netlist: {netlist_file_path}")
        return my_design

    def download_netlist(self) -> str:
        """
        生成压缩的网表文件
        :param output_filename: 输出文件名
        :return: 压缩文件路径
        """
        current_dir = os.path.dirname(os.path.abspath(__file__))
        netlist_file_path = os.path.join(current_dir,"apicommon", "get_all_cell_info.tcl")
        tcl_sender = TCLSender()
        result = tcl_sender.send_tcl_file(netlist_file_path, return_result=False)
        if len(result) != 1:
            logger.error(f"[Leapr] generate_compressed_netlist error: {result}")
            return ""
        server_result_txt = result[0]
        # 判断server_result_txt文件是否存在
        if not os.path.exists(server_result_txt):
            logger.error(f"[Leapr] generate_compressed_netlist error: {server_result_txt} not exists")
            return ""
        return result[0]

    def get_timing_info(self, topn=10) -> STA:
        """Leapr特有的时序分析功能
        :param topn:
        """
        tcl_sender = TCLSender()
        api_dir = DEFAULT_CONFIG.get("edx_tmp")
        tcl_sender.send_tcl([f'report_timing -group REG2REG -max_paths {topn} -path_type full > {api_dir}/report'])
        report_file = os.path.join(api_dir, "report")
        sta = STA()
        with open(report_file, 'r', encoding='utf-8') as f:
            # 文本格式是注释的样子，文件有很多这种路径，读取文件，解析成STA对象
            in_point = False
            counter = 0
            timing_path = None  # 初始化timing_path为None
            for line in f:
                if 'Startpoint:' in line:
                    # 如果之前有未完成的timing_path，将其添加到列表中
                    if timing_path is not None:
                        logger.debug(f'Adding incomplete timing path for {timing_path.start_point}')
                        sta.timing_paths.append(timing_path)
                    timing_path = TimingPath()
                    timing_path.start_point = line.split(':')[1].strip().split()[0]
                    continue
                if 'Endpoint:' in line:
                    timing_path.end_point = line.split(':')[1].strip().split()[0]
                    continue
                if 'Path Group:' in line:
                    timing_path.path_group = line.split(':')[1].strip()
                    continue
                if 'Scenario:' in line:
                    timing_path.scenario = line.split(':')[1].strip()
                    continue
                if 'Path Type:' in line:
                    timing_path.path_type = line.split(':')[1].strip()
                    continue
                if 'clock network delay' in line:
                    if counter % 2 == 0:
                        in_point = True
                    else:
                        in_point = False
                    counter = counter + 1
                    continue
                if in_point:
                    if 'data arrival time' in line:
                        in_point = False
                        continue
                    # 将line按空白字符分割，空白字符包括空格、制表符、换行符等
                    point_incr_path = line.split()
                    pin_name = point_incr_path[0]
                    logger.debug(f'line is {line}')
                    if '(' in point_incr_path[1]:
                        incr = point_incr_path[2]
                        path_delay = point_incr_path[3]
                    else:
                        incr = point_incr_path[1]
                        path_delay = point_incr_path[2]
                    timing_path.path.append((pin_name, float(incr), float(path_delay)))
                    continue
                if 'data required time' in line:
                    timing_path.data_required_time = float(line.split()[3])
                    continue
                if 'data arrival time' in line:
                    timing_path.data_arrival_time = float(line.split()[3])
                    continue
                if 'slack (' in line:
                    logger.info(f'slack: {line}')
                    timing_path.slack = float(line.split()[2])
                    sta.timing_paths.append(timing_path)
                    logger.info(f'path cell num is {len(timing_path.path)}')
                    timing_path = None  # 重置timing_path为None，准备下一个路径

        return sta

    def execute_tcl_command(self, tcl_commands) -> list[str]:
        """Leapr特有的TCL命令执行"""
        logger.info(f"[Leapr] 执行TCL命令: {tcl_commands}")
        return TCLSender().send_tcl(tcl_commands)

    def place_cells(self, cells: list[Cell]):
        tcl_cmds = []
        for cell in cells:
            tcl_cmds.append(f'place_cell {cell.get_cell_name()} {cell.get_x():.2f} {cell.get_y():.2f} -placed')
        tcl_sender = TCLSender()
        tcl_sender.send_tcl(tcl_cmds)


# 创建EDA工具实例的字典
eda_tools = {
    "leapr": Leapr_Tool(),
}


@app.route('/')
def home():
    logger.info("接收到来自主页的请求")
    response_data = {
        "message": "EDX Plugin REST API for Multiple EDA Tools",
        "version": "2.3",
        "supported_tools": list(eda_tools.keys()),
        "config_info": {tool: {"version": "1.0", "features": list(config.keys()) if isinstance(config, dict) else []}
                        for tool, config in DEFAULT_CONFIG.items()},
        "endpoints": [
            "/<tool_name>/load_netlist",
            "/<tool_name>/download_netlist",
            "/<tool_name>/get_timing",
            "/<tool_name>/execute_tcl",
            "/<tool_name>/place_cells"
        ]
    }
    logger.info("主页请求处理完成")
    return jsonify(EdxResponse(200, "Home page", response_data).to_dict())


@app.route('/<tool_name>/load_netlist', methods=['POST'])
def load_netlist(tool_name):
    """
    读取网表
    请求体参数:
    - file_path: 网表文件路径
    """
    logger.info(f"接收到[{tool_name}]的加载网表请求")
    try:
        if tool_name not in eda_tools:
            error_msg = f"Unsupported EDA tool: {tool_name}. Supported tools: {list(eda_tools.keys())}"
            logger.error(error_msg)
            return jsonify(EdxResponse(400, error_msg).to_dict()), 400
        design = eda_tools[tool_name].load_netlist()
        logger.info(f"[{tool_name}] 网表加载成功, cell number is {len(design.cells)}")
        return jsonify(EdxResponse(200, 'success', design).to_dict()), 200
    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{tool_name}] 加载网表时发生未预期异常: {error_msg}")
        return jsonify(EdxResponse(500, "Internal server error").to_dict()), 500


@app.route('/<tool_name>/download_netlist', methods=['GET'])
def download_netlist(tool_name):
    """
    下载网表文件 - 返回压缩的网表文件
    """
    logger.info(f"接收到[{tool_name}]的下载网表请求")
    try:
        if tool_name not in eda_tools:
            error_msg = f"Unsupported EDA tool: {tool_name}. Supported tools: {list(eda_tools.keys())}"
            logger.error(error_msg)
            return jsonify(EdxResponse(400, error_msg).to_dict()), 400

        # 生成压缩的网表文件
        compressed_file_path = eda_tools[tool_name].download_netlist()
        if len(compressed_file_path) < 1:
            error_msg = f"[{tool_name}] 网表文件生成失败"
            logger.error(error_msg)
            return jsonify(EdxResponse(500, error_msg).to_dict()), 500

        # 返回文件供下载
        from flask import send_file
        logger.info(f"[{tool_name}] 网表文件生成成功，准备返回下载: {compressed_file_path}")
        return send_file(compressed_file_path, as_attachment=True, download_name=os.path.basename(compressed_file_path))

    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{tool_name}] 生成网表文件时发生未预期异常: {error_msg}")
        return jsonify(EdxResponse(500, "Internal server error").to_dict()), 500


@app.route('/<tool_name>/get_timing', methods=['GET'])
def get_timing(tool_name):
    """
    获取时序信息
    查询参数:
    - topn: 获取前N个时序路径，默认为10
    """
    logger.info(f"接收到[{tool_name}]的获取时序信息请求")
    try:
        if tool_name not in eda_tools:
            error_msg = f"Unsupported EDA tool: {tool_name}. Supported tools: {list(eda_tools.keys())}"
            logger.error(error_msg)
            return jsonify(EdxResponse(400, "Unsupported EDA tool").to_dict()), 400

        # 获取查询参数topn，默认值为10
        topn = request.args.get('topn', default=10, type=int)
        sta = eda_tools[tool_name].get_timing_info(topn)

        response_data = EdxResponse(200, "success", sta)
        return jsonify(response_data.to_dict()), 200
    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{tool_name}] 获取时序信息时发生未预期异常: {error_msg}")
        return jsonify(EdxResponse(500, "Internal server error").to_dict()), 500


@app.route('/<tool_name>/execute_tcl', methods=['POST'])
def execute_tcl(tool_name):
    """
    执行TCL命令
    请求体参数:
    - commands: TCL命令字符串列表，列表中每个元素就是一行命令
    """
    logger.info(f"接收到[{tool_name}]的执行TCL命令请求")
    try:
        if tool_name not in eda_tools:
            error_msg = f"Unsupported EDA tool: {tool_name}. Supported tools: {list(eda_tools.keys())}"
            logger.error(error_msg)
            return jsonify(EdxResponse(400, "Unsupported EDA tool").to_dict()), 400

        data = request.get_json()
        command = data.get('commands')
        eda_resp = eda_tools[tool_name].execute_tcl_command(command)
        # 如果result为None，将其设为空列表
        if eda_resp is None:
            eda_resp = []
        logger.info(f"[{tool_name}] TCL命令执行完成, result is {eda_resp}")
        return jsonify(EdxResponse(200, "success", eda_resp).to_dict()), 200
    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{tool_name}] 执行TCL命令时发生未预期异常: {error_msg}")
        return jsonify(EdxResponse(500, "Internal server error").to_dict()), 500


@app.route('/<tool_name>/place_cells', methods=['POST'])
def place_cells(tool_name):
    """
    执行cell摆放
    请求体参数:
    [
        {
            "cell_name": xx,
            "x": 1.2,
            "y": 2.1,
            "width": 2.2,
            "height": 4.2,
            "orient": "R0",
            "place_status": "placed"
        }
    ]
    """
    logger.info(f"接收到[{tool_name}]的执行cell摆放请求")
    try:
        if tool_name not in eda_tools:
            error_msg = f"Unsupported EDA tool: {tool_name}. Supported tools: {list(eda_tools.keys())}"
            logger.error(error_msg)
            return jsonify(EdxResponse(400, "Unsupported EDA tool", {}).to_dict()), 400

        data = request.get_json()
        # 直接使用请求体数据作为cell列表，根据注释中的格式进行解析
        cell_list = []
        for cell_data in data:
            cell = Cell(
                cell_data["cell_name"],
                cell_data["x"],
                cell_data["y"],
                cell_data.get("width", 0.0),  # 使用get方法，如果没有宽度则默认为0
                cell_data.get("height", 0.0),  # 使用get方法，如果没有高度则默认为0
                cell_data.get("orient", ""),  # 使用get方法，如果没有方向则默认为空字符串
                place_status=cell_data.get("place_status", "")  # 使用get方法，如果没有放置状态则默认为空字符串
            )
            cell_list.append(cell)
        eda_tools[tool_name].place_cells(cell_list)
        logger.info(f"[{tool_name}] 执行cell摆放请求处理完成")
        return jsonify(EdxResponse(200, "success", {}).to_dict()), 200
    except Exception as e:
        error_msg = str(e)
        logger.error(f"[{tool_name}] 执行cell摆放时发生未预期异常: {error_msg}")
        return jsonify(EdxResponse(500, "Internal server error", {}).to_dict()), 500


if __name__ == '__main__':
    logger.info("启动EDX Plugin REST API服务器")
    app.run(debug=True, host='0.0.0.0', port=5000)