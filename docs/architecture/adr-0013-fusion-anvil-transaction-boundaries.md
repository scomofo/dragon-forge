# ADR-0013: Fusion Anvil Transaction Boundaries

## Status

Accepted

## Date

2026-05-26

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core / Scripting / Resources / UI |
| **Knowledge Risk** | MEDIUM - Godot 4.6 is post-LLM-cutoff |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md`; `docs/engine-reference/godot/deprecated-apis.md`; `docs/engine-reference/godot/current-best-practices.md`; `docs/engine-reference/godot/modules/ui.md` |
| **Post-Cutoff APIs Used** | Typed Resource/data services through ADR-0004; Godot 4 callable signals through ADR-0002 |
| **Verification Required** | Verify preview determinism, parent eligibility, inherited stat formulas, parent retention/removal rules, save rollback, and post-commit event ordering. |

Fusion uses ordinary GDScript, typed data/result classes, Control UI, SaveTransaction helpers, and DragonProgressionService. It does not require physics, navigation, networking, or deprecated Godot 3 APIs.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-0001 Save Transaction Boundary; ADR-0002 Semantic Event Contracts; ADR-0004 Authored Content Resources; ADR-0005 Godot Scene Flow And Autoload Boundaries; ADR-0006 Dragon Data Model And Progression Services |
| **Enables** | Fusion Anvil implementation stories; Fusion formula tests; roster mutation stories |
| **Blocks** | Any story that previews fusion, creates a fused child, removes or retains parents, mutates Elder flag, or commits Fusion Anvil roster changes |
| **Ordering Note** | This ADR must be Accepted before Fusion Engine stories are generated. |

## Context

Fusion combines two existing DragonRecords into a new child with inherited base stats, level bonus, same-element or cross-element modifiers, shiny reset, and potential Elder generation. ADR-0006 owns DragonRecord mutation, but Fusion still needs a binding transaction boundary so preview math, parent eligibility, child creation, and parent changes cannot diverge.

## Decision

Fusion will be implemented as a `FusionService` that produces deterministic previews from immutable save snapshots and commits fusion through one SaveTransaction.

```gdscript
class_name FusionService
extends RefCounted

func configure(save_service: SaveService, dragon_progression: DragonProgressionService, fusion_rules: FusionRules) -> void
func preview_fusion(snapshot: SaveSnapshot, parent_a_id: StringName, parent_b_id: StringName) -> FusionPreviewResult
func execute_fusion(parent_a_id: StringName, parent_b_id: StringName, source_id: StringName) -> FusionCommitResult
```

`preview_fusion()` is read-only and must use the same formula path as `execute_fusion()`.

`execute_fusion()` opens one SaveTransaction and stages:

1. Parent eligibility validation from staged snapshot.
2. Child base stat calculation.
3. Child creation through DragonProgressionService source-specific fusion helper.
4. Parent removal or retention rules according to the Fusion GDD.
5. Pending semantic events for child creation and roster mutation.

No fusion-complete, roster-changed, or child-created event publishes until Save / Persistence commit succeeds.

## Formula Ownership

FusionService owns the fusion formula pipeline but not the canonical DragonRecord schema. DragonProgressionService owns record construction and invariant enforcement.

Formula inputs:

- Parent base stats
- Parent levels
- Parent elements
- Parent Stage IV / Elder eligibility
- Same-element stability bonus
- Cross-element HP penalty

Formula outputs are carried in `FusionPreviewResult` and `FusionCommitResult`; anonymous dictionaries are forbidden.

## GDD Requirements Addressed

| GDD | Requirement |
|-----|-------------|
| `design/gdd/fusion-engine.md` | Stat inheritance, level bonus, same-element bonus, cross-element HP penalty, shiny reset, Elder generation, and parent rules. |
| `design/gdd/dragon-progression.md` | Child records must use canonical DragonRecord schema and source-specific creation helpers. |
| `design/gdd/save-persistence.md` | Fusion child creation and parent mutation must be atomic and rollback-safe. |
| `design/gdd/input-router.md` | Fusion UI must remain gamepad-first and use semantic input actions. |

## Alternatives Considered

### Fusion UI writes child DragonRecord directly

Rejected. UI-owned mutation would bypass DragonProgressionService invariants and make preview/commit drift likely.

### Separate commits for child creation and parent removal

Rejected. A crash between commits could duplicate or destroy roster value.

### Preview formula duplicated in UI

Rejected. Preview and commit must use the same formula path to keep player-facing information truthful.

## Consequences

- Fusion is deterministic and testable without UI.
- Roster changes commit atomically.
- Preview/commit drift becomes a test failure.
- Fusion stories can embed one clear contract instead of inferring from shared Dragon/Save ADRs.

## Verification Plan

- Unit tests for same-element and cross-element formulas.
- Unit tests for Elder eligibility and shiny reset.
- Integration tests for parent retention/removal, child creation, save failure rollback, and commit-before-emit ordering.
- UI tests/manual evidence that preview values equal committed child values.
