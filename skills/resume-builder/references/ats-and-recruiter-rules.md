# ATS & 6-Second Recruiter Scan Rules

## How Recruiters & Executives Actually Read a Resume
1. **Seconds 0–3 (Header + Summary)**: Name, target role title, location/remote status, clickable GitHub/LinkedIn/Portfolio links, and a 2–3 line summary matching the role.
2. **Seconds 3–6 (Current Role + Tech Stack)**: Current company, dates, and first 2 bullets — does this person ship real production systems at our level?
3. **Seconds 6–30 (Proof & Projects)**: Remaining experience bullets, 2–4 live projects with links, and education.

## ATS Parsing Safety Rules
- **Single-column layout only** (multi-column PDFs scramble text order in Workday/Greenhouse/Lever parsers).
- **Standard section headers**: `Summary`, `Skills`, `Experience`, `Projects`, `Education`.
- **Consistent date format**: `Mon YYYY – Mon YYYY` or `Mon YYYY – Present` (e.g., `Apr 2026 – Present`).
- **No tables, icons, progress bars, or skill star ratings**.
- **Mirror exact keywords from the JD** (e.g., if the JD says `PostgreSQL` and `Node.js`, write `PostgreSQL` and `Node.js`, not just `SQL` and `JS` — only when truthful).

## The XYZ / Action-Outcome Bullet Formula
> **Accomplished [X] (concrete capability/outcome) by doing [Z] (specific tech/architecture), resulting in [Y] (real impact or operational benefit).**

- **Weak**: *"Responsible for working on backend APIs and helping with caching."*
- **Strong**: *"Implemented Redis caching and BullMQ background job queues for calendar sync and high-concurrency endpoints, reducing API latency and database load."*

## Human-Writing Checklist (Anti-AI)
- Cut empty adjectives: *"results-driven"*, *"passionate"*, *"cutting-edge"*, *"proven track record"*, *"synergy"*.
- Prefer concrete nouns (PostgreSQL triggers, CASL RBAC, Stripe webhooks, Playwright E2E) over vague abstractions (*"scalable solutions"*, *"robust systems"*).
- Keep bullets to **1–2 lines (12–26 words)** and **3–6 bullets per role** (most recent role gets the most space).
