## TODO

> 目的：切割APR Design为多个SubAPR，并构造EDA Agent Sever与多个SubAPR + Flatten交互，做信息交互&布局控制
> 说明：勾选框用于跟踪进度；优先级从 P0（必须）到 P2（增强）。

---

## 事项

- [ ] **API：Human Vs EDA Tool Bridge**
  - [x] **读取网表**: 加载和解析电路网表文件
  - [x] **时序分析**: 获取电路的时序信息
  - [x] **TCL命令执行**: 执行EDA工具的TCL命令
  - [x] **Cell摆放**: 执行单元摆放算法
  - [ ] **多工具支持**: 支持Leapr等多种EDA工具
  - [ ] **日志记录**: 详细的日志记录功能，便于问题定位
  - [x] **统一响应格式**: 所有API返回统一的响应格式，包含code、message和data字段
  - [ ] **文件上传**: 支持将文件上传到EDA工具工作目录

- [ ] **API：Human Vs Mulit-SubAPR & Flatten APR Bridge**
  - [ ] **多对多服务接口** 多控制端 与 多SubAPR+FlattenAPR Bridge，基于上述单对单
  - [ ] **跨SubAPR时序** StartPoint & EndPoint路径、端口，时序Merge。

- [ ] **布局切割**
  - [x] **布局切割**：由Flatten布局切割，并生成对应的SubAPR边界
      ![全局布局](/data/image/test_clustering_1196cells.png)  
      ![sub1布局](/data/image/plot_2026-02-05-17-25-05_1.png)
      ![sub2布局](/data/image/plot_2026-02-05-17-25-05_3.png)
  - [ ] **端口位置**：布局切割后的subAPR端口位置自动化
  - [ ] **端口时序**：切割后端口时序分配

- [ ] **FlattenAPR & subAPR**
  - [x] **设计/约束切分**：网表 & 约束切分，按module
  - [ ] **设计/约束切分**：网表 & 约束切分，按Cycle
  - [ ] **subAPR重建**: 切分后的设计重建APR，不重新布局
      FlattenAPR布局
      ![全局布局](/data/image/flatten.png)  
      SubAPR重建
      ![sub1布局](/data/image/sub1.png) 
      时序
      ![sub2布局](/data/image/sub1timing.png) 


---



---

## 备注

- 相关文档入口：
  - `README.md`（总览）
  - `README_EDA_Flow_Bridge.md`（较完整的 API/部署说明）
  - `edx_agent/VISUALIZATION_README.md`（可视化详解）
  - `edx_agent/NETLIST_VISUALIZATION_GUIDE.md`（网表到可视化流程）

