---
title: Ticket Cases
hide:
  - toc
---

# Ticket Case Studies

!!! practice "Practice scenarios"
    These ten tickets are **simulated scenarios** written to show how I approach Service Desk work: classifying and prioritizing, troubleshooting step by step, escalating with a good hand-off note, and communicating clearly with the user. Names, systems and data are fictional.

Each case follows the same structure: **classification → resolution timeline → user report → diagnosis → resolution → communication → root cause and prevention**, and links to the KB article it relies on.

| Case | Type | Category | Priority | Status | Key skill |
|---|---|---|---|---|---|
| [TCK-001 Account keeps locking after a password change](tck-001-lockout-after-password-change.md) | Incident | Accounts & Identity | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Finding the device with stale credentials (Event 4740) |
| [TCK-002 Outlook not receiving new email](tck-002-outlook-not-receiving.md) | Incident | Microsoft 365 | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | Client vs. server isolation with Outlook on the web |
| [TCK-003 VPN fails from a hotel](tck-003-vpn-hotel-captive-portal.md) | Incident | Network | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Bottom-up troubleshooting: internet before VPN |
| [TCK-004 Several users on one floor have no network](tck-004-floor-no-internet-dhcp.md) | Incident (major) | Network | <span class="badge badge--p2">P2</span> | <span class="badge badge--escalated">Resolved</span> | Pattern recognition, parent ticket, escalation note |
| [TCK-005 Print jobs stuck in the queue](tck-005-print-queue-stuck.md) | Incident | Hardware & Printing | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | Safe scripted fix with `-WhatIf` |
| [TCK-006 Laptop extremely slow](tck-006-slow-laptop.md) | Incident | Hardware & Printing | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | Evidence-based diagnosis, before/after metrics |
| [TCK-007 User entered password on a phishing page](tck-007-phishing-credentials-entered.md) | Security incident | Security | <span class="badge badge--p2">P2</span> | <span class="badge badge--security">Resolved</span> | Containment order and evidence collection |
| [TCK-008 No audio in Teams after docking](tck-008-teams-no-audio-dock.md) | Incident | Microsoft 365 | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Urgency handling with a fallback |
| [TCK-009 BitLocker recovery after a BIOS update](tck-009-bitlocker-after-bios-update.md) | Incident | Hardware & Printing | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Secure key handling, feeding problem management |
| [TCK-010 Onboarding three new hires](tck-010-onboarding-three-new-hires.md) | Service request | Onboarding | <span class="badge badge--plain">—</span> | <span class="badge badge--request">Fulfilled</span> | Validating bulk changes with simulation mode |

Priorities follow the [priority matrix](../processes/priority-matrix.md).
