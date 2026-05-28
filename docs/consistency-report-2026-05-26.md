# Consistency Check Report — 2026-05-26

Registry checked: 1 entity, 8 items, 8 formulas, 19 constants.

GDDs scanned: 12 top-level system GDDs under `design/gdd/*.md`, excluding `game-concept.md` and `systems-index.md`.

## Verdict

**PASS AFTER REVISIONS**

The initial scan found conflicts; all mechanical registry/GDD contradictions identified in this pass were resolved in-session.

## Resolved Conflicts

| Area | Resolution |
|---|---|
| `rest_charges` vs `battle_charges` | Registry and stale GDD wording now use Resonance / `battle_charges`. |
| `is_elder` schema | Dragon Progression data contract now includes `is_elder`; registry clarifies Fusion writes it only for two-Stage-IV-parent fusions. |
| Elder Stage IV multiplier | Battle Engine now applies `ELDER_STAGE_MULT = 1.75` for Elder Stage IV dragons. |
| Damage formula registry | Registry now matches Battle Engine: DEF/type/Defend/variance `[0.85, 1.0]` included. |
| Fusion stat inheritance registry | Registry no longer applies Elder multiplier to inherited base stats. |
| Passive Resonance in Campaign Map | Interaction text now matches Rule 9 and AC-CM18: benched dragons gain +1 Resonance per expedition battle, no XP. |
| Approval labels | Campaign Map support dependencies and Dragon Progression header now match approved status. |
| Defrag Patch wording | Shop now matches Battle Engine's single-slot active status model. |
| Campaign Map consumables | Campaign Map now defines Cache Shard and Emergency Patch MAP_EXPLORE behavior and ACs. |
| `ending_id` ownership | Campaign Map reads Singularity-owned `ending_id`; it does not write it. |

## Clean Entries

- `PULL_COST = 50`
- `MAX_LEVEL = 60`
- Standard stage multipliers I/II/III/IV = `0.5 / 0.75 / 1.0 / 1.4`
- Relic prices: Wrench `175`, Lens `200`, Blade `225`
- Consumable prices and Shop formulas

## Remaining Non-Conflict Concerns

- OQ-SH01 remains open by design: boss/hazard Scrap bonuses need Campaign Map node/playtest data.
- Economy/content lock should be produced before production balance lock.
- Cross-element Fusion and single-active-dragon carry need validation, but are not registry contradictions.
