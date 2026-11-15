---
name: prompt-engineer
description: "Transform rough prompts using 11 structured frameworks (RTF, RISEN, CoT, RODES, RACE, STAR) AND run eval-gated LLM prompt optimization, RAG groundedness scoring, and agent config validation via Python CLI tools."
---

## Choosing the Right Mode

- **Mode 1 — Fast Prompt Crafting:** User wants a vague or complex request turned into a clean, ready-to-paste prompt (uses the 11 frameworks below).
- **Mode 2 — Production Eval, RAG & Agent Tuning:** User is debugging unreliable production prompts, measuring token/clarity baselines, scoring RAG retrieval faithfulness, or validating agent YAML/JSON configs (`scripts/prompt_optimizer.py`, `scripts/rag_evaluator.py`, `scripts/agent_orchestrator.py`).

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


---

## Production Eval-Gated Optimization, RAG & Agent Tooling

# Senior Prompt Engineer

Eval-driven prompt engineering, RAG quality measurement, and agent workflow validation. Everything here is **model-agnostic by design**: techniques are framed by what they do, not by which model generation they were observed on, and the tools never hardcode model IDs or pricing — you supply your provider's current rates when you want dollar figures.

## Operating Rules

1. **Never change a prompt without a baseline.** Capture metrics first (`--analyze --output baseline.json`), then compare every iteration against it.
2. **Eval set before optimization.** 10–20 representative cases with expected outputs minimum. If the user has no eval set, build one with them before touching the prompt — optimizing against vibes is the #1 failure mode.
3. **Prefer platform features over prompt hacks.** If the provider offers native structured outputs / JSON schema enforcement, tool-use APIs, or prompt caching, use those instead of "respond ONLY with JSON" incantations. Prompt-level format enforcement is the fallback, not the default.
4. **Current-generation models need less scaffolding.** Don't add chain-of-thought boilerplate, role framing, or few-shot examples reflexively — frontier models often do worse with redundant scaffolding. Add each element only when the eval set shows it helps.
5. **Cost numbers are always user-supplied.** Look up the provider's current per-Mtok pricing and pass it via `--price-per-mtok` (never trust a cached price table — including any you remember).

## Tools (exact CLIs, all stdlib)

### 1. Prompt Optimizer — `scripts/prompt_optimizer.py`

Static analysis: token estimate, clarity/structure scores (0–100), ambiguity + redundancy detection, few-shot example extraction.

```bash
# Full analysis (human-readable report)
python3 scripts/prompt_optimizer.py prompt.txt --analyze

# Save machine-readable baseline for later comparison
python3 scripts/prompt_optimizer.py prompt.txt --analyze --json --output baseline.json

# Token estimate; cost only if you supply your provider's current rate
python3 scripts/prompt_optimizer.py prompt.txt --tokens --model claude --price-per-mtok 3.00

# Whitespace/redundancy-trimmed version
python3 scripts/prompt_optimizer.py prompt.txt --optimize --output optimized.txt

# Extract Input/Output few-shot pairs to JSON
python3 scripts/prompt_optimizer.py prompt.txt --extract-examples --output examples.json

# Compare a revision against the saved baseline
python3 scripts/prompt_optimizer.py optimized.txt --analyze --compare baseline.json
```

`--model` accepts any string; only the tokenizer family is inferred (names containing "claude" → 3.5 chars/token, otherwise 4.0). Exit 0 on success, 1 on missing file.

### 2. RAG Evaluator — `scripts/rag_evaluator.py`

Measures retrieval and grounding quality from two JSON files (formats printed in `--help`).

```bash
python3 scripts/rag_evaluator.py --contexts retrieved.json --questions eval_set.json
python3 scripts/rag_evaluator.py --contexts ctx.json --questions q.json --k 10 --json
python3 scripts/rag_evaluator.py --contexts ctx.json --questions q.json --output report.json --verbose
python3 scripts/rag_evaluator.py --contexts ctx.json --questions q.json --compare baseline_report.json
```

Reports context relevance, precision@k, coverage, answer faithfulness, groundedness. Treat relevance < 0.80 as a retrieval problem (chunking/embedding/filtering), not a prompt problem — fix retrieval before rewriting the generation prompt.

### 3. Agent Orchestrator — `scripts/agent_orchestrator.py`

Validates agent configs (YAML/JSON): tool wiring, missing required config, loop risk, token estimates.

```bash
python3 scripts/agent_orchestrator.py agent.yaml --validate
python3 scripts/agent_orchestrator.py agent.yaml --visualize --format mermaid
python3 scripts/agent_orchestrator.py agent.yaml --estimate-cost --runs 100 \
    --input-price-per-mtok 3.00 --output-price-per-mtok 15.00
```

Without the two price flags, `--estimate-cost` reports token estimates only. The `model:` field in the config is informational — any model name is accepted.

## Workflows

### Prompt Optimization (eval-gated)

1. **Baseline:** `python3 scripts/prompt_optimizer.py current_prompt.txt --analyze --json --output baseline.json`
2. **Diagnose** from the report: ambiguous verbs ("analyze", "handle"), redundant blocks, missing output contract, token waste.
3. **Apply one change at a time**, in this order of leverage:
   | Symptom | Fix |
   |---------|-----|
   | Malformed/unparseable output | Native structured outputs / JSON schema if the API supports it; explicit schema-in-prompt otherwise |
   | Inconsistent answers across runs | Tighten instructions + add 2–3 contrastive examples (one near-miss showing what NOT to do) |
   | Misses edge cases | Enumerate the edge cases explicitly; add a "when uncertain, do X" rule |
   | Token bloat on repeated calls | Move stable prefix (system rules, examples) first so prompt caching applies; trim redundancy |
   | Wrong reasoning on hard cases | Ask for stepwise reasoning *in a scratch field the consumer ignores*, or use the provider's extended-thinking mode |
4. **Re-analyze and compare:** `python3 scripts/prompt_optimizer.py revised.txt --analyze --compare baseline.json`
5. **Eval gate (must pass before shipping):** run the revised prompt over the eval set, write per-case pass/fail to `eval_results.json`, then assert:
   ```bash
   python3 scripts/prompt_optimizer.py revised.txt --analyze --json --output revised.json \
     && python3 -c "
   import json, sys
   r = json.load(open('revised.json')); b = json.load(open('baseline.json'))
   ok = r['clarity_score'] >= b['clarity_score'] and r['token_count'] <= b['token_count'] * 1.10
   sys.exit(0 if ok else 1)"
   echo "gate exit=$?"   # 0 = ship; 1 = regression, iterate again
   ```
   Pair this structural gate with your task-level eval: the revision must not lose any previously-passing eval case (no-regression rule).

### Few-Shot Example Design

1. Define the task contract first (input shape, output shape, edge-case policy).
2. Start with **zero examples** and measure — current models often need none. Add examples only for failure clusters the eval reveals.
3. When adding: 3–5 max, ordered simple → edge → negative (what NOT to extract), formatted identically to the real output contract.
4. Validate consistency: `python3 scripts/prompt_optimizer.py prompt_with_examples.txt --extract-examples --output examples.json` and inspect that every extracted pair parses against your schema.
5. Re-run the eval set; if a case passes only because it resembles an example, add a held-out variant to the eval set.

### Structured Output Design

1. Write the JSON Schema first (types, enums, required, maxLength).
2. **Prefer API-native enforcement**: structured-outputs / response-schema / tool-call parameters guarantee shape; prompt text cannot.
3. Fallback (API without schema support): include the schema rendered as field-by-field rules + one valid example, and instruct "output only the JSON object".
4. Gate: pipe 10 eval outputs through a schema validator (`python3 -c "import json,sys; [json.loads(l) for l in sys.stdin]"` at minimum); 10/10 must parse, else return to step 2.

### RAG Tuning Loop

1. Build `questions.json` (id, question, reference answer) and capture current retrievals to `contexts.json`.
2. `python3 scripts/rag_evaluator.py --contexts contexts.json --questions questions.json --output rag_baseline.json`
3. Fix the **lowest metric first**: relevance → chunking/embeddings/metadata filters; faithfulness → grounding instructions + "answer only from context" + citation requirement; coverage → retrieval k / query expansion.
4. Gate: `python3 scripts/rag_evaluator.py --contexts new_contexts.json --questions questions.json --compare rag_baseline.json` — every metric must be ≥ baseline; any regression blocks the change.

### Agent Config Review

1. `python3 scripts/agent_orchestrator.py agent.yaml --validate` — must exit with VALIDATION PASSED; fix every error and warning (missing tool config, unbounded iterations, loop risk).
2. Check context discipline: each tool description ≤ 1–2 sentences, tool count minimal for the job, stable system prompt placed first (cache-friendly), iteration cap + early-exit condition present.
3. Budget: `--estimate-cost --runs N` with your current prices; if cost/run exceeds budget, cut tools or context before downgrading the model.

## References

| File | Contains | Load when user asks about |
|------|----------|---------------------------|
| `references/prompt_engineering_patterns.md` | 10 prompt patterns with input/output examples | "which pattern?", few-shot design, decomposition, meta-prompting |
| `references/llm_evaluation_frameworks.md` | Eval metrics, scoring methods, A/B testing | "how to evaluate?", "measure quality", "compare prompts" |
| `references/agentic_system_design.md` | Agent architectures (ReAct, Plan-Execute, Tool Use) | "build agent", "tool calling", "multi-agent" |

## Related Skills

- `engineering-team/skills/senior-ml-engineer` — model deployment and serving (this skill stops at the prompt/eval layer)
- `engineering/rag-architect` — RAG system architecture (this skill measures RAG quality; that one designs the pipeline)
- `engineering/agent-designer` — full agent system design (this skill validates configs; that one designs the architecture)
