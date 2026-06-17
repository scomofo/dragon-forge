# Forge & Skye (Companion + Relics)

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Player agency through persistent loadout customisation; narrative grounding through the Forge hub

## Summary

The Forge is the game's persistent hub screen where the player character Skye walks a 2-D space and interacts with five stations. The Anvil station manages Skye's passive equipment (Analog Relics) and the Wrench upgrade path that determines how many relics can be equipped simultaneously. Relics are dropped by bounty/boss kills and apply flat stat bonuses or conditional combat effects that carry into every dragon battle.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps: `battle-engine`, `persistence`, `singularity-progress`

---

## Overview

When the player navigates to the Forge screen, Skye spawns at a fixed starting position (x=30, y=75 on a 100×100 grid) and can move freely within the scene using keyboard (WASD / arrow keys) or gamepad d-pad. Six interactable stations are placed around the scene; Skye highlights the nearest station within its proximity radius and can press Enter / Space / E (or gamepad A / X / Start) to open that station's overlay. The Bulkhead station exits to the world map; Escape with no overlay open also exits. The Forge screen has no navigation bar — a persistent "EXIT TO MAP" button in the top-right corner ensures mouse/touch players are never trapped.

Skye's persistent state is stored under `save.skye.*` in `localStorage` key `dragonforge_save`. On first entry the game runs `bootstrapForgeSave`, which grants the starting relic (`iron_knuckle`) if the player has no relics, marks Felix as met, and unlocks available Captain's Log fragments.

---

## Player Fantasy

The player should feel like a returning operative coming back to base between missions — Skye is their avatar moving through a lived-in industrial space. Interacting with the Anvil should feel like meaningful loadout preparation: choosing which relics to slot is the one durable decision the player makes before every battle. Upgrading the wrench is a milestone moment ("I can carry more power now"). Felix's contextual one-liners reward players who notice the world, reinforcing the sense that their progress is being witnessed by someone who cares about it.

Primary MDA aesthetics served: **Fantasy** (being an operative with equipment choices), **Discovery** (finding new relics, unlocking log fragments), **Narrative** (Felix's commentary reacts to player milestones).

---

## Detailed Design

### Core Rules

#### Forge Movement

1. Skye's position is expressed as `{ x, y }` percentages on a 100×100 grid (`forgeMovement.js:1`).
2. Each keypress or gamepad direction press moves Skye by `FORGE_STEP = 2` units in the pressed direction (`forgeMovement.js:1,34`).
3. Position is clamped to `FORGE_BOUNDS = { minX: 4, maxX: 96, minY: 20, maxY: 92 }` after every move (`forgeMovement.js:4–7`).
4. Movement is disabled while any overlay is open (`ForgeScreen.jsx:112–114`).
5. Keyboard bindings: Arrow keys and WASD for movement; Enter, Space, or E to interact; Escape or Backspace to cancel overlay or exit Forge (`forgeMovement.js:9–18,53–59`).
6. Gamepad bindings: d-pad for movement; A, X, or Start to interact; B or Select to close overlay (`ForgeScreen.jsx:152–161`).

#### Station Proximity and Interaction

7. On every render, `findNearestStation(skyePos)` iterates all six `FORGE_STATIONS` entries and returns the station whose `pos` is within that station's `proximity` threshold and is closest to Skye (`forgeData.js:363–375`). If no station is within range, `nearest` is `null`.
8. Proximity thresholds per station (percentage units, `forgeData.js:32–98`):

   | Station | ID | Proximity |
   |---|---|---|
   | Hatchery Ring | `hatcheryRing` | 14 |
   | Save Lantern | `saveLantern` | 10 |
   | The Anvil | `anvil` | 12 |
   | The Console | `console` | 12 |
   | Felix | `felix` | 10 |
   | World Exit (Bulkhead) | `bulkhead` | 8 |

9. Interacting with Bulkhead immediately navigates to `map` with a `screenTransition` sound; no overlay is opened.
10. Interacting with Felix triggers context-aware dialogue (see Felix Dialogue System below). All other stations open an overlay panel.
11. Clicking the overlay backdrop (outside the panel) closes the overlay. Escape / Backspace with an overlay open closes the overlay instead of exiting the Forge.

#### First-Visit Bootstrap (`ForgeScreen.jsx:36–62`)

12. On first mount of `ForgeScreen`, `bootstrapForgeSave(save)` runs exactly once. It performs the following mutations if needed:
    - Sets `flags.metFelix = true` if not already set.
    - Runs `FRAGMENT_TRIGGERS` predicates against the current save; unlocks fragments `001` and `002` unconditionally; unlocks other fragments whose predicate returns `true`.
    - Grants `iron_knuckle` relic if `save.skye.relicsOwned` is empty.
    - Calls `refreshSave()` only if at least one mutation was made.

#### Felix Dialogue System (`forgeData.js:124–175`, `ForgeScreen.jsx:91–96`)

13. On first interaction with Felix (determined by `isFirstVisitRef` initialized from `!save.flags.felixGreeted`), the game plays `FELIX_FIRST_VISIT_LINE` and sets `flags.felixGreeted = true`. This path fires only once per save.
14. On subsequent interactions, `pickFelixLine(save)` iterates `FELIX_CONTEXTUAL` in order (skipping the `firstVisit` entry) and returns the `line` of the first entry whose `when(save)` predicate returns `true`. If no predicate matches, a random line from `FELIX_IDLE_LINES` (16 total) is returned.
15. Contextual predicates evaluated in priority order:

    | Priority | ID | Condition |
    |---|---|---|
    | 1 | `mirrorAdminDefeated` | `save.mirrorAdminDefeated === true` |
    | 2 | `allElements` | All 8 elements (`fire ice storm stone venom shadow void light`) are owned |
    | 3 | `remnantsAvailable` | `save.singularityComplete === true` |
    | 4 | `irisFragmentUnlocked` | Fragment `'007'` is in `flags.fragmentsUnlocked` |
    | 5 | `firstBountyKill` | `save.skye.bountiesCleared === 1` |
    | 6 | `wrenchTier3` | `save.skye.wrenchTier >= 3` |
    | 7 | `firstShiny` | Any owned dragon has `shiny: true` |
    | 8 | `firstFusion` | Any owned dragon has `fusedBaseStats` not null |
    | 9 | `tundraReturn` | `flags.lastZone === 'tundra'` |

#### Wrench Upgrade System (`forgeData.js:255–259`, `persistence.js:471–479`)

16. The Wrench has three tiers. Tier is stored in `save.skye.wrenchTier` (default `1`); relic slots are stored in `save.skye.relicSlots` (default `1`).

    | Tier | Label | Slots | Upgrade Cost |
    |---|---|---|---|
    | 1 | Standard Issue | 1 | — (starting tier) |
    | 2 | Field Reinforced | 2 | 400 Data Scraps |
    | 3 | Astraeus Core | 4 | 900 Data Scraps |

17. `upgradeWrench(nextTier, nextSlots, cost)` atomically checks `save.dataScraps >= cost`, deducts the cost, sets `save.skye.wrenchTier`, and sets `save.skye.relicSlots`. Returns `false` (and makes no changes) if funds are insufficient (`persistence.js:471–479`).
18. The Anvil overlay always shows the next available tier; once Tier 3 is reached, the upgrade row displays "MAX TIER — Astraeus Core wrench online." (`ForgeOverlays.jsx:112`).

#### Relic System

##### Relic Registry (`forgeData.js:187–251`)

19. Seven relics exist. Each has an `id`, `name`, `icon`, `slotCost` (1 or 2), `mythic` flag, `source` (boss that drops it), and `effect` (human-readable description).

    | ID | Name | Slot Cost | Mythic | Drop Source |
    |---|---|---|---|---|
    | `iron_knuckle` | Iron Knuckle | 1 | No | Recursive Golem (Cooling Intake boss) |
    | `hydra_cog` | Hydra Cog | 1 | No | Glitch Hydra (Tundra boss) |
    | `coolant_core` | Coolant Core | 1 | No | Bit Wraith (Tundra campaign) |
    | `phase_lens` | Phase Lens | 2 | No | Data Corruption (1st Singularity boss) |
    | `twin_forge` | Twin Forge | 2 | No | Memory Leak (2nd Singularity boss) |
    | `resonant_fork` | Resonant Tuning Fork | 1 | No | Stack Overflow (3rd Singularity boss) |
    | `astraeus_engine` | Astraeus Engine | 1 | Yes | Mirror Admin's Sanctum (Act IV) |

##### Relic Drops (`forgeData.js:262–271`)

20. Each NPC/boss has at most one associated relic drop. `grantRelic(relicId)` is idempotent: it pushes `relicId` onto `save.skye.relicsOwned` only if not already present, then saves. A drop is displayed in the victory overlay only when `grantRelic` returns `true` (i.e., newly obtained).

    | NPC/Boss ID | Drops |
    |---|---|
    | `recursive_golem` | `iron_knuckle` |
    | `glitch_hydra` | `hydra_cog` |
    | `bit_wraith` | `coolant_core` |
    | `data_corruption` | `phase_lens` |
    | `memory_leak` | `twin_forge` |
    | `stack_overflow` | `resonant_fork` |
    | `mirror_admin` | `astraeus_engine` |

##### Equip / Unequip Rules (`forgeData.js:279–285`, `persistence.js:503–521`)

21. `canEquipRelic({ relicId, owned, equipped, slots })` returns `true` if and only if all four conditions hold:
    - `relicId` exists in the `RELICS` registry.
    - `relicId` is in `owned`.
    - `relicId` is not already in `equipped`.
    - `getUsedRelicSlots(equipped) + relic.slotCost <= slots`.
22. `getUsedRelicSlots(relicIds)` sums the `slotCost` of all equipped relic IDs; relics not found in the registry contribute `1` by default (`forgeData.js:275–277`).
23. `unequipRelic(relicId)` always succeeds: it filters the relic out of `save.skye.relicsEquipped` and saves. There is no failure path for unequip.
24. In the Anvil overlay, clicking a relic card toggles it: if equipped, it is unequipped; if not equipped, the slot check runs and equip is attempted. If the attempt fails (slot budget exceeded), a `terminalWarning` sound plays and no change is made (`ForgeOverlays.jsx:64–79`).

##### Companion Dragon (`ForgeOverlays.jsx:198–274`)

25. The Hatchery Ring overlay shows all currently owned dragons. Each card is a toggle button that calls `setCompanionDragon(id)`. If the tapped dragon is already the companion, it is cleared to `null`; otherwise it is set to that dragon's ID.
26. Companion bonding requires `getCurrentAct(save) >= 4` (i.e., `save.singularityComplete === true`, `forgeData.js:314–320`). Clicking a dragon card while the feature is locked plays `terminalWarning` and makes no change.
27. Companion selection is stored in `save.skye.companionDragonId`. Its mechanical effect in combat is not implemented in `battleEngine.js` as of this document's verification date — it is a UI-only assignment at present.

#### Captain's Log / Console Overlay (`forgeData.js:291–299`, `ForgeOverlays.jsx:173–196`)

28. Seven Captain's Log fragments exist (`ids '001'–'007'`). Fragment unlock is gated by `FRAGMENT_TRIGGERS` predicates evaluated during `bootstrapForgeSave` on each Forge entry:

    | Fragment | Unlock Condition |
    |---|---|
    | `001` | `flags.metFelix` is truthy (also force-unlocked on first Forge visit) |
    | `002` | `flags.metFelix` is truthy (also force-unlocked on first Forge visit) |
    | `003` | `stats.battlesWon >= 3` |
    | `004` | At least 1 Singularity boss defeated |
    | `005` | At least 2 Singularity bosses defeated |
    | `006` | At least 3 Singularity bosses defeated |
    | `007` | `singularityComplete === true` |

29. The Console overlay shows unlocked fragment bodies; locked fragments display the placeholder body "Recover field signal to decrypt this body." with status "SIGNAL LOCKED".
30. A "OPEN JOURNAL" button at the bottom of the Console overlay navigates to the journal screen without closing via the normal Forge exit path.

---

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|---|---|---|---|
| Free movement | No overlay open | Interact key pressed near station, or Esc pressed | Skye position updates on each key/gamepad event; proximity highlight renders on nearest station |
| Overlay open | Interact key pressed while `nearest` station has an overlay type | Esc / Backspace pressed, or backdrop clicked, or certain overlay-internal buttons trigger `onClose` | Movement input ignored; overlay component renders above scene |
| First-visit | `!save.flags.felixGreeted` at mount | Felix overlay closed after first visit | `bootstrapForgeSave` runs; `isFirstVisitRef` flips false; `flags.felixGreeted` written on first Felix interaction |
| Exiting | Bulkhead interacted or Esc pressed with no overlay | `onNavigate('map')` called | `screenTransition` sound plays; screen unmounts |

---

### Interactions with Other Systems

| System | Direction | Nature |
|---|---|---|
| Battle Engine | Forge → Battle | `getRelicBattleModifiers(save.skye.relicsEquipped)` is called by battle setup to inject relic stat deltas into the combat calculation |
| Persistence (`persistence.js`) | Forge ↔ Persistence | All Forge state mutations (equip/unequip, wrench upgrade, companion set, relic grant, fragment unlock) are performed through persistence helpers; `refreshSave()` re-reads from storage into React state |
| Singularity Progress | Singularity → Forge | `getCurrentAct(save)` reads `singularityComplete` and `getSingularityStage(save)` to determine the act number, which controls the Bulkhead's visual variant and companion bonding availability |
| Hatchery | Forge ↔ Hatchery | Hatchery Ring overlay reads `save.dragons` and navigates to `hatchery` screen; dragon ownership is the source of truth for companion selection candidates |
| Journal / Milestones | Forge → Journal | Console overlay provides a navigation shortcut to the journal screen |
| Sound Engine | Forge → Sound | All interactions fire `playSound` calls: `buttonClick` on interact, `navSwitch` on close, `terminalOk` on successful equip/upgrade, `terminalWarning` on failure, `screenTransition` on exit |
| Lore Canon | loreCanon → Forge | `FELIX_CONTEXT_LINES` and `CAPTAINS_LOG_ARC` are imported from `loreCanon.js`; `forgeData.js` does not own the text content |

---

## Formulas

### Relic Slot Budget Check

```
canEquip = (getUsedRelicSlots(equipped) + relic.slotCost) <= save.skye.relicSlots
```

| Variable | Type | Range | Source | Description |
|---|---|---|---|---|
| `getUsedRelicSlots(equipped)` | integer | 0–8 | calculated | Sum of `slotCost` of all currently equipped relics |
| `relic.slotCost` | integer | 1–2 | `RELICS` registry | Slot cost of the relic being evaluated |
| `save.skye.relicSlots` | integer | 1–4 | save state | Total available slots; set by wrench tier |

**Expected output range**: boolean. Maximum possible used slots at Tier 3 with all 7 relics (but only if all fit): iron_knuckle(1) + hydra_cog(1) + coolant_core(1) + resonant_fork(1) + astraeus_engine(1) + phase_lens(2) + twin_forge(2) = 9 total slot cost across 7 relics vs. 4 available slots. A player with Tier 3 can equip at most 4 slots worth of relics.

### Relic Battle Modifiers (`forgeData.js:343–355`)

```
mods = getRelicBattleModifiers(save.skye.relicsEquipped)
```

This function returns a flat modifier object. Each field is independent; multiple relics do not stack the same field (each relic controls a distinct modifier):

| Output Field | Relic Required | Value When Active | Value When Inactive |
|---|---|---|---|
| `atkBonus` | `iron_knuckle` | `5` (flat ATK added) | `0` |
| `defMultiplier` | `phase_lens` | `1.15` (15% DEF bonus) | `1.0` |
| `spdBonus` | `twin_forge` | `5` (flat SPD added) | `0` |
| `chainHitChance` | `hydra_cog` | `0.20` (20% chance) | `0` |
| `statusDurationBonus` | `coolant_core` | `1` (turns added to ice/storm status) | `0` |
| `autoCleanseTurns` | `resonant_fork` | `3` (cleanse every 3rd turn) | `0` |
| `xpMultiplier` | `astraeus_engine` | `1.15` (15% XP boost) | `1.0` |

**Note**: `chainHitChance = 0.20` triggers a follow-up hit dealing 40% of normal damage (the 40% factor is described in the relic's `effect` string but the probability logic lives in the battle engine, not `forgeData.js`).

### Wrench Upgrade Cost Check

```
canUpgrade = save.dataScraps >= nextTier.cost
```

| Tier Upgrade | Cost | New Slot Count |
|---|---|---|
| T1 → T2 | 400 Data Scraps | 2 |
| T2 → T3 | 900 Data Scraps | 4 |

### Act Derivation (`forgeData.js:314–320`)

```
act = singularityComplete ? 4
    : getSingularityStage(save) >= 3 ? 3
    : getSingularityStage(save) >= 1 ? 2
    : 1
```

This is stateless — `currentAct` is never written to the save; it is derived every render. The act number drives the Bulkhead's visual variant.

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|---|---|---|
| Player has no relics at Forge entry | `bootstrapForgeSave` grants `iron_knuckle` if `relicsOwned.length === 0` | Guarantees the player always has at least one relic to interact with the Anvil |
| `grantRelic` called twice for same relic | Idempotent; second call returns `false` and does not push a duplicate | Victory overlay only shows a drop when `grantRelic` returns `true`, preventing duplicate announcements |
| `unequipRelic` called for a relic not in equipped list | `Array.filter` produces no change; save is written with same array; returns `true` | Safe no-op; no error state |
| Equip attempted with insufficient slots | `canEquipRelic` returns `false`; `terminalWarning` plays; no state change | Prevents over-budget loadout |
| Relic ID not in `RELICS` registry | `getRelic` returns `null`; `canEquipRelic` returns `false` immediately; `getUsedRelicSlots` falls back to slot cost `1` | Guards against stale save data referencing removed relics |
| Player presses Esc with no overlay open | Navigates to map (with `screenTransition` sound) rather than doing nothing | Prevents the Forge from acting as a dead end for keyboard users who cannot reach the Bulkhead |
| `companionDragonId` set to an ID the player no longer owns (fusion consumed it) | The Hatchery Ring overlay renders only `owned` dragons; the companion ID is not cleared automatically — it persists silently until overwritten | Stale companion ID is harmless because companion combat effects are not yet implemented |
| Fragment predicate throws (e.g., old save missing expected fields) | `bootstrapForgeSave` wraps each predicate in a try/catch and skips the fragment silently | Explicit best-effort policy for save migration safety |
| Tier 3 reached (max wrench) | Upgrade row is replaced with "MAX TIER" message; `nextTier` is `undefined` (index out of bounds on `WRENCH_TIERS`) | Array index `WRENCH_TIERS[3]` is `undefined`; the conditional `if (!nextTier)` guards the upgrade button render |

---

## Dependencies

| System | Direction | Nature of Dependency |
|---|---|---|
| `design/gdd/combat.md` | Battle Engine depends on this | Consumes `getRelicBattleModifiers(relicsEquipped)` output to inject ATK/DEF/SPD bonuses and conditional effects into combat resolution |
| `design/gdd/save-and-persistence.md` | This depends on Persistence | All state mutations use persistence helpers; `save.skye.*` is the canonical shape defined in `DEFAULT_SAVE` |
| `design/gdd/singularity-endgame.md` | This depends on Singularity Progress | `getSingularityStage(save)` and `save.singularityComplete` gate act number derivation and companion bonding unlock |
| `design/gdd/economy.md` | This depends on Economy | Wrench upgrades consume Data Scraps from `save.dataScraps`; relic drops are the reward side of the bounty economy |
| `design/gdd/narrative-and-lore.md` | This depends on Lore Canon | `FELIX_CONTEXT_LINES` and `CAPTAINS_LOG_ARC` content is owned by the lore module, not forgeData |
| `design/gdd/hatchery-gacha.md` | Forge depends on Hatchery | Dragon ownership data (`save.dragons`) is the source of truth for Hatchery Ring companion card display |

---

## Tuning Knobs

| Parameter | Current Value | File:Line | Safe Range | Category | Effect of Increase | Effect of Decrease |
|---|---|---|---|---|---|---|
| `FORGE_STEP` | `2` (percentage units per keypress) | `forgeMovement.js:1` | 1–5 | Feel | Skye moves faster; harder to stop precisely at stations | Skye moves slower; more key presses needed to traverse the scene |
| `iron_knuckle` ATK bonus | `5` | `forgeData.js:347` | 0–20 | Feel | More impactful early-game reward | Iron Knuckle becomes the weakest possible option |
| `phase_lens` DEF multiplier | `1.15` | `forgeData.js:348` | 1.0–2.0 | Feel | Greater survivability; may trivialise content | Negligible survivability gain |
| `twin_forge` SPD bonus | `5` | `forgeData.js:349` | 0–20 | Feel | More reliable turn-order advantage | Turn-order advantage negligible |
| `hydra_cog` chain hit chance | `0.20` | `forgeData.js:350` | 0.05–0.50 | Feel | Proc rate feels high; increases DPS variance | Proc rate barely noticeable |
| `hydra_cog` chain hit damage fraction | `0.40` (in effect description; battle engine owns probability application) | `forgeData.js:204` | 0.1–1.0 | Feel | Chain hits close to full damage; reduces incentive for other relics | Chain hits feel like a minor bonus |
| `coolant_core` status duration bonus | `1` (extra turn) | `forgeData.js:351` | 0–3 | Feel | Status strategies become dominant | Status extension negligible |
| `resonant_fork` cleanse interval | `3` (every 3rd turn) | `forgeData.js:352` | 1–10 | Gate | Cleanse so frequent it trivialises status enemies | Cleanse so infrequent it is unreliable |
| `astraeus_engine` XP multiplier | `1.15` | `forgeData.js:353` | 1.0–2.0 | Curve | Faster levelling; reduces grind; mythic relic feels more powerful | XP multiplier barely distinguishable from baseline |
| Wrench T2 cost | `400` Data Scraps | `forgeData.js:257` | 200–800 | Gate | Delays second relic slot; increases mid-game economy pressure | Second slot accessible very early |
| Wrench T3 cost | `900` Data Scraps | `forgeData.js:258` | 500–1500 | Gate | Delays four-slot loadout until late game | Four slots available before Singularity content |
| Hatchery Ring station proximity | `14` | `forgeData.js:37` | 8–20 | Feel | Easier to activate from further away | Must walk closer to the ring |
| Bulkhead station proximity | `8` | `forgeData.js:94` | 5–15 | Feel | Exit activates from a larger area; may fire accidentally | Exit requires precise positioning |
| `FELIX_IDLE_LINES` pool size | `16` | `forgeData.js:103` | N/A | N/A | More lines reduces repetition across a session | — |

---

## Visual / Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|---|---|---|---|
| Skye near a station | Station glows at its defined `glow` colour with CSS pulse animation at `pulseMs` interval | None | High |
| Overlay opens | Overlay panel fades/slides in over scene | `buttonClick` | High |
| Overlay closes | Overlay unmounts | `navSwitch` | High |
| Successful relic equip | Relic card moves from OWNED column to EQUIPPED column | `terminalOk` | High |
| Failed equip (slots full) | No state change; button shows "FULL" | `terminalWarning` | High |
| Successful wrench upgrade | Tier label and slot count update; upgrade row shows next tier or MAX TIER | `terminalOk` | High |
| Failed wrench upgrade (insufficient scraps) | Button shows "NEED N ◈" and is disabled | `terminalWarning` | High |
| Forge exit | Screen transitions to world map | `screenTransition` | High |
| Felix dialogue | Felix overlay displays quoted line | None | Medium |
| New relic granted (first defeat of a boss) | Victory overlay on battle end shows relic name (battle screen owns this) | Owned by battle screen | Medium |

---

## Game Feel

N/A — turn-based browser game. The Forge scene is a point-and-navigate hub with no real-time action. The sections on frame-data, hitbox timing, hit-stop, controller rumble, and animation startup/recovery do not apply.

The relevant feel target is **navigation clarity**: Skye should reach any station in under 10 keystrokes from the spawn position. The `FORGE_STEP = 2` on a 96-unit-wide playfield means approximately 24 steps to cross the full width. Station positions are clustered in the centre-left quadrant (Hatchery Ring at x=30,y=30; Anvil at x=30,y=60; Console at x=55,y=60) and are reachable without precise alignment given their proximity radii (10–14 units).

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|---|---|---|---|
| Current wrench tier + label | Anvil overlay summary row | On overlay open and after each upgrade | Always |
| Used / available relic slots | Anvil overlay summary row | On overlay open and after each equip/unequip/upgrade | Always |
| Current Data Scraps balance | Anvil overlay summary row | On overlay open and after upgrade attempt | Always |
| Upgrade cost and button state | Anvil upgrade row | On overlay open and after each upgrade | When not at max tier |
| Relic cards (icon, name, effect, slot cost) | Anvil relic grid (OWNED and EQUIPPED columns) | On overlay open and after each equip/unequip | When player owns at least one relic |
| "No relics yet" message | Anvil relic grid area | Static | When `relicsOwned.length === 0` |
| Fragment decrypted count (N / total) | Console overlay header | On overlay open | Always |
| Fragment body / locked placeholder | Console log list | On overlay open | Per fragment; depends on `fragmentsUnlocked` |
| Felix quote | Felix overlay | On overlay open | First visit: canonical first-visit line; subsequent: contextual or random |
| Companion badge on dragon card | Hatchery Ring overlay | On overlay open and after each companion toggle | When `companionDragonId` matches the dragon's ID |
| "Companion bonding unlocks in Act IV" message | Hatchery Ring overlay footer | Static when `act < 4` | When companion feature is locked |
| Proximity highlight | Scene: glow + label on nearest station | Every render (React state update on Skye position change) | When `nearest !== null` |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|---|---|---|---|
| Relic modifiers applied in combat | `design/gdd/combat.md` | `getRelicBattleModifiers` output fields (`atkBonus`, `defMultiplier`, `spdBonus`, `chainHitChance`, `statusDurationBonus`, `autoCleanseTurns`, `xpMultiplier`) | Data dependency |
| Act derivation from Singularity state | `design/gdd/singularity-endgame.md` | `getSingularityStage(save)` return value and `save.singularityComplete` flag | Rule dependency |
| Data Scraps as wrench upgrade currency | `design/gdd/economy.md` | `save.dataScraps` balance, `spendScraps` mechanic | Rule dependency |
| Dragon ownership for Hatchery Ring | `design/gdd/hatchery-gacha.md` | `save.dragons[id].owned` flag | Data dependency |
| Felix text content | `design/gdd/narrative-and-lore.md` | `FELIX_CONTEXT_LINES`, `FELIX_IDLE_LINES`, `CAPTAINS_LOG_ARC` | Data dependency |

---

## Acceptance Criteria

- [ ] Skye spawns at position `{ x: 30, y: 75 }` on every Forge entry and cannot move outside `FORGE_BOUNDS` (minX=4, maxX=96, minY=20, maxY=92).
- [ ] All six stations highlight when Skye is within their proximity radius; no station highlights when Skye is outside all radii.
- [ ] Interacting with the Bulkhead navigates to the map immediately; no overlay opens.
- [ ] On first Forge entry: `iron_knuckle` is in `save.skye.relicsOwned`; `flags.metFelix` is `true`; fragments `001` and `002` are in `flags.fragmentsUnlocked`.
- [ ] First interaction with Felix shows the canonical first-visit line exactly once; subsequent interactions show context-aware or random idle lines.
- [ ] Felix contextual lines fire in declared priority order: `mirrorAdminDefeated` line appears when that condition is met, regardless of other conditions also being true.
- [ ] Equipping a relic costs its `slotCost` from the slot budget; the UI updates immediately; `save.skye.relicsEquipped` contains the relic ID after equip.
- [ ] Equipping a relic that would exceed the slot budget plays `terminalWarning` and does not change `save.skye.relicsEquipped`.
- [ ] Unequipping a relic is always successful; `save.skye.relicsEquipped` no longer contains the relic ID after unequip.
- [ ] Wrench upgrade from T1→T2 costs exactly 400 scraps; T2→T3 costs exactly 900 scraps; Data Scraps balance decreases by the correct amount; `relicSlots` updates to 2 and 4 respectively.
- [ ] Wrench upgrade with insufficient scraps plays `terminalWarning` and does not change `wrenchTier`, `relicSlots`, or `dataScraps`.
- [ ] At Wrench Tier 3, the upgrade button is replaced by the "MAX TIER" message.
- [ ] `getRelicBattleModifiers([])` returns all zero/neutral values (`atkBonus=0`, `defMultiplier=1.0`, `spdBonus=0`, `chainHitChance=0`, `statusDurationBonus=0`, `autoCleanseTurns=0`, `xpMultiplier=1.0`).
- [ ] `getRelicBattleModifiers(['iron_knuckle', 'phase_lens'])` returns `atkBonus=5`, `defMultiplier=1.15`, all others at neutral.
- [ ] Captain's Log fragments unlock progressively: fragments `003`–`007` are locked until their respective conditions are met; they unlock on the next Forge entry after the condition becomes true.
- [ ] Companion bonding toggle in Hatchery Ring plays `terminalWarning` (not `terminalOk`) and makes no state change before Act IV.
- [ ] In Act IV, selecting a dragon as companion sets `save.skye.companionDragonId`; selecting the same dragon again clears it to `null`.
- [ ] Pressing Escape with no overlay open navigates to the map; pressing Escape with an overlay open closes the overlay only.
- [ ] The "EXIT TO MAP" button is visible when no overlay is open and hidden when an overlay is open.
- [ ] No relic IDs are hardcoded in `ForgeScreen.jsx` or `ForgeOverlays.jsx` — all relic data flows from `forgeData.js:RELICS`.

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|---|---|---|---|
| Companion dragon mechanical effect in battle | `lead-programmer` / `game-designer` | Before Act IV content ships | `save.skye.companionDragonId` is stored but `battleEngine.js` does not consume it as of 2026-06-16 — combat effect is unimplemented |
| Hydra Cog follow-up hit: damage fraction ownership | `systems-designer` | Next balance pass | Effect description says "40% damage" but the roll and application live in `battleEngine.js`, not `forgeData.js`; confirm the 0.40 factor is correctly implemented there |
| `mythic` flag usage | `game-designer` | Future relic expansion | `astraeus_engine` is flagged `mythic: true`; the UI shows " *" suffix but no gameplay distinction from non-mythic relics currently exists |
