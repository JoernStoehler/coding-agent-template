#!/bin/bash
# Helper script for central planner to set up agent environment
# Usage: ./setup-agent.sh <worktree-name> <task-description> [base-branch]

set -e

# Check arguments
if [[ $# -lt 2 ]]; then
    echo "Usage: $0 <worktree-name> <task-description> [base-branch]"
    echo "Example: $0 feat-dashboard 'Implement user dashboard with charts' main"
    exit 1
fi

WORKTREE_NAME="$1"
TASK_DESCRIPTION="$2"
BASE_BRANCH="${3:-main}"

# Validate worktree name
if [[ ! "$WORKTREE_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Error: Worktree name must contain only letters, numbers, dashes, and underscores"
    exit 1
fi

# Set up paths
WORKSPACES_DIR="/workspaces"
WORKTREE_PATH="$WORKSPACES_DIR/$WORKTREE_NAME"
MAIN_REPO_PATH="$WORKSPACES_DIR/main"

# Check if main repository exists
if [[ ! -d "$MAIN_REPO_PATH" ]]; then
    echo "Error: Main repository not found at $MAIN_REPO_PATH"
    echo "Please ensure the main repository is cloned first"
    exit 1
fi

# Check if worktree already exists
if [[ -d "$WORKTREE_PATH" ]]; then
    echo "Error: Worktree $WORKTREE_NAME already exists"
    exit 1
fi

# Change to main repository
cd "$MAIN_REPO_PATH"

# Create branch name
BRANCH_NAME=$(echo "$WORKTREE_NAME" | sed 's/^//' | sed 's/_/-/g')

# Create the worktree with a new branch
echo "Creating worktree: $WORKTREE_NAME"
echo "Creating branch: $BRANCH_NAME"
git worktree add -b "$BRANCH_NAME" "../$WORKTREE_NAME" "$BASE_BRANCH"

# Change to the new worktree
cd "$WORKTREE_PATH"

# Allocate ports (simple sequential allocation)
# Find the next available port range
PORT_BASE=3000
for existing_worktree in "$WORKSPACES_DIR"/*; do
    if [[ -f "$existing_worktree/.env" ]]; then
        existing_port=$(grep "MAIN_PORT=" "$existing_worktree/.env" 2>/dev/null | cut -d'=' -f2)
        if [[ -n "$existing_port" && "$existing_port" -ge "$PORT_BASE" ]]; then
            PORT_BASE=$((existing_port + 10))
        fi
    fi
done

MAIN_PORT=$PORT_BASE
API_PORT=$((PORT_BASE + 1))
DEBUG_PORT=$((PORT_BASE + 2))

# Create .env file
echo "Creating .env file with resource allocation"
cat > .env << EOF
# Agent identification
AGENT_NAME=$WORKTREE_NAME
WORKTREE_PATH=$WORKTREE_PATH

# Port allocation
MAIN_PORT=$MAIN_PORT
API_PORT=$API_PORT
DEBUG_PORT=$DEBUG_PORT
PORT_RANGE=$MAIN_PORT-$((PORT_BASE + 9))

# Task context
TASK_DESCRIPTION="$TASK_DESCRIPTION"
BRANCH_NAME=$BRANCH_NAME
BASE_BRANCH=$BASE_BRANCH

# Common paths
TMP_DIR=$WORKTREE_PATH/tmp
LOG_DIR=$WORKTREE_PATH/logs

# Development URLs (container-internal)
MAIN_URL=http://localhost:$MAIN_PORT
API_URL=http://localhost:$API_PORT
DEBUG_URL=http://localhost:$DEBUG_PORT
EOF

# Copy .mcp.json configuration for agent
echo "Copying .mcp.json configuration"
cat > .mcp.json << 'EOF'
{
  "mcpServers": {
    "mail": {
      "command": "python3",
      "args": ["scripts/mcp-servers/mcp_mail.py"],
      "cwd": "/workspaces"
    },
    "processes": {
      "command": "python3", 
      "args": ["scripts/mcp-servers/mcp_processes.py"],
      "cwd": "/workspaces"
    }
  }
}
EOF

# Create prompt.md file
echo "Creating prompt.md with agent instructions"
cat > prompt.md << EOF
# Agent Task: $WORKTREE_NAME

## Context
- **Project**: Coding Agent Infrastructure
- **Task**: $TASK_DESCRIPTION
- **Priority**: Medium
- **Worktree**: $WORKTREE_PATH
- **Branch**: $BRANCH_NAME

## Resources
- **Working Directory**: $WORKTREE_PATH
- **Environment**: Source .env file for configuration
- **Ports**: $MAIN_PORT (main), $API_PORT (api), $DEBUG_PORT (debug)
- **Temporary Files**: Use ./tmp/ directory
- **Logs**: Use ./logs/ directory

## Task Requirements
1. Implement the requested feature: $TASK_DESCRIPTION
2. Follow conventional commit format for all commits
3. Write clear, maintainable code
4. Test your implementation
5. Document any new features or changes

## Constraints
- Work only within this worktree: $WORKTREE_PATH
- Use allocated ports: $MAIN_PORT-$((PORT_BASE + 9))
- Do not modify files outside your worktree
- Commit frequently with descriptive messages

## Definition of Done
- [ ] Feature implemented and working
- [ ] Code follows project conventions
- [ ] Tests passing (if applicable)
- [ ] Changes committed with conventional commits
- [ ] Documentation updated if needed
- [ ] Ready for merge/review

## Communication
- **Mail System**: Use mcp__mail_send to communicate with other agents
- **Status Updates**: Send updates to 'central-planner' agent
- **Blockers**: Notify immediately if blocked or need help

## Common Commands
\`\`\`bash
# Start working
cd $WORKTREE_PATH
source .env

# View your environment
env | grep -E "(AGENT_|PORT_|TASK_)"

# Check git status
git status
git log --oneline -10

# Send mail to central planner
# Use MCP tool: mcp__mail_send from="$WORKTREE_NAME" to=["central-planner"] subject="Status update" body="..."
\`\`\`

## Available Tools
- **MCP Mail**: mcp__mail_send, mcp__mail_inbox, mcp__mail_read
- **MCP Processes**: mcp__process_start, mcp__process_list, mcp__process_logs, mcp__process_stop
- **Standard Tools**: git, python, node, docker, curl, etc.

## Getting Started
1. Review the codebase to understand the project structure
2. Plan your implementation approach
3. Create any necessary directories (tmp/, logs/)
4. Start implementing the feature
5. Test your implementation
6. Commit your changes
7. Send a completion message to central-planner

Good luck with your task!
EOF

# Create basic directories
mkdir -p tmp logs

# Create a basic .gitignore for the worktree
cat > .gitignore << EOF
# Agent-specific files
.env
prompt.md
.mcp.json
tmp/
logs/
*.log

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# Node
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
.npm
.eslintcache

# IDE
.vscode/
.idea/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db
EOF

# Initial commit
git add .gitignore
git commit -m "chore: initialize worktree $WORKTREE_NAME

- Add .gitignore for agent-specific files
- Set up basic directory structure
- Ready for: $TASK_DESCRIPTION"

echo ""
echo "✅ Agent environment set up successfully!"
echo ""
echo "📁 Worktree: $WORKTREE_PATH"
echo "🌿 Branch: $BRANCH_NAME"
echo "🚀 Ports: $MAIN_PORT-$((PORT_BASE + 9))"
echo ""
echo "To start the agent:"
echo "  cd $WORKTREE_PATH"
echo "  source .env"
echo "  claude --dangerously-skip-permissions \"@prompt.md\""
echo ""
echo "To monitor the agent:"
echo "  ./scripts/list-agents.sh"
echo ""