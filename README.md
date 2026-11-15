# Antigravity Skills, Subagents & Rules

[![Skills](https://img.shields.io/badge/Skills-576-10b981?style=for-the-badge)](#domain-highlights-576-skills)
[![Subagents](https://img.shields.io/badge/Subagents-25-3b82f6?style=for-the-badge)](#25-native-subagents)
[![Rules](https://img.shields.io/badge/Rules-100-8b5cf6?style=for-the-badge)](#how-it-works)
[![Agents](https://img.shields.io/badge/Works_With-Antigravity_%26_Claude_Code-f59e0b?style=for-the-badge)](./INSTALLATION.md)

A unified, production-ready customization pack for **Antigravity** (and **Claude Code**) bundling **576 on-demand skills**, **25 specialist subagents**, and **100 context-aware engineering rules** — complete with zero-dependency Python 3 CLI calculators and one-command local or global updates.

---

## Quick Start (30 Seconds)

### Interactive Install or Update (Asks *Current Directory* vs *Global*)

Run inside any project folder. You will be prompted to install/update in your **current directory** or **globally**:

```bash
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash
```

### Direct One-Line Commands

```bash
# 1. Antigravity — Current Project Directory (./.agents)
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --local

# 2. Antigravity — Global Plugin (~/.gemini/config/plugins/antigravity-skills)
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --global

# 3. Claude Code — Current Project (./.claude/skills) or Global (~/.claude/skills)
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --local
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --claude --global

# 4. Update an Existing Installation (auto-detects local/global & preserves custom files)
curl -fsSL https://raw.githubusercontent.com/Mynul-Sakil/antigravity-skills/main/install.sh | bash -s -- --update
```

> Full instructions for manual `git clone`, merging into existing `.agents/` folders, `skills.json` context tuning, Windows setup, and uninstallation: **[INSTALLATION.md](./INSTALLATION.md)**

---

## How It Works

This repository is structured natively for Antigravity's **Progressive Disclosure** system so you get deep domain workflows without bloating your prompt context window:

| Component | Folder | Count | How It Loads | Context Cost |
| :--- | :--- | :---: | :--- | :--- |
| **Skills & Slash Workflows** | `skills/<name>/SKILL.md` | **576** | Type `/<name>` in chat **or** ask in plain English | Full `SKILL.md`, `references/`, and `scripts/` load **only when activated** |
| **Specialist Subagents** | `agents/<name>.md` | **25** | Delegated via `invoke_subagent` (`subagent: true`) | Runs in an **isolated subagent context**; sized to keep built-in `browser` & `research` active |
| **Core Engineering Rules** | `rules/common-*.md` | **9** | `trigger: always_on` | Compact baseline (immutability, TDD, security, code review, git workflow) |
| **Language & Stack Rules** | `rules/<stack>-*.md` | **91** | `trigger: glob` (e.g. `**/*.ts`, `**/*.py`) | **Zero tokens** until you open or edit matching files |

---

## Domain Highlights (576 Skills)

Every skill includes structured workflows, reference checklists, and (where applicable) **zero-dependency Python 3 CLI tools** (`scripts/*.py`, stdlib-only). All skills work as `/<skill-name>` slash commands:

| Domain | Representative `/slash` Skills |
| :--- | :--- |
| **Architecture & Specs** | `/plan-prd`, `/prp-plan`, `/database-schema-designer`, `/api-design`, `/codebase-onboarding`, `/tech-debt-tracker`, `/monorepo-navigator` |
| **Full-Stack & Languages** | `/nextjs-best-practices`, `/nextjs-turbopack`, `/bun-runtime`, `/react-review`, `/fastapi-review`, `/python-review`, `/go-review`, `/rust-review`, `/flutter-review` |
| **TDD, QA & Playwright** | `/tdd-workflow`, `/pw`, `/pw-init`, `/playtest`, `/react-test`, `/api-test-suite-builder`, `/test-coverage`, `/build-fix` |
| **Multi-Agent Orchestration** | `/orch-add-feature`, `/orch-fix-defect`, `/orch-refine-code`, `/gan-build`, `/gan-design`, `/santa-loop`, `/council`, `/hub-run` |
| **Git, PR & DevOps** | `/pr`, `/pr-review-expert`, `/git-sync`, `/deploy-verify`, `/runbook-generator`, `/pm2`, `/quality-gate` |
| **Security & AI Safety** | `/senior-security`, `/ai-security`, `/red-team`, `/threat-detection`, `/soc2-compliance`, `/gdpr-audit-prep`, `/ai-act-readiness` |
| **Stock, Finance & Valuation** | `/stock-analysis`, `/financial-analyst`, `/passive-deal-screener`, `/business-investment-advisor`, `/cfo-advisor` |
| **Deep Research & Intel** | `/deep-research`, `/exa-search`, `/pulse`, `/competitive-intel`, `/graphify` |
| **Product & Agile Delivery** | `/agile-product-owner`, `/product-discovery`, `/product-strategist`, `/product-analytics`, `/experiment-designer`, `/jira` |
| **C-Suite & Strategy** | `/boardroom`, `/ceo-advisor`, `/cto-review`, `/cpo-review`, `/challenge`, `/stress-test`, `/hard-call`, `/scenario-war-room` |
| **Marketing, SEO & CRO** | `/seo-audit`, `/page-cro`, `/signup-flow-cro`, `/form-cro`, `/pricing-strategy`, `/launch-strategy`, `/social-content` |
| **Daily Productivity** | `/today-summary`, `/weekly-presentation-organizer`, `/rewrite`, `/prompt-engineer`, `/save-session`, `/resume-session` |

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

### 1. Run Any Skill as a Slash Command (Antigravity & Claude Code)

```text
/stock-analysis Analyze AAPL fundamentals and peer valuation multiples
/plan-prd Real-time portfolio alert notification service
/tdd-workflow Add JWT refresh token rotation with 80%+ test coverage
/today-summary
```

### 2. Automatic Plain-English Activation

You don't have to memorize skill names — just ask naturally:
- *"Value this SaaS business with a 5-year DCF and sensitivity table"* -> activates `financial-analyst`
- *"Audit our signup form for conversion drop-off"* -> activates `signup-flow-cro`
- *"Check if our AI feature falls under high-risk EU AI Act tiers"* -> activates `ai-act-readiness`

### 3. Run Bundled Zero-Dependency Python CLI Calculators

Many skills ship deterministic Python 3 standard-library calculators inside `scripts/`:

```bash
python3 .agents/skills/financial-analyst/scripts/ratio_calculator.py \
  .agents/skills/financial-analyst/assets/sample_financial_data.json
```

---

## Repository Layout

```text
antigravity-skills/
├── skills/          # 576 modular skills (<name>/SKILL.md + scripts/ + references/ + assets/)
├── agents/          # 25 native Antigravity specialist subagents
├── rules/           # 100 rules (9 always_on core rules + 91 glob-triggered stack rules)
├── plugin.json      # Native Antigravity plugin manifest (used for --global installs)
├── install.sh       # Interactive & CLI installer, updater, and uninstaller
├── INSTALLATION.md  # Full Antigravity + Claude Code setup, update & tuning guide
└── README.md
```

---

## Documentation & Support

- **Full Setup, Claude Code Guide, Updates & `skills.json` Filtering**: [INSTALLATION.md](./INSTALLATION.md)
- **Author**: [Mynul-Sakil](https://github.com/Mynul-Sakil)
