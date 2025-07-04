# Interface Specifications

## MCP Server Interfaces

### Mail System (`mcp_mail.py`)

**Purpose**: Simple file-based mail exchange for agent communication

**MCP Tools:**
```python
@server.tool("mcp__mail_send")
def mail_send(from_agent: str, to_agents: List[str], subject: str, body: str) -> str:
    """Send mail to one or more agents"""
    # Returns: message_id (uuid4)

@server.tool("mcp__mail_inbox") 
def mail_inbox(to_agent: str) -> List[Dict]:
    """Get inbox summary for an agent"""
    # Returns: List of {id, from, subject, timestamp, read}

@server.tool("mcp__mail_read")
def mail_read(message_id: str) -> Dict:
    """Read full message and mark as read"""
    # Returns: Complete message dict

@server.tool("mcp__mail_delete")
def mail_delete(message_id: str) -> bool:
    """Delete a message"""
    # Returns: success boolean
```

**File Storage:**
- Location: `/workspaces/.mail/`
- Format: `msg_<uuid4>.json`
- Schema:
```json
{
  "id": "msg_<uuid4>",
  "from": "agent-name",
  "to": ["recipient1", "recipient2"],
  "subject": "Task update", 
  "body": "Message content here",
  "timestamp": "2024-07-03T10:30:00Z",
  "read": false
}
```

### Background Process Manager (`mcp_processes.py`)

**Purpose**: Track and manage background processes started by agents

**MCP Tools:**
```python
@server.tool("mcp__process_start")
def process_start(command: str, cwd: str, name: str, owner: str) -> str:
    """Start a background process"""
    # Returns: process_id (uuid4)

@server.tool("mcp__process_list")
def process_list(owner: Optional[str] = None) -> List[Dict]:
    """List processes (optionally filtered by owner)"""
    # Returns: List of {id, name, owner, status, started_at}

@server.tool("mcp__process_logs")
def process_logs(process_id: str, lines: int = 50) -> str:
    """Get process output logs"""
    # Returns: log content as string

@server.tool("mcp__process_stop")
def process_stop(process_id: str) -> bool:
    """Stop a process"""
    # Returns: success boolean

@server.tool("mcp__process_restart")
def process_restart(process_id: str) -> bool:
    """Restart a process"""
    # Returns: success boolean
```

**File Storage:**
- Metadata: `/workspaces/.processes/proc_<uuid4>.json`
- Logs: `/workspaces/.processes/logs/<uuid4>.log`
- Schema:
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
  "env": {"PORT": "3001"}
}
```

## Agent Environment Interface

### Resource Allocation (`.env` file)

**Standard Variables:**
```bash
# Agent identification
AGENT_NAME=feat-dashboard
WORKTREE_PATH=/workspaces/feat-dashboard

# Port allocation
MAIN_PORT=3001
API_PORT=3002
DEBUG_PORT=3003
PORT_RANGE=3001-3010

# Task context
TASK_DESCRIPTION="Implement user dashboard with charts"
BRANCH_NAME=feat/dashboard
BASE_BRANCH=main

# Common paths
TMP_DIR=/workspaces/feat-dashboard/tmp
LOG_DIR=/workspaces/feat-dashboard/logs
```

### Agent Instructions (`prompt.md`)

**Template Structure:**
```markdown
# Agent Task: [Task Name]

## Context
- **Project**: [Project description]
- **Task**: [Specific task description]
- **Priority**: [High/Medium/Low]
- **Deadline**: [If applicable]

## Resources
- **Worktree**: `/workspaces/[worktree-name]`
- **Branch**: `[branch-name]`
- **Ports**: [Port allocation details]
- **Environment**: Source `.env` file for configuration

## Task Requirements
1. [Specific requirement 1]
2. [Specific requirement 2]
3. [Specific requirement 3]

## Constraints
- [Any limitations or constraints]
- [Dependencies or blockers]
- [Must-not-do items]

## Definition of Done
- [ ] [Acceptance criteria 1]
- [ ] [Acceptance criteria 2]
- [ ] [Code committed with conventional commits]
- [ ] [Tests passing (if applicable)]

## Communication
- **Mail system**: Use `mcp__mail_send` to communicate
- **Status updates**: Send progress updates to `central-planner`
- **Blockers**: Immediately notify if blocked

## Common Commands
```bash
# Start working
cd /workspaces/[worktree-name]
source .env

# Common development commands
[Tool-specific commands]
```

## References
- [Link to relevant documentation]
- [Related issues or tasks]
```

## Utility Scripts Interface

### Agent Management Scripts

**`list-agents.sh`**
```bash
#!/bin/bash
# List all running agents and their status
# Usage: ./list-agents.sh [--json]
```

**`setup-agent.sh`**
```bash
#!/bin/bash
# Helper script for central planner to set up agent environment
# Usage: ./setup-agent.sh <worktree-name> <branch-name> <task-description>
```

**`cleanup-worktree.sh`**
```bash
#!/bin/bash
# Clean up completed or abandoned worktrees
# Usage: ./cleanup-worktree.sh <worktree-name> [--force]
```

## Docker Compose Interface

### Service Definition
```yaml
version: '3.8'
services:
  coding-agent:
    build: .
    volumes:
      - ${HOME}/workspaces:/workspaces
      - claude_auth:/home/user/.claude
      - gemini_auth:/home/user/.gemini
      - gh_auth:/home/user/.config/gh
      - bash_history:/home/user/.bash_history
    ports:
      - "5000:5000"  # Main branch port
    environment:
      - OTLP_ENDPOINT=${OTLP_ENDPOINT:-}
      - HONEYCOMB_API_KEY=${HONEYCOMB_API_KEY:-}
    stdin_open: true
    tty: true
    command: /bin/bash

volumes:
  claude_auth:
  gemini_auth:
  gh_auth:
  bash_history:
```

### Docker Commands
```bash
# Start environment
docker-compose up -d

# Attach to container
docker-compose exec coding-agent bash

# VSCode integration
code --folder /workspaces
```

## Git Integration Interface

### Worktree Management
```bash
# Create new worktree (done by central planner)
git worktree add ../feat-dashboard main

# List worktrees
git worktree list

# Remove worktree
git worktree remove ../feat-dashboard
```

### Branch Management
```bash
# Create and switch to branch
git checkout -b feat/dashboard

# Commit with conventional format
git commit -m "feat: add user dashboard component"

# Push branch
git push -u origin feat/dashboard
```

## Error Handling Interface

### Mail System Errors
- **File corruption**: Skip corrupted files, log error
- **Permission issues**: Fail gracefully with clear error message
- **Disk full**: Return error, suggest cleanup

### Process Manager Errors
- **Process not found**: Return false, log warning
- **Permission denied**: Return error with explanation
- **Resource exhaustion**: Log error, suggest cleanup

### Recovery Procedures
1. **Corrupted mail**: Delete corrupted files, continue operation
2. **Dead processes**: Clean up process metadata, log event
3. **Disk issues**: Provide cleanup suggestions, pause operations

## Testing Interface

### MCP Server Testing
```python
# Test mail system
pytest tests/test_mcp_mail.py

# Test process manager
pytest tests/test_mcp_processes.py
```

### Integration Testing
```bash
# Test agent workflow
./tests/test_agent_workflow.sh

# Test multi-agent communication
./tests/test_multi_agent.sh
```

## Monitoring Interface

### Health Checks
```bash
# Check mail system
./health/check_mail.sh

# Check processes
./health/check_processes.sh

# Check disk usage
./health/check_disk.sh
```

### OTLP Integration
- **Existing**: claude-code sends telemetry automatically
- **Collection**: Manual OTLP collector startup
- **Destination**: Honeycomb.io EU servers
- **Metrics**: Token usage, API costs, response times