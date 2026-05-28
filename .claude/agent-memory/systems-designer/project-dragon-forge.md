---
name: project-dragon-forge
description: Dragon Forge — 16-bit cyber-retro dragon-collecting RPG; Singularity endgame arc in active design as of 2026-05-24
metadata:
  type: project
---

Dragon Forge is a 16-bit cyber-retro dragon-collecting RPG built in Godot 4.6 (GDScript, controller-first, PC). The studio uses a 49-agent Claude Code architecture with GDDs in `design/gdd/`. Entity registry is at `design/registry/entities.yaml`.

**Active work (2026-05-24):** Singularity GDD (`design/gdd/singularity.md`) is in design — Overview and Player Fantasy sections are written; Detailed Design and beyond are stubs. The user requested a full gap analysis before drafting Detailed Design.

**Why:** The Singularity system is the endgame arc: corruption state machine (NOMINAL→BREACH), boss sequencer (3 gatekeepers + Mirror Admin 3-phase), and ending gate (relic-based, 3 endings). It crosses Campaign Map, Audio Director, Save/Persistence, and Roster systems heavily.

**Key cross-system facts confirmed:**
- Campaign Map save data fields: `current_node_id`, `acts_unlocked[]`, `matrix_stabilized`, `visited_nodes[]`, `scar_nodes[]`, `cleared_bosses[]`, `cleared_combat_nodes[]`, `loadout_hp[]`, `previous_node_id`, `unlocked_gates[]`, `expedition_xp_earned`, `gate_denial_count`, `ending_id`
- `ending_id` is owned by Campaign Map in save data — Singularity writes to the same field (not a separate one)
- Void dragon is added to roster on Mirror Admin defeat; must conform to dragon data schema in entities.yaml
- Dragon data schema: id, element, stage, level, base_hp, base_atk, base_def, base_spd, is_elder, is_shiny, xp, rest_charges
- Relics: relic_wrench_owned (175 scraps), relic_lens_owned (200 scraps), relic_blade_owned (225 scraps) — lifetime flags, never reset

**How to apply:** Always check entities.yaml for cross-system facts before proposing data structures. `ending_id` is already in Campaign Map save — Singularity must write to that field, not define a new one.
