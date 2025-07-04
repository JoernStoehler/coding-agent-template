# Creating and Managing Agents

This guide covers the agent lifecycle from creation to cleanup.

## Creating an Agent

Use the setup script to create an agent workspace:

```bash
./scripts/setup-agent.sh <agent-name> "<task-description>"

# Example
./scripts/setup-agent.sh add-auth "Implement user authentication"
```

This creates:
- **Worktree**: `/workspaces/add-auth/` (isolated git branch)
- **Config**: `.env` with allocated ports and settings
- **Instructions**: `prompt.md` with task details
- **Directories**: `tmp/` and `logs/` for agent use

## Starting an Agent

Agents must be manually started (intentional design for cost control):

```bash
# In a new terminal
cd /workspaces/add-auth
source .env
claude --dangerously-skip-permissions "@prompt.md"
```

Or for Gemini:
```bash
gemini --dangerously-skip-permissions "@prompt.md"
```

## Agent Lifecycle

1. **Creation**: Worktree and config files created
2. **Execution**: Agent reads prompt.md and begins work
3. **Communication**: Uses mail system for updates
4. **Completion**: Creates PR or reports completion
5. **Cleanup**: Worktree removed after merge

## Monitoring Agents

### List Active Agents
```bash
./scripts/list-agents.sh
```

### Check Agent Status
```bash
# See worktrees
cd /workspaces
ls -la | grep -v '^\.'

# Check specific agent
cd /workspaces/agent-name
git status
git log --oneline -5
```

### Monitor Communication
```bash
# Check mail
ls /workspaces/.mail/*.json | wc -l

# Read recent messages
ls -lt /workspaces/.mail/*.json | head -5 | xargs cat | jq .
```

## Agent Communication

Agents communicate using the MCP mail system:

```python
# Send status update
mcp__mail__mcp__mail_send(
    from_agent="add-auth",
    to_agents=["orchestrator"],
    subject="Progress Update",
    body="Completed user model. Starting on API endpoints."
)

# Check inbox
messages = mcp__mail__mcp__mail_inbox(to_agent="add-auth")

# Read message
message = mcp__mail__mcp__mail_read(message_id="xxx")
```

## Resource Allocation

Each agent receives:
- **Port range**: 10 ports starting from allocated base
- **Directories**: Own tmp/ and logs/ directories
- **Git branch**: Isolated from other agents
- **Environment**: Variables from .env file

Example `.env`:
```bash
AGENT_NAME=add-auth
MAIN_PORT=3010
API_PORT=3011
DEBUG_PORT=3012
PORT_RANGE=3010-3019
```

## Multi-Agent Coordination

For complex tasks, create multiple agents:

```bash
# Frontend agent
./scripts/setup-agent.sh ui-dashboard "Build dashboard UI"

# Backend agent  
./scripts/setup-agent.sh api-dashboard "Create dashboard API"

# Integration agent
./scripts/setup-agent.sh test-dashboard "Test dashboard integration"
```

Agents can communicate via mail to coordinate work.

## Cleaning Up

After task completion:

```bash
# Remove worktree
cd /workspaces/main
git worktree remove ../add-auth

# Or force removal
git worktree remove --force ../add-auth
```

## Best Practices

1. **Clear task descriptions**: Be specific in prompt.md
2. **Resource limits**: Don't run too many agents at once
3. **Regular monitoring**: Check agent progress frequently
4. **Clean up promptly**: Remove completed worktrees
5. **Use conventional commits**: Helps with merging

## Common Patterns

### Sequential Tasks
```
1. Create agent A
2. Agent A completes subtask
3. Create agent B with A's output
4. Agent B continues work
```

### Parallel Development
```
1. Create multiple agents
2. Each works on separate component
3. Integration agent combines work
4. Final review and merge
```

### Review Workflow
```
1. Dev agent implements feature
2. Review agent checks code
3. Test agent verifies functionality
4. Merge when all approve
```

## Debugging Agents

If an agent is stuck:

1. Check the terminal output
2. Look for error messages in mail
3. Examine git status in worktree
4. Review agent's commits
5. Check resource availability (ports, disk)

See [Troubleshooting](troubleshooting.md) for more debugging help.