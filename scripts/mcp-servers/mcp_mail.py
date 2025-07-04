#!/usr/bin/env python3
"""
Mail system MCP server for agent communication.
Simple JSON file-based mail exchange.
"""

import json
import uuid
import os
from datetime import datetime
from typing import List, Dict, Optional
from pathlib import Path

from fastmcp import FastMCP

# Configuration
MAIL_DIR = Path("/workspaces/.mail")
MAIL_DIR.mkdir(exist_ok=True)

# Create MCP server
mcp = FastMCP("Agent Mail System")


def get_message_path(message_id: str) -> Path:
    """Get the file path for a message."""
    return MAIL_DIR / f"msg_{message_id}.json"


def generate_message_id() -> str:
    """Generate a unique message ID."""
    return str(uuid.uuid4())


def save_message(message: Dict) -> None:
    """Save a message to disk."""
    message_path = get_message_path(message["id"])
    with open(message_path, "w") as f:
        json.dump(message, f, indent=2)


def load_message(message_id: str) -> Optional[Dict]:
    """Load a message from disk."""
    message_path = get_message_path(message_id)
    if not message_path.exists():
        return None

    try:
        with open(message_path, "r") as f:
            return json.load(f)
    except (json.JSONDecodeError, IOError):
        return None


def list_messages() -> List[Dict]:
    """List all messages in the mail directory."""
    messages = []
    for file_path in MAIL_DIR.glob("msg_*.json"):
        try:
            with open(file_path, "r") as f:
                message = json.load(f)
                messages.append(message)
        except (json.JSONDecodeError, IOError):
            # Skip corrupted files
            continue

    # Sort by timestamp (newest first)
    messages.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
    return messages


@mcp.tool()
def mcp__mail_send(from_agent: str, to_agents: List[str], subject: str, body: str) -> str:
    """
    Send mail to one or more agents.

    Args:
        from_agent: Name of the sending agent
        to_agents: List of recipient agent names
        subject: Email subject
        body: Email body content

    Returns:
        Message ID of the sent message
    """
    message_id = generate_message_id()
    timestamp = datetime.utcnow().isoformat() + "Z"

    message = {
        "id": message_id,
        "from": from_agent,
        "to": to_agents,
        "subject": subject,
        "body": body,
        "timestamp": timestamp,
        "read": False,
    }

    save_message(message)
    return message_id


@mcp.tool()
def mcp__mail_inbox(to_agent: str) -> List[Dict]:
    """
    Get inbox summary for an agent.

    Args:
        to_agent: Name of the agent to get inbox for

    Returns:
        List of message summaries (without body content)
    """
    all_messages = list_messages()
    inbox = []

    for message in all_messages:
        if to_agent in message.get("to", []):
            # Return summary without body for performance
            summary = {
                "id": message["id"],
                "from": message["from"],
                "subject": message["subject"],
                "timestamp": message["timestamp"],
                "read": message.get("read", False),
            }
            inbox.append(summary)

    return inbox


@mcp.tool()
def mcp__mail_read(message_id: str) -> Dict:
    """
    Read full message and mark as read.

    Args:
        message_id: ID of the message to read

    Returns:
        Complete message content
    """
    message = load_message(message_id)
    if not message:
        return {"error": f"Message {message_id} not found"}

    # Mark as read
    message["read"] = True
    save_message(message)

    return message


@mcp.tool()
def mcp__mail_delete(message_id: str) -> bool:
    """
    Delete a message.

    Args:
        message_id: ID of the message to delete

    Returns:
        True if deleted successfully, False otherwise
    """
    message_path = get_message_path(message_id)
    if not message_path.exists():
        return False

    try:
        message_path.unlink()
        return True
    except OSError:
        return False


@mcp.tool()
def mcp__mail_list_all() -> List[Dict]:
    """
    List all messages in the system (for debugging).

    Returns:
        List of all messages with summaries
    """
    messages = list_messages()
    summaries = []

    for message in messages:
        summary = {
            "id": message["id"],
            "from": message["from"],
            "to": message["to"],
            "subject": message["subject"],
            "timestamp": message["timestamp"],
            "read": message.get("read", False),
        }
        summaries.append(summary)

    return summaries


if __name__ == "__main__":
    # Create README if it doesn't exist
    readme_path = MAIL_DIR / "README.md"
    if not readme_path.exists():
        with open(readme_path, "w") as f:
            f.write("""# Agent Mail System

This directory contains JSON files for agent communication.

## Structure
- `msg_<uuid>.json` - Individual mail messages
- `README.md` - This file

## Message Format
```json
{
  "id": "msg_<uuid4>",
  "from": "agent-name",
  "to": ["recipient1", "recipient2"],
  "subject": "Task update",
  "body": "Message content here",
  "timestamp": "2024-07-03T10:30:00Z",
  "read": false
}
```

## Usage
Messages are managed through the MCP mail server tools:
- `mcp__mail_send` - Send a message
- `mcp__mail_inbox` - Get inbox for an agent
- `mcp__mail_read` - Read and mark message as read
- `mcp__mail_delete` - Delete a message
""")

    mcp.run()
