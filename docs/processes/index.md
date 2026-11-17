---
title: Processes
---

# Service Desk Processes

How the Acme Corp Service Desk receives, classifies, prioritizes, resolves and escalates work. The processes are a lightweight adaptation of **ITIL 4** practices for a small IT team: *Service Desk*, *Incident Management*, *Service Request Management* and *Knowledge Management*.

<div class="grid cards" markdown>

-   :material-call-split:{ .lg .middle } **Incidents vs. service requests**

    ---

    Is something broken, or is the user asking for something? Classify correctly first.

    [:octicons-arrow-right-24: Read more](incident-vs-request.md)

-   :material-table-large:{ .lg .middle } **Priority matrix & SLAs**

    ---

    Impact × urgency gives the priority, and the priority gives the response and resolution targets.

    [:octicons-arrow-right-24: Read more](priority-matrix.md)

-   :material-sitemap:{ .lg .middle } **Escalation flow**

    ---

    When and how a ticket moves from L1 to L2, L3 or a vendor.

    [:octicons-arrow-right-24: Read more](escalation.md)

-   :material-message-text-outline:{ .lg .middle } **Response templates**

    ---

    Ready-to-use replies in English and Spanish with a friendly, clear tone.

    [:octicons-arrow-right-24: Read more](response-templates.md)

-   :material-account-switch-outline:{ .lg .middle } **Onboarding & offboarding**

    ---

    Checklists for joiners and leavers.

    [:octicons-arrow-right-24: Read more](onboarding-offboarding.md)

</div>

## Ticket lifecycle

```mermaid
stateDiagram-v2
    direction LR
    [*] --> New: User contacts the Service Desk
    New --> Assigned: Classify + prioritize
    Assigned --> InProgress: Technician starts work
    InProgress --> PendingUser: Waiting on user
    PendingUser --> InProgress: User replies
    InProgress --> Escalated: Needs L2/L3/vendor
    Escalated --> InProgress: Returned with fix
    InProgress --> Resolved: Fix applied + user confirms
    Resolved --> Closed: No reply in 3 business days
    Resolved --> InProgress: User reopens
    Closed --> [*]
```

## Golden rules

1. **Every contact is a ticket.** Phone, chat, email or walk-up, it gets logged, so nothing is lost and we can measure our work.
2. **Search the KB before you troubleshoot.** If an article helped, link it in the ticket. If it was missing or wrong, create or fix it (*Knowledge-Centered Service*).
3. **Verify identity before any account change** (password, MFA, access, recovery keys).
4. **Communicate proactively.** Update the user at least at every SLA checkpoint, even if there is no news.
5. **Write tickets for the next person.** Clear symptoms, steps tried, results and next action.
