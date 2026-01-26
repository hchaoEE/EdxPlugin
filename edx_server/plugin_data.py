# 这个类定义接口交互的数据结构，包括request和response
import json
from typing import Dict, List, Tuple


class PlaceCellRequest:
    def __init__(self, cell_name: str, x: float, y: float,  orient = 'RO'):
        self.cell_name = cell_name
        self.x = x
        self.y = y
        self.orient = orient
    # 生成get/set方法
    def get_cell_name(self):
        return self.cell_name
    def get_x(self):
        return self.x
    def get_y(self):
        return self.y
    def get_orient(self):
        return self.orient
    def set_cell_name(self, cell_name):
        self.cell_name = cell_name

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'cell_name': self.cell_name,
            'x': self.x,
            'y': self.y,
            'orient': self.orient
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


# 定义一个所有接口统一的返回格式
class PlaceCellResponse:
    def __init__(self, status: int, message:  str):
        self.status = status
        self.message = message

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'status': self.status,
            'message': self.message
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


# 定义cell存储结构，包含x,y,width,height,orient,cell_name
class Cell:
    def __init__(self, cell_name: str, x: float, y:  float, width: float, height: float, orient = 'R0', place_status = 'unplaced'):
        self.cell_name = cell_name
        self.x = x
        self.y = y
        self.width = width
        self.height = height
        self.orient = orient
        self.place_status = place_status

    # 获取和设置属性的方法
    def get_cell_name(self):
        return self.cell_name
    def get_x(self):
        return self.x
    def get_y(self):
        return self.y
    def get_width(self):
        return self.width
    def get_height(self):
        return self.height
    def get_orient(self):
        return self.orient
    def set_cell_name(self, cell_name:  str):
        self.cell_name = cell_name

    def set_x(self,  x: float):
        self.x = x

    def set_y(self,  y: float):
        self.y = y
    def set_width(self,  width: float):
        self.width = width
    def set_height(self,  height: float):
        self.height = height
    def set_orient(self,  orient: str):
        self.orient = orient

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'cell_name': self.cell_name,
            'x': self.x,
            'y': self.y,
            'width': self.width,
            'height': self.height,
            'orient': self.orient,
            'place_status': self.place_status
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


# 定义网表存储结构
class Design:
    def __init__(self):
        self._cells: Dict[str, Cell] = {}
        self._name: str = ""
        self._core_width: float = 0.0
        self._core_height: float = 0.0
        self._pin_to_cell: Dict[str, str] = {}
        self._nets: Dict[str, list[list[str]]] = {}

    @property
    def cells(self) -> Dict[str, Cell]:
        return self._cells

    @cells.setter
    def cells(self, cells: Dict[str, Cell]):
        self._cells = cells

    @property
    def name(self) -> str:
        return self._name

    @name.setter
    def name(self, name: str):
        self._name = name

    @property
    def core_width(self) -> float:
        return self._core_width

    @core_width.setter
    def core_width(self, core_width: float):
        self._core_width = core_width

    @property
    def core_height(self) -> float:
        return self._core_height

    @core_height.setter
    def core_height(self, core_height: float):
        self._core_height = core_height

    @property
    def pin_to_cell(self) -> Dict[str, str]:
        return self._pin_to_cell

    @pin_to_cell.setter
    def pin_to_cell(self, pin_to_cell: Dict[str, str]):
        self._pin_to_cell = pin_to_cell

    @property
    def nets(self) -> Dict[str, list[list[str]]]:
        return self._nets

    @nets.setter
    def nets(self, nets: Dict[str, list[list[str]]]):
        self._nets = nets

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'cells': {name: cell.to_dict() for name, cell in self._cells.items()},
            'name': self._name,
            'core_width': self._core_width,
            'core_height': self._core_height,
            'pin_to_cell': self._pin_to_cell,
            'nets': self._nets
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


class TimingPath:
    """
    Timing path class for Leapr.
    """
    def __init__(self):
        self._start_point: str = ""
        self._end_point: str = ""
        self._scenario: str = ""
        self._path_group: str = ""
        self._path_type: str = ""
        self._path: list[Tuple[str, float, float]] = []
        self._data_required_time: float = 0.0
        self._data_arrival_time: float = 0.0
        self._slack: float = 0.0

    @property
    def start_point(self) -> str:
        return self._start_point

    @start_point.setter
    def start_point(self, start_point: str):
        self._start_point = start_point

    @property
    def end_point(self) -> str:
        return self._end_point

    @end_point.setter
    def end_point(self, end_point: str):
        self._end_point = end_point

    @property
    def scenario(self) -> str:
        return self._scenario

    @scenario.setter
    def scenario(self, scenario: str):
        self._scenario = scenario

    @property
    def path_group(self) -> str:
        return self._path_group

    @path_group.setter
    def path_group(self, path_group: str):
        self._path_group = path_group

    @property
    def path_type(self) -> str:
        return self._path_type

    @path_type.setter
    def path_type(self, path_type: str):
        self._path_type = path_type

    @property
    def path(self) -> list[Tuple[str, float, float]]:
        return self._path

    @path.setter
    def path(self, path: list[Tuple[str, float, float]]):
        self._path = path

    @property
    def data_required_time(self) -> float:
        return self._data_required_time

    @data_required_time.setter
    def data_required_time(self, data_required_time: float):
        self._data_required_time = data_required_time

    @property
    def data_arrival_time(self) -> float:
        return self._data_arrival_time

    @data_arrival_time.setter
    def data_arrival_time(self, data_arrival_time: float):
        self._data_arrival_time = data_arrival_time

    @property
    def slack(self) -> float:
        return self._slack

    @slack.setter
    def slack(self, slack: float):
        self._slack = slack

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'start_point': self._start_point,
            'end_point': self._end_point,
            'scenario': self._scenario,
            'path_group': self._path_group,
            'path_type': self._path_type,
            'path': self._path,
            'data_required_time': self._data_required_time,
            'data_arrival_time': self._data_arrival_time,
            'slack': self._slack
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


class STA:
    """
    Timing class for Leapr.
    """
    def __init__(self):
        self._timing_paths: List[TimingPath] = []

    @property
    def timing_paths(self) -> List[TimingPath]:
        return self._timing_paths

    @timing_paths.setter
    def timing_paths(self, timing_paths: List[TimingPath]):
        self._timing_paths = timing_paths

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'timing_paths': [tp.to_dict() for tp in self._timing_paths]
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())


class EdxResponse:
    """
    Response class for EdxPlugin
    """
    def __init__(self, status: int, message: str, data: object):
        self.status = status
        self.message = message
        self.data = data

    def to_dict(self):
        """将对象转换为字典"""
        return {
            'status': self.status,
            'message': self.message,
            'data': self.data.to_dict() if hasattr(self.data, 'to_dict') and self.data is not None else self.data
        }

    def to_json(self):
        """将对象转换为JSON字符串"""
        return json.dumps(self.to_dict())