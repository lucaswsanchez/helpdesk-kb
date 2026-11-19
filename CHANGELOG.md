# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-11-18

### Fixed

- Mobile layout: wide data tables render as labelled cards on phones (no horizontal scrolling on any of the 54 pages at 375px), compact overview tables, 2x2 stat tiles, smaller headings and a full site title in the header.
- Command palette: the result count meant for screen readers was visible; on phones it opens full width with larger tap targets, and keyboard hints are hidden on touch screens.
- Plain-text templates and hand-off notes wrap instead of scrolling.
- Design audit fixes: balanced overview columns, full-width tables with aligned columns, centered card grids without orphans, KB metadata under the title, state labels that match their colors, palette-colored admonitions and KB IDs in the sidebar.

## [1.1.0] - 2026-11-17

### Added

- Operations-workspace design system (dark by default, accessible light mode) documented on a new Design System page.
- Ctrl+K / Cmd+K command palette over the site's search index, keyboard and screen-reader accessible, with no new dependencies.
- Service Desk Overview page with counts computed at build time by `hooks/stats.py` (with pytest coverage).
- Priority, state and support-level badges used consistently across the overview, KB index, priority matrix, infrastructure map and ticket cases.
- Resolution timeline (stages, no timestamps) and a Status field in every ticket case.
- Infrastructure Map page with a Mermaid service dependency map, impact reference and triage path.

### Changed

- Navigation reorganized into Overview, Incidents, Knowledge Base, Diagnostics, SLA & Processes, Infrastructure & Lab and About.
- KB article metadata badges now show level, category, estimated time and last-reviewed date.

### Removed

- The decorative "service status" strip on the home page, which could be mistaken for live monitoring.

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

[1.1.1]: https://github.com/lucaswsanchez/helpdesk-kb/releases/tag/v1.1.1
[1.1.0]: https://github.com/lucaswsanchez/helpdesk-kb/releases/tag/v1.1.0
[1.0.0]: https://github.com/lucaswsanchez/helpdesk-kb/releases/tag/v1.0.0
