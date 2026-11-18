---
title: Infrastructure Map
---

# Infrastructure Map

How the services documented in this knowledge base depend on each other. Use it during triage to answer the most important question for prioritizing an incident: **if this component fails, what else breaks, and for whom?**

!!! note "Documentation, not monitoring"
    This is the reference architecture of the fictional Acme Corp environment as described in the KB articles. It is not connected to any live system and shows no real-time status.

## Service dependency map

```mermaid
flowchart TB
    subgraph Endpoints["Endpoints"]
        LAP["Windows 11 laptops<br/>Intune + BitLocker"]
        PHN["Phones<br/>Outlook / Teams apps"]
    end

    subgraph Cloud["Microsoft 365 (cloud)"]
        ENTRA["Entra ID<br/>sign-in, MFA, SSPR"]
        EXO["Exchange Online<br/>mailboxes, shared mailboxes"]
        TEAMS["Teams"]
        ODSP["OneDrive / SharePoint"]
        INTUNE["Intune<br/>Company Portal, recovery keys"]
    end

    subgraph OnPrem["On-premises (HQ)"]
        AD["Active Directory DS<br/>users, groups, GPO"]
        SYNC["Entra Connect<br/>directory + password sync"]
        DNSDHCP["DNS / DHCP<br/>per-floor VLAN scopes"]
        WIFI["Wi-Fi ACME-CORP<br/>802.1X"]
        FS["File server<br/>department shares"]
        PRN["Print server<br/>floor printers"]
        VPN["VPN gateway"]
    end

    AD --> SYNC --> ENTRA
    ENTRA --> EXO & TEAMS & ODSP & INTUNE
    LAP --> WIFI --> DNSDHCP
    WIFI -. "authenticates" .-> AD
    LAP --> VPN -. "authenticates" .-> AD
    LAP --> FS & PRN
    FS -. "permissions (FS-* groups)" .-> AD
    LAP --> ENTRA
    PHN --> ENTRA
    INTUNE --> LAP
```

## Impact reference

| Component | If it fails, users see | Typical impact | Procedures |
|---|---|---|---|
| **Entra ID / MFA** | Cannot sign in to any Microsoft 365 app, MFA loops | Whole company: <span class="badge badge--p1">P1</span> | [KB-001](kb/kb-001-reset-m365-password.md), [KB-002](kb/kb-002-mfa-setup-and-reset.md) |
| **Active Directory** | Windows sign-in, Wi-Fi, VPN and file shares fail; lockouts | Site-wide: <span class="badge badge--p1">P1</span> | [KB-003](kb/kb-003-ad-account-locked-out.md), [KB-004](kb/kb-004-shared-folder-permissions.md) |
| **Entra Connect sync** | New hires or password changes don't reach Microsoft 365 | Delayed changes: <span class="badge badge--p3">P3</span> | [KB-020](kb/kb-020-employee-onboarding.md) |
| **Exchange Online** | No mail flow, Outlook and OWA both affected | Whole company: <span class="badge badge--p1">P1</span> | [KB-005](kb/kb-005-outlook-not-syncing.md), [KB-008](kb/kb-008-shared-mailbox-access.md) |
| **DHCP scope (one VLAN)** | "No internet", 169.254.x.x addresses on one floor | One floor: <span class="badge badge--p2">P2</span> | [KB-010](kb/kb-010-wifi-dns-troubleshooting.md), [TCK-004](tickets/tck-004-floor-no-internet-dhcp.md) |
| **DNS** | Websites and internal names fail, IPs still work | Site-wide: <span class="badge badge--p1">P1</span> | [KB-010](kb/kb-010-wifi-dns-troubleshooting.md) |
| **VPN gateway** | Remote staff cannot reach shares or internal apps | All remote users: <span class="badge badge--p2">P2</span> | [KB-009](kb/kb-009-vpn-not-connecting.md), [TCK-003](tickets/tck-003-vpn-hotel-captive-portal.md) |
| **File server** | Mapped drives disconnected, "network path not found" | Department or site: <span class="badge badge--p2">P2</span> | [KB-011](kb/kb-011-mapped-network-drive.md) |
| **Print server / printer** | Printer offline, jobs stuck | One floor: <span class="badge badge--p4">P4</span> | [KB-012](kb/kb-012-printer-offline.md), [TCK-005](tickets/tck-005-print-queue-stuck.md) |
| **Intune** | Apps don't install, recovery keys unavailable | Delayed changes: <span class="badge badge--p3">P3</span> | [KB-014](kb/kb-014-bitlocker-recovery.md), [KB-016](kb/kb-016-install-approved-software.md) |

Impact levels are starting points; apply the [priority matrix](processes/priority-matrix.md) with the real impact and urgency of each incident.

## Triage path for "nothing works"

```mermaid
flowchart TD
    A["User: nothing works"] --> B{"Other users affected?"}
    B -- "Yes, many" --> MI["Possible major incident:<br/>open parent ticket, notify lead"]
    B -- "No, only this user" --> C{"Has an IP address?<br/>ipconfig"}
    C -- "169.254.x.x / none" --> D["DHCP / Wi-Fi: KB-010"]
    C -- "Valid IP" --> E{"Can resolve names?<br/>nslookup"}
    E -- "No" --> F["DNS: KB-010 step 5"]
    E -- "Yes" --> G{"Can sign in to<br/>portal.office.com?"}
    G -- "No" --> H["Identity: KB-001 / KB-003"]
    G -- "Yes" --> I["App-specific:<br/>Outlook KB-005, Teams KB-006,<br/>OneDrive KB-007, VPN KB-009"]
```

The [`Test-Connectivity.ps1`](scripts/Test-Connectivity.md) script automates the network half of this path and produces evidence to attach to the ticket.
