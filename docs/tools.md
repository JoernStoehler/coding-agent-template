# Available Tools and Commands

This reference covers all tools, scripts, and MCP servers available to agents.

## MCP Servers

MCP (Model Context Protocol) servers provide tools that agents can call directly.

### Mail System

Located in `scripts/mcp-servers/mcp_mail.py`, provides inter-agent communication.

**mcp__mail__mcp__mail_send**
```python
# Send a message
mcp__mail__mcp__mail_send(
    from_agent="feature-agent",
    to_agents=["orchestrator", "test-agent"],
    subject="Feature Complete",
    body="Dashboard implementation ready for testing."
)
```

**mcp__mail__mcp__mail_inbox**
```python
# Check messages (returns summaries without body)
messages = mcp__mail__mcp__mail_inbox(to_agent="feature-agent")
for msg in messages:
    print(f"{msg['from']}: {msg['subject']}")
```

**mcp__mail__mcp__mail_read**
```python
# Read full message and mark as read
message = mcp__mail__mcp__mail_read(message_id="msg_550e8...")
print(message['body'])
```

**mcp__mail__mcp__mail_delete**
```python
# Delete a message
success = mcp__mail__mcp__mail_delete(message_id="msg_550e8...")
```

### Storage

Messages are stored as JSON files in `/workspaces/.mail/`:
```json
{
  "id": "msg_550e8400-e29b-41d4-a716-446655440000",
  "from": "sender-agent",
  "to": ["recipient-1", "recipient-2"],
  "subject": "Task Update",
  "body": "Message content...",
  "timestamp": "2025-01-04T10:30:00Z",
  "read": false
}
```

## Management Scripts

### setup-agent.sh
Creates new agent workspace with configuration.

```bash
./scripts/setup-agent.sh <name> "<description>"

# What it does:
# 1. Creates git worktree
# 2. Allocates ports
# 3. Generates .env config
# 4. Creates prompt.md
# 5. Sets up directories
```

### list-agents.sh
Shows active agents and their status.

```bash
./scripts/list-agents.sh

# Output:
# agent-1 (RUNNING) - Last commit: 2 hours ago
# agent-2 (IDLE) - Last commit: 1 day ago
```

### cleanup-worktree.sh
Removes completed agent worktrees.

```bash
./scripts/cleanup-worktree.sh <agent-name> [--force]
```

## System Commands

### Health Check
```bash
./health/check_system.sh

# Checks:
# - Docker status
# - Directory structure
# - Python dependencies
# - Port availability
# - Script permissions
```

### Container Management
```bash
# Start system
docker-compose up -d

# Enter container
docker-compose exec coding-agent bash

# View logs
docker-compose logs -f

# Stop system
docker-compose down
```

## Development Tools

### Git Commands
```bash
# Worktree management
git worktree add ../agent-name branch-name
git worktree list
git worktree remove ../agent-name

# Standard workflow
git status
git add .
git commit -m "feat: description"
git push -u origin branch-name
```

### Python Tools
```bash
# Run Python scripts
python3 script.py

# Install packages (not persisted)
pip install package-name

# Run tests
pytest tests/
```

### Node.js Tools
```bash
# Run Node scripts
node script.js

# Install packages (not persisted)
npm install package-name

# Run tests
npm test
```

## File Locations

### Agent Workspace
```
/workspaces/{agent-name}/
├── .env              # Configuration
├── .agent-id         # Identifier
├── prompt.md         # Instructions
├── tmp/              # Temporary files
├── logs/             # Log files
└── [project files]   # Your code
```

### Shared Resources
```
/workspaces/
├── .mail/           # Mail messages
├── .processes/      # Process tracking
├── main/            # Main repository
└── scripts/         # Utility scripts
```

## Environment Variables

Available in agent `.env` files:

```bash
# Identity
AGENT_NAME=feature-agent
AGENT_ID=550e8400-e29b

# Resources  
MAIN_PORT=3010
API_PORT=3011
DEBUG_PORT=3012
PORT_RANGE=3010-3019

# Paths
WORKTREE_PATH=/workspaces/feature-agent
TMP_DIR=/workspaces/feature-agent/tmp
LOG_DIR=/workspaces/feature-agent/logs

# Task
TASK_DESCRIPTION="Implement user dashboard"
BRANCH_NAME=feat/user-dashboard
BASE_BRANCH=main
```

## Process Management

### Background Services (Supervisor)
```bash
# Check service status
sudo supervisorctl status

# Start/stop/restart services
sudo supervisorctl start telemetry
sudo supervisorctl stop telemetry
sudo supervisorctl restart telemetry

# View service logs
sudo supervisorctl tail telemetry
sudo supervisorctl tail -f telemetry  # Follow logs

# Reload configuration
sudo supervisorctl reread
sudo supervisorctl update
```

Services are managed by supervisor for reliability and easy debugging.

## Debugging Tools

### Check Resources
```bash
# Disk usage
df -h /workspaces

# Memory
free -h

# Processes
ps aux | grep agent

# Ports in use
netstat -tlnp
```

### Inspect Mail
```bash
# Count messages
ls /workspaces/.mail/*.json | wc -l

# Find messages to agent
grep -l '"to":.*"my-agent"' /workspaces/.mail/*.json

# Read all messages
for f in /workspaces/.mail/*.json; do
  echo "=== $f ==="
  cat "$f" | jq .
done
```

## Best Practices

1. **Use provided scripts**: Don't reinvent functionality
2. **Check mail regularly**: Don't miss important messages
3. **Clean up temp files**: Use tmp/ directory
4. **Log important events**: Use logs/ directory
5. **Communicate status**: Send regular updates