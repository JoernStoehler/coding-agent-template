#!/bin/bash
# Post-creation setup script for coding agent devcontainer
# This script runs after the container is created to finalize setup

set -e

# Helper function to create directory with proper ownership
ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
    
    # Fix ownership if we have permission
    if [ "$EUID" -eq 0 ]; then
        chown -R $USER:$USER "$dir" || true
    elif command -v sudo &> /dev/null; then
        sudo chown -R $USER:$USER "$dir" || true
    fi
}

# Silent setup tasks
{
    # Create required directories with proper ownership
    ensure_directory /home/user/.local
    ensure_directory /home/user/.local/share
    ensure_directory /home/user/.local/share/direnv
    ensure_directory /home/user/.local/share/direnv/allow
    ensure_directory /home/user/.claude
    ensure_directory /home/user/.gemini
    ensure_directory /home/user/.config
    ensure_directory /home/user/.config/gh
    ensure_directory /home/user/.bash_history_dir
    ensure_directory /workspaces/.mail
    ensure_directory /workspaces/.processes/logs
    

    # Essential environment setup
    echo 'export CLAUDE_CONFIG_DIR="/home/user/.claude"' >> /home/user/.bashrc
    echo 'export PATH="/home/user/.local/bin:$PATH"' >> /home/user/.bashrc
    
    # Persistent bash history
    echo 'export HISTFILE=/home/user/.bash_history_dir/.bash_history' >> /home/user/.bashrc
    
    # Initialize tools (both are installed via Dockerfile)
    echo 'eval "$(direnv hook bash)"' >> /home/user/.bashrc
    echo 'eval "$(starship init bash)"' >> /home/user/.bashrc
    
    # Common aliases
    cat > /home/user/.bash_aliases << 'EOF'
# Common aliases for coding agent development
alias ll="ls -la"
alias la="ls -la"
alias gs="git status"
alias gl="git log --oneline -10"
alias gd="git diff"
alias check="check-services"
EOF

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