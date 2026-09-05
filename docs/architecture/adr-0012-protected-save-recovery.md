# ADR-0012: Protected Saves and Explicit Recovery

## Status

Accepted. Supersedes the corrupt-save fallback and unguarded storage operations in [ADR-0003](adr-0003-single-localstorage-save-migrate.md). Its canonical save schema, additive migrations, and React state ownership remain in force.

## Date

2026-09-05

## Context

Returning a playable fresh save after a parse or storage error let startup telemetry overwrite unreadable progress. A failed write could also throw or disappear when the next helper reloaded the older stored value. Players need a recoverable copy, visible failure feedback, and an explicit choice before replacing progress.

## Decision

1. Keep `DEFAULT_SAVE` and gameplay helpers in `persistence.js`, with the main JSON object at `dragonforge_save`. Validate known field shapes before `migrateSave`, then fill missing defaults after semantic migrations. Missing legacy fields remain supported; malformed present fields must not reach gameplay.
2. Put storage operations in `saveStorage.js`. Before a changed main write, save the previous readable value at `dragonforge_save_backup`. If that copy cannot be written, retain the main value. This is one previous write, not a full session checkpoint.
3. Block gameplay and startup/heartbeat writes when the main save is unreadable, storage cannot initially be read, or a missing main save leaves a backup. Offer recovery actions instead of mounting the title/game screens. Never automatically replace damaged bytes with defaults or a backup.
4. On an ordinary write failure, retain subsequent progress in this tab's memory. `loadSave` returns that pending progress; the persistent warning offers retry and download without leaving battle. A reload or closed tab can lose memory-only progress.
5. Compare the stored main value with the value last read before writing. A detected external change blocks further writes and retains the session for download. Loading the other tab's saved progress requires confirmation. This detects conflicts at writes; it is not an atomic cross-tab lock.
6. Settings and recovery expose JSON export, import preview, confirmed backup restore, and confirmed new game. Imports are limited to 1 MiB and validated before any replacement. Before an explicit replacement of damaged data, archive its exact bytes at `dragonforge_save_damaged` (numbered suffixes preserve later damaged originals). An archive failure prevents replacement.
7. Reset explicitly removes the backup and damaged copies before writing a fresh main save. On failure, preserve the main save and attempt to restore removed copies. Import, restore, and reset report success only after the main write succeeds. Multi-key localStorage updates are not atomic; rollback of auxiliary copies is best effort.

## Consequences and validation

No backend, external state library, or save-format version is introduced. Recovery uses additional origin storage; downloads remain the player's portable copy. Browser storage deletion and simultaneous cross-tab writes are outside the guarantees of a local backup.

Automated coverage belongs in `saveValidation.test.js`, `saveRecovery.test.js`, and `SaveRecovery.test.jsx`: legacy migrations, malformed data, backup/archive preservation, storage failures, pending progress, conflicts, and recovery UI contracts. Real-browser acceptance remains tracked in [save-recovery-playtest.md](../save-recovery-playtest.md).
