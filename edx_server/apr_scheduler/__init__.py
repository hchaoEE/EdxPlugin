"""
APR Scheduler package.

提供面向APR批量任务的轻量调度能力：
- 任务提交与查询
- 多主机资源管理
- 本地进程执行与控制（暂停/恢复/终止）
- 基础监控与统计
"""

from .api import scheduler_blueprint, scheduler_service

__all__ = ["scheduler_blueprint", "scheduler_service"]
