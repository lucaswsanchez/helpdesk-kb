---
title: "TCK-001: Account Keeps Locking After a Password Change"
---

# TCK-001: Account Keeps Locking After a Password Change

!!! practice "Practice scenario"
    This is a simulated ticket written to show troubleshooting reasoning. Names, systems and data are fictional.

| Field | Value |
|---|---|
| **Type** | Incident |
| **Category** | Accounts & Identity > Account lockout |
| **Priority** | **P3** — Impact: Low (one user) · Urgency: High (cannot sign in) |
| **Channel** | Phone |
| **Related KB** | [KB-003 Active Directory Account Locked Out](../kb/kb-003-ad-account-locked-out.md) |

## User report

> "I changed my password this morning because Windows asked me to. Since then I've been locked out three times. IT unlocked me an hour ago and it's happening again. I can't open anything."
> — Sales coordinator, office-based

## Diagnosis

1. **Verified identity** by calling back the number in the HR directory.
2. **Confirmed the lockout and its pattern** with PowerShell:

    ```powershell
    Get-ADUser -Identity c.ramirez -Properties LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet |
        Select-Object LockedOut, BadLogonCount, LastBadPasswordAttempt, PasswordLastSet
    ```

    `LockedOut: True`, `PasswordLastSet` 08:52, bad attempts continuing every few minutes even while the user was on the phone with me and **not typing anything**.
3. **Hypothesis:** a device or app is still using the **old password**. Repeated failures while the user is idle rule out mistyping.
4. **Asked targeted questions:** "Do you have work email on your phone?" Yes, the native iOS Mail app with the work account.
5. **Confirmed the source:** L2 checked the domain controller Security log for **Event ID 4740**. The *Caller Computer Name* was the Exchange/ADFS proxy, which matches a mobile mail client retrying with old credentials.

## Resolution

1. Unlocked the account (`Unlock-ADAccount -Identity c.ramirez`).
2. Guided the user to **remove the work account from iOS Mail** and use the **Outlook app** (the company-approved client), signing in with the new password and MFA.
3. Checked **Credential Manager** on the laptop and removed an old saved credential for `fileserver01`.
4. Monitored for 15 minutes: `BadLogonCount` stayed at 0, no new lockouts.

## Communication to the user

> Hi Carla, you're all set. The lockouts were caused by the Mail app on your phone, which kept trying your old password in the background. Moving your work email to the Outlook app fixed it. If you change your password again in the future, update it on your phone right away, or just use Outlook, which asks you automatically. I'll keep the ticket open until tomorrow in case it happens again.

## Root cause and prevention

- **Root cause:** stale credentials on a mobile mail client after a password change.
- **Prevention:** proposed a KB note in the password change notification email: *"Update your password on your phone and other devices."* Logged as a suggestion to move users to Outlook mobile with app protection policies.

## Skills demonstrated

Identity verification, Active Directory PowerShell, pattern-based hypothesis (failures while idle), Event ID 4740, user education.
