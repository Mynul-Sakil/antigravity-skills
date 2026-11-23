---
name: resume-builder
description: >-
  Use when creating a new resume from scratch, tailoring an existing resume to a
  target role or job description, auditing resume bullets for ATS compliance and
  HR/CEO/CTO scannability, or exporting an ATS-safe 1-page PDF, Markdown, or
  RenderCV YAML resume. Includes a deterministic Python ATS auditor
  (scripts/ats_resume_auditor.py) and zero-dependency Chrome headless PDF
  renderer (scripts/render_resume_pdf.py) that saves timestamped PDFs to
  output/<position>_<YYYY-MM-DD>_<HH-MM>.pdf.
---

# Resume Builder (`/resume-builder`)

Creates crisp, ATS-compliant, human-sounding resumes tailored for HR recruiters, hiring managers, and executives (CEOs/CTOs)—strictly grounded in real candidate facts, with built-in ATS auditing and 1-command PDF export.

## Hard Rules (Non-Negotiable)

1. **Never fabricate facts.** Never invent metrics, dates, companies, degrees, or technologies the candidate has not confirmed. If a bullet lacks a number, use concrete scope/outcomes (e.g., *"multi-tenant PostgreSQL schema with subdomain routing"*) or ask the user for real metrics.
2. **Zero AI buzzword fluff.** Avoid hollow clichés (*"results-driven"*, *"passionate"*, *"proven track record"*, *"cutting-edge"*, *"synergy"*, *"hardworking team player"*). Write in plain, concrete engineering & business language.
3. **Single-column ATS safety.** No tables, multi-column layouts, icons, or graphics in resume source text. Standard section headings only.
4. **Always run the auditor before finishing.** Never deliver a final resume without verifying it with `scripts/ats_resume_auditor.py`.

---

## Workflow

### Step 1: Gather Grounded Candidate Context
1. Check if the workspace already contains a candidate profile/resume folder (e.g., `resume/`, `portfolio/`, or pasted resume text). Read those files first.
2. Confirm only what is missing:
   - Target role title (e.g., Backend Engineer, Full Stack Developer, Frontend / React / Next.js, Mobile)
   - Job description (optional — if provided, save to a temporary file for `--jd` keyword matching)
   - Preferred output format: **Markdown** (`resources/resume-template.md`), **ATS-Safe PDF** (`scripts/render_resume_pdf.py`), or **RenderCV YAML** (`resources/rendercv-template.yaml`)

### Step 2: Load Positioning & Writing Rules
- Read [references/ats-and-recruiter-rules.md](./references/ats-and-recruiter-rules.md) for 6-second HR scan structure and XYZ bullet construction.
- Read [references/role-positioning-guides.md](./references/role-positioning-guides.md) to prioritize the right skills, experience bullets, and 3–4 strongest projects for the target role.

### Step 3: Draft the Tailored Resume
- Start from [resources/resume-template.md](./resources/resume-template.md) (or [resources/rendercv-template.yaml](./resources/rendercv-template.yaml) when RenderCV YAML is requested).
- Target **1 page** (`400–650 words`) for candidates with `< 6` years of experience.
- Keep every bullet **1–2 lines (`12–26 words`)**, starting with a strong past-tense (or present-tense for current role) action verb and ending with a clear business or technical outcome.
- Match truthful terminology from the job description in the Summary, Skills, and top Experience bullets.

### Step 4: Audit Deterministically with Python
Run the bundled auditor script (relative to this skill directory) against the drafted resume file:

```bash
python3 scripts/ats_resume_auditor.py \
  --resume <path-to-resume.md> \
  [--jd <path-to-jd.txt>]
```

- Exit `0` = **READY** (`>= 80/100`)
- Exit `2` = **NEEDS POLISH** (`60–79/100`)
- Exit `3` = **REWRITE** (`< 60/100`)

### Step 5: Iterate & Deliver
1. Fix every flagged AI cliché, weak passive starter, overly long bullet, or missing truthful JD keyword.
2. Re-run `scripts/ats_resume_auditor.py` until it exits `0` (`READY`).
3. Present the final resume along with:
   - The final ATS audit score
   - A 3-bullet tailoring summary explaining what was prioritized for the target role
   - Any optional real metrics the user could supply to make bullets even stronger

### Step 6: Export to ATS-Safe PDF (Zero Dependencies)
Render the audited Markdown directly to a single-column, text-selectable PDF via Google Chrome / Chromium headless (`--print-to-pdf`):

```bash
python3 scripts/render_resume_pdf.py \
  --resume <path-to-resume.md> \
  --out-dir output \
  --page-size letter \
  [--compact]
```

- Automatically creates `output/` and names the file `<position-slug>_<YYYY-MM-DD>_<HH-MM>.pdf`.
- Exit `0` = strict 1-page PDF generated cleanly; Exit `2` = spilled past 1 page (re-run with `--compact` or trim 2–3 lines).
- Visually inspect the rendered PDF before handing it off.
