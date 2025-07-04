# Coding Agent Infrastructure Documentation

This infrastructure helps you orchestrate AI coding agents that work collaboratively on software projects using Docker containers, git worktrees, and MCP servers.

## Quick Navigation

**Getting Started:**
- [Setup](setup.md) - Install and run the infrastructure
- [Agents](agents.md) - Create and manage AI agents
- [Examples](examples/) - Complete walkthroughs

**Customization:**
- [Customization](customization.md) - Adapt for your project
- [Conventions](conventions.md) - Code style and standards

**Reference:**
- [Tools](tools.md) - Available commands and MCP servers
- [Architecture](architecture.md) - System design and decisions
- [Troubleshooting](troubleshooting.md) - Common issues and solutions

## What This Is

A template repository providing:
- Docker environment for running AI agents
- Git worktree isolation for parallel work
- Mail system for agent communication
- Scripts for agent lifecycle management

## Key Concepts

- **Agents**: AI assistants (Claude/Gemini) working in isolated environments
- **Worktrees**: Separate git branches for each agent's work
- **MCP Servers**: Tools that agents can use (mail, process management)
- **Shared Container**: All agents run in one Docker container (YAGNI design)

## Getting Help

1. Check [Troubleshooting](troubleshooting.md) for common issues
2. Review [Architecture](architecture.md) to understand the system
3. See [Examples](examples/) for complete scenarios