"""MkDocs hook: replace {{ stat:NAME }} placeholders with numbers computed from the repo.

The overview page shows counts (articles, levels, cases, scripts) that must never
drift from the real content, so they are calculated at build time instead of
being typed by hand. Unknown placeholders fail the build.
"""

from __future__ import annotations

import re
from collections import Counter
from pathlib import Path

import yaml

PLACEHOLDER = re.compile(r"\{\{\s*stat:([a-z0-9_]+)\s*\}\}")
# Ticket field list: a "Priority" term followed by its definition line.
PRIORITY = re.compile(r"^Priority\n:\s+.*?\b(P[1-4])\b", re.M)

_stats: dict[str, int] = {}


def _front_matter(path: Path) -> dict:
    text = path.read_text(encoding="utf-8").replace("\r\n", "\n")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    return (yaml.safe_load(match.group(1)) or {}) if match else {}


def compute_stats(docs_dir: Path, repo_dir: Path) -> dict[str, int]:
    articles = [_front_matter(p) for p in sorted((docs_dir / "kb").glob("kb-*.md"))]
    levels = Counter(a.get("level") for a in articles)
    tickets = sorted((docs_dir / "tickets").glob("tck-*.md"))
    priorities = Counter()
    for t in tickets:
        found = PRIORITY.search(t.read_text(encoding="utf-8"))
        if found:
            priorities[found.group(1)] += 1
    return {
        "kb_total": len(articles),
        "kb_l1": levels.get("L1", 0),
        "kb_l2": levels.get("L2", 0),
        "kb_categories": len({a.get("category") for a in articles}),
        "tickets_total": len(tickets),
        "tickets_p2": priorities.get("P2", 0),
        "tickets_p3": priorities.get("P3", 0),
        "tickets_p4": priorities.get("P4", 0),
        "scripts_total": len(list((repo_dir / "scripts").glob("*.ps1"))),
        "process_pages": len([p for p in (docs_dir / "processes").glob("*.md") if p.name != "index.md"]),
    }


def on_config(config, **kwargs):
    docs_dir = Path(config["docs_dir"])
    _stats.clear()
    _stats.update(compute_stats(docs_dir, docs_dir.parent))
    return config


def on_page_markdown(markdown, page, config, files, **kwargs):
    def replace(match: re.Match) -> str:
        name = match.group(1)
        if name not in _stats:
            raise KeyError(f"Unknown stat placeholder '{name}' in {page.file.src_path}")
        return str(_stats[name])

    return PLACEHOLDER.sub(replace, markdown)
