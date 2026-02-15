from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any


def utc_now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


class JobStatus(str, Enum):
    CREATED = "CREATED"
    QUEUED = "QUEUED"
    DISPATCHED = "DISPATCHED"
    RUNNING = "RUNNING"
    PAUSED = "PAUSED"
    RETRYING = "RETRYING"
    SUCCESS = "SUCCESS"
    FAILED = "FAILED"
    CANCELLED = "CANCELLED"
    TIMEOUT = "TIMEOUT"

    @property
    def is_terminal(self) -> bool:
        return self in {
            JobStatus.SUCCESS,
            JobStatus.FAILED,
            JobStatus.CANCELLED,
            JobStatus.TIMEOUT,
        }


@dataclass
class ResourceRequest:
    cpu: int = 1
    memory_gb: int = 2
    slots: int = 1
    license_tokens: int = 1
    tool_version: str = ""
    host_labels: dict[str, str] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "cpu": self.cpu,
            "memory_gb": self.memory_gb,
            "slots": self.slots,
            "license_tokens": self.license_tokens,
            "tool_version": self.tool_version,
            "host_labels": self.host_labels,
        }


@dataclass
class Host:
    host_id: str
    total_slots: int
    total_cpu: int
    total_memory_gb: int
    labels: dict[str, str] = field(default_factory=dict)
    executor_prefix: str = ""
    used_slots: int = 0
    used_cpu: int = 0
    used_memory_gb: int = 0
    status: str = "ONLINE"
    last_heartbeat_at: str = field(default_factory=utc_now_iso)
    running_jobs: list[str] = field(default_factory=list)

    def can_run(self, request: ResourceRequest) -> bool:
        if self.status != "ONLINE":
            return False
        if self.used_slots + request.slots > self.total_slots:
            return False
        if self.used_cpu + request.cpu > self.total_cpu:
            return False
        if self.used_memory_gb + request.memory_gb > self.total_memory_gb:
            return False
        for key, value in request.host_labels.items():
            if self.labels.get(key) != value:
                return False
        return True

    def allocate(self, job_id: str, request: ResourceRequest) -> None:
        self.used_slots += request.slots
        self.used_cpu += request.cpu
        self.used_memory_gb += request.memory_gb
        self.running_jobs.append(job_id)

    def release(self, job_id: str, request: ResourceRequest) -> None:
        self.used_slots = max(self.used_slots - request.slots, 0)
        self.used_cpu = max(self.used_cpu - request.cpu, 0)
        self.used_memory_gb = max(self.used_memory_gb - request.memory_gb, 0)
        if job_id in self.running_jobs:
            self.running_jobs.remove(job_id)

    def to_dict(self) -> dict[str, Any]:
        return {
            "host_id": self.host_id,
            "total_slots": self.total_slots,
            "total_cpu": self.total_cpu,
            "total_memory_gb": self.total_memory_gb,
            "labels": self.labels,
            "executor_prefix": self.executor_prefix,
            "used_slots": self.used_slots,
            "used_cpu": self.used_cpu,
            "used_memory_gb": self.used_memory_gb,
            "status": self.status,
            "last_heartbeat_at": self.last_heartbeat_at,
            "running_jobs": self.running_jobs,
        }


@dataclass
class Job:
    job_id: str
    command: str
    project: str
    design: str
    owner: str
    priority: int = 1
    timeout_sec: int = 0
    retry_limit: int = 0
    resource_request: ResourceRequest = field(default_factory=ResourceRequest)
    workdir: str = "."
    env: dict[str, str] = field(default_factory=dict)
    status: JobStatus = JobStatus.CREATED
    assigned_host_id: str = ""
    created_at: str = field(default_factory=utc_now_iso)
    queued_at: str = ""
    started_at: str = ""
    finished_at: str = ""
    updated_at: str = field(default_factory=utc_now_iso)
    stage: str = ""
    message: str = ""
    retry_count: int = 0
    exit_code: int | None = None
    log_path: str = ""
    parent_job_id: str = ""

    def to_dict(self) -> dict[str, Any]:
        return {
            "job_id": self.job_id,
            "command": self.command,
            "project": self.project,
            "design": self.design,
            "owner": self.owner,
            "priority": self.priority,
            "timeout_sec": self.timeout_sec,
            "retry_limit": self.retry_limit,
            "resource_request": self.resource_request.to_dict(),
            "workdir": self.workdir,
            "env": self.env,
            "status": self.status.value,
            "assigned_host_id": self.assigned_host_id,
            "created_at": self.created_at,
            "queued_at": self.queued_at,
            "started_at": self.started_at,
            "finished_at": self.finished_at,
            "updated_at": self.updated_at,
            "stage": self.stage,
            "message": self.message,
            "retry_count": self.retry_count,
            "exit_code": self.exit_code,
            "log_path": self.log_path,
            "parent_job_id": self.parent_job_id,
        }


@dataclass
class Event:
    event_id: str
    job_id: str
    event_type: str
    message: str
    operator: str = "system"
    created_at: str = field(default_factory=utc_now_iso)

    def to_dict(self) -> dict[str, str]:
        return {
            "event_id": self.event_id,
            "job_id": self.job_id,
            "event_type": self.event_type,
            "message": self.message,
            "operator": self.operator,
            "created_at": self.created_at,
        }
