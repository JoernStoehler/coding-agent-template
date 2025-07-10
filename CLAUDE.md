# CLAUDE.md - AI Agent Context Hub

This file serves as the central navigation hub for AI agents working on this project. It provides essential context, links to detailed documentation, and guidelines for effective collaboration.

## Project Overview

This is a template repository for AI-powered coding agent projects. It provides:
- Telemetry and observability setup for tracking agent performance
- Agent-optimized file structure and documentation
- Modern development tooling (linting, type checking, testing)
- Environment-based configuration management

## Quick Navigation

### Essential Documentation
- **Setup Guide**: @docs/setup.md - Installation and configuration
- **Agent Management**: @docs/agents.md - Creating and managing agents
- **Architecture**: @docs/architecture.md - System design and decisions
- **Available Tools**: @docs/tools.md - Commands and MCP servers
- **Troubleshooting**: @docs/troubleshooting.md - Common issues and solutions

### Quick Links
- **Code Conventions**: @docs/conventions.md - Style and standards
- **Customization**: @docs/customization.md - Adapting for your project
- **Single Agent Example**: @docs/examples/single-agent-task.md
- **Multi-Agent Example**: @docs/examples/multi-agent-workflow.md
- **Debugging Guide**: @docs/examples/debugging-session.md

## Development Guidelines

### 1. File Naming Conventions
- Use descriptive names that indicate purpose: `user_authentication_service.py` not `auth.py`
- Group related files in clearly named directories
- Prefer flat structure over deep nesting for discoverability

### 2. Code Organization
- One class/major function per file when reasonable
- Clear module boundaries with explicit exports
- Related files should reference each other in docstrings

### 3. Documentation Standards
- Every file should have a docstring explaining its purpose
- Include "Related files:" section for cross-references
- Use type hints throughout
- Document recent changes with dates

### 4. Testing Requirements
- Write tests alongside implementation
- Run relevant tests before marking tasks complete
- Use `pytest` for all Python testing
- Maintain >80% code coverage

### 5. Performance Considerations
- Be mindful of token usage in prompts and responses
- Use batch operations where possible
- Cache expensive computations
- Profile and optimize hot paths

## Environment Setup

1. Copy `.env.example` to `.env` and configure:
   ```bash
   cp .env.example .env
   # Edit .env with your values
   ```

2. Telemetry collector is managed by supervisor (starts automatically if configured):
   ```bash
   # Check status
   sudo supervisorctl status telemetry
   
   # View logs
   sudo supervisorctl tail telemetry
   
   # Restart if needed
   sudo supervisorctl restart telemetry
   ```

3. Install dependencies:
   ```bash
   pip install -r requirements.txt
   pip install -r requirements-dev.txt
   ```

## Common Tasks

### Running Tests
```bash
pytest tests/ -v --cov=src --cov-report=html
```

### Linting and Formatting
```bash
ruff check .
ruff format .
mypy src/
```

### Starting Development Server
```bash
python src/main.py
```

## Telemetry and Observability

This project includes comprehensive telemetry for tracking:
- API token usage and costs
- Tool call patterns and performance
- Error rates and retry attempts
- Task completion times

Access telemetry data through your Honeycomb dashboard after configuring `HONEYCOMB_API_KEY` in `.env`.

## Architecture Decisions

### Why Environment-Based Config?
- Easy deployment across environments
- No hardcoded secrets
- Clear configuration validation
- Type-safe access patterns

### Why File-Based Architecture?
- Simple and debuggable
- Version control friendly
- No database complexity for small datasets
- Easy backup and restore

### Why Comprehensive Telemetry?
- Understand agent behavior and costs
- Identify optimization opportunities
- Track performance over time
- Debug issues with full context

## Anti-Patterns to Avoid

1. **Don't hardcode configuration** - Use environment variables
2. **Don't skip tests** - Always verify your changes
3. **Don't ignore telemetry** - Monitor costs and performance
4. **Don't create deep nesting** - Keep file structure discoverable
5. **Don't use vague names** - Be descriptive and specific

## Getting Help

- Check existing documentation in `docs/`
- Review similar implementations in the codebase
- Look for patterns in `.claude/commands/`
- Search for TODO/FIXME comments for known issues

## Recent Updates

- 2025-01-04: Initial template creation with telemetry setup
- 2025-01-04: Added environment-based configuration system
- 2025-01-04: Created CLAUDE.md as central navigation hub
- 2025-01-04: Major documentation reorganization into purpose-driven structure
- 2025-07-10: Migrated from nohup to supervisor for background service management

Remember: This file should be kept up-to-date as the project evolves. When making significant changes, update relevant sections here.