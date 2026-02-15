from __future__ import annotations

from flask import Blueprint, jsonify, request

from .service import SchedulerService


def _resp(status: int, message: str, data=None):
    if data is None:
        data = {}
    return jsonify({"status": status, "message": message, "data": data}), status


scheduler_service = SchedulerService()
scheduler_blueprint = Blueprint("apr_scheduler", __name__)


@scheduler_blueprint.route("/health", methods=["GET"])
def health():
    return _resp(200, "ok", {"service": "apr_scheduler"})


@scheduler_blueprint.route("/hosts/register", methods=["POST"])
def register_host():
    try:
        payload = request.get_json() or {}
        host = scheduler_service.register_host(payload)
        return _resp(200, "success", host.to_dict())
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/hosts/<host_id>/heartbeat", methods=["POST"])
def heartbeat(host_id: str):
    try:
        host = scheduler_service.heartbeat(host_id)
        return _resp(200, "success", host.to_dict())
    except KeyError as exc:
        return _resp(404, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/hosts", methods=["GET"])
def list_hosts():
    hosts = scheduler_service.list_hosts()
    return _resp(200, "success", {"hosts": hosts})


@scheduler_blueprint.route("/jobs", methods=["POST"])
def submit_job():
    try:
        payload = request.get_json() or {}
        job = scheduler_service.submit_job(payload)
        return _resp(200, "success", job.to_dict())
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/batch", methods=["POST"])
def submit_jobs_batch():
    try:
        payload = request.get_json() or {}
        jobs_payload = payload.get("jobs") or []
        if not isinstance(jobs_payload, list):
            return _resp(400, "jobs must be a list")
        jobs = scheduler_service.submit_jobs(jobs_payload)
        return _resp(200, "success", {"jobs": [job.to_dict() for job in jobs]})
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs", methods=["GET"])
def list_jobs():
    status = request.args.get("status", default="", type=str)
    owner = request.args.get("owner", default="", type=str)
    project = request.args.get("project", default="", type=str)
    jobs = scheduler_service.list_jobs(status=status, owner=owner, project=project)
    return _resp(200, "success", {"jobs": jobs})


@scheduler_blueprint.route("/jobs/<job_id>", methods=["GET"])
def get_job(job_id: str):
    try:
        job = scheduler_service.get_job(job_id)
        events = scheduler_service.get_job_events(job_id)
        data = job.to_dict()
        data["events"] = events
        return _resp(200, "success", data)
    except KeyError as exc:
        return _resp(404, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/<job_id>/logs", methods=["GET"])
def get_job_logs(job_id: str):
    try:
        tail = request.args.get("tail", default=200, type=int)
        data = scheduler_service.get_job_logs(job_id, tail=tail)
        return _resp(200, "success", data)
    except KeyError as exc:
        return _resp(404, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/<job_id>/pause", methods=["POST"])
def pause_job(job_id: str):
    try:
        operator = request.args.get("operator", default="api", type=str)
        job = scheduler_service.pause_job(job_id, operator=operator)
        return _resp(200, "success", job.to_dict())
    except KeyError as exc:
        return _resp(404, str(exc))
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/<job_id>/resume", methods=["POST"])
def resume_job(job_id: str):
    try:
        operator = request.args.get("operator", default="api", type=str)
        job = scheduler_service.resume_job(job_id, operator=operator)
        return _resp(200, "success", job.to_dict())
    except KeyError as exc:
        return _resp(404, str(exc))
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/<job_id>/stop", methods=["POST"])
def stop_job(job_id: str):
    try:
        operator = request.args.get("operator", default="api", type=str)
        job = scheduler_service.stop_job(job_id, operator=operator)
        return _resp(200, "success", job.to_dict())
    except KeyError as exc:
        return _resp(404, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/jobs/<job_id>/rerun", methods=["POST"])
def rerun_job(job_id: str):
    try:
        operator = request.args.get("operator", default="api", type=str)
        new_job = scheduler_service.rerun_job(job_id, operator=operator)
        return _resp(200, "success", new_job.to_dict())
    except KeyError as exc:
        return _resp(404, str(exc))
    except ValueError as exc:
        return _resp(400, str(exc))
    except Exception as exc:
        return _resp(500, f"internal error: {exc}")


@scheduler_blueprint.route("/metrics/summary", methods=["GET"])
def metrics_summary():
    data = scheduler_service.metrics_summary()
    return _resp(200, "success", data)
