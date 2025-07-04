#!/bin/bash
# System health check for coding agent infrastructure

set -e

echo "🏥 Coding Agent Infrastructure Health Check"
echo "==========================================="

# Check Docker
echo "🐳 Docker Status:"
if command -v docker &> /dev/null; then
    docker --version
    echo "✅ Docker is installed"
else
    echo "❌ Docker not found"
fi

# Check Docker Compose
echo ""
echo "🐳 Docker Compose Status:"
if command -v docker-compose &> /dev/null; then
    docker-compose --version
    echo "✅ Docker Compose is installed"
else
    echo "❌ Docker Compose not found"
fi

# Check directories
echo ""
echo "📁 Directory Structure:"
for dir in .mail .processes scripts docs tests; do
    if [[ -d "$dir" ]]; then
        echo "✅ $dir exists"
    else
        echo "❌ $dir missing"
    fi
done

# Check scripts
echo ""
echo "📜 Script Status:"
for script in scripts/list-agents.sh scripts/setup-agent.sh run-mcp-servers.sh; do
    if [[ -x "$script" ]]; then
        echo "✅ $script executable"
    else
        echo "❌ $script not executable"
    fi
done

# Check Python dependencies
echo ""
echo "🐍 Python Dependencies:"
if command -v python3 &> /dev/null; then
    python3 --version
    if python3 -c "import fastmcp" 2>/dev/null; then
        echo "✅ FastMCP available"
    else
        echo "⚠️  FastMCP not installed (run: pip install fastmcp)"
    fi
else
    echo "❌ Python 3 not found"
fi

# Check ports
echo ""
echo "🔌 Port Status:"
for port in 5000 3000 3001 3002; do
    if lsof -i :$port >/dev/null 2>&1; then
        echo "⚠️  Port $port is in use"
    else
        echo "✅ Port $port available"
    fi
done

echo ""
echo "🎯 Health Check Complete!"
