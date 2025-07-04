# MCP Servers

This directory contains the MCP (Model Context Protocol) servers that provide tools for agent communication and coordination.

## Servers

### `mcp_mail.py`
Simple JSON file-based mail system for inter-agent communication.

**Tools provided:**
- `mcp__mail_send` - Send messages between agents
- `mcp__mail_inbox` - Check incoming messages  
- `mcp__mail_read` - Read and mark messages as read
- `mcp__mail_delete` - Delete messages

### `mcp_processes.py`
Background process management for agents.

**Tools provided:**
- `mcp__process_start` - Start background processes
- `mcp__process_list` - List running processes
- `mcp__process_logs` - View process logs
- `mcp__process_stop` - Stop processes
- `mcp__process_restart` - Restart processes

## Configuration

These servers are automatically started by claude when configured in `.mcp.json`:

```json
{
  "mcpServers": {
    "mail": {
      "command": "python3",
      "args": ["/workspaces/scripts/mcp-servers/mcp_mail.py"]
    },
    "processes": {
      "command": "python3",
      "args": ["/workspaces/scripts/mcp-servers/mcp_processes.py"]
    }
  }
}
```

## Usage

Agents automatically get access to these tools when started with the proper `.mcp.json` configuration. No manual server startup required - claude handles this automatically.

## Storage

- **Mail**: Stored in `/workspaces/.mail/` as JSON files
- **Processes**: Metadata in `/workspaces/.processes/`, logs in `/workspaces/.processes/logs/`

## Development

To test or modify these servers:

1. Make your changes to the Python files
2. Test with: `python3 mcp_mail.py` or `python3 mcp_processes.py`
3. Update documentation if adding new tools
4. Restart any running agents to pick up changes