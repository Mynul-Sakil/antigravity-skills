# Installation & Update Guide

Complete guide for installing, updating, customizing, and uninstalling **`antigravity-skills`** in **Antigravity** and **Claude Code** — either in your **current project directory** or **globally** across all projects.

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Where Should I Install? (Current Directory vs Global)](#2-where-should-i-install-current-directory-vs-global)
3. [Antigravity Installation](#3-antigravity-installation)
4. [Claude Code Installation Guide](#4-claude-code-installation-guide)
5. [Using Both Antigravity & Claude Code in One Repo](#5-using-both-antigravity--claude-code-in-one-repo)
6. [Updating an Existing Installation](#6-updating-an-existing-installation)
7. [Selective Skill Loading & Context Budget](#7-selective-skill-loading--context-budget)
8. [OS-Specific Notes (macOS, Linux, Windows)](#8-os-specific-notes-macos-linux-windows)
9. [Verification & Troubleshooting](#9-verification--troubleshooting)
10. [Uninstallation](#10-uninstallation)

---

## 1. Prerequisites

- **`git`** (2.20+) — required for cloning and fast-forward updates
- **`bash`** (3.2+) — included by default on macOS, Linux, WSL2, and Git for Windows
- **`curl`** — optional, only needed for the one-line remote installer
- **`python3`** (3.8+) — optional but recommended; runs bundled zero-dependency CLI helpers (`scripts/*.py`, Python standard library only — **no `pip install` needed**) and speeds up manifest-based merges

---

## 2. Where Should I Install? (Current Directory vs Global)

When you run `install.sh`, it can install into your **current project directory** (`--local`) or **globally** on your machine (`--global`).

| Feature | Current Directory (`--local`) | Global (`--global`) |
| :--- | :--- | :--- |
| **Antigravity Path** | `<your-project>/.agents/` | `~/.gemini/config/plugins/antigravity-skills/` |
| **Claude Code Path** | `<your-project>/.claude/skills/` | `~/.claude/skills/` |
| **Active Scope** | Only when working inside `<your-project>` | Available in **every** project on your computer |
| **Personal Config Safety** | Self-contained inside the project folder | Isolated as a plugin (Antigravity) or SHA-256 manifest-tracked (Claude Code) — never overwrites your personal skills |
| **Settings UI Toggle** | Managed per workspace / `skills.json` | One-click **Enable / Disable** in Antigravity Plugins UI |
| **Precedence** | Overrides Global skills/rules with the same name | Acts as your machine-wide baseline |
| **Best For** | Team repositories, project-specific skill filtering | Solo developers working across many repositories |

> [!TIP]
> Pick **either** `--global` (for everyday use across all projects) **or** `--local` (per project). You don't need both in the same project unless you want project-specific overrides.

---

## 3. Antigravity Installation

### Option A — Interactive Prompt (Asks Current Dir vs Global)

Run this inside any project folder. It prompts you to choose **Current Directory** or **Global** — and if already installed at that location, it **automatically updates** it:

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash
```

### Option B — One-Line Non-Interactive Commands

**Install (or update) in Current Project Directory (`./.agents`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local
```

**Install (or update) in a Specific Project Directory:**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --dir /path/to/your-project
```

**Install (or update) Globally (`~/.gemini/config/plugins/antigravity-skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global
```

**Preview What Will Happen First (`--dry-run`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --dry-run
```

### Option C — Manual `git clone`

Because the repository root already matches Antigravity's exact layout (`skills/`, `agents/`, `rules/`, and `plugin.json`), a plain `git clone` works with zero build steps:

```bash
# Workspace install (inside your project root):
git clone --depth 1 https://github.com/Mynul-Sakil/antigravity-skills.git .agents

# OR Global plugin install (active across all workspaces):
mkdir -p ~/.gemini/config/plugins
git clone --depth 1 https://github.com/Mynul-Sakil/antigravity-skills.git ~/.gemini/config/plugins/antigravity-skills
```

> **Already have a custom `.agents/` folder in your project?**
> Use `install.sh --local` instead of `git clone`. The installer detects your existing `.agents/` directory and performs a **non-destructive merge** (tracking managed files in `.agents/.antigravity-skills.manifest` while leaving your custom skills, agents, and rules untouched).

---

## 4. Claude Code Installation Guide

All **576 skills** (including all `/slash` workflow skills such as `/plan-prd`, `/tdd-workflow`, `/react-review`, `/stock-analysis`, `/pr`, and `/git-sync`) follow the universal `SKILL.md` standard and work natively in **Claude Code**.

### Method 1 — Automated Installer (`--claude`)

The `--claude` flag safely merges all 576 skills into `.claude/skills/` or `~/.claude/skills/` using SHA-256 manifest tracking — **it never touches your `CLAUDE.md`, `settings.json`, or existing custom skills**.

**Claude Code — Current Project (`./.claude/skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local
```

**Claude Code — Global (`~/.claude/skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global
```

### Method 2 — Copy Only Specific Skills into Claude Code

If you only want a few domain skills in Claude Code (recommended to keep Claude Code's skill-listing budget lean):

```bash
git clone --depth 1 https://github.com/Mynul-Sakil/antigravity-skills.git /tmp/antigravity-skills
mkdir -p ~/.claude/skills

# Example: copy stock, finance, and TDD skills only
cp -R /tmp/antigravity-skills/skills/{stock-analysis,financial-analyst,tdd-workflow,plan-prd,react-review} ~/.claude/skills/

rm -rf /tmp/antigravity-skills
```

### How to Use in Claude Code

1. Open Claude Code in your terminal (`claude`).
2. Invoke any skill directly as a slash command (e.g., `/stock-analysis`, `/plan-prd`, `/tdd-workflow`, `/pr`) or ask naturally in plain English.
3. **Claude Code Context-Budget Tip**: Claude Code caps its automatic skill description list at ~1% of the context window by default (`skillListingBudgetFraction: 0.01`). If you install all 576 skills globally in Claude Code and want more descriptions shown inline, you can optionally raise `skillListingBudgetFraction` (e.g., `0.03`) in `~/.claude/settings.json`, or install only the skills you actively use.

---

## 5. Using Both Antigravity & Claude Code in One Repo

If your team uses **both** Antigravity and Claude Code in the same repository, install once into `.agents/` and symlink `.claude/skills` so both agents share one copy with zero extra disk usage:

```bash
# 1. Install into ./.agents
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local

# 2. Symlink ./.claude/skills -> ../.agents/skills
mkdir -p .claude
ln -s ../.agents/skills .claude/skills
```

*(On Windows, enable Developer Mode or run from an elevated shell when creating directory symlinks, or run `install.sh --claude --local` to copy instead.)*

---

## 6. Updating an Existing Installation

Running `install.sh` again on an existing target — or passing `--update` — updates your installation safely:

```bash
# Auto-detects whether Antigravity is installed locally, globally, or both, and updates:
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --update

# Update a specific target explicitly:
./.agents/install.sh --local --update
./.agents/install.sh --global --update
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --update
```

### Update Safety Guarantees

- **Git-cloned installs (`./.agents` or `~/.gemini/config/plugins/antigravity-skills`)**:
  - Uses `git fetch origin main` + `git merge --ff-only` (never runs `git reset --hard` or `git clean -fd`).
  - Untracked custom folders you added (e.g., `.agents/skills/my-company-skill/`) stay untouched.
  - If you edited a tracked file locally, `--update` stops safely and lists the modified files; pass `--force` if you want it to auto-stash your local edits (`git stash pop` restores them anytime).
- **Merged installs (`.claude/` or pre-existing `.agents/`)**:
  - Compares every file against `.antigravity-skills.manifest` (SHA-256).
  - Unmodified upstream files are updated; obsolete upstream files are pruned; **any custom or locally edited file is preserved** (or backed up to `.backups/<timestamp>/` when `--force` is passed).

---

## 7. Selective Skill Loading & Context Budget

Loading all **576** skills at once gives you maximum slash-command coverage (`/<skill-name>`), while Antigravity caps how many skill descriptions are injected inline per prompt.

To curate which skills auto-load in a specific Antigravity project, create `.agents/skills.json` using Antigravity's native configuration format:

### Example 1 — Load Only Selected Stack Skills (`include_only`)

If you installed globally (or cloned into `tools/antigravity-skills`) and want a workspace to expose only specific patterns:

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

### Example 2 — Exclude Unrelated Regulated/Mobile Domains (`exclude`)

```json
{
  "entries": [
    {
      "path": "skills",
      "exclude": [
        "fda-*",
        "iso13485-*",
        "mdr-*",
        "cmmc-*",
        "flutter-*",
        "kotlin-*",
        "cpp-*"
      ]
    }
  ]
}
```

---

## 8. OS-Specific Notes (macOS, Linux, Windows)

### macOS
- Works out of the box with macOS's built-in `/bin/bash` (Bash 3.2) and `python3`.
- If `git` prompts to install Command Line Developer Tools, run `xcode-select --install`.

### Linux
- Ensure `git`, `curl`, and `python3` are installed:
  ```bash
  # Ubuntu / Debian
  sudo apt-get update && sudo apt-get install -y git curl python3
  ```

### Windows
- Run `install.sh` inside **Git Bash** (installed with [Git for Windows](https://gitforwindows.org/)) or **WSL2**.
- Set `git config --global core.autocrlf input` before cloning so shell and Python scripts retain Unix `LF` line endings.
- In Git Bash, `~/.gemini/config/plugins/antigravity-skills` maps automatically to `C:\Users\<YourUser>\.gemini\config\plugins\antigravity-skills`.

---

## 9. Verification & Troubleshooting

### Quick Verification Commands

```bash
# For a current-directory (.agents) install:
ls -1 .agents/skills | wc -l    # Expected: 576
ls -1 .agents/agents | wc -l    # Expected: 25
ls -1 .agents/rules  | wc -l    # Expected: 100

# Smoke-test a bundled zero-dependency Python helper:
python3 .agents/skills/financial-analyst/scripts/ratio_calculator.py \
  .agents/skills/financial-analyst/assets/sample_financial_data.json
```

Then start a new chat in Antigravity (or Claude Code) and type `/plan-prd` or `/stock-analysis` to verify slash-command discovery.

### Troubleshooting

| Symptom | Cause | Fix |
| :--- | :--- | :--- |
| Skills don't show up right after install | Active chat session cached previous index | Start a **new chat** or reload the workspace window |
| `Non-interactive session detected without a scope flag` | Piped `curl \| bash` in CI/container without `/dev/tty` | Append `-s -- --local` or `-s -- --global` |
| `Local tracked modifications detected` on `--update` | You edited a file tracked inside `.agents` | Commit/stash your edit, or pass `--force` to auto-stash before updating |
| Adding `.agents/` to parent app repo shows gitlink warning | `.agents` has its own `.git` folder | Add `.agents/` to your app repo's `.gitignore` or `.git/info/exclude` |

---

## 10. Uninstallation

The installer includes safe uninstallation that verifies repository ownership (or manifest hashes) before removing anything:

```bash
# Uninstall Antigravity from Current Directory (./.agents):
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --uninstall

# Uninstall Antigravity Global Plugin:
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --uninstall

# Uninstall Claude Code managed skills (preserves your custom ~/.claude files & settings.json):
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --uninstall
```

*(Add `--yes` in automated scripts to skip the `[y/N]` confirmation prompt, or `--dry-run` to preview what would be removed.)*
