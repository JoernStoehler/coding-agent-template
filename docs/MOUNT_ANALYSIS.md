# Container Mount Analysis

This document explains exactly what gets mounted where when using the VSCode devcontainer.

## 🎯 **Final Mount Configuration**

### **Host → Container Mappings**

When you open `/home/joern/workspaces/coding-agent/` in VSCode devcontainer:

#### **1. Workspace Mount (from devcontainer.json)**
```
HOST: /home/joern/workspaces/     → CONTAINER: /workspaces/
├── coding-agent/                   ├── coding-agent/
├── other-projects/                 ├── other-projects/
└── agent-worktrees/               └── agent-worktrees/
```

**Source**: `"source=${localWorkspaceFolder}/..,target=/workspaces"`  
**Result**: Agents can create worktrees in `/workspaces/agent-name/`

#### **2. Git Credentials (from devcontainer.json)**
```
HOST: /home/joern/.gitconfig      → CONTAINER: /home/user/.gitconfig
HOST: /home/joern/.ssh/           → CONTAINER: /home/user/.ssh/
```

**Result**: Git operations work with your host credentials

#### **3. Persistent Storage (from docker-compose.yml)**
```
Docker Volume: claude_auth        → CONTAINER: /home/user/.claude
Docker Volume: gemini_auth        → CONTAINER: /home/user/.gemini
Docker Volume: gh_auth            → CONTAINER: /home/user/.config/gh
Docker Volume: bash_history_data  → CONTAINER: /home/user/.bash_history_dir
```

**Result**: API keys and container-specific bash history persist across container rebuilds

## 🔄 **Mount Resolution Order**

1. **Docker Compose** defines the service and named volumes
2. **VSCode Devcontainer** overrides/adds bind mounts 
3. **VSCode Automatic** behavior is overridden by explicit mounts

## 📁 **Working Directory Structure**

Inside the container at `/workspaces/`:
```
/workspaces/
├── coding-agent/          # This repository (the infrastructure)
│   ├── .devcontainer/     # Devcontainer configuration
│   ├── scripts/           # Agent management scripts
│   └── ...               # All repo files
├── agent-worktree-1/     # Created by setup-agent.sh
├── agent-worktree-2/     # Created by setup-agent.sh
└── other-projects/       # Any other projects you have
```

## ✅ **Verification Commands**

Inside the devcontainer:
```bash
# Check workspace mount
ls -la /workspaces/
# Should show: coding-agent/ and any other host projects

# Check git credentials
git config --list
# Should show your host git configuration

# Check SSH keys
ls -la ~/.ssh/
# Should show your host SSH keys

# Check persistent volumes
ls -la ~/.claude/ ~/.gemini/
# Should show API configurations (persisted across rebuilds)

# Check bash history setup
echo $HISTFILE
# Should show: /home/user/.bash_history_dir/.bash_history
history | tail -5
# Should show recent container commands
```

## 🐛 **Common Issues**

### **Issue**: Agent setup fails with "no such directory"
**Cause**: Workspace mount not working correctly  
**Check**: `ls /workspaces/coding-agent/` should exist  
**Fix**: Rebuild devcontainer

### **Issue**: Git operations require password
**Cause**: Git credentials not mounted  
**Check**: `git config --list` shows your details  
**Fix**: Ensure `~/.gitconfig` exists on host

### **Issue**: API keys not working
**Cause**: Environment variables not loaded  
**Check**: `env | grep -E "(ANTHROPIC|GOOGLE)"`  
**Fix**: Ensure `.env` file exists and container reads it

## 🎯 **Design Rationale**

**Why mount parent directory?**
- Agents need to create worktrees outside the coding-agent repo
- Enables multi-project workflows
- Maintains clean separation between infrastructure and work

**Why use Docker named volumes for auth?**
- Survives container rebuilds
- Secure (not visible on host filesystem)
- Easy to backup/restore

**Why bind mount git credentials?**
- Seamless git operations
- No need to reconfigure inside container
- Uses your existing SSH keys and git config

**Why container-only bash history?**
- Security: Agent commands with API keys stay private
- Context: History focused on container workflows
- Clean separation: No pollution of host history
- Primary environment: You'll work mainly in container