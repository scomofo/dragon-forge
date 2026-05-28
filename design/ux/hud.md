# HUD Design

> **Status**: In Design
> **Author**: Scott + ux-designer
> **Last Updated**: 2026-05-26
> **Template**: HUD Design

---

## HUD Philosophy

Dragon Forge uses an adaptive HUD. Exploration stays quiet and map-forward; battle becomes information-dense during TELEGRAPH; hub and shop surfaces show currency and collection state because those are planning tools. The HUD should feel like a rendered-world diagnostic layer: legible, restrained, and responsive without turning hidden lore gates into spreadsheets.

---

## Information Architecture

### Full Information Inventory

| Information | Source | Current Requirement |
|---|---|---|
| Player dragon HP and max HP | Battle / Campaign Map | Always visible in battle; active dragon HP visible on Campaign Map |
| NPC dragon HP and max HP | Battle | Always visible in battle |
| Active status and remaining turns | Battle | Visible only on afflicted combatant portrait |
| Turn phase | Battle | Visible during battle loop |
| Player action menu | Battle | Visible only in TELEGRAPH |
| NPC intent element | Battle | Visible during TELEGRAPH unless enemy skips |
| Defrag Patch action | Battle + Economy/Expedition settlement | Visible in TELEGRAPH when expedition flag allows it |
| Damage numbers | Battle | Contextual floating feedback |
| XP award | Battle / Dragon Progression | Shown at victory resolution before returning to map |
| Current act | Campaign Map | Always visible during MAP_EXPLORE |
| Data Scraps | Economy | Visible in Hub, Shop, Hatchery, and Campaign Map; exact below 1000, `999+` at 1000+ |
| Corruption class | Singularity | Visible on Campaign Map HUD as six-step indicator with text |
| Matrix tracker | Campaign Map + Dragon Progression | Hidden until `elemental_resonance` lore is read |
| Node name/type tooltip | Campaign Map | Contextual after 0.5s cursor inactivity |
| Gate denial text | Campaign Map | Terminal readout on denial |
| Dragon count | Hub / Dragon Progression | Visible in Hub passive HUD |
| Save Lantern state | Hub / Save | Peripheral progress indicator, non-blocking |
| Shop item price/current balance/projected balance | Shop / Economy | Shop focus and confirmation states |
| Hatchery pull cost and result | Hatchery / Economy / Dragon Progression | Visible on Hatchery screen and result screen |
| Fusion parent/child preview data | Fusion / Dragon Progression | Visible in Anvil preview |
| Shiny indicator | Dragon Progression | Persistent on dragon displays |
| Level and stage | Dragon Progression | Visible on dragon cards, battle panel, Hatchery detail |
| Crown relic choice | Singularity / Shop | Visible in Crown flow only |
| Mirror Admin phase | Singularity / Battle | Visible in Mirror Admin battle |
| Counter-ready state | Singularity / Battle | Visible during tritone window |
| Post-game archive/read-only state | Singularity / Campaign Map | Terminal readout, no persistent banner |

### Categorization

| Category | Items |
|---|---|
| Must Show | HP in battle, battle phase, TELEGRAPH action focus, NPC intent, current act on map, active dragon HP on map, Data Scraps where economy decisions happen, corruption class on map, focus state on all interactive screens |
| Contextual | Status indicators, Defrag Patch, damage numbers, XP award, node tooltip, gate denial, save progress, shop projected balance, Fusion preview, Crown relic choice, Mirror Admin phase, Counter-ready affordance |
| On Demand | Shop full item description through dwell reveal, Journal entries, roster details, longer lore terminal text |
| Hidden Until Earned | Elemental matrix tracker before `elemental_resonance`, exact hidden gate stats, post-ending unavailable relic purpose |
| Never Display | SPD stat, raw pity counters, hidden enemy level in map tooltip, internal save transaction state |

---

## Layout Zones

### Campaign Map

- **Top left**: Act label and current landmark name when stable.
- **Top right**: Data Scraps and corruption class indicator.
- **Bottom left**: Active dragon compact card with HP bar, level, stage, element, shiny indicator if applicable.
- **Bottom center**: Context prompt for current node, gate denial prompt, or Replay prompt.
- **Bottom right**: Matrix tracker only after `elemental_resonance` is read.
- **World layer**: Node cursor, SCAR overlays, CROWN icon, gate unlock presentation.

### Battle

- **Left combatant panel**: Player portrait, HP, level, stage, status.
- **Right combatant panel**: NPC portrait, HP, intent element, status.
- **Top center**: Turn phase label and Mirror Admin phase when active.
- **Bottom band**: TELEGRAPH action menu, Defend/Counter state, consumables when legal.
- **World layer**: Damage numbers, hit effects, KO/resolution feedback.

### Hub And Economy Screens

- **Top right**: Data Scraps and dragon count.
- **Screen body**: Station, Shop, Hatchery, Fusion, or Journal content owns the primary layout.
- **Peripheral indicators**: Save Lantern state and Forge Console glow remain readable without interrupting navigation.

---

## HUD Elements

| Element | Category | Contents | Interaction |
|---|---|---|---|
| Focus Ring | Must Show | Current gamepad/keyboard focus | Non-interactive feedback |
| Scrap Counter | Must Show / Contextual | `player_scraps`, `999+` at 1000+ | Read-only |
| Dragon Count | Contextual | Owned dragon count, `999+` at overflow | Read-only |
| Active Dragon Card | Must Show on Map/Battle | Portrait, element, HP, level, stage, shiny marker | Read-only during map/battle |
| Enemy Dragon Card | Must Show in Battle | Portrait, HP, intent/status | Read-only |
| Phase Label | Must Show in Battle | TELEGRAPH, IMPACT, RECOIL, Mirror Admin phase | Read-only |
| Action Menu | Contextual | Attack, Defend, status, consumables | Focusable, confirm/cancel |
| Corruption Indicator | Must Show on Map | Six-step class with text label and icon | Read-only |
| Matrix Tracker | Hidden Until Earned | Six filled/hollow element slots | Read-only |
| Node Tooltip | Contextual | Node name and type only | Auto-show, auto-dismiss |
| Transaction Panel | Contextual | Subject, price, balance, projected balance | Confirm/cancel |
| Terminal Readout | Contextual | Gate, Crown, post-game, Journal text | Confirm/cancel dismiss |

---

## Dynamic Behaviors

- HUD values update within one rendered frame of corresponding model or committed save-state changes.
- Purchase, reward, progression, ending, and post-game feedback waits for post-commit success.
- Matrix tracker is not instantiated until `elemental_resonance` is present in `visited_nodes[]`.
- Counter-ready presentation appears only during `tritone_window` and routes confirm through `battle_defend`.
- Battle action input is accepted only during TELEGRAPH.
- Save Lantern progress never locks Hub d-pad navigation.
- Gate denial readouts dismiss with confirm and preserve the player's map position.
- Corruption class changes update the HUD indicator within one frame and do not require audio to be understood.

---

## Platform & Input Variants

- Primary input: gamepad.
- Supported fallback: keyboard/mouse.
- Touch support: none.
- Every HUD-adjacent interaction uses Input Router semantic actions.
- Mouse hover can show equivalent visual focus, but keyboard/gamepad focus remains authoritative.
- Campaign Map d-pad tap moves node cursor; d-pad hold pans camera at the configured threshold.
- Shop and Crown horizontal rows stop at endpoints; no row wrap.

---

## Accessibility

- Follow the Standard tier in `design/accessibility-requirements.md`.
- HP danger state uses color, numeric HP, and bar fill, not color alone.
- Corruption class uses text plus icon state.
- Matrix tracker uses filled/hollow states plus element labels.
- Shiny state uses a persistent marker, not tooltip or hover.
- Save progress, Counter readiness, KO, and gate denial all have visual/text equivalents.
- Reduced-motion mode must bypass Hatchery reveal animation and reduce full-screen pulses/glitch transitions.

---

## Follow-Up Questions

- Font, icon, and final visual treatment should be locked when Art Bible Sections 5-9 are complete.
- Main menu and pause menu still need separate UX specs before the Pre-Production -> Production gate.
- Corruption rendering and restored gold-code overlay behavior must follow ADR-0011 before final HUD art sign-off.
- The final localization strategy should define text expansion limits for terminal readouts and compact HUD labels.
