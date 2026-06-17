# ADR-0004: Content lives in data-table modules, separate from logic

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge's game content (dragons, moves, NPCs, bosses, shop items, forge
recipes, milestones, relics, lore) is declared as plain JavaScript data tables in
dedicated content modules (`gameData.js`, `shopItems.js`, `singularityBosses.js`,
`forgeData.js`, `journalMilestones.js`, `loreCanon.js`), kept separate from the
stateful engines that interpret them. This keeps balance and content editable as
data without touching simulation code, and lets every screen and engine import the
same single source of truth.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW |
| **References Consulted** | `src/gameData.js`, `src/shopItems.js`, `src/singularityBosses.js`, `src/forgeData.js`, `src/journalMilestones.js`, `src/loreCanon.js`, `CLAUDE.md` (Architecture / Content-data section) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — pure ES modules, no engine-version-specific APIs |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | The engine/presentation separation (`*Engine.js` consume these tables); save-migration forward-compat (content keys are stable identifiers persisted in the save) |
| **Blocks** | None |
| **Ordering Note** | Foundational. Every gameplay system (battle, hatchery, fusion, shop, singularity, journal) reads these tables, so this pattern should be settled before any engine is authored. |

## Context

### Problem Statement

A dragon-collecting/fusion/battle game is overwhelmingly content: 9 player dragons,
~25 moves, 9 roaming NPCs, 3 Singularity gatekeepers + a multi-phase final boss + a
true-final boss + 3 multi-phase Corruption Remnants, 5 buyable shop items, 4 forge
recipes, 7 relics, 22 milestones, and a 7-fragment lore arc. This content needs
constant balance tuning (stats, power, accuracy, rewards, drop rates) during a long
design-lab phase. If content values are interleaved with the code that interprets
them, every balance change risks a logic regression, content can't be diffed or
reasoned about as a table, and there is no single place to point at when asking
"what are all the dragons?". The decision of where content lives must be made up
front because it dictates how every engine reads its inputs.

### Current State

This ADR documents the shipped state of the deployed browser build, where the
decision is already fully realized:

- **`gameData.js`** — the canonical combat-content table: `ELEMENTS`, `typeChart`
  (8x8 effectiveness matrix), `stageMultipliers`/`stageThresholds`, `moves`
  (keyed move table), `dragons` (keyed roster with `baseStats`, `moveKeys`,
  `stageSprites`), `npcs`, `STATUS_EFFECTS`, `rarityTiers`, plus tuning scalars
  (`PULL_COST`, `SHINY_CHANCE`, `PITY_THRESHOLD`, `STATUS_APPLY_CHANCE`).
- **`shopItems.js`** — `BUY_ITEMS`, `FORGE_RECIPES`, core-drop constants
  (`CORE_DROP_CHANCE`, `CORE_DOUBLE_CHANCE`).
- **`singularityBosses.js`** — `SINGULARITY_BOSSES`, `FINAL_BOSS` (with `phases`),
  `MIRROR_ADMIN` (with `phases` and `phaseLines`), `CORRUPTION_REMNANTS`,
  epilogue line arrays.
- **`forgeData.js`** — Forge layout (`FORGE_STATIONS`), `RELICS`, `WRENCH_TIERS`,
  `RELIC_DROPS`, `FRAGMENT_TRIGGERS`, Felix dialogue tables.
- **`journalMilestones.js`** — the `MILESTONES` achievement table.
- **`loreCanon.js`** — narrative canon constants and `CAPTAINS_LOG_ARC` fragments.

The grep below confirms the table is the shared source of truth: stateful engines
(`battleEngine.js`, `hatcheryEngine.js`, `singularityProgress.js`),
presentation (`battlePresentation.js`, `animationEngine.js`, `VfxOverlay.jsx`),
and ~15 screen components all `import` from these modules; none of them redeclare
content locally.

The pattern is **content-data + co-located pure helpers**, not strictly
"zero functions in content files". Several content modules also export small,
stateless query/derivation helpers that operate purely on the tables and a passed-in
`save` snapshot — e.g. `canForge`/`canAffordBuy`/`getForgeableElement` in
`shopItems.js`, `checkMilestones` in `journalMilestones.js`, and
`getRelicBattleModifiers`/`canEquipRelic`/`pickFelixLine` in `forgeData.js`. These
are read-only over content; they hold no mutable state and never touch
`localStorage`. The mutating, stateful logic (turn resolution, RNG-driven hatch,
progression writes) lives in the separate `*Engine.js` modules. This distinction —
pure derivation may sit with the data, stateful simulation may not — is the
load-bearing nuance of the pattern.

### Constraints

- **Long design-lab phase**: the browser build is the source of truth for balance
  and content (`CLAUDE.md`), so content values change far more often than logic.
- **Two consumers**: data is read by both pure engines (`node` test env, no DOM)
  and React screens; content modules must be plain ES modules with no React or
  browser dependency beyond the `assetUrl` path helper.
- **Save compatibility**: content keys (`'fire'`, `'magma_breath'`, boss `id`s,
  fragment ids `'001'`...) are persisted in the save object and matched by
  `migrateSave`, so identifiers in these tables are part of the save contract and
  cannot be renamed freely.
- **Solo/indie scope**: no time for a content-pipeline tool or external CMS; content
  must be hand-editable in-repo with normal code review and `git diff`.

### Requirements

- Designers/the author can retune any stat, reward, drop rate, or add a new
  dragon/NPC/boss/item/milestone by editing one data file, with no engine change.
- All systems read content from a single declaration (no duplicated stat tables).
- Content is statically importable and tree-shakeable by Vite.
- Content tables are directly testable in the `node` test environment (e.g.
  `battleEngine.test.js` imports `moves`/`typeChart`; `forgeData.test.js` imports
  relic helpers; `journalMilestones.test.js` imports `checkMilestones`).
- Adding content must not require touching `localStorage`/persistence code.

## Decision

Declare all game content as exported plain-data structures in dedicated content
modules, separate from the engines that interpret them. Content modules MAY export
pure, stateless helper functions that derive views over the tables (taking a `save`
snapshot as an argument) but MUST NOT own mutable state, perform persistence, or run
the simulation loop. Engines and screens import the tables; they never redeclare
content.

The canonical shapes:

- **Keyed lookup tables** for entities addressed by stable id: `moves`, `dragons`,
  `npcs`, `STATUS_EFFECTS`, `elementColors`, `RELICS`, `RELIC_DROPS`,
  `FRAGMENT_TRIGGERS`. The object key is the persisted identifier.
- **Ordered arrays** for content consumed in sequence or as a progression chain:
  `SINGULARITY_BOSSES`, `CORRUPTION_REMNANTS`, `MILESTONES`, `BUY_ITEMS`,
  `FORGE_RECIPES`, `rarityTiers`, `CAPTAINS_LOG_ARC`, epilogue line arrays. Chain
  order/gating is expressed in-data via `unlockRequires`.
- **Tuning scalars** as named exported constants (`PULL_COST`, `SHINY_CHANCE`,
  `PITY_THRESHOLD`, `CORE_DROP_CHANCE`, `STATUS_APPLY_CHANCE`, `stageThresholds`).

Content entries reference each other and assets by stable string ids/keys, not by
object reference: dragons list `moveKeys` into the `moves` table; NPCs list
`signatureMoveKey`; bosses chain via `unlockRequires` ids and own `fragmentIds`;
`RELIC_DROPS` maps boss id -> relic id. This indirection is what lets the engine
resolve content at runtime and keeps the save (which stores ids) decoupled from the
table internals.

Where a piece of content is inherently behavioral — an unlock condition or a
context-selection rule — it is expressed as a small **predicate embedded in the data
entry** (data-as-code), evaluated by a generic engine pass: milestone `check(save)`,
Felix `FELIX_CONTEXTUAL[].when(save)`, `FRAGMENT_TRIGGERS['001'](save)`. The engine
iterates and evaluates; it does not hardcode any individual condition.

### Architecture

```
                  CONTENT (data tables — single source of truth)
   gameData.js        shopItems.js       singularityBosses.js
   forgeData.js       journalMilestones.js   loreCanon.js
        |  (export plain objects/arrays/scalars + pure derive helpers)
        |  entries cross-reference by stable id (moveKeys, unlockRequires, RELIC_DROPS)
        v
   ----------------------------- import ------------------------------
        |                              |                         |
        v                              v                         v
   STATEFUL ENGINES            PURE DERIVE HELPERS         PRESENTATION + UI
   battleEngine.js             (co-located w/ data)        battlePresentation.js
   hatcheryEngine.js           canForge(recipe, save)      animationEngine.js
   singularityProgress.js      checkMilestones(save)       VfxOverlay.jsx
   (read tables, hold the      getRelicBattleModifiers()   BattleScreen.jsx + ~15
    sim state, mutate save)    getBossStatus(boss, save)   other *Screen.jsx
        |
        v
   persistence.js  <-- save stores content *ids*; migrateSave keeps them forward-compat
```

Data flow is one-directional: content is read-only input. State lives in the `save`
object and in engine locals; content modules never import an engine, persistence, or
React, so the dependency graph has no cycle from content back to logic.

### Key Interfaces

```
// gameData.js — keyed combat tables (move key is the contract used by dragons/npcs)
moves[moveKey] = { name, element, power, accuracy, vfxKey, canApplyStatus,
                   canCharge?, chargeChance?, actionType?, buffStat?, isReflect? }
dragons[id]    = { id, name, element, baseStats:{hp,atk,def,spd}, moveKeys[],
                   stageSprites:{1..4}, facesLeft? }
npcs[id]       = { id, name, element, level, stats, moveKeys[], signatureMoveKey?,
                   signatureCondition?, baseXP, scrapsReward, ...sprites }
typeChart[attacker][defender] = multiplier   // 8x8 effectiveness matrix

// singularityBosses.js — ordered, gated chain; bosses may carry phase arrays
SINGULARITY_BOSSES[] = { id, ...stats, unlockRequires: <bossId|null>, fragmentIds[] }
FINAL_BOSS / MIRROR_ADMIN = { id, phases:[{name,element,level,stats,moveKeys}], phaseLines? }
getBossStatus(boss, save) -> 'locked' | 'available' | 'defeated'   // pure derive

// content-with-embedded-predicate (data-as-code)
MILESTONES[] = { id, name, reward, check(save) -> { met, progress } }
FELIX_CONTEXTUAL[] = { id, when(save) -> bool, line }
FRAGMENT_TRIGGERS[fragmentId] = (save) -> bool

// pure derive helpers co-located with their tables (read-only over content + save)
canForge(recipe, save) / canAffordBuy(item, save)            // shopItems.js
checkMilestones(save) -> [{ ...milestone, claimed, newlyClaimed, progress }]  // journalMilestones.js
getRelicBattleModifiers(relicIds[]) -> { atkBonus, defMultiplier, ... }       // forgeData.js
```

### Implementation Guidelines

- **Adding content = editing a table.** New dragon -> add a `dragons[id]` entry +
  its `moveKeys`. New boss -> append to `SINGULARITY_BOSSES`/`CORRUPTION_REMNANTS`
  with `unlockRequires`. New shop item -> append to `BUY_ITEMS` + handle its
  `effect` string in the consuming screen. New milestone -> append to `MILESTONES`
  with a `check`. Do not add content by branching inside an engine.
- **Reference by id, never by import-and-inline.** Cross-links go through stable
  keys (`moveKeys`, `signatureMoveKey`, `unlockRequires`, `RELIC_DROPS`) so the
  save and the engine resolve at runtime.
- **Stable ids are a save contract.** Object keys and `id`/fragment-id strings are
  persisted; renaming one requires a `migrateSave` step. Prefer adding over renaming.
- **Keep helpers pure.** A function may live in a content module only if it is a
  read-only derivation over the tables and an optional `save` argument. Anything
  that mutates `save`, calls `localStorage`, owns RNG state across calls, or runs a
  turn loop belongs in an `*Engine.js`.
- **No React / no DOM in content.** The only allowed non-data dependency is
  `assetUrl` for path resolution, so content stays importable in the `node` test env.
- **Embedded predicates must be total and defensive.** `check`/`when` receive a raw
  `save` that may predate the content; guard with optional chaining and defaults
  (the existing tables do, e.g. `save.inventory?.cores || {}`).

## Alternatives Considered

### Alternative 1: Content interleaved with engine logic

- **Description**: Define stats, moves, and boss behavior inline inside
  `battleEngine.js` / screen components (e.g. `switch (dragonId)` blocks, hardcoded
  stat literals at use sites).
- **Pros**: Fewer files; behavior and its data sit together; no id-indirection to
  follow.
- **Cons**: Every balance tweak is a logic edit with regression risk; no single
  "what are all the dragons?" view; content can't be tested or diffed as a table;
  duplication across the ~15 screens that need dragon/element data.
- **Estimated Effort**: Lower up front, much higher over the long balance-tuning
  phase.
- **Rejection Reason**: The game is content-dominated and tuned constantly;
  coupling content to logic would make the most frequent change (balance) the most
  dangerous one.

### Alternative 2: External content files (JSON / YAML) loaded at runtime

- **Description**: Move tables out of JS into `.json`/`.yaml` assets fetched or
  imported at load; engines parse them into the same shapes.
- **Pros**: Truly data-only (no functions can sneak in); potentially editable by
  non-programmers or external tooling; clean data/code wall.
- **Cons**: Loses embedded predicates (`check`/`when`/`unlockRequires` evaluators)
  which are genuinely behavioral and currently live cleanly as functions; needs a
  loader + schema validation; no static import-time tree-shaking or type-adjacent
  editor help; adds a runtime fetch/parse step and a failure mode.
- **Estimated Effort**: Higher — requires a loader, validation, and re-homing the
  predicate logic elsewhere.
- **Rejection Reason**: For a solo build, ES-module data tables give 90% of the
  data/logic separation with zero pipeline, and keep data-as-code predicates
  expressible. JSON's purity isn't worth the lost ergonomics and the orphaned
  predicate logic.

### Alternative 3: A central content registry / database object

- **Description**: One aggregate module (or runtime registry class) that holds and
  serves all content through a query API, instead of many topic-scoped modules.
- **Pros**: Single import surface; one place to add cross-cutting indexing/validation.
- **Cons**: Becomes a god-module that everything depends on (worse tree-shaking,
  bigger blast radius on edit); obscures topic ownership; a registry implies
  lookup logic, blurring the data/logic line this ADR is drawing.
- **Estimated Effort**: Comparable, with worse modularity.
- **Rejection Reason**: Topic-scoped data modules already give a single source of
  truth per domain with clean, narrow imports; a central registry adds coupling
  without solving a real problem at this scale.

## Consequences

### Positive

- Balance and content are edited as plain data in one file each; the most frequent
  change (tuning) carries the least logic-regression risk.
- One source of truth per domain — ~15 screens and all engines import the same
  `dragons`/`npcs`/`moves` tables; no duplicated stat blocks.
- Content tables are directly unit-testable in the `node` env without DOM/mocks.
- Id-indirection (moveKeys, `unlockRequires`, `RELIC_DROPS`) keeps content
  decoupled from the save and lets `migrateSave` evolve the schema independently.
- New content (dragon, boss, item, milestone) is additive — append an entry, no
  engine surgery — which suits a long content-growth phase.

### Negative

- Stable ids are a hidden contract: renaming a key silently breaks saves unless a
  migration is written. The coupling is real but invisible at the edit site.
- Data-as-code predicates (`check`, `when`, `FRAGMENT_TRIGGERS`) mean some behavior
  lives in "content" files; the data/logic wall is a convention (pure-derive-only),
  not enforced by the file type. A future contributor could smuggle stateful logic
  in.
- No schema validation: a malformed entry (missing `moveKeys`, bad `element`) fails
  only at runtime/in tests, not at edit time.
- Some content references (a `moveKey` that doesn't exist, an `unlockRequires`
  pointing at a removed boss) are not statically checked.

### Neutral

- Content is JS, not a neutral data format, so it can't be consumed by non-JS
  tooling without a serialization step. Acceptable for a JS-only browser build.
- The Godot runtime re-implements the same content as GDScript tables in
  `dragon-forge-godot/scripts/sim/`; the two builds share the *pattern* and the art,
  not the literal files. Keeping them in sync is a manual, cross-build concern.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Renaming a content id breaks existing saves | Medium | High | Treat ids as a save contract; add over rename; route renames through `migrateSave`; keep an id allow-list test |
| Stateful logic creeps into content modules over time | Medium | Medium | Convention documented here ("pure-derive-only"); enforce in review; engines remain the home for mutation/RNG/persistence |
| Dangling reference (moveKey/unlockRequires/RELIC_DROPS to a removed entry) | Medium | Medium | `assetManifest.test.js` already validates sprite refs; add a referential-integrity test over moveKeys/boss chains |
| Malformed content entry ships (missing field) | Low | Medium | Engine tests exercise representative entries; consider a lightweight shape assertion per table |
| Web and Godot content tables drift apart | Medium | Medium | Browser build is declared source of truth (`CLAUDE.md`); port deltas deliberately; smoke-test Godot sim after content changes |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible — tables are static objects, looked up by key; no per-frame parsing | < 16.6ms/frame (60fps) |
| Memory | n/a | A few KB of static data resident for the session | Negligible |
| Load Time | n/a | Statically imported and tree-shaken into the bundle; no runtime fetch/parse | No measurable add to initial load |
| Network (if applicable) | n/a | None — content is bundled, not fetched | 0 KB extra |

The choice of ES-module tables over runtime-loaded JSON specifically avoids a
fetch/parse cost and keeps content tree-shakeable by Vite.

## Migration Plan

Not applicable — this ADR documents an already-shipped pattern, not a change. The
guidance below applies to *future* content edits that touch identifiers:

1. **Adding content**: append an entry/constant to the relevant table. No migration
   needed; verify with the system's test (`battleEngine.test.js`, `forgeData.test.js`,
   `journalMilestones.test.js`) and `npm run playtest:smoke`.
2. **Renaming/removing a content id that may be persisted**: add a `migrateSave`
   step in `persistence.js` mapping old id -> new (or pruning it), then update all
   cross-references (moveKeys, `unlockRequires`, `RELIC_DROPS`). Verify a save from
   before the change still loads.
3. **Promoting a content helper to an engine**: if a co-located helper needs mutable
   state or persistence, move it into the relevant `*Engine.js`; keep the content
   module pure.

**Rollback plan**: Content edits are ordinary reversible commits — `git revert` the
table change. Because content is data with no schema/runtime coupling beyond
persisted ids, reverting a non-id content change is safe; reverting an id change
requires the matching `migrateSave` revert.

## Validation Criteria

- [x] All gameplay systems import content from these six modules; no engine or
      screen redeclares dragon/move/NPC/boss/item/milestone data (confirmed via
      import grep).
- [x] Content modules carry no mutable state and do not import engines, persistence,
      or React (only `assetUrl`); they are importable in the `node` test env.
- [x] Engines and tests consume the tables directly (e.g. `battleEngine.js` imports
      `typeChart`/`moves`; `journalMilestones.test.js` imports `checkMilestones`).
- [ ] A balance change (e.g. a move `power` or boss `stats` tweak) requires editing
      only a content file, with no `*Engine.js` diff — spot-checked per change.
- [ ] Referential-integrity test exists covering moveKeys, `unlockRequires` chains,
      and `RELIC_DROPS` ids (recommended follow-up).

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/combat.md` | Combat | Dragons, moves, NPCs, type effectiveness, status effects, and stage scaling must be defined as tunable data the combat resolver reads | `gameData.js` declares `dragons`, `moves`, `npcs`, `typeChart`, `STATUS_EFFECTS`, `stageMultipliers`/`stageThresholds` as plain tables consumed by `battleEngine.js`; balance is editable without touching the resolver |
| `design/gdd/shop-and-crafting.md` | Shop & Crafting | Buyable items, forge recipes (core requirements + scraps cost), and drop rates must be data-defined and economy-tunable | `shopItems.js` declares `BUY_ITEMS`, `FORGE_RECIPES`, and `CORE_DROP_CHANCE`/`CORE_DOUBLE_CHANCE`; pure `canAffordBuy`/`canForge` derive availability from the tables + save |
| `design/gdd/singularity-endgame.md` | Singularity / Endgame | The endgame boss chain (gatekeepers, multi-phase final boss, true-final, remnants) and its fragment gating must be authored as a gated, ordered data chain | `singularityBosses.js` declares the chain with `unlockRequires` gating, `phases`, and `fragmentIds`; `getBossStatus(boss, save)` derives lock/available/defeated purely from save state |
| `design/gdd/journal-milestones.md` | Journal / Milestones | Achievement milestones with progress and rewards must be data-driven and evaluated against save state | `journalMilestones.js` declares `MILESTONES` with embedded `check(save)` predicates; `checkMilestones(save)` evaluates them generically |
| `design/gdd/forge-skye.md` | Forge / Skye | Relics, wrench tiers, drop mapping, Forge stations, and Felix dialogue must be content-defined | `forgeData.js` declares `RELICS`, `WRENCH_TIERS`, `RELIC_DROPS`, `FORGE_STATIONS`, and Felix dialogue tables; `getRelicBattleModifiers` derives combat bonuses purely from equipped relic ids |
| `design/gdd/narrative-and-lore.md` | Narrative / Lore | Canon, opening sequence, and the Captain's Log fragment arc must be authored as content the UI and triggers read | `loreCanon.js` declares canon constants, `OPENING_BOOT_LINES`/`OPENING_FELIX_LINES`, and `CAPTAINS_LOG_ARC`; `forgeData.js` `FRAGMENT_TRIGGERS` gate fragments via pure save predicates |

> Note: `design/gdd/combat.md` is being authored in parallel and is referenced by
> path; the other GDD documents listed exist under `design/gdd/`.

## Related

- ADR (engine vs. presentation separation) — the `*Engine.js` / `*Screen.jsx` split
  is the consumer side of this pattern; these data tables are its shared inputs.
- ADR (save state / `migrateSave` forward-compat) — content ids declared here are
  the persisted identifiers that the save schema and migration depend on.
- Code: `src/gameData.js`, `src/shopItems.js`, `src/singularityBosses.js`,
  `src/forgeData.js`, `src/journalMilestones.js`, `src/loreCanon.js`
- Consumers (evidence): `src/battleEngine.js`, `src/hatcheryEngine.js`,
  `src/singularityProgress.js`, `src/battlePresentation.js`, `src/BattleScreen.jsx`,
  `src/ShopScreen.jsx`, `src/SingularityScreen.jsx`, `src/JournalScreen.jsx`
- Tests (evidence): `src/battleEngine.test.js`, `src/forgeData.test.js`,
  `src/journalMilestones.test.js`, `src/assetManifest.test.js`
