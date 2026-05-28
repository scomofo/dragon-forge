# Architecture Review Report

Date: 2026-05-26
Mode: `/architecture-review full`
Engine: Godot 4.6
GDDs Reviewed: 15
ADRs Reviewed: 15

Loaded inputs: all root `design/gdd/*.md` files, all `docs/architecture/adr-*.md`, `docs/architecture/architecture.md`, `docs/architecture/control-manifest.md`, `docs/architecture/tr-registry.yaml`, `docs/registry/architecture.yaml`, `docs/engine-reference/godot/`, and `.Codex/docs/technical-preferences.md`.

## Verdict

CONCERNS

The architecture is ready for the Technical Setup -> Pre-Production gate and now includes follow-up ADRs for the previously partial Hatchery, Fusion, Journal / Console, and Audio Director systems. All Foundation requirements have ADR coverage, the previous Singularity and corruption-rendering gap is closed, ADR-0001 through ADR-0015 are Accepted, and no blocking cross-ADR conflicts or dependency cycles were found.

The verdict remains CONCERNS rather than PASS because Hub presentation composition still has one low-priority partial coverage item. That partial is not a Technical Setup blocker and can remain story-level unless Hub implementation reveals hidden cross-system ownership.

## Traceability Summary

| Status | Count |
|---|---:|
| Covered | 38 |
| Partial | 1 |
| Gap | 0 |
| Total | 39 |

Full matrix: `docs/architecture/requirements-traceability.md`.

## Coverage Improvements Since Prior Review

- ADR-0010 now covers Singularity activation, corruption/SCAR ownership, gatekeeper settlement, Mirror Admin phase checkpoints, Void grant, Crown ending resolution, and `ending_id` authority.
- ADR-0011 now covers corruption rendering, restored gold-code overlays, HUD layering, accessibility constraints, and OpenGL3 Compatibility fallback rendering.
- ADR-0012 now covers Hatchery pull RNG, pity, economy spend, dragon creation, duplicate XP, and rollback-safe pull settlement.
- ADR-0013 now covers Fusion preview/commit consistency, inherited stat formulas, child creation, and parent retention/removal transactions.
- ADR-0014 now covers Journal / Console fragment resources, milestone unlocks, terminal routing, and read-state ownership.
- ADR-0015 now covers Audio Director event routing, cue pools, corruption mix ownership, tritone cue routing, and non-blocking audio behavior.
- Approved GDD wording was updated to remove stale direct-write language for Scrap, expedition item flags, Battle settlement, Dragon Progression event timing, Singularity boss flags, and `ending_id != null`.
- ADR-0001 through ADR-0004 now include formal `## Engine Compatibility` and `## ADR Dependencies` sections.

## Remaining Partial Coverage

| Priority | Requirement | Issue | Required Before |
|---|---|---|---|
| Low | TR-hub-001 | Hub is bounded by Scene Flow/Input/Save/Economy ADRs, but Felix ambient presentation and full station composition do not have a dedicated presentation ADR. | Hub presentation expansion beyond current MVP handoff |

## GDD Revision Flags

None. Previously flagged GDD wording has been remediated in Shop, Campaign Map, Battle Engine, Dragon Progression, Singularity, and Save / Persistence.

## Required ADRs

No ADR is required to pass the Technical Setup -> Pre-Production gate. Follow-up ADRs for Hatchery, Fusion, Journal / Console, and Audio Director have been written and accepted as ADR-0012 through ADR-0015.

## Cross-ADR Conflicts

No blocking cross-ADR conflicts found.

Known conflict-prone pattern: rapid GDD revisions tend to leave stale ownership wording in dependency tables and acceptance criteria. The current pass found no remaining stale direct-write language that conflicts with accepted ADR ownership.

## ADR Dependency Order

No dependency cycles found. All referenced dependencies are Accepted.

Foundation:

1. ADR-0001 Save Transaction Boundary
2. ADR-0003 Input Router Semantic Actions
3. ADR-0004 Authored Content Resources
4. ADR-0002 Semantic Event Contracts

Foundation integration:

5. ADR-0005 Godot Scene Flow And Autoload Boundaries

Core:

6. ADR-0006 Dragon Data Model And Progression Services
7. ADR-0007 Battle Runtime State Machine

Feature/economy:

8. ADR-0008 Campaign Map Content And Reward Pipeline
9. ADR-0009 Economy And Shop Transaction Boundaries

Endgame/presentation:

10. ADR-0010 Singularity Boss And Ending Orchestration
11. ADR-0011 Corruption Rendering Pipeline
12. ADR-0012 Hatchery Pull Transaction And RNG Boundaries
13. ADR-0013 Fusion Anvil Transaction Boundaries
14. ADR-0014 Journal Console And Lore Delivery Resources
15. ADR-0015 Audio Event Routing And Mix Ownership

## Engine Compatibility Issues

Engine: Godot 4.6

| Check | Result |
|---|---|
| ADRs with explicit `## Engine Compatibility` section | 15 / 15 |
| ADRs with explicit `## ADR Dependencies` section | 15 / 15 |
| ADRs with explicit `## GDD Requirements Addressed` section | 15 / 15 |
| Stale engine version references | None found |
| Deprecated API usage in ADR decisions | None found |
| Dependency cycles | None found |

Godot specialist consultation returned CONCERNS with no blockers:

- ADR-0011's Compositor/CompositorEffect primary stance plus reduced OpenGL3 Compatibility fallback is sound for Godot 4.6.
- Deprecated API risk is clear: deprecated references are framed as forbidden patterns.
- The only engine concern was wording precision around rendering method versus graphics backend. ADR-0011 and the control manifest were updated to distinguish Forward+ rendering method, Windows D3D12 default backend behavior, explicit Vulkan pinning if required, and QA evidence for the pinned backend plus OpenGL3 fallback.

## Architecture Document Coverage

`docs/architecture/architecture.md` covers all approved MVP/supporting systems except Armor System, which is explicitly Supporting / Not Started and excluded from binding MVP architecture until authored.

The architecture document now references ADR-0010 and ADR-0011 and records that the previous hard blockers have been remediated. Remaining partial coverage is tracked as follow-up ADR work before relevant implementation stories, not as a Technical Setup gate blocker.

## Pre-Gate Checklist

| Item | Status |
|---|---|
| `tests/unit/` | Present |
| `tests/integration/` | Present |
| `.github/workflows/tests.yml` | Present |
| `project.godot` | Present |
| `addons/gut/` | Present |
| `design/accessibility-requirements.md` | Present |
| `design/ux/interaction-patterns.md` | Present |
| `design/ux/hud.md` | Present |
| `design/art/art-bible.md` Sections 1-4 | Present |

## Verification

- `godot --version` reports Godot 4.6.3 locally.
- `godot --headless --import` completed successfully.
- `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit` passed: 1 script, 1 test, 1 assertion.
- YAML parsing passed for architecture registry, TR registry, and CI workflow.
- ADR section scan passed for all ADRs through ADR-0011.
- No stale `ending_id != null`, old GUT runner, or direct-write GDD blocker wording remains outside intentional "never writes" prohibitions.

## Session Notes

- New TR-IDs registered: None.
- Requirements remain stable at 39.
- No entries were appended to `docs/consistency-failures.md` because this run found no cross-ADR conflicts.
