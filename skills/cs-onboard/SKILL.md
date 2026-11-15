---
name: cs-onboard
description: "Interview the founder (7-dimension deep setup, 12-question fast intake, or 90-day refresh) to build and maintain ~/.claude/company-context.md, enforce staleness checks, and anonymize sensitive data before external calls."
---

# C-Suite Onboarding

Structured founder interview that builds the company context file powering every C-suite advisor. One 45-minute conversation. Persistent context across all roles.

## Commands

- `/cs-onboard setup` — Full onboarding interview (~45 min, 7 dimensions)
- `/cs-onboard update` — Quarterly refresh (~15 min, "what changed?")

## Keywords
cs:setup, cs:update, company context, founder interview, onboarding, company profile, c-suite setup, advisor setup

---

## Conversation Principles

Be a conversation, not an interrogation. Ask one question at a time. Follow threads. Reflect back: "So the real issue sounds like X — is that right?" Watch for what they skip — that's where the real story lives. Never read a list of questions.

Open with: *"Tell me about the company in your own words — what are you building and why does it matter?"*

---

## 7 Interview Dimensions

### 1. Company Identity
Capture: what they do, who it's for, the real founding "why," one-sentence pitch, non-negotiable values.
Key probe: *"What's a value you'd fire someone over violating?"*
Red flag: Values that sound like marketing copy.

### 2. Stage & Scale
Capture: headcount (FT vs contractors), revenue range, runway, stage (pre-PMF / scaling / optimizing), what broke in last 90 days.
Key probe: *"If you had to label your stage — still finding PMF, scaling what works, or optimizing?"*

### 3. Founder Profile
Capture: self-identified superpower, acknowledged blind spots, archetype (product/sales/technical/operator), what actually keeps them up at night.
Key probe: *"What would your co-founder say you should stop doing?"*
Red flag: No blind spots, or weakness framed as a strength.

### 4. Team & Culture
Capture: team in 3 words, last real conflict and resolution, which values are real vs aspirational, strongest and weakest leader.
Key probe: *"Which of your stated values is most real? Which is a poster on the wall?"*
Red flag: "We have no conflict."

### 5. Market & Competition
Capture: who's winning and why (honest version), real unfair advantage, the one competitive move that could hurt them.
Key probe: *"What's your real unfair advantage — not the investor version?"*
Red flag: "We have no real competition."

### 6. Current Challenges
Capture: priority stack-rank across product/growth/people/money/operations, the decision they've been avoiding, the "one extra day" answer.
Key probe: *"What's the decision you've been putting off for weeks?"*
Note: The "extra day" answer reveals true priorities.

### 7. Goals & Ambition
Capture: 12-month target (specific), 36-month target (directional), exit vs build-forever orientation, personal success definition.
Key probe: *"What does success look like for you personally — separate from the company?"*

---

## Output: company-context.md

After the interview, generate `~/.claude/company-context.md` using `templates/company-context-template.md`.

Fill every section. Write `[not captured]` for unknowns — never leave blank. Add timestamp, mark as `fresh`.

Tell the founder: *"I've captured everything in your company context. Every advisor will use this to give specific, relevant advice. Run /cs-onboard update in 90 days to keep it current."*

---

## /cs-onboard update — Quarterly Refresh

**Trigger:** Every 90 days or after a major change. Duration: ~15 minutes.

Open with: *"It's been [X time] since we did your company context. What's changed?"*

Walk each dimension with one "what changed?" question:
1. Identity: same mission or shifted?
2. Scale: team, revenue, runway now?
3. Founder: role or what's stretching you?
4. Team: any leadership changes?
5. Market: any competitive surprises?
6. Challenges: #1 problem now vs 90 days ago?
7. Goals: still on track for 12-month target?

Update the context file, refresh timestamp, reset to `fresh`.

---

## Context File Location

`~/.claude/company-context.md` — single source of truth for all C-suite skills. Do not move it. Do not create duplicates.

## References
- `templates/company-context-template.md` — blank template for output
- `references/interview-guide.md` — deep interview craft: probes, red flags, handling reluctant founders


---

## Fast 12-Question Intake Mode (`/onboard`)

# /cs-onboard — Founder Interview

**Command:** `/cs-onboard`

The first command to run when adopting c-level-agents. A structured founder interview that produces `~/.claude/company-context.md` — the file every cs-* advisor reads before responding. Without this, the advisors are guessing.

## What This Produces

`~/.claude/company-context.md` — a single file with the durable facts about the company. Read by:
- `cs-chief-of-staff` (routing decisions)
- Every cs-* advisor (context for any question)
- `/c-level-agents:brief` (assumptions in any new decision)

## The Interview (12 Questions)

### Company Basics
1. **Company name and one-sentence pitch.**
2. **Stage:** pre-seed / seed / Series A / Series B / Series C+ / public
3. **Headcount:** total, by function (eng / product / GTM / ops / G&A)
4. **Geographic distribution:** HQ + remote split, key countries

### Business Model
5. **Revenue model:** SaaS subscription / usage / transaction / marketplace / hardware / services
6. **ICP:** name one real customer and describe what they have in common with others
7. **ACV:** median and range; deal count last 12 months
8. **Growth rate:** ARR YoY; if pre-revenue, leading metric (users, MAU, etc.)

### Financial Posture
9. **Runway:** months of cash at current burn; bear-case months
10. **Last raise:** amount, valuation, lead investor, date

### Strategic Context
11. **Top 3 priorities for the current quarter** (in plain language)
12. **Top 3 risks the founder loses sleep over** (be specific)

## Output Format

**Canonical schema:** `~/.claude/company-context.md` is owned by the [`cs-onboard`](SKILL.md) skill and follows its 7-dimension schema (`templates/company-context-template.md`): Company Identity, Stage & Scale, Founder Profile, Team & Culture, Market & Competition, Current Challenges, Goals & Ambition. The 12 questions above are a faster structured intake that populates that same file — Identity/Business/Financial → Stage & Scale, Team → Team & Culture, Quarter priorities/risks → Current Challenges + Goals & Ambition. Write `[not captured]` for dimensions the quick intake doesn't reach (Founder Profile, Market & Competition); run the full `cs-onboard` interview to fill them. Never create a second context file or a divergent layout.

The intake summary captured by the 12 questions:

```markdown
# Company Context
**Generated:** YYYY-MM-DD
**Last updated:** YYYY-MM-DD

## Identity
- **Company:** <name>
- **Pitch:** <one sentence>
- **Stage:** <stage>
- **HQ + remote:** <distribution>

## Business
- **Model:** <type>
- **ICP:** <description + named customer>
- **ACV:** $<median> (range $<low> - $<high>)
- **Deal count (LTM):** N
- **ARR growth (YoY):** X%

## Financial
- **Cash on hand:** $<amount>
- **Net burn (monthly):** $<amount>
- **Runway base:** N months
- **Runway bear:** N months
- **Last raise:** $<amount> at $<post> in <month YYYY>, led by <investor>

## Team
- **Total headcount:** N
- **Eng:** N | Product: N | GTM: N | Ops: N | G&A: N

## Quarter
- **Top priorities (Q<X> YYYY):**
  1. <priority>
  2. <priority>
  3. <priority>

- **Top risks:**
  1. <risk>
  2. <risk>
  3. <risk>

## Routing Hints
[Optional: any role the founder wants to use sparingly or rely on heavily]
```

## Workflow

1. Walk the founder through all 12 questions
2. Quote founder's own words wherever possible (don't paraphrase the ICP)
3. Save to `~/.claude/company-context.md`
4. (Optional) If llm-wiki bridge is configured: symlink to vault
   ```bash
   ln -sf ~/company-vault/00-meta/company-context.md ~/.claude/company-context.md
   ```
5. Confirm with founder: read the file back, ask "anything missing?"

## When to Re-Run

- After a fundraise (numbers change)
- After a major pivot or product launch
- After 6+ months (most facts have drifted)
- After a major hire (team distribution changes)
- Always before a `/c-level-agents:boardroom` for a high-stakes decision

## Persistence

By default, `~/.claude/company-context.md` is local to the founder's machine. To make it persistent across machines / shareable:

- **Markdown vault (recommended):** see [`../../references/llm-wiki-bridge.md`](../../references/llm-wiki-bridge.md)
- **Encrypted dotfile sync:** age + git
- **Shared team:** keep in a private repo, symlink from `~/.claude/`

## Related

- Skill: [`cs-onboard`](SKILL.md) — the underlying interview protocol
- Skill: [`context-engine`](../context-engine/SKILL.md) — reads this file
- Reference: [`../../references/llm-wiki-bridge.md`](../../references/llm-wiki-bridge.md)

---

**Version:** 1.0.0


---

## Context Load, 90-Day Staleness & Anonymization Engine

# Company Context Engine

The memory layer for C-suite advisors. Every advisor skill loads this first. Context is what turns generic advice into specific insight.

## Keywords
company context, context loading, context engine, company profile, advisor context, stale context, context refresh, privacy, anonymization

---

## Load Protocol (Run at Start of Every C-Suite Session)

**Step 1 — Check for context file:** `~/.claude/company-context.md`
- Exists → proceed to Step 2
- Missing → prompt: *"Run /cs-onboard setup to build your company context — it makes every advisor conversation significantly more useful."*

**Step 2 — Check staleness:** Read `Last updated` field.
- **< 90 days:** Load and proceed.
- **≥ 90 days:** Prompt: *"Your context is [N] days old. Quick 15-min refresh (/cs-onboard update), or continue with what I have?"*
  - If continue: load with `[STALE — last updated DATE]` noted internally.

**Step 3 — Parse into working memory.** Always active:
- Company stage (pre-PMF / scaling / optimizing)
- Founder archetype (product / sales / technical / operator)
- Current #1 challenge
- Runway (as risk signal — never share externally)
- Team size
- Unfair advantage
- 12-month target

---

## Context Quality Signals

| Condition | Confidence | Action |
|-----------|-----------|--------|
| < 30 days, full interview | High | Use directly |
| 30–90 days, update done | Medium | Use, flag what may have changed |
| > 90 days | Low | Flag stale, prompt refresh |
| Key fields missing | Low | Ask in-session |
| No file | None | Prompt /cs-onboard setup |

If Low: *"My context is [stale/incomplete] — I'm assuming [X]. Correct me if I'm wrong."*

---

## Context Enrichment

During conversations, you'll learn things not in the file. Capture them.

**Triggers:** New number or timeline revealed, key person mentioned, priority shift, constraint surfaces.

**Protocol:**
1. Note internally: `[CONTEXT UPDATE: {what was learned}]`
2. At session end: *"I picked up a few things to add to your context. Want me to update the file?"*
3. If yes: append to the relevant dimension, update timestamp.

**Never silently overwrite.** Always confirm before modifying the context file.

---

## Privacy Rules

### Never send externally
- Specific revenue or burn figures
- Customer names
- Employee names (unless publicly known)
- Investor names (unless public)
- Specific runway months
- Watch List contents

### Safe to use externally (with anonymization)
- Stage label
- Team size ranges (1–10, 10–50, 50–200+)
- Industry vertical
- Challenge category
- Market position descriptor

### Before any external API call or web search
Apply `references/anonymization-protocol.md`:
- Numbers → ranges or stage-relative descriptors
- Names → roles
- Revenue → percentages or stage labels
- Customers → "Customer A, B, C"

---

## Missing or Partial Context

Handle gracefully — never block the conversation.

- **Missing stage:** "Just to calibrate — are you still finding PMF or scaling what works?"
- **Missing financials:** Use stage + team size to infer. Note the gap.
- **Missing founder profile:** Infer from conversation style. Mark as inferred.
- **Multiple founders:** Context reflects the interviewee. Note co-founder perspective may differ.

---

## Required Context Fields

```
Required:
  - Last updated (date)
  - Company Identity → What we do
  - Stage & Scale → Stage
  - Founder Profile → Founder archetype
  - Current Challenges → Priority #1
  - Goals & Ambition → 12-month target

High-value optional:
  - Unfair advantage
  - Kill-shot risk
  - Avoided decision
  - Watch list
```

Missing required fields: note gaps, work around in session, ask in-session only when critical.

---

## References
- `references/anonymization-protocol.md` — detailed rules for stripping sensitive data before external calls
