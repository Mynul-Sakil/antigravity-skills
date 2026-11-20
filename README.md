# Antigravity Skills, Subagents & Rules

[![Skills](https://img.shields.io/badge/Skills-531-10b981?style=for-the-badge)](#domain-highlights-531-skills)
[![Subagents](https://img.shields.io/badge/Subagents-25-3b82f6?style=for-the-badge)](#25-native-subagents)
[![Rules](https://img.shields.io/badge/Rules-100-8b5cf6?style=for-the-badge)](#how-it-works)
[![Agents](https://img.shields.io/badge/Works_With-Antigravity_%7C_Claude_%7C_Copilot-f59e0b?style=for-the-badge)](./INSTALLATION.md)

A unified, production-ready customization pack for **Antigravity**, **Claude Code**, and **GitHub Copilot** featuring **531 on-demand skills**, **25 specialist subagents**, and **100 context-aware engineering rules** — with **selective sparse-checkout installation** so you can install the lean **Minimal Core** (default), **a single skill**, **a role pack**, or **all 531 skills**.

---

## Install Modes Overview

| Mode | CLI Flag | What Gets Installed | Downloads Whole Repo? |
| :--- | :--- | :--- | :---: |
| **Minimal *(Default)*** | *(none)* or `--minimal` | **17** daily core skills, **8** core subagents, **8** core rules | **No** (sparse fetch) |
| **Specific Skill(s)** | `--skill <name>` | **Only** the requested skill folder(s) (`SKILL.md` + `scripts/` + `references/`) | **No** (sparse fetch) |
| **Role Pack** | `--role <role>` | Curated pack (`frontend`, `backend`, `fullstack`, `qa`, `security`, `devops`, `ai-ml`, `finance`, `product`, `marketing`, `founder`) | **No** (sparse fetch) |
| **Full Catalog** | `--all` | All **531** skills, **25** subagents, and **100** rules | Yes |

---

## Quick Start (Copy One Command at a Time)

### Interactive Wizard (Asks *Location* + *Install Mode*)

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash
```

---

### 1. Antigravity — Minimal Install *(Default: 17 Core Skills, 8 Subagents, 8 Rules)*

**Current Project Directory (`./.agents`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local
```

**Global Plugin (`~/.gemini/config/plugins/antigravity-skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global
```

---

### 2. Install Specific Skill(s) Only *(Without Downloading the Whole Repo)*

**Install a single skill in your current project (example: `stock-analysis`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --skill stock-analysis
```

**Install multiple skills at once (comma-separated, local or global):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --skill stock-analysis,financial-analyst,deep-research
```

> Adding `--skill` on top of an existing `minimal` or `--role` install is **additive** — it keeps your existing skills intact and adds the new one.

---

### 3. Install by Role (`--role`)

Available roles: `frontend`, `backend`, `fullstack`, `qa`, `security`, `devops`, `ai-ml`, `finance`, `product`, `marketing`, `founder` (alias: `c-suite`).

**Install a role pack in your current project (example: `fullstack`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --role fullstack
```

**Install a role pack globally (example: `finance`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --role finance
```

**List all 11 role packs and their skill counts:**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --list-roles
```

---

### 4. Antigravity — Full Catalog (`--all`: All 531 Skills, 25 Subagents, 100 Rules)

**Current Project Directory (`./.agents`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --all
```

**Global Plugin (`~/.gemini/config/plugins/antigravity-skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global --all
```

---

### 5. Claude Code (`--claude`)

**Claude Code — Minimal Pack in Current Project (`./.claude/skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local
```

**Claude Code — Minimal Pack Globally (`~/.claude/skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global
```

**Claude Code — Install Specific Skill Only (example: `stock-analysis`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local --skill stock-analysis
```

**Claude Code — Install All 531 Skills Globally:**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global --all
```

---

### 6. GitHub Copilot (`--copilot`)

Works natively across **VS Code Copilot Agent Mode**, **GitHub Copilot CLI**, and **GitHub Copilot Cloud Coding Agent** (`agentskills.io` `SKILL.md` standard):

- **Project install (`--copilot --local`)** writes to `./.github/`:
  - `.github/skills/<name>/SKILL.md` — selected skills + stdlib Python scripts & references
  - `.github/instructions/<name>.instructions.md` — rules auto-converted to `applyTo` frontmatter (**never** overwrites your existing `.github/copilot-instructions.md` or `.github/workflows/`)
  - `.github/agents/<name>.agent.md` — specialist subagents auto-converted with Copilot `tools` (`read`, `search`, `edit`, `execute`)
- **Global install (`--copilot --global`)** writes personal skills to `~/.copilot/skills/`.

**GitHub Copilot — Minimal Pack in Current Project (`./.github/{skills,instructions,agents}`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --copilot --local
```

**GitHub Copilot — Minimal Skills Globally (`~/.copilot/skills`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --copilot --global
```

**GitHub Copilot — Install Specific Skill Only (example: `stock-analysis`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --copilot --local --skill stock-analysis
```

**GitHub Copilot — Install Role Pack in Current Project (example: `fullstack`):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --copilot --local --role fullstack
```

**GitHub Copilot — Update Existing Installation (Auto-Detects Local & Global):**

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --copilot --update
```

> In VS Code, open Copilot Chat and run **Chat: Open Customizations** to inspect loaded skills, instructions, and custom agents. Commit `.github/{skills,instructions,agents}` if you also want **GitHub Copilot Cloud Coding Agent** on GitHub.com to use them.

---

### 7. Update an Existing Installation

Auto-detects your local/global installation and refreshes **only** the mode, roles, and skills you installed (while preserving custom files):

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --update
```

> Full instructions for role contents, `skills.json` filtering, Windows setup, and uninstallation: **[INSTALLATION.md](./INSTALLATION.md)**

---

## How It Works

This repository is built natively around **Progressive Disclosure** so you get deep domain workflows without bloating your prompt context window:

| Component | Folder | Total Available | How It Loads | Context Cost |
| :--- | :--- | :---: | :--- | :--- |
| **Skills & Slash Workflows** | `skills/<name>/SKILL.md` | **531** | Type `/<name>` in chat **or** ask in plain English | Full `SKILL.md`, `references/`, and `scripts/` load **only when activated** |
| **Specialist Subagents** | `agents/<name>.md` | **25** | Delegated via `invoke_subagent` (`subagent: true`) | Runs in an **isolated subagent context**; sized to keep built-in `browser` & `research` active |
| **Core Engineering Rules** | `rules/common-*.md` | **8** (+1 optional) | `trigger: always_on` | Compact baseline (immutability, TDD, security, code review, git workflow) |
| **Language & Stack Rules** | `rules/<stack>-*.md` | **91** | `trigger: glob` (e.g. `**/*.ts`, `**/*.py`) | **Zero tokens** until you open or edit matching files |

---

## Domain Highlights (531 Skills)

Every skill includes structured workflows, reference checklists, and (where applicable) **zero-dependency Python 3 CLI tools** (`scripts/*.py`, stdlib-only). All skills work as `/<skill-name>` slash commands:

| Domain | Representative `/slash` Skills |
| :--- | :--- |
| **Architecture & Specs** | `/plan`, `/multi-plan`, `/plan-prd`, `/database-schema-designer`, `/api-design`, `/codebase-onboarding`, `/tech-debt-tracker`, `/monorepo-navigator` |
| **Full-Stack & Languages** | `/nextjs-best-practices`, `/nextjs-turbopack`, `/bun-runtime`, `/react-review`, `/fastapi-review`, `/python-review`, `/go-review`, `/rust-review`, `/flutter-review` |
| **TDD, QA & Playwright** | `/tdd-workflow`, `/pw`, `/e2e-testing`, `/playtest`, `/react-test`, `/api-test-suite-builder`, `/test-coverage`, `/build-fix` |
| **Multi-Agent Orchestration** | `/orch-workflow`, `/gan-build`, `/gan-design`, `/santa-method`, `/council`, `/hub-run` |
| **Git, PR & DevOps** | `/pr`, `/code-review`, `/git-sync`, `/deploy-verify`, `/runbook-generator`, `/pm2`, `/quality-gate` |
| **Security & AI Safety** | `/senior-security`, `/ai-security`, `/red-team`, `/threat-detection`, `/soc2-compliance`, `/gdpr-dsgvo-expert`, `/eu-ai-act-specialist` |
| **Stock, Finance & Valuation** | `/stock-analysis`, `/dse-stock-analyst`, `/financial-analyst`, `/passive-deal-screener`, `/business-investment-advisor`, `/cfo-advisor` |
| **Deep Research & Intel** | `/deep-research`, `/exa-search`, `/pulse`, `/competitive-intel`, `/graphify` |
| **Product & Agile Delivery** | `/agile-product-owner`, `/product-discovery`, `/product-strategist`, `/product-analytics`, `/experiment-designer`, `/jira-expert` |
| **C-Suite & Strategy** | `/boardroom`, `/ceo-advisor`, `/cto-review`, `/cpo-review`, `/challenge`, `/stress-test`, `/hard-call`, `/scenario-war-room` |
| **Marketing, SEO & CRO** | `/seo-audit`, `/page-cro`, `/signup-flow-cro`, `/form-cro`, `/pricing-strategy`, `/launch-strategy`, `/social-content` |
| **Daily Productivity** | `/today-summary`, `/weekly-presentation-organizer`, `/rewrite`, `/prompt-engineer`, `/coding-prompt-spec`, `/book-mentor`, `/mock-tech-interview`, `/job-application-email`, `/sessions`, `/session-handoff` |

---

## 25 Native Subagents

Configured in `agents/*.md` using Antigravity's native schema (`subagent: true`, `mainAgent: false`, mapped native tool permissions):

| Category | Subagents |
| :--- | :--- |
| **Architecture & Planning (4)** | `architect`, `planner`, `code-architect`, `code-explorer` |
| **Code & Stack Reviewers (12)** | `code-reviewer`, `code-simplifier`, `security-reviewer`, `typescript-reviewer`, `react-reviewer`, `python-reviewer`, `fastapi-reviewer`, `django-reviewer`, `go-reviewer`, `database-reviewer`, `mle-reviewer`, `rag-pipeline-reviewer` |
| **Build & Error Resolvers (4)** | `build-error-resolver`, `react-build-resolver`, `django-build-resolver`, `pytorch-build-resolver` |
| **TDD, E2E & Performance (5)** | `tdd-guide`, `e2e-runner`, `performance-optimizer`, `refactor-cleaner`, `silent-failure-hunter` |

---

## Usage Examples

### 1. Run Any Skill as a Slash Command (Antigravity, Claude Code & GitHub Copilot)

| Prompt Example | What It Runs |
| :--- | :--- |
| `/stock-analysis Analyze AAPL fundamentals and peer valuation multiples` | Equity fundamentals & valuation report |
| `/plan-prd Real-time portfolio alert notification service` | Problem-first PRD + implementation plan |
| `/tdd-workflow Add JWT refresh token rotation with 80%+ test coverage` | Red -> Green -> Refactor TDD workflow |
| `/today-summary` | Concise single-line summary of today's completed work |

### 2. Automatic Plain-English Activation

You don't have to memorize skill names — just ask naturally:
- *"Value this SaaS business with a 5-year DCF and sensitivity table"* -> activates `financial-analyst`
- *"Audit our signup form for conversion drop-off"* -> activates `signup-flow-cro`
- *"Check if our AI feature falls under high-risk EU AI Act tiers"* -> activates `eu-ai-act-specialist`

### 3. Run Bundled Zero-Dependency Python CLI Calculators

Many skills ship deterministic Python 3 standard-library calculators inside `scripts/` (for example, after installing `--skill financial-analyst`, `--role finance`, or `--all`):

```bash
python3 .agents/skills/financial-analyst/scripts/ratio_calculator.py .agents/skills/financial-analyst/assets/sample_financial_data.json
```

---

## How to Add a Skill

### Option A: Add an Existing Skill from This Catalog to Your Project

Browse all 531 available skill names:

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --list-skills
```

Add one or more skills **without replacing** your current install (works for Antigravity `--local`, Claude Code `--claude --local`, or GitHub Copilot `--copilot --local`):

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local --skill stock-analysis,seo-audit
```

### Option B: Create & Add Your Own Custom Skill

Every skill is a self-contained lowercase hyphenated folder under `skills/<skill-name>/` (or `.github/skills/<skill-name>/` / `.claude/skills/<skill-name>/`):

```text
skills/my-custom-skill/
├── SKILL.md           # Required: YAML frontmatter (name + description) + workflow steps
├── scripts/           # Optional: stdlib-only Python 3 CLI helpers
├── references/        # Optional: checklists, schemas, or deep guides
└── assets/            # Optional: templates or sample inputs
```

Minimal `SKILL.md` template:

```markdown
---
name: my-custom-skill
description: "Use when <exact trigger condition or user request> — <concise one-line summary of what this skill produces>."
---

# My Custom Skill

## When to Activate
- Trigger 1
- Trigger 2

## Workflow
1. Step 1
2. Step 2
3. Verify output before finishing
```

**Tips when contributing a skill back to this repo:**
- Keep `name:` identical to the folder name and `SKILL.md` focused (`< 800` lines).
- If the skill belongs in a curated pack, add its folder name to `profiles.json` under `minimal` or a `roles.<name>.skills` list.
- Run the self-cleaning 17-suite test harness before committing:

```bash
bash tests/test_installer.sh
```

---

## Repository Layout

```text
antigravity-skills/
├── skills/          # 531 modular skills (<name>/SKILL.md + scripts/ + references/ + assets/)
├── agents/          # 25 specialist subagents (auto-converted to .agent.md for Copilot)
├── rules/           # 100 rules (auto-converted to .instructions.md for Copilot)
├── scripts/         # Stdlib-only installer_engine.py (sparse sync & Copilot transformer)
├── tests/           # Self-cleaning 17-suite E2E test harness (tests/test_installer.sh)
├── profiles.json    # Declarative catalog for 'minimal' default & 11 '--role' packs
├── plugin.json      # Native Antigravity plugin manifest (used for --global installs)
├── install.sh       # Selective sparse-checkout installer, updater & uninstaller
├── INSTALLATION.md  # Complete Antigravity, Claude Code & GitHub Copilot setup guide
└── README.md
```

---

## Documentation & Support

- **Complete Setup, Single-Skill / Role Guides, Claude Code & Uninstallation**: [INSTALLATION.md](./INSTALLATION.md)
- **Author**: [Mynul-Sakil](https://github.com/Mynul-Sakil)
