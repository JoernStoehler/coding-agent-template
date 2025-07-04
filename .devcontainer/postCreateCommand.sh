#!/bin/bash
# Post-creation setup script for coding agent devcontainer
# This script runs after the container is created to finalize setup

set -e

# Silent setup tasks
{
    # Fix permissions on mounted volumes
    if [ "$EUID" -eq 0 ] || command -v sudo &> /dev/null; then
        if [ "$EUID" -eq 0 ]; then
            chown -R $USER:$USER /home/user/.claude || true
            chown -R $USER:$USER /home/user/.gemini || true
            chown -R $USER:$USER /home/user/.config/gh || true
            chown -R $USER:$USER /home/user/.bash_history_dir || true
        else
            sudo chown -R $USER:$USER /home/user/.claude || true
            sudo chown -R $USER:$USER /home/user/.gemini || true
            sudo chown -R $USER:$USER /home/user/.config/gh || true
            sudo chown -R $USER:$USER /home/user/.bash_history_dir || true
        fi
    fi

    # Create required directories
    mkdir -p /home/user/.claude
    mkdir -p /home/user/.gemini
    mkdir -p /home/user/.config/gh
    mkdir -p /home/user/.bash_history_dir
    mkdir -p /workspaces/.mail
    mkdir -p /workspaces/.processes/logs

    # Set up Claude config directory
    export CLAUDE_CONFIG_DIR="/home/user/.claude"
    echo 'export CLAUDE_CONFIG_DIR="/home/user/.claude"' >> /home/user/.bashrc

    # Update git config with environment variables if available
    if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
        git config --global user.name "$USER_NAME"
        git config --global user.email "$USER_EMAIL"
    fi
} &>/dev/null

# Start concise output
echo "Setting up coding agent..."
echo ""

# Collect critical issues only
issues=""

# Check Claude authentication
if command -v claude &> /dev/null; then
    # Check for OAuth credentials OR API key
    if [ ! -f "/home/user/.claude/.credentials.json" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        issues="${issues}⚠️  Claude: Authenticate via browser or set ANTHROPIC_API_KEY\n"
    fi
else
    issues="${issues}❌ Claude Code not installed\n"
fi

# Check GitHub CLI if installed
if command -v gh &> /dev/null; then
    if ! gh auth status &> /dev/null; then
        issues="${issues}⚠️  GitHub: Run 'gh auth login' to authenticate\n"
    fi
fi

# Check critical dependencies
if ! python -c "import fastmcp" 2>/dev/null; then
    issues="${issues}❌ FastMCP not installed (MCP servers won't work)\n"
fi

# Show status
if [ -n "$issues" ]; then
    echo -e "$issues"
else
    echo "✓ All tools configured"
fi

echo ""
echo "Ready. Run 'claude' to start."