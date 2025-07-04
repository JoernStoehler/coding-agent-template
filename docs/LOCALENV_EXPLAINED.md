# LocalEnv and Environment Variables Explained

## 🤔 **How `localEnv` Works**

### **Yes, we inherit from HOST**
```json
"containerEnv": {
  "ANTHROPIC_API_KEY": "${localEnv:ANTHROPIC_API_KEY}"
}
```

**What happens:**
1. VSCode reads `ANTHROPIC_API_KEY` from **host environment**
2. Passes it into the container as environment variable
3. Available inside container as `$ANTHROPIC_API_KEY`

### **Sources for localEnv**
VSCode looks for environment variables in this order:
1. **Host shell environment** (where you run `code .`)
2. **Host `.env` files** (in project directory)
3. **Host system environment**

## 🔧 **Recommended Setup**

### **Option 1: .env file (Recommended)**
```bash
# In ~/workspaces/coding-agent/.env on HOST
ANTHROPIC_API_KEY=sk-your-claude-key
GOOGLE_API_KEY=your-gemini-key
```

VSCode automatically loads `.env` files in the workspace root.

### **Option 2: Shell environment**
```bash
# In your shell before running code .
export ANTHROPIC_API_KEY=sk-your-claude-key
export GOOGLE_API_KEY=your-gemini-key
code .
```

### **Option 3: System environment**
```bash
# In ~/.bashrc or ~/.zshrc
export ANTHROPIC_API_KEY=sk-your-claude-key
export GOOGLE_API_KEY=your-gemini-key
```

## 🎯 **USER_NAME and USER_EMAIL**

### **Do we need them?**
**Not really!** The postCreateCommand.sh now handles this intelligently:

```bash
# If USER_NAME/USER_EMAIL are set, use them
if [ -n "$USER_NAME" ] && [ -n "$USER_EMAIL" ]; then
    git config --global user.name "$USER_NAME"
    git config --global user.email "$USER_EMAIL"
fi
# Otherwise, git config from host .gitconfig mount is used
```

### **Best Practice**
**Skip USER_NAME/USER_EMAIL** in .env - let git credentials come from host `.gitconfig` mount:
```json
// This mount provides your git identity automatically
"source=${localEnv:HOME}/.gitconfig,target=/home/user/.gitconfig,type=bind"
```

## 📁 **Simplified .env Template**
```bash
# Essential API keys only
ANTHROPIC_API_KEY=your-claude-api-key
GOOGLE_API_KEY=your-gemini-api-key

# Optional telemetry
OTLP_ENDPOINT=https://api.honeycomb.io
HONEYCOMB_API_KEY=your-honeycomb-api-key

# Skip these - git config mounted from host instead:
# USER_NAME=...
# USER_EMAIL=...
```

## 🔍 **Testing Environment Setup**

Inside the container:
```bash
# Check what got passed through
env | grep -E "(ANTHROPIC|GOOGLE|USER_)"

# Check git config (should come from host mount)
git config --list

# Check Claude config directory
echo $CLAUDE_CONFIG_DIR
# Should show: /home/user/.claude
```

## 🎯 **Result**

**Clean setup:**
- ✅ API keys from host `.env` file
- ✅ Git credentials from host `.gitconfig` mount  
- ✅ Claude config directory fixed for persistence
- ✅ Automatic tool authentication checking
- ✅ Permission fixes for mounted volumes

**Less configuration required, more automatic!**