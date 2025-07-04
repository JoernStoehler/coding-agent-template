# Technical Decisions & Implementation Notes

This document captures key technical decisions made during development and critical knowledge for maintaining/extending the system.

## Architecture Decisions

### ADR-001: Container Strategy - Shared vs Per-Agent
**Decision**: Single shared Docker container for all agents  
**Rationale**: 
- Simpler orchestration and resource management
- Easy VSCode integration via single mount point
- Agent-to-agent communication simplified
- YAGNI principle - avoid premature optimization

**Alternatives Considered**: Per-agent containers
**Trade-offs**: Less isolation, but significantly simpler implementation

### ADR-002: Base Docker Image Selection  
**Decision**: `python:3.11-slim` (Debian 12 bookworm)  
**Rationale**:
- 4x smaller than Ubuntu (80MB vs 300MB+)
- Python 3.11 pre-installed and properly configured
- Debian 12 stable, modern, excellent package management
- Industry standard for Python production environments

**Previous Issues**: Ubuntu 22.04 lacks Python 3.12, Node.js 12 too old
**Implementation**: Official NodeSource PPA for Node.js 20 LTS

### ADR-003: Git Integration Strategy
**Decision**: Git worktrees with automatic branch creation  
**Command**: `git worktree add -b <branch> ../<worktree> <base-branch>`

**Rationale**:
- Clean isolation between agents
- Shared repository history
- Easy merge management
- Standard git workflow

**Critical Implementation Detail**: Must create worktree AND branch in single command to avoid "already checked out" errors.

### ADR-004: MCP Server Configuration
**Decision**: Relative paths with explicit `cwd` parameter  
**Format**:
```json
{
  "mcpServers": {
    "mail": {
      "command": "python3",
      "args": ["scripts/mcp-servers/mcp_mail.py"],
      "cwd": "/workspaces"
    }
  }
}
```

**Rationale**: Environment portability, works across different container setups
**Previous Issues**: Absolute paths break in different environments

### ADR-005: Resource Allocation Strategy
**Decision**: Sequential port allocation starting from 3000  
**Implementation**: Each agent gets 10-port range (MAIN_PORT to MAIN_PORT+9)

**Rationale**: Simple, predictable, easy to debug
**Trade-offs**: No conflict detection, but sufficient for MVP

## Implementation Patterns

### Agent Setup Workflow
1. **Central Planner** creates worktree with `scripts/setup-agent.sh`
2. **Human Admin** spawns agent: `cd <worktree> && source .env && claude "@prompt.md"`
3. **Agent** works with MCP tools, commits frequently
4. **Central Planner** handles merges and cleanup

### File Structure Convention
```
/workspaces/
├── main/                    # Base repository
├── <agent-name>/           # Agent worktrees
│   ├── .env               # Resource allocation
│   ├── .mcp.json          # MCP configuration  
│   ├── prompt.md          # Agent instructions
│   ├── tmp/              # Temporary files
│   └── logs/             # Agent logs
├── .mail/                # Inter-agent communication
└── .processes/           # Background process management
```

### Agent Communication Protocol
- **Mail System**: JSON files in `/workspaces/.mail/`
- **Process Management**: Metadata in `/workspaces/.processes/`
- **Both**: FastMCP-based servers, auto-started by claude

## Critical Implementation Details

### Docker Volume Strategy
**Working**: Directory mounts for persistent auth
```yaml
volumes:
  - claude_auth:/home/user/.claude
  - gemini_auth:/home/user/.gemini
  - bash_history:/home/user/.bash_history
```

**Avoided**: File mounts create directory conflicts
```yaml
# DON'T DO THIS - creates directory instead of file
- git_config:/home/user/.gitconfig
```

### Git Configuration
**Solution**: Configure git in Dockerfile as non-root user
```dockerfile
USER user
RUN git config --global init.defaultBranch main \
    && git config --global user.name "Coding Agent" \
    && git config --global user.email "agent@example.com"
```

**Why**: Avoids volume mount complexity, works reliably

### Node.js Installation
**Critical**: Use official NodeSource repository
```dockerfile
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs
```

**Why**: Debian default Node.js 12 is too old for claude-code (requires 18+)

## Known Issues & Limitations

### 1. Port Conflict Detection
**Issue**: No automatic detection of port conflicts  
**Workaround**: Manual port range allocation  
**Future**: Implement port scanning in setup script

### 2. Agent Cleanup
**Issue**: No automatic cleanup of abandoned agents  
**Workaround**: Manual cleanup with `git worktree remove`  
**Future**: Add timeout-based cleanup script

### 3. MCP Server Dependencies  
**Issue**: Agents depend on FastMCP but installation not verified  
**Mitigation**: Pre-installed in Docker image  
**Future**: Add health checks for MCP servers

### 4. Cross-Environment Paths
**Issue**: Hardcoded `/workspaces` path  
**Mitigation**: Documented convention  
**Future**: Make configurable via environment variables

## Development Environment Setup

### Required Tools
- Docker & Docker Compose
- Git
- VSCode (optional but recommended)

### Environment Variables  
Create `.env` from `.env.template`:
```bash
USER_NAME=your-name
USER_EMAIL=your-email@example.com
OTLP_ENDPOINT=https://api.honeycomb.io  # optional
HONEYCOMB_API_KEY=your-key              # optional
```

### Common Commands
```bash
# Initial setup
docker-compose up -d
docker-compose exec coding-agent bash

# Create agent environment
./scripts/setup-agent.sh <name> "<description>"

# Monitor agents
./scripts/list-agents.sh

# Health check
./health/check_system.sh
```

## Testing Strategy

### Manual Testing Checklist
- [ ] Docker builds without errors
- [ ] Container starts and bash accessible
- [ ] Git config working in container
- [ ] Claude-code CLI installed and accessible
- [ ] Setup script creates worktrees successfully
- [ ] MCP servers can be started (FastMCP available)
- [ ] Mail system basic functionality
- [ ] Process manager basic functionality

### Integration Testing
- [ ] Agent can be spawned and accesses MCP tools
- [ ] Agents can communicate via mail system
- [ ] Background processes can be started and managed
- [ ] Git workflow (commit, branch management) works
- [ ] VSCode integration functional

## Security Considerations

### Current Security Model
- **Trust-based**: Agents have full access to their worktrees
- **Container isolation**: Agents isolated from host system
- **No network restrictions**: Agents can access external APIs
- **Shared file system**: All agents share `/workspaces`

### Security Trade-offs
- **Prioritized**: Simplicity and developer experience
- **Accepted Risk**: Malicious agent could affect other agents
- **Mitigation**: Code review, agent instruction clarity

## Performance Characteristics

### Resource Usage
- **Base Image**: ~400MB (python:3.11-slim + deps)
- **Memory**: ~100MB base + agent overhead
- **Storage**: Scales with number of worktrees
- **Network**: Depends on agent API usage

### Scaling Considerations
- **Current**: Designed for 5-10 concurrent agents
- **Bottlenecks**: Single container CPU, memory
- **Future**: Could scale to per-agent containers if needed

## Maintenance Guide

### Regular Maintenance
1. **Update base image**: Rebuild monthly for security updates
2. **Clean up old worktrees**: Remove completed agent branches
3. **Monitor disk usage**: `/workspaces` can grow large
4. **Update claude-code**: `npm update -g @anthropic-ai/claude-code`

### Troubleshooting Common Issues
1. **Build failures**: Check Node.js/Python versions in Dockerfile
2. **Git errors**: Verify git config and worktree state
3. **Port conflicts**: Check allocated port ranges
4. **MCP errors**: Verify FastMCP installation and server paths

## Future Improvements

### High Priority
- [ ] Add health checks for MCP servers
- [ ] Implement port conflict detection
- [ ] Add agent timeout and cleanup
- [ ] Create comprehensive test suite

### Medium Priority  
- [ ] Web dashboard for agent monitoring
- [ ] Advanced agent coordination patterns
- [ ] Performance monitoring and metrics
- [ ] Enhanced security isolation

### Low Priority
- [ ] Multi-repository support
- [ ] Cloud deployment options
- [ ] Agent templates and workflows
- [ ] Integration with CI/CD systems

## Handoff Checklist

For successful handoff to another developer:

### Must Read
- [ ] This document (TECHNICAL_DECISIONS.md)
- [ ] Main README.md
- [ ] docs/ARCHITECTURE_REFINED.md
- [ ] docs/agent-onboarding.md

### Must Test
- [ ] Complete docker-compose build and run
- [ ] Create test agent with setup script
- [ ] Verify basic MCP server functionality
- [ ] Check VSCode integration

### Must Understand
- [ ] Git worktree workflow and constraints
- [ ] MCP server architecture and configuration
- [ ] Agent communication patterns
- [ ] Docker volume mount strategy

### Access Required
- [ ] Docker environment
- [ ] Git repository access
- [ ] Understanding of FastMCP and claude-code CLI
- [ ] Basic Python and Node.js knowledge

---

**Last Updated**: 2024-07-04  
**Version**: 1.0 (MVP)  
**Maintainer**: Development team