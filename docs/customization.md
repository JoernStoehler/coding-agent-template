# Customizing for Your Project

This template is designed to be adapted. Here's how to customize it for your specific needs.

## Key Customization Points

### 1. CLAUDE.md - Agent Context

Create a `CLAUDE.md` file in your main project to provide context for all agents:

```markdown
# CLAUDE.md - Project Context for AI Agents

## Project Overview
[Your project description]

## Architecture
- Key components
- Technology stack
- Important patterns

## Conventions
- Naming standards
- Code style
- Testing approach

## Common Tasks
- How to add features
- How to fix bugs
- How to run tests

## Important Files
- `src/core/` - Core business logic
- `tests/` - Test suite
- `docs/` - Documentation
```

This file is the primary way to give agents project-specific knowledge.

## 2. Agent Prompts

Customize the prompt template in `scripts/setup-agent.sh`:

```bash
# Current generic prompt
cat > prompt.md << EOF
# Agent Task: $WORKTREE_NAME
...
EOF

# Customize for your domain
cat > prompt.md << EOF
# Agent Task: $WORKTREE_NAME

## Project Context
- E-commerce platform using Django
- Follow PEP-8 and our style guide
- All features need unit tests

## Your Task
$TASK_DESCRIPTION

## Success Criteria
- Tests pass (run: pytest)
- Linting passes (run: make lint)
- Documentation updated
EOF
```

## 3. Development Scripts

Add project-specific scripts to help agents:

```bash
# scripts/run-tests.sh
#!/bin/bash
cd /workspaces/main
python -m pytest tests/ -v

# scripts/lint-code.sh  
#!/bin/bash
cd /workspaces/main
black . && isort . && flake8
```

Reference these in your CLAUDE.md so agents know they exist.

## 4. Docker Environment

Modify the Dockerfile for your tech stack:

```dockerfile
# For a Python/Django project
RUN apt-get update && apt-get install -y \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*

RUN pip install django pytest black isort flake8

# For a Node/React project  
RUN npm install -g typescript eslint prettier jest
```

## 5. Environment Variables

Add project-specific configuration to `.env.template`:

```bash
# Project-specific
DATABASE_URL=postgresql://localhost/myapp
REDIS_URL=redis://localhost:6379
API_BASE_URL=http://localhost:8000
DEBUG=true
```

## 6. Git Configuration

Set up project conventions:

```bash
# .gitmessage template
feat: <description>

Why:
- 

What:
- 

# Configure in container
git config commit.template .gitmessage
```

## 7. MCP Extensions

Add domain-specific MCP tools if needed:

```python
# scripts/mcp-servers/mcp_database.py
@server.tool()
async def db_query(sql: str) -> list:
    """Run read-only database query"""
    # Implementation

@server.tool()  
async def db_migrate() -> str:
    """Run database migrations"""
    # Implementation
```

## When to Fork vs Configure

**Just Configure** when:
- Using standard tech stack (Python, Node, etc.)
- Default tools are sufficient
- Minor workflow adjustments needed

**Fork the Template** when:
- Drastically different tech stack
- Need specialized MCP tools
- Want to maintain your own version

## Project Types

### Web Application
- Add database tools
- Include API testing utilities
- Set up hot reloading

### CLI Tool
- Focus on argument parsing
- Add integration test helpers
- Include packaging scripts

### Library
- Emphasize documentation
- Add publishing workflows
- Include compatibility testing

### Data Science
- Add Jupyter support
- Include data validation tools
- Set up experiment tracking

## Best Practices

1. **Start minimal**: Add customizations as needs emerge
2. **Document changes**: Update CLAUDE.md when adding tools
3. **Test with agents**: Verify agents can use your customizations
4. **Share patterns**: If something works well, document it
5. **Keep it simple**: Resist over-engineering

## Example Customization Flow

1. Clone template
2. Add your main project
3. Create CLAUDE.md with project context
4. Run a test agent to identify gaps
5. Add missing tools/scripts
6. Update CLAUDE.md with new capabilities
7. Iterate based on agent feedback

The goal is to give agents enough context to work effectively without overwhelming them with information.