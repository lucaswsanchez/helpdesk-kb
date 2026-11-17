---
title: "TCK-007: User Entered Password on a Phishing Page"
---

# TCK-007: User Entered Password on a Phishing Page

!!! practice "Practice scenario"
    This is a simulated ticket written to show troubleshooting reasoning. Names, systems and data are fictional.

| Field | Value |
|---|---|
| **Type** | Security incident |
| **Category** | Security > Phishing |
| **Priority** | **P2** — Impact: Low→Medium (one account, but access to shared finance mailbox) · Urgency: High (active credential compromise) |
| **Channel** | Phone |
| **Related KB** | [KB-018 Report a Suspicious Email (Phishing)](../kb/kb-018-phishing-suspicious-email.md), [KB-001](../kb/kb-001-reset-m365-password.md), [KB-002](../kb/kb-002-mfa-setup-and-reset.md) |

## User report

> "I got an email saying a document was shared with me on OneDrive. I clicked, it asked for my Microsoft password and I typed it. Then the page went blank. Now I'm worried."
> — Accounts payable clerk

## Diagnosis and containment

Speed matters more than root cause here. **Contain first, investigate second.**

1. **Thanked the user for calling immediately** (reporting fast is the most important thing a user can do).
2. **Asked key facts:** Did you approve an MFA prompt? *"Yes, one came right after."* Did you download or open any file? *"No."* Which device? Company laptop.
3. That MFA approval means the attacker may have a **valid session**, not just the password. Treated as an account compromise.
4. **Containment (within 10 minutes):**
    - Reset the password from the admin center (user received the temporary password by phone call).
    - **Revoked all sessions** in Entra ID (**Users > [user] > Revoke sessions**).
    - Reviewed **authentication methods**: an unknown phone number had been added two minutes after the click → removed it.
    - Checked **Outlook inbox rules**: found a new rule moving emails containing "invoice" or "payment" to *RSS Feeds*, a common trick to hide replies → disabled it and kept a screenshot as evidence.
5. **Sign-in logs** showed a successful sign-in from an unfamiliar country right after the click.

## Escalation

Escalated to **Security** immediately as a P2 with: the original email (forwarded as attachment), time of click, the malicious URL, sign-in log entries, the rogue MFA method and inbox rule. Notified the **Finance manager** because the user can request payments.

## Resolution

1. Security blocked the sender domain and URL, searched and purged the same email from 14 other mailboxes (2 other users had clicked but not entered credentials).
2. User re-registered MFA with number matching (KB-002) and signed in successfully.
3. Finance confirmed no payment details had been changed.
4. Ticket kept open 48 hours for monitoring, then closed with Security's approval.

## Communication to the user

> Hi Romina, thank you for calling us so quickly. That made a real difference. Someone did try to use your account, but we blocked them within minutes: your password is changed, every session is signed out and we removed a rule they created. Nothing indicates any payment was affected. In future, if a sign-in page appears after clicking an email link, close it and open the site yourself. And remember you can always use the Report button in Outlook. You did the right thing today.

## Root cause and prevention

- **Root cause:** credential phishing with MFA fatigue/approval.
- **Prevention:** recommended enabling **number matching** and **phishing-resistant MFA** for Finance, plus a short awareness session. A problem record was created to alert on new inbox forwarding/hiding rules.

## Skills demonstrated

Security incident triage, containment order (password → sessions → MFA methods → mailbox rules), evidence collection, blameless and reassuring communication.
