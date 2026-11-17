"""Validate every KB article in docs/kb against the KB template.

Checks the YAML front matter (required fields and allowed values), the body
structure (H1 matches the title, required sections in order) and that links
to other KB articles point to files that exist.

The front matter is a stable contract: other tools (for example a RAG
assistant) read `id`, `title`, `category`, `level` and `tags` directly.

Usage:
    python tools/validate_kb.py            # validate docs/kb
    python tools/validate_kb.py path/to/kb
"""

from __future__ import annotations

import datetime as dt
import re
import sys
from dataclasses import dataclass, field
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_KB_DIR = ROOT / "docs" / "kb"

REQUIRED_FIELDS = ("id", "title", "category", "level", "tags", "estimated_time", "last_reviewed")
ALLOWED_CATEGORIES = {
    "Accounts & Identity",
    "Microsoft 365",
    "Network",
    "Hardware & Printing",
    "Software",
    "Security",
    "Onboarding & Offboarding",
}
ALLOWED_LEVELS = {"L1", "L2"}
REQUIRED_SECTIONS = (
    "Summary",
    "Applies to",
    "Symptoms",
    "Cause",
    "Resolution",
    "Escalation criteria",
    "Related articles",
    "Last reviewed",
)

ID_RE = re.compile(r"^KB-\d{3}$")
FILENAME_RE = re.compile(r"^kb-(\d{3})-[a-z0-9]+(?:-[a-z0-9]+)*\.md$")
TAG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
TIME_RE = re.compile(r"^\d{1,3} min$")
KB_LINK_RE = re.compile(r"\]\((kb-[^)#\s]+\.md)(?:#[^)]*)?\)")


@dataclass
class Article:
    path: Path
    meta: dict = field(default_factory=dict)
    body: str = ""


def parse_article(path: Path) -> Article:
    """Split a Markdown file into YAML front matter and body."""
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", text, re.DOTALL)
    if not match:
        return Article(path=path, meta={}, body=text)
    meta = yaml.safe_load(match.group(1)) or {}
    if not isinstance(meta, dict):
        meta = {}
    return Article(path=path, meta=meta, body=match.group(2))


def validate_article(article: Article) -> list[str]:
    """Return a list of human-readable problems for one article (empty = valid)."""
    errors: list[str] = []
    meta, name = article.meta, article.path.name

    if not meta:
        return ["missing or invalid YAML front matter"]

    for key in REQUIRED_FIELDS:
        if key not in meta or meta[key] in (None, "", []):
            errors.append(f"missing front matter field '{key}'")

    file_match = FILENAME_RE.match(name)
    if not file_match:
        errors.append("file name must look like 'kb-NNN-short-slug.md'")

    kb_id = meta.get("id")
    if kb_id is not None:
        if not isinstance(kb_id, str) or not ID_RE.match(kb_id):
            errors.append(f"id '{kb_id}' must look like 'KB-NNN'")
        elif file_match and kb_id != f"KB-{file_match.group(1)}":
            errors.append(f"id '{kb_id}' does not match file name number")

    category = meta.get("category")
    if category is not None and category not in ALLOWED_CATEGORIES:
        errors.append(f"category '{category}' is not one of {sorted(ALLOWED_CATEGORIES)}")

    level = meta.get("level")
    if level is not None and level not in ALLOWED_LEVELS:
        errors.append(f"level '{level}' must be L1 or L2")

    tags = meta.get("tags")
    if tags is not None:
        if not isinstance(tags, list) or not tags:
            errors.append("tags must be a non-empty list")
        else:
            bad = [t for t in tags if not isinstance(t, str) or not TAG_RE.match(t)]
            if bad:
                errors.append(f"tags must be lowercase-kebab-case: {bad}")

    est = meta.get("estimated_time")
    if est is not None and (not isinstance(est, str) or not TIME_RE.match(est)):
        errors.append(f"estimated_time '{est}' must look like '15 min'")

    reviewed = meta.get("last_reviewed")
    if reviewed is not None and not isinstance(reviewed, dt.date):
        errors.append(f"last_reviewed '{reviewed}' must be a YYYY-MM-DD date")

    # Body structure
    h1 = re.search(r"^# (.+)$", article.body, re.MULTILINE)
    if not h1:
        errors.append("missing H1 heading")
    elif meta.get("title") and h1.group(1).strip() != meta["title"]:
        errors.append("H1 heading does not match front matter title")

    sections = re.findall(r"^## (.+?)\s*$", article.body, re.MULTILINE)
    positions = []
    for section in REQUIRED_SECTIONS:
        if section not in sections:
            errors.append(f"missing section '## {section}'")
        else:
            positions.append(sections.index(section))
    if len(positions) == len(REQUIRED_SECTIONS) and positions != sorted(positions):
        errors.append("required sections are not in template order")

    # Links to sibling KB articles must resolve
    for target in KB_LINK_RE.findall(article.body):
        if not (article.path.parent / target).exists():
            errors.append(f"broken link to '{target}'")

    return errors


def validate_dir(kb_dir: Path) -> dict[str, list[str]]:
    """Validate all kb-*.md files in a directory, including cross-file checks."""
    results: dict[str, list[str]] = {}
    seen_ids: dict[str, str] = {}
    for path in sorted(kb_dir.glob("kb-*.md")):
        article = parse_article(path)
        errors = validate_article(article)
        kb_id = article.meta.get("id")
        if isinstance(kb_id, str):
            if kb_id in seen_ids:
                errors.append(f"duplicate id '{kb_id}' (also in {seen_ids[kb_id]})")
            seen_ids[kb_id] = path.name
        results[path.name] = errors
    return results


def main(argv: list[str] | None = None) -> int:
    args = sys.argv[1:] if argv is None else argv
    kb_dir = Path(args[0]) if args else DEFAULT_KB_DIR
    results = validate_dir(kb_dir)
    if not results:
        print(f"No KB articles found in {kb_dir}", file=sys.stderr)
        return 1

    failed = {name: errs for name, errs in results.items() if errs}
    for name, errs in failed.items():
        for err in errs:
            print(f"{name}: {err}", file=sys.stderr)

    if failed:
        print(f"\n{len(failed)} of {len(results)} articles have problems.", file=sys.stderr)
        return 1
    print(f"All {len(results)} KB articles are valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
