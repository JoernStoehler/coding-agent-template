# Coding Agent Infrastructure

A YAGNI-focused infrastructure for orchestrating AI coding agents using Docker containers and MCP (Model Context Protocol) servers.

## Overview

This project provides a reusable template for managing multiple AI coding agents working collaboratively on software projects. Agents communicate through a simple mail system, manage background processes, and work in isolated git worktrees within a shared Docker environment.

## Key Features

- **Shared Container Environment**: All agents run in a single Docker container with shared resources
- **Git Worktree Isolation**: Each agent works in its own git worktree for clean separation
- **Agent Communication**: Simple JSON-based mail system for inter-agent communication
- **Process Management**: Background process tracking and management
- **Resource Allocation**: Automatic port and resource allocation per agent
- **VSCode Integration**: Easy development environment setup

## Quick Start

**Get running in 5 minutes:** See [Quick Start Guide](docs/QUICK_START.md)

### Prerequisites
- Docker & Docker Compose
- Git configured  
- 4GB RAM available

### Essential Commands
```bash
# Start infrastructure
docker-compose up -d && docker-compose exec coding-agent bash

# Set up main repo (first time only)
cd /workspaces && cp -r coding-agent main && cd main
git init && git add . && git commit -m "Initial commit" && git branch -m main

# Create and start agent
./scripts/setup-agent.sh my-agent "Task description"
cd /workspaces/my-agent && source .env && claude "@prompt.md"
```

### VSCode Integration

```bash
# Open the workspace in VSCode
code --add /workspaces
```

## Architecture

### Container Structure
```
/workspaces/
├── .mail/              # Inter-agent communication
├── .processes/         # Background process management
├── main/              # Main repository
├── feat-dashboard/    # Agent worktree
│   ├── .env          # Resource allocation
│   ├── prompt.md     # Agent instructions
│   └── tmp/          # Temporary files
└── scripts/          # Utility scripts and MCP servers
```

### Agent Workflow

1. **Central Planner** creates worktrees and allocates resources
2. **Human Admin** spawns agents manually using claude CLI
3. **Agents** work in isolation, communicate via mail system
4. **Agents** commit frequently using conventional commits
5. **Central Planner** handles merging and conflict resolution

## MCP Servers

Located in `scripts/mcp-servers/` and automatically started by claude via `.mcp.json`:

### Mail System (`mcp_mail.py`)
- `mcp__mail_send` - Send messages between agents
- `mcp__mail_inbox` - Check incoming messages
- `mcp__mail_read` - Read and mark messages as read

### Process Manager (`mcp_processes.py`)
- `mcp__process_start` - Start background processes
- `mcp__process_list` - List running processes
- `mcp__process_logs` - View process logs
- `mcp__process_stop` - Stop processes

## Utility Scripts

- `scripts/list-agents.sh` - Show running agents and their status
- `scripts/setup-agent.sh` - Set up new agent environment
- `scripts/cleanup-worktree.sh` - Clean up completed worktrees

## Configuration

### Environment Variables
```bash
# Required for Docker Compose
USER_NAME=your-name
USER_EMAIL=your-email@example.com

# Optional OTLP/Honeycomb configuration
OTLP_ENDPOINT=https://api.honeycomb.io
HONEYCOMB_API_KEY=your-api-key
```

### Agent Environment (`.env`)
Each agent gets its own `.env` file with:
- Unique agent name and ID
- Allocated port ranges
- Task description and context
- Resource paths and configuration

## Development Workflow

### Common Use Cases

1. **Single Agent Task**: One agent works on a specific feature
2. **A/B Testing**: Multiple agents solve the same problem, pick the best solution
3. **Parallel Development**: Different agents work on different features simultaneously
4. **Review/QA**: One agent codes, another reviews

### Git Conventions

- **Branch naming**: `feat/feature-name`, `fix/bug-name`, `chore/task-name`
- **Commits**: Use conventional commit format
- **Worktrees**: One per agent, auto-created by setup script
- **Merging**: Handled by central planner agent

## Documentation

**Essential Reading:**
- [Quick Start Guide](docs/QUICK_START.md) - Get running in 5 minutes  
- [Devcontainer Setup](docs/DEVCONTAINER_SETUP.md) - VSCode development environment
- [LocalEnv Explained](docs/LOCALENV_EXPLAINED.md) - Environment variables and setup
- [Technical Decisions](docs/TECHNICAL_DECISIONS.md) - Critical implementation knowledge
- [Agent Onboarding](docs/agent-onboarding.md) - How agents should work

**Architecture:**
- [Architecture Details](docs/ARCHITECTURE_REFINED.md) - Complete system design
- [Interface Specifications](docs/INTERFACES.md) - API and protocol specs
- [Requirements Analysis](REQUIREMENTS.md) - Original requirements

## Troubleshooting

### Common Issues

1. **Port conflicts**: Check allocated ports in `.env` files
2. **Git worktree issues**: Use `git worktree list` to debug
3. **Agent communication**: Check `.mail/` directory for messages
4. **Process management**: Use `./scripts/list-agents.sh` to monitor

### Debugging

```bash
# Check agent status
./scripts/list-agents.sh

# Check mail system
ls -la /workspaces/.mail/

# Check processes
python3 mcp_processes.py &
# Then use MCP tools to inspect processes
```

## Contributing

This project follows YAGNI principles - start simple, add complexity only when needed. When contributing:

1. Keep changes minimal and focused
2. Use conventional commits
3. Document any new conventions
4. Test with actual agents before committing
5. Update documentation to reflect changes

## License

[Your License Here]

## Acknowledgments

- Built for use with Claude Code and Gemini CLI
- Uses FastMCP for MCP server implementation
- Inspired by modern DevOps practices and agent-based development