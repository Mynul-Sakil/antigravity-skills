---
name: deploy-verify
description: "Automated GitHub PR management, CI/CD deployment tracking, and remote task verification workflow"
---

# GitHub PR & Deployment Verification Skill

This workflow defines the standard operational procedures for creating GitHub pull requests, tracking GitHub Actions CI/CD deployment pipelines, and performing remote environment verifications (e.g. database migrations).

## Capabilities

### 1. Create Pull Request (`/deploy-verify pr`)

When preparing changes for deployment:

1. Check git branch and uncommitted changes (`git status`, `git diff`).
2. Commit and push branch to origin (`git push origin <branch-name>`).
3. Create GitHub Pull Request using `gh pr create --title "<title>" --body "<body>"`.
4. Monitor PR checks and merge status using `gh pr view <pr-number> --json state,mergedAt`.

### 2. Track GitHub Actions Deployment (`/deploy-verify track`)

When waiting for production/staging deployment:

1. Query active workflow runs on main branch using `gh run list --branch main --limit 5`.
2. Monitor specific build/deploy runs using `gh run view <run-id> --json status,conclusion`.
3. Wait until `Deploy Production` or `Build` workflow finishes with `conclusion: "success"`.

### 3. Remote Verification (`/deploy-verify verify`)

When deployment completes:

1. Execute remote database status check (`yarn db:migrate:remote:status`).
2. Execute remote database migration execution if needed (`yarn db:migrate:remote`).
3. Validate response status code and output diagnostics.

## Guidelines & Safety Rules

- **Always verify branch before pushing**: Ensure you are on the intended feature or fix branch.
- **Explain command execution**: Always follow `command-execution-policy` before running git or gh CLI commands.
- **Verify CI/CD before testing remote endpoints**: Never test remote endpoints while a deployment workflow is still `in_progress`. Wait until GitHub Actions reports `completed` and `success`.
