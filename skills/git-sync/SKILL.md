---
name: git-sync
description: "Synchronize main and dev branches across single or multi-repo workspaces: fetch/pull latest main and dev, merge or cherry-pick commits across branches, verify ESLint and TypeScript quality gates on both branches, and push cleanly to origin."
---

# Multi-Repo Git Sync (`main` & `dev`) Workflow

This skill standardizes the multi-repository Git delivery flow across `frontend` and `backend`.

---

## Workspace Structure

Works for single repositories or multi-repository workspaces (e.g., separate `frontend` and `backend` repositories):

1. **Frontend:** `<workspace-root>/frontend`
   - Framework: Next.js (App Router), React, TypeScript
   - Linter: `npm run lint`
   - Typecheck: `npx tsc --noEmit`
2. **Backend:** `<workspace-root>/backend`
   - Framework: Express, Node.js, TypeScript, PostgreSQL
   - Linter: `yarn lint`
   - Typecheck: `npx tsc --noEmit`

---

## When to Activate

Trigger this workflow whenever:
- A user feature or bugfix has been verified and is ready for synchronization.
- The user requests: *"pull main and dev, merge to main, cherry-pick to dev, check eslint, and push"*.
- Releasing changes to both production (`main`) and staging/development (`dev`).

---

## Standard 5-Phase Procedure

### Phase 1: Fetch & Inspect Remote State

Before creating new commits or modifying branch pointers, fetch latest remote changes for both repositories:

```bash
# In backend:
cd <workspace-root>/backend
git fetch origin main dev

# In frontend:
cd <workspace-root>/frontend
git fetch origin main dev
```

Ensure working trees are clean (`git status`). Stash or commit any unstaged work.

---

### Phase 2: Pull and Apply Changes to `main`

Ensure feature changes are cleanly committed on `main`:

#### In Backend (`backend`):
1. Checkout `main` and pull latest upstream:
   ```bash
   git checkout main && git pull origin main
   ```
2. If working on a feature branch (e.g. `fix_main` or `bug-fix`), merge or rebase onto `main`.
3. Verify local commits that will be pushed:
   ```bash
   git log origin/main..main --oneline
   ```

#### In Frontend (`frontend`):
1. Checkout `main` and pull latest upstream:
   ```bash
   git checkout main && git pull origin main
   ```
2. If feature commits exist on a working branch (e.g. `fix_bug_b`), cherry-pick or merge them onto `main`:
   ```bash
   git cherry-pick <commit-hash>
   ```

---

### Phase 3: Pull and Cherry-Pick to `dev`

Every change merged to `main` must also be reflected on `dev`:

#### In Backend (`backend`):
1. Switch to `dev` and pull latest changes:
   ```bash
   git checkout dev && git pull origin dev
   ```
2. Identify the commit hashes introduced on `main`:
   ```bash
   git log origin/main..main --oneline
   ```
3. Cherry-pick those commits onto `dev`:
   ```bash
   git cherry-pick <commit-hash-1> <commit-hash-2> ...
   ```
   *(If merge conflicts occur, resolve surgically or run `git cherry-pick --abort` before asking user).*

#### In Frontend (`frontend`):
1. Switch to `dev` and pull latest changes:
   ```bash
   git checkout dev && git pull origin dev
   ```
2. Cherry-pick the corresponding commit hash(es) onto `dev`:
   ```bash
   git cherry-pick <commit-hash>
   ```

---

### Phase 4: Quality Gates (ESLint & TypeScript Verification)

**CRITICAL:** Never push code without verifying zero lint and zero TypeScript errors on **both** branches across **both** repositories.

#### Backend Quality Checks:
```bash
cd <workspace-root>/backend

# 1. Check dev
git checkout dev
yarn lint
npx tsc --noEmit

# 2. Check main
git checkout main
yarn lint
npx tsc --noEmit
```

*Criteria:* 0 errors, 0 warnings. (If Prettier formatting warnings occur, fix with `--fix` or manual edit).

#### Frontend Quality Checks:
```bash
cd <workspace-root>/frontend

# 1. Check dev
git checkout dev
npm run lint
npx tsc --noEmit

# 2. Check main
git checkout main
npm run lint
npx tsc --noEmit
```

*Criteria:* 0 errors.

---

### Phase 5: Push to Origin

Once all quality gates pass, push both branches to GitHub in both repositories:

#### Backend:
```bash
cd <workspace-root>/backend
git push origin main
git checkout dev && git push origin dev
git checkout main
```

#### Frontend:
```bash
cd <workspace-root>/frontend
git push origin main
git checkout dev && git push origin dev
git checkout main
```

#### Final Verification:
Run `git status` in both repos to confirm:
* `On branch main`
* `Your branch is up to date with 'origin/main'`
* `nothing to commit, working tree clean`

---

## Safety & Operational Invariants

1. **Never Force Push:** Never use `git push --force` or `--force-with-lease` on `main` or `dev`.
2. **Command Explanations:** In accordance with repository policies, explain every git push/checkout command, purpose, and risk before execution.
3. **Zero Lint Debt:** If lint or typecheck fails on either branch, fix the issue immediately before pushing.
4. **Idempotent Cherry-Picks:** Verify commit logs (`git log -n 5 --oneline`) on both branches before pushing to ensure no duplicate commits or accidental regressions exist.
