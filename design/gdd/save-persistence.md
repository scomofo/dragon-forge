# Save / Persistence

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-26
> **Implements Pillar**: Craft Through Consequence

## Overview

Save / Persistence owns Dragon Forge's durable game state: loading, migration, atomic writes, rollback, and test-only failure injection. It does not decide game rules. Systems prepare state changes; Save / Persistence commits them safely or rejects the whole transaction.

The system is especially load-bearing for Singularity. Corruption class changes, SCAR node lists, Mirror Admin defeat, Void dragon grant, and `ending_id` must never appear as partial saves. A save may be old, missing optional fields, or interrupted during a write; it must not leave the player in an impossible world.

## Player Fantasy

The Save Lantern is not a menu abstraction. It is the ship remembering Skye without understanding her. A good save feels quiet and dependable: the player trusts the world to keep its scars, purchases, dragons, and ending choice exactly as earned.

## Detailed Design

### Core Rules

1. Save data is stored as a typed Godot Resource named `SaveData`.
2. Each save file has `schema_version`, `created_at_unix`, `updated_at_unix`, and `last_committed_transaction_id`.
3. Runtime systems do not write files directly. They request a `SaveTransaction`, mutate a staged copy, then call `commit()`.
4. A transaction either commits all staged fields or commits none. Partial saves are invalid.
5. File writes use an atomic temp-file flow: write `save_slot_N.tmp`, verify serialization, rename current save to `.bak`, rename tmp to canonical save, then emit success.
6. Signals that announce committed state changes fire only after the file commit succeeds.
7. Manual save is disabled during transactions marked `manual_save_locked = true`, including the Mirror Admin continuous encounter.
8. Save / Persistence exposes debug-only failure injection hooks for QA. These hooks must not compile into release exports.
9. Loading a missing optional field applies a documented default. Loading an invalid identity field discards only the invalid record when possible; if world-state identity is corrupt, load falls back to Hub recovery.
10. `ending_id != ""` is the only persistent post-game authority. No serialized `game_state = "post_game"` field exists.

### SaveData Fields

| Owner | Fields |
|---|---|
| Campaign Map | `current_node_id`, `acts_unlocked[]`, `unlocked_gates[]`, `matrix_stabilized`, `visited_nodes[]`, `cleared_bosses[]`, `cleared_combat_nodes[]`, `loadout_hp[]`, `previous_node_id`, `expedition_xp_earned`, `gate_denial_count{}`, `expedition_field_kit` |
| Singularity | `corruption_class`, `scar_nodes[]`, `gatekeeper_fire_defeated`, `gatekeeper_ice_defeated`, `gatekeeper_shadow_defeated`, `mirror_admin_defeated`, `void_dragon_granted`, `ending_id` |
| Economy | `player_scraps`, `relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned`, `expedition_defrag_patch`, `expedition_cache_shard`, `expedition_emergency_patch` |
| Dragon Systems | `dragons[]`, `story_roster[]`, `hatchery_pity_counter`, `element_drought_counters{}` |
| Journal / Console | `journal_unlocked_ids[]`, `journal_read_ids[]`, `terminal_read_ids[]` |

### Public API

| API | Purpose |
|---|---|
| `begin_transaction(reason: StringName) -> SaveTransaction` | Creates staged copy. |
| `commit_transaction(tx: SaveTransaction) -> SaveCommitResult` | Performs atomic write and emits success/failure. |
| `load_slot(slot_id: int) -> SaveLoadResult` | Loads, validates, and migrates a slot. |
| `request_manual_save(source: StringName) -> SaveCommitResult` | Save Lantern/manual save entry point. |
| `set_failure_injection(point: StringName, enabled: bool)` | Debug-only QA hook. |
| `clear_failure_injection()` | Debug-only reset hook. |

### Failure Injection Points

| Hook | Fires Before | Required For |
|---|---|---|
| `before_temp_write` | Temp file write starts | Generic save-failure UI |
| `after_temp_write_before_swap` | Temp file exists, canonical untouched | Atomicity rollback |
| `after_backup_before_rename` | Backup exists, canonical about to swap | Crash recovery |
| `before_signal_emit` | Commit succeeded, signals not yet emitted | Commit-before-emit ordering |
| `singularity_corruption_commit` | Corruption + `scar_nodes[]` commit | AC-SG13 |
| `singularity_mirror_admin_commit` | `mirror_admin_defeated` + Void grant commit | AC-SG28 |
| `singularity_ending_commit` | `ending_id` commit | AC-SG38 |
| `shop_purchase_commit` | Scrap deduction + item flag commit | AC-SH09/10/16 |

## Formulas

### Transaction Atomicity

```
commit_valid =
    temp_write_ok
    AND temp_verify_ok
    AND canonical_swap_ok
    AND post_load_validate_ok
```

If any term is false, the canonical save remains the pre-transaction state or is restored from `.bak` before failure is reported.

## Edge Cases

| ID | Case | Resolution |
|---|---|---|
| EC-SV01 | App closes after tmp write but before rename | On next boot, discard `.tmp`; keep canonical save. |
| EC-SV02 | App closes after backup rename but before canonical rename | Restore `.bak` to canonical if canonical is missing. |
| EC-SV03 | Legacy save lacks `ending_id` | Default empty string; not post-game. |
| EC-SV04 | Legacy save lacks `scar_nodes[]` | Ask Singularity/Campaign Map migration helper to re-derive from `corruption_class`. |
| EC-SV05 | Mirror Admin app close mid-encounter | Reload last pre-boss save; no persistent phase-progress field exists. |
| EC-SV06 | Save Lantern request during locked transaction | Return blocked result; Hub displays non-fatal save unavailable state. |

## Dependencies

| System | Relationship |
|---|---|
| Dragon Forge Hub | Manual Save Lantern calls `request_manual_save`. |
| Campaign Map | Reads expedition, node, matrix, and post-game fields; requests staged mutation through owning services and SaveTransaction helpers. |
| Shop | Requires atomic purchase commits. |
| Hatchery | Requires atomic pull commits: Scrap deduction, dragon result, pity counters. |
| Fusion Engine | Requires atomic fusion output commits. |
| Singularity | Requires atomic corruption, Mirror Admin, Void, and ending commits plus failure injection hooks. |
| Journal / Console | Requires atomic read-state commits for lore fragments and terminal entries. |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|---|---|---|---|
| `SAVE_SCHEMA_VERSION` | 1 | monotonic int | Increment on migration. |
| `MAX_BACKUP_FILES` | 1 | 1-3 | More than 1 is useful for QA but not required for MVP. |
| `MANUAL_SAVE_COOLDOWN_MS` | 500 | 250-2000 | Prevents double-trigger at Save Lantern. |

## Acceptance Criteria

| ID | Criterion |
|---|---|
| AC-SV01 | A successful manual save writes a loadable `SaveData` Resource and emits `save_committed` exactly once after file commit. |
| AC-SV02 | Injecting `after_temp_write_before_swap` leaves the canonical save unchanged after reload. |
| AC-SV03 | Corruption class + `scar_nodes[]` commit is atomic; injected failure rolls back both fields. |
| AC-SV04 | Mirror Admin defeat + Void grant commit is atomic; injected failure leaves both unset after reload. |
| AC-SV05 | Ending commit writes `ending_id` only; no `game_state` field is serialized. |
| AC-SV06 | Signals tied to committed state do not emit when commit fails. |
| AC-SV07 | Loading a save with `ending_id != ""` exposes that value to Campaign Map so it enters `MAP_FREE_ROAM`. |
| AC-SV08 | Debug failure injection API is unavailable in release export builds. |

## Open Questions

| ID | Question | Blocking? | Notes |
|---|---|---|---|
| OQ-SV01 | How many visible save slots ship in MVP? | No | Current GDD supports slot IDs; UI may expose one. |
| OQ-SV02 | Should backup restore show player-facing messaging? | No | Hub can show a subtle Save Lantern warning if desired. |
