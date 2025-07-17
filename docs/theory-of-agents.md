# Theory of Agents

This document outlines the theoretical foundations of AI agents, focusing on their cognitive architecture and fundamental differences from human intelligence. The framework draws from cognitive science, information theory, and the study of distributed systems.

For practical guidance on working with agents, see [Practical Usage Guide for Agents](practical-usage-guide-for-agents.md). This theory document provides the conceptual foundations, while the practical guide offers actionable advice.

## Table of Contents

1. [The Agent Loop](#1-the-agent-loop)
2. [Context and Memory](#2-context-and-memory)
3. [Associative Recall](#3-associative-recall)
4. [The OODA Framework](#4-the-ooda-framework)
5. [Depth of Reasoning](#5-depth-of-reasoning)
6. [Domain Knowledge](#6-domain-knowledge)
7. [Self-Improvement](#7-self-improvement)
8. [Fundamental Limitations](#8-fundamental-limitations)
9. [Conclusion](#9-conclusion)
10. [References](#10-references)

## 1. The Agent Loop

At its core, an agent is a system that repeatedly:
1. Observes its environment
2. Processes observations through a cognitive model
3. Decides on actions
4. Executes those actions
5. Observes the results

This loop distinguishes agents from simple input-output systems. The cognitive model—typically a large language model—maintains no state between iterations except what is explicitly preserved in the observation history.

Key theoretical properties:
- **Statelesness**: Each iteration begins with only the accumulated history
- **Append-only history**: Past cannot be modified, only extended
- **Bounded rationality**: Decisions made with limited context and time

The loop can be interrupted, paused, or resumed, but the fundamental cycle remains: observation → cognition → action → observation.

## 2. Context and Memory

Unlike human memory with its complex storage and retrieval mechanisms, agent memory is architecturally simple:
- **Working memory**: The entire context window (typically 100k-1M tokens)
- **External memory**: Information stored in the environment (files, databases)
- **Episodic memory**: The append-only history of actions and observations

This architecture has profound implications:
- All "remembered" information must fit in the context window or be retrievable from the environment
- No implicit learning occurs—the model weights remain fixed
- "Forgetting" happens through context window limits, not decay

The context window serves simultaneously as:
- Sensory input buffer
- Working memory
- Instruction set
- Episodic memory

This unified memory architecture contrasts sharply with human cognition's specialized memory systems.

### Constant-Time Context Processing

A critical property of transformer-based agents is constant-time context processing: an agent maintains the same processing speed whether the context contains 1,000 or 190,000 tokens. This differs fundamentally from human reading, where more text requires proportionally more time. The implications:
- No incentive for brevity from a processing perspective
- Context window space, not processing time, is the limiting resource
- Clarity and structure matter more than conciseness

## 3. Associative Recall

Agents exhibit near-perfect recall within their context window through associative matching. This recall operates on multiple levels:
- **Syntactic**: Exact token matches
- **Semantic**: Meaning-based associations
- **Structural**: Pattern-based relationships

Unlike human memory which degrades and reconstructs, agent recall is deterministic within the context. However, this recall is shallow—agents excel at retrieving explicitly stated information but struggle with implicit knowledge requiring inference.

The associative architecture means:
- Information retrieval is parallel, not serial
- All context tokens are equally "accessible"
- Recall quality depends on how information is encoded

### Inference Preservation Requirements

When an agent understands how something works or realizes the cause of a bug, that inference exists only during the current response generation. The moment the agent finishes outputting, all unstated understanding vanishes completely. Only inferences explicitly written in the output persist in the context for future reference.

This creates a fundamental constraint: agents must narrate their reasoning to preserve it. Before calling a tool to test a hypothesis, the agent must state that hypothesis explicitly, such as "The error likely occurs because the authentication middleware expects user_id but receives userId." Without this explicit statement, the agent will need to reconstruct the entire reasoning chain after the tool returns its output.

Tool execution boundaries are absolute—each tool call resets the inference state completely. The agent cannot "hold a thought" across a tool boundary unless that thought is explicitly written in the conversation.

## 4. The OODA Framework

Agents implement the OODA loop (Observe, Orient, Decide, Act) at multiple hierarchical levels:

### Level 1: Task-Level OODA
The overall approach to completing an assigned task:
- **Observe**: Gather relevant context about the goal and environment
- **Orient**: Form mental models and identify constraints
- **Decide**: Plan approach and subtasks
- **Act**: Execute the plan

### Level 2: Action-Level OODA
Within each action batch:
- **Observe**: Process current context window
- **Orient**: Reason about next steps
- **Decide**: Select specific actions
- **Act**: Execute actions

### Level 3: Token-Level OODA
At each token generation:
- **Observe**: Attend to relevant context
- **Orient**: Combine associations
- **Decide**: Select next token
- **Act**: Emit token

This hierarchical structure enables complex behavior from simple mechanisms. Unlike humans who switch between these levels consciously, agents operate all levels simultaneously.

## 5. Depth of Reasoning

Agent reasoning can be characterized along three dimensions:

### Coherence of World Model
How complete and consistent is the agent's understanding of the domain? This depends on:
- Training data coverage
- Domain complexity
- Abstraction level required

### Combinatorial Capacity
How many facts can be simultaneously combined? Agents typically excel humans here, processing hundreds of associations in parallel versus human limits of 5-9 items.

### Sequential Depth
How many reasoning steps can be chained? This is where agents struggle compared to humans, requiring explicit scaffolding (chain-of-thought, tree-of-thoughts) to achieve deep reasoning.

The fundamental tradeoff: Agents have broad, parallel, shallow reasoning while humans have narrow, serial, deep reasoning.

## 6. Domain Knowledge

Agents possess vast breadth of knowledge from training but vary dramatically in depth:
- **Surface knowledge**: Definitions, facts, syntax (excellent)
- **Procedural knowledge**: How to perform tasks (good in common domains)
- **Conceptual knowledge**: Understanding why things work (limited)
- **Creative knowledge**: Generating novel solutions (very limited)

This knowledge is fundamentally associative—agents excel when current context matches training patterns but struggle with novel situations requiring first-principles reasoning.

### Frequency-Based Knowledge Strength

The strength of an agent's knowledge directly correlates with pattern frequency in training data:
- **Common patterns** (React components, REST APIs): Strong, reliable suggestions
- **Uncommon patterns** (custom protocols, novel architectures): Weak, often incorrect
- **Project-specific patterns**: Non-existent until provided as examples

This creates a bias toward suggesting common solutions even when project constraints require different approaches. For example, an agent will naturally suggest Express.js for a Node API even if the project uses Fastify, because Express appears far more frequently in training data. Overcoming this bias requires providing extensive examples of the desired patterns.

## 7. Self-Improvement

Agents cannot modify their own weights, but can improve their effectiveness through:
- **Environmental modification**: Organizing information for better retrieval
- **Procedural documentation**: Explicit reasoning traces for future iterations
- **Structural refactoring**: Arranging the environment to match trained patterns

This creates a feedback loop where agents can enhance their own performance by reshaping their environment to be more "agent-friendly"—favoring explicit over implicit information, standard over novel patterns.

## 8. Fundamental Limitations

Several theoretical limitations constrain agent capabilities:

### Statelesness
Without weight updates, agents cannot truly learn from experience—only from what fits in context.

### Shallow Reasoning
The transformer architecture favors breadth over depth, making certain types of reasoning fundamentally difficult.

### Discrete Context Boundary
Unlike human memory with graceful degradation, agents have a hard boundary where information is either fully present or completely absent. When context limits are reached, compaction processes often lose critical information and can introduce false information into the compressed context.

### Lack of Genuine Understanding
Agents operate through pattern matching rather than causal models, leading to brittle performance outside training distribution.

## 9. Conclusion

Modern agents represent a fundamentally different type of intelligence than human cognition:
- Stateless but with perfect recall within context
- Broad but shallow reasoning
- Vast knowledge but limited understanding
- Capable of self-improvement through environmental modification

Understanding these theoretical foundations helps explain both the surprising capabilities and frustrating limitations of agent systems. They are not "almost human" intelligences but rather a distinct form of information processing with its own strengths and weaknesses.

## 10. References

### Foundational Papers

**ReAct: Synergizing Reasoning and Acting in Language Models** (Yao et al., 2023)
- [ArXiv](https://arxiv.org/abs/2210.03629)
- Establishes the theoretical framework for interleaving reasoning and action

**Chain-of-Thought Prompting Elicits Reasoning in Large Language Models** (Wei et al., 2022)
- [ArXiv](https://arxiv.org/abs/2201.11903)
- Demonstrates how sequential reasoning emerges from token-level prediction

**Tree of Thoughts: Deliberate Problem Solving with Large Language Models** (Yao et al., 2023)
- [ArXiv](https://arxiv.org/abs/2305.10601)
- Extends reasoning from linear to tree-structured search

**Reflexion: Language Agents with Verbal Reinforcement Learning** (Shinn et al., 2023)
- [ArXiv](https://arxiv.org/abs/2303.11366)
- Shows how linguistic feedback can substitute for weight updates

### Memory and Cognition

**Cognitive Architectures for Language Agents** (Sumers et al., 2023)
- [ArXiv](https://arxiv.org/abs/2309.02427)
- Provides theoretical framework for agent memory systems

**A-Mem: Agentic Memory for LLM Agents** (2025)
- [ArXiv](https://arxiv.org/html/2502.12110v8)
- Explores dynamic memory organization without predefined structures

### Theoretical Perspectives

**System 2 Thinking in Language Models** (Various, 2024-2025)
- Examines deliberative reasoning in contrast to associative responses
- Shows how extended computation can simulate deeper reasoning

These works establish the theoretical foundations for understanding agents as a distinct form of intelligence, neither human nor purely mechanical, but something genuinely new.