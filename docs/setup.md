# Setting Up Coding Agent Infrastructure

This guide covers installing and running the coding agent infrastructure.

## Prerequisites

- **Docker** 20.10+ and **Docker Compose** 1.29+
- **Git** 2.30+ with configured user credentials
- **4GB RAM** available
- **10GB disk space**
- **API keys** for Claude and/or Gemini

## Quick Start

```bash
# 1. Clone and enter directory
git clone <repository-url>
cd coding-agent

# 2. Configure environment
cp .env.template .env
# Edit .env with your API keys

# 3. Start infrastructure
docker-compose up -d

# 4. Enter container
docker-compose exec coding-agent bash

# 5. Verify setup
./health/check_system.sh
```

## Configuration

### Required Environment Variables

Create `.env` file with:
```bash
# User identity (for git commits)
USER_NAME=your-name
USER_EMAIL=your-email@example.com

# API keys (at least one required)
ANTHROPIC_API_KEY=sk-ant-xxx    # For Claude agents
GOOGLE_API_KEY=AIzaSyxxx         # For Gemini agents
```

### Optional Configuration

```bash
# Telemetry (for cost tracking)
HONEYCOMB_API_KEY=your-key
OTLP_ENDPOINT=https://api.honeycomb.io

# Resource limits
MAX_CONCURRENT_AGENTS=10
AGENT_TIMEOUT_SECONDS=3600
```

## Container Environment

The Docker container includes:
- Python 3.11 with common libraries
- Node.js 20 for JavaScript projects
- Git and development tools
- Claude/Gemini CLI tools
- MCP server runtime

### Persistence

**Persisted** (survives container rebuilds):
- `/workspaces/` - All agent work
- Git configuration
- SSH keys (if mounted)

**Not Persisted**:
- Installed packages (apt, pip, npm)
- Running processes
- Temporary files outside `/workspaces/`

## Initial Project Setup

Inside the container:

```bash
cd /workspaces

# Option 1: Clone existing project
git clone <your-project-url> main

# Option 2: Create new project
mkdir main && cd main
git init
git add . && git commit -m "Initial commit"
```

The `main` directory serves as the base for agent worktrees.

## Devcontainer Option

For VSCode users:
1. Open project in VSCode
2. Install "Dev Containers" extension
3. Run command: "Dev Containers: Reopen in Container"
4. Container builds and attaches automatically

## Verification

Check everything is working:

```bash
# Inside container
cd /workspaces

# Check Python environment
python3 --version
python3 -c "import fastmcp; print('MCP ready')"

# Check git setup
git config user.name
git config user.email

# Check agent tools
ls scripts/setup-agent.sh
ls scripts/mcp-servers/

# Test mail system
python3 -c "from scripts.mcp_servers.mcp_mail import mail_send; print('Mail system ready')"
```

## Next Steps

- [Create your first agent](agents.md)
- [Customize for your project](customization.md)
- [See complete example](examples/single-agent-task.md)