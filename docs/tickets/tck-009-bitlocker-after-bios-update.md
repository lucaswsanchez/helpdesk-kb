---
title: "TCK-009: BitLocker Recovery Screen After a BIOS Update"
---

# TCK-009: BitLocker Recovery Screen After a BIOS Update

!!! practice "Practice scenario"
    Simulated case for training and portfolio purposes. Names, systems and data are fictional.

<div class="ticket-meta" markdown>

Type
:   Incident

Category
:   Hardware & Printing > BitLocker

Priority
:   <span class="badge badge--p3">P3</span>

Impact / urgency
:   Impact: Low (one user) · Urgency: High (cannot use the laptop)

Status
:   <span class="badge badge--resolved">Resolved</span>

Handled by
:   L1 Service Desk (L2 Endpoint Management informed)

Channel
:   Phone (user's personal mobile)

Related KB
:   [KB-014 BitLocker Recovery Key Requested at Startup](../kb/kb-014-bitlocker-recovery.md)

</div>

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Phone call: BitLocker recovery screen after an overnight update.
2. **Triaged** Incident, Hardware & Printing, <span class="badge badge--p3">P3</span>. Identity verified by call-back.
3. **Diagnosed** Firmware update deployed without suspending BitLocker; Key ID matched in Intune.
4. **Resolved** Key read by phone, device booted twice cleanly, recovery key rotated.
5. **Follow-up** Trend of three similar tickets reported; problem record to suspend BitLocker during firmware updates.

</div>

## User report

> "My laptop installed an update last night and now there's a blue screen asking for a BitLocker recovery key. I've never seen this before."
> — Project manager, working from home

## Diagnosis

1. **Verified identity** before anything else: the recovery key unlocks all the data on the device. Called back the mobile number registered in the HR directory and confirmed the employee ID.
2. **Why did it happen?** Intune showed a **BIOS/firmware update** deployed to that model the night before. Firmware updates change the measurements BitLocker checks in the TPM, so a one-time recovery prompt is expected if BitLocker was not suspended during the update.
3. Asked the user to read the **first 8 characters of the Recovery key ID** from the screen: `4A7C19E2`.

## Resolution

1. In the Intune admin center: **Devices > [device] > Recovery keys**, matched Key ID `4A7C19E2…`.
2. **Read the 48-digit key to the user by phone**, in groups of six digits. (Not by email, chat or in the ticket.)
3. The laptop booted into Windows. Asked the user to **restart once more**: no recovery prompt, so TPM protection was re-sealed.
4. Because the key was disclosed, triggered **BitLocker key rotation** from Intune and confirmed a new key was escrowed.
5. Ticket notes record the device, the Key ID and the verification method, **not the key**.

## Escalation

Informed **L2 Endpoint Management** that the firmware update was triggering recovery prompts (three similar tickets that morning) so they could check that the deployment suspends BitLocker for one reboot. They opened a problem record.

## Communication to the user

> Hi Valeria, your laptop is working again. The screen appeared because last night's firmware update changed something BitLocker checks for security. That's expected and your data is safe. I've already replaced the recovery key with a new one, so the one I read to you is no longer valid. No action needed on your side.

## Root cause and prevention

- **Root cause:** firmware update without BitLocker suspension.
- **Prevention:** problem record to update the firmware deployment to suspend BitLocker for one restart (`Suspend-BitLocker -RebootCount 1`).

??? abstract "Portfolio note: skills demonstrated"
    Security-first identity verification, secure handling of recovery keys, key rotation, spotting a trend across tickets and feeding problem management.
