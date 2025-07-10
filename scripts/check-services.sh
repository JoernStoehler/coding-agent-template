#!/bin/bash
# check-services.sh - Service health and environment status checker
#
# DESCRIPTION:
#   Checks the health of various services and authentication states required
#   for the coding agent development environment. Provides actionable feedback
#   with specific commands to fix any issues found.
#
# USAGE:
#   check-services [OPTIONS]
#   
#   Options:
#     -v, --verbose  Show all checks including passed ones
#     --quick        Quick mode for prompt (exit code only)
#     -h, --help     Show help message
#
# MODES:
#   1. NORMAL (default): Shows only warnings with fix commands
#   2. VERBOSE (-v): Shows all checks, including successful ones
#   3. QUICK (--quick): Silent mode, only returns exit code (0=OK, 1=warnings)
#
# ARCHITECTURE DECISIONS:
#   1. UNIFIED SCRIPT: Combined status checking and quick checks because:
#      - Reduces code duplication
#      - Single source of truth for what constitutes a "warning"
#      - Easier to maintain consistent behavior
#      - More efficient than separate scripts
#
#   2. ACTIONABLE OUTPUT: Every warning includes the fix command because:
#      - Developers can immediately resolve issues
#      - No need to search documentation
#      - Reduces context switching
#      - Self-documenting system
#
#   3. EXIT CODES: Returns non-zero when warnings exist to:
#      - Enable scripting and automation
#      - Support prompt warning indicator
#      - Allow CI/CD integration
#
#   4. SERVICE DETECTION: Smart detection logic:
#      - Only shows cloudflared if running (not everyone needs it)
#      - Only checks Gemini if GOOGLE_API_KEY is set
#      - Avoids noise from irrelevant services
#
# CHECKED SERVICES:
#   Critical (always checked, shown in --quick mode):
#     - OTEL collector (telemetry/cost tracking)
#     - Claude authentication (via OAuth or API key)
#   
#   Important (always checked in normal/verbose):
#     - GitHub CLI authentication
#     - Gemini authentication (if API key present)
#     - Cloudflared (if running)
#   
#   Informational (verbose mode only):
#     - Current agent/worktree info
#     - Git branch and remote
#     - System info (user, hostname, directory)
#     - Disk space
#
# PERFORMANCE NOTES:
#   - Quick mode only runs 2 pgrep calls and 2 file checks (<10ms)
#   - Normal mode adds ~3-5 process checks
#   - Verbose mode adds git operations (~50ms)
#   - All modes avoid network calls
#
# CUSTOMIZATION:
#   To add new service checks:
#   1. Add to appropriate section (service/auth/env)
#   2. Use check_service() or check_auth() helpers
#   3. Include actionable fix command
#   4. Consider if it should be in --quick mode
#
# RELATED FILES:
#   - bash-customize.sh: Sources this for check-services command
#   - postCreateCommand.sh: Initial setup that this validates
#   - run-telemetry.sh: Script to start OTEL collector
#   - .config/starship.toml: Uses --quick mode for prompt indicator
#
# FUTURE CONSIDERATIONS:
#   - Could add --fix flag to auto-run fix commands
#   - Could cache results for prompt performance
#   - Could add service dependency checking
#   - Could integrate with project management service

# Parse arguments
mode="normal"
for arg in "$@"; do
    case $arg in
        -v|--verbose)
            mode="verbose"
            ;;
        --quick)
            mode="quick"
            ;;
        -h|--help)
            echo "Usage: check-services [OPTIONS]"
            echo "Check service status and environment configuration"
            echo ""
            echo "Options:"
            echo "  -v, --verbose  Show all checks including passed ones"
            echo "  --quick        Quick mode for prompt (exit code only)"
            echo "  -h, --help     Show this help message"
            exit 0
            ;;
    esac
done

# Quick mode - just check critical services and exit with status
if [ "$mode" = "quick" ]; then
    # OTEL collector
    pgrep -f otelcol-contrib >/dev/null || exit 1
    
    # Claude auth
    [ -f ~/.claude/.credentials.json ] || [ -n "$ANTHROPIC_API_KEY" ] || exit 1
    
    # All good
    exit 0
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track if we have warnings
has_warnings=0

# Verbose mode
verbose=false
[ "$mode" = "verbose" ] && verbose=true

# Service checks
check_service() {
    local name="$1"
    local check_cmd="$2"
    local fix_cmd="$3"
    
    if eval "$check_cmd" >/dev/null 2>&1; then
        $verbose && echo -e "${GREEN}✓${NC} $name"
    else
        echo -e "${YELLOW}⚠️${NC}  $name not running: run \`$fix_cmd\`"
        has_warnings=1
    fi
}

# Auth checks
check_auth() {
    local name="$1"
    local check_cmd="$2"
    local fix_cmd="$3"
    
    if eval "$check_cmd" >/dev/null 2>&1; then
        if $verbose; then
            # For some services, show more info
            case "$name" in
                "GitHub CLI")
                    local user=$(gh api user --jq .login 2>/dev/null || echo "unknown")
                    echo -e "${GREEN}✓${NC} $name authenticated as: $user"
                    ;;
                *)
                    echo -e "${GREEN}✓${NC} $name authenticated"
                    ;;
            esac
        fi
    else
        echo -e "${YELLOW}⚠️${NC}  $name not authenticated: run \`$fix_cmd\`"
        has_warnings=1
    fi
}

# Environment checks
check_env() {
    local name="$1"
    local check_cmd="$2"
    local info_cmd="$3"
    
    if eval "$check_cmd" >/dev/null 2>&1; then
        if $verbose && [ -n "$info_cmd" ]; then
            local info=$(eval "$info_cmd" 2>/dev/null)
            echo -e "${GREEN}✓${NC} $name: $info"
        elif $verbose; then
            echo -e "${GREEN}✓${NC} $name"
        fi
    else
        # Don't show as warning in non-verbose mode
        $verbose && echo -e "${BLUE}ℹ${NC} $name"
    fi
}

# Run checks
echo "=== Service Status ==="

# Critical services
check_service "OTEL collector" "pgrep -f otelcol-contrib" "sudo supervisorctl start telemetry"

# Authentication
check_auth "Claude" "[ -f ~/.claude/.credentials.json ] || [ -n \"\$ANTHROPIC_API_KEY\" ]" "claude auth login or export ANTHROPIC_API_KEY=..."
check_auth "GitHub CLI" "gh auth status" "gh auth login"

# Optional auth (only check if env var exists)
if [ -n "$GOOGLE_API_KEY" ] || $verbose; then
    check_auth "Gemini" "[ -n \"\$GOOGLE_API_KEY\" ]" "export GOOGLE_API_KEY=..."
fi

# Cloudflared (only if we expect it to be running)
if pgrep -f cloudflared >/dev/null 2>&1 || $verbose; then
    check_service "Cloudflared" "pgrep -f cloudflared" "cloudflared tunnel run"
fi

# Environment info (verbose only)
if $verbose; then
    echo ""
    echo "=== Environment ==="
    
    # Worktree info
    if [ -n "$AGENT_NAME" ]; then
        check_env "Agent" "true" "echo \$AGENT_NAME (port \${MAIN_PORT:-none})"
    fi
    
    # Git info
    if git rev-parse --git-dir >/dev/null 2>&1; then
        check_env "Git branch" "true" "git branch --show-current | tr -d '\n' && echo -n ' → ' && (git config --get branch.\$(git branch --show-current).remote || echo 'none')"
    fi
    
    # System info
    check_env "Host" "true" "echo \$(whoami)@\$(hostname)"
    check_env "Directory" "true" "pwd"
    
    # Disk space
    check_env "Disk free" "true" "df -h /workspaces | awk 'NR==2 {print \$4}'"
fi

echo "===================="

# Exit with warning status
exit $has_warnings