# ADR-0009: Permanent discovered codex flag decouples collection milestones from current ownership

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Collection-count milestones (`first_discovery`, `elemental_trio`, `full_roster`)
must never regress when fusion consumes a dragon, yet fusion intentionally flips
a parent's `owned` flag back to `false`. This ADR documents the decision to carry
a second, permanent per-dragon boolean — `discovered` — that is set `true` the
first time a dragon is ever owned and is never reverted, so collection progress
counts ever-owned dragons while gameplay eligibility continues to count
currently-owned dragons.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18 + Vite (browser build, `src/`) |
| **Domain** | Core (save-state schema / persistence) |
| **Knowledge Risk** | LOW — plain JS objects in `localStorage`, no engine-version-sensitive APIs |
| **References Consulted** | `src/persistence.js`, `src/journalMilestones.js`, `src/hatcheryEngine.js`, `src/journalMilestones.test.js` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — operates on the central `save` object (`DEFAULT_SAVE` / `migrateSave` in `persistence.js`) |
| **Enables** | Collection-completionism milestone layer (Journal & Milestones); irreversible-sacrifice fusion economy |
| **Blocks** | None |
| **Ordering Note** | The `discovered` field is part of the per-dragon save schema; any new dragon-mutating writer (pull, fusion, reward grant) must set `discovered: true` alongside `owned: true`. |

## Context

### Problem Statement

The game has two collection-facing systems with opposing requirements on the same
underlying dragon record:

- **Fusion** is designed as an irreversible sacrifice: fusing consumes two owned
  parents and produces one offspring. The natural representation is to set the
  parents `owned: false` (they are gone from the active roster).
- **Collection milestones** reward the player for the breadth of dragons they have
  catalogued (`first_discovery` at 1, `elemental_trio` at 3, `full_roster` at 8).
  These are one-time, DataScraps-rewarding achievements claimed in the Journal.

If collection milestones counted `owned`, then fusing away a parent would *reduce*
the collection count. A player at `full_roster` (8/8) who fuses two dragons would
drop to 6/8 and could, in principle, lose the visible completion state — punishing
the player for engaging with a core system. The milestone is also already claimed
(its ID lives permanently in `save.milestones`), so the regression would produce an
incoherent UI: a claimed badge whose live progress reads `6/8`.

A decision is needed on how to represent "this dragon has been part of the
collection" independently of "this dragon is in the active roster right now."

### Current State

Each entry in `save.dragons` carries both flags as independent booleans
(`src/persistence.js:9-19`):

```js
fire: { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null },
```

- `owned` — `true` while the dragon is in the active roster; gates fusion
  eligibility and current-roster prestige (shiny milestones, max-level milestones).
- `discovered` — a permanent codex flag, set `true` the first time `owned` becomes
  `true`, never reverted.

Collection milestones count `discovered`; fusion preserves `discovered` while
clearing `owned`. This is the shipped behavior this ADR records.

### Constraints

- **Single mutable save object.** All state lives in one `save` object loaded from
  `localStorage` (key `dragonforge_save`) and mutated through `persistence.js`
  helpers (see CLAUDE.md). The flag must live on the per-dragon record, not in a
  side structure, so every writer touches it naturally.
- **Forward-compatible migration required.** Saves predating the `discovered` field
  exist in the wild. `migrateSave` must backfill `discovered` without data loss and
  without crediting dragons the player never had.
- **No server / no authority.** This is a client-only save; there is no
  reconciliation layer. The schema itself must encode the invariant.
- **Pure, testable engines.** Milestone checks (`journalMilestones.js`) and pull
  application (`hatcheryEngine.js`) are pure functions with `.test.js` siblings; the
  rule must be expressible without I/O.

### Requirements

- Collection-count milestones must be monotonic: once a dragon is discovered, the
  collection count for that dragon never decreases by any in-game action.
- Fusion must remain an irreversible removal from the active roster (`owned: false`).
- Current-roster-prestige milestones (shiny, max-level) must still react to fusion —
  fusing away a shiny *should* drop the shiny count, because shinies are a
  current-roster prestige, not a codex entry.
- Legacy saves must migrate to correct `discovered` values, including reconstructing
  discovery for dragons that were already fused away before the field existed.

## Decision

Add a permanent per-dragon boolean `discovered` to the dragon save schema.
`discovered` becomes `true` the first time a dragon is ever owned and is **never**
set back to `false` by any game action. Two independent flags then serve two
independent questions:

- "Is this dragon in the active roster *right now*?" → `owned`
  (fusion eligibility, shiny prestige, max-level prestige).
- "Has this dragon *ever* been in the collection?" → `discovered`
  (collection-count milestones, codex display).

Every code path that grants a dragon sets both flags together. The only path that
clears `owned` (fusion) explicitly *keeps* `discovered: true`. `migrateSave`
backfills the flag for legacy saves and repairs collection regressions that
occurred before the field existed.

### Architecture

```
                       save.dragons[id]
                ┌───────────────────────────────┐
   writers ───▶ │ owned        discovered        │ ◀─── readers
                │ (current)    (ever-owned)      │
                └───────────────────────────────┘
                    │              │
   WRITERS:         │              │            READERS:
   unlockDragon ───▶ true   ────▶ true          ┌─ collection milestones
   applyPullResult ─▶ true  ────▶ true          │  (first_discovery, elemental_trio,
   fuseDragons:                                  │   full_roster) → count discovered
     parents  ────▶ false   (keep) true ─────────┤
     offspring ──▶ true     ────▶ true           ├─ fusion eligibility → owned
   markSingularity- ▶ true  ────▶ true           ├─ shiny milestones → owned && shiny
     Complete (light)                            └─ max-level milestones → owned && lvl>=50
   migrateSave (backfill) ─────▶ derived

   INVARIANT:  owned === true  ⟹  discovered === true     (set together, always)
               discovered      never transitions true → false
```

### Key Interfaces

```js
// Per-dragon save record (src/persistence.js)
{
  level: number,
  xp: number,
  owned: boolean,        // in active roster right now
  discovered: boolean,   // ever owned — permanent codex flag, monotonic
  shiny: boolean,
  fusedBaseStats: object | null,
}

// WRITERS — every dragon grant sets both flags:
unlockDragon(id, shiny):          dragons[id] = { ...prev, owned: true, discovered: true }
applyPullResult(save, pull):      dragon.owned = true; dragon.discovered = true   // on first acquire
fuseDragons(a, b, offspring,...): dragons[a] = { ...prev, owned: false, ..., discovered: true }  // KEEP
                                  dragons[b] = { ...prev, owned: false, ..., discovered: true }  // KEEP
                                  dragons[offspring] = { ...prev, owned: true, discovered: true }
markSingularityComplete():        dragons.light = { ..., owned: true, discovered: true }

// READERS — collection vs. current-roster split:
checkMilestones(save):
  discoveredCount = count(save.dragons where d.discovered)        // first_discovery / elemental_trio / full_roster
  shinyCount      = count(save.dragons where d.owned && d.shiny)  // shiny_* (current-roster prestige)
  maxedCount      = count(save.dragons where d.owned && d.level >= 50)
```

### Implementation Guidelines

- Treat `discovered` as monotonic. There must be exactly **one** transition for it
  per dragon: `false → true`, on first acquisition. No code path may write
  `discovered: false` onto an already-discovered dragon. The fusion writer is the
  trap to watch — when spreading a reset parent record, explicitly re-assert
  `discovered: true` (`persistence.js:364-365`).
- Any new dragon-granting code path (new reward, new boss drop, NG+ grant) MUST set
  `discovered: true` alongside `owned: true`. The established idiom is to set both in
  the same object literal.
- Collection milestones MUST count `discovered`; current-roster prestige milestones
  (shiny, max-level) MUST count `owned` (with the relevant secondary condition). Do
  not blur the two — the asymmetry is intentional (`journalMilestones.js:8-32` vs
  `36-61`).
- `migrateSave` is the only place that *derives* `discovered`. Backfill from any
  signal of past ownership (`owned || level > 1 || xp > 0 || fusedBaseStats`) and
  additionally walk `fusionLineage` to credit dragons that were fused away before the
  field existed (`persistence.js:67-79`).

## Alternatives Considered

### Alternative 1: Count `owned` for collection milestones (single flag)

- **Description**: Keep only the `owned` flag and have collection milestones count it
  directly. No `discovered` field.
- **Pros**: Simplest possible schema; one flag, no migration, no invariant to police.
- **Cons**: Directly causes the regression this ADR exists to prevent — fusing a
  dragon drops the collection count, can un-complete `full_roster` visually while the
  badge is already claimed, and punishes the player for using a core system. Conflicts
  with the design pillar that "the player should never feel that fusing dragons set
  them back in the collection" (`design/gdd/journal-milestones.md`).
- **Estimated Effort**: Lower (it is strictly less code).
- **Rejection Reason**: Fails the monotonicity requirement; produces incoherent
  claimed-but-regressed milestone UI.

### Alternative 2: Make fusion keep parents `owned: true`

- **Description**: Represent fusion non-destructively — leave parents `owned` and only
  add the offspring. Collection could then safely count `owned`.
- **Pros**: One flag again; no regression because nothing is removed.
- **Cons**: Destroys the fusion fantasy. Fusion is explicitly an irreversible
  sacrifice of two owned dragons (`design/gdd/fusion.md` — "both parents are
  permanently gone — there is no undo"). It also breaks fusion eligibility (parents
  would still appear as fuseable) and the cost/weight of the choice. The roster-count
  semantics that other systems rely on (active dragons) would be wrong.
- **Estimated Effort**: Comparable.
- **Rejection Reason**: Contradicts the core fusion design; `owned` must mean
  "currently in roster."

### Alternative 3: Separate `discoveredDragons` set/array at the save root

- **Description**: Track discovery in a top-level `save.discoveredDragons = [ids...]`
  collection rather than a per-dragon flag.
- **Pros**: Cleanly separates codex membership from the dragon record; impossible to
  accidentally clear during a per-dragon reset.
- **Cons**: Splits a single conceptual entity ("this dragon") across two structures,
  so every writer must remember to update two places and every reader must join them.
  It also breaks the project's prevailing pattern where per-dragon truth lives on
  `save.dragons[id]`, complicating the codex/Journal rendering that already iterates
  `save.dragons`. Migration would still be required.
- **Estimated Effort**: Higher (new structure + join logic + migration).
- **Rejection Reason**: More surface area and a worse fit with the single-object,
  per-dragon-record convention; the colocated boolean is simpler to read and test.

## Consequences

### Positive

- Collection milestones are monotonic by construction — fusing dragons can never
  reduce `first_discovery` / `elemental_trio` / `full_roster` progress. Directly
  verified by `src/journalMilestones.test.js` ("collection milestones count
  discovered, not owned").
- Fusion keeps its intended destructive semantics (`owned: false`) without any
  collateral damage to collection progress — the two systems are cleanly decoupled.
- The codex/Journal can display every dragon the player has ever owned, including ones
  fused away, by reading `discovered`.
- The asymmetry is expressive: shiny and max-level milestones intentionally *do*
  react to fusion (they read `owned`), correctly modeling them as current-roster
  prestige rather than permanent achievements.
- Legacy saves are repaired, including reconstructing discovery for dragons fused away
  before the field existed (lineage walk) and retroactively granting `full_roster`
  to saves that met the old 6-dragon threshold before it rose to 8.

### Negative

- A two-flag invariant must be maintained by hand: every dragon-granting writer has to
  remember `discovered: true`, and the fusion reset must re-assert it. A new writer
  that sets `owned: true` but forgets `discovered: true` would silently break codex
  display and collection milestones. This is mitigated by tests and the established
  same-object-literal idiom, but it is a standing maintenance obligation.
- Slightly larger save footprint (one boolean per dragon) — negligible.
- Two flags that are *usually* equal (`owned ⟹ discovered`) can read as redundant to a
  newcomer; the distinction only matters in the post-fusion / post-migration states.

### Neutral

- `migrateSave` carries dedicated backfill and lineage-repair logic
  (`persistence.js:67-79`) that runs once per load on legacy saves and is a no-op on
  current saves.
- Shiny milestones remain free to decrease (a fused-away shiny lowers the shiny
  count); this is deliberate and is documented as such in the GDD.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| New dragon-granting writer forgets `discovered: true` → codex/collection breaks for that path | Medium | Medium | Same-object-literal idiom; add a regression test per new grant path; code-review checklist item |
| Fusion reset re-introduces `discovered: false` during a future refactor | Low | High (silent collection regression) | `journalMilestones.test.js` asserts non-regression after fusion; keep the explicit `discovered: true` on parent records |
| Migration credits a dragon the player never owned (false-positive discovery) | Low | Low | Backfill keys off concrete signals (owned / level>1 / xp>0 / fusedBaseStats / lineage), not blanket true |
| Collection milestone authored to count `owned` instead of `discovered` | Low | Medium | GDD codifies the rule; existing milestones are the reference pattern |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | n/a | negligible (one extra boolean read per dragon during `checkMilestones`, run on Journal open, not per frame) | < 16.6ms/frame |
| Memory | n/a | +1 boolean per dragon (~9 booleans) | n/a |
| Load Time | n/a | one-time backfill + lineage walk in `migrateSave` on legacy saves (O(dragons + lineage entries)) | < 100ms save load |
| Network (if applicable) | n/a | n/a (client-only `localStorage`) | n/a |

## Migration Plan

This decision is already shipped; the migration is implemented in
`persistence.js:migrateSave`.

1. On load, for each dragon missing `discovered`, derive it from any signal of past
   ownership: `d.owned || d.level > 1 || d.xp > 0 || !!d.fusedBaseStats`
   (`persistence.js:67-69`). Verify: a save with a leveled dragon reports it as
   discovered.
2. Walk `save.fusionLineage` and set `discovered: true` for every `parentA`,
   `parentB`, and `offspring` id, repairing pre-`discovered` saves whose collection
   regressed because a parent was fused to `owned: false` before the field existed
   (`persistence.js:73-79`). Verify: a save with a fused-away parent counts it as
   discovered.
3. Retroactively grant `full_roster` (and its 500 DataScraps) to any save that now has
   `>= 8` discovered dragons but never claimed it — covering the threshold change from
   6 to 8 (`persistence.js:84-88`). Verify: a qualifying legacy save shows
   `full_roster` claimed after load.

**Rollback plan**: The field is additive and ignored by older code paths that only
read `owned`. To revert, change the three collection milestones to count `owned`
instead of `discovered` and stop preserving the flag in `fuseDragons`; the orphaned
`discovered` field can remain in saves harmlessly. (Rollback reintroduces the
regression bug, so it is not recommended.)

## Validation Criteria

- [x] After fusion consumes two parents, `full_roster` still reports 8/8 and remains
      claimed (`journalMilestones.test.js`: "full_roster stays at 8/8 after fusion").
- [x] `elemental_trio` does not regress when a discovered dragon is fused away
      (`journalMilestones.test.js`).
- [x] `first_discovery` stays met even if the only dragon was fused away
      (`journalMilestones.test.js`).
- [x] An entirely undiscovered roster reports zero collection progress
      (`journalMilestones.test.js`).
- [x] Shiny milestones count `owned && shiny` and may decrease when a shiny is fused
      away (`journalMilestones.js:36-61`).
- [x] Every dragon-granting writer sets `discovered: true` alongside `owned: true`
      (`unlockDragon`, `applyPullResult`, `fuseDragons` offspring,
      `markSingularityComplete`).

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/journal-milestones.md` | Journal & Milestones | "Discovery flag vs. owned flag … `discovered` is **never** reverted to `false` by any game action" (Core Rules #2); collection milestones count `discovered`, not `owned` (Formulas — Collection Milestone Progress) | Schema carries a permanent `discovered` boolean set on first ownership; `checkMilestones` counts `discovered` for `first_discovery` / `elemental_trio` / `full_roster` (`journalMilestones.js:8-32`) |
| `design/gdd/journal-milestones.md` | Journal & Milestones | "The player should never feel that fusing dragons set them back in the collection — discovered dragons stay in the codex permanently" (Player Fantasy) | Fusion preserves `discovered: true` on consumed parents, so collection count is monotonic (`persistence.js:364-365`) |
| `design/gdd/fusion.md` | Fusion | "Parent consumption … `{ … owned: false … discovered: true }`. The `discovered` flag is preserved (never cleared) so collection-count milestones do not regress" (Core Rules #9) | `fuseDragons` sets parents `owned: false` while explicitly re-asserting `discovered: true` (`persistence.js:364-365`) |
| `design/gdd/fusion.md` | Fusion | "`discovered` flag preservation means fusing a dragon does not reduce collection progress" (Interactions / dependencies) | The two-flag split decouples roster removal (`owned`) from codex membership (`discovered`) |

## Related

- `design/gdd/journal-milestones.md` — collection vs. current-roster milestone rules; primary consumer of `discovered`.
- `design/gdd/fusion.md` — parent-consumption rule that preserves `discovered`.
- `src/persistence.js` — `DEFAULT_SAVE` schema (lines 5-19), `migrateSave` backfill + lineage repair (lines 53-88), `unlockDragon` (line 181), `fuseDragons` (lines 358-381), `markSingularityComplete` (lines 309-320).
- `src/journalMilestones.js` — collection milestones counting `discovered` (lines 8-32); shiny/max-level milestones counting `owned` (lines 36-61, 205-215).
- `src/hatcheryEngine.js` — `applyPullResult` sets `owned` + `discovered` on first acquire (lines 57-61).
- `src/journalMilestones.test.js` — non-regression tests for collection milestones after fusion (lines 23-58).
