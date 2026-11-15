---
name: c-level-agents
description: "Virtual C-suite executive router and Founder-Mode dispatcher: automatically routes founder strategy questions to the right C-level advisor (CFO, CTO, CMO, CPO, CRO, COO, CHRO, CISO, GC, CAIO, CDO, CCO, VPE, CEO) or convenes a multi-role /boardroom."
---

# /c-level-agents:founder-mode — The Auto-Router

**Command:** `/c-level-agents:founder-mode <question>`

The single command a founder needs to remember. Routes the question to the right C-role automatically, or triggers `/c-level-agents:boardroom` if multi-role.

This is the **killer command** — the answer to "I don't know which slash command to use." Type the question; the system figures out the room.

## Routing Logic

The router (via `cs-chief-of-staff`) does keyword + intent matching:

| Signal in question | Route |
|---|---|
| burn, runway, fundraise, dilution, model, LTV, CAC | `cs-cfo-advisor` |
| pipeline, win rate, forecast, quota, ramp, sales motion | `cs-cro-advisor` |
| positioning, ICP, message, brand, channel, campaign | `cs-cmo-advisor` |
| roadmap, PMF, JTBD, North Star, RICE, kill | `cs-cpo-advisor` |
| cadence, OKR, scorecard, DRI, operating system, rhythm | `cs-coo-advisor` |
| hiring, comp, ladder, level, attrition, eNPS, equity | `cs-chro-advisor` |
| security, threat, breach, compliance, audit, SOC 2 | `cs-ciso-advisor` |
| architecture, scaling, tech debt, SLO, latency | `cs-cto-advisor` |
| contract, IP, term sheet, regulator, license | `cs-general-counsel-advisor` |
| retention, GRR, NRR, churn, customer success, CSM, time-to-value, renewals | `cs-cco-advisor` |
| training data, data rights, consent, data asset, warehouse, lakehouse, data mesh | `cs-cdo-advisor` |
| model selection, eval, hallucination, AI risk, EU AI Act, fine-tune, build vs buy AI | `cs-caio-advisor` |
| DORA, cycle time, deploy frequency, eng hiring funnel, team topology, delivery throughput | `cs-vpe-advisor` |
| strategy, vision, board, M&A, raise, exit | `cs-ceo-advisor` |
| **2+ signals from different roles** | `/c-level-agents:boardroom` |
| **ambiguous** | `/c-level-agents:office-hours` first, then route |

## Workflow

1. Parse the question for role signals
2. If exactly one role: invoke that cs-* agent directly
3. If 2+ roles: build a brief via `/c-level-agents:brief` and trigger `/c-level-agents:boardroom`
4. If ambiguous / no signal match: trigger `/c-level-agents:office-hours` to force the founder to sharpen
5. Log the routing decision (raw layer) via `decision-logger`

## Output

The router emits one of three responses:

### Single-role route
```
**Routing:** cs-cfo-advisor
**Why:** Question hits burn rate and unit economics.
**Next:** Invoking cs-cfo-advisor with company-context loaded.

[Advisor's response follows]
```

### Multi-role route
```
**Routing:** /c-level-agents:boardroom
**Why:** Question touches CFO + CMO + CPO (pricing change has finance, positioning, and product implications).
**Next:** Building brief via /c-level-agents:brief, then running boardroom.

Brief saved: ~/.claude/briefs/2026-05-12-pricing-v3.md
Run: /c-level-agents:boardroom ~/.claude/briefs/2026-05-12-pricing-v3.md
```

### Ambiguous → office hours
```
**Routing:** /c-level-agents:office-hours
**Why:** Question is too broad ("should we grow faster?"). Need framing before any advisor can help.
**Next:** Six-question intake.

[Office hours questions follow]
```

## Why This Is the Killer Command

gstack requires the founder to know all 23 slash commands and pick the right one. That's a cognitive tax. `/c-level-agents:founder-mode` collapses that to one — the system picks. This is also where persistent memory pays off: with company-context.md + decision-logger, the router knows what's already been decided and won't re-litigate.

## Examples

```
/c-level-agents:founder-mode "should we raise a Series B now or wait 6 months?"
   → boardroom (CFO + CEO + CRO touched)

/c-level-agents:founder-mode "the win rate dropped 20% this month"
   → cs-cro-advisor

/c-level-agents:founder-mode "gross retention dropped 5 points this quarter"
   → cs-cco-advisor

/c-level-agents:founder-mode "let's hire a VP Marketing"
   → boardroom (CHRO + CMO + CFO touched)

/c-level-agents:founder-mode "should we be growing faster?"
   → /c-level-agents:office-hours (too ambiguous)
```

## Related

- Agent: [`cs-chief-of-staff`](../../agents/cs-chief-of-staff.md) — does the routing
- Skill: [`chief-of-staff`](../chief-of-staff/SKILL.md) — routing logic
- Skill: [`context-engine`](../context-engine/SKILL.md) — loads context

---

**Version:** 1.0.0


---

# c-level-agents — Founder-Mode Executive Team

A virtual C-suite delivered through slash commands and persona agents.

## Keywords

founder mode, virtual c-suite, executive team, boardroom, office hours, cfo review, cmo review, strategic sprint, decision logging, cross-model consensus, persona agents, chief of staff, forcing questions

## What This Plugin Provides

### 13 cs-* Agents (in `agents/`)

Each agent wraps an existing c-level skill and adds:
- A distinct cognitive voice (numerate skeptic, narrative-first, etc.)
- Forcing questions specific to the role
- Workflow orchestration tied to skill Python tools
- Output template: Bottom Line → What → Why → How to Act → Your Decision

See `../../references/persona-voices.md` for voice specs.

### 21 /c-level-agents:* Slash Commands (in `skills/`)

**Forcing-question office hours (12):**
- `/c-level-agents:office-hours` — YC-style 6-question intake
- `/c-level-agents:cfo-review` — unit economics, runway, dilution
- `/c-level-agents:cmo-review` — ICP, CAC payback, positioning
- `/c-level-agents:cpo-review` — RICE, JTBD, North Star, PMF
- `/c-level-agents:cro-review` — pipeline coverage, win rate, NRR
- `/c-level-agents:cto-review` — architecture risk, scaling cliff
- `/c-level-agents:ciso-review` — threat model, blast radius, compliance
- `/c-level-agents:gc-review` — contracts, IP, regulatory, term sheets
- `/c-level-agents:cdo-review` — training-data rights, data products, data assets
- `/c-level-agents:caio-review` — model selection, evals, AI risk, AI costs
- `/c-level-agents:cco-review` — GRR/NRR decomposition, churn root cause, CS coverage
- `/c-level-agents:vpe-review` — DORA metrics, cycle time, eng hiring funnel, team structure

**Strategic sprint pipeline (5):**
- `/c-level-agents:brief` → `/c-level-agents:boardroom` → `/c-level-agents:decide` → `/c-level-agents:execute` → `/c-level-agents:post-mortem`

**Meta + safety (4):**
- `/c-level-agents:founder-mode` — auto-routes to the right C-role
- `/cs-onboard` — founder interview → `company-context.md`
- `/c-level-agents:cross-eval` — multi-model consensus
- `/c-level-agents:freeze` — cooldown lock on a decision

## Quick Start

```
/cs-onboard                          # populate company context first
/c-level-agents:office-hours "should we hire a VP Sales?"
/c-level-agents:founder-mode "runway pressure"   # auto-routes to CFO
/c-level-agents:boardroom briefs/pricing-v3.md   # full panel
```

## Architecture

```
User question
   │
   ├─ Single-role? → cs-{role}-advisor agent
   │                     ↓
   │                  /cs-{role}-review command (forcing Qs)
   │                     ↓
   │                  Skill tools + references
   │                     ↓
   │                  Bottom Line + Memo
   │
   └─ Multi-role?  → /c-level-agents:boardroom
                        ↓
                     6-phase deliberation (Phase 2 isolation)
                        ↓
                     /c-level-agents:decide → decision-logger (two-layer memory)
                        ↓
                     /c-level-agents:execute → 90-day plan
```

## Integration Points

- **Existing 33 c-level skills** — wrapped, not replaced
- **decision-logger** — every `/c-level-agents:decide` writes here
- **chief-of-staff** — routing layer the agent orchestrates
- **board-meeting** — protocol the `/c-level-agents:boardroom` command runs
- **llm-wiki** — optional persistent memory bridge (see `../../references/llm-wiki-bridge.md`)
- **executive-mentor** — adversarial `/executive-mentor:*` commands stack cleanly on top

## Design Principles

1. **Voice is bookended, analysis is neutral.**
2. **Artifacts over chat.** Every command produces a Markdown artifact the next command consumes.
3. **Phase 2 isolation in boardroom.** Independent thinking before cross-examination.
4. **Graceful degradation.** `/c-level-agents:cross-eval` falls back to Claude-only.
5. **No paid dependencies.** All Python tools are stdlib-only.

## References

- [persona-voices.md](../../references/persona-voices.md)
- [llm-wiki-bridge.md](../../references/llm-wiki-bridge.md)
- [Existing executive-mentor sibling](../executive-mentor/executive-mentor/SKILL.md)

---

**Version:** 1.0.0
**Last Updated:** 2026-05-12
**Status:** Production Ready


---

## C-Suite Bundle Overview

# C-Level Advisory Bundle — Index

This is the bundle index, not an advisor. It tells you what exists and where to start; the skills below do the work.

## Start Here

1. **Onboard** — the `cs-onboard` skill runs the founder interview (`/cs-onboard setup`, 7 dimensions, ~45 min) and writes `~/.claude/company-context.md`. Refresh quarterly with `/cs-onboard update`. This is the canonical context schema every advisor reads.
2. **Ask** — the `chief-of-staff` skill routes any question to the right advisor(s). See its routing matrix for all 14 roles.
3. **Big decisions** — the `board-meeting` skill runs a **6-phase** deliberation: (1) context gathering → (2) independent contributions (isolated) → (3) critic analysis → (4) synthesis → (5) founder review (full stop) → (6) decision extraction. Invoked via `/c-level-agents:boardroom` in the c-level-agents plugin.
4. **Memory** — decisions land in the canonical two-layer layout `~/.claude/decisions/{raw,approved}/` (see `../agent-protocol/SKILL.md` → "Decision Memory (Canonical Layout)").

## What's in the Bundle (33 skills)

**14 C-suite roles + critic (15):** ceo-advisor, cfo-advisor, cto-advisor, coo-advisor, cpo-advisor, cmo-advisor, cro-advisor, ciso-advisor, chro-advisor, general-counsel-advisor, chief-data-officer-advisor, chief-ai-officer-advisor, chief-customer-officer-advisor, vpe-advisor — plus the executive-mentor critic (sibling plugin).

**Orchestration (6):** cs-onboard, chief-of-staff, board-meeting, decision-logger, agent-protocol, context-engine.

**Cross-cutting (6):** board-deck-builder, scenario-war-room, competitive-intel, org-health-diagnostic, ma-playbook, intl-expansion.

**Culture & collaboration (6):** culture-architect, company-os, founder-coach, strategic-alignment, change-management, internal-narrative.

Plus this index (1). 37 stdlib-only Python tools and 68 reference docs across the bundle.

## Routing Quick Reference

Full matrix in `../chief-of-staff/SKILL.md` and `../chief-of-staff/references/routing-matrix.md`. Primary roles: CFO (capital/burn), CRO (pipeline/sales), CMO (positioning), CPO (roadmap/PMF), CTO (architecture), COO (ops/OKRs), CHRO (people), CISO (security), GC (contracts/term sheets), CDO (data strategy/training-data rights), CAIO (AI strategy/evals), CCO (retention/GRR), VPE (delivery/DORA), CEO (direction). Multi-domain or irreversible → board meeting.

## Related Layers

- `../../../c-level-agents/` — 13 cs-* persona agents + 21 `/cs-*` slash commands on top of these skills
- `../../executive-mentor/` — adversarial `/executive-mentor:*` critic commands
- `../../CLAUDE.md` — full architecture diagram and integration guide
