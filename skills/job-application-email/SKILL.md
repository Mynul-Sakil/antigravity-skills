---
name: job-application-email
description: "Draft personalized tech job-application and recruiter outreach emails matched to a job description (Standard or Impact format across Startup, Enterprise, Remote-First, and Formal tones) plus Boolean search queries for finding remote employers."
---

# Tech Job Application Email & Remote Employer Finder (`/job-application-email`)

Tailors high-signal job-application and cold-outreach emails for software engineers by parsing a job description, matching the candidate's real stack and measurable achievements, and adapting tone to the target company culture.

## When to Activate

- User shares a job posting and wants a personalized application email or cover note.
- User wants to rewrite an application email for a different tone (startup vs. enterprise vs. remote-first).
- User wants Boolean search queries to discover remote-first tech employers outside crowded job boards.

## Inputs to Gather (Ask Only for What's Missing)

1. **Job posting / role description** *(required)*
2. **Candidate profile:** primary stack, years of experience, and 2–3 relevant projects or measurable achievements
3. **Target role focus:** e.g., Full-Stack, Frontend, Backend, DevOps, Mobile
4. **Company culture / preferred tone:** `Modern Startup`, `Remote-First`, `Enterprise`, or `Formal`
5. **Format preference:** `Standard` or `Impact` (default: `Impact` for startups/remote, `Standard` for enterprise)

## Email Structures

### Standard Format
1. **Subject Line:** Clear role + key stack/value signal
2. **Opening Hook:** Specific reference to the company/product or role
3. **Role-Specific Experience:** 2–3 lines mapping directly to the posting's top requirements
4. **Project Highlights:** 1–2 concrete projects with outcomes/metrics
5. **Technical Stack Match:** Concise alignment with required tools
6. **Call to Action:** Low-friction next step (portfolio/GitHub/resume + short call)

### Impact Format *(Problem-Solution)*
1. **Subject Line:** Specific value hook + role title
2. **Problem-Solution Opener:** Address a pain point implied by the job posting
3. **Key Achievements:** 2–3 quantified bullets (latency, reliability, shipping velocity, user impact)
4. **Stack & Autonomy Fit:** Why you ramp quickly in their environment
5. **Direct Call to Action**

## Tone Matrix

| Tone | Style Guidance |
| :--- | :--- |
| **Modern Startup** | Concise, direct, builder-minded, product-curious, zero corporate clichés |
| **Remote-First** | Highlights async communication, ownership, self-direction, and documentation habits |
| **Enterprise** | Structured, methodology-aware (testing, security, scalability, cross-team collaboration) |
| **Formal** | Polished, traditional salutation and closing, conservative phrasing |

## Remote Employer Discovery (Boolean Search Helper)

When the user asks to find remote-first companies hiring for their stack, provide tailored search-engine Boolean queries that bypass saturated aggregators:

```text
("remote work companies" OR "distributed companies" OR "remote-first employers") AND ("<role 1>" OR "<role 2>") -site:linkedin.com -site:indeed.com -site:glassdoor.com filetype:pdf "list" OR "directory"
```

Also suggest searching official careers pages (`site:boards.greenhouse.io`, `site:jobs.lever.co`, `site:jobs.ashbyhq.com`) paired with `"remote"` and the candidate's core stack.

## Quality Checklist (Verify Before Outputting)

- [ ] Every claimed skill or achievement matches facts provided by the user (never invent metrics)
- [ ] Directly mirrors the job posting's top 3 technical requirements
- [ ] Concise and scannable (under ~180–220 words unless user requests a long cover letter)
- [ ] Includes a clear subject line and low-friction CTA
- [ ] Offers 1–2 quick suggestions for further personalization (e.g., link to a relevant live demo or PR)
