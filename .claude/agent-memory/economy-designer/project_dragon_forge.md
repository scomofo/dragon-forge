---
name: project-dragon-forge
description: Dragon Forge game project overview — economy-relevant facts, missing GDDs, key systems
metadata:
  type: project
---

Dragon Forge is a single-player turn-based RPG in Godot 4.6. Players raise elemental dragons through 4 evolution stages (levels 1-9, 10-24, 25-49, 50+) across a 40+ landmark campaign (Village Edge to Mainframe Crown).

**Why:** Economy review requested 2026-05-21. XP formula and progression balance were flagged as potentially unbalanced.

**How to apply:** When designing any resource flow or reward structure for this project, use these anchors.

## Economy-relevant anchors
- XP formula: `max(1, floor(base_xp × (enemyLevel / playerLevel)))`
- base_xp range: 25–90 across known NPCs
- Stat scaling: `floor((baseStat + (level-1)×3) × shinyMult)`; linear +3/level
- Stage multipliers: Stage I = 0.5×, II = 0.75×, III = 1.0×, IV = 1.4×
- Stage thresholds: level 10 (I→II), 25 (II→III), 50 (III→IV)
- No level cap defined in any GDD

## Critical missing documents
- `design/gdd/shop.md` — listed as Designed in systems index but file does not exist
- `design/gdd/dragon-progression.md` — listed as Designed but file does not exist
- `design/gdd/campaign-map.md` — listed as Designed but file does not exist
- XP-to-level curve: NEVER defined in any existing GDD (critical gap)
- HP recovery between battles: listed as open question in battle-engine.md

## Authored GDDs (files confirmed on disk as of 2026-05-21)
- design/gdd/battle-engine.md (Designed)
- design/gdd/game-concept.md (Approved)
- design/gdd/systems-index.md
