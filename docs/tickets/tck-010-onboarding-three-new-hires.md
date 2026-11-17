---
title: "TCK-010: Onboarding Three New Hires"
---

# TCK-010: Onboarding Three New Hires

!!! practice "Practice scenario"
    This is a simulated ticket written to show troubleshooting reasoning. Names, systems and data are fictional.

| Field | Value |
|---|---|
| **Type** | Service request |
| **Category** | Onboarding & Offboarding > New hire |
| **Priority** | Service request — fulfillment target 5 business days (request arrived 7 business days before start) |
| **Channel** | HR request form |
| **Related KB** | [KB-020 New Employee Onboarding](../kb/kb-020-employee-onboarding.md), [Onboarding checklist](../processes/onboarding-offboarding.md) |

## Request

> "Please set up accounts and laptops for three new Sales hires starting next Monday: two Account Executives and one Sales Ops Analyst. Manager: Mike Brown."
> — HR Business Partner (attached CSV)

## Analysis

1. **Validated the request:** names, titles, department, manager and start date present. One row had the title missing; asked HR and received it the same day.
2. **Checked approvals:** the manager approved the standard *Sales* role template (Sales share RO, CRM app, `Sales-All` distribution list). No extra access requested.
3. **Validated the CSV before touching AD**, using simulation mode:

    ```powershell
    .\New-BulkADUser.ps1 -CsvPath .\sales-hires.csv -Simulate
    ```

    Output showed one name collision: a new hire is also called *John Smith*, and an account `john.smith` already exists, so the script proposed `john.smith2`. Confirmed with HR that this naming was acceptable.

## Fulfillment

1. Previewed and then created the accounts (disabled until the start date), keeping an audit log:

    ```powershell
    .\New-BulkADUser.ps1 -CsvPath .\sales-hires.csv -WhatIf
    .\New-BulkADUser.ps1 -CsvPath .\sales-hires.csv -LogPath .\REQ-onboarding-log.csv
    ```

2. Added the accounts to the role groups, waited for the directory sync and assigned **Microsoft 365 E3** licenses.
3. Assigned three Autopilot laptops in Intune; confirmed BitLocker and compliance.
4. Prepared **Temporary Access Passes** for MFA registration, valid from Monday 08:00, handed to the manager in a sealed envelope (not by email).
5. **Day one:** enabled the accounts at 08:00, sat with each new hire for 15 minutes to sign in, register MFA and open Outlook, Teams and the Sales share. Completed the onboarding checklist.

## Communication

> **To HR and the manager:** All three accounts and laptops are ready for Monday. Accounts will be activated at 08:00. Mike, I've left the first-sign-in passes in a sealed envelope at reception, please hand one to each new hire. I'll be at the Sales area from 08:30 to help them sign in. Note: John Smith's username is john.smith2 because the name is already in use.

## Outcome

- All three new hires were working by 09:30 on day one.
- The `-Simulate` run caught the duplicate name and the missing title **before** anything was created.

## Skills demonstrated

Service request handling with approvals, least-privilege role templates, validating bulk changes with simulation and `-WhatIf`, secure credential handover, checklist discipline.
