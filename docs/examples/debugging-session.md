# Example: Debugging Session

This example shows how to debug a stuck or failing agent.

## Scenario

An agent was created to fix a bug but seems stuck after 30 minutes with no commits.

## Step 1: Check Agent Status

```bash
# List active agents
./scripts/list-agents.sh

# Output:
# fix-login-bug (RUNNING) - Last commit: never
# api-refactor (IDLE) - Last commit: 2 hours ago
```

## Step 2: Check Terminal Output

Look at the VSCode terminal where the agent was started:

```
[Expected output]
Reading prompt.md...
Analyzing codebase...
Found login handler at src/auth/login.py
Running tests...

[Actual output - stuck here]
Reading prompt.md...
Analyzing codebase...
```

## Step 3: Check Mail System

```bash
# Any messages from agent?
grep -l '"from":"fix-login-bug"' /workspaces/.mail/*.json

# Any messages TO agent?
grep -l '"to":.*"fix-login-bug"' /workspaces/.mail/*.json

# Read recent messages
ls -lt /workspaces/.mail/*.json | head -5 | while read f; do
  echo "=== $f ==="
  cat "$f" | jq '{from, to, subject, timestamp}'
done
```

## Step 4: Investigate Worktree

```bash
cd /workspaces/fix-login-bug

# Check git status
git status

# Output might show:
# - No changes (agent hasn't started work)
# - Uncommitted changes (agent working but not committing)
# - Merge conflicts (integration issue)

# Check if agent created any files
find . -newer prompt.md -type f

# Check logs directory
ls -la logs/
tail -f logs/*.log 2>/dev/null
```

## Step 5: Common Issues and Solutions

### Issue: API Key Problems

**Symptoms**: Agent starts but makes no progress.

**Check**:
```bash
cd /workspaces/fix-login-bug
source .env
echo $ANTHROPIC_API_KEY | cut -c1-10  # Should show first 10 chars
```

**Fix**:
```bash
# Update .env with correct key
vim .env
# Restart agent
```

### Issue: Git Conflicts

**Symptoms**: Agent can't create worktree or commit.

**Check**:
```bash
cd /workspaces/main
git worktree list
git status
```

**Fix**:
```bash
# Clean up broken worktree
git worktree remove --force ../fix-login-bug
rm -rf /workspaces/fix-login-bug

# Recreate
./scripts/setup-agent.sh fix-login-bug "Original task description"
```

### Issue: Unclear Instructions

**Symptoms**: Agent asks questions or works on wrong thing.

**Debug**:
```bash
cd /workspaces/fix-login-bug
cat prompt.md

# Look for:
# - Vague descriptions
# - Missing context
# - Ambiguous requirements
```

**Fix**: Update prompt with specifics:
```bash
cat >> prompt.md << 'EOF'

## Clarification

The bug specifically occurs when:
1. User enters email without @ symbol
2. System returns 500 error instead of validation error

The fix should:
1. Add email validation before database query
2. Return 400 Bad Request with clear message
3. Add test case for this scenario

File to modify: src/auth/login.py line 45-60
EOF

# Restart agent with updated prompt
```

### Issue: Resource Problems

**Symptoms**: Agent crashes or system slow.

**Check**:
```bash
# Disk space
df -h /workspaces

# Memory
free -h

# Processes
ps aux | sort -k 3 -r | head -10  # Top CPU
ps aux | sort -k 4 -r | head -10  # Top memory

# Port conflicts
netstat -tlnp | grep 3000
```

**Fix**:
```bash
# Free disk space
find /workspaces -name "*.log" -size +100M -delete
docker system prune -f

# Kill stuck processes
pkill -f "claude.*fix-login-bug"

# Stop other agents temporarily
```

### Issue: Missing Dependencies

**Symptoms**: Import errors, module not found.

**Debug**:
```bash
# Check if agent tried to install packages
grep -i "pip install" /workspaces/fix-login-bug/.bash_history

# Try running the code
cd /workspaces/fix-login-bug
python src/auth/login.py
```

**Fix**:
```bash
# Install missing packages
pip install -r requirements.txt

# Or tell agent explicitly
cat >> prompt.md << 'EOF'

## Note: Dependencies already installed
The following are available:
- flask
- pytest  
- requests

Do not run pip install.
EOF
```

## Step 6: Advanced Debugging

### Trace Agent Actions

```bash
# Monitor file changes
cd /workspaces/fix-login-bug
watch -n 2 'find . -type f -newer prompt.md -ls'

# Monitor git activity
watch -n 2 'git status --short'

# Monitor processes
watch -n 2 'ps aux | grep -E "(claude|python|node)" | grep -v grep'
```

### Check System Health

```bash
# Run health check
./health/check_system.sh

# Check Docker
docker-compose ps
docker-compose logs --tail=50

# Inside container resources
docker stats --no-stream
```

### Manual Intervention

Sometimes you need to help the agent:

```bash
cd /workspaces/fix-login-bug

# Fix obvious syntax error blocking agent
vim src/auth/login.py  # Fix syntax

# Stage fixes
git add -A
git commit -m "fix: syntax error blocking agent"

# Agent can now continue
```

## Step 7: Recovery Strategies

### Restart Agent

```bash
# Clean restart
cd /workspaces/fix-login-bug
git reset --hard
rm -rf tmp/* logs/*
source .env
claude --dangerously-skip-permissions "@prompt.md"
```

### Split Task

If task is too complex:
```bash
# Create simpler subtask
./scripts/setup-agent.sh fix-validation "Just add email validation"

# After completion, create follow-up
./scripts/setup-agent.sh fix-error-handling "Improve error responses"
```

### Pair Debugging

Create a debugging agent:
```bash
./scripts/setup-agent.sh debug-helper "Help debug fix-login-bug agent's work"

# In prompt, include:
# - Original task
# - What agent accomplished
# - Where it got stuck
# - Error messages
```

## Prevention Tips

1. **Clear prompts**: Include specific examples
2. **Verify setup**: Check environment before starting
3. **Monitor early**: Don't wait 30 minutes
4. **Set boundaries**: Tell agent what NOT to do
5. **Provide context**: Include file paths, line numbers

## Debug Checklist

- [ ] Check terminal output
- [ ] Review mail messages
- [ ] Inspect git status
- [ ] Verify environment variables
- [ ] Check resource availability
- [ ] Review prompt clarity
- [ ] Test code manually
- [ ] Look for error logs

Most agent issues fall into:
- Unclear instructions (50%)
- Environment problems (30%)
- Resource constraints (15%)
- Actual bugs (5%)

Start debugging with the most likely cause.