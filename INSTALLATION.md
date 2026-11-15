# Installation & Update Guide

Complete guide for installing, updating, customizing, and uninstalling **`antigravity-skills`** in **Antigravity** and **Claude Code** — either in your **current project directory** (`--local`) or **globally** (`--global`), using **`minimal`** (default), **specific `--skill`**, **`--role` packs**, or **`--all`**.

> **One-Click Copy-Paste Ready:** Every code block in this guide contains a **single standalone command** so clicking GitHub's Copy button always copies one ready-to-run command.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Current Directory (`--local`) vs Global (`--global`)](#2-current-directory---local-vs-global---global)
3. [Choosing an Install Mode (`Minimal` vs `Skill` vs `Role` vs `All`)](#3-choosing-an-install-mode-minimal-vs-skill-vs-role-vs-all)
4. [Antigravity Installation Commands](#4-antigravity-installation-commands)
5. [Installing Specific Skills Without Downloading the Whole Repo (`--skill`)](#5-installing-specific-skills-without-downloading-the-whole-repo---skill)
6. [Installing Role Packs (`--role`)](#6-installing-role-packs---role)
7. [Claude Code Installation Guide (`--claude`)](#7-claude-code-installation-guide---claude)
8. [Using Both Antigravity & Claude Code in One Repo](#8-using-both-antigravity--claude-code-in-one-repo)
9. [Updating an Existing Installation (`--update`)](#9-updating-an-existing-installation---update)
10. [Selective Skill Filtering via `skills.json`](#10-selective-skill-filtering-via-skillsjson)
11. [OS-Specific Notes (macOS, Linux, Windows)](#11-os-specific-notes-macos-linux-windows)
12. [Verification & Troubleshooting](#12-verification--troubleshooting)
13. [Uninstallation](#13-uninstallation)

---

## 1. Prerequisites

- **`git`** (2.25+ recommended for blobless sparse checkout; 2.20+ supported with automatic fallback)
- **`bash`** (3.2+) — included by default on macOS, Linux, WSL2, and Git for Windows
- **`python3`** (3.8+) — standard library only (**no `pip install` needed**); resolves `profiles.json`, tracks SHA-256 file manifests, and runs bundled skill calculators (`scripts/*.py`)
- **`curl`** — optional, only needed for one-line remote installation

---

## 2. Current Directory (`--local`) vs Global (`--global`)

| Feature | Current Directory (`--local`) | Global (`--global`) |
| :--- | :--- | :--- |
| **Antigravity Path** | `<your-project>/.agents/` | `~/.gemini/config/plugins/antigravity-skills/` |
| **Claude Code Path** | `<your-project>/.claude/skills/` | `~/.claude/skills/` |
| **Active Scope** | Only when working inside `<your-project>` | Available in **every** project on your machine |
| **Personal Config Safety** | Self-contained inside the project folder | Isolated as a plugin (Antigravity) or SHA-256 manifest-tracked (Claude Code) — never overwrites your personal skills |
| **Settings UI Toggle** | Managed per workspace / `skills.json` | One-click **Enable / Disable** in Antigravity Plugins UI |
| **Precedence** | Overrides Global skills/rules with the same name | Machine-wide baseline |

> [!TIP]
> Pick **either** `--global` (for everyday use across all projects) **or** `--local` (for project-specific stacks). Every install mode (`--minimal`, `--skill`, `--role`, `--all`) works in **both** `--local` and `--global`.

---

## 3. Choosing an Install Mode (`Minimal` vs `Skill` vs `Role` vs `All`)

By default, running `install.sh` installs **`--minimal`** via Git sparse checkout so your download completes in seconds and keeps your agent's context window lean.

| Mode | CLI Flag | Contents | Best For |
| :--- | :--- | :--- | :--- |
| **Minimal *(Default)*** | *(omitted)* or `--minimal` | **17** core skills, **8** core subagents, **8** `common-*` rules | Fast, zero-bloat daily engineering baseline |
| **Specific Skill(s)** | `--skill <name[,name2]>` | Only the named skill folder(s) | Grabbing 1–5 specialized skills without downloading the repo |
| **Role Pack** | `--role <role[,role2]>` | Curated role skills + matching subagents + stack rules | Tailoring to your role (`frontend`, `backend`, `fullstack`, `finance`, etc.) |
| **Full Catalog** | `--all` | All **526** skills, **25** subagents, **100** rules | Complete offline library of every domain skill |

### What Is Included in `minimal` (Default)?

- **17 Skills:** `plan`, `multi-plan`, `plan-prd`, `feature-dev`, `codebase-onboarding`, `tdd-workflow`, `build-fix`, `focused-fix`, `code-review`, `security-review`, `refactor-clean`, `test-coverage`, `commit-craft`, `pr`, `deep-research`, `update-docs`, `today-summary`
- **8 Subagents:** `planner`, `architect`, `tdd-guide`, `code-reviewer`, `security-reviewer`, `build-error-resolver`, `e2e-runner`, `refactor-cleaner`
- **8 Core Rules:** `common-agents`, `common-code-review`, `common-coding-style`, `common-development-workflow`, `common-git-workflow`, `common-patterns`, `common-security`, `common-testing`

---

## 4. Antigravity Installation Commands

### Interactive 2-Step Wizard (Asks Location + Mode)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash
```

### Minimal Pack *(Default)* — Current Directory (`./.agents`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local
```

### Minimal Pack *(Default)* — Global (`~/.gemini/config/plugins/antigravity-skills`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global
```

### Full Catalog (`--all`: All 526 Skills) — Current Directory (`./.agents`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --all
```

### Full Catalog (`--all`: All 526 Skills) — Global (`~/.gemini/config/plugins/antigravity-skills`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --all
```

### Target a Specific Project Path (`--dir`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --dir /path/to/your-project
```

### Preview Actions Without Modifying Any Files (`--dry-run`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --dry-run
```

### Manual Full Clone (Alternative to `install.sh --all`)

**Clone all 526 skills into your current project (`./.agents`):**

```bash
git clone --depth 1 https://github.com/Mynul-Sakil/antigravity-skills.git .agents
```

**Clone all 526 skills globally:**

```bash
mkdir -p ~/.gemini/config/plugins && git clone --depth 1 https://github.com/Mynul-Sakil/antigravity-skills.git ~/.gemini/config/plugins/antigravity-skills
```

---

## 5. Installing Specific Skills Without Downloading the Whole Repo (`--skill`)

`--skill` uses blobless Git sparse checkout (`--filter=blob:none --no-checkout`) to download **only** the requested `skills/<name>/` folder (including its `SKILL.md`, `scripts/`, `references/`, and `assets/`) while skipping the other 525 skills.

- **On a fresh folder:** Installs **only** the skill(s) you asked for.
- **On an existing install (`minimal` or `--role`):** Merges the new skill **additively** without deleting your previously installed skills.
- **Typo protection:** If you mistype a skill name, the installer suggests the closest matching skills before touching any files.

### Install One Skill in Your Current Project (Example: `stock-analysis`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --skill stock-analysis
```

### Install One Skill Globally (Example: `financial-analyst`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --skill financial-analyst
```

### Install Multiple Skills at Once (Comma-Separated)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --skill stock-analysis,financial-analyst,seo-audit
```

### Browse All 526 Available Skill Names

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --list-skills
```

---

## 6. Installing Role Packs (`--role`)

Each `--role` pack sparse-fetches a curated set of domain skills, matching subagents, `common-*` core rules, and stack-specific glob rules:

| Role Flag | Skills | Subagents | Rules | Focus Areas |
| :--- | :---: | :---: | :---: | :--- |
| `--role frontend` | 15 | 6 | 20 | React, Next.js, TypeScript, Vue, UI design systems, accessibility & Playwright UI testing |
| `--role backend` | 16 | 9 | 24 | APIs, schemas, Python/FastAPI/Django, Go, Rust, Bun & Stripe payments |
| `--role fullstack` | 17 | 10 | 20 | End-to-end SaaS shipping (Next.js, React, FastAPI, DB, Stripe, TDD, Playwright) |
| `--role qa` | 14 | 5 | 16 | TDD, Playwright E2E, flake fixing, BrowserStack, API test suites & coverage |
| `--role security` | 15 | 4 | 14 | Threat modeling, AI safety, cloud security, red-team & SOC2/ISO27001/GDPR |
| `--role devops` | 14 | 5 | 14 | CI/CD, Docker, Kubernetes, Terraform, AWS, observability, runbooks & incidents |
| `--role ai-ml` | 15 | 6 | 12 | LLM engineering, RAG pipelines, prompt engineering, eval harnesses & MLOps |
| `--role finance` | 13 | 2 | 9 | Stock analysis, DCF valuation, financial ratios, SaaS metrics, deal screening & CFO |
| `--role product` | 14 | 3 | 8 | PRDs, product discovery, agile stories, Jira, roadmaps, UX research & A/B tests |
| `--role marketing` | 18 | 2 | 8 | SEO/AEO audits, page/signup/form CRO, copywriting, content, pricing & launches |
| `--role founder` *(or `c-suite`)* | 17 | 2 | 8 | Virtual C-suite boardroom, fundraising, investor decks, runway & strategy |

### List All Roles from the CLI

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --list-roles
```

### Install a Role Pack Locally (Example: `fullstack`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --role fullstack
```

### Install a Role Pack Globally (Example: `ai-ml`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --role ai-ml
```

### Combine Multiple Roles (Example: `frontend` + `qa`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --role frontend,qa
```

---

## 7. Claude Code Installation Guide (`--claude`)

All **526 skills** follow the universal `SKILL.md` standard and work natively in **Claude Code** (including `/<skill-name>` slash commands). Passing `--claude` syncs only `skills/` (skipping Antigravity-only `agents/` and `rules/`) and tracks files via `.antigravity-skills.manifest` so your `CLAUDE.md`, `settings.json`, and custom skills are **never** touched.

### Claude Code — Minimal Pack *(Default: 17 Core Skills)* in Current Project (`./.claude/skills`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local
```

### Claude Code — Minimal Pack *(Default: 17 Core Skills)* Globally (`~/.claude/skills`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global
```

### Claude Code — Install Specific Skill(s) Only

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local --skill stock-analysis,financial-analyst
```

### Claude Code — Install a Role Pack Globally (Example: `fullstack`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --role fullstack
```

### Claude Code — Install All 526 Skills Globally

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --all
```

> [!NOTE]
> **Claude Code Context Tip:** Using the default `minimal`, `--skill`, or `--role` modes keeps your skill list well inside Claude Code's default `1%` skill-listing budget (`skillListingBudgetFraction: 0.01`). If you install `--all` (526 skills) in Claude Code, you can optionally set `"skillListingBudgetFraction": 0.03` in `~/.claude/settings.json`.

---

## 8. Using Both Antigravity & Claude Code in One Repo

If your team uses both agents in the same repository, install once into `./.agents` and symlink `./.claude/skills` so both agents share one copy:

**Step 1 — Install into `./.agents`:**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local
```

**Step 2 — Symlink `./.claude/skills` to `../.agents/skills`:**

```bash
mkdir -p .claude && ln -s ../.agents/skills .claude/skills
```

---

## 9. Updating an Existing Installation (`--update`)

`install.sh` stores your active mode, roles, and added skills in `.antigravity-skills.manifest` (`# @state {...}`). When you run `--update`, it refreshes **only** what you installed — it will never unexpectedly bloat a `minimal` or `--skill` install into all 526 skills, and it never overwrites custom or locally edited files.

### Auto-Detect and Update Antigravity (Local, Global, or Both)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --update
```

### Update Current Directory Explicitly

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --update
```

### Update Global Antigravity Plugin Explicitly

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --update
```

### Update Claude Code Global Skills

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --update
```

---

## 10. Selective Skill Filtering via `skills.json`

If you installed `--all` globally (`~/.gemini/config/plugins/antigravity-skills`), you can also filter which skills auto-load in a specific Antigravity project by creating `.agents/skills.json`:

```json
{
  "entries": [
    {
      "path": "~/.gemini/config/plugins/antigravity-skills/skills",
      "include_only": [
        "stock-analysis",
        "financial-analyst",
        "deep-research",
        "nextjs-*",
        "react-*",
        "tdd-workflow",
        "plan-prd",
        "pr"
      ]
    }
  ]
}
```

---

## 11. OS-Specific Notes (macOS, Linux, Windows)

### macOS
Works out of the box with macOS's built-in `/bin/bash` (Bash 3.2) and `python3`. If `git` prompts for developer tools, run:

```bash
xcode-select --install
```

### Linux (Ubuntu / Debian)
Ensure `git`, `curl`, and `python3` are installed:

```bash
sudo apt-get update && sudo apt-get install -y git curl python3
```

### Windows
Run `install.sh` inside **Git Bash** ([Git for Windows](https://gitforwindows.org/)) or **WSL2**. Configure Unix line endings before cloning so shell and Python helpers keep `LF` endings:

```bash
git config --global core.autocrlf input
```

---

## 12. Verification & Troubleshooting

### Check Installed Skill Count in Current Project

```bash
ls -1 .agents/skills | wc -l
```

*(Expected: `17` for default `--minimal`, `526` for `--all`, or your exact `--skill` / `--role` count.)*

### Smoke-Test a Bundled Python Calculator (Requires `financial-analyst` Skill)

```bash
python3 .agents/skills/financial-analyst/scripts/ratio_calculator.py .agents/skills/financial-analyst/assets/sample_financial_data.json
```

### Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Skills don't appear immediately after install | Active chat cached the previous skill list | Start a **new chat** or reload the workspace window |
| `Skill '<name>' not found. Did you mean: ...?` | Typo in `--skill <name>` | Use one of the suggested skill names or run `--list-skills` |
| `Non-interactive session detected without a scope flag` | Piped `curl \| bash` in CI without `/dev/tty` | Append `-s -- --local` or `-s -- --global` |
| Adding `.agents/` to parent app repo shows untracked files | `.agents` installed inside an app Git repo | Add `.agents/` to your app repo's `.gitignore` or `.git/info/exclude` |

---

## 13. Uninstallation

Uninstallation verifies repository/manifest hashes so your custom or modified files are never deleted unless `--force` is passed.

### Remove a Single Skill Only (`--uninstall --skill`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --uninstall --skill stock-analysis
```

### Uninstall Antigravity from Current Project (`./.agents`)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --uninstall
```

### Uninstall Antigravity Global Plugin

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --uninstall
```

### Uninstall Claude Code Managed Skills (Global)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --uninstall
```

*(Append `--yes` in non-interactive scripts to skip the `[y/N]` confirmation prompt, or `--dry-run` to preview.)*
