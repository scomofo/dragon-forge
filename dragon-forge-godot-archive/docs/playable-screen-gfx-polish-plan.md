# Playable Screen GFX Polish Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Hardware Dungeons look and read like authored playable spaces instead of placeholder geometry.

**Architecture:** Keep `HardwareDungeonScene` as a custom `Control._draw()` renderer. Add small drawing helpers for room palettes, industrial panels, catwalk platforms, hazards, mechanisms, exits, player silhouette, and HUD framing without changing simulation or route-gate logic.

**Tech Stack:** Godot 4.6, GDScript, existing headless smoke script.

---

### Task 1: Add Room Visual Tokens

**Files:**
- Modify: `scripts/dungeon/hardware_dungeon_scene.gd`

- [ ] Add helper methods `_room_accent_color()`, `_room_warning_color()`, and `_room_shadow_color()` that return style-aware colors for all four Hardware Dungeons.
- [ ] Use these helpers from existing draw code instead of adding new scene nodes or imported assets.
- [ ] Run the smoke script and confirm no parser errors.

### Task 2: Replace Placeholder Platform And Hazard Drawing

**Files:**
- Modify: `scripts/dungeon/hardware_dungeon_scene.gd`

- [ ] Replace direct platform rectangles in `_draw()` with `_draw_platform(platform)`.
- [ ] Replace direct hazard rectangles in `_draw()` with `_draw_hazard(hazard)`.
- [ ] Ensure platform top edges remain high contrast, hazard outlines remain clear, and disabled/revealed hazards have distinct colors.
- [ ] Run the smoke script and confirm existing dungeon tests still pass.

### Task 3: Upgrade Mechanisms, Exits, Player, And HUD

**Files:**
- Modify: `scripts/dungeon/hardware_dungeon_scene.gd`

- [ ] Replace mechanism rectangles with `_draw_mechanism(mechanism)`.
- [ ] Replace exit rectangle drawing with `_draw_exit()`.
- [ ] Replace player block drawing with `_draw_player()`.
- [ ] Upgrade `_draw_hud()` and `_draw_boss_pressure()` with framed panels and room accents while preserving the same text content.
- [ ] Run the smoke script and visually launch the project if possible.

### Task 4: Final Verification

**Files:**
- Verify only.

- [ ] Run:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

- [ ] Expected result: Godot exits successfully after the simulation smoke checks.
- [ ] Optionally run `.\run-godot.ps1` and inspect Cooling Intake, Southern Partition Airlock, Great Buffer, and Logic Core.
