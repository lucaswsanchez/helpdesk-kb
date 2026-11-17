---
title: "TCK-006: Laptop Extremely Slow"
---

# TCK-006: Laptop Extremely Slow

!!! practice "Practice scenario"
    This is a simulated ticket written to show troubleshooting reasoning. Names, systems and data are fictional.

| Field | Value |
|---|---|
| **Type** | Incident |
| **Category** | Hardware & Printing > Performance |
| **Priority** | **P4** — Impact: Low (one user) · Urgency: Medium (work is slow but possible) |
| **Channel** | Email |
| **Related KB** | [KB-013 Computer Is Running Slow](../kb/kb-013-slow-computer.md) |

## User report

> "My laptop is unbearably slow. Excel freezes, Teams calls stutter, and it takes forever to open anything. Can I get a new laptop?"
> — Financial analyst

## Diagnosis

1. **Collected a baseline** with the diagnostics script during a remote session:

    ```powershell
    .\Get-SystemDiagnostics.ps1 -OutputPath "$env:USERPROFILE\Desktop"
    ```

    Health check warnings in the HTML report:

    - *Uptime is 23.4 days. Restart the computer to apply updates and free resources.*
    - *Drive C: has only 4% free. Free disk space.*
    - Memory: 15.1 of 16 GB used (94%).

2. **Task Manager** showed 9 Excel workbooks open, 60+ browser tabs and the Windows Update service waiting for a restart.
3. **Asked when it started:** "a couple of weeks ago", which matches the uptime: the user had been closing the lid instead of restarting, and a cumulative update was pending.
4. **Disk:** `WinDirStat`-style check of the user profile showed 38 GB in `Downloads` (old exports) and 9 GB of temp files.
5. Hardware was healthy (`Get-PhysicalDisk` → *Healthy*), laptop 2 years old: **no replacement justified**.

## Resolution

1. Previewed temp cleanup, then ran it:

    ```powershell
    .\Clear-TempFiles.ps1 -WhatIf          # ~9.2 GB would be freed
    .\Clear-TempFiles.ps1 -Confirm:$false  # Deleted 18,412 files, freed 8.9 GB
    ```

2. With the user's agreement, moved old exports from `Downloads` to OneDrive (set to *Free up space*).
3. Disabled 4 non-business startup apps.
4. **Restarted** to complete the pending update.
5. Re-ran the diagnostics report: C: 31% free, memory 48% used after sign-in, no warnings. Attached before/after reports to the ticket.

## Communication to the user

> Hi Martín, your laptop should feel much faster now. It hadn't been restarted in 23 days and the disk was almost full, which slows everything down. I freed about 45 GB (temporary files plus old downloads moved to OneDrive), installed a pending update and restarted it. Your hardware is in good shape, so no replacement is needed. One tip: restart at least once a week (Start > Power > Restart), not just close the lid. Let me know how it goes this week.

## Root cause and prevention

- **Root cause:** high uptime with a pending update, nearly full disk, heavy memory use.
- **Prevention:** suggested enabling **Storage Sense** and an Intune restart reminder policy for devices with uptime over 7 days.

## Skills demonstrated

Evidence-based diagnosis with before/after metrics, avoiding an unnecessary hardware purchase, safe cleanup with `-WhatIf`, user habit coaching.
