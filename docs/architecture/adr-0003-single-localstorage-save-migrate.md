# ADR-0003: Single localStorage Save Object with `migrateSave` Forward-Compat; No External State Library

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge persists all player progress as a single JSON object under one
localStorage key (`dragonforge_save`), with a hand-written `migrateSave` function
that idempotently backfills missing fields on every load. The browser build owns
no Redux/Zustand/Context store: `App.jsx` holds the save in one `useState`, every
mutation goes through a `persistence.js` helper (load → mutate → write), and
screens call `refreshSave()` to re-read from storage and re-render.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build) |
| **Domain** | Core / Persistence / State Management |
| **Knowledge Risk** | LOW — React 18 + Web Storage API are well within training data |
| **References Consulted** | `src/persistence.js`, `src/App.jsx` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | Every stateful gameplay system (collection, economy, progression, milestones, Singularity, Forge/Skye, NG+) reads/writes through this contract |
| **Blocks** | None |
| **Ordering Note** | Foundational. The `DEFAULT_SAVE` shape in `persistence.js` is the authoritative schema; any new persistent system must extend it here and add a matching `migrateSave` backfill in the same change. |

## Context

### Problem Statement

Dragon Forge is a single-player, client-only collection/fusion/battle game with no
backend. Player progress — owned/discovered dragons, currency (data scraps),
gacha pity, milestones, campaign and Singularity completion, the Forge/Skye relic
loadout, records, daily streak, and NG+ tier — must survive page reloads and
browser sessions. Because the game ships continuously and adds new systems over
time (void/light/synthesis dragons, the Singularity arc, Skye/relics, remnants,
NG+ were all added after launch), saves written by older builds must keep loading
in newer builds without wiping the player's collection. The decision is how to
store, shape, and evolve that state.

### Current State

The browser build is feature-complete and deployed. State is implemented exactly
as described in this ADR:

- `src/persistence.js` defines `DEFAULT_SAVE` (the schema), `migrateSave` (the
  forward-compat layer), `loadSave`/`writeSave` (the storage boundary), and ~40
  typed mutator helpers (`addScraps`, `unlockDragon`, `fuseDragons`,
  `recordSingularityDefeat`, `equipRelic`, `applyNewGamePlus`, etc.).
- `src/App.jsx` holds the entire save in a single `useState(() => loadSave())`,
  passes it to every screen as a `save` prop, and exposes `refreshSave()` to
  re-read after a mutation.

There is nothing "wrong" with the current approach — this ADR documents a
deliberate, working decision so future systems extend it consistently rather than
introducing a parallel store or schema.

### Constraints

- **No backend / client-only**: there is no server to own canonical state or run
  migrations; everything happens in the browser.
- **Web Storage limits**: localStorage is synchronous, string-only, and ~5 MB per
  origin — the save must serialize to compact JSON and stay small.
- **Continuous shipping**: new builds deploy over existing players' saves; a
  returning player must never lose their collection because their save predates a
  field.
- **Solo / indie scope**: state plumbing must be understandable and debuggable by
  one developer six months later, with no framework ceremony.
- **Pure-engine testability**: engine modules (`battleEngine`, `fusionEngine`,
  etc.) are tested in a Node environment with no DOM, so persistence logic that
  needs to be unit-tested must be expressible as pure functions.

### Requirements

- A single, authoritative schema for all player progress.
- Loads of older saves must succeed and silently upgrade to the current schema.
- A corrupt or absent save must degrade to a fresh `DEFAULT_SAVE`, never a crash.
- Every XP/currency/collection mutation must be funneled through one place so the
  rules (level cap, "discovered" never regresses, currency floors) are enforced
  uniformly regardless of which screen triggered them.
- State changes must propagate to the React tree to re-render the active screen.

## Decision

Persist **one** save object as JSON under the single localStorage key
`dragonforge_save`. `persistence.js` is the only module that touches
`localStorage`, and it exposes the full surface:

1. **`DEFAULT_SAVE`** is the canonical schema and the fresh-game value.
2. **`migrateSave(save)`** is an idempotent, additive forward-compat pass run on
   every load: for each field, `if (save.x === undefined) save.x = <default>`. It
   never deletes fields and is safe to run repeatedly. It also performs a few
   **semantic** backfills (not just structural defaults) — e.g. inferring
   `discovered` from past ownership signals, repairing collection regressions from
   pre-`discovered` fusion saves via `fusionLineage`, retroactively granting the
   `full_roster` milestone to saves that met the old threshold, and granting the
   Light Dragon to players who already finished the Singularity.
3. **`loadSave()`** reads the key, returns a `structuredClone(DEFAULT_SAVE)` if
   absent, parses + migrates if present, and returns a fresh clone on any
   parse/throw (corrupt save never crashes the game).
4. **`writeSave(save)`** is the single `localStorage.setItem` call.
5. **Mutator helpers** all follow the same transaction shape:
   `const save = loadSave(); /* mutate */; writeSave(save);` — read-modify-write
   against storage, returning a boolean/object when the caller needs the outcome
   (e.g. `spendScraps` returns `false` on insufficient funds; `fuseDragons`
   returns the new save or `null`).

State management uses **React's built-in `useState` only — no Redux, Zustand,
Jotai, MobX, or Context provider.** `App.jsx` holds the save in one state cell;
screens receive it as the `save` prop and call the `refreshSave()` callback after
any mutation to re-read storage into state and trigger a re-render.

### Architecture

```
                    ┌─────────────────────────────────────────┐
                    │            localStorage                  │
                    │   key: "dragonforge_save"  (JSON string) │
                    └───────────────▲───────────┬──────────────┘
                          writeSave  │           │ getItem
                                     │           ▼
            ┌────────────────────────┴───────────────────────────┐
            │                    persistence.js                   │
            │  DEFAULT_SAVE (schema)   migrateSave (forward-compat)│
            │  loadSave()  writeSave()                             │
            │  mutators: addScraps, unlockDragon, fuseDragons,    │
            │            equipRelic, applyNewGamePlus, ... (~40)   │
            └──────▲───────────────────────────────┬──────────────┘
            mutate │                                │ loadSave()
                   │                                ▼
       ┌───────────┴──────────┐         ┌──────────────────────────┐
       │  Screen components    │  save   │   App.jsx                 │
       │  (Hatchery, Fusion,   │ ◄────── │  useState(loadSave())     │
       │   Shop, Battle, ...)  │         │  refreshSave() ──► setSave│
       │  call mutator(...)    │ ──────► │  passes `save` + callback │
       │  then refreshSave()   │ refresh │  to every screen          │
       └──────────────────────┘         └──────────────────────────┘
```

Data flow for a mutation (e.g. buying an XP boost in the Shop):

```
ShopScreen → setXpBoost(n)            // persistence.js: loadSave → mutate → writeSave
ShopScreen → refreshSave()            // App.jsx: loadSave() again → setSave(newSave)
App re-renders → Shop sees new `save` prop
```

### Key Interfaces

```js
// persistence.js — the storage contract

const STORAGE_KEY = 'dragonforge_save';
const DEFAULT_SAVE = { /* authoritative schema: dragons, dataScraps, milestones,
                          singularityProgress, inventory, stats, flags, skye, ... */ };

function migrateSave(save)            // idempotent additive backfill; mutates + returns save
export function loadSave()            // → migrated save | structuredClone(DEFAULT_SAVE)
export function writeSave(save)       // localStorage.setItem(STORAGE_KEY, JSON.stringify(save))

// Mutator transaction shape (all helpers follow this):
export function someMutation(args) {
  const save = loadSave();
  /* mutate save */
  writeSave(save);
  return /* boolean | object when the caller needs the outcome */;
}

// Pure, testable reset/transform helpers (no storage access):
export function applyDragonXp(dragon, amount)   // canonical XP→level curve, caps at 50
export function applyNewGamePlus(save)          // re-locks campaign, keeps collection
export function getReplayReward(clearCount)     // deterministic, unit-tested
```

```jsx
// App.jsx — the React state contract

const [save, setSave] = useState(() => loadSave());
function refreshSave() {
  const newSave = loadSave();
  /* milestone-ready toast diffing */
  setSave(newSave);
}
// Every screen receives: <Screen save={save} refreshSave={refreshSave} ... />
```

### Implementation Guidelines

- **One key, one object.** Do not introduce additional localStorage keys for game
  state. If a new system needs persistence, add its slice to `DEFAULT_SAVE` and a
  matching `migrateSave` backfill **in the same change**.
- **All storage access goes through `persistence.js`.** No component should call
  `localStorage` directly. Add a typed mutator helper instead.
- **Mutators are read-modify-write.** Always `loadSave()` at the top of a mutator
  rather than trusting an in-memory copy — this is the source of truth and avoids
  lost updates between screens.
- **`migrateSave` must stay idempotent and additive.** Use the
  `if (save.x === undefined) save.x = default` pattern. Never remove a field a
  shipped save might depend on; deprecate by leaving it dormant.
- **Prefer pure transforms for testable rules.** Logic with interesting semantics
  (XP curve, NG+ reset, replay rewards) is factored into pure functions
  (`applyDragonXp`, `applyNewGamePlus`, `getReplayReward`) so it can be unit-tested
  without a DOM, then wrapped by a thin storage-touching helper.
- **After any mutation from a screen, call `refreshSave()`** so the React tree
  re-reads storage and re-renders. Do not mutate the `save` prop in place.
- **Never let a bad save crash the game.** Keep the try/catch in `loadSave()` that
  falls back to a fresh clone of `DEFAULT_SAVE`.

## Alternatives Considered

### Alternative 1: External state library (Redux / Zustand / Jotai) as the store of record

- **Description**: Hold game state in a dedicated store, with localStorage
  persistence handled by middleware (e.g. `redux-persist` or Zustand's `persist`
  middleware), and components subscribing to slices.
- **Pros**: Fine-grained subscriptions (fewer re-renders), devtools time-travel,
  established migration hooks, decoupled from `App.jsx`.
- **Cons**: Adds a dependency and conceptual surface for a solo dev; the game's
  state-change cadence is coarse (screen transitions, battle ends, purchases), so
  whole-tree re-render is a non-issue; persist middleware still requires
  hand-written migrations, so it buys little over `migrateSave`.
- **Estimated Effort**: Higher — new dependency, store wiring, slice definitions,
  migration config.
- **Rejection Reason**: The performance and ergonomics benefits don't pay for the
  added complexity at this game's scale; React `useState` + one save object is the
  simplest thing that meets every requirement (Simplicity, Maintainability).

### Alternative 2: Multiple localStorage keys (one per system)

- **Description**: Store `df_dragons`, `df_economy`, `df_skye`, etc. as separate
  keys, each loaded/migrated independently.
- **Pros**: Smaller individual writes; a corrupt slice only loses one system.
- **Cons**: Cross-system invariants (e.g. fusion consumes scraps **and** mutates
  two dragons **and** appends `fusionLineage`) become multi-key transactions that
  can tear if a write fails mid-way; migration logic is scattered; there is no
  single schema to reason about; export/import of a save becomes multi-key.
- **Estimated Effort**: Comparable, but higher ongoing coordination cost.
- **Rejection Reason**: Many of the game's mutations are inherently
  cross-cutting; a single atomic JSON write keeps those invariants trivially
  consistent (Correctness, Simplicity).

### Alternative 3: Versioned save with an explicit `schemaVersion` + numbered migration steps

- **Description**: Tag the save with `schemaVersion: N` and run an ordered list of
  migration functions (`v1→v2`, `v2→v3`, …) on load.
- **Pros**: Explicit, auditable migration history; can perform destructive or
  reshaping migrations that the additive `undefined`-check pattern can't.
- **Cons**: More ceremony (version bookkeeping, ordered migration registry); the
  additive `if (x === undefined)` approach already covers every migration the game
  has needed so far without ever needing to delete or reshape a field.
- **Estimated Effort**: Higher upfront and per-migration.
- **Rejection Reason**: Over-engineered for the migrations actually required, which
  are all additive backfills. This remains the natural upgrade path **if** a future
  change ever needs a destructive/reshaping migration (Reversibility — the door is
  open without paying the cost now).

### Alternative 4: IndexedDB

- **Description**: Use IndexedDB for structured, async, higher-capacity storage.
- **Pros**: Larger quota, structured records, async (non-blocking) I/O.
- **Cons**: Async API complicates the synchronous read-modify-write mutator
  pattern; far more boilerplate; the save is tiny (well under the localStorage
  cap), so none of the capacity benefits apply.
- **Estimated Effort**: Higher.
- **Rejection Reason**: Solves problems this game does not have; localStorage's
  synchronous simplicity is a feature here (Simplicity, Correctness).

## Consequences

### Positive

- **One source of truth.** `DEFAULT_SAVE` is the whole schema; anyone can read one
  object literal and understand all persistent state.
- **Old saves keep working.** `migrateSave` has absorbed every post-launch system
  (new dragons, Singularity, Skye/relics, remnants, NG+) without wiping players.
- **Atomic, consistent writes.** Cross-system mutations (fusion, NG+) are a single
  JSON write, so invariants can't tear.
- **Crash-proof loading.** Corrupt/absent saves fall back to a fresh game.
- **Uniform rules.** Funneling every mutation through `persistence.js` means the
  level cap, "discovered never regresses," and currency floors are enforced in one
  place regardless of caller.
- **Testable core.** Pure transforms (`applyDragonXp`, `applyNewGamePlus`,
  `getReplayReward`) are unit-tested in the Node test env with no DOM.
- **Zero state dependencies.** No library to learn, version, or audit.

### Negative

- **Whole-save re-read per mutation.** `refreshSave()` re-parses the entire save
  from localStorage; fine at this scale, but not free if the save grew large.
- **Coarse re-renders.** Updating one field replaces the whole `save` and re-renders
  the active screen; acceptable given the screen-switch cadence.
- **`migrateSave` only grows.** Additive backfills accumulate; it can never delete
  the migration for a field a shipped save might still carry, so the function
  trends longer over time.
- **No schema enforcement.** The save shape is a plain object literal with no
  runtime validation (e.g. no zod/TypeScript), so a typo in a mutator can write a
  malformed field that `migrateSave` won't catch.
- **Manual discipline required.** New systems must remember to extend both
  `DEFAULT_SAVE` and `migrateSave` together; nothing enforces this.

### Neutral

- State lives in `App.jsx` rather than a separate store module — intentional given
  the single-screen-at-a-time architecture.
- Read-modify-write mutators always hit storage rather than trusting an in-memory
  copy; slightly redundant but eliminates lost-update bugs across screens.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| New system added to `DEFAULT_SAVE` without a matching `migrateSave` backfill, so old saves load with `undefined` slices | Medium | Medium | Implementation guideline mandates both in the same change; code review checks the pair |
| A future change needs a destructive/reshaping migration the additive pattern can't express | Low | Medium | Alternative 3 (explicit `schemaVersion` + ordered migrations) is the documented upgrade path; introduce it only when first needed |
| Save grows large enough that per-mutation full re-read/re-parse becomes noticeable | Low | Low | Save is small; if it grows, batch reads or move to an in-memory authoritative copy with periodic flush |
| Malformed write from a buggy mutator persists silently (no schema validation) | Low | Medium | Keep mutations in `persistence.js`; consider a runtime schema check on write if mutators proliferate |
| localStorage cleared/blocked by browser (private mode, user wipe) loses progress | Low | High (player) | `loadSave()` degrades to fresh game without crashing; an export/import-save feature would mitigate data-loss (not currently implemented) |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | Negligible — JSON parse/stringify of a small save on mutation/nav only, never per-frame | < 16.6 ms/frame (60 fps); persistence does not run in the render loop |
| Memory | n/a | One save object (a few KB) held in `useState` | Trivial vs. browser heap |
| Load Time | n/a | One synchronous `getItem` + parse + `migrateSave` pass at boot | < 50 ms at boot |
| Network (if applicable) | n/a | None — client-only, no backend | 0 |

## Migration Plan

This ADR documents an already-shipped decision; no migration is required. The
"migration" is the runtime `migrateSave` behaviour itself, which executes on every
load:

1. On `loadSave()`, read `dragonforge_save`. Absent → fresh `DEFAULT_SAVE` clone.
2. Present → `JSON.parse`, then `migrateSave` backfills every missing field and
   runs semantic repairs (discovered inference, fusion-lineage repair, retroactive
   `full_roster`, Light Dragon grant for Singularity finishers).
3. Parse/throw at any point → fresh `DEFAULT_SAVE` clone (no crash).

**Rollback plan**: Adopting an external state library or splitting keys later would
be a fresh ADR superseding this one. Because all storage access is already
isolated in `persistence.js`, a future store would wrap `loadSave`/`writeSave`
rather than rewriting every call site — the blast radius of reversing this
decision is contained to one module.

## Validation Criteria

- [x] All player progress survives reload via a single `dragonforge_save` key.
- [x] A save written by a pre-void/light/synthesis, pre-Singularity, pre-Skye build
      loads in the current build without losing the existing collection
      (`migrateSave` backfills + semantic repairs).
- [x] A corrupt or absent save yields a fresh game instead of a crash
      (`loadSave` try/catch → `structuredClone(DEFAULT_SAVE)`).
- [x] No external state-management dependency is present in `package.json`.
- [x] Every persistent mutation routes through a `persistence.js` helper rather
      than touching `localStorage` directly.
- [x] Pure persistence transforms are unit-testable without a DOM
      (`applyDragonXp`, `applyNewGamePlus`, `getReplayReward`).

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/save-and-persistence.md` | Save & Persistence | Player progress must persist across sessions and survive build updates without data loss | Single `dragonforge_save` localStorage object + idempotent additive `migrateSave` forward-compat layer in `src/persistence.js` |
| `design/gdd/dragon-progression.md` | Dragon Progression | Dragons level the same regardless of XP source, capped at level 50 | `applyDragonXp` is the single canonical XP→level curve all sources funnel through; persisted on the per-dragon save slice |
| `design/gdd/economy.md` | Economy | Data scraps and cores are spent/earned consistently with floors and caps | `addScraps`/`spendScraps`/`addCore`/`spendCores` enforce floors (`return false` on insufficient funds) and caps (cores clamp to 99) over the single save object |
| `design/gdd/journal-milestones.md` | Journal & Milestones | Collection-count milestones must never regress when fusion consumes a dragon | `discovered` codex flag is permanent in the schema; `migrateSave` repairs pre-`discovered` saves via `fusionLineage` and retroactively grants `full_roster` |
| `design/gdd/fusion.md` | Fusion | Fusion atomically consumes two parents, produces offspring, spends currency, and records lineage | `fuseDragons` performs the whole transaction in one read-modify-write against the single save object |
| `design/gdd/singularity-endgame.md` | Singularity Endgame | Endgame progress, replay rewards, and the New Game+ reset must persist while keeping the collection | `singularityProgress`, `remnantDefeated`, NG+ (`applyNewGamePlus`) live in the save; NG+ re-locks the campaign while preserving dragons/scraps/cores/milestones |
| `design/gdd/forge-skye.md` | Forge / Skye | Relic loadout, wrench tier, and companion selection must persist and respect slot rules | The `skye` save slice plus `upgradeWrench`/`grantRelic`/`equipRelic` (slot-validated via `canEquipRelic`) |

> If this is a foundational decision with no direct GDD dependency, write:
> "Foundational — no GDD requirement. Enables: [list what GDD systems this
> decision unlocks or constrains]"

## Related

- Code: `src/persistence.js` (`DEFAULT_SAVE`, `migrateSave`, `loadSave`/`writeSave`,
  all mutators), `src/App.jsx` (`useState(loadSave())`, `refreshSave()`,
  `save`-prop fan-out to every screen).
- GDD (authored in parallel): `design/gdd/save-and-persistence.md` and the
  per-system GDDs listed above, all of which depend on this persistence contract.
- This is a foundational ADR; gameplay-system ADRs that introduce new persistent
  state should reference it as the schema/migration extension point.
