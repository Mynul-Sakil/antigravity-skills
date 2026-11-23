#!/usr/bin/env python3
"""
Deterministic ATS & Recruiter Resume Auditor (Zero External Dependencies).

Scores a Markdown/text resume 0-100 across 5 dimensions:
  1. Structure & ATS Compliance (20 pts)
  2. Word Budget & Scannability (20 pts)
  3. Action Verbs & Concrete Impact (25 pts)
  4. Anti-AI & Anti-Fluff Hygiene (15 pts)
  5. Job Description Keyword Match (20 pts; full 20 pts if no --jd supplied)

Exit codes:
  0 -> READY (score >= 80)
  2 -> NEEDS POLISH (60 <= score < 80)
  3 -> REWRITE (score < 60)
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REQUIRED_SECTIONS = {
    "summary": r"\b(summary|profile|objective|overview)\b",
    "experience": r"\b(experience|work history|employment)\b",
    "skills": r"\b(skills|technologies|technical stack|competencies)\b",
    "education": r"\b(education|academic)\b",
}

WEAK_STARTERS = [
    "responsible for",
    "worked on",
    "helped with",
    "assisted in",
    "assisted with",
    "tasked with",
    "involved in",
    "participated in",
    "duties included",
    "handled",
]

AI_CLICHES = [
    "results-driven",
    "result-driven",
    "passionate",
    "synergy",
    "cutting-edge",
    "proven track record",
    "hardworking",
    "team player",
    "go-getter",
    "think outside the box",
    "detail-oriented",
    "dynamic professional",
    "leverage cutting-edge",
    "seasoned professional",
    "self-motivated",
]

STRONG_VERBS = {
    "architected", "automated", "built", "configured", "consolidated",
    "containerized", "created", "delivered", "deployed", "designed",
    "developed", "eliminated", "enforced", "engineered", "established",
    "implemented", "improved", "integrated", "launched", "led",
    "migrated", "modeled", "optimized", "orchestrated", "published",
    "reduced", "refactored", "resolved", "scaled", "shipped",
    "standardized", "streamlined", "tested", "tuned",
}

TECH_STOPWORDS = {
    "the", "and", "for", "with", "that", "this", "from", "your", "will",
    "have", "are", "you", "our", "work", "team", "experience", "years",
    "strong", "ability", "using", "build", "building", "role", "position",
    "looking", "candidate", "skills", "required", "preferred", "plus",
    "must", "about", "into", "across", "their", "they", "who", "what",
    "when", "where", "which", "while", "more", "than", "other", "such",
    "good", "great", "best", "high", "well", "full", "time", "remote",
    "company", "business", "product", "products", "software", "engineer",
    "developer", "engineering", "development", "applications", "systems",
}


def extract_bullets(text: str) -> list[str]:
    bullets = []
    for line in text.splitlines():
        stripped = line.strip()
        if re.match(r"^[-*•]\s+", stripped):
            clean = re.sub(r"^[-*•]\s+", "", stripped)
            clean = re.sub(r"\*\*(.+?)\*\*", r"\1", clean)
            # Skip contact metadata bullets at the top
            if re.match(r"^(Location|Phone|Email|Portfolio|GitHub|LinkedIn)\s*:", clean, re.I):
                continue
            bullets.append(clean)
    return bullets


def extract_jd_keywords(jd_text: str) -> list[str]:
    tokens = re.findall(r"[A-Za-z][A-Za-z0-9+#.\-/]{1,}", jd_text)
    freq: dict[str, int] = {}
    canonical: dict[str, str] = {}
    for tok in tokens:
        cleaned = tok.strip(".,;:/()-")
        low = cleaned.lower()
        if len(low) < 2 or low in TECH_STOPWORDS:
            continue
        # Favor tech terms (mixed case, dots, +, #, or repeated domain words)
        is_tech_like = (
            any(ch in cleaned for ch in ".+#/")
            or (any(c.isupper() for c in cleaned[1:]) and any(c.islower() for c in cleaned))
            or cleaned.isupper()
        )
        weight = 2 if is_tech_like else 1
        freq[low] = freq.get(low, 0) + weight
        canonical.setdefault(low, cleaned)

    ranked = sorted(freq.items(), key=lambda kv: (-kv[1], kv[0]))
    return [canonical[k] for k, _ in ranked[:30]]


def audit_resume(resume_text: str, jd_text: str | None = None) -> dict:
    lower_text = resume_text.lower()
    words = re.findall(r"\b\w+\b", resume_text)
    word_count = len(words)
    bullets = extract_bullets(resume_text)

    issues: list[str] = []
    strengths: list[str] = []

    # 1. Structure & ATS Compliance (20 pts)
    structure_score = 20
    missing_sections = [
        name for name, pat in REQUIRED_SECTIONS.items()
        if not re.search(pat, lower_text)
    ]
    if missing_sections:
        penalty = min(12, len(missing_sections) * 4)
        structure_score -= penalty
        issues.append(f"Missing standard sections: {', '.join(missing_sections)}")
    else:
        strengths.append("All core ATS sections present (Summary, Experience, Skills, Education)")

    has_email = bool(re.search(r"[\w.+-]+@[\w-]+\.[\w.-]+", resume_text))
    has_profile_link = bool(re.search(r"(github\.com|linkedin\.com)", lower_text))
    if not has_email:
        structure_score -= 4
        issues.append("No email address detected")
    if not has_profile_link:
        structure_score -= 2
        issues.append("No GitHub or LinkedIn link detected")
    if "|" in resume_text and re.search(r"^\|.+\|$", resume_text, re.M):
        structure_score -= 4
        issues.append("Markdown tables detected — avoid tables for ATS parsing safety")
    structure_score = max(0, structure_score)

    # 2. Word Budget & Scannability (20 pts)
    scannability_score = 20
    if word_count < 280:
        scannability_score -= 8
        issues.append(f"Resume is very short ({word_count} words; target 400–650 for 1 page)")
    elif word_count > 800:
        scannability_score -= 6
        issues.append(f"Resume may exceed 1 page ({word_count} words; target 400–650)")
    else:
        strengths.append(f"Healthy length ({word_count} words)")

    long_bullets = [b for b in bullets if len(b.split()) > 30]
    if long_bullets:
        penalty = min(10, len(long_bullets) * 2)
        scannability_score -= penalty
        issues.append(
            f"{len(long_bullets)} bullet(s) exceed 30 words (keep bullets crisp, 1–2 lines): "
            f"e.g. \"{long_bullets[0][:70]}...\""
        )
    scannability_score = max(0, scannability_score)

    # 3. Action Verbs & Concrete Impact (25 pts)
    impact_score = 25
    weak_found = []
    strong_count = 0
    quantified_count = 0
    for b in bullets:
        b_low = b.lower()
        if any(b_low.startswith(w) for w in WEAK_STARTERS):
            weak_found.append(b[:65])
        first_word = re.sub(r"[^a-z]", "", b_low.split()[0]) if b_low.split() else ""
        if first_word in STRONG_VERBS:
            strong_count += 1
        if re.search(r"\b\d+[%+xXkKmM]?\b", b):
            quantified_count += 1

    if weak_found:
        penalty = min(12, len(weak_found) * 4)
        impact_score -= penalty
        issues.append(f"{len(weak_found)} bullet(s) start with weak passive phrasing (e.g. \"{weak_found[0]}...\")")

    if bullets:
        strong_ratio = strong_count / len(bullets)
        if strong_ratio < 0.45:
            impact_score -= 6
            issues.append(f"Only {strong_count}/{len(bullets)} bullets start with strong action verbs")
        else:
            strengths.append(f"Strong action-verb coverage ({strong_count}/{len(bullets)} bullets)")

        if quantified_count == 0:
            impact_score -= 5
            issues.append("No quantified scope/metrics detected in bullets — add real numbers where truthful")
    else:
        impact_score -= 10
        issues.append("No bullet points detected under Experience/Projects")
    impact_score = max(0, impact_score)

    # 4. Anti-AI & Anti-Fluff Hygiene (15 pts)
    hygiene_score = 15
    found_cliches = [c for c in AI_CLICHES if c in lower_text]
    if found_cliches:
        penalty = min(15, len(found_cliches) * 5)
        hygiene_score -= penalty
        issues.append(f"AI/resume cliché phrases found: {', '.join(found_cliches)}")
    else:
        strengths.append("Zero AI-cliché filler phrases detected")
    hygiene_score = max(0, hygiene_score)

    # 5. JD Keyword Match (20 pts)
    matched_keywords: list[str] = []
    missing_keywords: list[str] = []
    if jd_text:
        jd_keywords = extract_jd_keywords(jd_text)
        for kw in jd_keywords:
            if re.search(rf"\b{re.escape(kw.lower())}\b", lower_text):
                matched_keywords.append(kw)
            else:
                missing_keywords.append(kw)
        ratio = len(matched_keywords) / max(1, len(jd_keywords))
        jd_score = round(20 * ratio)
        if missing_keywords:
            issues.append(
                "Missing JD keywords (add ONLY if truthful): "
                + ", ".join(missing_keywords[:10])
            )
        strengths.append(f"JD keyword match: {len(matched_keywords)}/{len(jd_keywords)} ({int(ratio * 100)}%)")
    else:
        jd_score = 20

    total = structure_score + scannability_score + impact_score + hygiene_score + jd_score
    if total >= 80:
        verdict = "READY"
        exit_code = 0
    elif total >= 60:
        verdict = "NEEDS POLISH"
        exit_code = 2
    else:
        verdict = "REWRITE"
        exit_code = 3

    return {
        "score": total,
        "verdict": verdict,
        "exit_code": exit_code,
        "word_count": word_count,
        "bullet_count": len(bullets),
        "breakdown": {
            "structure_ats": f"{structure_score}/20",
            "scannability": f"{scannability_score}/20",
            "action_impact": f"{impact_score}/25",
            "anti_ai_hygiene": f"{hygiene_score}/15",
            "jd_keyword_match": f"{jd_score}/20",
        },
        "strengths": strengths,
        "issues": issues,
        "matched_keywords": matched_keywords,
        "missing_keywords": missing_keywords[:12],
    }


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a resume for ATS compliance and recruiter readability.")
    parser.add_argument("--resume", required=True, help="Path to resume Markdown or text file")
    parser.add_argument("--jd", help="Optional path to target job description text file")
    parser.add_argument("--json", action="store_true", dest="as_json", help="Output JSON report")
    args = parser.parse_args()

    resume_path = Path(args.resume)
    if not resume_path.is_file():
        print(f"Error: Resume file not found: {resume_path}", file=sys.stderr)
        return 1

    resume_text = resume_path.read_text(encoding="utf-8")
    jd_text = None
    if args.jd:
        jd_path = Path(args.jd)
        if not jd_path.is_file():
            print(f"Error: JD file not found: {jd_path}", file=sys.stderr)
            return 1
        jd_text = jd_path.read_text(encoding="utf-8")

    report = audit_resume(resume_text, jd_text)

    if args.as_json:
        print(json.dumps(report, indent=2))
    else:
        print(f"RESUME AUDIT: {report['score']}/100 — {report['verdict']}")
        print(f"Words: {report['word_count']} | Bullets: {report['bullet_count']}")
        print("Breakdown:")
        for k, v in report["breakdown"].items():
            print(f"  - {k}: {v}")
        if report["strengths"]:
            print("Strengths:")
            for s in report["strengths"]:
                print(f"  + {s}")
        if report["issues"]:
            print("Fixes Needed:")
            for issue in report["issues"]:
                print(f"  ! {issue}")

    return report["exit_code"]


if __name__ == "__main__":
    raise SystemExit(main())
