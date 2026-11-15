---
name: grill-me
description: "Relentlessly interview the user one question at a time (with recommended answers) to resolve every branch of a design/plan decision tree. Automatically grounds questions in CONTEXT.md glossaries and docs/adr/ ADRs when present."
license: MIT
---

# Grill Me (Plan Interrogation & Docs-Anchored Design Review)

Interview the user relentlessly about every aspect of a plan or design until reaching shared understanding, walking depth-first down the decision tree one question at a time.

## Non-Negotiable Rules

1. **One question per turn.** Never bundle multiple questions.
2. **Always provide a recommended answer + 1-sentence rationale.** Never ask a lazy open-ended *"what do you think?"*.
3. **Explore the codebase & docs before asking.** If `grep`, `read_file`, `CONTEXT.md`, or `docs/adr/` answers it, inspect first and confirm evidence instead of asking.
4. **Walk depth-first & respect dependencies.** Resolve foundational decision A before dependent decision B.

## Standard Workflow

1. **Pre-Flight Check (Codebase + Optional Domain Docs):**
   - If `CONTEXT.md` exists: run `python3 scripts/context_md_linter.py CONTEXT.md` and `python3 scripts/glossary_code_consistency.py --context CONTEXT.md --code src/` to surface dead glossary terms or conflicting domain language.
   - If `docs/adr/` exists: run `python3 scripts/adr_scanner.py docs/adr/` to inspect architectural decisions already locked.
   - Extract plan branches with `python3 scripts/decision_tree_extractor.py` and `python3 scripts/question_generator.py`.
   - Start tracking: `python3 scripts/grill_session_tracker.py --action start`.
2. **Interactive Grilling Loop (1 Question/Turn):**
   ```text
   Q[i]/[total]: [Focused question]
   Recommended answer: [Concrete call + 1-sentence rationale]
   ```
   - Call out conflicts with `CONTEXT.md` glossary terms or existing code behavior immediately.
   - If `CONTEXT.md` is used, update resolved ubiquitous-language definitions inline (see [CONTEXT-FORMAT.md](CONTEXT-FORMAT.md)).
   - Offer a new ADR (see [ADR-FORMAT.md](ADR-FORMAT.md)) **only** when a decision is (1) hard to reverse, (2) surprising without context, and (3) a genuine trade-off.
3. **Closing Summary:**
   - Report locked-in decisions, updated glossary terms, any ADRs created, and remaining open items.

## Bundled Python Tools (Stdlib-Only)

| Script | Purpose |
| :--- | :--- |
| `scripts/decision_tree_extractor.py` | Extract decision branches and dependencies from a plan |
| `scripts/question_generator.py` | Generate ordered forcing questions with recommendations |
| `scripts/grill_session_tracker.py` | Track resolved vs open branches across turns |
| `scripts/context_md_linter.py` | Validate `CONTEXT.md` glossary structure |
| `scripts/adr_scanner.py` | Validate `docs/adr/NNNN-slug.md` numbering and completeness |
| `scripts/glossary_code_consistency.py` | Cross-check `CONTEXT.md` terms against codebase identifiers |

## References
- [references/forcing_question_patterns.md](references/forcing_question_patterns.md) — Forcing-question patterns
- [references/when_to_stop_grilling.md](references/when_to_stop_grilling.md) — Convergence criteria
- [references/ubiquitous_language.md](references/ubiquitous_language.md) — Domain glossary discipline
- [references/adr_practice.md](references/adr_practice.md) — High-signal ADR criteria
- [references/context_md_as_artifact.md](references/context_md_as_artifact.md) — Maintaining `CONTEXT.md`
