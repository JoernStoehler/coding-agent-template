# Agent Onboarding Guide

This guide explains how AI agents should approach working in this infrastructure.

## Understanding Your Environment

### Your Working Directory
- **Worktree Path**: Found in `$WORKTREE_PATH` environment variable
- **Branch**: Your dedicated git branch (in `$BRANCH_NAME`)
- **Ports**: Allocated port range (see `$MAIN_PORT`, `$API_PORT`, `$DEBUG_PORT`)
- **Task**: Your specific assignment (in `$TASK_DESCRIPTION`)

### Key Files in Your Worktree
- `.env` - Your resource allocation and configuration
- `prompt.md` - Your detailed task instructions
- `tmp/` - Use this for temporary files
- `logs/` - Use this for log files
- `.gitignore` - Prevents agent-specific files from being committed

## Common Workflow Patterns

### 1. Starting a New Task

```bash
# Always source your environment first
source .env

# Review your task
cat prompt.md

# Check your git status
git status
git log --oneline -5

# Plan your work
echo "Planning phase..." | tee logs/planning.log
```

### 2. Development Cycle

```bash
# Make changes
# Edit files, create new ones as needed

# Test frequently
# Run your code, check for errors

# Commit frequently with conventional commits
git add .
git commit -m "feat: implement user authentication"

# Document your progress
echo "Completed authentication module" >> logs/progress.log
```

### 3. Communication with Other Agents

```python
# Send a message to the central planner
mcp__mail_send(
    from_agent=os.getenv("AGENT_NAME"),
    to_agents=["central-planner"],
    subject="Task progress update",
    body="Authentication module completed. Starting on dashboard UI."
)

# Check for incoming messages
inbox = mcp__mail_inbox(to_agent=os.getenv("AGENT_NAME"))
for message in inbox:
    if not message["read"]:
        full_message = mcp__mail_read(message["id"])
        # Process the message
```

### 4. Managing Background Processes

```python
# Start a development server
process_id = mcp__process_start(
    command=f"python app.py --port={os.getenv('MAIN_PORT')}",
    cwd=os.getenv("WORKTREE_PATH"),
    name="dev-server",
    owner=os.getenv("AGENT_NAME")
)

# Check if it's running
processes = mcp__process_list(owner=os.getenv("AGENT_NAME"))
print(f"Running processes: {len(processes)}")

# View logs
logs = mcp__process_logs(process_id, lines=20)
print(logs)
```

## Best Practices

### Code Organization
- Follow existing project conventions
- Use descriptive file and directory names
- Keep files focused and single-purpose
- Comment complex logic clearly

### Git Workflow
- Make small, focused commits
- Use conventional commit messages:
  - `feat: add new feature`
  - `fix: resolve bug in authentication`
  - `docs: update API documentation`
  - `chore: update dependencies`
- Push frequently to avoid conflicts

### Communication
- Send status updates to central-planner
- Ask for help when blocked
- Notify of completion with summary
- Be specific about what you need

### Resource Management
- Use your allocated ports only
- Keep temporary files in `tmp/`
- Clean up resources when done
- Monitor your background processes

## Common Patterns

### Frontend Development
```bash
# Set up development environment
cd $WORKTREE_PATH
npm install
npm run dev -- --port=$MAIN_PORT

# Run in background
mcp__process_start(
    command="npm run dev -- --port=$MAIN_PORT",
    cwd=os.getenv("WORKTREE_PATH"),
    name="frontend-dev",
    owner=os.getenv("AGENT_NAME")
)
```

### Backend API Development
```bash
# Start API server
source .env
python -m uvicorn app:app --host 0.0.0.0 --port $API_PORT --reload

# Or as background process
mcp__process_start(
    command=f"python -m uvicorn app:app --host 0.0.0.0 --port {os.getenv('API_PORT')} --reload",
    cwd=os.getenv("WORKTREE_PATH"),
    name="api-server",
    owner=os.getenv("AGENT_NAME")
)
```

### Database Setup
```bash
# Use your allocated ports for database
export DB_PORT=$((API_PORT + 1))
docker run -d --name ${AGENT_NAME}-db -p $DB_PORT:5432 postgres:13
```

## Error Handling

### Common Issues

1. **Port Already in Use**
   ```bash
   # Check what's using your port
   lsof -i :$MAIN_PORT
   
   # Kill the process or use a different port
   export MAIN_PORT=$((MAIN_PORT + 1))
   ```

2. **Git Conflicts**
   ```bash
   # Check for conflicts
   git status
   
   # If you have conflicts, ask for help
   mcp__mail_send(
       from_agent=os.getenv("AGENT_NAME"),
       to_agents=["central-planner"],
       subject="Merge conflict help needed",
       body="I have conflicts in: [list files]"
   )
   ```

3. **Process Management Issues**
   ```python
   # List all your processes
   processes = mcp__process_list(owner=os.getenv("AGENT_NAME"))
   
   # Stop a problematic process
   mcp__process_stop(process_id)
   ```

### Getting Help

1. **Send mail to central-planner** with specific details
2. **Check logs** in your `logs/` directory
3. **Review task requirements** in `prompt.md`
4. **Check environment** with `env | grep -E "(AGENT_|PORT_|TASK_)"`

## Task Completion

### Before Marking Complete

- [ ] All requirements met (check `prompt.md`)
- [ ] Code tested and working
- [ ] All changes committed
- [ ] Documentation updated if needed
- [ ] Background processes stopped or documented
- [ ] Temporary files cleaned up

### Completion Message

```python
mcp__mail_send(
    from_agent=os.getenv("AGENT_NAME"),
    to_agents=["central-planner"],
    subject="Task completed: [task name]",
    body="""
    Task completed successfully!
    
    Summary:
    - [What was accomplished]
    - [Key files created/modified]
    - [Tests passing/features working]
    - [Any notes or considerations]
    
    Ready for review and merge.
    """
)
```

## Advanced Topics

### Multi-Agent Coordination
- Use mail system for coordination
- Avoid direct file system coupling
- Design clear interfaces between components
- Document shared conventions

### Performance Optimization
- Monitor resource usage
- Use background processes efficiently
- Clean up when done
- Profile code when needed

### Security Considerations
- Don't commit secrets
- Use environment variables for sensitive data
- Validate inputs and outputs
- Follow security best practices

## Troubleshooting Guide

### Environment Issues
```bash
# Check your environment
source .env
env | grep -E "(AGENT_|PORT_|TASK_)"

# Verify paths
ls -la $WORKTREE_PATH
pwd
```

### Communication Issues
```bash
# Check mail directory
ls -la /workspaces/.mail/

# Test mail system
python3 -c "
import sys
sys.path.append('/workspaces')
from mcp_mail import mcp__mail_send
print(mcp__mail_send('test', ['central-planner'], 'Test', 'Hello'))
"
```

### Process Issues
```bash
# Check your processes
ps aux | grep $AGENT_NAME

# Check process manager
ls -la /workspaces/.processes/
```

Remember: This infrastructure is designed to be simple and transparent. When in doubt, examine the files, check the logs, and ask for help!