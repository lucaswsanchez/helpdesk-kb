---
title: Overview
hide:
  - navigation
  - toc
---

<div class="ops-header">
  <div class="ops-header__text">
    <p class="ops-eyebrow">Acme Corp &middot; IT Service Desk</p>
    <h1>Service Desk Overview</h1>
    <p>Knowledge base, incident procedures and technician toolkit in one workspace. Start typing what is happening, for example <em>"outlook not syncing"</em> or <em>KB-010</em>.</p>
  </div>
  <button type="button" class="ops-search-cta" data-cmdk-open aria-label="Open command palette">
    <span>Search articles, cases, scripts&hellip;</span> <kbd>Ctrl K</kbd>
  </button>
</div>

<div class="ops-stats" aria-label="Portal contents (computed from the repository at build time)">
  <a class="ops-stat" href="kb/">
    <span class="ops-stat__label">KB articles</span>
    <span class="ops-stat__value">{{ stat:kb_total }}</span>
    <span class="ops-stat__hint">{{ stat:kb_l1 }} L1 &middot; {{ stat:kb_l2 }} L2 &middot; {{ stat:kb_categories }} categories</span>
  </a>
  <a class="ops-stat" href="tickets/">
    <span class="ops-stat__label">Incident case studies</span>
    <span class="ops-stat__value">{{ stat:tickets_total }}</span>
    <span class="ops-stat__hint">{{ stat:tickets_p2 }} P2 &middot; {{ stat:tickets_p3 }} P3 &middot; {{ stat:tickets_p4 }} P4 &middot; practice</span>
  </a>
  <a class="ops-stat" href="scripts/">
    <span class="ops-stat__label">Diagnostic scripts</span>
    <span class="ops-stat__value">{{ stat:scripts_total }}</span>
    <span class="ops-stat__hint">PowerShell 5.1 &amp; 7 &middot; Pester-tested</span>
  </a>
  <a class="ops-stat" href="processes/priority-matrix/">
    <span class="ops-stat__label">Process pages</span>
    <span class="ops-stat__value">{{ stat:process_pages }}</span>
    <span class="ops-stat__hint">ITIL 4 &middot; priority &amp; SLA</span>
  </a>
</div>

<div class="ops-columns" markdown>

<div class="ops-panel" markdown>

## Most used procedures

| ID | Procedure | Level | Est. |
|---|---|---|---|
| KB-001 | [Reset a forgotten Microsoft 365 password](kb/kb-001-reset-m365-password.md) | <span class="badge badge--l1">L1</span> | 10 min |
| KB-003 | [Active Directory account locked out](kb/kb-003-ad-account-locked-out.md) | <span class="badge badge--l1">L1</span> | 10 min |
| KB-005 | [Outlook is not syncing email](kb/kb-005-outlook-not-syncing.md) | <span class="badge badge--l1">L1</span> | 20 min |
| KB-009 | [VPN does not connect](kb/kb-009-vpn-not-connecting.md) | <span class="badge badge--l1">L1</span> | 20 min |
| KB-010 | [Wi-Fi connected but no internet (DNS)](kb/kb-010-wifi-dns-troubleshooting.md) | <span class="badge badge--l1">L1</span> | 15 min |
| KB-012 | [Printer offline or jobs stuck](kb/kb-012-printer-offline.md) | <span class="badge badge--l1">L1</span> | 15 min |
| KB-018 | [Report a suspicious email (phishing)](kb/kb-018-phishing-suspicious-email.md) | <span class="badge badge--l1">L1</span> | 10 min |
| KB-020 | [New employee onboarding](kb/kb-020-employee-onboarding.md) | <span class="badge badge--l2">L2</span> | 60 min |

[All articles by category &rarr;](kb/index.md){ .ops-panel__link }

## Contact

| Channel | Use for | Hours |
|---|---|---|
| Portal (this site) | Self-service | 24/7 |
| `servicedesk@acme.example` | P3 / P4 requests | Mon–Fri 08–18 |
| Phone ext. `4357` | P1 / P2, you cannot work | On-call for P1 |

</div>

<div class="ops-panel" markdown>

## Priority &amp; SLA targets

| Priority | First response | Resolution |
|---|---|---|
| <span class="badge badge--p1">P1 Critical</span> | 15 min | 4 h |
| <span class="badge badge--p2">P2 High</span> | 30 min | 8 business h |
| <span class="badge badge--p3">P3 Medium</span> | 4 business h | 3 business days |
| <span class="badge badge--p4">P4 Low</span> | 1 business day | 5 business days |

[How priority is calculated &rarr;](processes/priority-matrix.md){ .ops-panel__link }

## Case states

| State | Meaning |
|---|---|
| <span class="badge badge--resolved">Resolved</span> | Fix applied and confirmed by the user |
| <span class="badge badge--escalated">Escalated</span> | Handed to L2/L3 or a vendor with a hand-off note |
| <span class="badge badge--security">Security</span> | Security incident, containment first |
| <span class="badge badge--request">Fulfilled</span> | Service request completed with approval |

</div>

</div>

<div class="ops-section" markdown>

## Workspaces

<div class="grid cards" markdown>

-   :material-alert-octagon-outline: **Incidents**

    Worked cases with classification, diagnosis, escalation and a resolution timeline.

    [Open incidents &rarr;](tickets/index.md)

-   :material-book-open-variant: **Knowledge Base**

    Step-by-step fixes with symptoms, cause and escalation criteria.

    [Browse the KB &rarr;](kb/index.md)

-   :material-console: **Diagnostics**

    PowerShell toolkit: system report, connectivity, cleanup, AD and print spooler.

    [Open the toolkit &rarr;](scripts/index.md)

-   :material-timer-sand: **SLA & Processes**

    Incident vs. request, priority matrix, escalation flow and templates.

    [Open processes &rarr;](processes/index.md)

-   :material-lan: **Infrastructure & Lab**

    Service dependency map, impact reference and the planned Windows Server lab.

    [Open the map &rarr;](infrastructure.md)

-   :material-ticket-outline: **Ticketing tools**

    How this KB, priorities and SLAs map to Zendesk and Freshdesk.

    [Read the guide &rarr;](tools-ticketing.md)

</div>

</div>

!!! info "About this portal"
    Acme Corp is a **fictional company** and this is a portfolio project. Counts above are computed from the repository when the site is built; there is no live monitoring or ticket queue behind this page. Incident cases are **practice scenarios**.
