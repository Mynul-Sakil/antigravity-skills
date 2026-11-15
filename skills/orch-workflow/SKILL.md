---
name: orch-workflow
description: "Gated multi-step engineering orchestrator covering 6 modes: add-feature, build-mvp, change-feature, fix-defect, refine-code, and review. Enforces explicit plan approval (GATE 1), test-first execution, reviewer subagents, and gated conventional commits (GATE 2)."
---

# Orchestrated Engineering Workflows (`orch-workflow`)

Self-contained gated orchestration pipelines for building features, bootstrapping MVPs, changing behavior, fixing bugs, refactoring safely, and running pre-commit reviews.

## Usage

```text
/orch-workflow add-feature <capability to build>
/orch-workflow build-mvp <path/to/spec-or-sdd.md>
/orch-workflow change-feature <new desired behavior>
/orch-workflow fix-defect <bug description>
/orch-workflow refine-code <module or target to restructure>
/orch-workflow review [base-ref]
```

## Shared Gate Discipline

- **GATE 1 (Plan / Test Spec Approval):** Present the scoped plan, vertical slices, or behavior-change test plan and wait for user approval on non-trivial changes before editing implementation files.
- **GATE 2 (Pre-Commit Verification):** Run relevant tests + `code-reviewer` (and `security-reviewer` whenever auth, user input, SQL, secrets, APIs, or payments are touched) before creating a conventional commit.

---

## Mode 1: `add-feature` — Net-New Capability

1. **Size & Research:** Classify scope (`small | standard | large`). Inspect existing codebase patterns with `code-explorer` before designing new abstractions.
2. **Plan (`GATE 1`):** Produce concrete file list, interfaces, and test cases (`planner` + `architect` for multi-module work). Confirm with user.
3. **TDD Execution:** Delegate/follow `tdd-guide` — write failing unit/integration tests first (RED), implement minimal code to pass (GREEN), and clean up (REFACTOR) to 80%+ coverage.
4. **Review & Commit (`GATE 2`):** Run `code-reviewer` (+ `security-reviewer` if applicable), verify build/tests pass, and prepare a `feat:` commit.

## Mode 2: `build-mvp` — Vertical-Slice MVP from Spec/SDD

1. **Ingest & Slice (`GATE 1`):** Read the PRD/SDD document, extract locked constraints, and order features into thin end-to-end vertical slices (walking skeleton first). Confirm slice order.
2. **Scaffold Slice 1:** Stand up the minimal runnable project/route/test harness.
3. **Iterative Slice Delivery:** For each slice, apply TDD (or pair with `gan-build` generator/evaluator rubric when visual/UX scoring is needed) until acceptance criteria pass.
4. **Review & Commit (`GATE 2`):** Run `code-reviewer` (+ `security-reviewer` on auth/data slices) and commit each completed slice cleanly as `feat:`.

## Mode 3: `change-feature` — Intentional Behavior Change

*Use when existing code works as designed, and the specification itself is changing.*

1. **Locate Existing Behavior:** Find current implementation and its existing test suite.
2. **Test-Spec Update (`GATE 1`):** Update existing assertions (and add new edge-case tests) so the test suite expresses the new desired behavior and fails against old code.
3. **Update Implementation:** Modify implementation minimally until all updated and regression tests turn green.
4. **Review & Commit (`GATE 2`):** Run `code-reviewer` and commit (`feat:` or `refactor:` per semantic impact).

## Mode 4: `fix-defect` — Regression-Proven Bug Fix

*Use when behavior is broken or violates expected specifications.*

1. **Root-Cause Diagnosis:** Inspect logs and trace execution (`code-explorer` if cross-module) before patching; avoid speculative fixes.
2. **Red Regression Test:** Write a focused automated test that reproduces the exact failure and confirm it fails for the expected reason.
3. **Minimal Safe Patch:** Fix the root cause with minimal blast radius until the new regression test and existing suite pass.
4. **Review & Commit (`GATE 2`):** Run `code-reviewer` (+ `security-reviewer` if on a sensitive path) and commit as `fix:`.

## Mode 5: `refine-code` — Behavior-Preserving Refactor

*Use only when external behavior must remain 100% identical.*

1. **Characterization Safety Net (`GATE 1`):** Verify existing tests pass before editing; if coverage is thin, add characterization tests first and outline the refactor steps.
2. **Incremental Restructure:** Refactor in small, reversible steps (extracting cohesive modules, eliminating duplication, or delegating dead-code sweeps to `refactor-cleaner`), re-running tests after each step.
3. **Review & Commit (`GATE 2`):** Confirm diff is strictly behavior-neutral via `code-reviewer` and commit as `refactor:`.

## Mode 6: `review` — Deterministic + Subagent Quality Gate

1. **Deterministic Checks:** Inspect `git status` and `git diff` (against `HEAD` or `[base-ref]`), run build/typecheck/lint/test commands, and scan diff for hardcoded secrets or leftover debug logs.
2. **Specialist Review:** Run `code-reviewer` on the diff, plus `security-reviewer` whenever security-sensitive surfaces are modified.
3. **Structured Verdict:** Report `APPROVE`, `WARN`, or `BLOCK` with file:line findings grouped by `CRITICAL`, `HIGH`, `MEDIUM`, and `LOW`.
