#!/usr/bin/env python3
"""Generate and verify the complete A-Z skills catalog in SKILLS.md."""

from __future__ import annotations

import argparse
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple

FRONTMATTER_RE = re.compile(r"^---\r?\n(.*?)\r?\n---(?:\r?\n(.*))?$", re.DOTALL)
TOP_KEY_RE = re.compile(r"^([A-Za-z0-9_-]+):(.*)$")
MAX_DESC_LEN = 220


def clean_scalar(text: str) -> str:
    """Normalize whitespace, strip outer quotes, and escape Markdown table pipes."""
    val = re.sub(r"\s+", " ", text).strip()
    if len(val) >= 2 and val[0] == val[-1] and val[0] in ('"', "'"):
        q = val[0]
        val = val[1:-1].strip()
        if q == '"':
            val = val.replace('\\"', '"')
    val = val.replace("|", "\\|")
    return val[: MAX_DESC_LEN - 3].rstrip() + "..." if len(val) > MAX_DESC_LEN else val


def parse_frontmatter(raw: str) -> Tuple[Dict[str, str], str]:
    """Extract top-level scalar fields and body text from SKILL.md without PyYAML."""
    m = FRONTMATTER_RE.match(raw)
    if not m:
        return {}, raw
    lines = m.group(1).splitlines()
    fields: Dict[str, str] = {}
    idx = 0
    while idx < len(lines):
        km = TOP_KEY_RE.match(lines[idx])
        if not km:
            idx += 1
            continue
        key, rest = km.group(1).strip(), km.group(2).strip()
        is_block = rest in (">", ">-", "|", "|-", "")
        parts = [] if is_block else [rest]
        idx += 1
        while idx < len(lines):
            nxt = lines[idx]
            if (not is_block and not nxt.strip()) or (nxt.strip() and not nxt[0].isspace() and TOP_KEY_RE.match(nxt)):
                break
            if nxt.strip():
                parts.append(nxt.strip())
            idx += 1
        fields[key] = " ".join(parts)
    return fields, m.group(2) or ""


def fallback_description(body: str) -> str:
    """Return the first non-heading prose line when frontmatter lacks description."""
    for ln in body.splitlines():
        s = ln.strip()
        if s and not s.startswith(("#", "---", "```", ">")):
            return clean_scalar(s)
    return "No description provided."


def detect_bundled(skill_dir: Path) -> str:
    """Summarize bundled helper directories (scripts, references, assets/resources)."""
    checks = (("scripts", ("scripts",)), ("refs", ("references",)), ("assets", ("assets", "resources")))
    tags = [
        label
        for label, names in checks
        if any((skill_dir / n).is_dir() and any(not c.name.startswith(".") for c in (skill_dir / n).iterdir()) for n in names)
    ]
    return ", ".join(tags) if tags else "—"


def collect_skills(skills_dir: Path) -> List[Tuple[str, str, str]]:
    """Collect sorted (folder_name, description, bundled) tuples from skills/*/SKILL.md."""
    entries: List[Tuple[str, str, str]] = []
    for p in sorted(skills_dir.iterdir(), key=lambda d: d.name.lower()):
        if not p.is_dir() or p.name.startswith(".") or not (p / "SKILL.md").is_file():
            continue
        fields, body = parse_frontmatter((p / "SKILL.md").read_text(encoding="utf-8"))
        desc = clean_scalar(fields.get("description", "")) or fallback_description(body)
        entries.append((p.name, desc, detect_bundled(p)))
    return entries


def render_markdown(entries: List[Tuple[str, str, str]]) -> str:
    """Render the complete A-Z Markdown skills catalog."""
    total = len(entries)
    grouped: Dict[str, List[Tuple[int, str, str, str]]] = defaultdict(list)
    for num, (folder, desc, bundled) in enumerate(entries, start=1):
        ch = folder[0].upper()
        grouped[ch if ch.isalpha() else "0-9"].append((num, folder, desc, bundled))

    letters = sorted(grouped.keys())
    jump = " · ".join(f"[{lt}](#{lt.lower()})" for lt in letters)
    out = [
        f"# Complete Skills Catalog ({total} Skills)",
        "",
        f"All **{total}** on-demand skills in `skills/`. Invoke any skill in chat with `/<skill-name>` or install a single skill cleanly via `./install.sh --local --skill <name>`.",
        "",
        "Regenerate this catalog anytime with `python3 scripts/generate_skills_list.py`.",
        "",
        f"**Jump to:** {jump}",
        "",
    ]
    for lt in letters:
        out.extend([f"## {lt}", "", "| # | Skill | Slash Command | Description | Bundled |", "| ---: | :--- | :--- | :--- | :--- |"])
        out.extend(f"| {num} | [{folder}](./skills/{folder}/SKILL.md) | `/{folder}` | {desc} | {bundled} |" for num, folder, desc, bundled in grouped[lt])
        out.append("")
    return "\n".join(out)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate or verify SKILLS.md.")
    parser.add_argument("--check", action="store_true", help="Exit non-zero if SKILLS.md is out of date.")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    entries = collect_skills(repo_root / "skills")
    rendered = render_markdown(entries)
    out_file = repo_root / "SKILLS.md"

    if args.check:
        current = out_file.read_text(encoding="utf-8") if out_file.is_file() else ""
        if current != rendered:
            print(f"[ERR]  {out_file} is out of date. Run: python3 scripts/generate_skills_list.py", file=sys.stderr)
            return 1
        print(f"[OK]   {out_file.name} is up to date ({len(entries)} skills).")
        return 0

    out_file.write_text(rendered, encoding="utf-8")
    print(f"[OK]   Wrote {out_file} ({len(entries)} skills).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
