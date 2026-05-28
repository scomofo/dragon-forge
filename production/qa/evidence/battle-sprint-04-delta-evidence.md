# Battle Sprint 04 Delta Evidence

> **Sprint**: Sprint 04
> **Date**: 2026-05-28
> **Engine**: Godot 4.6.3
> **Reviewer**: Codex

## Scope

This evidence covers BATTLE-005 and BATTLE-006, which were pulled after Sprint 03 QA sign-off and therefore were not included in the Sprint 03 QA verdict. Both stories are now reviewed, story-done closed, and verified under Sprint 04.

## Story Coverage

| Story | Evidence | Result |
|---|---|---|
| BATTLE-005 - Turn Resolution And Presentation Events | `tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd` verifies IMPACT simultaneous KO, RECOIL declaration order, Defrag Patch IMPACT timing, 50-turn status loop stability, presentation event payload carry/drain, and one-shot `battle_completed(payload, delta)`. | PASS |
| BATTLE-006 - NPC Action Selection Heuristics | `tests/unit/battle_engine/test_npc_action_selection_heuristics.gd` verifies super-effective 70% preference, status 40% preference, high-power 60% fallback, priority order, NPC Defend cooldown, enemy consumable rejection, and authored move immutability. | PASS |

## Review And Closure

| Gate | Evidence | Result |
|---|---|---|
| Code review | `/code-review` approved after required presentation-event, legal consumable timing, completion payload/delta, runtime typing, and enemy-consumable rejection fixes. | PASS |
| BATTLE-005 story-done | `production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md` is marked Complete with 5/5 ACs checked. | PASS |
| BATTLE-006 story-done | `production/epics/battle-engine/story-006-npc-action-selection-heuristics.md` is marked Complete with 6/6 ACs checked; optional majority-playtest evidence remains advisory. | PASS WITH NOTES |

## Control Manifest Checks

| Rule | Evidence | Result |
|---|---|---|
| CM-GLOB-04 | BATTLE-005 coverage verifies missing presentation listeners do not block gameplay progression. | PASS |
| CM-GLOB-08 / CM-BATTLE-03 | BATTLE-005 completion uses `battle_completed(payload, delta)` as a pre-commit settlement request; Battle runtime does not commit durable rewards. | PASS |
| CM-BATTLE-01 / CM-DATA-06 | BATTLE-005/BATTLE-006 runtime state is held in `BattleSession` / `CombatantBattleState`, while authored moves remain immutable Resources. | PASS |

## Commands

Focused BATTLE-005/BATTLE-006 regression:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd -gtest=res://tests/unit/battle_engine/test_npc_action_selection_heuristics.gd -gexit
```

Result: 2 scripts, 11/11 tests passing, 387 assertions.

Adjacent Battle Engine slice:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gtest=res://tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd -gtest=res://tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd -gtest=res://tests/unit/battle_engine/test_status_and_recoil_effects.gd -gtest=res://tests/integration/battle_engine/test_telegraph_defend_and_defrag_delta.gd -gtest=res://tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd -gtest=res://tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd -gtest=res://tests/unit/battle_engine/test_npc_action_selection_heuristics.gd -gexit
```

Result: 7 scripts, 42/42 tests passing, 1,590 assertions.

Full unit/integration suite:

```bash
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

Result: 31 scripts, 157/157 tests passing, 7,682 assertions.

Note: the full suite prints expected `push_error` and `push_warning` output from defensive Dragon save/progression tests. GUT reports these as `ExpectedError`, and the suite passes.

## Manual Notes

- BATTLE-006's majority-playtest check remains advisory because deterministic unit tests verify the weighted thresholds exactly. A short internal playtest can still be added later if a playable battle UI path is available.
- Sprint 04 still needs SCENE-003 manual launch evidence and BATTLE-007 source/content evidence before phase-advancement claims.

## Sign-Off

| Role | Scope | Decision |
|---|---|---|
| QA | Sprint 04 Battle delta automated evidence | [x] Approved |
| Gameplay/Systems | BATTLE-005/BATTLE-006 story closure evidence | [x] Approved |
