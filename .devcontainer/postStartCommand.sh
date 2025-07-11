#!/bin/bash
# Post-start script for coding agent devcontainer
# This script runs every time the container starts
# Use this to start background services like telemetry, monitoring, etc.

set -e

# Load environment variables directly from .env
# Why: postStartCommand runs in a fresh shell without direnv context,
# so we source .env directly. set -a exports all variables automatically.
if [ -f "/workspaces/coding-agent/.env" ]; then
    set -a  # Mark all variables for export as they're set
    source /workspaces/coding-agent/.env
    set +a  # Turn off automatic export
fi

# Ensure directories exist (supervisor handles processes now)

# Check authentication status for various tools
echo "Checking authentication status..."

# Check Claude authentication
if command -v claude &> /dev/null; then
    # Check for OAuth credentials OR API key
    # Why: Claude supports both OAuth (browser auth) and API key auth.
    # OAuth creates .credentials.json, API key is used if OAuth not present.
    if [ ! -f "/home/vscode/.claude/.credentials.json" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
        echo "⚠️  Claude: Authenticate via browser or set ANTHROPIC_API_KEY"
    fi
else
    echo "❌ Claude Code not installed"
fi

# Check GitHub CLI if installed
if command -v gh &> /dev/null; then
    if ! gh auth status &> /dev/null; then
        echo "⚠️  GitHub: Run 'gh auth login' to authenticate"
    fi
fi

# Check telemetry configuration
if [ -z "$HONEYCOMB_API_KEY" ]; then
    echo "⚠️  Telemetry: Set HONEYCOMB_API_KEY in .env for cost tracking"
fi

echo ""

# Ensure supervisor is running (it might not be if container was restarted)
# Why: postCreateCommand starts supervisor on first creation, but on container
# restart only postStartCommand runs, so we need to ensure supervisor is up
if ! pgrep -x supervisord > /dev/null; then
    echo "Starting supervisor..."
    sudo /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
    sleep 2  # Give supervisor time to start
fi

# Show telemetry status (supervisor handles the actual service)
# Why: We check supervisor instead of the process directly because supervisor
# manages restarts and provides better status info (RUNNING, STOPPED, etc.)
if [ -n "$HONEYCOMB_API_KEY" ]; then
    # Start telemetry if it's not running
    if ! sudo supervisorctl status telemetry 2>/dev/null | grep -q "RUNNING"; then
        echo "Starting telemetry collector..."
        sudo supervisorctl start telemetry
        sleep 2  # Give telemetry time to start
    fi
    
    # Check final status
    if sudo supervisorctl status telemetry 2>/dev/null | grep -q "RUNNING"; then
        echo "✓ Telemetry collector running"
    else
        echo "⚠️  Telemetry collector not running - check logs with: sudo supervisorctl tail telemetry"
    fi
fi

echo "Post-start services initialized"