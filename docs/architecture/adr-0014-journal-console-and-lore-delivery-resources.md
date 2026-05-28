# ADR-0014: Journal Console And Lore Delivery Resources

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | UI / Scripting / Resources / Save |
| **Knowledge Risk** | MEDIUM - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/modules/ui.md`; `docs/engine-reference/godot/current-best-practices.md` |
| **Post-Cutoff APIs Used** | Godot 4 callable signals through ADR-0002; Control focus behavior through ADR-0003/0005 |
| **Verification Required** | Verify stable fragment IDs, post-commit unlock events, read-state transactions, terminal routing, gamepad focus, and localization-ready text fields. |

Journal / Console uses Control UI, typed Resources, SaveTransaction helpers, and semantic events. It does not require physics, rendering post-processing, navigation, networking, or deprecated Godot 3 APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0003 Input Router Semantic Actions; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0010 Singularity Boss And Ending Orchestration |
| **Enables** | Journal / Console implementation stories; lore fragment tests; terminal routing stories; post-game terminal stories |
| **Blocks** | Any story that unlocks lore fragments, persists read state, routes Forge Console/post-game terminal content, or exposes Singularity terminal readouts |
| **Ordering Note** | This ADR must be Accepted before Journal / Console stories are generated. |

## Context

Journal / Console reads milestones from Campaign Map, Dragon Progression, and Singularity, unlocks lore, tracks read state, and displays terminal content. Shared Save/Event/Authored Data ADRs cover generic patterns, but Journal needs a system-level resource and read-state boundary so narrative delivery cannot mutate gameplay state or drift from stable content IDs.

## Decision

Journal / Console will be implemented as a presentation-facing feature service backed by authored `JournalLibrary` Resources and SaveTransaction read-state helpers.

```gdscript
class_name JournalService
extends RefCounted

signal fragment_unlocked(payload: JournalFragmentUnlockedPayload)
signal terminal_entry_available(payload: TerminalEntryAvailablePayload)

func configure(save_service: SaveService, library: JournalLibrary) -> void
func handle_milestone(payload: SemanticMilestonePayload) -> JournalUnlockResult
func mark_fragment_read(fragment_id: StringName) -> JournalReadResult
func mark_terminal_read(terminal_id: StringName) -> JournalReadResult
func get_available_fragments(snapshot: SaveSnapshot) -> Array[JournalFragmentDefinition]
func get_terminal_entry(snapshot: SaveSnapshot, terminal_id: StringName) -> TerminalEntryDefinition
```

Journal unlocks are requests triggered by post-commit semantic milestones. If an unlock itself changes save state, Journal opens a new guarded SaveTransaction and emits Journal events only after its commit succeeds.

## Authored Data

```gdscript
class_name JournalLibrary
extends Resource

@export var fragments: Array[JournalFragmentDefinition]
@export var terminals: Array[TerminalEntryDefinition]
```

```gdscript
class_name JournalFragmentDefinition
extends Resource

@export var fragment_id: StringName
@export var title_string_id: StringName
@export var body_string_id: StringName
@export var unlock_milestone_id: StringName
@export var category_id: StringName
```

All IDs must validate at boot/content-lock time. Display text uses string IDs or localization-ready fields; implementation logic must never key off prose text.

## State Ownership

Journal / Console owns:

- `journal_unlocked_ids[]`
- `journal_read_ids[]`
- `terminal_read_ids[]`

Journal / Console reads but does not own:

- Dragon roster/progression state
- Campaign Map node and Matrix state
- Singularity corruption, boss, Void, and ending state
- Shop/economy state

## GDD Requirements Addressed

| GDD | Requirement |
|-----|-------------|
| `design/gdd/journal.md` | Captain's Log fragments, Forge Console delivery, stable fragment IDs, terminal read state, and post-game terminal routing. |
| `design/gdd/singularity.md` | Gatekeeper, Mirror Admin, ending, and post-game terminal milestones feed lore delivery without granting gameplay authority. |
| `design/gdd/save-persistence.md` | Journal unlock/read state persists atomically. |
| `design/gdd/input-router.md` | Journal and terminal UI are completable by d-pad plus confirm/cancel. |

## Alternatives Considered

### Milestone systems write Journal fields directly

Rejected. It spreads read-state ownership across gameplay systems and makes narrative delivery hard to migrate.

### Journal content hardcoded in screen scripts

Rejected. Stable IDs and localization need authored content Resources or generated tables.

### Audio/terminal playback blocks Journal unlocks

Rejected. Missing presentation assets must not block gameplay or lore state.

## Consequences

- Journal remains narrative/presentation state, not gameplay authority.
- Stable IDs support localization, save migration, and terminal routing.
- Singularity and Campaign Map can emit milestones without knowing Journal internals.
- Journal stories have clear read/write ownership.

## Verification Plan

- Unit tests for milestone-to-fragment mapping and duplicate unlock idempotency.
- Integration tests for read-state save commit/rollback.
- UI/manual tests for d-pad focus, terminal dismissal, unread/read markers, and post-game terminal routing.
