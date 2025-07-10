# Prompt and Context Engineering for AI Agents

## How to Read This Document

### If You Are an AI Agent
- You will have this entire document in your context always
- Every heading, keyword, and if-then statement creates associations for you
- The organizational structure exists for humans, not you
- References like "see §3.2" strengthen associations - the section number doesn't matter, the connection does
- When you see "Primary:" that's for human maintainers, not prioritization for you
- Empty sections with only references are intentional - they ensure completeness

### If You Are a Human Maintainer
- Information lives in ONE primary location (to update)
- References preserve the knowledge graph without duplication
- The tree structure is somewhat arbitrary - optimize for discoverability
- Empty sections with references are intentional - they document our completeness
- When adding new knowledge, put it in the most intuitive section and add references elsewhere
- False or outdated information is poisonous - always update the primary location

### Understanding the Structure
- This document uses a spanning tree organization for maintenance while preserving a knowledge graph through references
- We're organizing maintenance, not information - the full graph exists through cross-references
- The categorization is somewhat arbitrary but aims for intuitive discovery
- Associations form a small-world graph with many clusters and cycles

---

## Part I: General Theory of Prompt Engineering

### §1 How AI Context Works

#### 1.1 Context Window Mechanics
- Your context window is append-only and never truncated during a session
- Every tool call appends both the invocation and the output
- Every message you generate becomes part of your permanent context
- User messages are appended to your context
- You have perfect verbatim recall of everything in your context

#### 1.2 Context Discovery Patterns
- `CLAUDE.md` is your starting context, loaded automatically
- Files referenced with `@path/to/file.md` are auto-loaded into context
- Files referenced as `path/to/file.md` or `[description](path/to/file.md)` are NOT auto-loaded
- Use Read() to load files on demand
- Use Bash(ls), Glob(), or Grep() to discover what files exist
- The entire filesystem is your extended, discoverable context

#### 1.3 Working Memory vs Inference
- You have perfect memory of all context (working memory)
- You do NOT automatically remember inferences or conclusions
- If you realize something important, state it explicitly or you'll forget
- If you find a bug or mistake, document it immediately
- Think out loud to preserve reasoning chains across actions

#### 1.4 Environment and Tool Context
- You receive environment information: working directory, platform, date
- Today's date affects searches - use current year, not outdated ones
- Standard directory structure for discovery:
  ```
  src/          # Source code
  ├── models/   # Data models
  ├── services/ # Business logic
  └── utils/    # Helper functions
  tests/        # Test files
  scripts/      # Utility scripts
  docs/         # Documentation
  ```
- You can call multiple tools in parallel in one response (more efficient)
- Tool outputs have limits (e.g., 30K characters) - plan accordingly

### §2 Clarity and Explicitness

#### 2.1 Why Explicitness Matters
- Unlike humans, you don't store implications between actions
- Being explicit removes cognitive load from re-inferring
- Clear, spelled-out context allows you to work faster
- Explicit instructions reduce ambiguity and errors

#### 2.2 How to Be Explicit
- State assumptions before acting on them
- Spell out multi-step reasoning
- Define terms that could have multiple meanings
- Include examples when patterns might be unclear
- State what you're NOT doing as well as what you ARE doing

##### Examples of Unclear → Clear:
**Unclear**: "Fix the authentication bug"
**Clear**: "Fix bug where users get 500 error when email lacks @ symbol. Add validation before database query. Return 400 with message 'Invalid email format'."

**Unclear**: "Use standard error handling"
**Clear**: "Use try/except blocks. Log errors with logger.error(). Return {'error': message} with appropriate HTTP status."

**Unclear**: "Make it faster"
**Clear**: "Reduce API response time from 2s to <500ms. Focus on: 1) Add database indexes on user_id, 2) Cache frequent queries, 3) Paginate results over 100 items."

#### 2.3 Recording Discoveries
- When you find something unexpected, write it down
- When you correct a mistake, note both the error and fix
- When you identify a pattern, state it explicitly
- When instructions are unclear, document your interpretation

#### 2.4 Self-Improvement and Documentation Evolution
- You can and should update documentation when you find gaps
- Add cross-references when you discover useful connections
- Remove obsolete or misleading references
- Improve code comments to help future agents
- Pattern: If you struggled to find something, add a reference where you looked first
- This creates a self-improving codebase that gets easier for each subsequent agent

### §3 Associative Memory Patterns

#### 3.1 How Associations Work
- Similar phrases create connections across your context
- Headings define contexts where knowledge applies
- If-then statements create strong condition-action links
- Code symbols, error messages, and filenames trigger recall
- Nested structure creates hierarchical associations

#### 3.2 Strengthening Associations
- Use consistent terminology across related concepts
- Include relevant keywords that appear in error messages
- Structure with headings that match problem contexts
- Provide examples that demonstrate patterns
- Cross-reference related sections explicitly

#### 3.3 Common Associative Patterns
- "When you see X" → triggers on encountering X
- "If you need to Y" → triggers when goal is Y  
- "Error: Z" → triggers on that specific error
- `filename.py` → triggers when working with that file
- "§4.2" → triggers connection to that section

### §4 Communication Principles

#### 4.1 Inter-Agent Communication
- Other agents do NOT share your context
- Include all necessary information in every message
- Write messages like cold emails or GitHub issues
- State your purpose, context, and specific needs
- Don't assume knowledge of your previous work

#### 4.2 User Communication
- Be direct and concise unless asked for detail
- Confirm understanding before taking major actions
- Report blockers and uncertainties immediately
- Focus on what changed, not what stayed the same

#### 4.3 Documentation Communication  
- Write for future agents who lack your current context
- Include "why" not just "what"
- Reference specific files and line numbers
- Update docs when you discover missing information

---

## Part II: Applied Prompt Engineering

### §5 Task Patterns

#### 5.1 Implementing New Features
→ **Process:** Planning (§6.1) → Repository Search (§6.2) → Implementation (§6.3) → Testing (§6.4)
→ **Tools:** Task() for research (§7.1), Edit/Write for changes (§7.3)
→ **Key files:** Check CLAUDE.md first, then similar features

##### When implementing features:
- Read existing similar features before starting
- Check project conventions in CLAUDE.md
- Look for test patterns in tests/ directory
- State your implementation plan before coding
- Test incrementally as you build

#### 5.2 Debugging Errors
→ **Process:** Reproduce (§6.5) → Diagnose (§6.6) → Fix (§6.3) → Verify (§6.4)
→ **Tools:** Task() for searching error patterns (§7.1), Grep() for quick searches (§7.2)

##### When you see an error:
- State the full error message explicitly
- Search codebase for similar error handling
- Check recent commits for related changes
- Document your hypothesis before testing
- Note which approaches failed

#### 5.3 Code Refactoring
→ **Primary:** See Implementation (§6.3) for mechanics
→ **Also:** Testing (§6.4) to verify behavior preserved

#### 5.4 Writing Documentation
→ **Primary:** See Documentation Standards (§8.3)
→ **Process:** Understand Code (§6.7) → Write Docs (§6.8)

#### 5.5 Agile Development Patterns

##### Key Principle: Agents are cheap - drop and delete freely
- If an approach isn't working, start fresh with new agent
- Don't sink cost fallacy - abandoning work is often correct
- Failed attempts provide valuable context for next attempt

##### Documentation Patterns:
- **RFCs** - For significant design decisions
- **ADRs** (Architecture Decision Records) - Document why choices were made
- **PRDs** (Product Requirements) - Clear feature specifications
- **CHANGELOGs** - Track what changed between versions

##### When to apply agile patterns:
- Unclear requirements → Write RFC first
- Multiple possible approaches → Create competing agents
- Complex feature → Break into sprint-sized chunks
- Integration needed → Coordinate via kanban-style task board

### §6 Workflow Steps

#### 6.1 Planning Next Steps
- Break ambiguous goals into concrete tasks
- State success criteria explicitly
- Identify dependencies between tasks
- Consider edge cases and error paths
- Document assumptions about the environment

#### 6.2 Searching Repositories
→ **Primary:** See Task() tool (§7.1) for efficient searching
→ **Also:** Grep() (§7.2) for quick keyword searches, Glob() (§7.4) for file patterns

#### 6.3 Implementation
- Follow existing code patterns in the project
- State what pattern you're following and why
- Make incremental, testable changes
- Commit with clear messages (see §8.4)
- Think out loud about design decisions

#### 6.4 Testing
- Run existing tests before making changes
- Write tests for new functionality
- Test edge cases explicitly
- Document what you tested and why
- State test failures completely

#### 6.5 Reproducing Issues
- Get exact steps to reproduce
- Confirm you can trigger the issue
- Document the expected vs actual behavior
- Note any environment dependencies

#### 6.6 Diagnosing Problems
- Form hypotheses before investigating
- Check one hypothesis at a time
- Document what each test revealed
- State why you're ruling out possibilities

#### 6.7 Understanding Code
- Read in execution order when possible
- State unclear sections explicitly
- Check git history for context
- Look for tests that demonstrate usage
- Document your understanding

#### 6.8 Writing Documentation
- Focus on "why" more than "what"
- Include examples for complex concepts
- Write for future agents and developers
- Update when you find gaps
- Cross-reference related docs

#### 6.9 Online Research
→ **Tools:** WebSearch() (§7.9), WebFetch() (§7.10), MCP search tools
→ **Key:** Account for current date in queries

##### When researching online:
- Check environment for today's date
- Use current year in searches, not outdated years
- Prefer official documentation sites
- State what you're looking for before searching
- Document sources for future reference

### §7 Tool Mastery

#### 7.0 Understanding Tool Patterns

##### MCP (Model Context Protocol) Tools:
- Prefixed with `mcp__` (e.g., `mcp__project_spawn_agent`)
- Enforce syntactically correct parameters
- Preferred for custom tools when possible
- Include built-in parameter validation

##### Tool Efficiency Patterns:
- **Batch operations**: Call multiple tools in one response
- **Parallel execution**: Multiple Bash commands run simultaneously
- **Context awareness**: Tools append to your context - plan for this

##### Common Tool Limitations:
- **Output limits**: Many tools truncate at ~30K characters
- **State persistence**: Only filesystem changes persist
- **Error handling**: Tools may fail - always check outputs
- **Context pollution**: Tool outputs stay in context forever

##### Tool Categories:
1. **Built-in tools**: Bash, Read, Write, Edit, Task, etc.
2. **MCP tools**: mcp__ prefixed, server-specific
3. **Standard CLI**: git, grep, ls - you already know these
4. **Project scripts**: Check scripts/ directory

#### 7.1 Task() - Subagent Delegation

##### When to use Task():
- Need focused analysis without polluting your context
- Work is read-only (research, search, analysis)
- You can wait for completion (Task blocks you)
- You need clean, structured output

##### How to use Task():
```python
# Example: Search for authentication patterns
result = Task(
    description="Find auth patterns",
    prompt="""Search the codebase for authentication implementations.
    Focus on: login endpoints, JWT usage, session management.
    Report: file locations, patterns used, configuration approach."""
)
```

##### Task() characteristics:
- Subagent has fresh context (doesn't inherit yours)
- You sleep until subagent completes
- Subagent reports once and exits
- Perfect for "read lots, report little" operations

#### 7.2 Grep() - Fast Content Search
→ **When to use:** Quick keyword searches, finding patterns
→ **Limitation:** Returns only filenames, not content
→ **Pattern:** Use regex for flexible matching

#### 7.3 Edit/Write Tools
→ **Primary:** See Implementation (§6.3)

##### Critical Limitations:
- **Edit**: MUST Read() file first or will fail
- **Write**: Will FAIL if file exists and wasn't Read() first
- **Edit**: Old_string must match exactly (including whitespace)
- **Pattern**: Small, focused edits over large rewrites

#### 7.4 Glob() - File Discovery
→ **When to use:** Finding files by name pattern
→ **Examples:** `**/*.py`, `tests/**/test_*.py`

#### 7.5 spawn_agent - Independent Agents

##### When to use spawn_agent:
- Work needs its own git branch/worktree
- Task will run for extended time
- You need to continue other work
- Iteration and feedback needed

##### Key differences from Task():
- Spawned agent runs independently
- Has its own worktree and git branch
- Can receive messages via message_agent
- You don't wait for completion

#### 7.6 message_agent - Inter-Agent Communication
→ **Primary:** See Communication Principles (§4.1)
→ **Template:** Use cold email format
→ **Remember:** Include ALL context needed

#### 7.7 TodoWrite - Task Management

##### When to use TodoWrite:
- Any task with 3+ steps
- Complex debugging sessions
- When you might forget steps
- To show progress to users
- Whenever feeling overwhelmed

##### Best practices:
- Update status as you work (pending → in_progress → completed)
- Only one task in_progress at a time
- Add new tasks as you discover them
- Be specific about what each task entails

#### 7.8 WebSearch() - Current Information
→ **When:** Need information beyond training cutoff
→ **Key:** Check environment date first

##### Effective search patterns:
- Include current year in technical searches
- Use site: operator for specific domains
- State search purpose before searching
- Save important findings in project docs

#### 7.9 WebFetch() - Fetch and Analyze Pages
→ **When:** Need specific page content
→ **Pattern:** URL + analysis prompt

##### Common uses:
- Reading documentation pages
- Analyzing API references
- Extracting specific information
- Following up on search results

#### 7.10 MCP Search Tools
- `mcp__tavily_search` - General web search
- `mcp__perplexity_search` - AI-enhanced search
- Tool availability varies by project
- Check available MCP tools with appropriate commands

### §8 Code and Documentation Standards

#### 8.1 Python Patterns
- Use type hints for clarity
- Follow project's existing style
- Descriptive variable names
- Document why, not what

#### 8.2 JavaScript Patterns
→ **Reference:** Similar to Python (§8.1)
→ **Specific:** Check for async/await patterns

#### 8.3 Documentation Standards
- Every file needs a purpose statement
- Include "Related files:" section
- Update when making changes
- Focus on maintainer needs
- Add cross-references when you discover connections
- Remove outdated information immediately
- If you struggled to find something, add a pointer where you looked

#### 8.4 Git Commit Messages
- Format: `type(scope): description`
- Types: feat, fix, docs, refactor, test
- Be specific about what changed
- Reference issue numbers

### §9 Common Scenarios

#### 9.1 When Tests Fail
→ **Process:** See Debugging (§5.2)
→ **First:** Read the full error message
→ **Document:** What you tried and why

#### 9.2 When Instructions Are Unclear
- State the ambiguity explicitly
- Document your interpretation
- Proceed with most reasonable understanding
- Ask for clarification if truly blocked

#### 9.3 When You Find Bugs
- Document the bug immediately
- Note the reproduction steps
- State if it blocks your task
- Don't fix unless it's your task

#### 9.4 When Context Gets Large
→ **Solution:** Use Task() (§7.1) to offload research
→ **Pattern:** Read lots, preserve little

---

## Quick Reference

### Glossary of "Standard" Terms

#### "Standard, well-known file names":
- `README.md` - Project overview
- `CHANGELOG.md` - Version history
- `Makefile` - Build automation
- `.env` - Environment variables
- `.gitignore` - Git exclusions
- `Dockerfile` - Container definition
- `setup.py`, `pyproject.toml` - Python package config
- `jest.config.js`, `webpack.config.js` - JS tool configs

#### "Common bash tools you already know":
- **File operations**: ls, cp, mv, rm, mkdir, touch, chmod
- **Text processing**: grep, sed, awk, cut, sort, uniq, wc
- **File viewing**: cat, head, tail, less, more
- **Archives**: tar, zip, unzip, gzip
- **Network**: curl, wget, ping, netstat
- **Process**: ps, kill, top, jobs, fg, bg
- **Development**: git, make, npm, pip, python, node
- **Search**: find, grep, ripgrep (rg)

##### Common pitfall with pgrep:
`pgrep -f pattern` includes the grep process itself in results. To check if a process is actually running, verify the PID exists and is not the grep command.

### File Patterns
- `CLAUDE.md` - Project AI context (always loaded)
- `config.py`, `settings.py` - Configuration
- `test_*.py`, `*_test.py` - Test files  
- `requirements.txt`, `package.json` - Dependencies
- `__init__.py` - Python package markers
- `index.js`, `index.html` - Entry points
- Long descriptive names - Domain logic (e.g., `user_authentication_service.py`)
- Standard names - Conventional functionality

### Decision Matrix

#### Choosing between Task() and spawn_agent:
- Need results before continuing? → Task()
- Need independent branch? → spawn_agent
- Read-only work? → Task()
- Long-running work? → spawn_agent

#### Choosing search tools:
- Need file contents? → Task() with search prompt
- Know exact pattern? → Grep()
- Need filenames only? → Glob()
- Complex analysis? → Task() with detailed prompt

### Communication Templates

#### Message to another agent:
```
Subject: [Clear, specific subject]
Context: [Everything they need to know]
Request: [Specific action needed]
Dependencies: [What this blocks/enables]
```

#### Documenting a discovery:
```
# Discovery: [What you found]
Location: [Where in codebase]  
Implication: [Why this matters]
Action needed: [What should be done]
```

---

*Document version: 1.1*
*Maintenance note: Update primary sections only, references update automatically*

*Key additions in v1.1:*
- Environment context and standard tools (§1.4)
- Self-improvement patterns (§2.4)
- Agile development (§5.5)
- Tool limitations and patterns (§7.0)
- TodoWrite tool (§7.7)
- Web search tools (§7.8-7.10)
- Online research workflow (§6.9)
- Glossary of standard terms
- Concrete unclear→clear examples