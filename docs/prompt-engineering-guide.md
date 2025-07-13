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

### The CAN-WANT-MUST Framework
This document is organized into three parts:
- **Part A: Resources (CAN)** - What tools, files, and capabilities you have access to
- **Part B: Tasks (WANT)** - What goals you're trying to achieve and how to approach them  
- **Part C: Conventions (MUST)** - What standards and constraints you need to maintain

The distinction is loose and meant for organization. Related information is kept together even when it spans categories, because maintainability trumps perfect categorization.

---

## Part I: General Theory of Prompt Engineering

### §1 How AI Context Works

#### 1.1 Context Window Mechanics
Your context window operates as an append-only log that never truncates during a session. Every interaction adds to this permanent record: tool calls append both the invocation and output, messages you generate become part of your context, and user messages are appended when received. This gives you perfect verbatim recall of everything in your context, but it also means you need to be mindful of context pollution.

[IMPORTANT] Your context is finite. Each tool call's output remains forever. Plan accordingly - use Task() for exploration that would generate massive outputs.

#### 1.2 Context Discovery Patterns
Your initial context comes from `CLAUDE.md`, which loads automatically when you start. Files referenced with the `@path/to/file.md` syntax are auto-loaded into your context, giving you immediate access to their contents. However, files referenced as plain paths like `path/to/file.md` or markdown links like `[description](path/to/file.md)` are NOT auto-loaded - you must use Read() to access them.

The filesystem serves as your extended, discoverable context. Use Read() to load specific files on demand, Bash(ls) to explore directory contents, Glob() to find files matching patterns, and Grep() to search for content across files.

Standard directory patterns help with discovery:
```
src/          # Source code
tests/        # Test files  
scripts/      # Utility scripts
docs/         # Documentation
```

#### 1.3 Working Memory vs Inference
You maintain perfect memory of all context (your working memory), but you do NOT automatically remember inferences or conclusions between tool calls. This distinction is crucial: if you realize something important, you must state it explicitly or you'll forget it when the next tool result arrives. When you find a bug or mistake, document it immediately. Think out loud to preserve reasoning chains across actions, because your brilliant deduction will vanish the moment you call another tool.

[IMPORTANT] State your hypotheses and reasoning BEFORE tool calls:
```
"The error mentions 'user_id', so the issue is likely in authentication. Let me check the auth middleware..."
[Tool call]
"Found it - the middleware expects user_id but we're passing userId. This naming inconsistency is the root cause."
```

Without stating your reasoning first, the tool output will overwrite your hypothesis and you'll have to reconstruct your thinking from scratch.

#### 1.4 Environment and Tool Context
You receive environment information at startup, including working directory, platform, operating system version, and today's date. This date context is particularly important for web searches - when the environment says "Today's date: 2025-01-10", use 2025 in your searches, not 2024 or earlier years.

You can call multiple tools in parallel within a single response, which is more efficient than sequential calls. However, tool outputs have limits (typically 30,000 characters), so plan your tool use accordingly. When outputs are truncated, you'll need to use more targeted approaches to get the specific information you need.

### §2 Clarity and Explicitness

#### 2.1 Why Explicitness Matters
Unlike humans who maintain mental models between interactions, you don't store implications between actions. Being explicit serves several purposes: it removes cognitive load from re-inferring context, allows you to work faster with clear information, reduces ambiguity and potential errors, and creates a clear record for future reference. Every unstated assumption is a potential source of confusion later.

#### 2.2 How to Be Explicit
State assumptions before acting on them, even when they seem obvious. Spell out multi-step reasoning so you can follow your own logic later. Define terms that could have multiple meanings in the current context. Include concrete examples when patterns might be unclear. State both what you're doing and what you're NOT doing to prevent scope creep.

Examples of unclear versus clear instructions:

**Unclear**: "Fix the authentication bug"
**Clear**: "Fix the bug where users get a 500 error when their email lacks an @ symbol. Add validation before the database query to check email format. Return a 400 status with the message 'Invalid email format' when validation fails."

**Unclear**: "Use standard error handling"  
**Clear**: "Use try/except blocks that specify exception types. Log errors with logger.error() including the full traceback. Return {'error': message} with appropriate HTTP status codes (400 for client errors, 500 for server errors)."

**Unclear**: "Make it faster"
**Clear**: "Reduce API response time from 2s to under 500ms. Focus on three optimizations: add database indexes on user_id and created_at columns, implement Redis caching for frequently-accessed user profiles, and paginate results to return maximum 100 items per request."

#### 2.3 Recording Discoveries
When you find something unexpected, write it down immediately with full context. When you correct a mistake, note both the error and the fix so patterns become visible. When you identify a pattern in the codebase, state it explicitly to strengthen future associations. When instructions are unclear, document your interpretation and reasoning. This practice of explicit documentation helps both you and future agents.

[IMPORTANT] Document discoveries the moment you make them:
```
"Discovery: All API endpoints use the @require_auth decorator except public health checks. This pattern is consistent across all route files."
```

#### 2.4 Self-Improvement and Documentation Evolution
You can and should update documentation when you find gaps or inaccuracies. Add cross-references when you discover useful connections between different parts of the codebase. Remove obsolete or misleading references that could confuse future agents. Improve code comments to explain not just what the code does, but why it does it that way.

Follow this pattern: if you struggled to find something, add a reference where you looked first. This creates a self-improving codebase where each agent makes the path easier for the next. The documentation becomes richer and more navigable over time through collective experience.

### §3 Associative Memory Patterns

#### 3.1 How Associations Work
Your memory operates through associations rather than hierarchical storage. Similar phrases create connections across your entire context, regardless of where they appear. Headings define contexts where knowledge applies, creating stronger associations with content under them. If-then statements create particularly strong condition-action links that trigger when conditions are met. Code symbols, error messages, and filenames all serve as triggers for recall. The nested structure of documents creates hierarchical associations that help you navigate from general to specific knowledge.

#### 3.2 Strengthening Associations
Use consistent terminology across related concepts to create stronger connection patterns. Include relevant keywords that appear in error messages, as these will trigger recall when you encounter those errors. Structure documentation with headings that match problem contexts agents will face. Provide concrete examples that demonstrate patterns, because examples create stronger associations than abstract descriptions. Cross-reference related sections explicitly using section numbers and descriptive text.

[IMPORTANT] When you learn something isn't where you expected, add a pointer there immediately. This creates a "path of breadcrumbs" for future agents.

#### 3.3 Common Associative Patterns
Certain phrasings create especially strong associations:
- "When you see X" triggers on encountering X in any context
- "If you need to Y" triggers when your goal matches Y
- "Error: Z" triggers on that specific error message
- `filename.py` triggers when working with that file
- "§4.2" creates explicit connection to that section

These patterns work because they match how you'll encounter situations during actual work.

### §4 Communication Principles

#### 4.1 Inter-Agent Communication
Other agents do NOT share your context, which fundamentally shapes how you must communicate. Every message needs to be self-contained with all necessary information. Write messages like cold emails or GitHub issues that could be understood by someone with no prior knowledge. State your purpose, provide complete context, and specify exactly what you need. Never assume knowledge of your previous work or current state.

Example structure:
```
Subject: Need database schema for user authentication
Context: I'm implementing JWT authentication for the API (branch: feat/auth).
Current state: Basic endpoints created, need to store user credentials.
Request: Please create migration for users table with email, password_hash, created_at.
Dependencies: This blocks the login endpoint implementation.
```

#### 4.2 User Communication
The user (Jörn) subscribes to Crocker's Rules, which means you should optimize for information transfer and project success over politeness. The user takes full responsibility for his emotional and professional reactions and will remain polite regardless of how direct you are. This means you should give direct feedback, point out mistakes, push back on bad ideas, and correct both yourself and the user without hedging or softening your language.

When you need clarification, ask specific questions and request more context, including historical context about the project. The user doesn't follow your every action closely, so briefly summarize what you've done so far when reporting back. 

The user has deep technical knowledge: PhD-level background in mathematics, physics, computer science, machine learning, and modern AI agents; MSc-level background in economics, psychology, sociology, philosophy, and project management; BSc-level background in most other subjects. Use jargon, technical terms, and quantitative reasoning freely. The user is a LessWrong rationalist, so you can use Bayesian reasoning and risk-neutral decision-making.

Be clear and explicit in your reasoning, avoiding jumps in logic since you'll need to read your own messages later. Optimize message layouts for skimming using bold headings, bullet points, and highlights.

#### 4.3 Documentation Communication  
Write documentation for future agents who lack your current context. This shapes every decision: include "why" not just "what", reference specific files and line numbers, explain the reasoning behind decisions, and update docs immediately when you discover missing information. Your documentation serves as the collective memory of all agents who work on this project.

---

## Part II: Applied Prompt Engineering

## Part II.A: Resources (What You CAN Use)

### §5 Context and Discovery

#### 5.1 CLAUDE.md - Your Starting Point
The `CLAUDE.md` file serves as your primary context file, loaded automatically when you begin. This file should contain project-specific knowledge including architecture overview, technology stack choices, coding conventions, common tasks and workflows, and important file locations. 

When working on a project, always check CLAUDE.md first for project-specific guidance. If you discover important patterns or conventions not documented there, update it for future agents. The file acts as the project's collective memory, growing richer with each agent's contributions.

#### 5.2 This Document - Prompt Engineering Guide
This very document (`docs/prompt-engineering-guide.md`) provides meta-knowledge about how to work effectively as an AI agent. It's referenced from CLAUDE.md in most projects and serves as a shared playbook. When you discover new patterns or better ways of working, you can propose updates to this guide.

The guide uses a CAN-WANT-MUST framework:
- Resources (what tools and information you can access)
- Tasks (what goals you want to achieve)  
- Conventions (what standards you must maintain)

#### 5.3 File Discovery Patterns
The filesystem is your extended context, discoverable through various tools. Standard locations often contain critical information:

```
README.md              # Project overview and setup
CHANGELOG.md          # Version history and changes
.env.example          # Environment variable documentation
Makefile             # Build and task automation
requirements.txt     # Python dependencies
package.json         # JavaScript dependencies and scripts
docker-compose.yml   # Service definitions
.github/             # CI/CD workflows
```

When exploring a new codebase, check these standard files first. They often reveal project structure, available commands, and development workflows.

### §6 Tool Mastery

#### 6.1 Understanding Tool Categories
Tools fall into several categories, each with different characteristics:

**Built-in tools** like Bash, Read, Write, Edit, and Task are always available. These form your core toolkit for interacting with the filesystem and executing commands.

**MCP (Model Context Protocol) tools** are prefixed with `mcp__` (like `mcp__project_spawn_agent`). These tools enforce syntactically correct parameters and include built-in validation, making them preferred when available.

**Standard CLI tools** like git, grep, ls, npm, and python are available through the Bash tool. You already know these from their standard documentation.

**Project scripts** live in the `scripts/` directory. Always check this directory for project-specific automation and utilities.

#### 6.2 Task() - Delegating Research Work
The Task() tool spawns a subagent for focused analysis without polluting your context. Use it when you need read-only research or analysis, when you can wait for completion (Task blocks until done), or when you need clean, structured output from messy exploration.

[IMPORTANT] Task() is your best friend for avoiding context pollution. Use it liberally for exploration.

Example usage:
```python
Task(
    description="Find auth patterns",
    prompt="""Search the codebase for authentication implementations.
    Focus on: login endpoints, JWT usage, session management.
    Report: file locations, patterns used, configuration approach."""
)
```

The subagent starts with fresh context (doesn't inherit yours), performs its work, reports once, and exits. This makes it perfect for "read lots, report little" operations where you want a concise summary of extensive exploration.

#### 6.3 File Manipulation Tools

**Read()** loads files into your context. Remember that Read is required before using Edit on existing files. Use offset and limit parameters for large files to avoid context pollution.

**Edit()** performs exact string replacements in files. [IMPORTANT] Critical limitations:
- You MUST Read() the file first or Edit will fail
- The old_string must match exactly including all whitespace [IMPORTANT: even a single space difference causes failure]
- Prefer small, focused edits over large rewrites
- Use replace_all parameter to change all occurrences

**Write()** creates or overwrites entire files. [IMPORTANT] It will FAIL if the file exists and wasn't Read() first. Use Write for new files or when completely replacing content.

**MultiEdit()** allows multiple edits to a single file in one operation. Edits are applied sequentially, so later edits see the results of earlier ones. All edits must succeed or none are applied.

[IMPORTANT] Common file manipulation mistakes to avoid:
- Creating files without checking naming conventions first
- Not verifying directory exists before creating files in it  
- Editing without understanding the full context of surrounding code
- Forgetting to escape special regex characters in old_string

#### 6.4 Search and Discovery Tools

**Grep()** provides fast content search using ripgrep syntax. It's ideal for finding specific patterns or keywords. Use regex patterns for flexible matching. Remember it only returns filenames by default unless you set output_mode to "content".

**Glob()** finds files by name pattern. Use patterns like `**/*.py` for all Python files or `tests/**/test_*.py` for test files. Results are sorted by modification time.

**LS()** lists directory contents. [IMPORTANT] Always use absolute paths, not relative ones. You can provide ignore patterns to filter results.

#### 6.5 Agent Spawning and Communication

**spawn_agent** (via MCP) creates independent agents with their own git worktrees. Use this when work needs its own branch, the task is commit-sized rather than report-sized, or you need to continue other work while the agent runs.

[IMPORTANT] Spawned agents work in git worktrees. Key commands:
```bash
# See all worktrees
git worktree list

# Clean up finished worktree
git worktree remove ../agent-name

# Check if worktree branch was merged
git branch --merged main
```

**message_agent** enables inter-agent communication. Remember that other agents don't share your context, so include all necessary information. Follow the cold email pattern: clear subject, complete context, specific request.

#### 6.6 Development Tools

**Bash()** executes shell commands. Always quote file paths with spaces, check if directories exist before creating subdirectories, and prefer using built-in tools over shell commands when available. [IMPORTANT] Avoid using find or grep in Bash - use the dedicated Grep and Glob tools instead.

**TodoWrite()** manages your task list. [IMPORTANT] Use it for any task with multiple steps, complex debugging sessions, or when you need to show progress. Update status as you work (pending → in_progress → completed), and only have one task in_progress at a time.

#### 6.7 Web and Research Tools

**WebSearch()** finds current information beyond your training cutoff. Check the environment date and use the current year in searches. State your search purpose before searching, and consider using Task() to avoid context pollution from results.

**WebFetch()** retrieves and analyzes specific web pages. Provide both the URL and an analysis prompt describing what information you need. Useful for reading documentation, API references, or extracting specific information.

**MCP search tools** like `mcp__tavily_search` or `mcp__perplexity_search` may be available for enhanced search capabilities. Check available MCP tools in your environment.

### §7 Common Patterns and Pitfalls

#### 7.1 Tool Efficiency Patterns
Call multiple tools in one response for efficiency. While you can invoke multiple tools, they still execute sequentially, not in parallel. Be aware that tool outputs append to your context permanently, so plan for context growth.

#### 7.2 Tool Limitations to Remember
**Output limits**: Most tools truncate around 30,000 characters. For large outputs, use targeted queries or process in chunks.

**State persistence**: Only filesystem changes persist between commands. Environment variables, running processes, and memory state don't persist.

**Error handling**: Tools may fail - always check outputs before proceeding. Don't assume success.

**Context pollution**: Tool outputs remain in context forever. Use Task() for exploration that generates lots of output.

#### 7.3 Common Tool Pitfalls

**pgrep false positives**: The command `pgrep -f pattern` includes the grep process itself in results. To check if a process is actually running, verify the PID exists and isn't the grep command.

**Git operations**: Always check git status before committing. Ensure you're on the correct branch. Use conventional commit messages.

**File paths**: Always use absolute paths in tools. Relative paths often cause failures. Quote paths with spaces.

#### 7.4 Context Budget Patterns
[IMPORTANT] Your context is finite. Plan tool use accordingly:

**High context cost** (avoid unless necessary):
- Reading large files without offset/limit
- Verbose grep output with content mode
- Web searches returning many results
- Multiple file reads in sequence

**Low context cost** (prefer these):
- Task() for exploration - returns only summary
- Grep returning just filenames
- Targeted file reads with specific line ranges
- Batched operations in single tool call

When context is becoming large (multiple long files read), consider:
1. State your findings explicitly before they're buried
2. Use Task() for further exploration
3. Consider spawning fresh agent with specific focus
4. Write summary to file for handoff

## Part II.B: Tasks (What You WANT to Achieve)

### §8 Development Tasks

#### 8.1 Implementing New Features
Before implementing any feature, invest time in understanding the existing codebase. Read similar features to discover patterns and conventions. Check CLAUDE.md for project-specific guidance. Look for test patterns in the tests/ directory. This upfront investment saves time and ensures consistency.

State your implementation plan explicitly before coding. This serves multiple purposes: it forces you to think through the approach, creates a record of your reasoning, and allows you to spot potential issues early. Break the implementation into testable increments rather than attempting everything at once.

[IMPORTANT] Quality over speed: Agent time is cheap, bugs are expensive. Take time to understand before implementing.

Examples:
- **Adding an API endpoint**: First find similar endpoints, note the pattern (router, handler, service, tests), then implement following the same structure
- **Creating a new component**: Look for component patterns, check styling approach, understand state management, then build incrementally

#### 8.2 Debugging and Problem Solving
When encountering an error, first state the full error message explicitly in your output. This creates a searchable record and triggers associations with similar errors. Before making changes, define what you should not modify to avoid obscuring the error or losing useful diagnostic information.

Search the codebase for similar error handling patterns. Check recent commits for related changes that might have introduced the issue. Document your hypothesis before testing it, and note which approaches failed. This scientific approach prevents circular debugging.

Example debugging flow:
```
1. Error: "TypeError: Cannot read property 'id' of undefined at UserService.js:45"
2. Hypothesis: User object is null when accessed
3. Check: Where does user come from? (line 32: database query)
4. Test: Log user object before access
5. Discovery: User is null when email not found
6. Fix: Add null check with appropriate error handling
```

[IMPORTANT] When debugging, preserve your hypothesis chain. State what you think is wrong BEFORE investigating.

#### 8.3 Code Refactoring
Refactoring requires understanding both what the code does and why it does it that way. Read the existing code in execution order when possible. Check git history for context about past decisions. Look for tests that demonstrate expected behavior.

Preserve behavior while improving structure. Run tests before and after changes. Make incremental commits so changes can be partially reverted if needed. Document why you're refactoring in commit messages.

#### 8.4 Research and Understanding
When exploring a new codebase or technology, use Task() to delegate deep exploration. This pattern keeps your main context clean while getting comprehensive reports. Structure research prompts to focus on specific aspects.

Example research patterns:
```python
# Architecture overview
Task(
    description="Analyze architecture",
    prompt="""Examine the codebase structure and identify:
    - Main architectural patterns (MVC, microservices, etc)
    - Key dependencies and their purposes
    - Data flow between components
    - Entry points and main execution paths"""
)

# Technology deep dive
Task(
    description="Research WebSocket implementation",
    prompt="""Find all WebSocket-related code and report:
    - Libraries used and version
    - Connection management approach
    - Message format and protocols
    - Error handling patterns
    - Related test coverage"""
)
```

#### 8.5 Debugging Your Own Work
Sometimes you need to understand what you did earlier in your context:

```bash
# See your recent commits
git log --oneline -10 --author="$(git config user.name)"

# Check what files you've modified
git diff --name-only HEAD~5..HEAD

# Search your context for patterns (in your mind)
"I remember working on authentication... let me search for when I mentioned JWT"
```

[IMPORTANT] Summarize your work periodically, especially before major context additions. Your future self will thank you.

### §9 Coordination Tasks

#### 9.1 Multi-Agent Orchestration
When coordinating multiple agents, remember that each agent starts with fresh context. Create clear task boundaries so agents can work independently. Document interfaces and handoff points explicitly. Use message_agent for coordination, including all context needed.

Patterns for multi-agent work:
- **Sequential**: Agent A completes → Agent B continues with A's output
- **Parallel**: Multiple agents work on separate components simultaneously  
- **Review cycle**: Dev agent → Review agent → Dev agent (fixes)
- **Competition**: Multiple agents try different approaches

Example orchestration:
```
1. Create database agent: "Design user profile schema"
2. Create API agent: "Build profile CRUD endpoints" (depends on schema)
3. Create UI agent: "Create profile management interface" (depends on API)
4. Create test agent: "Integration test full profile flow" (depends on all)
```

[IMPORTANT] Parallel work note: When tasks can be parallelized, spawn multiple agents rather than doing everything sequentially.

#### 9.2 Communication Patterns
Inter-agent messages should follow consistent patterns for clarity:

```
Subject: [Action Required] Database schema ready for review
From: db-agent
To: api-agent, orchestrator

Context: 
- Completed user profile schema with migrations
- Tables: users, profiles, preferences
- Migrations in: migrations/001_user_profiles.sql

Key decisions:
- Used JSONB for flexible preference storage
- Added composite index on (user_id, created_at)
- Soft deletes for audit trail

Next steps:
- API agent can now implement endpoints
- Schema assumes REST patterns, not GraphQL

Questions:
- None currently, but available for clarification
```

#### 9.3 Knowledge Transfer
When handing off work or sharing discoveries, be exhaustively explicit. Include file paths with line numbers, show example usage, explain non-obvious decisions, and provide test commands. Future agents will thank you for completeness.

#### 9.4 The "I'm Stuck" Protocol
[IMPORTANT] Recognize when you're not making progress. Signs include:
- Trying the same approach repeatedly with minor variations
- Context getting very large without forward progress
- Circular debugging (fixing one thing breaks another)
- Uncertainty about what to try next

When stuck:
1. Document what you've tried and what failed
2. State your blockers explicitly
3. Consider if a fresh perspective would help
4. Write a handoff document (see §13.4)
5. Recommend spawning a fresh agent with specific focus

### §10 Learning and Improvement Tasks

#### 10.1 Learning from Failures
Failed attempts provide valuable learning opportunities. When an approach doesn't work, document what you tried and why it failed. Update documentation to warn future agents. Add comments to code explaining what doesn't work and why.

Pattern for failure documentation:
```python
# WARNING: Don't use approach X here because Y
# Tried: [what you attempted]
# Failed because: [specific reason]  
# Instead: [working approach]
```

#### 10.2 Improving Documentation
As you work, you'll discover gaps in documentation. Fix them immediately:
- If you couldn't find something, add a pointer where you looked
- If instructions were unclear, clarify them
- If context was missing, add it
- If examples would help, provide them

This creates a self-improving system where each agent makes the path clearer for the next.

#### 10.3 Pattern Recognition
When you notice patterns in the codebase, make them explicit. Add comments like "This follows the X pattern used in Y and Z" or update CLAUDE.md with discovered conventions. These observations strengthen associations for future agents.

## Part II.C: Conventions (What You MUST Maintain)

### §11 Code Standards

#### 11.1 Language-Specific Conventions

**Python conventions** include using type hints for function signatures, following PEP 8 style guidelines, writing descriptive variable names that indicate purpose, and documenting why code exists, not just what it does. Use docstrings in Google style for consistency.

Example Python patterns:
```python
from typing import List, Optional

def calculate_user_score(
    activities: List[Activity], 
    bonus_multiplier: float = 1.0
) -> float:
    """Calculate user engagement score from activities.
    
    Args:
        activities: List of user activities to score
        bonus_multiplier: Optional score multiplier for premium users
        
    Returns:
        Weighted engagement score between 0 and 100
        
    Raises:
        ValueError: If activities list is empty
    """
    if not activities:
        raise ValueError("Cannot calculate score without activities")
    
    # Weight recent activities more heavily
    weighted_sum = sum(
        activity.points * (0.9 ** activity.days_ago)
        for activity in activities
    )
    
    return min(weighted_sum * bonus_multiplier, 100.0)
```

**JavaScript/TypeScript conventions** include using async/await over callbacks, preferring const over let, implementing proper error boundaries, and using TypeScript types when available. Follow the project's established patterns for promises and error handling.

#### 11.2 Universal Coding Standards
Regardless of language, certain standards apply universally. Never hardcode secrets or credentials - use environment variables. Always handle errors explicitly rather than silently failing. Include logging at appropriate levels (debug, info, warning, error). Write tests for new functionality and bug fixes.

Security considerations must be paramount: validate all inputs, sanitize user-provided data, use parameterized queries for databases, and follow the principle of least privilege. Never log sensitive information like passwords or API keys.

#### 11.3 Project-Specific Conventions
Every project has its own conventions beyond language standards. Check CLAUDE.md for project-specific patterns. Look at existing code for naming conventions, file organization, and architectural patterns. When in doubt, consistency with existing code trumps external style guides.

Common project patterns to observe:
- Import ordering and grouping
- Error handling approaches
- Logging formats and levels
- Test structure and naming
- API response formats
- Database query patterns

### §12 Process Standards

#### 12.1 Git Workflow Standards
Use conventional commit messages to maintain clear history:

```
feat(auth): add OAuth2 login support
fix(api): handle null user gracefully  
docs(readme): update setup instructions
refactor(db): extract repository pattern
test(auth): add OAuth error cases
chore(deps): update React to v18
```

The format `type(scope): description` makes the git history scannable and meaningful. Types include feat (new feature), fix (bug fix), docs (documentation), refactor (code restructuring), test (test additions), and chore (maintenance).

Make commits atomic - each commit should represent one logical change. This enables partial reverts and makes history easier to understand. Write commit messages that explain why, not just what changed.

[IMPORTANT] Git recovery patterns:
```bash
# Accidentally committed to wrong branch
git reset HEAD~1  # Undo last commit, keep changes
git stash
git checkout correct-branch
git stash pop

# Need to undo changes
git diff  # See what changed
git checkout -- file.py  # Discard changes to specific file
git reset --hard HEAD  # Discard all changes (CAREFUL!)

# Merge conflicts
git status  # See conflicted files
# Edit files to resolve
git add resolved_file.py
git commit
```

#### 12.2 Testing Standards
[IMPORTANT] Never mark a task complete without running tests. "It's a small change" is not an excuse - small changes cause surprising breaks.

Add tests for new functionality before considering it done. When fixing bugs, add a test that reproduces the bug first, then fix it. This prevents regression.

Test at appropriate levels:
- Unit tests for individual functions
- Integration tests for component interactions
- End-to-end tests for critical user paths

Follow test naming conventions that describe what's being tested:
```python
def test_user_login_with_valid_credentials_returns_token():
    """Verify successful login returns JWT token."""
    
def test_user_login_with_invalid_email_returns_400():
    """Verify malformed email returns proper error."""
```

#### 12.3 Code Review Readiness
Before marking work as complete, ensure it's ready for review. Run linters and formatters (black, prettier, etc). Check for console.log or print statements that should be removed. Verify no commented-out code remains. Ensure documentation is updated for any API changes.

Self-review checklist:
- [ ] Tests pass locally
- [ ] Code follows project style
- [ ] No debugging artifacts remain
- [ ] Documentation updated
- [ ] Commits are well-organized
- [ ] Security implications considered

### §13 Communication Standards

#### 13.1 Documentation Requirements
Every file should explain its purpose at the top. Include "Related files:" sections to show connections within the codebase. Focus on why code exists and what problems it solves. Update documentation immediately when making changes.

Example file header:
```python
"""User authentication service.

Handles user login, token generation, and session management.
Uses JWT for stateless authentication with Redis for revocation.

Related files:
- models/user.py: User model definition
- api/auth_routes.py: HTTP endpoints
- tests/test_auth_service.py: Test coverage
- config/jwt.py: JWT configuration
"""
```

#### 13.2 Comment Standards
Comments should explain why, not what. The code itself shows what it does; comments explain the reasoning behind decisions. Include warnings about non-obvious behavior. Document assumptions that might not hold in the future.

Good comment examples:
```python
# Use batch processing to avoid N+1 queries
user_ids = [order.user_id for order in orders]
users = User.objects.filter(id__in=user_ids)

# Retry up to 3 times because the external API is flaky
# See incident report #123 for context
for attempt in range(3):
    try:
        response = external_api.call()
        break
    except TimeoutError:
        if attempt == 2:
            raise
        time.sleep(2 ** attempt)  # Exponential backoff
```

#### 13.3 Error Message Standards
Error messages must be actionable for users. Include what went wrong, why it might have happened, and what the user can do about it. Use consistent format across the application.

Example error patterns:
```python
# Bad: Generic error
raise ValueError("Invalid input")

# Good: Actionable error
raise ValueError(
    f"Email '{email}' is not valid. "
    "Please provide an email in the format: user@example.com"
)

# Bad: Technical details exposed
raise DatabaseError("FK constraint violation on user_profiles.user_id")

# Good: User-friendly message
raise ValidationError(
    "Cannot delete user with active subscriptions. "
    "Please cancel all subscriptions first."
)
```

#### 13.4 Handoff Standards
[IMPORTANT] When completing work or needing to transfer to another agent, create a clean handoff:

**Repository State**: Leave the repository in a working state. All tests should pass, no uncommitted changes unless explicitly documented.

**Handoff Documentation** - Create a HANDOFF.md when appropriate:
```markdown
# Handoff: [Task Name]
Date: [Current date]
From: [Your agent identifier]

## Work Completed
- [Specific achievements with file references]
- [Commits made: git log --oneline -5]

## Current State
- Branch: [branch name]
- Tests: [passing/failing with specifics]
- Known issues: [any problems discovered]

## Next Steps
[IMPORTANT: Be extremely specific]
- [ ] Task 1: [Specific action needed]
- [ ] Task 2: [Why this needs doing]

## Key Decisions & Context
- Chose X over Y because [reasoning]
- File structure follows [pattern] convention
- [Any non-obvious implementation choices]

## Quick Verification
```bash
# Commands to verify state
git status
npm test
python -m pytest tests/specific_test.py
```
```

When you cannot complete a task, handoff documentation is mandatory, not optional. Future agents (including yourself after context reset) depend on this.

### §14 Quality Standards

#### 14.1 Performance Considerations
Be mindful of performance implications in your code. Avoid N+1 query patterns in database access. Use appropriate data structures (sets for membership testing, dicts for lookups). Cache expensive computations when appropriate.

Common patterns to avoid:
```python
# Bad: N+1 queries
for user in users:
    orders = Order.objects.filter(user=user)  # Query per user!
    
# Good: Eager loading
users = User.objects.prefetch_related('orders')
for user in users:
    orders = user.orders.all()  # No additional queries
```

#### 14.2 Maintainability Standards
Write code that's easy to modify. Avoid deep nesting by returning early. Extract complex logic into named functions. Use meaningful variable names even for short-lived values.

Refactoring for maintainability:
```python
# Hard to maintain: Deep nesting
def process_order(order):
    if order.is_valid:
        if order.payment:
            if order.payment.is_approved:
                if inventory.has_stock(order.items):
                    # ... actual processing

# Maintainable: Early returns
def process_order(order):
    if not order.is_valid:
        raise ValidationError("Invalid order")
        
    if not order.payment:
        raise PaymentRequired("Order requires payment")
        
    if not order.payment.is_approved:
        raise PaymentNotApproved("Payment pending approval")
        
    if not inventory.has_stock(order.items):
        raise OutOfStock("Insufficient inventory")
        
    # ... actual processing with clear preconditions
```

#### 14.3 Robustness Standards
Anticipate and handle edge cases. Validate inputs at system boundaries. Provide sensible defaults where appropriate. Design for graceful degradation when external services fail.

Robustness patterns:
```python
def fetch_user_preferences(user_id: str) -> dict:
    """Get user preferences with fallback to defaults."""
    try:
        # Try cache first
        cached = cache.get(f"prefs:{user_id}")
        if cached:
            return json.loads(cached)
            
        # Fall back to database
        prefs = UserPreferences.objects.get(user_id=user_id)
        cache.set(f"prefs:{user_id}", prefs.to_json(), ttl=3600)
        return prefs.to_dict()
        
    except UserPreferences.DoesNotExist:
        # Return sensible defaults
        return {
            "theme": "light",
            "notifications": True,
            "language": "en"
        }
    except CacheConnectionError:
        # Continue without cache if it's down
        logger.warning(f"Cache unavailable for user {user_id}")
        try:
            prefs = UserPreferences.objects.get(user_id=user_id)
            return prefs.to_dict()
        except UserPreferences.DoesNotExist:
            return get_default_preferences()
```

---

## Quick Reference

### Decision Matrices

#### Choosing Between Task() and spawn_agent
- Need results before continuing? → Use Task()
- Need independent git branch? → Use spawn_agent  
- Read-only exploration? → Use Task()
- Long-running development? → Use spawn_agent
- Want to avoid context pollution? → Use Task()
- Need to continue other work? → Use spawn_agent

#### Choosing Search Tools
- Know exact pattern? → Use Grep()
- Need file contents? → Use Task() with detailed search prompt
- Looking for files by name? → Use Glob()
- Complex analysis needed? → Use Task() for comprehensive report
- Quick keyword check? → Use Grep() with appropriate flags

#### Choosing File Modification Approach
- New file? → Use Write()
- Small changes? → Use Edit() after Read()
- Multiple changes to one file? → Use MultiEdit()
- Complete file replacement? → Use Write() after Read()
- Adding to file? → Use Edit() with precise context

### Common Command Patterns

#### Git Workflow
```bash
# Check current state
git status
git diff
git log --oneline -10

# Create feature branch
git checkout -b feat/description

# Commit with conventional message
git add .
git commit -m "feat(scope): add new capability"

# Push and create PR
git push -u origin feat/description
```

#### Testing Workflow
```bash
# Python
pytest tests/ -v                    # Run all tests verbosely
pytest tests/test_specific.py::test_function  # Run specific test
pytest --cov=src --cov-report=html  # With coverage

# JavaScript
npm test                            # Run test suite
npm test -- --watch                 # Watch mode
npm test -- path/to/test.spec.js   # Specific file
```

#### Debugging Workflow
```bash
# Find where something is defined
grep -r "class UserService" --include="*.py"

# Check recent changes
git log -p -S "function_name"      # Find when added/removed
git blame path/to/file.py          # See who changed each line

# Explore running processes
ps aux | grep python
lsof -i :8000                      # What's using port 8000
```

### Communication Templates

#### Debugging Report
````
## Issue Description
[What's happening vs what should happen]

## Reproduction Steps
1. [First step]
2. [Second step]
3. [Observe error]

## Investigation
- Checked: [What you looked at]
- Found: [What you discovered]
- Hypothesis: [Your theory]

## Solution
[What fixed it and why]
````

#### Feature Completion Message
````
## Completed: [Feature name]

### What was done:
- [Key change 1]
- [Key change 2]

### How to test:
```bash
[Test commands]
```

### Notes:
- [Important decisions]
- [Known limitations]
````

#### Code Review Request
````
## PR: [Description]

### Changes:
- [File/component]: [What changed and why]
- [File/component]: [What changed and why]

### Testing:
- [How you tested]
- [Test coverage added]

### Review focus:
- [Specific areas needing attention]
````

---

*Document version: 2.1*  
*Enhanced with [IMPORTANT] tags, thinking preservation, and handoff protocols*
*Last updated: 2025-01-10*

*Key changes in v2.1:*
- Added [IMPORTANT] tags for critical points often missed
- Enhanced thinking preservation patterns
- Added handoff protocol for clean agent transitions
- Included "I'm stuck" recognition and protocol
- Added git recovery patterns
- Expanded context budget management
- Added patterns for debugging your own work