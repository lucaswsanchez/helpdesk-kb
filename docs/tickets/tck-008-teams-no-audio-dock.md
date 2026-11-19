---
title: "TCK-008: No Audio in Teams After Docking"
---

# TCK-008: No Audio in Teams After Docking

!!! practice "Practice scenario"
    Simulated case for training and portfolio purposes. Names, systems and data are fictional.

<div class="ticket-meta" markdown>

Type
:   Incident

Category
:   Microsoft 365 > Teams

Priority
:   <span class="badge badge--p3">P3</span>

Impact / urgency
:   Impact: Low (one user) · Urgency: High (customer call in 10 minutes)

Status
:   <span class="badge badge--resolved">Resolved</span>

Handled by
:   L1 Service Desk

Channel
:   Teams chat

Related KB
:   [KB-006 Microsoft Teams Has No Audio or Camera](../kb/kb-006-teams-audio-camera.md), [KB-015 External Monitor or Docking Station](../kb/kb-015-monitor-docking-station.md)

</div>

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Teams chat: no audio, customer call in 10 minutes.
2. **Triaged** Incident, Microsoft 365, <span class="badge badge--p3">P3</span>; mobile app offered as a fallback.
3. **Diagnosed** Hot-desk dock switched Teams to the monitor speakers and the dock microphone.
4. **Resolved** Headset selected in Teams and Windows; test call OK; user joined on time.

</div>

## User report

> "Nobody can hear me in Teams and I can't hear them. My headset works on my phone. I have a customer call in 10 minutes!"
> — Customer success manager

## Diagnosis

1. **Time-boxed:** with a call in 10 minutes, the priority was a working workaround first. Told the user they could join from the Teams mobile app as a fallback.
2. **Asked what changed:** "I moved to a hot desk today and plugged into the dock." Docking stations add new audio devices (the dock and the monitor's speakers), and Windows often switches the default to them.
3. In **Teams > Settings > Devices**, *Speaker* was set to the monitor (`DELL U2722D` over DisplayPort, which has no speakers connected) and *Microphone* to the dock's audio jack, with nothing plugged in.

## Resolution

1. Selected the USB headset for **Speaker** and **Microphone** in Teams and ran **Make a test call**: the user heard the playback.
2. Set the headset as the **default device** in Windows Sound settings so other apps match.
3. The user joined the customer call on time from the laptop.

## Communication to the user

> Hi Tomás, you're good to go. When you plugged into the dock, Teams switched to the monitor's speakers. I set it back to your headset in Teams and in Windows. If it happens at another desk: Teams > Settings > Devices and pick your headset. Good luck with the call!

## Root cause and prevention

- **Root cause:** automatic default device change after docking.
- **Prevention:** added a quick "hot desk" note to KB-006 step 2 (pick the right device). If it keeps happening at that desk, L2 can disable the monitor audio endpoint in the hot-desk image.

??? abstract "Portfolio note: skills demonstrated"
    Urgency handling with a fallback, "what changed?" questioning, device selection in Teams/Windows, concise friendly communication.
