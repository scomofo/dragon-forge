# ADR-0001: Save Transaction Boundary

## Status

Accepted

## Date

2026-05-26

## Context

Dragon Forge has many systems writing durable state: Campaign Map, Shop, Hatchery, Fusion, Journal / Console, Dragon Progression, and Singularity. Several approved GDD requirements depend on multiple fields changing together. Examples include Shop purchases deducting Scraps and setting item flags, Singularity committing corruption class and SCAR nodes, Mirror Admin defeat granting the Void dragon, and ending resolution writing `ending_id`.

Godot 4.6 supports typed `Resource` data and explicit deep duplication through `duplicate_deep()`, which is suitable for staged save copies. The project needs a single architecture rule that prevents partial writes and prevents gameplay systems from writing save files directly.

## Decision

Save / Persistence owns all durable game state through a typed Godot `Resource` named `SaveData`.

Runtime systems must request a `SaveTransaction`, mutate the staged copy, and commit through Save / Persistence. A transaction is valid only if all staged field changes are committed, verified, and reloaded successfully. Commit success signals fire only after the file commit succeeds.

The atomic file flow is:

1. Write `save_slot_N.tmp`.
2. Verify serialization.
3. Rename the current canonical save to `.bak`.
4. Rename the temp file to the canonical save.
5. Validate by reload.
6. Emit committed-state signals.

If any step fails, Save / Persistence restores or preserves the pre-transaction canonical save and returns failure.

## GDD Requirements Addressed

- `design/gdd/save-persistence.md`: AC-SV01 through AC-SV07
- `design/gdd/shop.md`: AC-SH09, AC-SH10, AC-SH16
- `design/gdd/singularity.md`: corruption, Mirror Admin, Void grant, and ending atomicity requirements
- `design/gdd/journal.md`: AC-JR05

## Implementation Rules

- Gameplay systems must not call file APIs to persist game state.
- `SaveData` is the only durable save schema.
- `ending_id != ""` is the only persistent post-game authority.
- Save commit signals must be emitted after commit, never before.
- Debug-only failure injection hooks must be excluded from release exports.
- Systems may keep local presentation state, but durable state must round-trip through Save / Persistence.

## Alternatives Considered

### Direct system writes

Rejected. Direct file writes by feature systems would make partial purchase, ending, and corruption states possible.

### Dictionary or JSON-only save data

Rejected for MVP architecture. Untyped dictionaries are easier to mutate accidentally and make schema migration and field ownership harder to audit.

### Emit gameplay signals before disk commit

Rejected. Downstream systems could react to state that later rolls back.

## Consequences

Feature implementation must route all durable changes through Save / Persistence, which adds a small amount of ceremony to every transactional system. In return, failures are testable, rollback behavior is deterministic, and later story implementation can reason about state ownership from one place.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Resources |
| **Knowledge Risk** | HIGH - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md` |
| **Post-Cutoff APIs Used** | Typed Resource save schema; `duplicate_deep()` for staged nested Resource copies where needed |
| **Verification Required** | Verify temp/backup/rename/reload flow, rollback under failure injection, deep-copy isolation, and commit-before-emit ordering. |

Save / Persistence must use Godot 4 callable signal connections and must avoid string-based `connect()`. Any staged copy of nested Resource state must use explicit deep duplication rather than shallow `duplicate()` leakage.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None |
| **Enables** | ADR-0002, ADR-0006, ADR-0007, ADR-0008, ADR-0009, ADR-0010 |
| **Blocks** | Any story that writes durable save state or emits committed durable-state signals |
| **Ordering Note** | This is a foundation ADR and must remain Accepted before feature transaction stories are generated. |
