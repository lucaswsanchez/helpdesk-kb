---
title: Design System
---

# Design System

The portal is styled as a technical **operations workspace**: dark by default, dense, flat panels and color used only to carry meaning (priority, state, level). Everything is implemented in [`extra.css`](https://github.com/lucaswsanchez/helpdesk-kb/blob/main/docs/stylesheets/extra.css) on top of Material for MkDocs, without extra front-end dependencies.

## Color tokens

| Token | Dark | Light | Used for |
|---|---|---|---|
| `--ops-bg` | `#10151C` | `#F5F7FA` | Page background |
| `--ops-panel` | `#19212B` | `#FFFFFF` | Tables, cards, admonitions, dialogs |
| `--ops-border` | `#2A3542` | `#D5DCE4` | Panel borders and dividers |
| `--ops-blue` | `#5B9EFF` | `#1F5FBF` | Links, focus, active navigation, P3 |
| `--ops-teal` | `#42C8B5` | `#0B6E63` | Resolved state, completed timeline step |
| `--ops-amber` | `#F2A65A` | `#A8560F` | P2, escalated state |
| `--ops-red` | `#F27474` | `#B42323` | P1, security incidents |
| `--ops-muted` | `#97A3B3` | `#566476` | Secondary text, table headers, P4 |

Light-mode values are darker variants chosen to keep at least WCAG AA contrast on white panels. No fluorescent green is used; "resolved" uses teal.

## Typography

- **Inter** for interface and prose: 16px body text and 14px tables and navigation, comfortable for long sessions.
- **JetBrains Mono** for code, logs, IDs (`KB-010`, `TCK-004`), badges and numbers in stat tiles.

## Badges

Priority and state always use the same component, so a P1 looks the same on the overview, the matrix, the infrastructure map and a ticket.

| Type | Examples |
|---|---|
| Priority | <span class="badge badge--p1">P1 Critical</span> <span class="badge badge--p2">P2 High</span> <span class="badge badge--p3">P3 Medium</span> <span class="badge badge--p4">P4 Low</span> |
| Case state | <span class="badge badge--resolved">Resolved</span> <span class="badge badge--escalated">Escalated</span> <span class="badge badge--security">Security</span> <span class="badge badge--request">Request</span> |
| Support level (neutral: a level is not a status) | <span class="badge badge--l1">L1</span> <span class="badge badge--l2">L2</span> |

```html
<span class="badge badge--p2">P2 High</span>
```

Badges combine color **and** text, so meaning never depends on color alone.

## Resolution timeline

Ticket cases show the lifecycle stages they went through. Stages have no timestamps because the cases are practice scenarios.

<div class="timeline" markdown>

1. **Reported** User calls: cannot sign in.
2. **Triaged** Incident, <span class="badge badge--p3">P3</span>.
3. **Diagnosed** Stale password on the phone's mail app.
4. **Resolved** Account unlocked, phone updated, confirmed by the user.

</div>

```markdown
<div class="timeline" markdown>

1. **Reported** User calls: cannot sign in.
2. **Resolved** Account unlocked and confirmed.

</div>
```

## Command palette

Press ++ctrl+k++ (++cmd+k++ on macOS); the header search field shows the shortcut, and the overview has a jump box for touch screens. It searches page titles, KB and ticket IDs from the site's real search index, and includes actions (theme toggle, full-text search, repository). It follows the WAI-ARIA combobox pattern: arrow keys, ++enter++, ++esc++, and results are announced to screen readers.

## Principles

1. **Density over decoration**: compact tables, few boxes (borders only where something is interactive or a table needs a frame); no gradients, glows or illustrations. Uppercase is reserved for table headers.
2. **Color means something**: blue = interactive/informational, amber = attention, red = critical/security, teal = done.
3. **No fake telemetry**: numbers on the overview are computed from the repository at build time; there are no simulated live dashboards, terminals or status lights.
4. **Accessible by default**: visible focus rings, `prefers-reduced-motion` respected, keyboard-operable palette, light mode available.
