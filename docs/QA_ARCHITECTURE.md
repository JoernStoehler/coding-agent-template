# Architecture Clarification Questions

## 1. MCP Server Implementation Details

**Mail System:**
- Storage format: JSON files in `/workspaces/.mail/`? Or SQLite? Or other?
- Message IDs: UUID4, timestamp-based, or sequential?
- Threading: Should we support conversation threads between agents?
- Broadcast: How to handle messages to "all agents" or agent groups?
- Retention: Auto-delete old messages? Archive them? Keep forever?
- Notifications: Should agents get interrupted when receiving mail, or poll?

[Jörn]
- What do you think is simpler to get working, and to maintain?
- UUID4 is enough, can use prefix-matching to avoid typing the full IDs
- No threads, agents can manually set subjects to "Re:"
- No broadcast, manually specify recipients
- Keep forever so we have sth to inspect later for debugging and feature development
- Poll for now; later: "claude hooks" allows gentle push, i.e. no interruptions of atomic, focused work, but insertion after an atomic step is done

**Background Process Manager:**
- Process persistence: Should processes survive container restarts?
- Process ownership: Can agents see/control other agents' processes?
- Log storage: How long to keep process logs? Size limits?
- Auto-restart: Should failed processes restart automatically?
- Resource limits: Memory/CPU limits per process?

[Jörn]
- If easy, surviving restart would be nice, but we can just tell agents after a restart when we start them up again that their background processes are gone (or that they should check at least)
- No security model for now, agents can see + control all processes; they are just told that they are responsible only for their own, and should not mess with others
- I see no size limits, so "forever" is fine, but they also aren't super valuable; if the ai wants to access logs long-term, it has to e.g. run the background process wiht a designed log file itself, e.g. python flask webserver with logging to a file in the worktree that is gitignored
- autostart should be handled by the agent, e.g. instead of "foo" run "foo --autostart" or "foo-script-with-autostart.sh" or similar
- No resource limits for now until we ever encounter performance issues.
- In general, please think about "YAGNI": often we can postpone features until we actually need them, e.g. resource limits, optimizations, security, etc. Let's start simple and iterate.

## 2. File System & Directory Structure

**Worktree naming:**
```
Option A: feat-dashboard, fix-bug-123, add-auth
Option B: agent-001-dashboard, agent-002-bug-123
Option C: 2024-07-03-dashboard, 2024-07-03-bug-123
```
Which pattern? Should we include timestamps, agent IDs, or human-readable names?

[Jörn]
- Option A, task <=> branch <=> worktree <=> agent are matchable by their names

**Agent metadata:**
- Where do we store agent status (active/completed/failed)?
- Should we track agent creation time, last activity, completion time?
- How do we handle "abandoned" agents that never finished?

[Jörn]
- For now, since we use the TUIs, no need to store status, we can just run `ps aux` etc. Maybe write a "list agents" utility script that lists running claude instances and their cwds and start times
- I kill abandoned agents, and then tell the orchestrator to remove the worktree; if the orchestrator wants some agent to stop, it tells me
- So I am kinda the admin, the orchestrator is more of a "central planner", unsure if orchestrator is still the right name for the role?

**Global gitignore:**
- Should `.env` files be ignored by default?
- What about `.agent-id`, `prompt.md`, process logs?
- Should we have agent-specific gitignore patterns?
[Jörn]
- I guess so!
- Also ignore, they don't belong in git, and we don't ever want to transfer agents between HOSTs (or mounted host folders) anyway
- Agents can modify their gitignores, e.g. if they add new tools e.g. latex, but that's still more about the repo than the agent itself.
- If agents do tmp files, they can use a pre-configured tmp/ directory that is gitignored, or the /tmp/ directory, or similar

## 3. Resource Allocation Specifics

**Port allocation:**
- Port range: 3000-3999? 8000-8999? What's safe on your system?
- Allocation strategy: Sequential, random, or hash-based?
- Registry: Central file tracking port usage, or collision detection?
- Host conflicts: How to detect/avoid ports already used on host?

[Jörn]
- No idea, we aren't special. I don't think we need to mount lots of ports onto the host, we just need to have container-internal ports
- Maybe the main branch has its :5000 port bound to the host, so I can view the main branch webserver
- Unsure about the others, I guess we can just YAGNI for now
- Wrt port usage: Bash() commands can inspect which ports are in use, and ".env" lists the local worktree's allocated ports

**Database naming:**
- Pattern: `agent_feat_dashboard`, `db_001`, or random UUIDs?
- Should we use Docker volumes for databases or host mounts?
- Cleanup: Auto-delete unused databases?

[Jörn]
- I am confused what database you are talking about. YAGNI?

**Temporary directories:**
- Pattern: `/tmp/agent-{id}/`, `/workspaces/{agent}/.tmp/`?
- Cleanup: Auto-delete on agent completion?

[Jörn]
- mktmp etc are fine, or if agents need to choose paths, /workspaces/{worktree}/tmp/ is a good idea. ".tmp" is harder to read since it is "hidden", so let's avoid that.
- Cleanup: Since neither tmp is merged, it gets deleted or forgotten once we cleanup the worktree.

## 4. Agent Communication Protocol

**Mail format:**
```json
{
  "id": "msg_20240703_001",
  "from": "orchestrator", 
  "to": ["feat-dashboard-001"],
  "subject": "Task update",
  "body": "Please implement the login form",
  "timestamp": "2024-07-03T10:30:00Z",
  "priority": "normal",  // normal, high, urgent?
  "thread_id": "thread_123",  // optional for threading?
  "read": false,
  "metadata": {  // optional extra data?
    "task_id": "task_123",
    "attachments": ["file1.txt"]
  }
}
```

**Questions:**
- Should we support message priorities (normal/high/urgent)?
- Should we support file attachments (references to files)?
- How do we handle message delivery failures?
- Should we have read receipts or delivery confirmations?

[Jörn]
- YAGNI: no hard-coded priorities etc
- Agents can just reinvent the features the need by e.g. mentioning "urgent" in the subject, or naming absolute file paths to their own worktree in the body
- Good question wrt read receipts! Write that idea down, but postpone for now bc YAGNI, until we do need it

## 5. Docker Configuration Specifics

**Base image:**
- Ubuntu 22.04, Python 3.11, Node 18?
- Or use a dev-focused image like `mcr.microsoft.com/devcontainers/python:3.11`?
- Should we use multi-stage builds for smaller images?

[Jörn]
- I prefer sth with apt-get, python >= 3.12, node >= 20
- No need to optimize for super-small size, we could use "universal:2" as base if necessary, but I also don't think that's beneficial
- Let's just write a Dockerfile that we understand, i.e. a very commonly used base image and/or manual installation of stuff
- We rebuild with cache, so build times are fast enough if we keep the start of the Dockerfile stable

**Tool installation:**
- Which versions: `claude-code`, `gemini-cli`, `git`, `docker`, `curl`?
- Should we pre-install common packages (numpy, requests, etc.)?
- How do we handle agents installing new packages?
[Jörn]
- Latest for claude-code and gemini-cli, latest stable and well known for git, docker, curl, such that you are familiar with the version
- For python: uv sync is fast enough, no need to pre-install in the Dockerfile already
- For node: npm install is fast enough, no need to pre-install in the Dockerfile
- Unsure about others, e.g. maybe we want full latex? YAGNI says not to add latex for this repo, or only as a optional "feature" / commented out with a disclaimer about YAGNI
- Agents can install packages, and should also update thier local git worktree Dockerfile, s.t. after the next merge + rebuild the installed packages are also in the Dockerfile and thus permanently available

**Volume mounts:**
```dockerfile
# These mounts?
-v ~/workspaces:/workspaces
-v ~/.claude:/root/.claude
-v ~/.gemini:/root/.gemini
-v ~/.config/gh:/root/.config/gh
-v ~/.bash_history:/root/.bash_history
```
[Jörn]
- Sounds good, I think we can mount the HOST's folders here; least sure about bash_history bc sensitive secrets (?) Maybe use a named volume for that one instead?
- Ah wait, no, there was some bug/problem with oauth from HOST not being valid in the container; I think we need named volumes for all of those folders! I.e. we cannot use the files from HOST for oauth, sadly
- also: we need container:$USER (e.g. vscode) to chown the mounted folders, iirc docker mounts as root, so pay attention + debug that.

**Network configuration:**
- Should we use host networking or bridge with port mapping?
- Do we need custom DNS resolution?
- Should we restrict outbound network access?

[Jörn]
- You decide
- I am not aware of custom DNS needs?
- Restrictions are a YAGNI security feature

## 6. Git Integration Details

**Worktree management:**
- Base branch: Always `main`, or configurable?
- Merge strategy: Squash commits, preserve history, or rebase?
- Branch naming: `feat/{agent-id}`, `agent/{task-name}`, other?

[Jörn]
- `main` is the current default in the open source community, so let's use that
- I am confused, whatever you think is best!
- feat/{feature-name} or chore/{what-to-do} etc. Descriptive, not opaque ids

**Commit conventions:**
- Should agents follow conventional commits format?
- Auto-commit frequency: After each task, or manual?
- Commit message templates for agents?

[Jörn]
- conventional commits are great for agents!
- frequent commits done by the agents, especially agents shouldn't claim they are done without having committed and tested their work
- no template need, YAGNI

**Conflict resolution:**
- How do we handle merge conflicts between agents?
- Should we have automatic conflict resolution strategies?
- What's the escalation path when agents can't resolve conflicts?

[Jörn]
- Central planner agent handles conflicts one after the other when merging the branches
- YAGNI: just use default strategies for now
- planner agent can worst case ask me for help, or if I also don't know what to do, we have to abandon a branch and start over from the current main branch s.t. merging will be possible

## 7. Security & Isolation

**Container security:**
- Should we run as non-root user inside container?
- Do we need AppArmor/SELinux profiles?
- Should we use seccomp filters?

[Jörn]
- Yes, no idea, no idea

**File system permissions:**
- Should each agent have its own user ID?
- How do we prevent agents from modifying each other's files?
- Should we use bind mounts with specific permissions?

[Jörn]
- No! One user, agents just are different processes. Security is YAGNI

**Network security:**
- Should we block certain outbound connections?
- Do we need to monitor/log network traffic?
- Should we use a firewall or proxy?

[Jörn]
- YAGNI

## 8. Error Handling & Recovery

**Container failures:**
- Should we automatically restart crashed containers?
- How do we preserve agent state across restarts?
- What's the retry strategy for transient failures?

[Jörn]
- YAGNI restarts
- claude has a "-c" option to load the last state of the last agent that ran in the cwd. This is often enough. The history is stored in the `~/.claude/` folder, so that one needs to persist as we already discussed
- not sure what you mean wrt transient failures

**Agent failures:**
- How do we detect when an agent is stuck?
- Should we have timeouts for agent tasks?
- What's the rollback strategy for failed tasks?

[Jörn]
- YAGNI, let's wait for an agent to get stuck or take very long or fail.

**Data corruption:**
- How do we handle corrupted mail files or process metadata?
- Should we have backup/restore mechanisms?
- What's the recovery process for git repository issues?

[Jörn]
- YAGNI, let's wait for an agent/bad luck to corrupt data (?? Pushback?)

## 9. Performance & Monitoring

**Resource monitoring:**
- Should we track CPU/memory usage per agent?
- Do we need disk space monitoring?
- Should we implement rate limiting for API calls?

[Jörn]
- YAGNI

**Logging:**
- Log level: DEBUG, INFO, WARN, ERROR?
- Log rotation: Size-based or time-based?
- Centralized logging: All agents to same file or separate?

[Jörn]
- What do you want to log? I call YAGNI btw

**Metrics:**
- Should we track agent task completion times?
- Do we need success/failure rates?
- Should we monitor system resource usage?

[Jörn]
- YAGNI; claude-code already sends OTLP data, which we should collect with a central otlp collector process that I start manually in a vscode terminal; data is forwarded to Honeycomb.io (eu servers) with my api key; this way I can in the future investigate e.g. agent productivity and tokens/second or $/second api costs etc.
- YAGNI wrt adding more otlp metrics for now, I doubt we need them, but maybe write down that if we ever need to track sth, we can hitchhike the otlp setup we do for monetary accounting already

## 10. Development Workflow

**Testing strategy:**
- Should we have unit tests for MCP servers?
- Integration tests for agent workflows?
- How do we test multi-agent scenarios?

[Jörn]
- Yes-ish; though if the server is very simple an agent can just test it manually
- No-ish, agent workflows are costly to redo constantly, and hopefully not that complex (?)
- No formal testing of multi-agent scenarios, we just frequently do them in practice while working on this or other projects, and so we get feedback that way

**Documentation:**
- What level of detail for agent onboarding docs?
- Should we have video tutorials or just written guides?
- How do we keep docs in sync with code changes?

[Jörn]
- Agents need: high explicitness, low cognitive overhead, commonly known workflows and tools and styles and conventions all work by far better than custom ones; agents start without any context, so all context needs to be provided. They can explore e.g. folders and file contents, but we should streamline the process by telling them where folders are, and which files are relevant for what kind of tasks. Since each agent has a well-scoped task to work on, no agent needs to know everything, so the agent should be offered choices/a "menu" to pick from; i.e. the repo must have commonly known layouts, with descriptive file paths, and explicit documentation about what is where and what conventions apply for develoeprs and users.
- No videos. AI agents deal best with text still, though images have become barely usable.
- We regularly spawn agents that update docs to reflect the actually implemented features better (e.g. looking at git history etc), and ofc each agent is also told to document their work

**Deployment:**
- Should we use Docker Compose for easier setup?
- Do we need migration scripts for version updates?
- How do we handle breaking changes to the infrastructure?

[Jörn]
- docker compose is fine! I know it okayishly
- YAGNI wrt migration
- None of our *infrastructure* data is valuable, not even in other projects, so we can just e.g. delete all old mails when the mail syntax changes
- Othre repos pull/checkout/copy-paste from this repo after we update the "template" infrastructure

## Priority Questions (Please answer first)

1. **What's your preferred port range for agent allocation?**
2. **Docker base image preference and required tool versions?**
3. **Should mail system use JSON files or SQLite?**
4. **Worktree naming convention preference?**
5. **How should we handle agent cleanup and lifecycle?**
6. **What's the merge strategy when agents complete tasks?**
7. **Should we start with manual agent spawning or build automation first?**
8. **What's your tolerance for system complexity vs. features?**

These answers will determine the core architecture and allow us to start implementation. The remaining questions can be addressed iteratively as we build.