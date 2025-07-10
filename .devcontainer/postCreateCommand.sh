#!/bin/bash
# Post-creation setup script for coding agent devcontainer
# This script runs after the container is created to finalize setup

set -e

# Note: We don't need to load .envrc here since we source .env directly below

# Helper function to create directory with proper ownership
ensure_directory() {
    local dir="$1"
    mkdir -p "$dir"
    
    # Fix ownership if we have permission (vscode user in devcontainer)
    if [ "$EUID" -eq 0 ]; then
        chown -R vscode:vscode "$dir" || true
    elif command -v sudo &> /dev/null; then
        sudo chown -R vscode:vscode "$dir" || true
    fi
}

# Create required directories with proper ownership
# Why: direnv needs its directories to exist before use (may be obsolete).
# For mounted volumes (gh, bash_history_dir), Docker should create them but we ensure they exist.
ensure_directory /home/vscode/.local
ensure_directory /home/vscode/.local/share
ensure_directory /home/vscode/.local/share/direnv
ensure_directory /home/vscode/.local/share/direnv/allow  # direnv stores .envrc approvals here
ensure_directory /home/vscode/.claude
ensure_directory /home/vscode/.gemini
ensure_directory /home/vscode/.config
ensure_directory /home/vscode/.config/gh         # Mounted volume, but ensure it exists
ensure_directory /home/vscode/.bash_history_dir  # Mounted volume, but ensure it exists
ensure_directory /workspaces/.mail               # Shared mail directory for agent communication

# Essential environment setup
# Why: Ensure Claude stores config in persistent location and user-installed
# binaries (via pip install --user) are accessible in PATH
echo 'export CLAUDE_CONFIG_DIR="/home/vscode/.claude"' >> /home/vscode/.bashrc
echo 'export PATH="/home/vscode/.local/bin:$PATH"' >> /home/vscode/.bashrc

# Persistent bash history
# Why: Default history is lost on container rebuild, but this directory
# is mounted as a Docker volume so history persists across rebuilds
echo 'export HISTFILE=/home/vscode/.bash_history_dir/.bash_history' >> /home/vscode/.bashrc

# Initialize tools (both are installed via Dockerfile)
# Why: direnv auto-loads .envrc files when entering directories,
# starship provides context-aware prompts showing git branch, Python env, etc.
echo 'eval "$(direnv hook bash)"' >> /home/vscode/.bashrc
echo 'eval "$(starship init bash)"' >> /home/vscode/.bashrc

# Common aliases
# Why: Many developers (and AI agents) intuitively try commands like 'll' or 'gs'.
# These aliases provide familiar shortcuts for common operations.
cat > /home/vscode/.bash_aliases << 'EOF'
# Common developer aliases for productivity
alias ll="ls -la"      # Long list, very common in Unix/Linux
alias la="ls -la"      # Same as ll, alternate form
alias gs="git status"  # Quick git status check
alias gl="git log --oneline -10"  # Recent commit history
alias gd="git diff"    # See uncommitted changes
EOF

# Configure AI CLI telemetry settings (merge into existing config)
# Why: Both Claude and Gemini CLIs support OpenTelemetry for tracking token usage,
# costs, and performance. Configuring this enables centralized observability.
echo "📝 Configuring AI CLI telemetry settings..."

# Claude CLI telemetry config to merge
CLAUDE_TELEMETRY_CONFIG='{
  "env": {
    "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
    "OTEL_METRICS_EXPORTER": "otlp",
    "OTEL_LOGS_EXPORTER": "otlp",
    "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
    "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
    "OTEL_SERVICE_NAME": "claude-cli",
    "OTEL_RESOURCE_ATTRIBUTES": "service.name=claude-cli,service.namespace=coding-agent"
  }
}'

# Merge Claude settings (HOME is /home/vscode in devcontainer)
mkdir -p "$HOME/.claude"
if [ -f "$HOME/.claude/settings.json" ]; then
    # Merge with existing settings
    # Why: Users may have other settings we don't want to overwrite,
    # so we merge our telemetry config with their existing preferences
    jq -s '.[0] * .[1]' "$HOME/.claude/settings.json" <(echo "$CLAUDE_TELEMETRY_CONFIG") > "$HOME/.claude/settings.json.tmp" && \
    mv "$HOME/.claude/settings.json.tmp" "$HOME/.claude/settings.json"
    echo "   ✅ Merged Claude telemetry settings"
else
    # Create new settings file
    echo "$CLAUDE_TELEMETRY_CONFIG" > "$HOME/.claude/settings.json"
    echo "   ✅ Created Claude telemetry settings"
fi

# Gemini CLI telemetry config to merge
GEMINI_TELEMETRY_CONFIG='{
  "telemetry": {
    "enabled": true,
    "target": "local",
    "otlpEndpoint": "http://localhost:4317",
    "logPrompts": true,
    "serviceName": "gemini-cli",
    "resourceAttributes": {
      "service.namespace": "coding-agent"
    }
  }
}'

# Merge Gemini settings
mkdir -p "$HOME/.gemini"
if [ -f "$HOME/.gemini/settings.json" ]; then
    # Merge with existing settings
    jq -s '.[0] * .[1]' "$HOME/.gemini/settings.json" <(echo "$GEMINI_TELEMETRY_CONFIG") > "$HOME/.gemini/settings.json.tmp" && \
    mv "$HOME/.gemini/settings.json.tmp" "$HOME/.gemini/settings.json"
    echo "   ✅ Merged Gemini telemetry settings"
else
    # Create new settings file
    echo "$GEMINI_TELEMETRY_CONFIG" > "$HOME/.gemini/settings.json"
    echo "   ✅ Created Gemini telemetry settings"
fi

echo "✅ AI CLI telemetry configuration complete"

# Generate otel config if API key is configured
if [ -f "/workspaces/coding-agent/.env" ]; then
    source /workspaces/coding-agent/.env
    
    if [ -n "$HONEYCOMB_API_KEY" ]; then
        echo "Generating telemetry configuration..."
        # Use j2cli to process the Jinja2 template with environment variables
        # Why: j2cli properly handles default values like ${VAR:-default} syntax
        # and is a standard tool for template processing in DevOps workflows
        # The -e '' flag imports all environment variables into the template context
        export HONEYCOMB_API_KEY HONEYCOMB_API_ENDPOINT HONEYCOMB_DATASET ENVIRONMENT
        j2 -e '' /etc/otel/config.yaml.j2 | sudo tee /etc/otel/config.yaml > /dev/null
        echo "Telemetry configuration generated."
    else
        echo "Telemetry not configured (HONEYCOMB_API_KEY not set in .env)"
    fi
fi

# Start supervisor
# Why: Supervisor manages our background services (like telemetry collector)
# with automatic restarts, log rotation, and centralized control.
# We start it here rather than Dockerfile because it needs runtime config.
echo "Starting supervisor..."
sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf

# Start telemetry if configured
# Why: Telemetry is optional and only starts when API key is provided
# to avoid errors and unnecessary resource usage in dev environments
if [ -n "$HONEYCOMB_API_KEY" ]; then
    echo "Starting telemetry collector..."
    sudo supervisorctl start telemetry
fi

# Setup complete
echo "Coding agent environment configured."
echo "Authentication status will be checked on container start."
