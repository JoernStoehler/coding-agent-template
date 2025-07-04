#!/bin/bash
# List all running agents and their status
# Usage: ./list-agents.sh [--json]

set -e

# Check if jq is available for JSON output
if ! command -v jq &> /dev/null; then
    echo "Warning: jq not installed, JSON output will be raw" >&2
fi

# Function to get agent info from a process
get_agent_info() {
    local pid=$1
    local cwd=$(pwdx "$pid" 2>/dev/null | cut -d' ' -f2- || echo "unknown")
    local cmd=$(ps -p "$pid" -o cmd --no-headers 2>/dev/null || echo "unknown")
    local start_time=$(ps -p "$pid" -o lstart --no-headers 2>/dev/null || echo "unknown")
    
    # Extract agent name from cwd if it's a worktree
    local agent_name="unknown"
    if [[ "$cwd" =~ /workspaces/([^/]+)$ ]]; then
        agent_name="${BASH_REMATCH[1]}"
    fi
    
    echo "$pid|$agent_name|$cwd|$start_time|$cmd"
}

# Find all claude and gemini processes
echo "Finding running AI agents..."
agent_processes=$(ps aux | grep -E "(claude|gemini)" | grep -v grep | grep -v "$0" | awk '{print $2}')

if [[ -z "$agent_processes" ]]; then
    echo "No running AI agents found."
    exit 0
fi

# Collect agent information
agents=()
while IFS= read -r pid; do
    if [[ -n "$pid" ]]; then
        agent_info=$(get_agent_info "$pid")
        agents+=("$agent_info")
    fi
done <<< "$agent_processes"

# Output format
if [[ "$1" == "--json" ]]; then
    # JSON output
    echo "["
    first=true
    for agent in "${agents[@]}"; do
        IFS='|' read -r pid name cwd start_time cmd <<< "$agent"
        if [[ "$first" == true ]]; then
            first=false
        else
            echo ","
        fi
        echo "  {"
        echo "    \"pid\": $pid,"
        echo "    \"name\": \"$name\","
        echo "    \"cwd\": \"$cwd\","
        echo "    \"start_time\": \"$start_time\","
        echo "    \"command\": \"$cmd\""
        echo -n "  }"
    done
    echo ""
    echo "]"
else
    # Human-readable output
    echo ""
    echo "Running AI Agents:"
    echo "=================="
    printf "%-8s %-20s %-30s %-20s %s\n" "PID" "AGENT" "DIRECTORY" "STARTED" "COMMAND"
    echo "------------------------------------------------------------------------"
    
    for agent in "${agents[@]}"; do
        IFS='|' read -r pid name cwd start_time cmd <<< "$agent"
        # Truncate long paths and commands for display
        short_cwd=$(echo "$cwd" | sed 's|/workspaces/||' | cut -c1-28)
        short_cmd=$(echo "$cmd" | cut -c1-40)
        printf "%-8s %-20s %-30s %-20s %s\n" "$pid" "$name" "$short_cwd" "$start_time" "$short_cmd"
    done
    
    echo ""
    echo "Total agents: ${#agents[@]}"
    
    # Show worktree information
    echo ""
    echo "Available Worktrees:"
    echo "==================="
    if [[ -d "/workspaces" ]]; then
        for dir in /workspaces/*/; do
            if [[ -d "$dir" && "$dir" != "/workspaces/main/" ]]; then
                worktree_name=$(basename "$dir")
                if [[ -f "$dir/.env" ]]; then
                    echo "  $worktree_name (configured)"
                else
                    echo "  $worktree_name (no .env)"
                fi
            fi
        done
    fi
fi