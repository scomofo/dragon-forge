---
name: project-fusion-engine-review
description: Adversarial QA review of Fusion Engine GDD AC set — findings, blocking gaps, and rewrites
metadata:
  type: project
---

Conducted adversarial review of `design/gdd/fusion-engine.md` AC set (53 ACs) on 2026-05-22.

**4 blocking gaps found:**

1. AC-FE11 is vacuously untestable — same-element same-stat test cannot distinguish canonical vs. leveled stat usage. Needs cross-element cross-level test spec (e.g., Storm level 50 + Stone level 59 to produce divergent leveled vs. canonical outputs).

2. AC-FE41 (crash-during-RESOLVING) requires test infrastructure (crash hook / fault injection) not yet designed or scoped. Cannot enter sprint without test hook design.

3. Missing Elder numeric regression AC — AC-FE25 only checks flags, not numeric output. Need AC: Fire+Fire Elder (both level 50) produces HP=137, ATK=35, DEF=20, SPD=27, is_elder=true.

4. AC-FE39 vs AC-FE41 design contradiction — AC-FE39 says invalid state cannot be persisted (atomic save); AC-FE41 says invalid state triggers repair on load (non-atomic). GDD line 104 also says "atomic" but EC-FE-16 implies repair-on-load. Designer must resolve before implementation.

**4 advisory gaps found:**

- AC-FE29 is a code-review criterion (no hardcoded 1.75), not a behavioral AC. Move to code review checklist; replace with behavioral AC testing constant coupling.
- AC-FE46 (secondary confirmation) has no observable negative case spec and no UX definition of the gesture. Needs UX spec alignment.
- Dual audio on Elder fusions: does fusion_complete also fire on Elders, or only elder_emerged? GDD implies both fire but ACs are ambiguous.
- PREVIEW stat comparison display (UI Requirements line 427) has zero AC coverage — entire feature unspecified in AC set.

**How to apply:** When this GDD's stories are sprint-planned, block Logic/Integration stories on findings 1, 3, 4. Require test hook design for Finding 2 before story can be accepted. Findings from the advisory set should be raised with designer/game-designer before UI stories are written.
