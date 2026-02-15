# APR Scheduler 使用说明（MVP）

本文说明如何使用新增的 APR 调度接口，在无商业调度器的场景下实现批量任务并行、监控和控制。

## 1. 功能概览

新增接口统一挂在 `/scheduler` 前缀下，支持：

- 主机注册与心跳
- 单任务/批量任务提交
- 队列调度与状态查询
- 日志查看
- 控制动作（pause/resume/stop/rerun）
- 汇总指标

## 2. 启动服务

沿用原有启动方式（确保已有环境变量 `EDX_TMP_BASE`）：

```bash
cd edx_server
python3 run_server.py --host 0.0.0.0 --port 5000
```

健康检查：

```bash
curl -X GET http://127.0.0.1:5000/scheduler/health
```

## 3. 注册5台服务器（示例）

```bash
curl -X POST http://127.0.0.1:5000/scheduler/hosts/register \
  -H "Content-Type: application/json" \
  -d '{
    "host_id": "host-a",
    "total_slots": 8,
    "total_cpu": 32,
    "total_memory_gb": 128,
    "executor_prefix": "ssh -o BatchMode=yes cad@10.0.0.11",
    "labels": {"tool": "innovus", "node": "A"}
  }'
```

你可以按相同格式注册 `host-b` ~ `host-e`。

心跳（建议每5秒一次）：

```bash
curl -X POST http://127.0.0.1:5000/scheduler/hosts/host-a/heartbeat
```

## 4. 提交任务

### 4.1 单任务

```bash
curl -X POST http://127.0.0.1:5000/scheduler/jobs \
  -H "Content-Type: application/json" \
  -d '{
    "project": "P1",
    "design": "top",
    "owner": "cad_user",
    "priority": 2,
    "timeout_sec": 3600,
    "retry_limit": 1,
    "workdir": "/tmp",
    "command": "bash -lc \"echo start && sleep 5 && echo done\"",
    "resource_request": {
      "cpu": 4,
      "memory_gb": 8,
      "slots": 1,
      "host_labels": {"tool": "innovus"}
    }
  }'
```

### 4.2 批量任务（100个）

参考 `apr_scheduler/examples/batch_jobs.json`，执行：

```bash
curl -X POST http://127.0.0.1:5000/scheduler/jobs/batch \
  -H "Content-Type: application/json" \
  -d @apr_scheduler/examples/batch_jobs.json
```

或者先生成100任务模板：

```bash
cd apr_scheduler/examples
python3 gen_batch_jobs.py --count 100 --output batch_jobs_100.json
curl -X POST http://127.0.0.1:5000/scheduler/jobs/batch \
  -H "Content-Type: application/json" \
  -d @batch_jobs_100.json
```

## 5. 监控与控制

任务列表：

```bash
curl -X GET "http://127.0.0.1:5000/scheduler/jobs?status=RUNNING"
```

任务详情（含事件）：

```bash
curl -X GET http://127.0.0.1:5000/scheduler/jobs/<job_id>
```

查看日志尾部：

```bash
curl -X GET "http://127.0.0.1:5000/scheduler/jobs/<job_id>/logs?tail=200"
```

暂停/恢复/终止/重跑：

```bash
curl -X POST http://127.0.0.1:5000/scheduler/jobs/<job_id>/pause
curl -X POST http://127.0.0.1:5000/scheduler/jobs/<job_id>/resume
curl -X POST http://127.0.0.1:5000/scheduler/jobs/<job_id>/stop
curl -X POST http://127.0.0.1:5000/scheduler/jobs/<job_id>/rerun
```

汇总指标：

```bash
curl -X GET http://127.0.0.1:5000/scheduler/metrics/summary
```

## 6. 调度规则（当前实现）

1. 优先级高的任务先调度（priority 越大优先级越高）。
2. 必须满足资源请求（slots/cpu/memory/host_labels）。
3. 在可用主机中选择当前负载更低的主机。
4. 失败任务支持自动重试（受 `retry_limit` 控制）。
5. 若主机配置了 `executor_prefix`，任务将通过该前缀命令执行（常见为SSH远程执行）。

## 7. 注意事项

1. 当前MVP调度器以内存保存元数据，服务重启后任务历史不会保留。
2. 控制动作 pause/resume 依赖 Linux 信号能力（SIGSTOP/SIGCONT），且仅适用于本地执行主机。
3. 若用于生产，建议增加持久化数据库、鉴权和告警模块。
