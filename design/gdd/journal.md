# Journal / Console

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-26
> **Implements Pillar**: Archaeological Memory

## Overview

Journal / Console owns lore fragment availability, Captain's Log delivery, Forge Console glow state, and post-game terminal text routing. It listens to milestone events from progression systems and tells the Hub when unread content is available.

It does not own combat, economy, map traversal, or ending resolution. It owns the record of what the player is allowed to read and where that record appears.

## Player Fantasy

The Journal is not a codex that explains the world from above. It is recovered evidence: the ship's old language surfacing when Skye has earned enough context to understand it. The Forge Console glows because something has become readable, not because a menu needs attention.

## Detailed Design

### Core Rules

1. Journal content is stored as `JournalFragment` Resources.
2. Fragments unlock from signals and save flags; the Journal never polls every frame.
3. The Forge Console has two states owned by Dragon Forge Hub: Neutral and Glow. Journal emits `journal_entry_available(fragment_id)` to request Glow.
4. Reading a fragment writes `journal_read_ids[]` atomically.
5. The Act 2 Matrix Concept LORE node must deliver `elemental_resonance`.
6. Stage IV dragon lore consists of six Captain's Log fragments, one per core element.
7. Void does not require a Stage IV Captain's Log fragment in MVP; its acquisition line is owned by Singularity/Narrative, while Journal may record a terminal entry.
8. Singularity milestone events may unlock terminal readouts, but relic-specific residual Admin final lines remain authored in Singularity/Narrative, not Journal.
9. Post-game Crown and Mirror Admin terminal content is read-only and selected by `ending_id`.
10. Replaying a battle must not duplicate first-time Journal unlocks.

### Required Fragment IDs

| Fragment ID | Unlock Source | Delivery Surface |
|---|---|---|
| `elemental_resonance` | Campaign Map Act 2 LORE node | LORE node + Forge Console |
| `stage_iv_fire` | `stage_iv_reached(Fire)` | Forge Console |
| `stage_iv_ice` | `stage_iv_reached(Ice)` | Forge Console |
| `stage_iv_storm` | `stage_iv_reached(Storm)` | Forge Console |
| `stage_iv_stone` | `stage_iv_reached(Stone)` | Forge Console |
| `stage_iv_venom` | `stage_iv_reached(Venom)` | Forge Console |
| `stage_iv_shadow` | `stage_iv_reached(Shadow)` | Forge Console |

### Terminal Entries

| Terminal ID | Unlock Source | Notes |
|---|---|---|
| `mirror_admin_archived` | `mirror_admin_defeated()` | Shown at Mirror Admin node after defeat/post-game. |
| `crown_total_restore` | `ending_resolved(total_restore)` | Post-game Crown terminal profile. |
| `crown_the_patch` | `ending_resolved(the_patch)` | Post-game Crown terminal profile. |
| `crown_hardware_override` | `ending_resolved(hardware_override)` | Post-game Crown terminal profile. |

## Formulas

### Availability

```
is_available(fragment_id) =
    fragment_id in journal_unlocked_ids
    AND fragment_id not in journal_read_ids
```

Forge Console Glow is active when any fragment is available.

## Edge Cases

| ID | Case | Resolution |
|---|---|---|
| EC-JR01 | Listener connects after Stage IV already reached | On connect/load, scan core dragons with `level >= 50` and unlock missing stage fragments. |
| EC-JR02 | Same unlock signal fires twice | Unlock is idempotent; no duplicate entries. |
| EC-JR03 | Player reads `elemental_resonance` after already owning all six elements | Campaign Map matrix tracker appears immediately after read. |
| EC-JR04 | Post-game terminal opened before exact prose is final | Display approved placeholder terminal text marked content-draft in data, not code. |

## Dependencies

| System | Relationship |
|---|---|
| Dragon Forge Hub | Receives `journal_entry_available(fragment_id)` and owns Console Neutral/Glow presentation. |
| Campaign Map | Emits `landmark_reached(node_id)` and hosts `elemental_resonance` LORE node. |
| Dragon Progression | Emits `stage_iv_reached(element)`. |
| Singularity | Emits `gatekeeper_defeated`, `mirror_admin_defeated`, and `ending_resolved`. |
| Save / Persistence | Stores `journal_unlocked_ids[]`, `journal_read_ids[]`, and terminal read state. |

## Tuning Knobs

| Knob | Default | Safe Range | Notes |
|---|---|---|---|
| `CONSOLE_GLOW_PULSE_SECONDS` | 1.5 | 0.5-3.0 | Visual only. |
| `MAX_FRAGMENT_TITLE_CHARS` | 48 | 24-72 | UI fit. |

## Acceptance Criteria

| ID | Criterion |
|---|---|
| AC-JR01 | Reading the Act 2 Matrix LORE node unlocks and displays `elemental_resonance`. |
| AC-JR02 | `journal_entry_available(elemental_resonance)` fires when the fragment becomes available. |
| AC-JR03 | Each core element's `stage_iv_reached(element)` unlocks exactly one matching Stage IV fragment. |
| AC-JR04 | Duplicate unlock signals do not duplicate Journal entries. |
| AC-JR05 | Reading a fragment writes `journal_read_ids[]` atomically through Save / Persistence. |
| AC-JR06 | Mirror Admin post-game terminal opens `mirror_admin_archived` and does not trigger combat. |
| AC-JR07 | Crown post-game terminal selects content by `ending_id`. |

## Open Questions

| ID | Question | Blocking? | Notes |
|---|---|---|---|
| OQ-JR01 | Final prose for all seven Captain's Log fragments. | No | Blocks content polish, not delivery implementation. |
| OQ-JR02 | Final post-game terminal prose. | No | Singularity requires terminal function; prose can land later. |
