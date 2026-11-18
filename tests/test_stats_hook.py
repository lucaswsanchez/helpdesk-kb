"""Tests for hooks/stats.py (overview numbers computed at build time)."""

from __future__ import annotations

import sys
from pathlib import Path
from types import SimpleNamespace

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "hooks"))

import stats  # noqa: E402


def test_stats_match_repository_content():
    s = stats.compute_stats(ROOT / "docs", ROOT)
    assert s["kb_total"] == len(list((ROOT / "docs" / "kb").glob("kb-*.md")))
    assert s["kb_l1"] + s["kb_l2"] == s["kb_total"]
    assert s["kb_categories"] == 7
    assert s["tickets_total"] == len(list((ROOT / "docs" / "tickets").glob("tck-*.md")))
    # Every incident case except the service request has a priority.
    assert s["tickets_p2"] + s["tickets_p3"] + s["tickets_p4"] == s["tickets_total"] - 1
    assert s["scripts_total"] == len(list((ROOT / "scripts").glob("*.ps1")))


def test_placeholders_are_replaced():
    stats.on_config({"docs_dir": str(ROOT / "docs")})
    page = SimpleNamespace(file=SimpleNamespace(src_path="index.md"))
    out = stats.on_page_markdown("Articles: {{ stat:kb_total }} / {{stat:scripts_total}}", page, None, None)
    assert "{{" not in out
    assert out.startswith("Articles: ")


def test_unknown_placeholder_fails_the_build():
    stats.on_config({"docs_dir": str(ROOT / "docs")})
    page = SimpleNamespace(file=SimpleNamespace(src_path="index.md"))
    with pytest.raises(KeyError):
        stats.on_page_markdown("{{ stat:does_not_exist }}", page, None, None)
