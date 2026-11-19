---
title: "TCK-005: Print Jobs Stuck in the Queue"
---

# TCK-005: Print Jobs Stuck in the Queue

!!! practice "Practice scenario"
    Simulated case for training and portfolio purposes. Names, systems and data are fictional.

<div class="ticket-meta" markdown>

Type
:   Incident

Category
:   Hardware & Printing > Print queue

Priority
:   <span class="badge badge--p4">P4</span>

Impact / urgency
:   Impact: Low (one user) · Urgency: Low (another printer nearby works)

Status
:   <span class="badge badge--resolved">Resolved</span>

Handled by
:   L1 Service Desk

Channel
:   Walk-up

Related KB
:   [KB-012 Printer Shows Offline or Jobs Are Stuck](../kb/kb-012-printer-offline.md)

</div>

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Walk-up: large PDF stuck, nothing prints, jobs cannot be cancelled.
2. **Triaged** Incident, Hardware & Printing, <span class="badge badge--p4">P4</span>: another printer works.
3. **Diagnosed** A colleague prints fine to the same printer: local spooler blocked by a corrupted job.
4. **Resolved** Reset-PrintSpooler.ps1 previewed with -WhatIf, then run; document reprinted.

</div>

## User report

> "I sent a 40-page PDF to the 2nd-floor printer and nothing came out. Now nothing else prints either, and I can't cancel the jobs."
> — HR assistant

## Diagnosis

1. **Is it the printer or the PC?** A colleague printed to the same printer successfully, so the printer and network were fine. The problem was on this user's PC.
2. **Print queue** showed the 40-page job with status *Error – Deleting* and three jobs behind it. *Cancel all documents* did nothing: the job was stuck in the spooler.
3. Classic symptom of a corrupted spool file blocking the local Print Spooler.

## Resolution

1. Previewed the fix without changing anything:

    ```powershell
    .\Reset-PrintSpooler.ps1 -WhatIf
    # WhatIf: would stop 'Spooler', delete 8 spool file(s) and start the service again.
    ```

2. Ran it in an elevated session:

    ```powershell
    .\Reset-PrintSpooler.ps1 -Confirm:$false
    # Print Spooler reset: 8 pending job file(s) deleted, service is running.
    ```

3. Asked the user to print the PDF again. It printed correctly, and so did a test page.

## Communication to the user

> Hi Paula, the print queue on your laptop got stuck on the large PDF, so I cleared it and restarted the printing service. Your documents are printing again. The jobs that were waiting were removed, so please send any of them again if you still need them.

## Root cause and prevention

- **Root cause:** corrupted spool job from a large PDF.
- **Prevention:** none required for a single occurrence; if it repeats with the same PDF, update the printer driver.

??? abstract "Portfolio note: skills demonstrated"
    Isolating device vs. client with a quick comparison, safe use of a script with `-WhatIf` first, clear note about what the user must redo.
