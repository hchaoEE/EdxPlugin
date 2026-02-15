#!/usr/bin/env python3
"""
生成批量任务JSON，用于/scheduler/jobs/batch接口。

示例:
python3 gen_batch_jobs.py --count 100 --output batch_jobs_100.json
"""

import argparse
import json


def build_jobs(count: int) -> dict:
    jobs = []
    for idx in range(1, count + 1):
        jobs.append(
            {
                "project": "P1",
                "design": f"top_variant_{idx:03d}",
                "owner": "cad_user",
                "priority": 1,
                "timeout_sec": 7200,
                "retry_limit": 1,
                "workdir": "/tmp",
                "command": f"bash -lc \"echo job{idx:03d} && sleep 5\"",
                "resource_request": {
                    "cpu": 2,
                    "memory_gb": 4,
                    "slots": 1,
                    "host_labels": {"tool": "innovus"},
                },
            }
        )
    return {"jobs": jobs}


def main():
    parser = argparse.ArgumentParser(description="Generate APR batch jobs payload")
    parser.add_argument("--count", type=int, default=100, help="job count")
    parser.add_argument("--output", type=str, default="batch_jobs_100.json", help="output JSON file")
    args = parser.parse_args()
    payload = build_jobs(args.count)
    with open(args.output, "w", encoding="utf-8") as fp:
        json.dump(payload, fp, indent=2, ensure_ascii=False)
    print(f"generated {args.count} jobs -> {args.output}")


if __name__ == "__main__":
    main()
