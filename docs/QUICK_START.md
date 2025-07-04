# Quick Start Guide

Get the coding agent infrastructure running in 5 minutes.

## Prerequisites
- VSCode installed
- Docker & Docker Compose installed  
- Git configured
- 4GB RAM available

## Step 1: Environment Setup
```bash
# Clone the repository
git clone <repository-url>
cd coding-agent

# Configure environment
cp .env.template .env
# Edit .env with your API keys (git config comes from host automatically):
# ANTHROPIC_API_KEY=your-claude-key
# GOOGLE_API_KEY=your-gemini-key
```

## Step 2: Start with Devcontainer
```bash
# Open in VSCode
code .

# Open Command Palette (CMD+Shift+P)
# Run: "Dev Containers: Reopen in Container"
# Container builds automatically (5-10 minutes first time)
# Uses pure devcontainer (no docker-compose needed!)
```

## Step 3: Set Up Main Repository
```bash
# Enter container
docker-compose exec coding-agent bash

# Set up main repository
cd /workspaces
cp -r coding-agent main
cd main
git init
git add .
git commit -m "Initial commit"
git branch -m main
```

## Step 4: Create Your First Agent
```bash
# Create test agent
./scripts/setup-agent.sh test-agent "Test basic functionality"

# Verify setup
ls -la /workspaces/test-agent/
cat /workspaces/test-agent/.env
```

## Step 5: Test Agent Spawn (Optional)
```bash
# Navigate to agent workspace
cd /workspaces/test-agent

# Load environment
source .env

# Start agent (requires API keys)
claude --dangerously-skip-permissions "@prompt.md"
```

## Verification Commands
```bash
# Check system health
./health/check_system.sh

# List any running agents
./scripts/list-agents.sh

# Test MCP servers
python3 scripts/mcp-servers/mcp_mail.py --help
```

## VSCode Integration
```bash
# Open workspace in VSCode (from host)
code --add ~/workspaces
```

## Next Steps
- Read [Agent Onboarding Guide](agent-onboarding.md)
- Check [Technical Decisions](TECHNICAL_DECISIONS.md)
- Review [Architecture Overview](ARCHITECTURE_REFINED.md)

## Troubleshooting

**Docker build fails?**
- Check disk space (need ~2GB)
- Try: `docker system prune -f && docker-compose build --no-cache`

**Git errors in container?**
- Verify git config: `git config --list`
- Check: `git config --global user.name "Your Name"`

**Port conflicts?**
- Check allocated ports in agent `.env` files
- Default range: 3000-3999

**Can't access container?**
- Verify: `docker-compose ps`
- Restart: `docker-compose down && docker-compose up -d`

## Support
- Check logs: `docker-compose logs`
- System health: `./health/check_system.sh`
- Documentation: [README.md](../README.md)