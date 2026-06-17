# Fusion

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P1 — Collection Is the Heartbeat

## Summary

Fusion lets the player permanently sacrifice two owned dragons (both level 10+) to create a single, more powerful offspring whose element is determined by an alchemy table and whose stats exceed the average of its parents. It is the primary mid-to-late-game power escalation path and the only way to obtain the secret Synthesis Dragon. Costs 100 Data Scraps per operation.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `battleEngine (calculateStatsForLevel, getStageForLevel)`, `persistence (fuseDragons, setStabilityBoost)`, `shopItems (stability_matrix item)`

---

## Overview

From the Fusion Chamber screen the player selects two owned dragons as parents, previews the outcome (element, stability tier, and projected stats), then pays 100 Data Scraps to confirm. Both parents are consumed — their `owned` flag is cleared and their level is reset to 1 — while the offspring is written to the save at the calculated element slot with the computed base stats and level. A Stability Matrix consumable (purchasable from the Shop) can be held in inventory and spent during the fusion to upgrade the stability tier by one step, trading economy resources for improved offspring stats. The system is the backbone of long-term progression and the sole unlock path for the Synthesis Dragon.

---

## Player Fantasy

The player should feel like a mad scientist witnessing an irreversible alchemical transformation. The choice is weighty because both parents are permanently gone — there is no undo. The reward is a dragon that feels demonstrably stronger than either parent. Players who invest in high-level parents should see a stat jump that visibly reflects that investment. Discovering a new element recipe for the first time (especially Synthesis) should feel like a eureka moment.

MDA primary aesthetic: **Discovery** (element alchemy table as hidden knowledge) and **Expression** (choosing which dragons to sacrifice is a meaningful, personal strategic statement).

---

## Detailed Design

### Core Rules

1. **Eligibility.** A dragon is eligible as a fusion parent if and only if: `owned === true` AND `level >= 10` AND the dragon's id is present in the `dragons` data table (`gameData.js`). Dragons with `owned === false` are excluded even if `discovered === true`.
   - Source: `FusionScreen.jsx` line 18–25: `.filter(([id, d]) => d.owned && d.level >= 10 && dragons[id])`

2. **Slot selection.** The player fills two slots (Parent A and Parent B). The same dragon cannot occupy both slots. Clicking a filled slot deselects it. Clicking a card from the picker fills the first empty slot; if both are empty, it fills slot A first.

3. **Cost gate.** A fusion attempt requires exactly 100 Data Scraps in `save.dataScraps`. The "FUSE — 100◆" button is disabled if the condition `parentA && parentB && save.dataScraps >= 100` is not met.
   - Source: `FusionScreen.jsx` line 27, `persistence.js` line 360.

4. **Offspring element.** Determined by `getFusionElement(parentA.element, parentB.element)`. The element key is derived by sorting the two parent element strings alphabetically and joining with `_`, then looking up the result in the `ALCHEMY` table. If the key is absent from ALCHEMY, the result is the alphabetically first element of the two parents.
   - Source: `fusionEngine.js` lines 1–42.

5. **Stability tier.** Determined by `getStabilityTier(elementA, elementB, stabilityBoost)`:
   - Same-element parents → `stable`
   - Opposing-pair parents → `unstable`
   - All other pairings → `normal`
   - If `stabilityBoost === true` and the calculated tier is not already `stable`, the tier advances one step up the order: `unstable → normal → normal → stable`.
   - Source: `fusionEngine.js` lines 27–62.

6. **Stat calculation.** Stats are computed by `calculateFusionStats(statsA, statsB, stabilityTier)`. The inputs (`statsA`, `statsB`) are the **level-scaled current stats** of each parent as returned by `calculateStatsForLevel`, not the raw base stats.
   - Source: `FusionScreen.jsx` line 23–24 (stats computed via `calculateStatsForLevel`), `fusionEngine.js` lines 64–92.

7. **Offspring level.** `Math.min(30, Math.max(1, Math.round((parentA.level + parentB.level) / 2)))`. The result is capped at 30 regardless of parent levels. XP starts at 0.
   - Source: `fusionEngine.js` line 100. Note: `fuseDragons` in `persistence.js` line 361 applies a secondary cap of 50, which is never reached given the formula's 30 cap.

8. **Shiny inheritance.** If either parent has `shiny === true`, the offspring has `shiny === true`.
   - Source: `fusionEngine.js` line 98.

9. **Parent consumption.** After a successful fusion, both parent entries in `save.dragons` are set to: `{ level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null, discovered: true }`. The `discovered` flag is preserved (never cleared) so collection-count milestones do not regress.
   - Source: `persistence.js` lines 364–365.

10. **Offspring write.** The offspring entry at `save.dragons[offspringElement]` is overwritten (merging with existing entry to preserve other fields): `{ level, xp: 0, owned: true, discovered: true, shiny, fusedBaseStats }`.
    - If the target slot is already occupied (the offspring element already `owned`), the existing dragon is overwritten without warning.
    - Source: `persistence.js` lines 366–374.

11. **Lineage record.** Each fusion appends `{ parentA: parentAId, parentB: parentBId, offspring: offspringElement, offspringLevel }` to `save.fusionLineage`. This array is used by `migrateSave` to retroactively preserve `discovered` flags on old saves.
    - Source: `persistence.js` lines 377–378.

12. **Stability Matrix consumption.** When `stabilityBoost === true` at fusion time, and the unmodified stability tier would have been `unstable` or `normal` (i.e., the boost had an effect), `setStabilityBoost(false)` is called, consuming the item.
    - If the pair was already `stable` without the boost, the Matrix is **not** consumed and the UI shows "STABILITY MATRIX — NO EFFECT (pair already stable)".
    - Source: `FusionScreen.jsx` lines 64, 29, 152–156.

13. **Stat tracking.** `save.stats.fusionsCompleted` is incremented by 1 on each successful fusion (both in `fuseDragons` and via `trackStat('fusionsCompleted')` — the latter is called after the async animation, so the stat increments twice per fusion).
    - Source: `persistence.js` line 376, `FusionScreen.jsx` line 65.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| `select` | Screen mount / after result dismiss | Player confirms fusion (enters `animating`) | Player picks parents, previews result |
| `animating` | `handleFuse` called when `canFuse && phase === 'select'` | Animation completes (~1000ms) | Locked UI; plays `fusionMerge` then `fusionBurst` sounds; executes fusion logic |
| `result` | Animation completes | Player clicks result card | Displays offspring card; plays `fusionReveal` sound |

### Interactions with Other Systems

- **Battle Engine (`calculateStatsForLevel`, `getStageForLevel`)**: FusionScreen uses `calculateStatsForLevel` to resolve each parent's current stats for use as fusion inputs. `getStageForLevel` determines sprite stage for preview display.
- **Persistence (`fuseDragons`, `setStabilityBoost`, `trackStat`)**: All save mutations happen through these functions. `fuseDragons` is the authoritative mutation; it also decrements `dataScraps` and appends the lineage record.
- **Shop (`stability_matrix` item)**: The Stability Matrix is purchased in the Shop, setting `save.inventory.stabilityBoost = true`. It is a one-time-use consumable that FusionScreen reads and conditionally clears.
- **Journal Milestones**: The `fusionsCompleted` stat increment triggers milestone checks elsewhere in the app (e.g., first fusion milestone).
- **Dragon Codex / Collection Screen**: `discovered` flag preservation means fusing a dragon does not reduce collection progress.

---

## Formulas

### Offspring Base Stats

```
avg_stat     = (statA + statB) / 2
fused_stat   = floor(avg_stat * 1.1)

if stabilityTier === 'stable':
    final_stat = floor(fused_stat * 1.25)

else if stabilityTier === 'unstable':
    final_hp   = floor(fused_hp * 0.8)     // HP only
    final_atk  = floor(fused_atk * 1.1)    // ATK only; DEF and SPD unchanged

else (normal):
    final_stat = fused_stat
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `statA` | int | ≥ 1 | Parent A's level-scaled current stat | One of hp/atk/def/spd |
| `statB` | int | ≥ 1 | Parent B's level-scaled current stat | One of hp/atk/def/spd |
| `stabilityTier` | enum | `stable \| normal \| unstable` | `getStabilityTier()` | Determines multiplier path |

**Effective multipliers vs. raw parent average (all stats):**
- Stable: `× 1.375` (= 1.1 × 1.25)
- Normal: `× 1.1`
- Unstable: HP `× 0.88` (= 1.1 × 0.8), ATK `× 1.21` (= 1.1 × 1.1), DEF `× 1.1`, SPD `× 1.1`

Source: `fusionEngine.js` lines 64–92.

### Offspring Level

```
offspring_level = min(30, max(1, round((levelA + levelB) / 2)))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `levelA` | int | 10–50 | `parentA.level` | Level of parent A at time of fusion |
| `levelB` | int | 10–50 | `parentB.level` | Level of parent B at time of fusion |

**Expected output range**: 10 to 30.

Source: `fusionEngine.js` line 100.

### Stability Tier Determination

```
if elementA === elementB:
    tier = 'stable'
else if (elementA, elementB) is an OPPOSING_PAIR:
    tier = 'unstable'
else:
    tier = 'normal'

if stabilityBoost AND tier != 'stable':
    tier = STABILITY_ORDER[indexOf(tier) + 1]
    // 'unstable' → 'normal', 'normal' → 'stable'
```

**OPPOSING_PAIRS** (order-independent):
- `fire ↔ ice`
- `storm ↔ stone`
- `venom ↔ shadow`

Source: `fusionEngine.js` lines 27–62.

### Alchemy Table (Element Output by Input Pair)

The table is keyed by alphabetically sorted `elementA_elementB`. Pairs not listed fall back to the alphabetically first input element.

| Sorted Key | Offspring Element |
|------------|------------------|
| `fire_fire` | fire |
| `ice_ice` | ice |
| `storm_storm` | storm |
| `stone_stone` | stone |
| `venom_venom` | venom |
| `shadow_shadow` | shadow |
| `fire_ice` | storm |
| `fire_storm` | fire |
| `fire_stone` | stone |
| `fire_venom` | shadow |
| `fire_shadow` | fire |
| `ice_storm` | ice |
| `ice_stone` | stone |
| `ice_venom` | venom |
| `ice_shadow` | shadow |
| `stone_storm` | storm |
| `storm_venom` | venom |
| `shadow_storm` | shadow |
| `stone_venom` | venom |
| `shadow_stone` | stone |
| `shadow_venom` | shadow |
| `light_void` | synthesis |
| `void_light` | synthesis |

**Secret recipe**: `light + void → synthesis`. This is the only recipe that produces the Synthesis Dragon. The duplicate `light_void` / `void_light` entries are redundant given the `sortedKey` normalization, but both are listed in the source table.

Source: `fusionEngine.js` lines 1–25.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Offspring element slot is already owned | Existing dragon is silently overwritten with the new offspring. No confirmation prompt. | Persistence: `fuseDragons` does not guard against this. Implementers: add a warning if desired. |
| Both parents at level 10 (minimum) | Offspring level = `round((10+10)/2)` = 10. | Minimum offspring level is 10 given the eligibility floor. |
| Both parents at level 30 | Offspring level = 30 (cap applies). | Level cap prevents fusion chains from creating hyper-leveled dragons trivially. |
| Both parents at level 50 | Offspring level = 30 (cap applies). | Same cap; the secondary cap of 50 in `fuseDragons` is never reached. |
| One parent shiny, one not | Offspring is shiny. | Shiny is inherited if either parent carries it (`fusionEngine.js` line 98). |
| Stability Matrix held, pair already stable | Matrix is NOT consumed. UI shows "NO EFFECT" notice. | `boostEffective` check in `FusionScreen.jsx` line 29 guards consumption. |
| Stability Matrix on unstable pair | Tier advances to normal; Matrix is consumed. | `getStabilityTier` with `stabilityBoost=true` and tier `unstable` returns `normal`. |
| Stability Matrix on normal pair | Tier advances to stable; Matrix is consumed. | Tier `normal` → index 1 → index 2 → `stable`. |
| Pair not in ALCHEMY table | Offspring element = alphabetically first of the two parents. | `getFusionElement` fallback: `key.split('_')[0]` after alphabetical sort. |
| `dataScraps < 100` at time of confirm | `fuseDragons` returns `null` without mutation. UI button is already disabled by `canFuse` guard. | Double-guard: UI and persistence both enforce the cost. |
| `fusionsCompleted` double-increment | `stats.fusionsCompleted` increments once inside `fuseDragons` and once via `trackStat`. Net effect: +2 per fusion. | This is a live bug. The stat is only used for milestones and display; it does not affect gameplay balance. |
| Offspring base stats stored vs. live stats | `fusedBaseStats` (the fusion output) is stored on the offspring's save entry and used as the base for future `calculateStatsForLevel` calls. Repeated fusions accumulate compounding base stat boosts. | Intended: fusion chains can produce powerful dragons. No upper bound is enforced on `fusedBaseStats` values. |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `battleEngine.calculateStatsForLevel` | Fusion depends on Battle Engine | Fusion inputs are level-scaled stats, not raw base stats. If the level-scaling formula changes, fusion output changes. |
| `battleEngine.getStageForLevel` | Fusion depends on Battle Engine | Used in FusionScreen for sprite stage display only; no effect on stats. |
| `persistence.fuseDragons` | Fusion depends on Persistence | All save mutations route through this function. |
| `persistence.setStabilityBoost` | Fusion depends on Persistence | Clears the Stability Matrix flag after use. |
| `shopItems.stability_matrix` | Fusion depends on Shop | The Stability Matrix item is the only external source of `save.inventory.stabilityBoost = true`. |
| `gameData.dragons` | Fusion depends on Game Data | Offspring element must exist in the `dragons` table or the result card has no sprite/name. |
| `journalMilestones` | Milestones depend on Fusion | `fusionsCompleted` stat is checked for milestone thresholds. |
| `collectionScreen / codex` | Collection depends on Fusion | `discovered` flag preservation ensures collection counts are not regressed by fusion. |

---

## Tuning Knobs

All values are hardcoded in `src/fusionEngine.js` and `src/persistence.js` — no external data file. They should be migrated to `assets/data/fusion.json` for easier balancing.

| Parameter | Current Value | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-------------------|-------------------|
| Fusion cost (scraps) | 100 | 50–300 | Gate | Fusion is rarer, scrap economy more meaningful | Fusion is trivial; players fuse recklessly |
| Base fusion multiplier | 1.1× (all stats) | 1.0×–1.3× | Curve | Offspring stats grow faster; chain-fusion snowball risk | Fusion provides less incentive; normal stat gain |
| Stable bonus multiplier | 1.25× (applied after base 1.1×) | 1.1×–1.5× | Curve | Same-element fusions become dominant strategy | Stability tier distinction loses meaning |
| Unstable HP penalty | 0.8× HP | 0.6×–0.95× | Curve | Opposing fusions become more punishing | Opposing fusions become acceptable |
| Unstable ATK bonus | 1.1× ATK (applied after base 1.1×) | 1.0×–1.3× | Curve | Unstable fusions become an ATK-specialist strategy | Unstable fusions are pure downgrade |
| Level cap for offspring | 30 | 10–50 | Gate | Offspring start stronger; reduces incentive to level parents before fusing | Offspring start weaker; fusing high-level parents has less benefit |
| Minimum parent level to fuse | 10 | 5–20 | Gate | Forces more investment before fusion unlocks | Allows early fusion; reduces hatchery relevance |

Source file locations: cost check at `fusionEngine.js` implicit (enforced in `persistence.js:360`), multipliers at `fusionEngine.js:73–89`, level cap at `fusionEngine.js:100`, minimum level filter at `FusionScreen.jsx:19`.

---

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Fusion confirmed | Phase transitions to `animating`; radial white gradient flash overlay displayed | `fusionMerge` (600ms), then `fusionBurst` (400ms after merge) | High |
| Fusion result revealed | Phase transitions to `result`; full-size offspring sprite card displayed with stability badge | `fusionReveal` | High |
| Stability Matrix active | "STABILITY MATRIX ACTIVE — +1 TIER" notice (purple `#cc88ff`) in preview | None | Medium |
| Stability Matrix no-effect | "STABILITY MATRIX — NO EFFECT (pair already stable)" notice (grey `#888`) in preview | None | Low |
| Parent slot filled | Slot renders parent sprite + name + level | `buttonClick` | Medium |
| Shiny offspring | `★` star badge rendered next to offspring name on result card | None (inherits parent shiny VFX via DragonSprite) | Medium |

---

## Game Feel

N/A — turn-based browser game. There is no frame-data, hitbox timing, controller rumble, or hit-stop to specify. The mechanic's "feel" is expressed through the irreversibility of parent consumption (weight) and the stat preview (information). The ~1000ms animation sequence (`fusionMerge` + `fusionBurst`) provides the single kinetic moment of commitment before the reveal.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Both parent slots (name, level, element color, sprite) | Fusion parents panel | On parent selection change | Always shown |
| Result preview (element, stability tier badge, projected stats) | `fusion-preview` panel | On any parent selection change | Shown when both parents selected |
| Stability Matrix active notice | Inside `fusion-preview` | Reactive | `boostEffective === true` |
| Stability Matrix no-effect notice | Inside `fusion-preview` | Reactive | `stabilityBoost && !boostEffective` |
| Cost warning ("⚠ Both parents will be consumed") | Inside `fusion-preview` | Static | Shown whenever preview is visible |
| "FUSE — 100◆" button (enabled/disabled) | Bottom of select phase | On `canFuse` change | Always shown during select phase |
| "Need 2+ dragons at level 10+" hint | Below fuse button | Static | `ownedDragons.filter(d => d.level >= 10).length < 2` |
| Result card (offspring sprite, name, stability badge, base stats, level) | Fullscreen result overlay | Static until dismissed | Shown in `result` phase |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Level-scaled parent stats used as fusion inputs | `design/gdd/dragon-progression.md` | `calculateStatsForLevel` formula and stat budget (12 per level) | Data dependency |
| Stage display in Fusion Chamber | `design/gdd/dragon-progression.md` | `getStageForLevel` thresholds (levels 8, 20, 38) | Data dependency |
| Stability Matrix item definition and cost | `design/gdd/economy.md` | `stability_matrix` shop item (100 scraps + 3 different-element cores) | Rule dependency |
| Data Scraps currency | `design/gdd/economy.md` | `dataScraps` balance and faucet/sink model | Rule dependency |
| `discovered` flag preservation | `design/gdd/journal-milestones.md` | Collection progress non-regression guarantee | Rule dependency |
| `fusionsCompleted` milestone triggers | `design/gdd/journal-milestones.md` | Milestone threshold values | State trigger |

---

## Acceptance Criteria

**Functional:**
- [ ] Fusing two dragons with a valid ALCHEMY key produces offspring of the correct element (verify all 23 recipes in the table, including `light + void → synthesis`).
- [ ] Fusing a pair not in ALCHEMY produces offspring of the alphabetically first element.
- [ ] Both parents have `owned = false`, `level = 1`, `xp = 0`, `shiny = false`, `fusedBaseStats = null`, `discovered = true` after fusion.
- [ ] Offspring is written with `owned = true`, `discovered = true`, correct `fusedBaseStats`, and `level = min(30, max(1, round((lA+lB)/2)))`.
- [ ] `dataScraps` is reduced by exactly 100.
- [ ] Fusion is rejected (button disabled and `fuseDragons` returns `null`) when `dataScraps < 100`.
- [ ] Dragons with `level < 10` do not appear in the picker.
- [ ] Stability Matrix is consumed (set to `false`) only when the boost had a material effect (pair was not already stable).
- [ ] Stability Matrix is not consumed when fusing a same-element pair.
- [ ] Same-element fusion produces `stable` tier; opposing-pair fusion produces `unstable` tier; all other pairs produce `normal` tier.
- [ ] `fusionLineage` gains one entry per fusion with correct `parentA`, `parentB`, `offspring`, `offspringLevel`.
- [ ] Shiny offspring is produced when at least one parent was shiny.
- [ ] A second fusion can use the offspring of the first fusion (provided offspring is level ≥ 10).

**Experiential (playtest):**
- [ ] Players understand that fusion is permanent before committing (the "⚠ Both parents will be consumed" warning is visible and read).
- [ ] The stat preview accurately matches the final offspring stats within ±1 (rounding).
- [ ] First-time discovery of the `synthesis` recipe produces a moment of surprise/delight without external hints.
- [ ] Players who fuse two same-element level-30 dragons perceive the result as stronger than a freshly hatched dragon of the same type.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| `fusionsCompleted` double-increment bug (increments +2 per fusion via both `fuseDragons` and `trackStat`) | Lead Programmer | — | Not yet resolved. Milestone thresholds should be audited for off-by-one if fixed. |
| No confirmation prompt when fusing would overwrite an already-owned offspring dragon | Game Designer | — | Should a warning be added for the overwrite case? Current behavior is silent overwrite. |
| `fusedBaseStats` has no cap; repeated fusion chains can produce arbitrarily high base stats | Systems Designer | — | Determine whether a stat ceiling is needed for balance, especially in NG+ runs. |
