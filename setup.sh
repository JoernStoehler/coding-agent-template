#!/bin/bash
# Initial setup script for the coding agent infrastructure
# Run this once after cloning the repository

set -e

echo "🚀 Setting up Coding Agent Infrastructure..."

# Make scripts executable
echo "📁 Making scripts executable..."
chmod +x scripts/*.sh
chmod +x setup.sh

# Create basic directory structure
echo "📁 Creating directory structure..."
mkdir -p docs/workflows
mkdir -p docs/conventions
mkdir -p tests
mkdir -p .mail
mkdir -p .processes/logs

# Create basic workflow documentation
echo "📝 Creating workflow documentation..."
cat > docs/workflows/README.md << 'EOF'
# Workflow Documentation

This directory contains documentation for common agent workflows:

- `frontend-dev.md` - Frontend development patterns
- `backend-api.md` - Backend API development patterns  
- `bug-fixing.md` - Bug fixing and debugging workflows
- `testing.md` - Testing strategies and patterns

Each workflow document should include:
- Prerequisites and setup
- Step-by-step instructions
- Common commands and patterns
- Troubleshooting tips
- Example agent prompts
EOF

# Create conventions documentation
echo "📝 Creating conventions documentation..."
cat > docs/conventions/README.md << 'EOF'
# Project Conventions

This directory contains documentation for project standards:

- `git-workflow.md` - Git branching and commit conventions
- `coding-standards.md` - Code style and quality standards
- `file-organization.md` - Project structure and naming conventions
- `communication.md` - Agent communication patterns

These conventions help ensure consistency across agents and human contributors.
EOF

# Create a basic test structure
echo "🧪 Creating test structure..."
cat > tests/README.md << 'EOF'
# Testing

This directory contains tests for the coding agent infrastructure:

- `test_mcp_mail.py` - Mail system tests
- `test_mcp_processes.py` - Process manager tests
- `test_agent_workflow.sh` - Integration tests for agent workflows
- `test_multi_agent.sh` - Multi-agent coordination tests

Run tests with:
```bash
# Python tests
python -m pytest tests/

# Shell script tests
./tests/test_agent_workflow.sh
```
EOF

# Create environment template
echo "🔧 Creating environment template..."
cat > .env.template << 'EOF'
# Environment configuration template
# Copy this to .env and fill in your values

# User configuration
USER_NAME=your-name
USER_EMAIL=your-email@example.com

# Optional OTLP/Honeycomb configuration for telemetry
OTLP_ENDPOINT=https://api.honeycomb.io
HONEYCOMB_API_KEY=your-api-key

# Docker configuration
DOCKER_BUILDKIT=1
COMPOSE_DOCKER_CLI_BUILD=1
EOF

# Create basic requirements file for Python dependencies
echo "📦 Creating requirements file..."
cat > requirements.txt << 'EOF'
# Core MCP server dependencies
fastmcp>=0.1.0
pydantic>=2.0.0
python-dotenv>=1.0.0

# Development and utility dependencies
requests>=2.31.0
click>=8.1.0
rich>=13.0.0

# Testing dependencies
pytest>=7.0.0
pytest-asyncio>=0.21.0
EOF

# Create MCP server runner script
echo "🖥️ Creating MCP server runner..."
cat > run-mcp-servers.sh << 'EOF'
#!/bin/bash
# Start MCP servers in the background
# Usage: ./run-mcp-servers.sh [start|stop|status]

set -e

MAIL_PID_FILE="/tmp/mcp_mail.pid"
PROCESS_PID_FILE="/tmp/mcp_processes.pid"

start_servers() {
    echo "Starting MCP servers..."
    
    # Start mail server
    if [[ ! -f "$MAIL_PID_FILE" ]]; then
        python3 mcp_mail.py &
        echo $! > "$MAIL_PID_FILE"
        echo "✅ Mail server started (PID: $!)"
    else
        echo "⚠️  Mail server already running (PID: $(cat $MAIL_PID_FILE))"
    fi
    
    # Start process server
    if [[ ! -f "$PROCESS_PID_FILE" ]]; then
        python3 mcp_processes.py &
        echo $! > "$PROCESS_PID_FILE"
        echo "✅ Process server started (PID: $!)"
    else
        echo "⚠️  Process server already running (PID: $(cat $PROCESS_PID_FILE))"
    fi
}

stop_servers() {
    echo "Stopping MCP servers..."
    
    # Stop mail server
    if [[ -f "$MAIL_PID_FILE" ]]; then
        kill $(cat "$MAIL_PID_FILE") 2>/dev/null || true
        rm -f "$MAIL_PID_FILE"
        echo "✅ Mail server stopped"
    fi
    
    # Stop process server
    if [[ -f "$PROCESS_PID_FILE" ]]; then
        kill $(cat "$PROCESS_PID_FILE") 2>/dev/null || true
        rm -f "$PROCESS_PID_FILE"
        echo "✅ Process server stopped"
    fi
}

status_servers() {
    echo "MCP Server Status:"
    echo "=================="
    
    # Check mail server
    if [[ -f "$MAIL_PID_FILE" ]]; then
        PID=$(cat "$MAIL_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "✅ Mail server running (PID: $PID)"
        else
            echo "❌ Mail server PID file exists but process not running"
            rm -f "$MAIL_PID_FILE"
        fi
    else
        echo "❌ Mail server not running"
    fi
    
    # Check process server
    if [[ -f "$PROCESS_PID_FILE" ]]; then
        PID=$(cat "$PROCESS_PID_FILE")
        if kill -0 "$PID" 2>/dev/null; then
            echo "✅ Process server running (PID: $PID)"
        else
            echo "❌ Process server PID file exists but process not running"
            rm -f "$PROCESS_PID_FILE"
        fi
    else
        echo "❌ Process server not running"
    fi
}

case "${1:-start}" in
    start)
        start_servers
        ;;
    stop)
        stop_servers
        ;;
    restart)
        stop_servers
        sleep 2
        start_servers
        ;;
    status)
        status_servers
        ;;
    *)
        echo "Usage: $0 [start|stop|restart|status]"
        exit 1
        ;;
esac
EOF

chmod +x run-mcp-servers.sh

# Create basic health check script
echo "🏥 Creating health check script..."
mkdir -p health
cat > health/check_system.sh << 'EOF'
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
EOF

chmod +x health/check_system.sh

# Final summary
echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy .env.template to .env and configure your settings"
echo "2. Run: docker-compose up -d"
echo "3. Run: ./health/check_system.sh"
echo "4. Read the documentation in docs/"
echo ""
echo "🚀 You're ready to start using coding agents!"
echo ""
echo "To get started:"
echo "  docker-compose up -d"
echo "  docker-compose exec coding-agent bash"
echo "  ./scripts/setup-agent.sh my-first-agent 'Test the system'"
echo ""