# Tool-Specific Guide for AI Agents

This document provides detailed, tool-specific guidance for working with current AI agent implementations like Claude (via claude-code CLI) and Gemini. This information is version-specific and will change as tools evolve.

For fundamental cognitive theory, see [Theory of Agents](theory-of-agents.md). For high-level practical patterns, see [Practical Usage Guide for Agents](practical-usage-guide-for-agents.md).

## Table of Contents

1. [File Loading and Context Management](#1-file-loading-and-context-management)
2. [Subagent Patterns](#2-subagent-patterns)
3. [Tool Usage Best Practices](#3-tool-usage-best-practices)
4. [Model-Specific Quirks](#4-model-specific-quirks)
5. [Format Preferences](#5-format-preferences)
6. [Performance Optimization](#6-performance-optimization)

## 1. File Loading and Context Management

### @-Notation for Auto-Loading Files

**What it is**: Files can be automatically loaded into context using `@filename` syntax.

**How it works**:
```bash
# In claude-code CLI
claude "@prompt.md @src/main.py"

# This loads both files into initial context
```

**Context auto-loading sources**:
Freshly started AI agents are provided with context from:
1. A static system prompt defined by Anthropic
2. A project-specific `CLAUDE.md` file (if present)
3. Files referenced with `@` prefix in CLAUDE.md or command line

**Important distinction**:
- `@path/to/file` - Auto-loads the file content
- `path/to/file` or `[description](path/to/file)` - Just a reference, NOT auto-loaded

**Best practices**:
- Use @-notation for files that must be in context from the start
- Combine with explicit file lists in prompts for complex tasks
- Remember that @-loaded files consume initial context space
- Put critical reference files in CLAUDE.md with @ prefix

**Limitations**:
- Only works at invocation time, not during conversation
- Relative paths are resolved from current directory
- No wildcards or glob patterns supported

### Context Window Token Counting

**Current limits** (as of 2025-01):
- Claude 3.5 Sonnet: 200k tokens
- Gemini 1.5 Pro: 1M tokens
- GPT-4: 128k tokens

**Token approximations**:
- 1 token ≈ 4 characters
- 1 token ≈ 0.75 words
- 100 lines of code ≈ 2,000-3,000 tokens

## 2. Subagent Patterns

### Task() Subagents vs Spawned Agents

**Task() Subagents** (Blocking, Read-Only):
```python
# Used for research and information gathering
result = Task(
    description="Find all API endpoints",
    prompt="Search for all REST API endpoints in the codebase and list them"
)
```

**Characteristics**:
- Blocks until complete
- Read-only access
- Returns results to parent
- Good for: research, analysis, exploration
- Context is discarded after completion

**Spawned Agents** (Independent, Full Access):
```bash
# Create independent agent with full capabilities
claude-code --new-session "@task.md"
```

**Characteristics**:
- Runs independently
- Can modify files
- No automatic result return
- Good for: implementation, refactoring
- Must coordinate via files or messages

### When to Use Each Pattern

| Use Case | Task() | Spawned Agent |
|----------|---------|---------------|
| Find information | ✓ | |
| Analyze code | ✓ | |
| Write new code | | ✓ |
| Refactor | | ✓ |
| Run tests | ✓ | ✓ |
| Complex implementation | | ✓ |

## 3. Tool Usage Best Practices

### Bash() Tool

**Best practices**:
```bash
# Good: Explicit error handling
if ! command -v node &> /dev/null; then
    echo "Node.js not installed"
    exit 1
fi

# Good: Pipe to filter output
grep "error" large.log | tail -100

# Bad: Unfiltered large output
cat massive-file.log
```

**Common pitfalls**:
- Output truncation at 30,000 characters
- No interactive commands (no `-i` flags)
- Working directory persists between calls
- Environment variables persist in session

### Read() Tool

**Performance tips**:
```python
# Good: Read with limits for large files
Read(file_path="/path/to/large/file.py", limit=100, offset=500)

# Good: Read multiple files in one action batch
files = ["config.py", "main.py", "utils.py"]
# Agent will read all in parallel

# Bad: Sequential reads
Read("file1.py")
# wait for response
Read("file2.py")
# wait for response
```

### Edit() Tool

**String matching requirements**:
- Must match exactly including whitespace
- Include enough context for uniqueness
- Use `replace_all=True` for multiple occurrences

**Common failures**:
```python
# Will fail - doesn't match indentation
Edit(
    file_path="app.py",
    old_string="def hello():",  # Missing leading spaces
    new_string="def greeting():"
)

# Will fail - string not unique
Edit(
    file_path="app.py",
    old_string="return True",  # Appears multiple times
    new_string="return False"
)
```

## 4. Model-Specific Quirks

### Claude (claude-code)

**Strengths**:
- Excellent at following multi-step instructions
- Strong code comprehension
- Good at maintaining context over long conversations

**Quirks**:
- Sometimes overly cautious about modifications
- May ask for confirmation unnecessarily
- Prefers explicit over implicit instructions

### Gemini (gemini-cli)

**Strengths**:
- Faster response times
- Better at mathematical reasoning
- Larger context window (1M tokens)

**Quirks**:
- More prone to hallucination in code details
- May be more verbose in responses
- Different prompt sensitivity

## 5. Format Preferences

### Docstring Formats

**Best format for AI agents** - Google Style:
```python
def calculate_total(items: List[Item], tax_rate: float = 0.08) -> float:
    """Calculate total price including tax.
    
    Args:
        items: List of items to price
        tax_rate: Tax rate as decimal (default: 0.08)
        
    Returns:
        Total price including tax
        
    Raises:
        ValueError: If tax_rate is negative
    """
```

**Why this works best**:
- Clear section headers agents can parse
- Explicit parameter descriptions
- Type information reinforced in docs

### Commit Message Format

**Conventional Commits work best**:
```
feat: add user authentication
fix: resolve memory leak in worker
docs: update API documentation
test: add integration tests for auth
refactor: extract validation logic
```

**Why**: Agents trained on millions of examples using this format.

### Configuration Files

**YAML with comments**:
```yaml
# Database configuration
database:
  host: localhost  # Development host
  port: 5432      # PostgreSQL default
  name: myapp_dev # Database name
  
# Feature flags
features:
  new_ui: false   # Enable with NEW_UI=true
  debug: true     # Verbose logging
```

## 6. Performance Optimization

### Reducing Context Usage

**File reading strategies**:
1. Use grep/search before reading entire files
2. Read only relevant sections with offset/limit
3. Batch related reads together
4. Use descriptive filenames to avoid unnecessary reads

### Parallel Operations

**Good pattern**:
```python
# Agent makes these calls in one batch
actions = [
    Read("config.py"),
    Read("database.py"),
    Bash("npm test"),
    Grep("TODO", path="src/")
]
```

**Bad pattern**:
```python
# Sequential calls waste time
Read("config.py")
# wait for response
Read("database.py") 
# wait for response
```

### Context Preservation

**For long tasks**:
1. Start with minimal context
2. Summarize findings periodically
3. Use external files for intermediate results
4. Clear context with fresh agent when >70% full

## Version History

- 2025-01: Initial version for Claude 3.5 and Gemini 1.5
- Tool versions: claude-code v1.x, gemini-cli v1.x

Remember: This guide covers current tool implementations. Always check tool documentation for the latest updates.