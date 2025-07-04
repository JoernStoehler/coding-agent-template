# Bash History Design Decision

## 🎯 **Decision: Container-Only Bash History**

After careful analysis, we chose to keep bash history **container-only** using a Docker volume rather than syncing with the host.

## 🤔 **Reasoning**

### **Primary Development Environment**
- You'll work primarily **inside the container**
- Container commands are what you'll want to recall and reuse
- Host bash history becomes less relevant for daily workflow

### **Security & Privacy**
Agent workflows involve sensitive commands:
```bash
# These shouldn't leak to host history:
claude --api-key sk-... "@prompt.md"
export ANTHROPIC_API_KEY=sk-...
mcp__mail_read msg_containing_sensitive_info
./scripts/setup-agent.sh secret-project "Confidential task"
```

### **Context Separation**
Container and host have different:
- **Tools**: `claude`, MCP tools vs general host tools
- **Paths**: `/workspaces/` vs `/home/joern/`
- **Purpose**: Agent orchestration vs general development
- **Relevance**: Container history builds agent workflow expertise

### **Clean Command History**
Container-only history means:
- No pollution of host history with container-specific commands
- No confusion from host commands that don't work in container
- Focused, relevant command history for the container environment

## 🔧 **Implementation**

### **Docker Volume Mount**
```yaml
# docker-compose.yml
volumes:
  - bash_history_data:/home/user/.bash_history_dir
```

### **Bash Configuration**
```dockerfile
# Dockerfile
RUN mkdir -p /home/user/.bash_history_dir \
    && touch /home/user/.bash_history_dir/.bash_history \
    && echo 'export HISTFILE=/home/user/.bash_history_dir/.bash_history' >> /home/user/.bashrc \
    && echo 'export HISTSIZE=10000' >> /home/user/.bashrc \
    && echo 'export HISTFILESIZE=10000' >> /home/user/.bashrc
```

### **Benefits**
- ✅ **Persistence**: History survives container rebuilds
- ✅ **Security**: Sensitive commands stay in container
- ✅ **Context**: History relevant to container workflows
- ✅ **Performance**: No file sync overhead
- ✅ **Cleanliness**: Host history stays focused on host tasks

## 🛠 **Usage**

### **Inside Container**
```bash
# Your agent command history builds up:
claude "@prompt.md"
./scripts/setup-agent.sh my-agent "Task"
mcp__mail_send from="agent1" to=["agent2"] subject="Update"
cd /workspaces/agent-workspace/

# Use history normally:
history
!! # Repeat last command
!claude # Repeat last claude command
```

### **Accessing History**
```bash
# View recent commands
history | tail -20

# Search history
history | grep claude
history | grep mcp__

# History is automatically saved and restored between sessions
```

## 🔄 **Alternative Considered: Host Sync**

**Why we didn't choose host sync:**
- Security risk of exposing agent commands on host
- Context pollution (container commands in host history)
- Tool confusion (different available commands)
- Less focused development experience

## 📋 **Result**

This approach gives you:
1. **Clean separation** between host and container environments
2. **Security** by keeping agent commands private to container
3. **Focused history** that builds expertise in agent workflows
4. **Persistence** across container rebuilds
5. **No pollution** of your host command history

Perfect for container-first development workflow with AI agents!