---
title: Incident Case Studies
hide:
  - toc
---

# Incident Case Studies

!!! practice "Practice scenarios"
    These ten cases are **simulated incidents and requests**, worked end to end. Names, systems and data are fictional.

Each case has the same layout: ticket fields, resolution timeline, user report, diagnosis, resolution, message to the user, and root cause with prevention.

| Case | Type | Category | Priority | Status | Root cause |
|---|---|---|---|---|---|
| [TCK-001 Account keeps locking after a password change](tck-001-lockout-after-password-change.md) | Incident | Accounts & Identity | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Stale password in a phone mail app |
| [TCK-002 Outlook not receiving new email](tck-002-outlook-not-receiving.md) | Incident | Microsoft 365 | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | Local Outlook cache corrupted by a shutdown |
| [TCK-003 VPN fails from a hotel](tck-003-vpn-hotel-captive-portal.md) | Incident | Network | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Hotel captive portal not completed |
| [TCK-004 Several users on one floor have no network](tck-004-floor-no-internet-dhcp.md) | Incident (major) | Network | <span class="badge badge--p2">P2</span> | <span class="badge badge--escalated">Escalated</span> | DHCP scope exhausted on one VLAN |
| [TCK-005 Print jobs stuck in the queue](tck-005-print-queue-stuck.md) | Incident | Hardware & Printing | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | Corrupted job blocking the local spooler |
| [TCK-006 Laptop extremely slow](tck-006-slow-laptop.md) | Incident | Hardware & Printing | <span class="badge badge--p4">P4</span> | <span class="badge badge--resolved">Resolved</span> | 23 days of uptime and a nearly full disk |
| [TCK-007 User entered password on a phishing page](tck-007-phishing-credentials-entered.md) | Security incident | Security | <span class="badge badge--p2">P2</span> | <span class="badge badge--security">Security</span> | Credential phishing plus an approved MFA prompt |
| [TCK-008 No audio in Teams after docking](tck-008-teams-no-audio-dock.md) | Incident | Microsoft 365 | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Dock changed the default audio device |
| [TCK-009 BitLocker recovery after a BIOS update](tck-009-bitlocker-after-bios-update.md) | Incident | Hardware & Printing | <span class="badge badge--p3">P3</span> | <span class="badge badge--resolved">Resolved</span> | Firmware update without suspending BitLocker |
| [TCK-010 Onboarding three new hires](tck-010-onboarding-three-new-hires.md) | Service request | Onboarding | <span class="badge badge--plain">—</span> | <span class="badge badge--request">Fulfilled</span> | &mdash; (service request; name collision caught in simulation) |

Priorities follow the [priority matrix](../processes/priority-matrix.md). Status shows how each case was handled: <span class="badge badge--resolved">Resolved</span> at L1, <span class="badge badge--escalated">Escalated</span> to L2 and then resolved, <span class="badge badge--security">Security</span> incident, <span class="badge badge--request">Fulfilled</span> service request.
