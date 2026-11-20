---
name: coding-prompt-spec
description: "Lightweight pre-code specification gate: structure any coding task into Goal, 3–7 Rules, 2 Input->Output Examples, 2 Edge Cases, and runnable test deliverables, then list potential mistakes and confirm rules before writing code."
---

# Pre-Code Specification Gate (`/coding-prompt-spec`)

A fast, disciplined specification template for turning vague coding requests into unambiguous, testable deliverables — catching edge-case bugs **before** a single line of implementation code is written.

## When to Activate

- User wants to structure a coding prompt cleanly before generating code.
- A task is small-to-medium (utility, parser, script, endpoint, algorithm) and needs crisp acceptance criteria without a full PRD.

## The 5-Part Specification Template

Fill out (or ask the user to confirm) these five compact sections:

```markdown
- **Goal:** (One sentence describing the exact outcome)
- **Rules:** (3 to 7 concrete behavioral invariants)
- **Examples:** (2 concrete input -> output pairs)
- **Edge Cases:** (2 inputs or states that could break a naive implementation)
- **Deliverables:**
  - Single runnable implementation file (or minimal scoped diff)
  - Built-in automated assertions/tests (e.g., Node `assert`, Python `assert`/`pytest`)
  - One printed example output demonstrating expected behavior
```

## Mandatory Pre-Code Gate

**Before writing any implementation code:**
1. List **3–5 concrete mistakes or failure modes** that could violate the rules or break the edge cases.
2. Confirm the rules and edge-case behavior with the user (or explicitly state assumptions if the user requested immediate execution).
3. Only after confirmation, write the runnable code, include the assertions covering both examples and both edge cases, and execute them to verify output.
