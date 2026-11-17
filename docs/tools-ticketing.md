---
title: Tools & Ticketing
---

# Tools & Ticketing: Running This KB in Zendesk or Freshdesk

This page explains how the knowledge base and processes on this site would be configured in a real help desk tool. It is a **design document**: Acme Corp is fictional and no screenshots are shown, because I did not build this configuration in a live account. The settings named below are standard features of both products.

## Mapping overview

| This site | Zendesk | Freshdesk |
|---|---|---|
| KB categories (Accounts & Identity, Microsoft 365…) | **Guide** categories / sections | **Solutions** categories / folders |
| KB articles with L1/L2 level | Articles with **labels** (`l1`, `l2`) and **user segments** (L2 = agents only) | Solution articles with **tags**, folder **visibility** (agents only for L2) |
| Ticket type: incident / service request | **Ticket form** or the built-in *Type* field (Incident, Question, Task, Problem) | **Type** field (Incident, Service Request, Question, Problem) |
| Category (e.g. Network > VPN) | Custom **dropdown field** with nested values (`network::vpn`) | **Dependent field** (Category → Subcategory) |
| Priority P1–P4 | **Priority** field (Urgent, High, Normal, Low) | **Priority** field (Urgent, High, Medium, Low) |
| Impact / Urgency | Two custom dropdowns + a **trigger** that sets Priority | Two custom dropdowns + an **automation rule** that sets Priority |
| SLA targets | **SLA policies** | **SLA policies** |
| Escalation tiers L1/L2/L3 | **Groups** (Service Desk, Desktop, Identity, Network, Security) | **Groups** with the same names |
| Response templates | **Macros** | **Canned responses** (+ Scenario automations for multi-step actions) |
| Parent incident (TCK-004) | **Side conversations** or linking tickets to a *Problem* ticket | **Parent-child tickets** / link to a *Problem* |

## Knowledge base structure

```text
Help Center / Solutions
├── Accounts & Identity        (KB-001 … KB-004)
├── Microsoft 365              (KB-005 … KB-008)
├── Network                    (KB-009 … KB-011)
├── Hardware & Printing        (KB-012 … KB-015)
├── Software                   (KB-016, KB-017)
├── Security                   (KB-018, KB-019)
└── Onboarding & Offboarding   (KB-020, KB-021)   ← visible to agents only
```

- **L1 articles** are public in the customer-facing help center so users can self-serve.
- **L2 articles** (admin steps) are visible to agents only.
- The article template (Summary → Last reviewed) becomes an **article template** in the editor so every article keeps the same structure.
- **Article verification**: assign an owner and a review interval (for example 6 months) so the *Last reviewed* date stays honest.

## Ticket fields and forms

| Field | Values | Required at |
|---|---|---|
| Type | Incident, Service request, Question, Security incident | Solve |
| Category | Accounts & Identity, Microsoft 365, Network, Hardware & Printing, Software, Security, Onboarding & Offboarding | Solve |
| Impact | High, Medium, Low | Create (agent) |
| Urgency | High, Medium, Low | Create (agent) |
| Related KB | Text (KB-ID) | Solve |

A **trigger / automation** sets Priority from Impact × Urgency using the [priority matrix](processes/priority-matrix.md), so agents never choose priority by feel.

## SLA policies

| Priority | First reply | Next reply | Resolution | Schedule |
|---|---|---|---|---|
| Urgent (P1) | 15 min | 30 min | 4 h | 24/7 |
| High (P2) | 30 min | 2 h | 8 business h | Business hours |
| Normal / Medium (P3) | 4 business h | 1 business day | 3 business days | Business hours |
| Low (P4) | 1 business day | 2 business days | 5 business days | Business hours |

- Business hours: Mon–Fri 08:00–18:00 (America/Argentina/Buenos_Aires).
- Status *Pending* (waiting on the user) **pauses** the resolution SLA.
- An automation notifies the team lead when a P1/P2 ticket reaches 75% of its resolution target.

## Macros / canned responses

Each [response template](processes/response-templates.md) becomes a macro in English and Spanish. Macros also **set fields** so the reply and the ticket state stay consistent:

| Macro | Actions |
|---|---|
| *Acknowledge – standard* | Add public reply; set Status = Open; assign to Service Desk |
| *Request more information* | Add public reply; set Status = Pending |
| *Escalate to L2 Network* | Add internal note with the hand-off template; set Group = Network; add tag `escalated_l2` |
| *Resolved – confirm with user* | Add public reply with KB link; set Status = Solved/Resolved |
| *Phishing – containment started* | Set Type = Security incident; Priority = High; Group = Security; add internal checklist note |

## Views (queues)

| View | Conditions |
|---|---|
| **My open tickets** | Assignee = current user; Status < Solved |
| **Unassigned – Service Desk** | Group = Service Desk; Assignee empty |
| **SLA breaching in < 1 h** | SLA next breach within 1 hour |
| **P1/P2 open** | Priority ∈ {Urgent, High}; Status < Solved |
| **Pending > 3 days** | Status = Pending; updated > 3 days ago (follow-up or auto-close) |
| **Security incidents** | Type = Security incident |

## Automations worth adding

- **Auto-close** solved tickets after 3 business days without a reply, matching the resolution template.
- **CSAT survey** on close (one question + comment).
- **Answer suggestions**: Zendesk *Answer Bot / AI agents* or Freshdesk *Freddy* can suggest KB articles from the ticket text. Clean, consistently structured articles (as in this KB) make those suggestions much better.
- **Reporting**: first contact resolution rate, SLA compliance by priority, top categories (to decide which KB articles to write next) and backlog age.

## Why this matters

Tools change; the fundamentals don't. Clear categories, a priority matrix applied the same way by everyone, templates with a good tone and a KB that is kept up to date carry over to Zendesk, Freshdesk, Jira Service Management or ServiceNow.
