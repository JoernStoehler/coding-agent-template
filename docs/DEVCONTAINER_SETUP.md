# Devcontainer Setup Guide

This guide covers switching from manual Docker to VSCode devcontainer for the best development experience.

## 🎯 **Why Devcontainer?**

**Advantages:**
- ✅ **Git credentials** automatically forwarded from host
- ✅ **Extensions** auto-install and sync
- ✅ **Industry standard** approach
- ✅ **Local performance** when working locally
- ✅ **Remote flexibility** via `code tunnel` + devcontainer
- ✅ **One-click setup** for new developers

## 🚀 **Quick Setup**

### **Option 1: Local Development**
```bash
# 1. Copy environment template
cp .env.template .env
# Edit .env with your API keys and details

# 2. Open in VSCode
code .

# 3. CMD+Shift+P → "Dev Containers: Reopen in Container"
# VSCode builds and opens the container automatically
```

### **Option 2: Remote Development**
```bash
# 1. SSH to your remote machine
ssh your-server

# 2. Clone and setup
git clone <repo> && cd coding-agent
cp .env.template .env && nano .env

# 3. Start VSCode tunnel
code tunnel

# 4. Open https://vscode.dev
# 5. Connect to your tunnel
# 6. CMD+Shift+P → "Dev Containers: Reopen in Container"
```

## 🔧 **Configuration Details**

### **Automatic Features**
- **Git credentials**: Your `~/.gitconfig` and `~/.ssh` mounted automatically
- **Extensions**: Python, JSON, Git Graph, etc. auto-installed
- **Port forwarding**: Ports 3000-3010, 5000, 8080 forwarded
- **API keys**: Loaded from `.env` file automatically

### **File Structure**
```
.devcontainer/
├── devcontainer.json     # VSCode configuration
└── docker-compose.yml    # Container definition
```

### **Environment Variables**
The devcontainer reads from your `.env` file:
```bash
# Required for agents to work
ANTHROPIC_API_KEY=your-claude-key
GOOGLE_API_KEY=your-gemini-key

# Your identity for git commits
USER_NAME=your-name
USER_EMAIL=your@email.com
```

## 🛠 **Development Workflow**

### **Daily Usage**
```bash
# Just open VSCode - everything else is automatic
code .
# If not in container: CMD+Shift+P → "Reopen in Container"
```

### **Creating Agents**
```bash
# Inside VSCode terminal (automatically in container)
./scripts/setup-agent.sh my-agent "Task description"
cd /workspaces/my-agent
source .env
claude "@prompt.md"
```

### **Rebuilding Container**
```bash
# When you change Dockerfile or dependencies
# CMD+Shift+P → "Dev Containers: Rebuild Container"
```

## 🔄 **Migration from Manual Docker**

If you were using the old manual approach:

```bash
# 1. Stop old container
docker-compose down

# 2. Move to devcontainer
# (Already done in the repo)

# 3. Open in VSCode
code .
# CMD+Shift+P → "Dev Containers: Open in Container"
```

## 🌐 **Remote Work Setup**

### **Host Machine**
```bash
# Install VSCode and enable tunneling
code tunnel --accept-server-license-terms

# Clone repo and setup
git clone <repo> && cd coding-agent
cp .env.template .env && nano .env
```

### **Local Machine**
```bash
# Open https://vscode.dev
# Connect to your tunnel
# Open the coding-agent folder
# CMD+Shift+P → "Dev Containers: Reopen in Container"
```

**Result**: Full VSCode experience running remotely in container!

## 🐛 **Troubleshooting**

### **Container won't start**
```bash
# Check your .env file
cat .env

# Try rebuilding
# CMD+Shift+P → "Dev Containers: Rebuild Container Without Cache"
```

### **Container build hangs during setup**
If the Docker build process hangs or times out during container setup:

**Common symptoms:**
- Build stops at "Installing Cloudflared" or "Installing OTEL Collector"
- Download progress stalls at 0% for extended periods
- Build eventually fails with timeout or network errors

**Root cause:** GitHub `/latest/download/` URLs occasionally return 404 errors or have network issues.

**Solution implemented:**
- Cloudflared: Uses official `/latest/download/` URL with retry logic
- OTEL Collector: Uses GitHub API to get versioned `.deb` package URL
- Both: Include connection timeouts and retry mechanisms

**Recovery steps:**
```bash
# Force rebuild without cache
# CMD+Shift+P → "Dev Containers: Rebuild Container Without Cache"

# If still failing, check network connectivity
curl -I https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
```

**Technical details:**
The Dockerfile `.devcontainer/Dockerfile` uses proper package management:
- GitHub API calls to get latest release URLs (for OTEL Collector)
- `apt-get install` instead of `dpkg` for dependency resolution
- Temporary file handling with proper cleanup

### **Git not working**
```bash
# Verify git config mounted
git config --list

# Check SSH keys
ls -la ~/.ssh/
```

### **API keys not working**
```bash
# Check environment variables loaded
env | grep -E "(ANTHROPIC|GOOGLE)"

# Verify .env file
cat .env
```

### **Extensions not loading**
```bash
# CMD+Shift+P → "Developer: Reload Window"
```

## 🔒 **Security Notes**

- **Git credentials**: Mounted read-only from host
- **SSH keys**: Mounted for git operations
- **API keys**: In `.env` file (add to `.gitignore`)
- **Container isolation**: Full container isolation from host system

## 📚 **References**

- [VSCode Devcontainers Documentation](https://code.visualstudio.com/docs/remote/containers)
- [Remote Tunneling Guide](https://code.visualstudio.com/docs/remote/tunnels)
- [Docker Compose in Devcontainers](https://code.visualstudio.com/docs/remote/create-dev-container#_use-docker-compose)