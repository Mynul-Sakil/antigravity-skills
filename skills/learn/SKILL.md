---
name: learn
description: "Extract reusable patterns, debugging breakthroughs, and architectural lessons from the current session, score quality across 5 dimensions, and save to Project or Global skills (including full SKILL.md + references packaging)."
---

# Session Learning & Skill Extraction (`/learn`)

Capture non-obvious, reusable engineering insights from the active session, evaluate them rigorously before saving, and persist them in the right scope so future sessions never repeat the same investigation.

## Workflow

### Step 1: Identify High-Signal Candidates

Scan the session for:
1. **Non-obvious debugging root causes** (misleading symptoms, race conditions, environment quirks)
2. **Framework/library workarounds** (version-specific API gotchas, configuration invariants)
3. **Project-specific conventions** (architecture boundaries, build/test commands, migration steps)
4. **Tooling & integration patterns** that took multiple attempts to get right

*Skip trivial typos, standard language syntax, or one-off throwaway incidents.*

### Step 2: 5-Dimension Self-Evaluation Gate (Rubric Score >= 3.5/5 Required)

Before writing any file, grade the extracted draft honestly (1–5) on five axes:

| Dimension | Question | Minimum |
| :--- | :--- | :---: |
| **1. Specificity** | Contains concrete file paths, commands, or code snippets rather than vague platitudes? | `3/5` |
| **2. Actionability** | Gives a clear Trigger -> Action -> Verification sequence? | `4/5` |
| **3. Scope Fit** | Correctly classified as Project-only vs Globally reusable? | `3/5` |
| **4. Non-Redundancy** | Checked existing skills/rules so we update rather than duplicate? | `3/5` |
| **5. Completeness** | Self-contained without relying on ephemeral chat history? | `3/5` |

If any dimension misses its minimum, refine the draft (up to 2 passes) before asking to save.

### Step 3: Choose Save Scope & Format

| Signal | Recommended Target | Format |
| :--- | :--- | :--- |
| Applies only to this repository's architecture/scripts | **Project** (`.agents/skills/<slug>/SKILL.md` or `.claude/skills/<slug>/SKILL.md`) | Focused `SKILL.md` |
| Applies across repositories in the same language/stack | **Global** (`~/.gemini/config/skills/<slug>/SKILL.md` or `~/.claude/skills/learned/<slug>/SKILL.md`) | Focused `SKILL.md` |
| Rich multi-step workflow with templates/checklists (`/extract`) | Standalone skill directory (`<slug>/SKILL.md` + `references/` + `scripts/`) | Full Skill Package |

### Step 4: Draft Structure & Confirm

Every extracted `SKILL.md` must include valid YAML frontmatter (`name`, trigger-rich `description` under 250 chars) and structured sections:
- **Context & Trigger Conditions** (exact symptoms, error messages, or user intents)
- **Root Cause / Why It Happens**
- **Step-by-Step Solution** (concrete commands/code)
- **Verification & Edge Cases**

Present the proposed path, scope rationale, 5-dimension rubric table, and draft content to the user for confirmation before writing.
