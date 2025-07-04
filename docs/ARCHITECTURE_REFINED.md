# Refined Architecture - YAGNI-Focused MVP

## Core Philosophy
- **YAGNI**: Start simple, add complexity only when needed
- **High explicitness**: Agents need clear, detailed documentation
- **Common conventions**: Use well-known patterns agents understand
- **Fast iteration**: Get MVP working, then improve incrementally

## System Overview

### Container Architecture
- **Single shared Docker container** for all agents
- **Docker Compose** for easy setup
- **Named volumes** for persistent auth (claude, gemini, gh, bash_history)
- **Non-root user** inside container
- **Host mount**: `~/workspaces` → `/workspaces`

### Agent Lifecycle
1. **Central Planner Agent** (orchestrator role):
   - Creates git worktrees: `git worktree add ../feat-dashboard main`
   - Allocates resources (writes `.env` file)
   - Writes task instructions (`prompt.md`)
   - Tells human (Jörn) to spawn agent

2. **Human Admin** (Jörn):
   - Spawns agents manually: `cd ../feat-dashboard && source .env && claude --dangerously-skip-permissions "@prompt.md"`
   - Monitors agent progress via TUI
   - Kills abandoned agents
   - Manages container lifecycle

3. **Agent Execution**:
   - Agents work in their worktrees
   - Communicate via mail system
   - Make frequent commits using conventional commit format
   - Manage their own background processes

## File System Layout

```
/workspaces/
├── .mail/                 # Mail exchange (JSON files)
│   ├── msg_<uuid4>.json  # Individual messages
│   └── README.md         # Mail system documentation
├── .processes/           # Background process management
│   ├── proc_<uuid4>.json # Process metadata
│   └── logs/             # Process logs
├── main/                 # Main repository
├── feat-dashboard/       # Agent worktree
│   ├── .env             # Resource allocation (ports, etc.)
│   ├── prompt.md        # Agent instructions
│   └── tmp/             # Agent temporary files
└── fix-bug-123/         # Another agent worktree
    ├── .env
    ├── prompt.md
    └── tmp/
```

## Interface Specifications

### Mail System (`mcp_mail.py`)
```python
# Simple JSON-based mail system
mcp__mail_send(from: str, to: List[str], subject: str, body: str) -> str
mcp__mail_inbox(to: str) -> List[Dict]  # Returns list of mail summaries
mcp__mail_read(id: str) -> Dict        # Returns full message
```

**Message Format:**
```json
{
  "id": "msg_<uuid4>",
  "from": "agent-name",
  "to": ["recipient1", "recipient2"],
  "subject": "Task update",
  "body": "Please implement the login form",
  "timestamp": "2024-07-03T10:30:00Z",
  "read": false
}
```

### Background Process Manager (`mcp_processes.py`)
```python
# Simple process tracking
mcp__process_start(command: str, cwd: str, name: str) -> str
mcp__process_list() -> List[Dict]      # All agents can see all processes
mcp__process_logs(id: str) -> str      # Get process output
mcp__process_stop(id: str) -> bool     # Stop process
```

## Resource Allocation

### Port Allocation
- **Container-internal** ports (no host binding needed for most)
- **Main branch**: Port 5000 exposed to host for viewing
- **Agent ports**: Allocated in `.env` file by central planner
- **Port range**: 3000-3999 (safe default range)

### Example `.env` file:
```bash
# Agent identification
AGENT_NAME=feat-dashboard
WORKTREE_PATH=/workspaces/feat-dashboard

# Port allocation
MAIN_PORT=3001
API_PORT=3002
DEBUG_PORT=3003

# Task context
TASK_DESCRIPTION="Implement user dashboard with charts"
BRANCH_NAME=feat/dashboard
```

## Git Integration

### Workflow
1. **Branch naming**: `feat/dashboard`, `fix/bug-123`, `chore/cleanup`
2. **Worktree creation**: `git worktree add ../feat-dashboard main`
3. **Commit strategy**: Frequent commits with conventional format
4. **Merge handling**: Central planner resolves conflicts sequentially

### Conventional Commits
- `feat: add user dashboard component`
- `fix: resolve login validation issue`
- `chore: update dependencies`
- `docs: add API documentation`

## Docker Configuration

### Base Setup
```dockerfile
FROM ubuntu:22.04
# Install: Python 3.12+, Node 20+, git, curl, docker-cli
# Install: claude-code (latest), gemini-cli (latest)
# Create non-root user
# Set up common directories
```

### Volume Strategy
```yaml
# docker-compose.yml
volumes:
  - ~/workspaces:/workspaces
  - claude_auth:/home/user/.claude
  - gemini_auth:/home/user/.gemini
  - gh_auth:/home/user/.config/gh
  - bash_history:/home/user/.bash_history
```

## Agent Documentation Requirements

### Agent Onboarding Pattern
Each agent gets:
1. **Explicit context**: Full task description, constraints, resources
2. **Clear file structure**: Where to find what, naming conventions
3. **Workflow examples**: Common patterns for their type of task
4. **Resource information**: Available ports, directories, tools
5. **Communication guide**: How to use mail system, when to communicate

### Documentation Structure
```
docs/
├── agent-onboarding.md     # General agent setup
├── workflows/              # Common task patterns
│   ├── frontend-dev.md
│   ├── backend-api.md
│   └── bug-fixing.md
├── conventions/            # Standards and patterns
│   ├── git-workflow.md
│   ├── coding-standards.md
│   └── file-organization.md
└── troubleshooting.md      # Common issues and solutions
```

## Monitoring & Observability

### Current Setup
- **OTLP collection**: claude-code already sends telemetry
- **Honeycomb.io**: For cost and performance analysis
- **Manual monitoring**: Via TUI and `ps aux`

### Simple Utilities
- `list-agents.sh`: Show running claude instances and their locations
- `agent-status.sh`: Quick overview of all worktrees and their state
- `cleanup-abandoned.sh`: Remove old worktrees after confirmation

## MVP Milestone Definition

### Acceptance Criteria
- [ ] Docker Compose setup creates working environment
- [ ] Central planner can create worktrees with .env and prompt.md
- [ ] Agents can be spawned manually and work in isolation
- [ ] Mail system allows agent-to-agent communication
- [ ] Background process manager tracks agent processes
- [ ] VSCode can access all worktrees simultaneously
- [ ] Agents can commit work using conventional commits
- [ ] Central planner can handle simple merge conflicts

### Out of Scope for MVP
- Web dashboard (manual TUI monitoring is sufficient)
- Automatic agent spawning (manual is fine)
- Complex error handling (simple failure modes)
- Resource monitoring (OTLP is sufficient)
- Security isolation (trust-based model)
- Performance optimization (optimize when needed)

## Next Steps

1. **Create project structure** with basic files
2. **Write Docker Compose** configuration
3. **Implement MCP servers** (mail and processes)
4. **Write agent onboarding** documentation
5. **Create utility scripts** for common tasks
6. **Test with simple agent workflow**

## Open Questions

1. **OTLP Collector**: Should we include an OTLP collector container, or is manual startup preferred?
2. **Agent Templates**: Should we create template `prompt.md` files for common task types?
3. **Port Conflict Detection**: How detailed should port allocation be, or is simple range allocation sufficient?
4. **Git Configuration**: Should we set up git config (user.name, user.email) in the container?

These questions can be answered during implementation - the YAGNI principle suggests starting simple and adding complexity only when needed.