# Prompt and Context Engineering for AI Agents

## 1. Context Discovery
- Current AI agents have large context windows of 200k+ tokens. Conciseness has become less critical than other considerations when building up the agents' context.
- Freshly started AI agents are provided with a context that is built from a static system prompt defined by Anthropic, and a project-specific context file called `CLAUDE.md`. `CLAUDE.md` can reference other files with a `@` prefix to autoload them into the context. Normal references `path/to/file` or `[description](path/to/file)` will not be autoloaded.
- As the AI agent works, their context is appended to. It is never truncated or replaced.
- Common agent actions that expand the context include:
  - tool calls, which append both the tool call itself with inputs, and the tool's output
  - text generation by the agent, e.g. to communicate with the user or to think out loud
  - user messages, which are written by the user
- Importantly, the agent can call `Read()` to view entire files, or parts of files, or call `Bash(ls -a)` to list directories. This way the entire repository/filesystem serves as discoverable optional context.
- In order to speed up the agent's work, the discovery of relevant context must be streamlined. This is done by:
  - using `CLAUDE.md` to provide always-important context, usually by including files with `@` references and not by writing directly to `CLAUDE.md`
  - also in other files, we reference must-read files with `@`, and optional further readings as `path/to/file` or `[description](path/to/file)`
  - We provide explanations for when to read other files, e.g. "The configuration is defined in `config.py` and then imported in other modules." or "See `config.py` for the central configuration of the project."
  - We use either long, descriptive file names, e.g. `ces_production_functions.py`, or standard, well-known file names, e.g. `config.py`, to make it intuitive and simple to find the right files and decide for/against reading them.
  - We use a consistent, discoverable folder structure, e.g. `src/`, `tests/`, `docs/`, etc., again putting files in their standard, intuitive location.
  - Similarly, symbol names need to be either long and descriptive, e.g. `ces_production(capital, labor, sigma)`, `test_ces_production_returns_to_scale()`, or standard, well-known, e.g. `main()`
  - Agents use `Pattern()` and `Grep()` and `Bash(grep)` to search for files. We optimize for these search tools by using unique keywords, and avoiding name collisions where sensible.
- Agents are themselves able to update the documentation of the project, inside markdown but also inside code comments. If agents discover useful further readings that were not yet linked to in some location, they can add these links to help future agents discover them faster and more reliably. Similarly, obsolete or irrelevant links can be removed.

## 2. Clarity and Explicitness
- The context of AI agents is only appended-to, and remains available to the agent for every single action. Essentially, the agent has memorized everything it has read during a session verbatim.
- This is a vastly larger working memory than any human developer has, and we want to make use of the agents' vast working memory.
- On the other hand, unlike humans, AI agents do not automatically store the thoughts and implications they inferred from their context for the rest of the session. This means that either agents have to constantly re-infer and re-think about context (which is inefficient), or they have to be given a chance to explicitly store their inferences and implications for later use.
- The best way to do this is to simply encourage AI agents to think out loud and note important inferences and implications they found. In particular, corrections, and pointing out their own mistakes or mistakes made by the writers of the context files, are very important to note, as otherwise in the future agents may forget that some idea was already flagged as incorrect, or that some bug was already noticed and handled.
- Furthermore, to avoid putting cognitive load on the agents, we should just spell out all implications and inferences that we want the agents to make in the first place. This way, they needn't re-infer them, and needn't record them, since we already did that for them.
- This is in fact the most important consideration of prompt and context engineering: Clarity and Explicitness. If all our static and autoloaded and optional context is written in a clear, unambiguous, explicit, broken-down and spelled-out manner, then AI agents can read blazingly fast through the context without needing to record inferences, and they make use of it immediately for every single step of their work since all knowledge is readily available due to their perfect memory.
- TODO: Provide instructions on how to write clear and explicit.
- TODO: make sure this entire most-important section is written in a clear and explicit manner.

## 3. Associative Memory
- AI agents can remember verbatim what they have read, but it is also important to remember the right snippet of information at the right time.
- We can help agents with this by making associative links more clear and explicit. This makes the associate links more available/stronger for the agents, leading to a faster/higher recall rate.
- The fundamental pattern is to spell out what knowledge is relevant in some context or situation, since the "context => knowledge" direction is more important than the other way around.
- Unlike human developers, who have a drastically limited working memory, we can store many more associations in the agents' context. The hurdle for spelling out precisely which knowledge is relevant when is thus far lower, and we should take advantage of this.
- Common ways to make associations more explicit include:
  - Use structured text, e.g. with headings, bullet lists, paragraphs, and simple spatial proximity within the file. This groups related information together. 
  - Headings and paragraph sentences can define the context/situation, e.g. by naming a topic. If the agent considers the topic, it will then also recall the knowledge from the associated paragraph.
  - If-then sentences also create strong associations, e.g. "If you need to implement a mathematical function from a paper, make sure to write a docstring that matches math symbols to Python symbols."
  - Nested headings also work, e.g. `# Troubleshooting`, `## Tool Invocation Errors`, `### Bash Tool`, `### Environment Misconfiguration`, ...
  - Nested headings then apply to all children, e.g. an agent who is troubleshooting, will remember to check with `env` whether environment variables aren't set, without having to explicitly think through the steps Troubleshooting => Tool Invocation Errors => Environment Misconfiguration first.
  - Identical or similar phrases, and phrases with similar/related semantics, also create associations accross the context. We can make use of this by using such phrases when defining a context or when stating some knowledge, for example we can use a excerpt of a error message to associate some piece of knowledge with situations where this particular error message occurs. Similarly we can use code symbols, file names, headings and quotes that associate with situations where the quoted file has been included in the context, and so on.
  - Examples that show the application of some fact, e.g. the invocation of a tool or the adherence to some programming pattern, also create associations.
- The rules of Clarity and Explicitness also apply here: We should spell out the associations we want the agents to make, we should spell out the context that knowledge should be recalled in, etc. We needn't tell the agent directly to recall a particular piece of knowledge, but only because the instruction "recall X" is empty, since if an agent remembers the instruction, they already remember the knowledge X as well.
- In essence, we use associative patterns such as headings, bullet lists, if-then sentences, and relevant phrases/keywords/symbols to strengthen recall of relevant knowledge at the right time.

## 4. Actionable Instructions
- We must apply the principles of Clarity, Explicitness, and Associative Context to goal-definitions or action instructions.
- In particular, we should make sure that goals are clearly defined. A way to make goals clearer, or ensure that they are clear already, is to ask ourselves if the goal is
  - unambiguous, i.e. avoids concepts that aren't properly narrowed down to a single meaning (up to details we don't care about, e.g. we may not care about what exact implementation the agent uses, as long as the interface is correct)
  - complete, i.e. does not omit important aspects that an agent would need to know / ask about while working on the goal
  - actionable, i.e. can be broken down into smaller steps that the agent can actually take
  - measurable, i.e. there is a (spelled-out) way for the agent to know if the goal has been achieved, and ideally already how much progress has been made towards the goal
  - context-aware, i.e. the goal is defined within a larger context, that the agent can consult in case we failed to be complete or unambiguous
  - recoverable, i.e. there are recovery procedures the agents can use if e.g. errors happen, a problem is unexpectedly beyond the agent's capabilities, or even outside the agent's control/scope
  - documented, i.e. the goal is written down persistently such that the agent can consult and annotate it. Usually the context window is sufficient, i.e. a user message or loud thinking are persistent already, but writing down the goal as a file can also help, especially if delegating to subagents or asking other agents/the user for feedback and help. Recovery and measurement often require documentation as well, since reviewers or error handlers need to access the goal definition.
- Modern AI agents are quite capable, and they are in particular able to adapt their own (sub-)goals if a larger context/goal is provided for them. This means that we can make suggestions, leave clearly stated open questions, or even ask for pushback on the goal itself in case it is ambiguously stated or ill-advised. Examples in clear, explicit, associative language can include
  - "Before you start planning how to carry out the goal, please check if you understood the goal, and if you have any questions, please ask them now."
  - "One suggested way to split the config is XYZ. We suggest this way simply because it is standard and came to mind first. If you find a simpler, or more maintainable way, please feel free to use that instead."
  - "We are unsure if the goal is achievable, since we may not have enough tools for network debugging setup yet. If that's the case, please don't try to setup the network debugging, but report back so that we can dedicate a full agent and more resources to this task."
  - "The current implementation may be bugged, since we did not test it exhaustively. If you find bugs, please don't hotfix them, but report them back and leave them as is, or investigate and fix the root cause. Hotfixes tend to hide other bugs, which is why we should avoid them."

## 5. Subagents and Agent-Agent Communication
- Agents are capable of spawning new agents and delegating to agents.
- The important types of agents are
  - Task() subagents, which work in the same working directory as the parent agent, but have their own context window.
  - claude-code agents, which are spawned via the `mcp__project_spawn_agent` tool, and which have their own git worktree.
- After spawning one or multiple Task() subagents, the parent agent sleeps until all subagents have finished and reported back.
- Spawned claude-code agents have independent lifetimes, and the spawning agent can continue working.
- All claude-code agents can communicate with each other via the `mcp__project_send_message` tools.
- Task() subagents are most suitable for tasks that 
  - block the parent agent
  - are read-only
  - that require a lot of context but produce a far smaller deliverable
  - that are short enough to be completed within minutes
  - that do not require any iterations or feedback, since the subagent is deconstructed after reporting back its first and only result
- claude-code agents are most suitable for tasks that 
  - are not blocking the parent agent, i.e. where the parent agent can continue working
  - are write-heavy, e.g. produce an entire commit or PR
  - are lengthier in duration
  - need iterative feedback where the child agent retains its highly useful context until the parent agent explicitly deconstructs it
- The rules of prompt- and context-engineering apply when communicating and spawning subagents, and are of great importance.
- In particular, communication must be clear and explicit. Since subagents, parent agents, and agents have their own independent context, they are not aware of what other agents are thinking and doing. They must be explicitly provided with information and further context about their work. This applies especially for the initial prompt specified in Task(), and the deliverable returned by the Task() subagent, since no iterated interrogation is possible.
- The same applies to the `mcp__project_send_message` tool, which is used to communicate between claude-code agents. The message must be clear and explicit, and it must contain all relevant context for the receiving agent to understand the message. A useful, intuitive, high-information messaging format is to write the message content to be like a cold mail, or a github issue. This way it is intuitively clear that the receiving agent is not expected to know anything about the sender besides the messaging thread and linked resources therein.

## 6. Tool Definitions
- Special care should be taken when providing tools for the agent, since often the correct usage of tools is not obvious.
- A common trick is to use standard tools wherever possible, i.e. tools that are well-known to many senior developers and that have had a stable interface for years.
- For example, agents are able to use many common bash tools perfectly, such as `ls, grep, jq, rg, sed, git, gh, ...`. 
- Agents are also trained to use their built-in tools, such as `Bash(), Task(), Grep(), ...`.
- For custom tools, detailed instructions need to be provided, and the knowledge of common tool usage patterns must be leveraged. Custom tools should
  - ideally use the MCP protocol, which directly enforces syntactically correct tool calls, e.g. types of parameters.
  - provide clear, explicit usage instructions in the tool docstrings or in docs/ files about the tool.
  - provide examples if necessary to make the usage even more explicit and associative.
  - use well-known data formats, e.g. cli-like file paths that are then expanded in a shell, or JSON objects that are similar to well-known APIs.
  - custom tools should also provide an extended, longer help text for troubleshooting, which contains implementation details, assumptions about the environment and context, and so on. Usually the source code of the tool is a good place for this, e.g. as a file docstring or as a comment header.
- When considering to make a new tool, make sure to
  - Clarify what functionalities you have needed, what functionalities you (partially) have available already, and what functionalities you imagine you will need in the future.
  - Check if there are common well-known tools that provide (some) aspects of the desired functionality and whether that's enough for your use case, since building and using a tool adds notable overhead.
  - Consider if you can use a very common tool-pattern, such as a shell script, or a Makefile command, or a stand-alone python script (e.g. with uv and pep 723).

## 7. Style and Convention Definitions
- TBD

## 8. Web Search and External Sources
- TBD

## 9. Self-Improvement and Learning
- TBD

## 10. Agent-User Interaction
- TBD

## 11. Agile Software Development for Agents
- TBD
- RFCs, ADRs, PRDs, CHANGELOGs, Kanban boards, ...
- SCRUM
- Agile: drop and delete, since agents are cheap

## 12. Miscellaneous Best Practices

### CLAUDE.md

### Files and Folders

### Python Code

### Markdown Text

### Bash Scripts

### Recommended Architectures

### Microservices

### Custom Tools

### 