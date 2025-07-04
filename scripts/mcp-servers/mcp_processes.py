#!/usr/bin/env python3
"""
Background process manager MCP server for agent workflows.
Simple process tracking and management system.
"""

import json
import uuid
import os
import signal
import subprocess
import time
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path

from fastmcp import FastMCP

# Configuration
PROCESS_DIR = Path("/workspaces/.processes")
PROCESS_DIR.mkdir(exist_ok=True)
LOG_DIR = PROCESS_DIR / "logs"
LOG_DIR.mkdir(exist_ok=True)

# Create MCP server
mcp = FastMCP("Agent Process Manager")


def get_process_path(process_id: str) -> Path:
    """Get the file path for process metadata."""
    return PROCESS_DIR / f"proc_{process_id}.json"


def get_log_path(process_id: str) -> Path:
    """Get the file path for process logs."""
    return LOG_DIR / f"{process_id}.log"


def generate_process_id() -> str:
    """Generate a unique process ID."""
    return str(uuid.uuid4())


def save_process(process_data: Dict) -> None:
    """Save process metadata to disk."""
    process_path = get_process_path(process_data["id"])
    with open(process_path, "w") as f:
        json.dump(process_data, f, indent=2)


def load_process(process_id: str) -> Optional[Dict]:
    """Load process metadata from disk."""
    process_path = get_process_path(process_id)
    if not process_path.exists():
        return None

    try:
        with open(process_path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return None


def list_processes() -> List[Dict]:
    """List all processes in the process directory."""
    processes = []
    for file_path in PROCESS_DIR.glob("proc_*.json"):
        try:
            with open(file_path, "r") as f:
                process_data = json.load(f)
                # Update status based on actual process state
                process_data = update_process_status(process_data)
                processes.append(process_data)
        except (json.JSONDecodeError, IOError):
            # Skip corrupted files
            continue

    # Sort by start time (newest first)
    processes.sort(key=lambda x: x.get("started_at", ""), reverse=True)
    return processes


def update_process_status(process_data: Dict) -> Dict:
    """Update process status based on actual process state."""
    pid = process_data.get("pid")
    if not pid:
        process_data["status"] = "unknown"
        return process_data

    try:
        # Check if process is still running
        os.kill(pid, 0)  # Send null signal to check if process exists
        process_data["status"] = "running"
    except (OSError, ProcessLookupError):
        process_data["status"] = "stopped"

    return process_data


def is_process_running(pid: int) -> bool:
    """Check if a process is still running."""
    try:
        os.kill(pid, 0)
        return True
    except (OSError, ProcessLookupError):
        return False


@mcp.tool()
def mcp__process_start(command: str, cwd: str, name: str, owner: str) -> str:
    """
    Start a background process.

    Args:
        command: Command to execute
        cwd: Working directory for the process
        name: Human-readable name for the process
        owner: Agent name that owns this process

    Returns:
        Process ID of the started process
    """
    process_id = generate_process_id()
    timestamp = datetime.utcnow().isoformat() + "Z"
    log_file = get_log_path(process_id)

    try:
        # Start the process
        with open(log_file, "w") as log:
            process = subprocess.Popen(
                command,
                shell=True,
                cwd=cwd,
                stdout=log,
                stderr=subprocess.STDOUT,
                preexec_fn=os.setsid,  # Create new process group
            )

        # Save process metadata
        process_data = {
            "id": process_id,
            "name": name,
            "owner": owner,
            "command": command,
            "cwd": cwd,
            "pid": process.pid,
            "status": "running",
            "started_at": timestamp,
            "log_file": str(log_file),
        }

        save_process(process_data)
        return process_id

    except Exception as e:
        return f"Error starting process: {str(e)}"


@mcp.tool()
def mcp__process_list(owner: Optional[str] = None) -> List[Dict]:
    """
    List processes (optionally filtered by owner).

    Args:
        owner: Optional agent name to filter by

    Returns:
        List of process summaries
    """
    processes = list_processes()

    if owner:
        processes = [p for p in processes if p.get("owner") == owner]

    # Return summary information
    summaries = []
    for process in processes:
        summary = {
            "id": process["id"],
            "name": process["name"],
            "owner": process["owner"],
            "status": process["status"],
            "started_at": process["started_at"],
            "pid": process.get("pid"),
        }
        summaries.append(summary)

    return summaries


@mcp.tool()
def mcp__process_logs(process_id: str, lines: int = 50) -> str:
    """
    Get process output logs.

    Args:
        process_id: ID of the process
        lines: Number of lines to return (default 50)

    Returns:
        Log content as string
    """
    log_file = get_log_path(process_id)

    if not log_file.exists():
        return f"No logs found for process {process_id}"

    try:
        # Read last N lines
        with open(log_file, "r") as f:
            all_lines = f.readlines()
            if lines > 0:
                last_lines = all_lines[-lines:]
            else:
                last_lines = all_lines
            return "".join(last_lines)
    except IOError as e:
        return f"Error reading logs: {str(e)}"


@mcp.tool()
def mcp__process_stop(process_id: str) -> bool:
    """
    Stop a process.

    Args:
        process_id: ID of the process to stop

    Returns:
        True if stopped successfully, False otherwise
    """
    process_data = load_process(process_id)
    if not process_data:
        return False

    pid = process_data.get("pid")
    if not pid:
        return False

    try:
        # Try graceful shutdown first
        os.killpg(os.getpgid(pid), signal.SIGTERM)
        time.sleep(2)

        # Check if process is still running
        if is_process_running(pid):
            # Force kill if still running
            os.killpg(os.getpgid(pid), signal.SIGKILL)

        # Update process status
        process_data["status"] = "stopped"
        process_data["stopped_at"] = datetime.utcnow().isoformat() + "Z"
        save_process(process_data)

        return True

    except (OSError, ProcessLookupError):
        # Process already stopped
        process_data["status"] = "stopped"
        save_process(process_data)
        return True


@mcp.tool()
def mcp__process_restart(process_id: str) -> bool:
    """
    Restart a process.

    Args:
        process_id: ID of the process to restart

    Returns:
        True if restarted successfully, False otherwise
    """
    process_data = load_process(process_id)
    if not process_data:
        return False

    # Stop the process first
    if not mcp__process_stop(process_id):
        return False

    # Start it again with the same parameters
    new_process_id = mcp__process_start(
        command=process_data["command"],
        cwd=process_data["cwd"],
        name=process_data["name"],
        owner=process_data["owner"],
    )

    return not new_process_id.startswith("Error")


@mcp.tool()
def mcp__process_cleanup() -> Dict:
    """
    Clean up stopped processes and their metadata.

    Returns:
        Summary of cleanup operation
    """
    processes = list_processes()
    cleaned_count = 0

    for process in processes:
        if process["status"] == "stopped":
            # Remove process metadata
            process_path = get_process_path(process["id"])
            if process_path.exists():
                process_path.unlink()

            # Optionally remove old log files (keep recent ones)
            log_path = get_log_path(process["id"])
            if log_path.exists():
                # Keep logs for debugging, don't auto-delete
                pass

            cleaned_count += 1

    return {
        "cleaned_processes": cleaned_count,
        "remaining_processes": len(processes) - cleaned_count,
    }


if __name__ == "__main__":
    # Create README if it doesn't exist
    readme_path = PROCESS_DIR / "README.md"
    if not readme_path.exists():
        with open(readme_path, "w") as f:
            f.write("""# Agent Process Manager

This directory contains metadata for background processes started by agents.

## Structure
- `proc_<uuid>.json` - Process metadata files
- `logs/` - Process log files
- `README.md` - This file

## Process Metadata Format
```json
{
  "id": "proc_<uuid4>",
  "name": "webserver",
  "owner": "feat-dashboard",
  "command": "python app.py",
  "cwd": "/workspaces/feat-dashboard",
  "pid": 12345,
  "status": "running",
  "started_at": "2024-07-03T10:30:00Z",
  "log_file": "/workspaces/.processes/logs/<uuid>.log"
}
```

## Usage
Processes are managed through the MCP process server tools:
- `mcp__process_start` - Start a background process
- `mcp__process_list` - List processes
- `mcp__process_logs` - Get process logs
- `mcp__process_stop` - Stop a process
- `mcp__process_restart` - Restart a process
- `mcp__process_cleanup` - Clean up stopped processes
""")

    mcp.run()
