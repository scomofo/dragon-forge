# Journal & Milestones

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P1 — Collection Is the Heartbeat

## Summary

The Journal is a persistent, always-accessible codex that displays every dragon the player has ever owned, their live stats and lineage history, and a milestone achievement board. Milestones are one-time objectives spanning collection, battle, economy, and endgame categories that reward DataScraps on first claim. The system provides a soft long-term goal layer on top of the core collect-fuse-battle loop.

> **Quick reference** — Layer: `Feature` · Priority: `Vertical Slice` · Key deps: `Persistence, Battle Engine, Hatchery Engine, Fusion Engine`

## Overview

The Journal Screen is the player's durable record of progression. A left-side grid shows every dragon in the game; undiscovered dragons are silhouetted with a "???" label. Selecting a dragon opens a right-side detail panel showing its current sprite, nickname (editable), element, level, stage, live combat stats, and a lore quote attributed to Professor Felix. Below the detail panel sits the Fusion Lineage history (last five entries) and the full Milestone badge board.

Milestones are evaluated each time the player opens the Journal Screen. Any milestone whose condition is met and that has not previously been claimed is auto-claimed on entry: its ID is appended to `save.milestones`, its DataScraps reward is added to `save.dataScraps`, a `journalUnlock` sound plays, and a toast notification fires for each newly-claimed badge. Progress bars are shown on unclaimed badges so the player always knows how close they are to each reward.

## Player Fantasy

The player should feel like a dedicated researcher cataloguing a living world. Opening the Journal is a satisfying pause moment — a chance to survey what has been built, admire shinies, re-read lore, and see tangible proof of effort in the milestone board. Claiming a milestone should feel like a light punctuation mark: acknowledged, rewarded, and then the adventure continues. The player should never feel that fusing dragons set them back in the collection — discovered dragons stay in the codex permanently.

Primary MDA aesthetics served: **Collection** (the completionist drive to fill the grid), **Discovery** (unlocking lore entries), **Expression** (dragon nicknames).

## Detailed Design

### Core Rules

1. **Journal entry point.** The Journal Screen is reached via the NavBar and is available at all times. It does not consume any resources to visit.

2. **Discovery flag vs. owned flag.** Each dragon entry in `save.dragons` carries two independent boolean fields:
   - `owned`: `true` while the dragon is in the player's active roster. Set to `false` when the dragon is consumed as a fusion parent.
   - `discovered`: a permanent codex flag, set to `true` the first time `owned` becomes `true`. Fusion that consumes a dragon explicitly preserves `discovered: true` (see `persistence.js:fuseDragons`, lines 364-365). `discovered` is **never** reverted to `false` by any game action.

3. **Milestone evaluation.** On first render of the Journal Screen (`useEffect` with `hasCheckedRef` guard, `JournalScreen.jsx:23`), `checkMilestones(save)` is called. This iterates the `MILESTONES` array, runs each milestone's `check(save)` function, and computes `newlyClaimed = !claimed && met`.

4. **Auto-claim on entry.** For every milestone where `newlyClaimed` is `true`, `claimMilestone(milestoneId, reward)` is called (`persistence.js:218`). `claimMilestone` is idempotent: it checks `save.milestones.includes(milestoneId)` before acting and returns `false` (without writing) if the ID is already present. On a successful claim:
   - `milestoneId` is pushed to `save.milestones` (the array that serves as the permanent claimed-set).
   - `reward` DataScraps are added directly to `save.dataScraps`.
   - The save is written to `localStorage`.

5. **Batch claim UI.** All milestones that become newly-claimed in a single Journal visit are processed in a single loop. One `journalUnlock` sound fires (not one per milestone). One toast notification fires per claimed milestone: `"🏆 {name} — +{reward} ◆"`.

6. **Badge display.** Every milestone in `MILESTONES` is rendered as a badge in the `journal-milestones` grid regardless of claim state:
   - **Claimed**: green checkmark prefix, full-opacity badge.
   - **Newly claimed this visit**: gold `+{reward} ◆` sub-label shown temporarily.
   - **Unclaimed**: progress fraction shown as a sub-label (e.g., `7/8`).

7. **Dragon nickname.** Any owned dragon can be renamed via clicking the name in the detail panel. The input accepts up to 20 characters. On `Enter` or `blur`, `setDragonNickname(id, trimmedValue || null)` is called, which writes `nickname` to `save.dragons[id]` (or `null` to clear back to the species default). `Escape` cancels without saving.

8. **Dragon selection default.** On mount, the selected dragon defaults to the first element in `ELEMENTS` that the player currently owns. If no dragon is owned, it defaults to `'fire'` (the first entry in `ELEMENTS`).

9. **Lineage panel.** The Fusion Lineage panel renders if `save.fusionLineage.length > 0` OR `save.stats.fusionsCompleted > 0`. It shows the last five fusion events in reverse-chronological order, formatted as `PARENT_A + PARENT_B → OFFSPRING Lv.N`.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| Journal Idle | Player navigates to Journal | Player navigates away | Milestone check fires once on first render; browse freely |
| Milestone Claim | `newlyClaimed` items found on first render | Claim loop completes | `claimMilestone` called per item, sound plays, toasts fire, `refreshSave()` called |
| Nickname Edit | Player clicks an owned dragon's name | `Enter`, `blur`, or `Escape` | Input shown in-place; `Enter`/blur saves; `Escape` cancels |
| Dragon Detail | Player clicks any grid card | Another card clicked or navigate away | Right panel updates to show selected dragon's data |

### Interactions with Other Systems

| System | Data Flow | Details |
|--------|-----------|---------|
| Persistence (`persistence.js`) | Bidirectional | `checkMilestones` reads `save`; `claimMilestone` and `setDragonNickname` write to `localStorage` |
| Battle Engine (`battleEngine.js`) | Journal reads | `calculateStatsForLevel` and `getStageForLevel` used to display live stats and stage in the detail panel |
| Hatchery Engine | Upstream writer | Sets `owned: true` and `discovered: true` via `unlockDragon`; increments `save.stats.totalPulls` |
| Fusion Engine (`fusionEngine.js`, `persistence.js:fuseDragons`) | Upstream writer | Consumes parents (sets `owned: false`, preserves `discovered: true`), creates offspring; appends to `fusionLineage`; increments `stats.fusionsCompleted` |
| Sound Engine (`soundEngine.js`) | Journal writes | `playSound('journalUnlock')` fires on any newly-claimed milestone batch |
| NavBar | Navigation | `onNavigate` prop propagates screen changes |

## Formulas

### Collection Milestone Progress

Collection milestones count dragons where `discovered === true`, not `owned === true`.

```
discoveredCount = count(save.dragons where d.discovered === true)
```

This is evaluated independently per milestone with a hardcoded threshold:

| Milestone ID | Threshold | Field Checked |
|---|---|---|
| `first_discovery` | >= 1 | `d.discovered` |
| `elemental_trio` | >= 3 | `d.discovered` |
| `full_roster` | >= 8 | `d.discovered` |

`journalMilestones.js:8-32`

### Shiny Milestone Progress

Shiny milestones count dragons where `owned === true AND shiny === true`. Shiny count can decrease if a shiny dragon is fused away (this is intentional: shinies are a current-roster prestige, not a permanent codex entry).

```
shinyCount = count(save.dragons where d.owned && d.shiny)
```

| Milestone ID | Threshold | Reward |
|---|---|---|
| `shiny_hunter` | >= 1 | 300 DataScraps |
| `shiny_collector` | >= 3 | 1000 DataScraps |
| `shiny_completionist` | >= 8 | 2000 DataScraps |

`journalMilestones.js:36-61`

### Battle Win Milestones

```
winsProgress = Math.min(save.stats.battlesWon, threshold)
```

Progress display is capped at the threshold to avoid confusing `15/10` displays. The underlying `save.stats.battlesWon` is uncapped and used for other systems.

`journalMilestones.js:86-101`

### Stage Threshold (referenced by `elder_forged` and `apex_roster`)

Stage boundaries are defined in `gameData.js:23`:

```
stageThresholds = { 2: 8, 3: 20, 4: 38 }
```

Stage IV begins at level 38 but `elder_forged` requires `level >= 50` (the level cap). `apex_roster` requires all currently-registered dragons to be `owned && level >= 50`.

`journalMilestones.js:65-71` and `battleEngine.js:62-67`

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player fuses away a dragon that was their only copy | `discovered` stays `true`; collection milestones do not regress | Explicit design: fusion is an advancement action, not a loss (`persistence.js:364`) |
| Player opens Journal with 0 milestones met | `milestoneResults` populated from `checkMilestones`; no sound, no toasts; badges show progress fractions | Normal early-game state |
| Two milestones become claimable on same Journal open | Both claimed in a single loop; one `journalUnlock` sound plays; one toast per milestone | Batch behavior per `JournalScreen.jsx:35-43` |
| Player opens Journal again after claiming | `hasCheckedRef.current` is already `true`; `checkMilestones` does not re-run during the same React session | Guards against double-claiming on re-render |
| `claimMilestone` called for already-claimed ID | Returns `false` immediately without writing | Idempotency guard at `persistence.js:219` |
| Dragon has no nickname set | Detail panel displays `dragon.name` (species default); `progress.nickname` is `null` | `JournalScreen.jsx:161` |
| Nickname input left blank on blur | `setDragonNickname(id, null)` called; display reverts to species name | Trim-to-null logic at `JournalScreen.jsx:145` |
| `save.stats` is undefined (very old save) | Milestone checks use `|| 0` optional-chain fallback; no crash | `journalMilestones.js:89` pattern |
| `full_roster` milestone with old 6-dragon threshold save | Retroactively granted in `migrateSave` if `discovered >= 8` | `persistence.js:83-88` |
| `synthesis` dragon counted in `apex_roster` denominator | Yes — `apex_roster` iterates `Object.values(save.dragons)` which includes `synthesis`; requires all 9 dragons (8 base + synthesis) at Lv.50 | Intentional post-game completionist target |
| Player navigates away before milestone claim loop finishes | Claim loop is synchronous; completes before navigation state changes | No async risk |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `design/gdd/save-and-persistence.md` | This depends on Persistence | Reads `save.dragons`, `save.milestones`, `save.stats`, `save.records`, `save.inventory`, `save.fusionLineage`; writes via `claimMilestone`, `setDragonNickname` |
| `design/gdd/combat.md` | This depends on Battle Engine | Uses `calculateStatsForLevel`, `getStageForLevel` to display live stats in detail panel; `save.stats.battlesWon`, `save.records.longestStreak` feed battle milestones |
| `design/gdd/hatchery-gacha.md` | Hatchery depends on this | Hatchery sets `discovered: true` on unlock; hatchery pull count (`save.stats.totalPulls`) feeds `pull_addict` milestone |
| `design/gdd/fusion.md` | Fusion depends on this | Fusion must preserve `discovered: true` on consumed parents to avoid milestone regression; fusion outcome feeds `fusion_master` milestone |
| `design/gdd/economy.md` | This depends on Economy | Milestone rewards are dispensed as DataScraps into `save.dataScraps`; `scraps_hoarder` reads `save.stats.totalScrapsEarned` |
| `design/gdd/singularity-endgame.md` | This depends on Singularity | `singularity_contained`, `mirror_shattered`, `remnants_purged`, `synthesis_born` read Singularity completion flags |
| `design/gdd/dragon-progression.md` | This depends on Dragon Data | Reads `dragons[id].name`, `element`, `spriteSheet`, `stageSprites`, `baseStats`; reads `dragonLore[element]` |

## Tuning Knobs

All milestone thresholds and reward values live directly in `src/journalMilestones.js`. There are no external data files for this system — values are inline constants.

| Parameter | Current Value | Location | Category | Safe Range | Notes |
|-----------|--------------|----------|----------|------------|-------|
| `first_discovery` threshold | 1 | `journalMilestones.js:9` | Gate | 1 (fixed) | Onboarding reward; must trigger on first dragon |
| `first_discovery` reward | 100 DataScraps | `journalMilestones.js:7` | Curve | 50–200 | Low; early-game seed currency |
| `elemental_trio` threshold | 3 | `journalMilestones.js:18` | Gate | 2–4 | Mid-early collection target |
| `elemental_trio` reward | 200 DataScraps | `journalMilestones.js:17` | Curve | 100–400 | |
| `full_roster` threshold | 8 | `journalMilestones.js:28` | Gate | Fixed (= total base dragons) | Tracks base roster only; synthesis excluded |
| `full_roster` reward | 500 DataScraps | `journalMilestones.js:27` | Curve | 300–1000 | |
| `shiny_hunter` threshold | 1 owned shiny | `journalMilestones.js:39` | Gate | 1 (fixed) | |
| `shiny_hunter` reward | 300 DataScraps | `journalMilestones.js:38` | Curve | 200–500 | |
| `shiny_collector` threshold | 3 owned shinies | `journalMilestones.js:49` | Gate | 2–5 | |
| `shiny_collector` reward | 1000 DataScraps | `journalMilestones.js:48` | Curve | 500–2000 | |
| `shiny_completionist` threshold | 8 owned shinies | `journalMilestones.js:59` | Gate | Fixed (= total base dragons) | End-game completionist target; hardest milestone |
| `shiny_completionist` reward | 2000 DataScraps | `journalMilestones.js:58` | Curve | 1000–5000 | |
| `elder_forged` level threshold | 50 (level cap) | `journalMilestones.js:69` | Gate | 40–50 | Requires max level, not just Stage IV entry (38) |
| `elder_forged` reward | 250 DataScraps | `journalMilestones.js:67` | Curve | 150–500 | |
| `fusion_master` reward | 200 DataScraps | `journalMilestones.js:78` | Curve | 100–400 | Triggers on first `fusedBaseStats` dragon owned |
| `battle_veteran` threshold | 10 wins | `journalMilestones.js:88` | Gate | 5–25 | |
| `battle_veteran` reward | 150 DataScraps | `journalMilestones.js:87` | Curve | 100–300 | |
| `battle_champion` threshold | 50 wins | `journalMilestones.js:98` | Gate | 25–100 | |
| `battle_champion` reward | 500 DataScraps | `journalMilestones.js:97` | Curve | 300–1000 | |
| `core_collector` threshold | 50 total cores | `journalMilestones.js:109` | Gate | 25–100 | Counts all element cores across `save.inventory.cores` |
| `core_collector` reward | 200 DataScraps | `journalMilestones.js:107` | Curve | 100–400 | |
| `scraps_hoarder` threshold | 5000 total DataScraps earned | `journalMilestones.js:119` | Gate | 2500–10000 | Based on `totalScrapsEarned`, not current balance |
| `scraps_hoarder` reward | 300 DataScraps | `journalMilestones.js:118` | Curve | 150–600 | |
| `pull_addict` threshold | 50 hatchery pulls | `journalMilestones.js:129` | Gate | 25–100 | Based on `save.stats.totalPulls` |
| `pull_addict` reward | 200 DataScraps | `journalMilestones.js:128` | Curve | 100–400 | |
| `void_hunter` reward | 500 DataScraps | `journalMilestones.js:137` | Curve | 300–750 | Specific dragon acquisition; no threshold |
| `light_bearer` reward | 500 DataScraps | `journalMilestones.js:148` | Curve | 300–750 | Singularity completion reward dragon |
| `win_streak_5` threshold | 5 consecutive wins | `journalMilestones.js:162` | Gate | 3–10 | Based on `save.records.longestStreak` (all-time best) |
| `win_streak_5` reward | 250 DataScraps | `journalMilestones.js:161` | Curve | 150–500 | |
| `singularity_contained` reward | 1000 DataScraps | `journalMilestones.js:170` | Curve | 750–2000 | Post-game milestone |
| `mirror_shattered` reward | 1500 DataScraps | `journalMilestones.js:180` | Curve | 1000–3000 | True-final boss milestone |
| `remnants_purged` threshold | 3 remnants | `journalMilestones.js:191` | Gate | Fixed (3 = total remnants) | |
| `remnants_purged` reward | 1000 DataScraps | `journalMilestones.js:190` | Curve | 500–2000 | |
| `synthesis_born` reward | 750 DataScraps | `journalMilestones.js:199` | Curve | 500–1500 | Requires forging the Synthesis Dragon |
| `apex_roster` threshold | all dragons Lv.50 | `journalMilestones.js:209-214` | Gate | Fixed (all 9 dragons in roster) | Dynamic: counts all dragons in `save.dragons`; includes Synthesis |
| `apex_roster` reward | 2000 DataScraps | `journalMilestones.js:208` | Curve | 1000–5000 | Highest-effort milestone in the game |
| Nickname max length | 20 characters | `JournalScreen.jsx:134` | Feel | 10–30 | `maxLength` on the input element |
| Fusion Lineage display count | last 5 entries | `JournalScreen.jsx:199` | Feel | 3–10 | `.slice(-5).reverse()` |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Milestone newly claimed | Badge flashes `newly-claimed` CSS class; gold `+{reward} ◆` sub-label appears | `journalUnlock` sound: ascending sweep + arpeggio (280→860 Hz sweep, then 659/784/1047 Hz arpeggio triangle) | High |
| Dragon selected in grid | `selected` CSS class on card; border changes to element primary color | `buttonClick` sound | Medium |
| Undiscovered dragon slot | Silhouette rendering via `undiscovered-silhouette` CSS class; name shown as "???" | None | High |
| Nickname edit mode | In-place text input replaces name label with element glow color | None | Medium |
| Shiny dragon display | `★` star suffix on name in both grid card and detail panel | None | Medium |
| Fused dragon badge | `FUSED` tag in detail meta row | None | Low |

## Game Feel

N/A — turn-based browser game. The Journal is a UI information screen, not a real-time mechanic. There are no animation timings, hitboxes, or input latency requirements beyond standard browser event responsiveness. The only feel target is that milestone claim feedback (sound + toast) should fire within one render cycle of Journal open so the player connects the arrival action to the reward.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Dragon grid (all elements) | Left panel, `journal-grid` | Static per visit (no live updates after mount) | Always |
| Dragon sprite (current stage) | Left panel cards + right detail | On dragon selection | Always |
| Dragon name / nickname | Grid card label + detail header | On selection and after nickname save | Always; shows species name if no nickname |
| Dragon level + stage | Grid card sub-label + detail meta | On selection | Owned dragons only |
| "???" label + silhouette | Grid card | Static | Undiscovered dragons only |
| Live combat stats (HP/ATK/DEF/SPD) | Detail panel stat block | On selection | Owned dragons only |
| Lore quote | Detail panel | On selection | Owned: actual lore; Unowned: "No data available" |
| FUSED tag | Detail meta row | On selection | Dragon has `fusedBaseStats !== null` |
| Fusion Lineage panel | Below detail lore | On mount | `fusionLineage.length > 0` OR `fusionsCompleted > 0` |
| Discovery count | Below grid | Static per visit | Always; format: `N/M DISCOVERED` |
| Milestone badges | Bottom of detail panel | On mount (claims update state) | All milestones; progress fraction shown on unclaimed |
| Toast notification | Global toast overlay | On mount if newly claimed | Only when milestones are claimed this visit |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| `discovered` flag permanence | `design/gdd/fusion.md` | `fuseDragons` preserves `discovered: true` on parents | Rule dependency |
| DataScraps reward disbursement | `design/gdd/economy.md` | `save.dataScraps` increment via `claimMilestone` | Data dependency |
| `save.stats.battlesWon` | `design/gdd/combat.md` | Battle win counter tracked by `trackStat` | Data dependency |
| `save.records.longestStreak` | `design/gdd/combat.md` | Win streak record updated by `updateRecords` | Data dependency |
| `getStageForLevel` | `design/gdd/combat.md` | Stage IV threshold (level 38), level cap (50) | Rule dependency |
| `calculateStatsForLevel` | `design/gdd/combat.md` | Live stat computation for display in detail panel | Data dependency |
| `save.singularityComplete` | `design/gdd/singularity-endgame.md` | Completion flag set by `markSingularityComplete` | State trigger |
| `save.mirrorAdminDefeated` | `design/gdd/singularity-endgame.md` | True-final boss defeat flag | State trigger |
| `save.remnantDefeated` | `design/gdd/singularity-endgame.md` | Array of defeated remnant IDs; length checked against 3 | State trigger |
| `save.dragons.synthesis.owned` | `design/gdd/fusion.md` | Synthesis Dragon ownership flag | State trigger |
| `save.stats.totalPulls` | `design/gdd/hatchery-gacha.md` | Cumulative hatchery pull counter | Data dependency |
| `save.stats.totalScrapsEarned` | `design/gdd/economy.md` | Lifetime DataScraps earned counter | Data dependency |
| `save.inventory.cores` | `design/gdd/economy.md` | Core inventory map; values summed for `core_collector` | Data dependency |

## Acceptance Criteria

**Functional**

- [ ] Opening the Journal Screen with an unclaimed, met milestone results in that milestone being claimed exactly once: `save.milestones` gains the ID, `save.dataScraps` increases by the reward amount, and the badge shows the green checkmark.
- [ ] Opening the Journal Screen a second time in the same session does not re-claim any milestone (the `hasCheckedRef` guard prevents duplicate evaluation).
- [ ] After a dragon is fused away (parent consumed), its collection milestone progress does not decrease: `first_discovery`, `elemental_trio`, and `full_roster` evaluate `d.discovered`, not `d.owned`, and remain at or above their pre-fusion values.
- [ ] `claimMilestone` called with an already-claimed ID returns `false` and does not modify `save.dataScraps`.
- [ ] A player who navigates to the Journal with multiple simultaneously newly-claimable milestones receives one `journalUnlock` sound and one toast per milestone.
- [ ] A dragon nickname saved as empty string is stored as `null` and the detail panel displays the species name.
- [ ] Nickname changes persist across page reload (written to `localStorage` via `setDragonNickname`).
- [ ] Undiscovered dragons render as silhouettes with "???" name and "UNDISCOVERED" sub-label.
- [ ] The Fusion Lineage panel shows a maximum of 5 entries, in reverse-chronological order.
- [ ] `apex_roster` does not trigger until all dragons in `save.dragons` (including `synthesis`) are `owned && level >= 50`.
- [ ] `shiny_completionist` counts only `owned && shiny` dragons; fusing away a shiny can un-meet the milestone (though already-claimed milestones are never revoked).
- [ ] The discovery count label below the grid equals the count of currently-owned dragons (`owned === true`), not the `discovered` count. (Known Divergence (intended): `JournalScreen.jsx:59` — `discoveredCount` is computed as `filter(d => d.owned).length` so the grid shows current ownership for UX clarity; milestone logic uses `discovered` so collection progress never regresses when dragons are fused. QA should not file this as a defect.)

**Experiential**

- [ ] A playtester who fuses their only fire dragon does not notice any regression in the milestone board — collection badges hold their progress.
- [ ] The milestone board is readable at a glance: claimed badges are visually distinct from in-progress ones without requiring a legend.
- [ ] Renaming a dragon feels immediate: no loading state, no confirmation dialog.
- [ ] The Journal functions as a satisfying mid-session pause point — playtesters describe it as rewarding to visit, not as an obligation.

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should `win_streak_5` track `currentStreak` (requires consecutive wins in this session) or `longestStreak` (all-time)? Currently uses `longestStreak`. | Game Designer | — | Implemented as `longestStreak`; `currentStreak` is also tracked in `save.records` if a session-scoped variant is desired. |
| Should shiny milestone regression (fusing away shinies un-meeting the badge) be addressed with a `shinyDiscovered` permanent flag analogous to `discovered`? | Game Designer | — | Not currently implemented; by design, shiny milestones track current roster state. |
| `full_roster` counts only the 8 base elements; `apex_roster` counts all 9 including Synthesis. Should `full_roster` be renamed to reflect the "8 base dragons" scope? | Game Designer | — | Open. |
