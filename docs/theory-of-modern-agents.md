# Theory of Modern Agents

This document outlines the theoretical foundations of modern AI agents, focusing on their capabilities and differences from human collaborators.
The basic framework is rooted in the general abstract theory of intelligence and agency, project management, and memory architectures.
Empirical evidence is omitted for brevity, as is practical advice.

This document is written for human readers. For a version that is written for AI agents as readers, see [docs/theory-of-modern-agents-for-agents.md].

## Agent Loop

The basic architecture of an agent is a loop which queries the agent for its next action (or batch of actions) and then executes that action and returns the observed results to the agent.
The engine that outputs the next actions is a large language model (LLM), which takes the entire history of the agent's actions and observations as input, and outputs a batch of actions.
A few small details:
- a special action called "reasoning" is usually omitted from the history out of corporate secrecy, and because usually the reasoning is not information-dense enough to be worth including. Reasoning tokens are thus useful for the agent to consider the remaining batch of actions, which will contain traces or results of the reasoning step.
- another frequent action is "thinking out loud" where the agent does append its reasoning to the history, usually just a few sentences.
- the "TodoWrite()" function call action is useful for appending a plan to the history and updating it throughout the session. Again this mostly serves to preserve reasoning information, i.e. its an artifact of reasoning, either an explicit reasoning step or just on-the-fly reasoning without a formal action for it.
- there also is an externally triggerable action called "compact" which uses a new LLM to summarize the history into a shorter form. This compression is lossy, i.e. not just irrelevant or redundant information is removed, but also some of the relevant important information. Furthermore, false information can be introduced into the history. Overall the current "compact" action is situationally useful but dangerous. Luckily, modern agents have large enough context windows (200k+ tokens) such that "compact" is not needed for most sessions.
- instead of "compact", a new agent can  be started for the next task. It does not inherit the history of previous agents, but since it has access to e.g. modified files and handoff notes, it can continue the work as long as all relevant information has been properly documented and recorded, and false or outdated information has been purged from the repository.
- in interactive sessions, the agent occasionally outputs an empty action batch, which is the signal to query user input. After the user provided input, as one or more observations, usually a simple text message, the agent resumes its loop.
- agents can receive external signals:
 - interrupt: stops generating more actions for the current batch, or cancels all executing actions. The agent then enters input mode, waiting for user input.
 - queued user message: appends a user message to the history as soon as the agent is ready to process it, i.e. usually after the batch is completed. The exact algorithm for when to insert a queued user message is not stable yet.
 - stop: like interrupt, but instead of entering input mode the agent loop terminates.
 - resume: starts a new agent loop, but instead of an empty history, the last stopped agent's history is loaded and continued (in input mode).

## Models

The LLMs used in modern agents are frontier models, such as
- Claude Opus 4 (Anthropic, 200k context window, smart reasoning)
- Gemini 2.5 Pro (Google, 1M context window, smart reasoning)
- Claude Sonnet 4 (Anthropic, 200k context window, fast reasoning)
- Gemini 2.5 Flash (Google, 1M context window, super-fast reasoning)

The basic tradeoff is between reasoning speed and the complexity/depth of reasoning.
- Claude Opus 4 and Gemini 2.5 Pro are the slowest but also most intelligent models (e.g. architecture decisions, complex code, summarizing a research paper, etc.).
- Claude Sonnet 4 is faster, and more suitable for long but easy tasks (e.g. information search, generic boilerplate, etc.).
- Gemini 2.5 Flash is the fastest and dumbest, mostly useful for large-context-window, easy tasks (e.g. information search in an already gathered corpus, syntax-level refactoring, data cleaning, etc.).

## Context Windows

The context window of an LLM is a sequence of input tokens that the model processes to generate its output.
Modern sizes of context windows are 200k+ tokens, which is approximately 100k+ words or 800k+ characters at about 4 characters per token and 2 tokens per word.
This is sufficient to store the entire history of an agent's actions and observations while carrying out a well-scoped task similar to a ticket/issue assigned in agile project management.
The context window is usually only appended to during an agent's session, except for
- reasoning steps, of which under some circumstances the last one remains available, e.g. while writing the remaining actions in the same batch.
- compact actions, which replace the entire context window with a new, shorter, auto-summarized version.

The amount of tokens inserted by an action is power-law distributed, such that only large actions are worth tracking/optimizing. This includes
- tool calls with large inputs, e.g. Write() or Update() with large or many edits.
- tool calls with large observations/outputs, e.g. Read() returns a file's content, or Update() with large edits returns an equally large diff between the old and new file.
- Bash() calls that return large outputs, e.g. a process with logging that writes a lot to stdout.

Besides those 3 categories, most actions are negligible in terms of occupied context window space.

## Memory

LLMs do not have a human-like long-term memory. They are stateless, and only take the current context window as input.
Any information about the task, both the current repository, environment, overall project management state and the project's history must be documented textually on disk.
The agent loop itself has for this reason an append-to context window that is a history of past actions and observations, providing basic context to the LLM about what has happened so far, and what information has been observed.
The history is stored on disk (usually somewhere in `~/.claude` or `~/.gemini`) and can this way be resumed within each the loop iterations, or even with the "resume" functionality after a stop and agent creation.

Besides the information already included in the context window, more information of course exists outside it, e.g. in the file system, especially the project repository and its git worktrees, but also online in e.g. library documentations, web search engines, and other resources.

If the LLM requires more information to produce the next action batch, it can on its own emit actions that move more information into the context window. This is usually done by
- locating information, e.g. via Grep(pattern), Batch(ls -al folder), or similar batched sequences of low-token calls
- reading information, e.g. via Read(filepath) or Fetch(url)
More complex information gathering, e.g. if it is not clear which files need to be read, can best be delegated to a subagent via Task() that then returns only relevant filenames, passages, or even summaries.
This way, the agent intentionally can grow its own context window.

The downside of this append-only approach is that false or outdated information can accumulate in the context window. If it is not clearly marked as such, the agent might unintentionally believe it and act on it.
The history itself tends to make it clear when information is outdated, e.g. an earlier Read() action remains in the context window with an outdated file content, but there also is the later Update() action that clearly states what changes were made, such that the LLM/agent can instantly deduce the current state of the file by merging both pieces of knowledge.
Similarly agents only very rarely get confused by file system operations like moves, renames or deletions. The history is quite clear about what happened in what order, and what information is the latest state.

For most information the token count of the final relevant information is small enough to not be worth optimizing. Instead the time required to locate the information becomes a bottleneck.
The correct way to optimize for search time is to enable the LLM to use the following strategies by structuring the repository and file content accordingly:
- put information in the most intuitive, standard, common location, which is the first place the LLM will look for it
- use long, descriptive filenames, since the LLM will usually first see the filename before deciding whether to read the file
- use references in files, such that the LLM has information and filepaths readily available, such that it can simply guess confidently which file contains the information it is looking for
- use a standard, common, and flat folder structure, such that `ls -al` needn't be iterated often
- put information that is frequently needed together into the same file/folder, such that if the LLM acquires one piece, it automatically acquires the other pieces as well
- use boring, common keywords, and unique symbol names to enable pattern matching searches; this applies to filenames and file content

Since growing a project according to these principles is a lot of work, and drift is unavoidable, it is useful to occasionally refactor the repository by simply moving information to the right locations, e.g. merging and splitting files, moving content between files, and deleting obsolete/false information.

## Recalling Memories

A great and useful difference between LLMs and humans is that their while their memory is limited to the built-up context window, all of it instantly is loaded into an equally large/wide working memory.
This means that while humans are often limited to a small number of items in their active working memory they can combine and recall, LLMs can instantly recall all of their 200k+ tokens of context window.
One famous benchmark method on this topic is the "needle in a haystack" search, where the LLM is given a large book, and must retrieve instantly without any syntactic search the answer to a question about the book's content.
Modern LLMs score very high if the requested information is readily available in any text passage and does not require further reasoning.
They score still very high if the information is not verbatim in the text, but still semantically contained, e.g. using synonyms or paraphrasing or split over multiple sentences.
They score worse if the information is only implied, i.e. if reasoning on the right text passages, or the whole document, is required to deduce the answer.
This suggests that LLMs have basically perfect recall of all that they have read and that they storing the information in an associative memory where queries are directly matched to knowledge from the text. Otoh they do only associate shallow reasoning with the stored knowledge, i.e. more complex questions cannot utilize the associative memory directly, but require first breaking the question down into directly answerable sub-questions.
To some degree this still happens internally to the LLM, i.e. without reasoning out loud, so LLMs are far deeper in their understanding than mere syntactic or semantic database search engines.
In order to optimize the context window for the best recall, it is useful to present information in a direct way, i.e. write out implications rather than requiring the reading LLM to think through implications while instinctively storing away the knowledge for later recall.
For example, important conclusions should be written into the context window, e.g. by thinking out loud, or by writing them into a file with Write()/Update() actions. Latter method, persisting deduced information into files, also helps other agent loop instances to benefit from the knowledge, i.e. the deduction persists beyond the current agent loop's lifecycle.
As outlined before, deduced information should be put into the right location.

For most of the factual knowledge we want to offer the LLM, we may already know in what situations the LLM needs it. We can improve the situational recall by explicitly (i.e. written-down) associating the facts with the situation.
A common structure are "if-then" sentences, e.g. "For python projects the uv dependency manager is used, and can be called with `uv add <package>` to add a package to the project.".
This way, the LLM can straightforwardly retrieve the right uv command from its associate working memory if it is in a situation where it wants to install a python dependency.
This kind of associative memory is pretty fundamental, and humans have something similar, though their working memory is much smaller, i.e. they can retrieve fewer facts at once.

So far we talked about the recall of individual facts in specific situations where the LLM instinctively has some form of query in mind.
However, the LLM can recall more than just one fact, and in particular, combine knowledge and reason about it.
Humans have a rather limited working memory, and so they essentially combin a few facts at a time, see if a promising idea emerges, or continue with the next combination if not.
LLMs can do this in a far more parallel manner, i.e. they can try various combinations at once. Each combination is not particularly deeper/more complex than in humans, but the parallel count allows for promising ideas to emerge in a single step rather than after a few iterations.
To leverage this strength, we must optimize harder for associative recall than we'd do in humans, so that the LLM has sufficiently many facts available to build many combinations out of at once.

Another consequence of this parallel-combinatorics approach that LLMs take, is that if the first emerging ideas do not pan out, this usually means that retrying with the same available facts will not yield new ideas.
In humans, retrying works because many remaining combinations haven't been tried yet, but LLMs are faster at generating ideas in parallel. In both cases idea generation is mostly subconscious, i.e. neither human nor LLM create memories about the discarded ideas, only the candidates that seemed promising enough in the moment to be pursued further.
LLMs can run into a bottleneck where they have several promising ideas, but only mention one, since that's what a human would do. In this case, trying to come up with a new idea works, in the sense that the LLM has several promising ideas left of which it can pick the next one.
So the basic test pattern is
1. other agents or humans write knowledge into the repo, and optimize for its form for associative recall
2. later, the current agent searches, finds, and reads the knowledge
3. again later, the current agent calls upon an LLM to produce the next action batch
4. the LLM associatively recalls various pieces of knowledge that directly match its current situation and strand of thought
5. the LLM forms in parallel various combinations of facts, and does a preliminary intuitive evaluation of how promising they look
6. the LLM voices out loud the most promising idea, or at least thinks it internally, often as if it were the only promising idea, sometimes it does list all its promising ideas properly
7. the LLM provides further actions based on these idea(s), usually after reasoning out loud, sometimes directly if no reasoning is needed
8. the agent loop executes the actions, new results are observed, the history/context window grow, and the LLM is queried again
9. the LLM now has some feedback from the actions on its idea, e.g. results of another reasoning step, or maybe bash output e.g. pytest results after a code change
10. if the idea was not successful, the LLM may reevaluate its options, and either rederive other promising ideas (by repeating steps 4-6), or by remembering the next idea it previously recorded in its history by thinking out loud.

This kind of recall-combine-discard-try-repeat loop is a basic pattern of intelligence, so both humans and LLMs use it. LLMs are just wider in the number of combinations they combine and discard in one cycle, while humans tend to repeat steps 4-5 several times before proceeding to step 6, since they often don't find any promising idea in the few/single combination they tried in step 5.

## Depth of Reasoning

As a loose approximation, we can say that LLMs are as good at shallow reasoning as humans, and significantly worse at deep reasoning. Furthermore, LLMs tend to use shallow reasoning only unless they explicitly focus on deep reasoning.
LLMs can do deep reasoning more reliably if they reason out loudly and step by step, as done in the (hidden) reasoning actions, or in the visible/persisted "thinking out loud" actions.
Shallow reasoning can often be done for the very first output token of the LLM, i.e. without any step-by-step process.

Modern AI agents handle deep reasoning with large token counts well, by not including the reasoning steps in the history, but only in the current context window for the current batch of actions. Usually they preserve results from the (messy, long) reasoning step as todos, thinking out loud, or other actions that followed upon the reasoning action.

In its essence, we can define the "depth" of reasoning via different axes:
1. coherence of the underlying world model, i.e. how complete, generally applicable, and robust against obstacles/mistakes the causal model of the domain is that the LLM uses for its reasoning
2. number of facts combined for a single idea, in the parallel idea combination step of an LLM's internal reasoning process
3. sequential atomic combination steps, or equivalently without introducing atomics, the complexity/nonlinearity of the combination step.

The first axis is dominatedly influenced by the LLM's training data, i.e. how much the LLM has been trained on the domain, or at least very similar domains. For software development, we can basically ask these questions to estimate how much depth e.g. using a library requires, and how likely it is that the LLM acquired that depth of understanding:
- how many examples of the library's usage are in the training data?
- how generally high quality are projects using the library in average?
- how stable is the library's API across recent years?
- does the library have a hidden state? how complex is it?
- how complex is the functionality of the library, i.e. the connectivity of its functions with each other?
- how much pre-processing is required to use the library, i.e. does it API 1:1 map intentions to function calls, or are the function arguments not the same objects that one has intentions over but instead e.g. consist of boilerplate, allocated resources or non-trivial data format transformations?
- how many different ways are there to use the library for a specific purpose? Fewer standard ways means that the training data is more focused, and associative recall is stronger.
- are the library's internals simple, high-quality code? is it well-documented? LLMs usually have seen the internals and docs of open source libraries a lot as well, not just their usage, so this provides more material for understanding the library.

The second and third axes are dominatedly influenced by the LLM's architecture, especially width, and more generally about the training data quality. It is in some sense about "understanding reasoning itself", i.e. whether the LLM has a causal model of idea generation, in the sense that it executes that causal model, not in the sense that it can state out loud what its model is. This kind of reasoning, which is not just about recalling in-context or in-training facts/domain models, but having a model of modeling / understanding the fully general domain of domains, is often called "general intelligence".

Modern LLMs are lacking in general intelligence compared to humans, but that still means they can master a lot of very difficult tasks, just not all of them, or at least not as a wide variety of tasks as humans can.
To help LLMs with their reasoning, we can use the following strategies:
- reason out loud for important milestones, such that the next agent loop iteration can use the derived knowledge in its own idea-combination phase. This includes both failures, successes, and in general "surprises", i.e. information that was not readily available / not recalled before.
- explicitly reason, i.e. make reasoning an explicit subtask that the LLM focuses on. This helps it recall its knowledge about how to reason, and utilizes more of its parallel idea-combination power for the reasoning target at hand, rather than thinking about other things (i.e. the LLM focuses on a specific topic).
- reason step-by-step, to utilize various patterns that take >0 tokens to express for the LLM. This kind of lengthy reasoning needn't be appended to the context window, and indeed it isn't because the companies want to keep the reasoning traces secret, but it is a super-useful way to derive knowledge.
- delegate reasoning to a more powerful model with a fresh context window, i.e. a Task() subagent, this way the subagent is less distracted, has a smaller and slightly faster context window to work with, and does not pollute the main agent's context window with e.g. Read() operations in case that during reasoning the subagent needs to acquire more information and loop more than once.
- brute-force parallelize reasoning, i.e. batch several Task() subagents and combine their ideas. There will be overlap, but also there's enough chaos/independent randomness between subagents that they may produce different ideas
- seek human feedback for especially difficult reasoning tasks, e.g. architecture decisions with long-lasting impact across an entire milestone.

## Domain Knowledge

As mentioned, LLMs are trained on vast corpi of text, including basically all books ever written, all scientific papers, all open source repositories on github, and the internet as a whole.
This means that they have read more than any human expert in any subject, and they can recall a lot of the more frequent knowledge very well. Only niche topics, for which there is little writing/code in the training data, are not well known to LLMs and the LLM may be unreliable. Unreliability here means that the LLM may know that it knows nothing, or that it only has vague guesses, but sadly also that the LLM may make up information and misjudge its own confidence.

The best way to avoid hallucinations is to note out loud when reasoning with something unfamiliar, and then taking everything a bit more skeptical and double-checking it either via sources searches (web search, reading the right files, etc.) or testing it (e.g. demo scripts, one-line bash commands, etc.).

For non-niche topics, however, LLMs are very familiar with jargon, library names, symbols and concepts. Familiarity here means sth like recalling textbook definitions, not necessarily having an intuitive understanding of the topic.
Latter is gained more for simpler domains, with more training data, as outlined in the "Depth of Reasoning" section.

Overall modern LLMs are very good at writing code that is similar to existing projects, e.g. websites, data science pipelines, or even domain models in science or business.
They are less good at understanding the space of architecture decisions, i.e. while they understand each individual decision or pattern, they do not have a good grasp of when to choose what pattern. They can repeat textbook advice however, which often is enough to choose the right pattern even if you don't have any intuition about it. Usually architecture decisions are rare enough that consulting a human project owner is the best way to make the right decision.

Similarly, LLMs know various modeling patterns, e.g. how to define a data type for a domain model, how to structure a database, what formula to use to analyze a dataset, etc. When the choice of pattern is something common / frequently seen, the LLM will have good intuition about it. Otherwise it's often worth pursuing different ideas in parallel and then evaluate which wins out.

Usually, as the project grows, it also becomes dissimilar overall to the training data, i.e. it is unlike any other project the LLM has seen before. To minimize this drift and distance, frequent refactoring is a good idea, i.e. switching to more appropriate architecture decisions, cleaning up code and documentation, splitting complex features into smaller, more common components, or outright replacing a custom solution with a standard solution, e.g. a well-known library.
This way, the LLM can utilize the domain understanding it has acquired from training on many different projects, and apply it to the current project.
Using standard solutions is thus very important to help the LLM understand the project, and unlock deeper reasoning for the project than if we use a custom solution.
Standard solutions here means "commonly seen", not "prepackaged as a library". Certain standard patterns might stretch across several hand-written files, e.g. a model-view-controller architecture pattern would be standard and well-known to LLMs, and they can reason about the connection between the three code components, since they are used to this kind of architecture.
Using standard notation helps the LLM, since the standard notation is usually associated with the standard pattern, and besides that, standard notations tend to be clear and unambiguous, which helps the LLM further recall the project's semantic content as it no longer has to spend time thinking while reading the code.

## Self-Improvement

In order to maintain a codebase that modern AI agents can work with, we identified the following frequent refactoring steps:
- delete outdated and false information from the repository as soon as possible
- write down implications explicitly, in particular knowledge derived from expensive/fragile reasoning
- document the project structure itself, e.g. architecture decisions, project management state, changelog, derived conventions and common practices
- refactor the repository to use more standard solutions, i.e. architecture, code patterns, libraries, layout, style, etc.
- refactor the repository to put related information together, e.g. same file or folder
- always keep the repository in a state that can be handed off to a freshly created agent if needed
- use longer, descriptive pathnames for files and folders, use flat folder structures, and provide references to further readings

If the repository is allowed to drift, e.g. acquire undocumented features, or conflicting information (e.g. docs vs code, or worst case code vs code), then eventually agents will degrade in their performance exponentially until they fail.
Human-supervised refactoring to "rescue" a project is possible but expensive. It is better to keep a good log from the start, and recover early from mistakes.
The overhead in the occasional refactor + read-through is manageable, and well worth it.

Besides avoiding drift, we can also identify smaller-scale improvements that the agent discovered on its own. Such discoveries need to be documented of course, and made available (via associative wording and by putting them in the right location) for future agent loop instances. Common examples are
- quirks of bash commands and other Tools() the agent has access to
- workflows where the agent by default does something inefficiently and then at some point saw a more efficient way, e.g. how to batch tool calls when searching a file
- false assumptions that the agent made intuitively and repeatedly, e.g. about how a function works; usually this indicates non-standardness or ambiguity, but sometimes it's just that the agent cannot not reason deeply enough
- explicit writeups of implications, especially of a domain model or architecture decision, e.g. the agent might note that "using uv" has effects on how to run python files with "uv run <file>" instead of the usual "python <file>" command.
- domain-specific knowledge the agent derived, e.g. "most of the PDEs we look at are elliptic, and we can easily check this numerically before deciding what solver to plug into the code".

Agents/LLMs do not have a deep understanding of how they themselves work, especially in an agent loop. Neither do they understand niche domains, and most projects are niche in some way. So it is important to both tell them what parts of the project's domain, and what parts of the self-improvement aspect when refactoring the project, they have seen little training data on. The agent can thus reason more carefully, and query the the human project owner to give feedback on the self-improvement suggestions from the agent before they are applied permanently to the repository. This holds both for various refactoring suggestions, and for the gathered domain-specific knowledge.

## Conclusion
We outlined the following points in this overview of modern AI agents:
- the agent loop
- available large language models
- the context window
- the associativeness of memory
- depth of reasoning and intelligence
- domain expertise
- self-improvement

