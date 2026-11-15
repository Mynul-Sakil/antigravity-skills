---
name: git-sync
description: "Pull main and dev, merge changes to main, cherry-pick to dev, check ESLint and type safety on both branches, and push both repositories to origin."
---

# Git Sync Workflow (`/git-sync`)

Use this workflow to safely synchronize, verify, and push verified changes across both `frontend-clinic-booking-app` and `backend-clinic-booking-app` repositories to `main` and `dev`.

## Execution Steps

1. **Fetch & Pull:**
   - In both repos: fetch and pull latest remote changes on `main` and `dev`.
2. **Apply to Main:**
   - In both repos: apply / merge working branch feature commits onto `main`.
3. **Cherry-Pick to Dev:**
   - In both repos: checkout `dev` and cherry-pick the newly introduced feature commits.
4. **Quality Gates:**
   - In `backend-clinic-booking-app`: run `yarn lint` and `npx tsc --noEmit` on both `dev` and `main` (0 errors required).
   - In `frontend-clinic-booking-app`: run `npm run lint` and `npx tsc --noEmit` on both `dev` and `main` (0 errors required).
5. **Push to Origin:**
   - In both repos: push `origin main` and `origin dev`.
   - Verify working trees are clean on `main`.

Refer to the [git-main-dev-sync skill](file:///Users/apple/Desktop/work/clinic-booking-app/.agent/skills/git-main-dev-sync/SKILL.md) for full procedural details.
