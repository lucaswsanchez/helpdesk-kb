---
title: Onboarding & Offboarding Checklists
---

# Onboarding & Offboarding Checklists

Process checklists for joiners and leavers. The technical, step-by-step procedures are in [KB-020 New Employee Onboarding](../kb/kb-020-employee-onboarding.md) and [KB-021 Employee Offboarding](../kb/kb-021-employee-offboarding.md).

## Onboarding (joiner)

**Trigger:** HR "New hire" service request, at least **5 business days** before the start date.

### Before day one

- [ ] Request contains name, title, department, manager, start date, location, required access
- [ ] Manager approved the role template (groups, shares, apps)
- [ ] AD account created (`firstname.lastname`), placed in the department OU
- [ ] Attributes set: department, title, manager, office, phone
- [ ] Added to role-based security and distribution groups (least privilege)
- [ ] Microsoft 365 license assigned after directory sync
- [ ] Mailbox, OneDrive and Teams membership confirmed
- [ ] Laptop assigned in Intune / Autopilot, encrypted (BitLocker) and compliant
- [ ] Peripherals ready: dock, monitor, headset, badge (with Facilities)
- [ ] Temporary password and Temporary Access Pass prepared for secure handover

### Day one

- [ ] Identity verified in person or by the manager
- [ ] User signs in and changes the temporary password
- [ ] MFA registered in Microsoft Authenticator (KB-002)
- [ ] Outlook, Teams and OneDrive working; department share accessible
- [ ] Short security briefing: phishing reporting (KB-018), lost device (KB-019), where to get help (this portal)
- [ ] Ticket closed with groups, license and device serial number recorded

## Offboarding (leaver)

**Trigger:** HR "Leaver" service request with the last working day and time. **Immediate termination**: start within 1 hour.

### On the last day (at the agreed time)

- [ ] Request confirmed with HR; data recipients identified (mailbox, files)
- [ ] AD account disabled, description updated with date and ticket number
- [ ] Password reset to a random value; all sessions revoked in Entra ID
- [ ] Group memberships recorded in the ticket, then removed
- [ ] Admin roles and privileged access removed
- [ ] Mailbox converted to shared mailbox; manager granted access or auto-reply set
- [ ] OneDrive access granted to the manager (30-day retention)
- [ ] Microsoft 365 licenses removed after conversion
- [ ] Account moved to the *Disabled Users* OU

### Devices and other systems

- [ ] Laptop, phone, badge and peripherals collected
- [ ] Devices wiped and re-provisioned via Intune / Autopilot
- [ ] Company data retired from personal phones (selective wipe)
- [ ] SaaS accounts outside SSO disabled; shared passwords the person knew rotated
- [ ] Ticket closed with checklist and timestamps

### Monthly control

- [ ] Run `Get-InactiveAccount.ps1` to list accounts with no sign-in for 90+ days and confirm each with HR
