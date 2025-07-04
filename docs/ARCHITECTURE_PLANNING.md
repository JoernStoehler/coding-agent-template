# Architecture Planning & Interface Specifications

## Critical Architecture Gaps

### 1. MCP Server Interface Specifications

**Mail Server (`mcp_mail.py`):**
```python
# Need exact API definitions:
mcp__mail_send(from: str, to: List[str], subject: str, body: str) -> str  # returns message_id
mcp__mail_inbox(to: str, from?: str, subject_contains?: str, since_hours?: int) -> List[MailSummary]
mcp__mail_read(id: str) -> MailDetail
mcp__mail_delete(id: str) -> bool
```

**Background Process Server (`mcp_processes.py`):**
```python
# Need exact API definitions:
mcp__process_start(command: str, cwd: str, env: Dict, owner: str, name: str) -> str  # returns process_id
mcp__process_list(owner?: str, status?: str) -> List[ProcessSummary]
mcp__process_logs(id: str, lines?: int, grep?: str) -> str
mcp__process_stop(id: str) -> bool
mcp__process_restart(id: str) -> bool
```

**Questions:**
- What's the exact mail storage format? JSON files in `/workspaces/.mail/`?
- How do we handle process cleanup on container restart?
- Should processes auto-restart on failure?
- What's the security model for cross-agent process access?

### 2. File System Layout & Conventions

**Current assumption:**
```
/workspaces/
├── .mail/              # Mail exchange directory
│   ├── {id}.json      # Individual mail messages
│   └── agents.json    # Agent registry
├── .processes/         # Process management
│   ├── {id}.json      # Process metadata
│   └── logs/          # Process logs
├── main/              # Main repository
├── feat-dashboard/    # Agent worktree example
│   ├── .env          # Agent-specific environment
│   ├── prompt.md     # Agent instructions
│   └── .agent-id     # Agent identifier
└── fix-bug-123/      # Another agent worktree
```

**Questions:**
- Should we use a different naming convention for worktrees?
- Where do we store agent metadata (status, created_at, etc.)?
- How do we handle cleanup of abandoned worktrees?
- Should `.env` files be gitignored globally?

### 3. Agent Lifecycle Management

**Current process:**
1. Orchestrator creates worktree: `git worktree add ../feat-X origin/main`
2. Orchestrator allocates resources (ports, etc.)
3. Orchestrator writes `.env` and `prompt.md`
4. Orchestrator tells human to spawn agent
5. Human runs: `cd ../feat-X && source .env && claude --dangerously-skip-permissions "@prompt.md"`

**Questions:**
- How do we track which agents are active vs. completed?
- Should we have a standard "agent shutdown" protocol?
- How do we handle agents that crash or get stuck?
- What's the merge/PR workflow when agents finish?

### 4. Resource Allocation Strategy

**Port allocation example:**
```bash
# In .env file:
AGENT_ID=feat-dashboard-001
MAIN_PORT=3001
API_PORT=3002
DEBUG_PORT=3003
AGENT_PORT_RANGE=3001-3010
```

**Questions:**
- Should we use a central port registry to avoid conflicts?
- How do we handle port conflicts with existing host processes?
- What other resources need allocation (database names, temp dirs)?
- Should agents be able to request additional ports dynamically?

### 5. Communication Protocol Specification

**Mail message format:**
```json
{
  "id": "msg_20240703_001",
  "from": "orchestrator",
  "to": ["feat-dashboard-001"],
  "subject": "Task update",
  "body": "Please implement the login form component",
  "timestamp": "2024-07-03T10:30:00Z",
  "read": false,
  "thread_id": "thread_123"
}
```

**Questions:**
- Should we support threaded conversations?
- How do we handle broadcast messages (to all agents)?
- Should we have message priorities or urgency levels?
- What's the message retention policy?

### 6. Error Handling & Recovery

**Failure scenarios:**
- Agent crashes mid-task
- Docker container restarts
- Git merge conflicts
- Port conflicts
- Disk space issues
- Rate limiting from Claude/Gemini APIs

**Questions:**
- Should we have automatic retry mechanisms?
- How do we preserve agent state across restarts?
- What's the rollback strategy for failed tasks?
- Should we implement circuit breakers for API calls?

### 7. Integration Points

**VSCode integration:**
- Mount: `~/workspaces` → `/workspaces`
- Command: `code --add /workspaces/feat-X`

**Git integration:**
- Worktrees for isolation
- Merge strategy: PR-based or direct merge?
- Commit message conventions?

**Docker integration:**
- Base image: Ubuntu? Python? Node?
- Volume mounts for persistence
- Network configuration

**Questions:**
- Should we use devcontainer.json for VSCode integration?
- What's the exact docker run command with all mounts?
- How do we handle git credentials in the container?
- Should we use docker-compose for multi-container setups?

## Milestone Definitions

### Milestone 1: Basic Agent Orchestration
**Acceptance Criteria:**
- [ ] Orchestrator can create worktrees with .env and prompt.md
- [ ] Human can spawn agents manually in worktrees
- [ ] Agents can communicate via mail system
- [ ] Agents can manage background processes
- [ ] VSCode can access all worktrees simultaneously

**Out of scope for M1:**
- Web dashboard
- Automatic agent spawning
- Advanced error handling
- Performance monitoring

### Milestone 2: Enhanced Workflow
**Acceptance Criteria:**
- [ ] Web dashboard for agent monitoring
- [ ] Automatic merge/PR workflow
- [ ] Agent status tracking
- [ ] Better error handling and recovery

### Milestone 3: Advanced Features
**Acceptance Criteria:**
- [ ] A/B testing workflows
- [ ] Advanced agent collaboration
- [ ] Performance monitoring
- [ ] Auto-scaling based on load

## Technical Specifications Needed

### Docker Configuration
- Base image choice and rationale
- Required packages and tools
- Volume mount strategy
- Network configuration
- Security considerations

### MCP Server Implementation
- FastMCP vs. other frameworks
- Error handling patterns
- Logging and monitoring
- Performance requirements

### Agent Onboarding Documentation
- Standard prompt templates
- Common workflow patterns
- Troubleshooting guides
- Best practices and anti-patterns

## Decision Records Needed

1. **DR001: Container Strategy** - Why shared container over per-agent
2. **DR002: Communication Protocol** - Why file-based mail over network
3. **DR003: Resource Allocation** - Why env files over centralized registry
4. **DR004: Agent Spawning** - Why manual over automatic spawning
5. **DR005: Git Strategy** - Why worktrees over separate repos
6. **DR006: Process Management** - Why custom MCP over existing tools
7. **DR007: Security Model** - Trust boundaries and threat model
8. **DR008: Data Persistence** - What survives container restarts
9. **DR009: Error Handling** - Failure modes and recovery strategies
10. **DR010: Monitoring Strategy** - How to observe system health