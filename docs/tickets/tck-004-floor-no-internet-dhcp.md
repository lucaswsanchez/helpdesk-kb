---
title: "TCK-004: Several Users on One Floor Have No Network"
---

# TCK-004: Several Users on One Floor Have No Network

!!! practice "Practice scenario"
    Simulated case for training and portfolio purposes. Names, systems and data are fictional.

<div class="ticket-meta" markdown>

Type
:   Incident (parent ticket, 6 child tickets linked)

Category
:   Network > Wi-Fi / DHCP

Priority
:   <span class="badge badge--p2">P2</span>

Impact / urgency
:   Impact: Medium (a floor, ~40 users) · Urgency: High (no workaround for laptops arriving now)

Status
:   <span class="badge badge--escalated">Escalated &rarr; Resolved</span>

Handled by
:   L1 Service Desk &rarr; L2 Network

Channel
:   Phone + chat (multiple users within 15 minutes)

Related KB
:   [KB-010 Wi-Fi Connected but No Internet](../kb/kb-010-wifi-dns-troubleshooting.md)

</div>

## Resolution timeline

<div class="timeline" markdown>

1. **Reported** Six contacts from the 3rd floor in 15 minutes: "No internet".
2. **Triaged** Parent incident created, children linked, raised from P4 to <span class="badge badge--p2">P2</span>, team lead notified.
3. **Diagnosed** APIPA addresses on late arrivals vs. valid leases on early ones: DHCP scope exhaustion suspected.
4. **Escalated** Hand-off to L2 Network with ipconfig output and Test-Connectivity reports.
5. **Resolved** L2 shortened leases and moved guest devices; users renewed and confirmed; floor notice sent.
6. **Follow-up** Problem record: scope-utilization alert at 85%.

</div>

## User reports

> "Wi-Fi shows 'No internet'." · "Teams disconnected." · "My laptop just got here and won't connect." (6 contacts from the 3rd floor between 09:00 and 09:15)

## Diagnosis

1. **Recognized a pattern:** six tickets from the same floor in 15 minutes is not six problems, it is one. Created a **parent incident**, linked the child tickets and raised priority from P4 to **P2**. Notified the team lead.
2. **Remote session with one affected user**, `ipconfig /all`:
    - IPv4 address: `169.254.71.12` (APIPA): the laptop **did not get an address from DHCP**.
3. **Compared with a working user on the same floor** (arrived at 08:30): valid address `10.30.3.214`, everything worked.
4. **Hypothesis:** people who connected early got addresses; people arriving later did not. That pattern points to **DHCP scope exhaustion** on the 3rd-floor VLAN, not a Wi-Fi outage.
5. Ran `Test-Connectivity.ps1` on both laptops and attached both reports to the parent ticket as evidence.

## Escalation

Escalated to **L2 Network** within 20 minutes with this hand-off:

```text
Summary:   3rd floor Wi-Fi: users arriving after ~08:45 get APIPA (169.254.x.x).
           Users connected earlier have valid 10.30.3.x leases and work fine.
Impact:    ~40 users, 6 tickets linked to this parent. P2.
Evidence:  ipconfig /all from affected and working laptop; Test-Connectivity reports.
Suspect:   DHCP scope for VLAN 30 exhausted.
Ask:       Check scope utilization and lease duration on the DHCP server.
```

## Resolution (by L2 Network, verified by L1)

1. L2 confirmed the scope was **100% used**: lease duration was 8 days and a recent event had connected many guest phones to the corporate SSID.
2. L2 reduced the lease duration to 8 hours, removed stale leases and moved guest devices to the guest SSID.
3. L1 asked affected users to toggle Wi-Fi off/on (`ipconfig /renew`). All six confirmed they were working.
4. Sent a resolution notice to the floor and closed the child tickets with a link to the parent.

## Communication to users

> **Update – 3rd floor Wi-Fi restored.** Some laptops on the 3rd floor could not connect this morning because the network ran out of available addresses. Our network team has fixed it. If you still see "No internet", turn Wi-Fi off and on again. Sorry for the disruption, and thank you to everyone who reported it quickly.

## Root cause and prevention

- **Root cause:** DHCP scope exhaustion (long lease time + personal devices on the corporate SSID).
- **Prevention:** a problem record was opened for L2 to add scope-utilization monitoring (alert at 85%) and enforce the guest SSID for personal devices.

??? abstract "Portfolio note: skills demonstrated"
    Spotting a major incident from multiple tickets, parent/child ticket linking, re-prioritization, APIPA interpretation, comparison against a working device, high-quality escalation note.
