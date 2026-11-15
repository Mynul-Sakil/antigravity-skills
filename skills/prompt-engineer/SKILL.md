---
name: prompt-engineer
description: Transforms user prompts into optimized prompts using frameworks (RTF, RISEN, Chain of Thought, RODES, Chain of Density, RACE, RISE, STAR, SOAP, CLEAR, GROW)
version: 1.1.0
author: Eric Andrade
created: 2025-02-01
updated: 2026-02-04
platforms: [github-copilot-cli, claude-code, codex]
category: automation
tags: [prompt-engineering, optimization, frameworks, ai-enhancement]
risk: safe
---

# Prompt Engineer Skill (`prompt-engineer`)

## Purpose

This skill transforms raw, unstructured user prompts into highly optimized prompts using established prompting frameworks. It analyzes user intent, identifies task complexity, and intelligently selects the most appropriate framework(s) to maximize output quality.

The skill operates in "magic mode" - it works silently behind the scenes, only interacting with users when clarification is critically needed. Users receive polished, ready-to-use prompts without technical explanations or framework jargon.

This is a **universal skill** that works in any terminal context, not limited to Obsidian vaults or specific project structures.

## When to Use

Invoke this skill when:

- User provides a vague or generic prompt (e.g., "help me code Python")
- User has a complex idea but struggles to articulate it clearly
- User's prompt lacks structure, context, or specific requirements
- Task requires step-by-step reasoning (debugging, analysis, design)
- User needs a prompt for a specific AI task but doesn't know prompting frameworks
- User wants to improve an existing prompt's effectiveness
- User asks variations of "how do I ask AI to..." or "create a prompt for..."

## Workflow

### Step 1: Analyze Intent

**Objective:** Understand what the user truly wants to accomplish.

**Actions:**

1. Read the raw prompt provided by the user
2. Detect task characteristics:
   - **Type:** coding, writing, analysis, design, learning, planning, decision-making, creative, etc.
   - **Complexity:** simple (one-step), moderate (multi-step), complex (requires reasoning/design)
   - **Clarity:** clear intention vs. ambiguous/vague
   - **Domain:** technical, business, creative, academic, personal, etc.
3. Identify implicit requirements:
   - Does user need examples?
   - Is output format specified?
   - Are there constraints (time, resources, scope)?
   - Is this exploratory or execution-focused?

**Detection Patterns:**

- **Simple tasks:** Short prompts (<50 chars), single verb, no context
- **Complex tasks:** Long prompts (>200 chars), multiple requirements, conditional logic
- **Ambiguous tasks:** Generic verbs ("help", "improve"), missing object/context
- **Structured tasks:** Mentions steps, phases, deliverables, stakeholders

### Step 2: Framework Selection

**Framework Mapping Logic:**

| Task Type                                                   | Recommended Framework(s)                                              | Rationale                                    |
| ----------------------------------------------------------- | --------------------------------------------------------------------- | -------------------------------------------- |
| **Role-based tasks** (act as expert, consultant)            | **RTF** (Role-Task-Format)                                            | Clear role definition + task + output format |
| **Step-by-step reasoning** (debugging, proof, logic)        | **Chain of Thought**                                                  | Encourages explicit reasoning steps          |
| **Structured projects** (multi-phase, deliverables)         | **RISEN** (Role, Instructions, Steps, End goal, Narrowing)            | Comprehensive structure for complex work     |
| **Complex design/analysis** (systems, architecture)         | **RODES** (Role, Objective, Details, Examples, Sense check)           | Balances detail with validation              |
| **Summarization** (compress, synthesize)                    | **Chain of Density**                                                  | Iterative refinement to essential info       |
| **Communication** (reports, presentations, storytelling)    | **RACE** (Role, Audience, Context, Expectation)                       | Audience-aware messaging                     |
| **Investigation/analysis** (research, diagnosis)            | **RISE** (Research, Investigate, Synthesize, Evaluate)                | Systematic analytical approach               |
| **Contextual situations** (problem-solving with background) | **STAR** (Situation, Task, Action, Result)                            | Context-rich problem framing                 |
| **Documentation** (medical, technical, records)             | **SOAP** (Subjective, Objective, Assessment, Plan)                    | Structured information capture               |
| **Goal-setting** (OKRs, objectives, targets)                | **CLEAR** (Collaborative, Limited, Emotional, Appreciable, Refinable) | Goal clarity and actionability               |
| **Coaching/development** (mentoring, growth)                | **GROW** (Goal, Reality, Options, Will)                               | Developmental conversation structure         |

**Blending Strategy:**

- **Combine 2-3 frameworks** when task spans multiple types
- Example: Complex technical project → **RODES + Chain of Thought** (structure + reasoning)
- Example: Leadership decision → **CLEAR + GROW** (goal clarity + development)

**Critical Rule:** Framework selection happens **silently** - do not explain framework choice to user.

### Step 3: Quality Verification & Formatting

**Quality Checks:**

- [ ] Prompt is self-contained (no external context needed)
- [ ] Task is specific and measurable
- [ ] Output format is clear
- [ ] No ambiguous language
- [ ] Appropriate level of detail for task complexity

## Critical Rules

### **NEVER:**

- ❌ Assume information that wasn't provided - ALWAYS ask if critical details are missing
- ❌ Explain which framework was selected or why (magic mode - keep it invisible)
- ❌ Generate generic, one-size-fits-all prompts - always customize to context
- ❌ Ask more than 3 clarifying questions
- ❌ Present output without code block formatting

### **ALWAYS:**

- ✅ Analyze intent before generating
- ✅ Select framework(s) based on task type and complexity
- ✅ Blend multiple frameworks when it improves prompt quality
- ✅ Include output format specification in generated prompts
- ✅ Present final prompt in clean Markdown code block
