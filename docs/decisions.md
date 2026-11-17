---
title: Technical Decisions
---

# Technical Decisions

Short architecture decision records (ADR-style) for the choices that shaped this project.

## ADR-1: Docs as code with MkDocs Material on GitHub Pages

**Context.** A service desk knowledge base needs search, good navigation and a review process, and this one must be public and free to host.

**Decision.** Write everything in Markdown in the Git repository, build it with **MkDocs Material** and deploy to **GitHub Pages** with GitHub Actions.

**Why.** No server, database or license to maintain; built-in client-side search, dark mode and Mermaid diagrams; every change to an article goes through a pull request with history and review, the same way code does.

**Trade-off.** No in-browser editing or per-article analytics. A real company would likely use the KB inside its ticketing tool (see [Tools & Ticketing](tools-ticketing.md)); the content and structure transfer directly.

## ADR-2: YAML front matter is a validated contract

**Context.** Articles must stay consistent as the KB grows, and other tools (a planned AI triage assistant using RAG) need to read them reliably.

**Decision.** Every article has front matter with `id`, `title`, `category`, `level`, `tags`, `estimated_time` and `last_reviewed`, and a fixed section order. `tools/validate_kb.py` enforces it in CI, and the KB index is generated from the front matter.

**Why.** Machine-readable metadata enables filtering (L1 vs L2), retrieval and badges without parsing prose. Validation in CI turns "please follow the template" into a check that cannot be forgotten.

## ADR-3: Scripts are safe by default

**Context.** Support scripts run on users' computers and in Active Directory; a mistake can lock someone out or delete data.

**Decision.** Diagnostic scripts are **read-only**. Every script that changes state uses `SupportsShouldProcess` (`-WhatIf`, `-Confirm`). The AD script has a **simulation mode** that runs automatically when the ActiveDirectory module is missing. Generated passwords exist only as `SecureString` and are never printed or logged.

**Why.** Technicians can preview every change, validate a CSV from any workstation, and attach the output to a ticket as evidence.

## ADR-4: Test without production, on both PowerShell editions

**Context.** The scripts touch services, the registry, the network and Active Directory, none of which should be changed by a test run, and CI runners have no domain.

**Decision.** Pester tests use `TestDrive`, a loopback `TcpListener`, a temporary registry key, mocked services and stubbed AD cmdlets. Helper functions are extracted from the script's AST so they can be unit-tested without running the script body. The suite runs on **Windows PowerShell 5.1 and PowerShell 7** in CI, and PSScriptAnalyzer lints everything.

**Why.** Windows PowerShell 5.1 is still the default shell on Windows 10/11 where these scripts would run, while PowerShell 7 is the future; supporting both avoids surprises. Deterministic tests make CI trustworthy.

## ADR-5: Generate script docs from comment-based help

**Context.** Documentation that lives apart from code drifts.

**Decision.** `tools/Build-ScriptDoc.ps1` generates each script's page from its comment-based help and AST (parameters, types, defaults, examples, `-WhatIf` support). CI fails if a page is stale.

**Why.** One source of truth: `Get-Help` in the console and the website always match.

## ADR-6: Pin MkDocs below 2.0

**Context.** The Material for MkDocs team warns that MkDocs 2.0 removes the plugin system and theme overrides with no migration path.

**Decision.** `requirements.txt` pins `mkdocs>=1.6,<2` and `mkdocs-material==9.7.*`.

**Why.** A reproducible build today; upgrading becomes a deliberate decision rather than a surprise failure.
