---
title: Overview
hide:
  - navigation
  - toc
---

<div class="ops-header">
  <div class="ops-header__text">
    <p class="ops-eyebrow">Acme Corp &middot; IT Service Desk</p>
    <h1>What is happening?</h1>
    <p>Start from the symptom. Each entry points to the procedures the Service Desk follows, from the first check to the escalation criteria.</p>
  </div>
  <button type="button" class="ops-search-cta" data-cmdk-open aria-label="Open command palette">
    <span>Jump to an article or case&hellip;</span> <kbd>Ctrl K</kbd>
  </button>
</div>

<div class="triage" markdown>

<section class="triage__item triage__item--security" markdown>

### :material-shield-alert-outline: Security: act now

Clicked a suspicious link, entered a password, lost a device.

- [KB-018 Suspicious email or phishing click](kb/kb-018-phishing-suspicious-email.md)
- [KB-019 Lost or stolen laptop or phone](kb/kb-019-lost-stolen-device.md)
- [TCK-007 Worked case: credentials entered](tickets/tck-007-phishing-credentials-entered.md)

</section>

<section class="triage__item" markdown>

### :material-account-lock-outline: Can't sign in

Forgotten password, MFA prompts, locked account.

- [KB-001 Reset a Microsoft 365 password](kb/kb-001-reset-m365-password.md)
- [KB-002 Set up or reset MFA](kb/kb-002-mfa-setup-and-reset.md)
- [KB-003 Active Directory account locked out](kb/kb-003-ad-account-locked-out.md)

</section>

<section class="triage__item" markdown>

### :material-lan-disconnect: No network or VPN

"Connected, no internet", VPN errors, missing drives.

- [KB-010 Wi-Fi / DNS troubleshooting](kb/kb-010-wifi-dns-troubleshooting.md)
- [KB-009 VPN does not connect](kb/kb-009-vpn-not-connecting.md)
- [Triage path for "nothing works"](infrastructure.md#triage-path-for-nothing-works)

</section>

<section class="triage__item" markdown>

### :material-email-alert-outline: Email, Teams, OneDrive

Mail not syncing, no audio or camera, files not uploading.

- [KB-005 Outlook is not syncing](kb/kb-005-outlook-not-syncing.md)
- [KB-006 Teams has no audio or camera](kb/kb-006-teams-audio-camera.md)
- [KB-007 OneDrive is not syncing](kb/kb-007-onedrive-not-syncing.md)

</section>

<section class="triage__item" markdown>

### :material-laptop: Device or printer

Slow computer, printer offline, BitLocker screen, dock issues.

- [KB-013 Computer is running slow](kb/kb-013-slow-computer.md)
- [KB-012 Printer offline or jobs stuck](kb/kb-012-printer-offline.md)
- [KB-014 BitLocker recovery key](kb/kb-014-bitlocker-recovery.md)

</section>

<section class="triage__item triage__item--request" markdown>

### :material-account-plus-outline: Request: access, software, people

New hire, leaver, shared folder, approved software.

- [KB-020 New employee onboarding](kb/kb-020-employee-onboarding.md)
- [KB-004 Access to a shared folder](kb/kb-004-shared-folder-permissions.md)
- [KB-016 Install approved software](kb/kb-016-install-approved-software.md)

</section>

</div>

<div class="ops-columns" markdown>

<div class="ops-panel" markdown>

## Priority and response targets

<div class="compact-table" markdown>

| Priority | First response | Resolution |
|---|---|---|
| <span class="badge badge--p1">P1 Critical</span> | 15 min | 4 h |
| <span class="badge badge--p2">P2 High</span> | 30 min | 8 business h |
| <span class="badge badge--p3">P3 Medium</span> | 4 business h | 3 business days |
| <span class="badge badge--p4">P4 Low</span> | 1 business day | 5 business days |

</div>

[How priority is calculated &rarr;](processes/priority-matrix.md){ .ops-panel__link } &nbsp; [Escalation flow &rarr;](processes/escalation.md){ .ops-panel__link }

</div>

<div class="ops-panel" markdown>

## Contact the Service Desk

| Channel | Use for |
|---|---|
| Portal (this site) | Self-service, 24/7 |
| `servicedesk@acme.example` | P3 / P4 requests, Mon–Fri 08–18 |
| Phone ext. `4357` | P1 / P2 when you cannot work; on-call for P1 |

</div>

</div>

<p class="ops-inventory">Portal contents: {{ stat:kb_total }} KB articles ({{ stat:kb_l1 }} L1, {{ stat:kb_l2 }} L2) &middot; {{ stat:tickets_total }} incident case studies &middot; {{ stat:scripts_total }} PowerShell scripts &middot; {{ stat:process_pages }} process pages. Acme Corp is fictional; nothing on this page is live monitoring.</p>
