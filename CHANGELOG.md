# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-11-17

### Added

- MkDocs Material self-service portal for the fictional Acme Corp IT Service Desk with search, dark mode, custom theme, logo and favicon, deployed to GitHub Pages.
- Knowledge base with 21 articles in 7 categories, a shared article template, YAML front matter (`id`, `title`, `category`, `level`, `tags`, `estimated_time`, `last_reviewed`) and a generated category index.
- `tools/validate_kb.py` and `tools/gen_kb_index.py` with pytest coverage.
- ITIL 4 process pages: incident vs. service request, priority matrix with SLA targets, escalation flow, EN/ES response templates, onboarding/offboarding checklists.
- Ten ticket case studies marked as practice scenarios.
- PowerShell toolkit: `Get-SystemDiagnostics`, `Test-Connectivity`, `Clear-TempFiles`, `Export-InstalledSoftware`, `New-BulkADUser`, `Get-InactiveAccount`, `Reset-PrintSpooler`, with sample data.
- Pester test suite and PSScriptAnalyzer settings; CI on Windows PowerShell 5.1 and PowerShell 7.
- Script reference pages generated from comment-based help (`tools/Build-ScriptDoc.ps1`).
- Tools & Ticketing guide (Zendesk / Freshdesk mapping), technical decisions, home lab plan.
- Dockerfile and docker-compose for local preview.

[1.0.0]: https://github.com/lucaswsanchez/helpdesk-kb/releases/tag/v1.0.0
