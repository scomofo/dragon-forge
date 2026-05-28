---
name: project-game-context
description: Dragon Forge core context — pillars, platform, emotional arc, key characters
metadata:
  type: project
---

Dragon Forge is a 16-bit cyber-retro dragon-collecting RPG in Godot 4.6 (GDScript), desktop-only (Windows/macOS/Linux). Primary input is gamepad; keyboard/mouse is fallback. No touch support.

**Game pillars:** Gamepad-first, 16-bit cyber-retro aesthetic, emotional weight on Hub decisions (hatching and fusion are significant moments, not menu actions).

**Emotional arc:** Wonder → Attachment → Urgency → Dread → Agency.

**Key characters for UX:** Felix (mentor, keeps the Hub, speaks only at Elder emergence — one line ever), Skye (player character), Unit 01 (shop, slowly awakening android). Felix's silence is a narrative device; his presence in the room is the weight, not his words.

**Core loop:** Hatch (Hatchery Ring, costs 50 Data Scraps) → Forge (Anvil, fuses 2 dragons permanently) → Battle → Explore (Campaign Map) → Stabilize.

**Visual identity:** Charcoal/navy UI (#111118), 1px black outlines, CRT scanline overlays, pixel art. No floaty or distracting UI elements — Hub must feel like a room, not a menu.

**Godot 4.6 dual-focus constraint:** Mouse hover and keyboard/gamepad focus are separate systems. Any UI state that relies on hover will be invisible to gamepad players. All interactive elements need explicit focus states, not hover states. All labels that appear on hover must instead appear on gamepad focus.

**How to apply:** Frame all UX recommendations in terms of gamepad-first navigation. Never recommend hover-only states. Always check that suggested patterns work with d-pad + face button only.
