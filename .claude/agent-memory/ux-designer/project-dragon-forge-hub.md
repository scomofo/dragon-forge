---
name: project-dragon-forge-hub
description: Dragon Forge Hub UX design context — station model, open decisions, and adversarial review findings
metadata:
  type: project
---

Dragon Forge Hub is the central hub space. Seven stations: Hatchery Ring, Anvil, Forge Console, Save Lantern, Bulkhead, Felix, Unit 01 (shop). All stations visible simultaneously, no loading screens between them. Gamepad-first: d-pad cycles focus between stations, face button activates.

**Why:** Hub is the emotional core of the game — "the room Felix is keeping." Every UX decision must serve the feeling that the room is held and maintained, not that it is a menu.

**Open UX decisions as of 2026-05-22 (adversarial review):**
1. Navigation order: spatial d-pad vs. linear cycle vs. hybrid shortcut — not yet decided
2. Bulkhead dual-role (viewport + exit): needs confirmation gate to prevent accidental Campaign Map exit — not yet designed
3. Unavailable station feedback: must use Godot-focus-aware inline labels + audio + visual (not hover tooltips) — not yet specified
4. Felix in focus cycle: either remove from cycle OR give ambient gesture response — binary decision needed before scene tree is built
5. Focus state on Hub return: recommend Save Lantern as canonical home station, explicit grab_focus() call — not yet decided
6. Passive HUD (floor-level info): Data Scraps, dragon count/capacity, act indicator must be always-visible without station activation — not yet designed

**How to apply:** When working on any Hub UX spec, check these six open questions first. None of these can be deferred to implementation — they affect scene tree structure, Godot focus system configuration, and animation requirements.
