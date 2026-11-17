---
title: Toolkit
---

# PowerShell Support Toolkit

Seven scripts the Service Desk uses for diagnostics and routine administration. Each one has comment-based help (`Get-Help`), validated parameters, error handling and **automated Pester tests**, and is linted with **PSScriptAnalyzer** in CI on Windows PowerShell 5.1 and PowerShell 7.

| Script | What it does | Level | Changes the system? | Related KB |
|---|---|---|---|---|
| [Get-SystemDiagnostics](Get-SystemDiagnostics.md) | OS, uptime, CPU, RAM, disks and network as an HTML report with health warnings | L1 | No | [KB-013](../kb/kb-013-slow-computer.md) |
| [Test-Connectivity](Test-Connectivity.md) | Layered gateway → internet → DNS → TCP port checks | L1 | No | [KB-010](../kb/kb-010-wifi-dns-troubleshooting.md), [KB-009](../kb/kb-009-vpn-not-connecting.md) |
| [Clear-TempFiles](Clear-TempFiles.md) | Deletes old temp files, skips files in use, reports space freed | L1 | Yes (`-WhatIf`) | [KB-013](../kb/kb-013-slow-computer.md) |
| [Export-InstalledSoftware](Export-InstalledSoftware.md) | Installed software inventory to CSV | L1/L2 | No | [KB-016](../kb/kb-016-install-approved-software.md) |
| [Reset-PrintSpooler](Reset-PrintSpooler.md) | Stops the spooler, clears stuck jobs, restarts it | L1 (admin) | Yes (`-WhatIf`) | [KB-012](../kb/kb-012-printer-offline.md) |
| [New-BulkADUser](New-BulkADUser.md) | Bulk AD account creation from CSV with simulation mode | L2 | Yes (`-WhatIf`) | [KB-020](../kb/kb-020-employee-onboarding.md) |
| [Get-InactiveAccount](Get-InactiveAccount.md) | Accounts with no sign-in for 90+ days, with recommendations | L2 | No | [KB-021](../kb/kb-021-employee-offboarding.md) |

## Getting started

```powershell
git clone https://github.com/lucaswsanchez/helpdesk-kb.git
cd helpdesk-kb\scripts

# Scripts downloaded from the internet may be blocked by the execution policy.
# Allow local scripts for this session only:
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

Get-Help .\Test-Connectivity.ps1 -Full
.\Test-Connectivity.ps1
```

Try the AD scripts without a domain using the sample data:

```powershell
.\New-BulkADUser.ps1 -CsvPath .\samples\new-hires.csv -Simulate
.\Get-InactiveAccount.ps1 -InputCsv .\samples\ad-users.csv -ReferenceDate 2026-11-17
```

## Safety principles

1. **Read-only by default.** Diagnostic scripts never change anything.
2. **Preview first.** Every script that changes state supports `-WhatIf` and `-Confirm` (`SupportsShouldProcess`).
3. **Fail clearly.** Missing modules, missing rights or invalid input produce an actionable error, not a stack trace.
4. **No secrets in output.** Generated passwords are `SecureString` only and never written to the console, logs or files.
5. **Tested without production.** Tests use `TestDrive`, a loopback TCP listener, a temporary registry key and stubbed AD cmdlets, so they run on any Windows machine without admin rights or a domain.

!!! note "Generated pages"
    The individual script pages are generated from each script's comment-based help by `tools/Build-ScriptDoc.ps1`, and CI fails if they are out of date. `Get-Help` and this website always say the same thing.
