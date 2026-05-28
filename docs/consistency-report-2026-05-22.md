# Consistency Check Report
Date: 2026-05-22
Registry entries checked: 1 entity, 1 item, 5 formulas, 9 constants
GDDs scanned: 5 (battle-engine.md, hatchery.md, dragon-progression.md, fusion-engine.md, dragon-forge-hub.md)

---

### Conflicts Found (must resolve before architecture)

*None.*

---

### Stale Registry Entries (registry behind the GDD)

*None. Registry was populated fresh from the 5 approved GDDs on this date.*

---

### Unverifiable References (no conflict, informational)

ℹ️ **battle-engine.md** — Stage IV range written as "50+" (not "50-60").
   Dragon Progression is authoritative and states "50-60". "50+" is technically
   correct given MAX_LEVEL=60 but does not state the upper bound explicitly.
   No conflict detected. No action required; informational for future authors.

ℹ️ **battle-engine.md** — Stage IV threshold tuning knob (line ~289) written as
   `Stage IV threshold (level) | 50 | 45–55`. Dragon Progression owns this
   threshold. If battle-engine's safe range (45–55) is ever tuned, Dragon
   Progression must be updated first. No conflict now.

ℹ️ **dragon-progression.md** — XP threshold table (line ~62, ~258) shows
   Stage IV as levels "50–59" because level 60 is the cap with no next threshold.
   Stage definitions still show Stage IV as 50–60 consistently. Internally
   coherent; not a conflict.

---

### Clean Entries (no issues found)

✅ **MAX_LEVEL = 60** — dragon-progression.md (owner) + fusion-engine.md + hatchery.md all consistent.

✅ **PULL_COST = 50** — hatchery.md (owner) + dragon-forge-hub.md both state 50 Data Scraps.

✅ **SHINY_MULT = 1.2** — dragon-progression.md (owner) + battle-engine.md (shinyMult = 1.2) + hatchery.md ("1.2× stat multiplier") all consistent.

✅ **ELDER_STAGE_MULT = 1.75** — fusion-engine.md (owner) states 1.75 in multiple locations; no contradicting value in any other GDD.

✅ **ELDER_LEVEL_THRESHOLD = 50** — fusion-engine.md defines `is_elder = (parent.level >= 50)`; dragon-progression.md defines Stage IV entry at level 50. Consistent.

✅ **STAGE_I_MULT = 0.5** — dragon-progression.md (owner) + battle-engine.md both show I=0.5×.

✅ **STAGE_II_MULT = 0.75** — dragon-progression.md (owner) + battle-engine.md both show II=0.75×.

✅ **STAGE_III_MULT = 1.0** — dragon-progression.md (owner) + battle-engine.md both show III=1.0×.

✅ **STAGE_IV_MULT = 1.4** — dragon-progression.md (owner) + battle-engine.md both show IV=1.4×.

✅ **Stage thresholds** (I=1-9, II=10-24, III=25-49, IV=50-60) — both GDDs agree on all four boundaries.

✅ **Stat formula** `floor((baseStat + (level − 1) × 3) × shinyMult)` — dragon-progression.md (owner) and battle-engine.md (consumer) have identical expressions.

✅ **apply_xp** — hatchery.md correctly delegates to dragon-progression.md Formula 4 (`dragon_progression.apply_xp(dragon, xpGained)`).

✅ **xp_battle_scaling** `max(1, floor(base_xp × float(enemyLevel) / float(playerLevel)))` — battle-engine.md (canonical owner) and dragon-progression.md reference consistently.

✅ **is_elder flag** — fusion-engine.md sets at fusion time; dragon-forge-hub.md and hatchery.md reference without contradicting the definition.

✅ **child_data schema** — `{id, element, stage, level, base_hp, base_atk, base_def, base_spd, is_elder, is_shiny, xp, rest_charges}` — fusion-engine.md exports; dragon-forge-hub.md consumes; no field contradictions found.

✅ **Data Scrap HUD overflow** — dragon-forge-hub.md states "< 1000 displays exactly; ≥ 1000 shows '999+'" consistently across Formula 3, tuning knobs, and ACs.

---

Verdict: **PASS** — no conflicts. Registry and GDDs agree on all checked values.
16 entries verified across 5 GDDs with no conflicts.
