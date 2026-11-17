---
title: KB Article Template
---

# KB Article Template

Every knowledge base article follows the same structure so technicians and users always know where to look. New articles are copied from this template and must pass the automated validator (`tools/validate_kb.py`) in CI.

## File naming

`docs/kb/kb-NNN-short-slug.md`, for example `kb-010-wifi-dns-troubleshooting.md`.

## Front matter

```yaml
---
id: KB-010                      # unique, KB-NNN
title: Wi-Fi Connected but No Internet (DNS and Connectivity)
category: Network               # one of the allowed categories below
level: L1                       # L1 or L2
tags: [wifi, dns, ipconfig, nslookup]
estimated_time: 15 min          # typical hands-on resolution time
last_reviewed: 2026-11-17       # YYYY-MM-DD
---
```

Allowed categories: `Accounts & Identity`, `Microsoft 365`, `Network`, `Hardware & Printing`, `Software`, `Security`, `Onboarding & Offboarding`.

## Body sections (in this order)

```markdown
# <Title>

## Summary
One or two sentences: what this fixes and for whom.

## Applies to
Systems, versions and user groups in scope.

## Symptoms
What the user sees or reports (error messages verbatim).

## Cause
The most common root causes.

## Resolution
Numbered, testable steps. Start with the least disruptive fix.
Mark steps that need a technician or admin rights.

## Escalation criteria
When L1 must escalate, to whom, and what to include in the ticket.

## Related articles
Links to other KB articles.

## Last reviewed
YYYY-MM-DD by Service Desk.
```

## Writing guidelines

- Write for the person reading it under pressure: short sentences, one action per step.
- Quote error messages exactly so search finds them.
- Commands go in code blocks and must be safe to copy and paste.
- Never ask users to share passwords. Never include real names, IPs or secrets.
