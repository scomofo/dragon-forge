# Save & Persistence

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-09-05
> **Last Verified**: 2026-09-05 (save recovery implementation; browser acceptance pending)
> **Implements Pillar**: P3 — The Myth Is Hardware (diegetic save); P5 — Earned Mastery, Never Trivialized

## Summary

Save & Persistence stores the canonical game state at `dragonforge_save`, with a previous-write backup and preserved damaged originals for explicit recovery. `persistence.js` owns the schema and gameplay helpers; `saveValidation.js` validates known field shapes; `saveStorage.js` handles guarded reads/writes and pending progress. Additive migration retains legacy progress, including reconstruction of the `discovered` codex flag from fusion lineages.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (all other systems depend on this; this system depends on none)

---

## Overview

Screens call `persistence.js` helpers, which load a copy, mutate it, and attempt a synchronous write. `DEFAULT_SAVE` remains the canonical schema. Load validates present fields, runs semantic `migrateSave()` backfills, then fills missing defaults. If a write fails, subsequent helpers use the pending in-memory save so later mutations do not discard unsaved progress. A status subscription drives the recovery screen or persistent save warning. There is no versioning integer, migration queue, or server round-trip.

---

## Player Fantasy

The target feeling is **trustworthiness**: normal saving stays quiet; failures explain what is retained and give the player a recovery choice. A local backup cannot survive origin storage deletion, and memory-only progress can be lost when a tab closes, so downloads provide a portable copy. Returning players retain the `introSeen` heuristic and retroactive milestone grants instead of having to re-earn old progress.

Primary MDA aesthetics served: **Submission** (the player trusts the system enough to stop worrying about losing progress) and **Achievement** (milestone and record state are permanent, so every accomplishment accumulates visibly).

---

## Detailed Design

### Core Rules

1. **Storage keys**: `dragonforge_save` remains the main object. `dragonforge_save_backup` holds the previous changed write; `dragonforge_save_damaged` and numbered suffixes retain raw damaged originals during explicit recovery. These are managed by `saveStorage.js`.

2. **Load path**: A genuinely empty store starts with defaults. Malformed JSON, invalid field shapes, inaccessible storage on startup, or a missing main save with a backup block gameplay. A complete fallback object is available for rendering, but it does not authorize fresh-game writes. Recovery must explicitly restore, import, or reset.

3. **Write path**: `writeSave(save)` validates, compares the stored main value with the last value read, writes the safety copy, then writes the main value. Failure returns `false` and retains ordinary gameplay changes in memory for retry/export. A detected external change blocks further writes until the player resolves the conflict. This comparison is not an atomic cross-tab lock.

4. **No versioning integer**: Migration is field-presence-based (`if (field === undefined)`), not schema-version-based. Every migration guard runs on every load, making the function idempotent: calling `migrateSave` on an already-migrated save is a no-op.

5. **Explicit replacement**: Import (up to 1 MiB) previews owned dragons, wins, and scraps before confirmation. Restore confirms replacement with the backup. Damaged main bytes must be archived before either overwrites them. Confirmed reset removes recovery copies and writes a fresh main save; failures retain the main value and attempt to restore removed copies. Multi-key rollback is best effort. These actions return an explicit success/error result.

6. **Dragon `discovered` flag semantics**: `discovered` is a permanent codex flag. Once `true` it is never set back to `false`, even when fusion consumes a dragon (which sets `owned = false`). Codex collection-count milestones count `discovered`, not `owned`, so fusing never regresses progress. (`persistence.js` lines 6–8, comment block)

7. **Fusion write**: `fuseDragons()` resets both parents to `{ level: 1, xp: 0, owned: false, shiny: false, fusedBaseStats: null, discovered: true }`, sets the offspring's full state, deducts 100 DataScraps, increments `stats.fusionsCompleted`, and appends a lineage record `{ parentA, parentB, offspring, offspringLevel }` to `save.fusionLineage`. (`persistence.js` lines 358–381)

8. **XP progression**: `applyDragonXp(dragon, amount)` is the single canonical XP function. It walks the dragon up as many levels as the XP covers, using `xpForLevel(level) = 50 + (level - 1) * 5`. Level cap is 50; at cap, residual XP is zeroed. All XP sources (battle win, duplicate pull, shop item) must call this function. (`persistence.js` lines 188–204)

9. **Core inventory cap**: Element cores are capped at 99 per element in both `addCore()` and `grantReplayReward()`. (`persistence.js` lines 325–327, 264)

10. **New Game+**: `startNewGamePlus()` gates on `mirrorAdminDefeated === true`. `applyNewGamePlus()` increments `ngPlus`, clears `defeatedNpcs`, `singularityProgress`, `singularityComplete`, `mirrorAdminDefeated`, `remnantDefeated`, and resets `flags.currentAct` to 1 and `flags.fragmentsUnlocked` to `[]`. The collection (dragons, scraps, cores, milestones, records, stats, skye) is fully preserved. (`persistence.js` lines 424–441)

    **NG+ reset vs. kept boundary** — fields explicitly reset: `defeatedNpcs`, `singularityProgress`, `singularityComplete`, `mirrorAdminDefeated`, `remnantDefeated`, `flags.currentAct`, `flags.fragmentsUnlocked`. Fields explicitly kept (not reset): `dragons`, `dataScraps`, `inventory.cores`, `milestones`, `stats`, `skye`, `ngPlus` (incremented), `fusionLineage`, `journalRecords`, **`pityCounter`**. `pityCounter` carries over intentionally: a player who reaches NG+ with an accumulated pity count is guaranteed a Rare+ on their first NG+ hatchery pull as a reward for the completed run. This is a deliberate design choice, not an oversight.

11. **Daily Challenge streak**: `completeDailyChallenge(seed)` stores the seed of the last completed challenge as `lastDailyCompleted`. Streak increments only if `lastDailyCompleted` equals "yesterday's seed" (computed as `YYYY * 10000 + MM * 100 + DD` for the previous calendar day). Otherwise streak resets to 1. (`persistence.js` lines 406–418)

12. **Replay rewards**: `getReplayReward(clearCount)` grants a 5-core cache of a rotating element on every 5th total clear of any Singularity boss (`clearCount % 5 === 0`). The element cycles through `['fire','ice','storm','stone','venom','shadow']` in index order. (`persistence.js` lines 253–258)

### States and Transitions

Storage status is separate from the save schema: `ready` permits play; `unsaved` retains session progress and shows retry/download; `recovery`, `unavailable`, and `conflict` block gameplay. Startup telemetry and heartbeats skip blocked states. The save itself contains these progression fields:

| Field | Values | Transition Rule |
|-------|--------|----------------|
| `dragon.owned` | `false` → `true` | Set by `unlockDragon()`, `fuseDragons()` offspring, `markSingularityComplete()` (light dragon). Never set to false by any path other than fusion parents via `fuseDragons()`. |
| `dragon.discovered` | `false` → `true` | Set to `true` by any of: `unlockDragon()`, `fuseDragons()` (parents and offspring), `migrateSave()` backfill. Never transitions back to `false`. |
| `introSeen` | `false` → `true` | Set by `markIntroSeen()`. Migration backfills to `true` if any dragon is already owned. |
| `singularityComplete` | `false` → `true` | Set by `markSingularityComplete()`. Reset to `false` by `applyNewGamePlus()`. |
| `mirrorAdminDefeated` | `false` → `true` | Set by `markMirrorAdminDefeated()`. Reset to `false` by `applyNewGamePlus()`. |
| `ngPlus` | integer ≥ 0 | Incremented by `applyNewGamePlus()`. Never decremented. |
| `flags.currentAct` | integer ≥ 1 | Set via `setFlag('currentAct', n)`. Reset to `1` by `applyNewGamePlus()`. |

### Interactions with Other Systems

Every game system reads from and writes to the save object via `persistence.js` helpers. No system maintains its own separate persistent state.

| Caller System | Read | Write | Primary Helpers Used |
|---------------|------|-------|---------------------|
| Battle (battleEngine) | dragon stats, ngPlus, relics | battlesWon/Lost, XP, scraps, records, cores | `loadSave`, `writeSave`, `applyDragonXp`, `updateRecords`, `addScraps`, `addCore`, `decrementXpBoost` |
| Hatchery | pityCounter, scraps, dragon owned/shiny | dragon unlock, pity, scraps | `unlockDragon`, `addDragonXp`, `updatePityCounter`, `spendScraps` |
| Fusion | dragon levels, scraps | dragon states, fusionLineage, scraps, stats | `fuseDragons` |
| Shop | scraps, cores, inventory | scraps, xpBoost, stabilityBoost, relics | `spendScraps`, `spendCores`, `setXpBoost`, `setStabilityBoost`, `grantRelic` |
| Journal Milestones | milestones[], dragon discovered counts | milestones, scraps | `claimMilestone`, `loadSave` |
| Singularity | singularityProgress, singularityComplete | singularityProgress, light dragon | `recordSingularityDefeat`, `updateFinalBossPhase`, `markSingularityComplete` |
| Forge/Skye | skye object, flags | wrenchTier, relicSlots, relicsOwned/Equipped, companionDragonId, fragments | `upgradeWrench`, `grantRelic`, `equipRelic`, `unequipRelic`, `unlockFragment`, `setCompanionDragon` |
| Daily Challenge | lastDailyCompleted, dailyStreak | both | `completeDailyChallenge` |
| App.jsx | all fields | introSeen, flags | `markIntroSeen`, `setFlag`, `setLastZone` |

---

## Formulas

### XP-to-Level Curve

```
xpRequired(level) = 50 + (level - 1) * 5
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `level` | integer | 1–49 | The level the dragon currently holds (not the level being entered) |
| result | integer | 50–290 | XP needed to advance from `level` to `level + 1` |

**Level cap**: 50. At level 50, `dragon.xp` is zeroed and no further advancement occurs.

**Example**: To advance from level 1 to level 2 requires 50 XP. From level 10 to 11 requires 95 XP. From level 49 to 50 requires 290 XP.

**Full-curve bounds**: minimum 50 XP per level (at level 1), maximum 290 XP per level (at level 49).

Source: `persistence.js` line 188.

### Daily Challenge Seed

```
seed = year * 10000 + (month + 1) * 100 + day
```

`year`, `month`, `day` are from `new Date()` at the moment the challenge is completed. `month` is zero-indexed (JS `Date.getMonth()`), so `+1` is applied. The seed is used as a comparator only — it identifies a calendar day as an integer, not as a random seed for content generation.

Source: `persistence.js` lines 406–418.

### Replay Core Reward Rotation

```
element = REPLAY_REWARD_CORE_ELEMENTS[((clearCount / 5) - 1) % 6]
reward  = { element, count: 5 }   (only when clearCount % 5 === 0)
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `clearCount` | integer | ≥ 1 | Total number of times this boss has been cleared (all-time, including current run) |
| element | string | one of 6 | Cycles: fire → ice → storm → stone → venom → shadow → fire → ... |
| count | integer | 5 | Cores granted; capped at 99 per element in inventory |

Source: `persistence.js` lines 253–265.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Storage cannot be read on startup | Block gameplay and offer retry/import/recovery; do not write defaults. | Existing progress may still be present. |
| Storage write fails during play | Show a persistent warning, retain all subsequent changes in memory, and offer retry/download. | The next helper must not reload older disk progress. |
| Malformed JSON or invalid nested shape | Block gameplay, leave raw main bytes untouched, and offer damaged download plus explicit recovery. | Unreadable data must not be silently overwritten by startup or heartbeat writes. |
| Backup/archive write fails | Do not overwrite the main save; report failure. | Recovery protection must succeed before replacement. |
| Another tab changes the main save before a pending write | Block the write, retain this session for download, and confirm loading the stored progress. | Prevent detected stale writes from silently replacing another session. |
| Dragon pulled that player already owns | XP is granted to the existing dragon via `applyDragonXp` instead of setting `owned = true` again. No duplicate entry is created. | Handled by hatchery callers, not by `persistence.js` itself. |
| Fusion with insufficient scraps (< 100) | `fuseDragons()` returns `null` and writes nothing. | Guard at `persistence.js` line 360. |
| `xpForLevel` called at level 50 | Returns 290 (the formula is evaluated, result is valid but unused — the `while` loop condition `dragon.level < 50` prevents the value from being consumed). | No division or undefined behavior; the cap is in the loop guard, not the formula. |
| `discovered` flag for pre-existing saves | `migrateSave()` backfills based on current `owned || level > 1 || xp > 0 || !!fusedBaseStats`, then repairs any dragon that appears in `fusionLineage` as parent or offspring. | Ensures collection-count milestones are correct for players who upgraded mid-development. |
| `full_roster` milestone retroactive grant | If `milestones` does not include `'full_roster'` and the player has ≥ 8 discovered dragons, `migrateSave()` pushes `'full_roster'` and adds 500 DataScraps. | The milestone threshold was raised from 6 to 8 dragons at some point; this compensates older saves that met the old threshold. |
| Singularity complete, light dragon not owned | `migrateSave()` sets `dragons.light.owned = true` and `discovered = true`. Also enforced by `markSingularityComplete()` at the moment of completion. | Light Dragon is the Singularity completion reward; retroactive grant covers players who completed before the reward was introduced. |
| `startNewGamePlus()` called when `mirrorAdminDefeated` is false | Returns `false` and writes nothing. | Gate prevents NG+ from being triggered by incomplete runs. |
| `pityCounter` value after `applyNewGamePlus()` | `pityCounter` is NOT reset; it retains its pre-NG+ value. A player who enters NG+ with a high pity count will receive a guaranteed Rare+ on their first NG+ hatchery pull. This is intentional — the carry-over is a reward for completing the endgame arc. | Distinct from the full collection/economy fields that are also preserved: `pityCounter` carry-over has a direct mechanical effect on the player's first NG+ session.|
| Core count exceeding cap | `addCore()` and `grantReplayReward()` both apply `Math.min(99, ...)`. Overflow is silently truncated. | Prevents unbounded inventory growth. |
| `spendCores()` goes to zero or below | The key is deleted from `inventory.cores` entirely (`delete save.inventory.cores[el]`), leaving a clean sparse object. | Avoids accumulation of zero-valued keys. |
| `claimMilestone()` called with already-claimed ID | Returns `false` immediately; no scraps are added and the array is not modified. | Idempotency guard — safe to call from any context. |

---

## Dependencies

This system is the **foundation layer**. All other systems depend on it; it depends on nothing.

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| `design/gdd/dragon-progression.md` | Dragon Progression depends on Save | Dragon level, XP, and fusedBaseStats are stored in and read from the save object. `applyDragonXp` is the canonical XP function. |
| `design/gdd/hatchery-gacha.md` | Hatchery depends on Save | `pityCounter`, `dataScraps`, and `dragon.owned/shiny` are all persisted here. |
| `design/gdd/economy.md` | Economy depends on Save | `dataScraps` faucets and sinks are all writes to this system. |
| `design/gdd/fusion.md` | Fusion depends on Save | `fuseDragons()` is the only write path for fusion outcomes. `fusionLineage` record lives here. |
| `design/gdd/journal-milestones.md` | Journal Milestones depends on Save | `milestones[]` and `dragon.discovered` count are read and written here. |
| `design/gdd/shop-and-crafting.md` | Shop depends on Save | Inventory items (`cores`, `xpBoostBattles`, `stabilityBoost`) and relic ownership live here. |
| `design/gdd/forge-skye.md` | Forge/Skye depends on Save | The entire `skye` sub-object and `flags.fragmentsUnlocked` are owned by this system. |
| `design/gdd/daily-challenge.md` | Daily Challenge depends on Save | `lastDailyCompleted` and `dailyStreak` are owned here. |
| `design/gdd/campaign-map.md` | Campaign Map depends on Save | `defeatedNpcs`, `flags.currentAct`, `flags.lastZone`, `ngPlus` are all owned here. |

**External dependency**: `forgeData.js` — `canEquipRelic()` is imported by `persistence.js` and called inside `equipRelic()`. This is the one case where `persistence.js` imports from a content module rather than being purely data-agnostic. (`persistence.js` line 1)

**ADR references**: [ADR-0003](../../docs/architecture/adr-0003-single-localstorage-save-migrate.md) records the canonical schema and React ownership. [ADR-0012](../../docs/architecture/adr-0012-protected-save-recovery.md) supersedes its corrupt-save fallback and unguarded storage operations.

---

## Tuning Knobs

| Parameter | Current Value | Safe Range | Category | File:Line | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-----------|-------------------|-------------------|
| Main storage key | `'dragonforge_save'` | N/A — compatibility contract | Gate | `saveStorage.js` | N/A | N/A |
| XP base at level 1 (`50` in `xpForLevel`) | 50 | 30–100 | Feel | `persistence.js:188` | Slower early levelling; more grinding before first stage unlock | Faster early power spike; reduces sense of level-up accomplishment |
| XP ramp per level (`5` in `xpForLevel`) | 5 | 2–15 | Curve | `persistence.js:188` | Steeper late-game XP wall; levels 40–50 become very slow | Flatter curve; high levels feel less meaningful as milestones |
| Dragon level cap | 50 | 20–100 | Gate | `persistence.js:197` | More room for long-term grind; stat spread widens | Shorter progression arc; caps out earlier in campaign |
| Fusion cost | 100 DataScraps | 50–200 | Gate | `persistence.js:360` | Makes fusion a rarer, more deliberate event | Makes fusion trivial; reduces its significance as a system |
| Core inventory cap | 99 per element | 20–999 | Gate | `persistence.js:325` | Allows more stockpiling; reduces pressure to spend | More inventory pressure; forces regular crafting |
| Replay core reward count | 5 cores per qualifying clear | 1–10 | Curve | `persistence.js:257` | More generous endgame farm; reduces grind for crafting targets | Less rewarding replay loop; boss replay feels less worth doing |
| Replay reward frequency | every 5th clear | 3–10 | Gate | `persistence.js:256` | Rewards less frequent; replay loop extended | Rewards more frequent; endgame economy floods faster |
| `full_roster` retroactive milestone threshold | 8 discovered dragons | N/A — historical fix | Gate | `persistence.js:85` | N/A (historical migration value; do not tune) | N/A |
| NG+ gate | `mirrorAdminDefeated` required | N/A — boolean gate | Gate | `persistence.js:437` | N/A | N/A |

---

## Visual/Audio Requirements

This is a pure data-layer system. No visual or audio output is generated by `persistence.js` itself. All feedback from save-driven events (e.g., dragon level-up, milestone claim) is the responsibility of the calling screen component.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Save written | None (silent background operation) | None | N/A |
| Load failure / corrupt save | Blocking recovery screen with explicit actions and damaged download | None | High |
| Write failure during play | Persistent retry/download warning, including during battle | None | High |
| Level-up (triggered by `applyDragonXp`) | Handled by caller (BattleScreen, HatcheryScreen) | Handled by caller | High |
| Milestone claimed (`claimMilestone`) | Handled by caller (JournalScreen) | Handled by caller | High |

---

## Game Feel

Successful saves stay quiet. A failed write keeps the active battle mounted while retry and download remain available. Recovery text must state what will be replaced, and cancellation must leave progress unchanged.

---

## UI Requirements

`SaveRecovery.jsx` supplies the blocking recovery screen, persistent save warning, and shared Settings save controls. Import, restore, reset, and loading conflicting stored progress require explicit confirmation; errors must not show success feedback. Controls need keyboard focus, accessible status/error text, and a readable 390px layout. Gameplay callers still invoke `refreshSave()` to display the current save, including pending in-memory progress.

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| `dragon.discovered` codex flag drives collection milestones | `design/gdd/journal-milestones.md` | `full_roster` and collection-count milestone checks | Rule dependency |
| `fusionLineage` backfill repairs `discovered` for fusion parents | `design/gdd/fusion.md` | fuseDragons() write contract | Rule dependency |
| `applyDragonXp` is the canonical XP function for all sources | `design/gdd/dragon-progression.md` | `xpForLevel` curve and level cap | Data dependency |
| `pityCounter` field supports the 10-pull pity guarantee | `design/gdd/hatchery-gacha.md` | Pity reset rule | Data dependency |
| `dataScraps` faucets and sinks | `design/gdd/economy.md` | DataScraps economy model | Data dependency |
| `skye` sub-object (wrench, relics, companion) | `design/gdd/forge-skye.md` | Wrench tier and relic slot counts | Data dependency |
| `defeatedNpcs`, `flags.currentAct` | `design/gdd/campaign-map.md` | NPC defeat tracking, act progression | Data dependency |
| `inventory.cores` | `design/gdd/shop-and-crafting.md` | Core spending in forge crafting | Data dependency |
| `lastDailyCompleted`, `dailyStreak` | `design/gdd/daily-challenge.md` | Streak tracking | Data dependency |
| `canEquipRelic` imported from `forgeData.js` | `design/gdd/forge-skye.md` | Relic equip eligibility rules | Rule dependency |

---

## Acceptance Criteria

- [ ] An empty store starts normally; inaccessible startup storage blocks writes without throwing.
- [ ] Malformed JSON or invalid nested data opens recovery; startup and heartbeat leave its bytes untouched.
- [ ] Failed writes preserve sequential gameplay mutations for retry and current-save download.
- [ ] Backup/archive failures leave the main value untouched; invalid imports change nothing.
- [ ] Confirmed restore/import preserves damaged bytes; confirmed reset removes old recovery copies.
- [ ] A detected conflicting stored value cannot be overwritten by retrying pending progress.
- [ ] Complete the real-browser checks in `docs/save-recovery-playtest.md`, including failures during battle and narrow-screen keyboard/touch controls.
- [ ] `writeSave()` followed immediately by `loadSave()` returns an object equal to the written object (round-trip fidelity).
- [ ] `migrateSave()` called on an already-migrated save produces an identical result (idempotency).
- [ ] A save created before `discovered` existed: after `migrateSave()`, every dragon with `owned === true` or `level > 1` or `xp > 0` has `discovered === true`.
- [ ] A save with a `fusionLineage` containing a dragon that has since been fused away: after `migrateSave()`, that dragon has `discovered === true` even though `owned === false`.
- [ ] `fuseDragons()` returns `null` and does not mutate the save when `dataScraps < 100`.
- [ ] `fuseDragons()` leaves both parent dragons with `discovered: true` even though `owned: false`.
- [ ] `applyDragonXp()` never advances a dragon beyond level 50; at level 50 the dragon's `xp` field is zeroed.
- [ ] `xpForLevel(1)` returns 50; `xpForLevel(49)` returns 290.
- [ ] `addCore()` caps the result at 99; calling `addCore('fire', 100)` on a save with `cores.fire === 50` yields `cores.fire === 99`, not 150.
- [ ] `startNewGamePlus()` returns `false` without writing if `mirrorAdminDefeated` is `false`.
- [ ] After `applyNewGamePlus()`: `defeatedNpcs` is `[]`, `singularityProgress.defeated` is `[]`, `singularityComplete` is `false`, `ngPlus` incremented, dragon collection unchanged.
- [ ] `claimMilestone()` with a previously claimed ID returns `false` and does not increment `dataScraps`.
- [ ] `completeDailyChallenge(seed)`: if `lastDailyCompleted` equals yesterday's seed, `dailyStreak` increments; otherwise it resets to 1.
- [ ] `getReplayReward(5)` returns `{ element: 'fire', count: 5 }`; `getReplayReward(10)` returns `{ element: 'ice', count: 5 }`; `getReplayReward(7)` returns `null`.
- [ ] `markSingularityComplete()` sets `dragons.light.owned = true` and `dragons.light.discovered = true`.
- [ ] The retroactive `full_roster` grant in `migrateSave()` triggers only when `discovered` count ≥ 8 and `'full_roster'` is not already in `milestones[]`; exactly 500 DataScraps are added.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| If the game expands to Godot runtime, should `persistence.js` semantics be ported 1:1 to GDScript, or should the Godot build use a different save format (e.g., `.tres` resource files)? | technical-director | Before Godot persistence is implemented | The Godot build at `dragon-forge-godot/` does not yet have a persistence layer; this question is open. |
| `canEquipRelic` is imported from `forgeData.js` inside `persistence.js`, coupling a pure-data module to a content module. Should this logic move into `persistence.js` or remain in `forgeData.js`? | lead-programmer | Next refactor sprint | Current design works; question is one of architectural cleanliness. |
