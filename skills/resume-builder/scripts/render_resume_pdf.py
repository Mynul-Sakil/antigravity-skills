#!/usr/bin/env python3
"""
ATS-Safe Markdown Resume to PDF Renderer (Zero External Python Dependencies).

Converts a resume-builder Markdown resume into a crisp, single-column,
text-selectable PDF using Google Chrome headless (--print-to-pdf).

Output filename format:
  <out-dir>/<position-slug>_<YYYY-MM-DD>_<HH-MM>.pdf

Exit codes:
  0 -> PDF generated and fits cleanly on 1 page
  2 -> PDF generated, but spans > 1 page (re-run with --compact or trim text)
  1 -> Error (missing input file, Chrome not found, or render failure)
"""

from __future__ import annotations

import argparse
import datetime as dt
import html
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

CHROME_CANDIDATES = [
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
    "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser",
    "google-chrome",
    "chromium",
    "chromium-browser",
]


def find_chrome(override: str | None = None) -> str | None:
    if override:
        p = Path(override)
        if p.exists():
            return str(p)
        found = shutil.which(override)
        if found:
            return found
        return None
    for candidate in CHROME_CANDIDATES:
        if candidate.startswith("/"):
            if Path(candidate).exists():
                return candidate
        else:
            found = shutil.which(candidate)
            if found:
                return found
    return None


def slugify(text: str) -> str:
    cleaned = re.sub(r"[^a-zA-Z0-9]+", "-", text.strip().lower()).strip("-")
    return cleaned or "resume"


def extract_position(md_text: str, fallback_stem: str) -> str:
    lines = [line.strip() for line in md_text.splitlines() if line.strip()]
    for idx, line in enumerate(lines[:6]):
        # Pattern 1: **Target Role Title** right under # Name
        m_bold = re.fullmatch(r"\*\*(.+?)\*\*", line)
        if m_bold and idx > 0:
            return m_bold.group(1).strip()
        # Pattern 2: # Name — Role Title
        if line.startswith("# "):
            heading = line[2:].strip()
            for sep in (" — ", " - ", " | "):
                if sep in heading:
                    return heading.split(sep, 1)[1].strip()
    return fallback_stem


def format_inline(text: str) -> str:
    """Convert inline Markdown links, bold, italic, and code safely to HTML."""
    # Protect markdown links first with placeholders
    links: list[str] = []

    def _link_repl(match: re.Match[str]) -> str:
        label = html.escape(match.group(1))
        url = html.escape(match.group(2), quote=True)
        links.append(f'<a href="{url}">{label}</a>')
        return f"\x00LINK{len(links) - 1}\x00"

    temp = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", _link_repl, text)
    escaped = html.escape(temp)

    # Inline code
    escaped = re.sub(r"`([^`]+)`", r"<code>\1</code>", escaped)
    # Bold
    escaped = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", escaped)
    # Italic
    escaped = re.sub(r"\*([^*]+)\*", r"<em>\1</em>", escaped)

    # Restore links
    for i, link_html in enumerate(links):
        escaped = escaped.replace(f"\x00LINK{i}\x00", link_html)

    return escaped


def markdown_to_html_body(md_text: str) -> tuple[str, str]:
    """Parse resume-builder Markdown into clean single-column semantic HTML."""
    lines = md_text.splitlines()
    out: list[str] = []
    in_list = False
    in_header = True
    doc_title = "Resume"

    def close_list() -> None:
        nonlocal in_list
        if in_list:
            out.append("</ul>")
            in_list = False

    for raw in lines:
        line = raw.strip()
        if not line:
            close_list()
            continue

        if line == "---":
            close_list()
            continue

        if line.startswith("# "):
            close_list()
            title_text = line[2:].strip()
            doc_title = title_text
            out.append('<header class="resume-header">')
            out.append(f"<h1>{format_inline(title_text)}</h1>")
            continue

        if line.startswith("## "):
            close_list()
            if in_header:
                out.append("</header>")
                in_header = False
            out.append(f"<h2>{format_inline(line[3:].strip())}</h2>")
            continue

        if line.startswith("### "):
            close_list()
            if in_header:
                out.append("</header>")
                in_header = False
            out.append(f"<h3>{format_inline(line[4:].strip())}</h3>")
            continue

        if re.match(r"^[-*•]\s+", line):
            if in_header:
                out.append("</header>")
                in_header = False
            if not in_list:
                out.append("<ul>")
                in_list = True
            item = re.sub(r"^[-*•]\s+", "", line)
            out.append(f"<li>{format_inline(item)}</li>")
            continue

        # Header lines (role + contact) vs body paragraphs/metadata
        close_list()
        if in_header:
            if re.fullmatch(r"\*\*(.+?)\*\*", line):
                role_inner = line[2:-2].strip()
                out.append(f'<p class="role">{format_inline(role_inner)}</p>')
            else:
                out.append(f'<p class="contact">{format_inline(line)}</p>')
        elif re.fullmatch(r"\*(.+?)\*", line):
            meta_inner = line[1:-1].strip()
            out.append(f'<p class="meta">{format_inline(meta_inner)}</p>')
        else:
            out.append(f'<p class="body-text">{format_inline(line)}</p>')

    close_list()
    if in_header:
        out.append("</header>")

    return doc_title, "\n".join(out)


def build_html_document(title: str, body_html: str, page_size: str, compact: bool) -> str:
    page_css_size = "letter" if page_size == "letter" else "A4"
    margin = "0.28in 0.42in" if compact else "0.38in 0.46in"
    base_font = "8.6pt" if compact else "9.4pt"
    line_height = "1.24" if compact else "1.33"
    h1_size = "16.5pt" if compact else "18.5pt"
    h2_margin_top = "6.5pt" if compact else "9.5pt"
    h3_margin_top = "4pt" if compact else "5.5pt"
    li_margin = "1.3pt" if compact else "2.2pt"

    return f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <title>{html.escape(title)}</title>
  <style>
    @page {{
      size: {page_css_size};
      margin: {margin};
    }}
    * {{
      box-sizing: border-box;
    }}
    html, body {{
      margin: 0;
      padding: 0;
      background: #ffffff;
      color: #1f2937;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      font-size: {base_font};
      line-height: {line_height};
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }}
    a {{
      color: #1d4ed8;
      text-decoration: none;
    }}
    .resume-header {{
      margin-bottom: 6pt;
      padding-bottom: 5pt;
      border-bottom: 1.25pt solid #111827;
    }}
    h1 {{
      margin: 0 0 1.5pt 0;
      font-size: {h1_size};
      font-weight: 700;
      letter-spacing: -0.2pt;
      color: #111827;
      line-height: 1.15;
    }}
    .role {{
      margin: 0 0 3pt 0;
      font-size: 10.5pt;
      font-weight: 600;
      color: #1d4ed8;
    }}
    .contact {{
      margin: 0;
      font-size: 8.6pt;
      color: #374151;
    }}
    h2 {{
      margin: {h2_margin_top} 0 4pt 0;
      padding-bottom: 2pt;
      font-size: 9.8pt;
      font-weight: 700;
      text-transform: uppercase;
      letter-spacing: 0.6pt;
      color: #111827;
      border-bottom: 0.75pt solid #d1d5db;
      break-after: avoid;
      page-break-after: avoid;
    }}
    h3 {{
      margin: {h3_margin_top} 0 0.8pt 0;
      font-size: 9.2pt;
      font-weight: 700;
      color: #111827;
      break-after: avoid;
      page-break-after: avoid;
    }}
    .meta {{
      margin: 0 0 2.5pt 0;
      font-size: 8.5pt;
      font-style: italic;
      color: #4b5563;
      break-after: avoid;
      page-break-after: avoid;
    }}
    .body-text {{
      margin: 0 0 4pt 0;
      color: #1f2937;
    }}
    ul {{
      margin: 1.5pt 0 3.5pt 0;
      padding-left: 13pt;
    }}
    li {{
      margin: 0 0 {li_margin} 0;
      color: #1f2937;
    }}
    li strong {{
      color: #111827;
    }}
    code {{
      font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
      font-size: 8.6pt;
      background: #f3f4f6;
      padding: 0.5pt 2.5pt;
      border-radius: 2pt;
    }}
  </style>
</head>
<body>
{body_html}
</body>
</html>
"""


def count_pdf_pages(pdf_path: Path) -> int:
    """Count pages in a PDF using pure Python (matches /Type /Page excluding /Pages)."""
    data = pdf_path.read_bytes()
    matches = re.findall(rb"/Type\s*/Page(?![a-zA-Z])", data)
    return len(matches)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render a Markdown resume to an ATS-safe PDF in output/<position>_<YYYY-MM-DD>_<HH-MM>.pdf."
    )
    parser.add_argument("--resume", required=True, help="Path to source Markdown resume (.md)")
    parser.add_argument(
        "--out-dir",
        default="output",
        help="Output directory for generated PDF (default: ./output)",
    )
    parser.add_argument(
        "--position",
        default=None,
        help="Optional override for position name used in the output filename",
    )
    parser.add_argument(
        "--page-size",
        choices=("letter", "a4"),
        default="letter",
        help="PDF page size (default: letter)",
    )
    parser.add_argument(
        "--compact",
        action="store_true",
        help="Use slightly tighter margins and spacing to guarantee a 1-page fit",
    )
    parser.add_argument(
        "--keep-html",
        action="store_true",
        help="Also save the intermediate HTML next to the PDF for inspection",
    )
    parser.add_argument(
        "--chrome",
        default=None,
        help="Optional explicit path to Google Chrome / Chromium binary",
    )
    args = parser.parse_args()

    resume_path = Path(args.resume).expanduser().resolve()
    if not resume_path.exists():
        print(f"ERROR: Resume file not found: {resume_path}", file=sys.stderr)
        return 1

    chrome_bin = find_chrome(args.chrome)
    if not chrome_bin:
        print(
            "ERROR: Google Chrome / Chromium not found. Install Chrome or pass --chrome <path>.",
            file=sys.stderr,
        )
        return 1

    md_text = resume_path.read_text(encoding="utf-8")
    position_raw = args.position or extract_position(md_text, resume_path.stem)
    position_slug = slugify(position_raw)
    timestamp = dt.datetime.now().strftime("%Y-%m-%d_%H-%M")

    out_dir = Path(args.out_dir).expanduser().resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    pdf_path = out_dir / f"{position_slug}_{timestamp}.pdf"

    title, body_html = markdown_to_html_body(md_text)
    full_html = build_html_document(title, body_html, args.page_size, args.compact)

    if args.keep_html:
        html_path = out_dir / f"{position_slug}_{timestamp}.html"
        html_path.write_text(full_html, encoding="utf-8")
        temp_ctx = None
    else:
        temp_ctx = tempfile.TemporaryDirectory()
        html_path = Path(temp_ctx.name) / "resume.html"
        html_path.write_text(full_html, encoding="utf-8")

    try:
        cmd = [
            chrome_bin,
            "--headless=new",
            "--disable-gpu",
            "--no-pdf-header-footer",
            f"--print-to-pdf={pdf_path}",
            html_path.as_uri(),
        ]
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if result.returncode != 0 or not pdf_path.exists() or pdf_path.stat().st_size == 0:
            print(f"ERROR: Chrome failed to render PDF (code={result.returncode}).", file=sys.stderr)
            if result.stderr:
                print(result.stderr.strip(), file=sys.stderr)
            return 1
    finally:
        if temp_ctx is not None:
            temp_ctx.cleanup()

    size_kb = pdf_path.stat().st_size / 1024
    pages = count_pdf_pages(pdf_path)

    print(f"PDF GENERATED: {pdf_path}")
    print(f"Position: {position_raw} | Page Size: {args.page_size.upper()} | Size: {size_kb:.1f} KB | Pages: {pages}")

    if pages > 1:
        print(
            "WARNING: Resume spans more than 1 page. Re-run with --compact or trim 2-3 lines for a strict 1-page fit.",
            file=sys.stderr,
        )
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
