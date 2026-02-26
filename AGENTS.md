# AGENTS.md

## Cursor Cloud specific instructions

### Project Overview

EDX Plugin is a Python/Flask REST API server that bridges AI agents with EDA (Electronic Design Automation) tools. See `README_EDA_Flow_Bridge.md` for full API documentation (in Chinese).

### Services

| Service | Directory | Port | Command |
|---------|-----------|------|---------|
| Flask API Server | `edx_server/` | 5000 | `EDX_TMP_BASE=/tmp/edx_tmp python3 main.py` |
| Visualization Module | `edx_agent/` | N/A | `EDX_TMP_BASE=/tmp/edx_tmp MPLBACKEND=Agg python3 test_visualization.py` |

### Key Caveats

- **`EDX_TMP_BASE` is required**: The Flask server will crash on import if this env var is not set. Always export it before running any server code or importing `config.py`. A good default is `/tmp/edx_tmp`.
- **`EDX_INSTANCE_ID`** (optional, default `1`): Creates a subdirectory `tmp_<id>` under `EDX_TMP_BASE` for IPC files.
- **No external EDA tool available**: The Leapr EDA tool is external/commercial and not present in this environment. API endpoints that interact with the EDA tool (e.g. `load_netlist`, `get_timing`, `execute_tcl`, `place_cells`) will hang indefinitely waiting for file-based IPC responses. Only `GET /` (home), `POST /<tool>/upload_file`, and the visualization module can be fully tested without the EDA tool.
- **No linter or test framework configured**: The project has no `pytest`, `flake8`, `pylint`, or similar tooling. The only tests are curl-based scripts in `edx_server/test_api_curl.sh`.
- **Visualization CJK font warnings**: When running visualization on systems without Chinese fonts (SimHei), matplotlib will produce harmless glyph-missing warnings. Output images are still generated correctly.
- **`main.py` must be run from `edx_server/` directory**: The server uses relative paths for TCL scripts and log files. Always `cd edx_server` or set working directory before running.
- **Python path for `edx_agent`**: The `test_visualization.py` script adds `../edx_server` to `sys.path` at import time, so `EDX_TMP_BASE` must be set even when running visualization-only code.

### Standard Commands

- **Install deps**: `pip install -r requirements.txt`
- **Start server**: `cd edx_server && EDX_TMP_BASE=/tmp/edx_tmp python3 main.py`
- **Start server (script)**: `cd edx_server && EDX_TMP_BASE=/tmp/edx_tmp bash start_edx_server.sh`
- **Run API tests**: `cd edx_server && bash test_api_curl.sh` (requires server running)
- **Run visualization test**: `cd edx_agent && EDX_TMP_BASE=/tmp/edx_tmp MPLBACKEND=Agg python3 test_visualization.py`
