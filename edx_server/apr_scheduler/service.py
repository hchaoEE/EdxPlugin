from __future__ import annotations

import os
import shlex
import signal
import subprocess
import threading
import time
import uuid
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any

from .models import Event, Host, Job, JobStatus, ResourceRequest, utc_now_iso


def now_ts() -> float:
    return datetime.now(timezone.utc).timestamp()


@dataclass
class ProcessHandle:
    process: subprocess.Popen
    host_id: str
    start_ts: float


class SchedulerService:
    def __init__(
        self,
        data_dir: str = "",
        heartbeat_timeout_sec: int = 20,
        schedule_interval_sec: float = 1.0,
    ):
        base = data_dir or os.environ.get("APR_SCHEDULER_DATA_DIR", "/tmp/apr_scheduler")
        self.data_dir = base
        self.log_dir = os.path.join(self.data_dir, "logs")
        os.makedirs(self.log_dir, exist_ok=True)

        self.heartbeat_timeout_sec = heartbeat_timeout_sec
        self.schedule_interval_sec = schedule_interval_sec

        self.jobs: dict[str, Job] = {}
        self.hosts: dict[str, Host] = {}
        self.events: dict[str, list[Event]] = {}

        self._processes: dict[str, ProcessHandle] = {}
        self._lock = threading.RLock()
        self._stop_event = threading.Event()
        self._scheduler_thread = threading.Thread(target=self._schedule_loop, daemon=True)
        self._scheduler_thread.start()

    def _new_id(self, prefix: str) -> str:
        return f"{prefix}_{uuid.uuid4().hex[:10]}"

    def _append_event(self, job_id: str, event_type: str, message: str, operator: str = "system") -> None:
        event = Event(
            event_id=self._new_id("evt"),
            job_id=job_id,
            event_type=event_type,
            message=message,
            operator=operator,
        )
        self.events.setdefault(job_id, []).append(event)

    def register_host(self, payload: dict[str, Any]) -> Host:
        host_id = (payload.get("host_id") or "").strip()
        if not host_id:
            raise ValueError("host_id is required")
        total_slots = int(payload.get("total_slots", 1))
        total_cpu = int(payload.get("total_cpu", total_slots))
        total_memory_gb = int(payload.get("total_memory_gb", max(total_slots * 2, 2)))
        labels = payload.get("labels") or {}
        executor_prefix = str(payload.get("executor_prefix", "")).strip()
        if total_slots <= 0:
            raise ValueError("total_slots must be > 0")
        with self._lock:
            if host_id in self.hosts:
                host = self.hosts[host_id]
                host.total_slots = total_slots
                host.total_cpu = total_cpu
                host.total_memory_gb = total_memory_gb
                host.labels = labels
                host.executor_prefix = executor_prefix
                host.status = "ONLINE"
                host.last_heartbeat_at = utc_now_iso()
            else:
                host = Host(
                    host_id=host_id,
                    total_slots=total_slots,
                    total_cpu=total_cpu,
                    total_memory_gb=total_memory_gb,
                    labels=labels,
                    executor_prefix=executor_prefix,
                )
                self.hosts[host_id] = host
            return host

    def heartbeat(self, host_id: str) -> Host:
        with self._lock:
            host = self.hosts.get(host_id)
            if not host:
                raise KeyError(f"host {host_id} not found")
            host.status = "ONLINE"
            host.last_heartbeat_at = utc_now_iso()
            return host

    def list_hosts(self) -> list[dict[str, Any]]:
        with self._lock:
            return [h.to_dict() for h in self.hosts.values()]

    def submit_job(self, payload: dict[str, Any]) -> Job:
        command = (payload.get("command") or "").strip()
        if not command:
            raise ValueError("command is required")
        owner = (payload.get("owner") or "unknown").strip()
        project = (payload.get("project") or "default").strip()
        design = (payload.get("design") or "").strip()
        priority = int(payload.get("priority", 1))
        timeout_sec = int(payload.get("timeout_sec", 0))
        retry_limit = int(payload.get("retry_limit", 0))
        workdir = payload.get("workdir") or "."
        env = payload.get("env") or {}
        req_obj = payload.get("resource_request") or {}
        request = ResourceRequest(
            cpu=int(req_obj.get("cpu", 1)),
            memory_gb=int(req_obj.get("memory_gb", 2)),
            slots=int(req_obj.get("slots", 1)),
            license_tokens=int(req_obj.get("license_tokens", 1)),
            tool_version=str(req_obj.get("tool_version", "")),
            host_labels=req_obj.get("host_labels") or {},
        )
        if request.slots <= 0:
            raise ValueError("resource_request.slots must be > 0")
        if request.cpu <= 0:
            raise ValueError("resource_request.cpu must be > 0")
        if request.memory_gb <= 0:
            raise ValueError("resource_request.memory_gb must be > 0")

        job_id = self._new_id("job")
        job = Job(
            job_id=job_id,
            command=command,
            project=project,
            design=design,
            owner=owner,
            priority=priority,
            timeout_sec=timeout_sec,
            retry_limit=retry_limit,
            resource_request=request,
            workdir=workdir,
            env=env,
            status=JobStatus.QUEUED,
            queued_at=utc_now_iso(),
            stage="queued",
        )
        with self._lock:
            self.jobs[job.job_id] = job
            self._append_event(job.job_id, "SUBMITTED", f"job submitted by {owner}", operator=owner)
        return job

    def submit_jobs(self, payloads: list[dict[str, Any]]) -> list[Job]:
        jobs: list[Job] = []
        for payload in payloads:
            jobs.append(self.submit_job(payload))
        return jobs

    def get_job(self, job_id: str) -> Job:
        with self._lock:
            job = self.jobs.get(job_id)
            if not job:
                raise KeyError(f"job {job_id} not found")
            return job

    def list_jobs(self, status: str = "", owner: str = "", project: str = "") -> list[dict[str, Any]]:
        with self._lock:
            jobs = list(self.jobs.values())
            if status:
                jobs = [j for j in jobs if j.status.value == status]
            if owner:
                jobs = [j for j in jobs if j.owner == owner]
            if project:
                jobs = [j for j in jobs if j.project == project]
            jobs.sort(key=lambda item: item.created_at, reverse=True)
            return [j.to_dict() for j in jobs]

    def get_job_events(self, job_id: str) -> list[dict[str, Any]]:
        with self._lock:
            return [e.to_dict() for e in self.events.get(job_id, [])]

    def get_job_logs(self, job_id: str, tail: int = 200) -> dict[str, Any]:
        job = self.get_job(job_id)
        if not job.log_path:
            return {"job_id": job_id, "log_path": "", "lines": []}
        if not os.path.exists(job.log_path):
            return {"job_id": job_id, "log_path": job.log_path, "lines": []}
        with open(job.log_path, "r", encoding="utf-8", errors="replace") as fp:
            lines = fp.readlines()
        tail = max(tail, 1)
        return {
            "job_id": job_id,
            "log_path": job.log_path,
            "lines": [line.rstrip("\n") for line in lines[-tail:]],
        }

    def stop_job(self, job_id: str, operator: str = "system") -> Job:
        with self._lock:
            job = self.jobs.get(job_id)
            if not job:
                raise KeyError(f"job {job_id} not found")
            if job.status in {JobStatus.SUCCESS, JobStatus.FAILED, JobStatus.CANCELLED, JobStatus.TIMEOUT}:
                return job
            handle = self._processes.get(job_id)
            if handle:
                handle.process.terminate()
                self._append_event(job_id, "STOP", "terminate signal sent", operator=operator)
                job.message = "terminate signal sent"
            else:
                job.status = JobStatus.CANCELLED
                job.finished_at = utc_now_iso()
                job.updated_at = utc_now_iso()
                job.message = "cancelled before dispatch"
                self._append_event(job_id, "STOP", "cancelled in queue", operator=operator)
            return job

    def pause_job(self, job_id: str, operator: str = "system") -> Job:
        with self._lock:
            job = self.jobs.get(job_id)
            if not job:
                raise KeyError(f"job {job_id} not found")
            host = self.hosts.get(job.assigned_host_id)
            if host and host.executor_prefix:
                raise ValueError("pause is not supported for remote executor host")
            handle = self._processes.get(job_id)
            if not handle:
                raise ValueError("job is not running")
            if job.status == JobStatus.PAUSED:
                return job
            os.kill(handle.process.pid, signal.SIGSTOP)
            job.status = JobStatus.PAUSED
            job.updated_at = utc_now_iso()
            job.message = "paused by operator"
            self._append_event(job_id, "PAUSE", "paused by operator", operator=operator)
            return job

    def resume_job(self, job_id: str, operator: str = "system") -> Job:
        with self._lock:
            job = self.jobs.get(job_id)
            if not job:
                raise KeyError(f"job {job_id} not found")
            host = self.hosts.get(job.assigned_host_id)
            if host and host.executor_prefix:
                raise ValueError("resume is not supported for remote executor host")
            handle = self._processes.get(job_id)
            if not handle:
                raise ValueError("job is not running")
            if job.status != JobStatus.PAUSED:
                return job
            os.kill(handle.process.pid, signal.SIGCONT)
            job.status = JobStatus.RUNNING
            job.updated_at = utc_now_iso()
            job.message = "resumed by operator"
            self._append_event(job_id, "RESUME", "resumed by operator", operator=operator)
            return job

    def rerun_job(self, job_id: str, operator: str = "system") -> Job:
        old_job = self.get_job(job_id)
        if not old_job.status.is_terminal:
            raise ValueError("only terminal jobs can rerun")
        new_job = self.submit_job(
            {
                "command": old_job.command,
                "project": old_job.project,
                "design": old_job.design,
                "owner": old_job.owner,
                "priority": old_job.priority,
                "timeout_sec": old_job.timeout_sec,
                "retry_limit": old_job.retry_limit,
                "resource_request": old_job.resource_request.to_dict(),
                "workdir": old_job.workdir,
                "env": old_job.env,
            }
        )
        with self._lock:
            new_job.parent_job_id = old_job.job_id
            self._append_event(new_job.job_id, "RERUN", f"rerun from {old_job.job_id}", operator=operator)
        return new_job

    def metrics_summary(self) -> dict[str, Any]:
        with self._lock:
            jobs = list(self.jobs.values())
            total = len(jobs)
            status_counts: dict[str, int] = {}
            for job in jobs:
                status_counts[job.status.value] = status_counts.get(job.status.value, 0) + 1
            success = status_counts.get(JobStatus.SUCCESS.value, 0)
            failed = status_counts.get(JobStatus.FAILED.value, 0)
            timeout = status_counts.get(JobStatus.TIMEOUT.value, 0)
            cancelled = status_counts.get(JobStatus.CANCELLED.value, 0)
            finished = success + failed + timeout + cancelled
            success_rate = (success / finished) if finished else 0.0
            host_list = list(self.hosts.values())
            cluster_slots = sum(h.total_slots for h in host_list)
            used_slots = sum(h.used_slots for h in host_list)
            return {
                "total_jobs": total,
                "status_counts": status_counts,
                "finished_jobs": finished,
                "success_rate": round(success_rate, 4),
                "total_hosts": len(host_list),
                "total_slots": cluster_slots,
                "used_slots": used_slots,
            }

    def _mark_offline_hosts(self) -> None:
        with self._lock:
            for host in self.hosts.values():
                dt = now_ts() - datetime.fromisoformat(host.last_heartbeat_at).timestamp()
                if dt > self.heartbeat_timeout_sec:
                    host.status = "OFFLINE"

    def _pick_host_for_job(self, job: Job) -> Host | None:
        candidates = [h for h in self.hosts.values() if h.can_run(job.resource_request)]
        if not candidates:
            return None
        candidates.sort(key=lambda h: (h.used_slots, h.used_cpu, h.host_id))
        return candidates[0]

    def _dispatch_one_job(self, job: Job, host: Host) -> None:
        job.status = JobStatus.DISPATCHED
        job.assigned_host_id = host.host_id
        job.stage = "dispatching"
        job.updated_at = utc_now_iso()
        host.allocate(job.job_id, job.resource_request)
        self._append_event(job.job_id, "DISPATCHED", f"dispatched to host {host.host_id}")
        threading.Thread(target=self._run_job_process, args=(job.job_id,), daemon=True).start()

    def _run_job_process(self, job_id: str) -> None:
        log_file = None
        with self._lock:
            job = self.jobs.get(job_id)
            if not job:
                return
            workdir = os.path.abspath(job.workdir)
            os.makedirs(workdir, exist_ok=True)
            log_path = os.path.join(self.log_dir, f"{job.job_id}.log")
            job.log_path = log_path
            host = self.hosts.get(job.assigned_host_id)
            if not host:
                job.status = JobStatus.FAILED
                job.message = "host not found"
                job.finished_at = utc_now_iso()
                job.updated_at = utc_now_iso()
                self._append_event(job_id, "FAILED", "host not found during dispatch")
                return
            env = os.environ.copy()
            env.update({str(k): str(v) for k, v in job.env.items()})
            cmd = job.command
            cwd = workdir
            if host.executor_prefix:
                env_exports = " ".join(
                    f"export {k}={shlex.quote(str(v))};" for k, v in sorted(job.env.items())
                )
                remote_workdir = shlex.quote(job.workdir)
                remote_cmd = f"{env_exports} mkdir -p {remote_workdir}; cd {remote_workdir}; {job.command}"
                cmd = f"{host.executor_prefix} {shlex.quote(remote_cmd)}"
                cwd = os.getcwd()
                env = os.environ.copy()
            log_file = open(log_path, "a", encoding="utf-8")
            process = subprocess.Popen(
                cmd,
                shell=True,
                cwd=cwd,
                stdout=log_file,
                stderr=subprocess.STDOUT,
                env=env,
                text=True,
                preexec_fn=os.setsid,
            )
            self._processes[job_id] = ProcessHandle(process=process, host_id=job.assigned_host_id, start_ts=now_ts())
            job.status = JobStatus.RUNNING
            job.stage = "running"
            job.started_at = utc_now_iso()
            job.updated_at = utc_now_iso()
            self._append_event(job_id, "RUNNING", f"pid={process.pid}, host={host.host_id}")

        timed_out = False
        exit_code: int | None = None
        while True:
            with self._lock:
                handle = self._processes.get(job_id)
                current_job = self.jobs.get(job_id)
            if not handle or not current_job:
                break
            if current_job.timeout_sec > 0 and (now_ts() - handle.start_ts) > current_job.timeout_sec:
                timed_out = True
                try:
                    os.killpg(os.getpgid(handle.process.pid), signal.SIGTERM)
                except ProcessLookupError:
                    pass
            exit_code = handle.process.poll()
            if exit_code is not None:
                break
            time.sleep(0.5)

        with self._lock:
            handle = self._processes.pop(job_id, None)
            job = self.jobs.get(job_id)
            if not handle or not job:
                return
            host = self.hosts.get(handle.host_id)
            if host:
                host.release(job_id, job.resource_request)

            if timed_out:
                job.status = JobStatus.TIMEOUT
                job.message = "timeout reached"
                self._append_event(job_id, "TIMEOUT", f"timeout at {job.timeout_sec}s")
            elif job.status == JobStatus.PAUSED:
                # 保护分支：被外部改为PAUSED但进程结束了
                job.status = JobStatus.FAILED
                job.message = "paused job exited unexpectedly"
                self._append_event(job_id, "FAILED", "paused job exited unexpectedly")
            else:
                if exit_code == 0:
                    job.status = JobStatus.SUCCESS
                    job.message = "completed successfully"
                    self._append_event(job_id, "SUCCESS", "exit code 0")
                else:
                    # 终止命令通常会得到非零退出码，这里判断是否来自用户stop
                    if job.message.startswith("terminate signal sent"):
                        job.status = JobStatus.CANCELLED
                        self._append_event(job_id, "CANCELLED", "stopped by operator")
                    else:
                        job.status = JobStatus.FAILED
                        job.message = f"exit code {exit_code}"
                        self._append_event(job_id, "FAILED", f"exit code {exit_code}")

            job.exit_code = exit_code
            job.stage = "finished"
            job.finished_at = utc_now_iso()
            job.updated_at = utc_now_iso()

            # 自动重试：仅对FAILED生效
            if job.status == JobStatus.FAILED and job.retry_count < job.retry_limit:
                job.retry_count += 1
                job.status = JobStatus.RETRYING
                job.stage = "retrying"
                job.updated_at = utc_now_iso()
                self._append_event(job.job_id, "RETRYING", f"retry {job.retry_count}/{job.retry_limit}")
                job.status = JobStatus.QUEUED
                job.assigned_host_id = ""
                job.queued_at = utc_now_iso()
                job.stage = "queued"
                job.finished_at = ""
                job.exit_code = None
                job.message = f"retry {job.retry_count}/{job.retry_limit}"
        if log_file:
            log_file.close()

    def _schedule_loop(self) -> None:
        while not self._stop_event.is_set():
            self._mark_offline_hosts()
            with self._lock:
                queued = [j for j in self.jobs.values() if j.status == JobStatus.QUEUED]
                queued.sort(key=lambda j: (-j.priority, j.created_at))
                for job in queued:
                    host = self._pick_host_for_job(job)
                    if not host:
                        continue
                    self._dispatch_one_job(job, host)
            time.sleep(self.schedule_interval_sec)

    def shutdown(self) -> None:
        self._stop_event.set()
        self._scheduler_thread.join(timeout=2)
