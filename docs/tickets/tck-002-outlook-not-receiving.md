---
title: "TCK-002: Outlook Not Receiving New Email"
---

# TCK-002: Outlook Not Receiving New Email

!!! practice "Practice scenario"
    Simulated case for training and portfolio purposes. Names, systems and data are fictional.

<div class="ticket-meta" markdown>

Type
:   Incident

Category
:   Microsoft 365 > Outlook

Priority
:   <span class="badge badge--p4">P4</span>

Impact / urgency
:   Impact: Low (one user) · Urgency: Medium (workaround: Outlook on the web)

Status
:   <span class="badge badge--resolved">Resolved</span>

Handled by
:   L1 Service Desk

Channel
:   Self-service portal

Related KB
:   [KB-005 Outlook Is Not Syncing Email](../kb/kb-005-outlook-not-syncing.md)

</div>

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Portal ticket: no new email in Outlook since the previous afternoon.
2. **Triaged** Incident, Microsoft 365, <span class="badge badge--p4">P4</span>: Outlook on the web works as a workaround.
3. **Diagnosed** Server side ruled out via OWA; safe mode, quota and build fine; corrupted OST after a battery shutdown.
4. **Resolved** OST rebuilt, test email received, user confirmed. Old OST deleted the next day.

</div>

## User report

> "My Outlook hasn't shown new email since yesterday afternoon. A client says they sent me a quote and I don't see it."
> — Purchasing analyst

## Diagnosis

1. **Scoped the problem first:** asked the user to open <https://outlook.office.com>. The client's email **was there**. So mail flow and the mailbox are fine; the problem is the **desktop client**. This single check saved escalating to Messaging.
2. **Checked for other affected users:** no similar tickets, Microsoft 365 Service Health was green.
3. **Status bar** showed *"Working offline"*? No: it showed *"Connected"* but the last update was 22 hours ago.
4. **Safe mode** (`outlook.exe /safe`): still no new mail, so add-ins were not the cause.
5. **Mailbox size**: 12 GB of 50 GB, not a quota problem.
6. **Office build** was current.
7. The remaining likely cause was a **corrupted local cache (.ost)**. The OST file was 9 GB and the user mentioned the laptop had shut down during a battery drain yesterday afternoon, which matches when sync stopped.

## Resolution

1. Closed Outlook and renamed `%localappdata%\Microsoft\Outlook\<user>.ost` to `.ost.old` (kept as a backup until confirmed).
2. Restarted Outlook. It created a new cache and started downloading. Recent mail (last 12 months by default) was available in about 20 minutes.
3. Confirmed the client's quote was visible and that a test email I sent arrived within seconds.
4. Deleted the old `.ost` the next day after the user confirmed everything was fine.

## Communication to the user

> Hi Diego, your Outlook is syncing again. The local copy of your mailbox on the laptop got damaged when the battery ran out yesterday, so I rebuilt it. Nothing was lost: your email is stored safely in the cloud. Tip: if Outlook ever looks out of date again, you can always check outlook.office.com while we look into it.

## Root cause and prevention

- **Root cause:** OST corruption after an unexpected shutdown.
- **Prevention:** reminded the user about battery warnings; no further action needed.

??? abstract "Portfolio note: skills demonstrated"
    Isolating client vs. server (OWA comparison), elimination order from least to most disruptive, Outlook cache rebuild, clear non-technical explanation.
