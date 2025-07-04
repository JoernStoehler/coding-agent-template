# Architecture and Design Decisions

This document explains how the system works and why it's designed this way.

## System Overview

```
┌─────────────────────────────────────┐
│         Docker Container            │
│                                     │
│  ┌─────────────┐  ┌──────────────┐ │
│  │   Agent 1   │  │   Agent 2    │ │
│  │ (worktree)  │  │  (worktree)  │ │
│  └──────┬──────┘  └──────┬───────┘ │
│         │                 │         │
│         └────────┬────────┘         │
│                  ▼                  │
│           ┌─────────────┐           │
│           │ Mail System │           │
│           │   (JSON)    │           │
│           └─────────────┘           │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    Shared /workspaces       │   │
│  │  - main repo                │   │
│  │  - agent worktrees          │   │
│  │  - mail messages            │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

## Key Design Decisions

### 1. Single Shared Container

**Decision**: All agents run in one Docker container.

**Why**:
- Simplifies networking (all on localhost)
- Easy file sharing via /workspaces
- Lower resource overhead
- Simpler to debug and monitor

**Trade-offs**:
- Agents share resources
- No security isolation
- Can't scale across machines

### 2. Git Worktrees for Isolation

**Decision**: Each agent works in a separate git worktree.

**Why**:
- Natural branch isolation
- Easy to create/destroy
- Familiar git workflow
- No custom abstractions

**Example**:
```
/workspaces/
├── main/              # Primary repository
├── feat-auth/         # Agent 1's worktree
├── fix-bug-123/       # Agent 2's worktree
└── test-integration/  # Agent 3's worktree
```

### 3. JSON File Mail System

**Decision**: Agents communicate via JSON files in a shared directory.

**Why**:
- Human-readable for debugging
- No database needed
- Simple to implement
- Naturally persistent
- Git-friendly format

**Trade-offs**:
- No complex queries
- Manual cleanup needed
- Linear performance

### 4. Manual Agent Spawning

**Decision**: Humans must manually start agents in terminals.

**Why**:
- Control over API costs
- Easy to monitor output
- Natural rate limiting
- Clear responsibility
- Simple debugging

**Alternative considered**: Automatic spawning would add complexity without clear benefit for current scale.

### 5. Environment-Based Configuration

**Decision**: Each agent gets a `.env` file with its configuration.

**Why**:
- Self-contained setup
- Standard practice
- Easy to modify
- No central registry
- Works with existing tools

### 6. YAGNI Philosophy

**Decision**: Start simple, add complexity only when proven necessary.

**Examples**:
- No agent authentication (trust model)
- No automatic retries
- No distributed coordination
- No web dashboard (yet)
- Root user in container

Each can be added later if needed.

## Component Details

### Docker Container

**Base image**: `python:3.11-slim`
- Includes Python ecosystem
- Minimal size
- Debian-based (familiar)

**Installed tools**:
- Git, vim, tmux, screen
- Python with FastMCP
- Node.js for JavaScript
- Basic dev utilities

**Persistence**: Only `/workspaces/` survives container rebuilds.

### Mail System

**Message lifecycle**:
1. Agent calls `mcp__mail_send`
2. Message saved as JSON file
3. Recipient polls with `mcp__mail_inbox`
4. Full message read with `mcp__mail_read`
5. Optional deletion with `mcp__mail_delete`

**File format**: `msg_{uuid4}.json`
```json
{
  "id": "msg_550e8400...",
  "from": "agent-1",
  "to": ["agent-2", "orchestrator"],
  "subject": "Status Update",
  "body": "Task completed successfully",
  "timestamp": "2025-01-04T10:30:00Z",
  "read": false
}
```

### Port Allocation

**Strategy**: Sequential allocation starting from 3000.

```
main:     5000 (reserved)
agent-1:  3000-3009
agent-2:  3010-3019
agent-3:  3020-3029
```

**Implementation**: `setup-agent.sh` scans existing `.env` files to find next available range.

### Process Management

**Current approach**: Basic Unix process management.
- Background with `&`
- Track with PID files
- Processes reparent to init
- Survive terminal closure

**Future option**: Could add proper process manager if needed.

## Scaling Considerations

### Current Limits
- ~10 concurrent agents (resource bound)
- Single machine only
- Manual coordination
- No automatic load balancing

### Scaling Path
1. **Vertical**: Increase container resources
2. **Horizontal**: Multiple containers (requires network mail system)
3. **Distributed**: Multi-machine with message queue
4. **Managed**: Kubernetes deployment

Each step adds complexity - only take when needed.

## Security Model

### Current (MVP)
- Shared container = shared trust
- No agent authentication
- Read-only SSH key mounts
- No resource quotas
- Suitable for controlled environments

### Future Enhancements
- User namespace isolation
- Agent capability restrictions
- Resource quotas per agent
- Audit logging
- Network policies

## Comparison with Alternatives

### vs. Kubernetes
- K8s: Complex orchestration, high learning curve
- This: Simple Docker, quick to understand

### vs. Separate Containers
- Separate: Network complexity, resource overhead
- This: Shared filesystem, easy communication

### vs. Cloud Functions
- Functions: Stateless, short-lived, vendor lock-in
- This: Stateful, long-running, portable

### vs. Local Processes
- Local: No isolation, dependency conflicts
- This: Clean environment, reproducible

## Future Considerations

**When to add complexity**:
- Web dashboard: When monitoring many agents
- Authentication: When untrusted agents exist
- Distribution: When single machine insufficient
- Persistence: When rebuilding containers frequently

**What to keep simple**:
- File-based mail (works well)
- Git worktrees (proven solution)
- Manual spawning (human oversight valuable)
- JSON storage (debuggable)

The architecture prioritizes developer understanding over system sophistication. This is intentional - a system you understand is one you can fix, extend, and trust.