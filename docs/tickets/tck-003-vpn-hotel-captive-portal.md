---
title: "TCK-003: VPN Fails From a Hotel"
---

# TCK-003: VPN Fails From a Hotel

!!! practice "Practice scenario"
    This is a simulated ticket written to show troubleshooting reasoning. Names, systems and data are fictional.

| Field | Value |
|---|---|
| **Type** | Incident |
| **Category** | Network > VPN |
| **Priority** | <span class="badge badge--p3">P3</span> — Impact: Low (one user) · Urgency: High (client presentation in 2 hours needs files from the share) |
| **Status** | <span class="badge badge--resolved">Resolved</span> |
| **Channel** | Phone (user travelling) |
| **Related KB** | [KB-009 VPN Does Not Connect](../kb/kb-009-vpn-not-connecting.md), [KB-010 Wi-Fi Connected but No Internet](../kb/kb-010-wifi-dns-troubleshooting.md) |

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Phone call from a hotel: VPN cannot reach the gateway, client meeting in 2 hours.
2. **Triaged** Incident, Network, <span class="badge badge--p3">P3</span> because of the deadline.
3. **Diagnosed** Internet checked before VPN: the hotel captive portal was not completed.
4. **Resolved** Portal login completed, VPN connected, file copied and also saved to OneDrive.

</div>

## User report

> "I'm at a hotel for a client meeting. The VPN says 'Unable to connect to the gateway'. Wi-Fi says connected. I need the presentation that's on the S: drive."
> — Account manager

## Diagnosis

Followed the bottom-up approach: **internet first, then VPN**.

1. **Internet check:** asked the user to open any website. The browser redirected to `hotel-wifi-login...` asking for a room number. The laptop was connected to Wi-Fi but **not yet authorized on the hotel's captive portal**, so all traffic except the portal was blocked.
2. That explains the VPN error: the client could not reach the gateway at all.

## Resolution

1. User entered the room number and surname on the hotel portal and accepted the terms.
2. Websites loaded normally; VPN connected on the first try and the MFA prompt was approved.
3. **Verified access:** user opened `S:\Sales\Clients\` and copied the presentation locally.
4. Suggested a backup for the meeting: the file was also uploaded to the user's OneDrive so it would be available even without VPN.

## Communication to the user

> Hi Lucía, glad you're connected! Hotel Wi-Fi usually needs you to log in on a web page before anything else works, including the VPN. Next time, open a website first and complete the hotel login, then start the VPN. I also saved the presentation to your OneDrive so you can open it from any device. Good luck with the meeting!

## Root cause and prevention

- **Root cause:** captive portal not completed.
- **Prevention:** added a "Travelling? Read this first" tip to the VPN KB article (step 1 already covers captive portals). Proposed adding the most-used sales folders to OneDrive/SharePoint to reduce VPN dependency.

## Skills demonstrated

Layered troubleshooting (don't troubleshoot the VPN before the internet), urgency-aware workaround, empathetic communication under time pressure.
