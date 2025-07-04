# Troubleshooting Guide

Common issues and their solutions.

## Container Issues

### Container won't start

**Symptoms**: `docker-compose up` fails or container exits immediately.

**Solutions**:
```bash
# Check Docker is running
docker version

# Check ports aren't in use
lsof -i :5000

# Check disk space
df -h

# View detailed error
docker-compose logs

# Verify compose file
docker-compose config
```

### Can't enter container

**Symptoms**: `docker-compose exec` fails.

**Solutions**:
```bash
# Check container is running
docker-compose ps

# Use correct service name
docker-compose exec coding-agent bash  # Not "coding_agent" 

# If still failing, restart
docker-compose restart
```

## Agent Issues

### Agent won't start

**Symptoms**: Claude/Gemini command fails.

**Check**:
```bash
# Verify API key
echo $ANTHROPIC_API_KEY
echo $GOOGLE_API_KEY

# Check you're in agent directory
pwd  # Should be /workspaces/agent-name

# Verify files exist
ls -la prompt.md .env

# Source environment
source .env
```

### Agent seems stuck

**Symptoms**: No output, no progress.

**Debug steps**:
1. Check if agent is waiting for input
2. Look for errors in terminal
3. Check mail for error messages:
   ```bash
   ls -lt /workspaces/.mail/*.json | head -5
   ```
4. Verify resources (disk, memory)
5. Check git status in worktree

### Agent can't send mail

**Symptoms**: Mail operations fail.

**Check**:
```bash
# Mail directory exists and writable
ls -la /workspaces/.mail/

# Test mail system directly
python3 -c "
from scripts.mcp_servers.mcp_mail import mail_send
mail_send('test', ['test'], 'Test', 'Body')
"

# Check for file permission issues
touch /workspaces/.mail/test.json
rm /workspaces/.mail/test.json
```

## Git Issues

### Worktree creation fails

**Symptoms**: `setup-agent.sh` fails to create worktree.

**Solutions**:
```bash
# Check main repo exists
ls -la /workspaces/main/.git

# Clean up broken worktrees
cd /workspaces/main
git worktree prune

# List existing worktrees
git worktree list

# Manual cleanup if needed
rm -rf /workspaces/broken-agent
git worktree prune
```

### Merge conflicts

**Symptoms**: Can't merge agent branches.

**Solutions**:
```bash
# Update main branch first
cd /workspaces/main
git pull origin main

# Try automatic merge
git merge agent-branch

# If conflicts, resolve manually
git status  # See conflicted files
# Edit files to resolve
git add .
git commit
```

## Resource Issues

### Port conflicts

**Symptoms**: "Address already in use" errors.

**Check**:
```bash
# Find what's using a port
lsof -i :3000
netstat -tlnp | grep 3000

# Check agent port allocations
grep MAIN_PORT /workspaces/*/.env

# Kill process using port
kill $(lsof -t -i :3000)
```

### Disk space issues

**Symptoms**: Operations fail with "No space left on device".

**Solutions**:
```bash
# Check disk usage
df -h /workspaces

# Find large files
du -sh /workspaces/* | sort -h

# Clean up old worktrees
cd /workspaces/main
git worktree list
git worktree remove ../old-agent

# Clear mail backlog
rm /workspaces/.mail/msg_*.json  # BE CAREFUL
```

### Memory issues

**Symptoms**: Container or agents crash, system slow.

**Check**:
```bash
# Inside container
free -h
ps aux --sort=-%mem | head

# From host
docker stats

# Reduce concurrent agents
# Increase Docker memory limit
```

## Mail System Issues

### Messages not delivered

**Check**:
```bash
# Message files created
ls -la /workspaces/.mail/

# File permissions
ls -ld /workspaces/.mail/

# Disk space
df -h /workspaces

# Test write
echo '{}' > /workspaces/.mail/test.json
rm /workspaces/.mail/test.json
```

### Can't read messages

**Solutions**:
```bash
# Check message format
cat /workspaces/.mail/msg_*.json | jq .

# Find corrupted messages
for f in /workspaces/.mail/*.json; do
  jq . "$f" > /dev/null 2>&1 || echo "Bad: $f"
done

# Remove corrupted files
rm /workspaces/.mail/corrupted.json
```

## Performance Issues

### Slow agent responses

**Check**:
1. API rate limits (check provider dashboard)
2. Container resources (CPU, memory)
3. Disk I/O (many agents writing)
4. Network latency to API
5. Complex prompts causing timeouts

**Solutions**:
- Reduce concurrent agents
- Increase container resources
- Simplify agent tasks
- Add retries for API calls

### High API costs

**Monitor**:
```bash
# Track token usage in prompts
# Shorter, focused prompts
# Avoid repeated context
# Use appropriate models
```

## Debug Commands

### System state
```bash
# Container health
docker-compose ps
docker-compose logs --tail=50

# Inside container
ps aux | grep -E "(claude|gemini|python)"
df -h
free -h
```

### Agent state
```bash
# List all worktrees
find /workspaces -name ".agent-id" -type f

# Check specific agent
cd /workspaces/agent-name
git status
git log --oneline -10
cat .env
```

### Mail state
```bash
# Message count
ls /workspaces/.mail/*.json 2>/dev/null | wc -l

# Recent messages
ls -lt /workspaces/.mail/*.json | head -10

# Messages by agent
grep -l '"from":"agent-name"' /workspaces/.mail/*.json
```

## Recovery Procedures

### Reset agent
```bash
cd /workspaces/agent-name
git reset --hard
git clean -fd
source .env
# Re-run agent
```

### Clean restart
```bash
# Outside container
docker-compose down
docker-compose up -d
docker-compose exec coding-agent bash
```

### Emergency cleanup
```bash
# Remove all messages (CAREFUL)
rm /workspaces/.mail/*.json

# Remove all worktrees except main
cd /workspaces/main
git worktree list | grep -v main | awk '{print $1}' | xargs -I {} git worktree remove {}
```

## Getting More Help

1. Check agent terminal output
2. Review recent git commits
3. Examine mail messages
4. Check system logs
5. Review architecture documentation

Most issues are related to:
- Missing configuration
- Resource exhaustion  
- Git state problems
- API key issues

Start with the simplest explanation first.