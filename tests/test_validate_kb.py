"""Unit tests for tools/validate_kb.py and tools/gen_kb_index.py."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))

import gen_kb_index  # noqa: E402
import validate_kb  # noqa: E402

VALID_ARTICLE = """---
id: KB-001
title: Example Article
category: Network
level: L1
tags: [wifi, dns]
estimated_time: 15 min
last_reviewed: 2026-11-17
---

# Example Article

## Summary
Text.

## Applies to
Text.

## Symptoms
Text.

## Cause
Text.

## Resolution
1. Step.

## Escalation criteria
Text.

## Related articles
- [Other](kb-002-other.md)

## Last reviewed
2026-11-17 by Service Desk.
"""


def write(tmp_path: Path, name: str, content: str) -> Path:
    path = tmp_path / name
    path.write_text(content, encoding="utf-8")
    return path


def errors_for(tmp_path: Path, content: str, name: str = "kb-001-example.md") -> list[str]:
    write(tmp_path, "kb-002-other.md", VALID_ARTICLE.replace("KB-001", "KB-002"))
    path = write(tmp_path, name, content)
    return validate_kb.validate_article(validate_kb.parse_article(path))


def test_valid_article_has_no_errors(tmp_path):
    assert errors_for(tmp_path, VALID_ARTICLE) == []


def test_missing_front_matter(tmp_path):
    assert errors_for(tmp_path, "# Just a heading\n") == ["missing or invalid YAML front matter"]


@pytest.mark.parametrize("field", validate_kb.REQUIRED_FIELDS)
def test_each_required_field_is_enforced(tmp_path, field):
    lines = [ln for ln in VALID_ARTICLE.splitlines() if not ln.startswith(f"{field}:")]
    errors = errors_for(tmp_path, "\n".join(lines) + "\n")
    assert f"missing front matter field '{field}'" in errors


def test_invalid_category_and_level(tmp_path):
    content = VALID_ARTICLE.replace("category: Network", "category: Misc").replace("level: L1", "level: L3")
    errors = errors_for(tmp_path, content)
    assert any("category 'Misc'" in e for e in errors)
    assert any("level 'L3'" in e for e in errors)


def test_id_must_match_file_name(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE, name="kb-005-example.md")
    assert "id 'KB-001' does not match file name number" in errors


def test_bad_file_name(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE, name="kb-1-Example.md")
    assert any("file name must look like" in e for e in errors)


def test_tags_must_be_kebab_case(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("[wifi, dns]", "[WiFi, dns]"))
    assert any("lowercase-kebab-case" in e for e in errors)


def test_estimated_time_format(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("15 min", "quarter hour"))
    assert any("estimated_time" in e for e in errors)


def test_last_reviewed_must_be_date(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("last_reviewed: 2026-11-17", "last_reviewed: yesterday"))
    assert any("last_reviewed" in e for e in errors)


def test_h1_must_match_title(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("# Example Article", "# Something Else"))
    assert "H1 heading does not match front matter title" in errors


def test_missing_section(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("## Cause\nText.\n\n", ""))
    assert "missing section '## Cause'" in errors


def test_sections_out_of_order(tmp_path):
    content = VALID_ARTICLE.replace("## Symptoms", "## TMP").replace("## Cause", "## Symptoms").replace("## TMP", "## Cause")
    assert "required sections are not in template order" in errors_for(tmp_path, content)


def test_broken_related_link(tmp_path):
    errors = errors_for(tmp_path, VALID_ARTICLE.replace("kb-002-other.md", "kb-099-missing.md"))
    assert "broken link to 'kb-099-missing.md'" in errors


def test_duplicate_ids_detected(tmp_path):
    write(tmp_path, "kb-001-a.md", VALID_ARTICLE.replace("kb-002-other.md", "kb-001-a.md"))
    write(tmp_path, "kb-001-b.md", VALID_ARTICLE.replace("kb-002-other.md", "kb-001-a.md"))
    results = validate_kb.validate_dir(tmp_path)
    assert any("duplicate id 'KB-001'" in e for e in results["kb-001-b.md"])


def test_repository_kb_is_valid():
    """The real knowledge base must always pass validation."""
    results = validate_kb.validate_dir(validate_kb.DEFAULT_KB_DIR)
    assert len(results) >= 20
    problems = {name: errs for name, errs in results.items() if errs}
    assert problems == {}


def test_repository_kb_index_is_up_to_date():
    assert gen_kb_index.main(["--check"]) == 0
