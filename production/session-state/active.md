# Session State

**Task**: Hatchery Story 001 implementation
**Current section**: HATCHERY-001 implemented; code review next
**File**: production/epics/hatchery/story-001-pull-table-and-result-contracts.md

## Latest Handoff — 2026-05-28

Fresh handoff for a new chat:

`production/session-state/active.md`

Immediate next action:

1. Run `/code-review src/hatchery/hatchery_pull_table.gd src/hatchery/hatchery_pity_rules.gd src/hatchery/hatchery_rarity_weight.gd src/hatchery/hatchery_element_weight.gd src/hatchery/hatchery_pull_table_validation_result.gd src/hatchery/hatchery_pull_table_snapshot.gd src/hatchery/hatchery_preview_result.gd src/hatchery/hatchery_pull_result.gd src/hatchery/hatchery_rng_provider.gd assets/hatchery/pull_tables/standard_hatchery.tres tests/unit/hatchery/test_pull_table_and_result_contracts.gd production/epics/hatchery/story-001-pull-table-and-result-contracts.md`.

Fresh evidence: HATCHERY-001 implemented typed pull-table/result contracts, an authored `standard_hatchery.tres` table, validation results, detached runtime snapshots, and deterministic RNG seams. Review fix added per-rarity element total validation. Focused Hatchery unit suite passes with 8/8 tests and 94 assertions; full Godot/GUT unit + integration suite passes with 165/165 tests and 7,776 assertions. Sprint 04 still needs HATCHERY-001 code review/story-done, SCENE-003 manual launch evidence, BATTLE-007 source/content evidence, smoke check, and QA sign-off before close-out.

<!-- QA RUN: 2026-05-27 | Sprint: sprint-02 | Verdict: APPROVED WITH CONDITIONS | Report: production/qa/qa-signoff-sprint-02-2026-05-27.md -->
<!-- RETRO: 2026-05-27 | Sprint: sprint-02 | Report: production/retrospectives/retro-sprint-02-2026-05-27.md -->
<!-- SPRINT PLAN: 2026-05-27 | Sprint: sprint-03 | Report: production/sprints/sprint-03.md | Producer: CONCERNS addressed -->
<!-- QA-PLAN: 2026-05-27 | System: sprint-03 | Plan written: production/qa/qa-plan-sprint-03-2026-05-27.md -->
<!-- SMOKE: 2026-05-27 | Sprint: sprint-03 | Verdict: PASS WITH WARNINGS | Report: production/qa/smoke-sprint-03-2026-05-27.md -->
<!-- QA RUN: 2026-05-27 | Sprint: sprint-03 | Verdict: APPROVED WITH CONDITIONS | Report: production/qa/qa-signoff-sprint-03-2026-05-27.md -->
<!-- RETRO: 2026-05-27 | Sprint: sprint-03 | Report: production/retrospectives/retro-sprint-03-2026-05-27.md -->
<!-- QA-PLAN: 2026-05-28 | System: sprint-04 | Plan written: production/qa/qa-plan-sprint-04-2026-05-28.md -->
<!-- QA-EVIDENCE: 2026-05-28 | System: sprint-04-battle-delta | Evidence: production/qa/evidence/battle-sprint-04-delta-evidence.md -->
<!-- CREATE-STORIES: 2026-05-28 | Epic: hatchery | Stories: 7 | Path: production/epics/hatchery/ -->
<!-- DEV-STORY: 2026-05-28 | Story: production/epics/hatchery/story-001-pull-table-and-result-contracts.md | Focused: 8/8 tests, 94 assertions | Full: 165/165 tests, 7776 assertions -->

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/battle-engine/story-007-animation-manifest-runtime-lookup.md — Animation Manifest Runtime Lookup
- Acceptance criteria: 4/4 passing.
- Test evidence: focused BATTLE-007 integration suite passed with 7/7 tests and 80 assertions; adjacent Battle animation/content suite passed with 11/11 tests and 65 assertions; Battle Engine integration slice passed with 14/14 tests and 909 assertions; full unit/integration suite passed with 139/139 tests and 7,129 assertions.
- QA coverage gate: ADEQUATE locally; full-mode qa-lead sidecar unavailable due agent thread limit.
- Lead programmer gate: APPROVED via `/code-review`; full-mode lead-programmer sidecar unavailable due agent thread limit.
- Tech debt logged: None.
- Next recommended: `/story-readiness production/epics/battle-engine/story-004-telegraph-defend-and-defrag-delta.md`, then address any remaining BATTLE-004 readiness gaps.

## Session Extract — /dev-story 2026-05-27
- Story: production/epics/battle-engine/story-007-animation-manifest-runtime-lookup.md — Animation Manifest Runtime Lookup
- Status: In Progress; implementation and automated evidence are complete, code review/story closure pending.
- Implementation: added `BattleAnimationLookupResult`, extended `BattleSetupPayload` with typed battle definition / manifest / move-definition inputs, and added BattleSession lookup helpers for action, VFX, receive, hurt, defend-hit, KO, and defend clips through configure-time ID maps. Runtime code contains no authored move/VFX ID branches, snapshots the configured battle definition plus move dictionary against post-start setup mutation, and can disambiguate receive clips by source actor set when move IDs are shared.
- Test written: `tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd` with 7 test functions covering manifest ID lookup, actor/move binding resolution, base reaction clips, receive clips, missing binding errors, setup mutation safety, source-actor disambiguation, and no hardcoded runtime move/VFX IDs.
- Test evidence: focused BATTLE-007 integration suite passed with 7/7 tests and 80 assertions; adjacent Battle animation/content suite passed with 11/11 tests and 65 assertions; Battle Engine integration slice passed with 14/14 tests and 909 assertions; full unit/integration suite passed with 139/139 tests and 7,129 assertions.
- Scope notes: no new art assets, no animation player implementation, and no production content lock expansion beyond existing fixture validation.
- Blockers: None.
- Next recommended: `/code-review src/battle/runtime/battle_session.gd src/battle/runtime/battle_setup_payload.gd src/battle/runtime/battle_animation_lookup_result.gd tests/integration/battle_engine/test_animation_manifest_runtime_lookup.gd production/epics/battle-engine/story-007-animation-manifest-runtime-lookup.md`, then `/story-done production/epics/battle-engine/story-007-animation-manifest-runtime-lookup.md`.

## Session Extract — /dev-story 2026-05-27
- Story: production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md — Production Shell Main Scene Smoke Path
- Files changed: project.godot, scenes/bootstrap/BootstrapRoot.tscn, scenes/hub/HubShell.tscn, src/scene_flow/bootstrap_root.gd, src/scene_flow/hub_shell_screen.gd, tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd, production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md, production/sprint-status.yaml
- Test written: tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd
- Review fixes: direct `boot()` calls now update `get_last_boot_result()`; malformed screen registration config returns a named `scene_registration_failed` / `invalid_registration` result; focus-target assertions no longer dereference before checking type; focus restoration is asserted through `InputRouter.focus_restored`; Sprint 03 smoke evidence records production shell/main-menu as PASS.
- Blockers: None
- Next: /code-review src/scene_flow/bootstrap_root.gd src/scene_flow/hub_shell_screen.gd scenes/bootstrap/BootstrapRoot.tscn scenes/hub/HubShell.tscn project.godot tests/integration/scene_flow/test_production_shell_main_scene_smoke_path.gd production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md then /story-done production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE
- Story: production/epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md — Production Shell Main Scene Smoke Path
- Acceptance criteria: 6/6 passing.
- Test evidence: focused SCENE-003 suite passed with 4/4 tests and 37 assertions; adjacent Scene Flow/bootstrap suites passed with 12/12 tests and 117 assertions; full unit/integration suite passed with 123/123 tests and 6,891 assertions.
- Smoke evidence: `production/qa/smoke-sprint-03-2026-05-27.md` records production shell/main-menu launch as PASS, not DEFERRED.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVED via `/code-review`.
- Tech debt logged: None.
- Next recommended: `/story-readiness production/epics/dragon-progression/story-005-save-load-integrity-and-repair.md`.

## Session Extract — /dev-story 2026-05-27

- Story: production/epics/dragon-progression/story-005-save-load-integrity-and-repair.md — Save Load Integrity And Repair
- Status: Complete as of 2026-05-27.
- Implementation: added `DragonValidationResult` and Dragon Progression load validation helpers for discarding invalid level/XP/element records, rejecting duplicate dragon IDs, enforcing the reserved Void dragon ID both directions, repairing MAX_LEVEL XP/charges, repairing overflow XP with charges reset before the loop, selecting local/cloud conflict winners, preserving reserved Void story records, and deriving post-load stage/stage multiplier snapshots.
- Test written: `tests/integration/dragon/test_save_load_integrity_and_repair.gd` with 4 test functions covering invalid record discard logs, XP repair final states, conflict selection, Void preservation, and derived stage snapshots.
- Test evidence: focused Dragon save/load integrity suite passed with 4/4 tests and 62 assertions; full unit/integration suite passed with 127/127 tests and 6,953 assertions.
- Scope notes: no cloud sync UI prompt, no stage badge presentation, and no battle runtime damage verification implemented.
- Blockers: None.
- Next recommended: `/story-readiness production/epics/battle-engine/story-003-status-and-recoil-effects.md`.

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/dragon-progression/story-005-save-load-integrity-and-repair.md — Save Load Integrity And Repair
- Acceptance criteria: 8/8 passing.
- Test evidence: focused Dragon save/load integrity suite passed with 4/4 tests and 62 assertions; full unit/integration suite passed with 127/127 tests and 6,953 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVED WITH SUGGESTIONS via `/code-review`; full-mode lead-programmer sidecar retry unavailable due thread limit.
- Tech debt logged: None.
- Next recommended: `/story-readiness production/epics/battle-engine/story-003-status-and-recoil-effects.md`.

## Session Extract — /dev-story 2026-05-27
- Story: production/epics/battle-engine/story-003-status-and-recoil-effects.md — Status And Recoil Effects
- Status: In Progress; implementation and review fix evidence are complete, code review/story closure pending.
- Implementation: added runtime-only `CombatantBattleState` and `StatusRuntimeState`, named status apply/recoil result payloads, and BattleSession helpers for deterministic status application, single-slot overwrite, Burn/Poison RECOIL DoT, Freeze/Paralysis TELEGRAPH skips, Guard Break effective defense, and player-then-enemy RECOIL ordering. Review fix clears stale Freeze `pending_skip` when a non-Freeze status overwrites it.
- Test written: `tests/unit/battle_engine/test_status_and_recoil_effects.gd` with 5 test functions covering every story acceptance criterion.
- Test evidence: focused BATTLE-003 unit suite passed with 5/5 tests and 38 assertions; Battle Engine unit/integration slice passed with 17/17 tests and 921 assertions; full unit/integration suite passed with 132/132 tests and 7,013 assertions.
- Scope notes: no status UI/icons, Defrag Patch clearing, presentation profile signals, animation binding, SaveData mutation, or durable settlement added.
- Blockers: None.
- Next recommended: `/code-review src/battle/runtime/battle_session.gd src/battle/runtime/combatant_battle_state.gd src/battle/runtime/status_runtime_state.gd src/battle/runtime/battle_status_apply_result.gd src/battle/runtime/battle_recoil_result.gd tests/unit/battle_engine/test_status_and_recoil_effects.gd production/epics/battle-engine/story-003-status-and-recoil-effects.md`, then `/story-done production/epics/battle-engine/story-003-status-and-recoil-effects.md`.

## Session Extract — /story-done 2026-05-27
- Verdict: COMPLETE WITH NOTES
- Story: production/epics/battle-engine/story-003-status-and-recoil-effects.md — Status And Recoil Effects
- Acceptance criteria: 6/6 passing.
- Test evidence: focused BATTLE-003 unit suite passed with 5/5 tests and 38 assertions; Battle Engine unit/integration slice passed with 17/17 tests and 921 assertions; full unit/integration suite passed with 132/132 tests and 7,013 assertions.
- QA coverage gate: ADEQUATE locally; full-mode qa-lead sidecar unavailable due thread limit.
- Lead programmer gate: APPROVED via `/code-review`; full-mode lead-programmer sidecar unavailable due thread limit.
- Tech debt logged: None.
- Next recommended: `/story-readiness production/epics/battle-engine/story-004-telegraph-defend-and-defrag-delta.md`.

CodeGraph is now usable for GDScript in this project: 74 files, 2,022 nodes, 4,530 edges, 63 GDScript files, index up to date. The old note below saying CodeGraph was unusable is superseded.

## Singularity Blocker Pass — 2026-05-26

Resolved in current pass:

1. Save/Persistence draft created: `design/gdd/save-persistence.md`
   - Defines `SaveData`, atomic transaction flow, temp/backup swap, `ending_id`-only post-game authority, and QA failure injection hooks.
   - Resolves Singularity OQ-SG14 automation blocker.
2. Audio Director draft created: `design/gdd/audio-director.md`
   - Defines buses, event inputs, corruption mix table, Mirror Admin phase audio, and six-semitone tritone counter formula.
3. Input Router draft created: `design/gdd/input-router.md`
   - Defines gamepad-first action map, Godot 4.6 dual-focus handling, d-pad/confirm/cancel completion, and Defend/Counter routing.
4. Journal / Console draft created: `design/gdd/journal.md`
   - Defines `elemental_resonance`, six Stage IV Captain's Log fragment IDs, Forge Console glow signal, and post-game terminal routing.
5. Campaign Map OQ-CM06 reclassified resolved:
   - Hatchery already contains element soft-pity onset 20 / guaranteed 40.
6. Singularity OQ-SG10 reclassified resolved:
   - Authored SCAR node IDs and protected IDs added to Singularity Map Corruption.
7. Systems Index updated:
   - Save/Persistence, Audio Director, Input Router, and Journal / Console moved to **Approved** after lean review.
8. Entity registry updated:
   - Relic descriptions no longer expose "required for ending" framing.
   - Singularity and Save/Persistence added as dragon/relic consumers.
9. Support GDD lean reviews approved:
   - `design/gdd/save-persistence.md`, `design/gdd/audio-director.md`, `design/gdd/input-router.md`, and `design/gdd/journal.md` are Approved in their files and in `design/gdd/systems-index.md`.
   - Review logs were added under `design/gdd/reviews/`.
10. Shop OQ-SH01 checked:
   - Still open. Campaign Map defines per-node fields and Battle Engine return contracts, but no authored Act 3 mandatory-node distribution or playtest economy data exists yet.
11. Architecture handoff started:
   - Accepted ADRs added for save transaction boundaries, semantic event contracts, Input Router semantic actions, and authored content Resources.
   - `docs/architecture/control-manifest.md` added as the current implementation rule sheet.
   - `docs/registry/architecture.yaml` updated with state ownership, interface, API, and forbidden-pattern entries.
12. Singularity lean re-review approved:
   - `design/gdd/singularity.md` is Approved.
   - `design/gdd/systems-index.md` marks Singularity and folded Mirror Admin tracking row as Approved.
   - Review log added at `design/gdd/reviews/singularity-review-log.md`.
13. Cross-GDD review + consistency check completed:
   - `design/gdd/gdd-cross-review-2026-05-26.md` added.
   - `docs/consistency-report-2026-05-26.md` added.
   - Mechanical contradictions resolved in-session across Battle Engine, Campaign Map, Dragon Progression, Shop, Hatchery, Hub, and entity registry.
14. Master architecture drafted:
   - `docs/architecture/architecture.md` added.
   - Covers Godot 4.6 engine risks, provisional technical requirements, layer map, module ownership, data flows, API boundaries, ADR audit, and required ADR backlog.
   - Technical Director self-review verdict: APPROVED WITH CONDITIONS.
   - Lead Programmer feasibility review completed: FEASIBLE WITH CONDITIONS.
   - Follow-up revisions folded into architecture: immutable save snapshots, named payload schemas, Scene Flow API, Authored Content Loader API, and Economy Ledger API.
15. ADR-0005 accepted:
   - `docs/architecture/adr-0005-godot-scene-flow-and-autoload-boundaries.md` Status changed to Accepted.
   - Godot specialist verdict: Accept with minor clarifications.
   - Technical Director verdict: Accept with conditions.
   - Required review conditions folded into the ADR: AudioDirector remains Presentation, `ScreenTransitionPayload`, safe transition failure behavior, save/event ordering, authored screen IDs, and top-level-only SceneFlow scope.
   - Architecture registry and control manifest updated with SceneFlow and service-boundary stances.
16. ADR-0006 accepted:
   - `docs/architecture/adr-0006-dragon-data-model-and-progression-services.md` Status changed to Accepted.
   - Godot specialist required revisions folded in: no progression signals inside staged `apply_xp()`, service is not a saved Resource/global Autoload, dragon events carry both `dragon_id` and `element`, mutable snapshots forbidden, and explicit runtime guards replace `assert()`.
   - Technical Director required revisions folded in: active/passive Resonance charge mutation goes through Dragon Progression helpers, `stage` is derived not persisted, Elder multiplier authority remains Fusion/Battle, source-specific creation helpers defined, and named result types required.
   - Architecture registry and control manifest updated with canonical `dragon_id`, derived `stage`, typed result, snapshot, and progression-event stances.
17. ADR-0007 accepted:
   - `docs/architecture/adr-0007-battle-runtime-state-machine.md` Status changed to Accepted.
   - Drafted around a scene-local/runtime-only Battle session, typed payloads, TELEGRAPH-only semantic input, settlement payloads/deltas instead of direct save writes, Campaign Map/Singularity reward ownership, Defrag Patch durable delta reporting, and continuous Mirror Admin phase swaps.
   - Architecture registry and control manifest updated with Battle runtime ownership, settlement, Mirror Admin checkpoint, and forbidden direct-commit stances.
18. ADR-0008 accepted:
   - `docs/architecture/adr-0008-campaign-map-content-and-reward-pipeline.md` added with Status: Accepted.
   - Godot specialist verdict: Accept with conditions; revisions folded in for deferred Matrix stabilization transactions, named settlement event payloads, and immutable authored map Resources.
   - Technical Director verdict: Accept with conditions; revisions folded in for passive bench Resonance on defeat, Scrap reward authority, OQ-SH01 pass threshold, and BOSS clear-state ownership.
   - Campaign Map GDD updated so Singularity bosses use Singularity flags rather than Campaign Map `cleared_bosses[]`.
19. ADR-0009 accepted:
   - `docs/architecture/adr-0009-economy-and-shop-transaction-boundaries.md` added with Status: Accepted.
   - Godot specialist revisions folded in for named `PurchaseFlagResult`, immutable catalog Resources, and explicit dependency injection/setup for `ShopService`.
   - Technical Director revisions folded in through registry/control-manifest sync for `player_scraps`, expedition item flags, relic flags, Campaign settlement, and Economy/Shop boundaries.
20. Singularity Mirror Admin persistence wording synced:
   - `design/gdd/singularity.md` now follows the ADR-0007 phase-checkpoint model when CRITICAL/BREACH are committed mid-fight.
   - Reload after a successful phase checkpoint resumes from latest committed checkpoint; committing corruption without checkpoint data is invalid.
21. Technical setup blocker remediation completed:
   - `design/art/art-bible.md` added with Sections 1-4.
   - ADR-0010 Singularity Boss And Ending Orchestration accepted.
   - ADR-0011 Corruption Rendering Pipeline accepted after Godot specialist review notes were folded in.
   - `docs/registry/architecture.yaml`, `docs/architecture/control-manifest.md`, and `docs/architecture/architecture.md` synced through ADR-0011.
   - ADR-0001 through ADR-0004 retrofitted with `## Engine Compatibility` and `## ADR Dependencies`.
   - Stale approved-GDD wording cleaned across Shop, Campaign Map, Battle Engine, Dragon Progression, and Singularity.
   - `project.godot` added; GUT v9.6.0 installed at `addons/gut/`; CI uses official GUT command-line runner after a Godot import.

## Shop GDD — Revision 2 (2026-05-24)

All 13 blockers from the NEEDS REVISION re-review resolved:

1. DWELL_REVEAL threshold: 300ms → 400ms (state machine, UI Requirements, Tuning Knobs, AC-SH48/49)
2. CONFIRMING dialog: full item description added (identical to DWELL_REVEAL text)
3. Defrag Patch: "most recently applied" selection rule added to item catalog + Cross-GDD Contracts
4. Cache Shard formula: INT_MAX removed; explicit Stage IV early-return branch; implicit flat-cost assumption documented
5. xp_threshold_for(): declared as required public export from Dragon Progression in Cross-GDD Contracts
6. ALREADY_OWNED dismiss: AC-SH13 rewritten with "any face button (A/B/X/Y)" + debug precondition
7. AC-SH09/10: rewritten as force-quit atomicity test (observable by QA)
8. AC-SH02: rewritten — "interaction prompt does not render" (observable signal)
9. AC-SH13: rewritten with debug fixture precondition + pass criterion
10. AC-SH16: rewritten; flags Save/Persistence debug hook dependency; covers both rollback sub-paths
11. Missing ACs: AC-SH52 (CONFIRMING balance arithmetic) + AC-SH53 (d-pad edge stops) added; INSUFFICIENT_FUNDS exit added to AC-SH17
12. Ordering constraint #3: EMERGENCY_PATCH_PRICE must always be below FIELD_KIT_PRICE
13. Unit 01 Voice Profile: full section added (knowledge state, per-state register table, prohibitions)

Advisory also resolved:
- Cache Shard grey-out ownership → Campaign Map (EC-3.1, EC-3.2 updated)
- Sink-competition design intent and bad-luck floor decisions documented
- DWELL_REVEAL_THRESHOLD marked as player accessibility setting
- Party array length-3 guarantee documented in Field Kit formula
- AC-SH48/49 manual proxy vs. automated boundary test clarified

## Open Items

- [ ] Targeted re-review: `/design-review design/gdd/shop.md` (new session — use `--depth lean` or spawn only ux-designer + qa-lead)
- [ ] OQ-SH01: BOSS_SCRAP_BONUS / HAZARD_SCRAP_BONUS validation — blocked on authored Campaign Map node distribution and playtest economy data
- [x] OQ-SH03: Battle Engine forward contract for Defrag Patch TELEGRAPH action
- [x] OQ-SH04: Unit 01 dialogue lines (Writer GDD; voice profile now spec'd in shop.md)
- [x] Review newly drafted GDDs: save-persistence, audio-director, input-router, journal
- [ ] Design remaining GDDs: armor-system
- [x] Cross-GDD review: `/review-all-gdds`
- [x] Consistency check: `/consistency-check`
- [ ] Create economy/content lock artifact before production balance lock
- [ ] Validate single-active-dragon carry and cross-element Fusion value in simulation/playtest
- [x] Create ADRs (Step 2c)
- [x] Run /create-control-manifest (Step 2d)
- [x] Lead Programmer feasibility review for `docs/architecture/architecture.md`
- [x] Write/accept required core ADRs from `docs/architecture/architecture.md`
- [x] Accept ADR-0005 and update architecture registry/control manifest with its stances
- [x] Accept ADR-0006 and sync registry/control-manifest wording for `dragon_id` and derived `stage`
- [x] Accept ADR-0007 and update architecture registry/control manifest with battle runtime stances
- [x] Accept ADR-0008 and update architecture registry/control manifest with Campaign Map content/reward stances
- [x] Accept ADR-0009 and update architecture registry/control manifest with Economy/Shop transaction stances
- [x] Accept ADR-0010 and update architecture registry/control manifest with Singularity boss/ending stances
- [x] Accept ADR-0011 and update architecture registry/control manifest with corruption rendering stances
- [x] Clean up remaining approved-GDD wording now superseded by ADR-0006/0007/0008/0009/0010/0011, especially direct Battle writes, direct `battle_charges` mutation, direct expedition-flag writes, direct Scrap mutation phrasing, and rendering ownership
- [x] Run `/architecture-review`
- [x] Run `/test-setup`
- [x] Run `/ux-design`
- [x] Run `/gate-check technical-setup`
- [x] Rerun `/architecture-review` after blocker remediation
- [x] Rerun `/gate-check technical-setup` after fresh architecture review
- [x] Correct stage marker to Pre-Production
- [x] Start `/vertical-slice` with standalone Godot scaffold
- [x] Create follow-up ADRs before stories for partially covered systems

## Systems Index Status

- Shop: **Approved** (Revision 4 — 2026-05-26)
- Campaign Map: **Approved** (Revision 5 — 2026-05-24)
- All others: see design/gdd/systems-index.md

## Key Design Decisions (Shop)

- Defrag Patch selection: most recently applied status effect (automatic, no sub-menu)
- DWELL_REVEAL: 400ms threshold, exposed as player accessibility setting
- CONFIRMING dialog: includes full description for all items
- Stage IV cache shard: explicit early-return branch (no INT_MAX sentinel)
- Unit 01 register: transactional/neutral; no emotion; cannot speculate about relic purpose
- Price ladder (175/200/225): intentionally inverted from ending weight — cheapest relic = bleakest ending (Total Restore) — deliberate design, not a bug

## Consistency Check — 2026-05-24

<!-- CONSISTENCY-CHECK: 2026-05-24 | GDDs checked: 7 | Conflicts found: 0 | Stale registry entries: 1 (resolved) -->

- Verdict: **PASS** — 0 conflicts across 36 registry entries × 7 GDDs
- Stale entry resolved: `DWELL_REVEAL_THRESHOLD` updated from 300→400ms, safe_range "150–500 ms" → "300–600 ms"
- 3 unverifiable references (forward contracts, not conflicts): ELDER_STAGE_MULT in battle-engine, EMERGENCY_PATCH_FACTOR in campaign-map, Void element type chart gap

## Session Extract — /architecture-review 2026-05-26

- Verdict: CONCERNS
- Requirements: 39 total — 25 covered, 13 partial, 1 gap
- New TR-IDs registered: 39
- GDD revision flags: shop.md, campaign-map.md, battle-engine.md, dragon-progression.md, singularity.md
- Top ADR gaps: Singularity Boss And Ending Orchestration; Corruption Rendering Pipeline; Hatchery Pull Transaction And RNG Boundaries
- Report: docs/architecture/architecture-review-2026-05-26.md

## Session Extract — /test-setup, /ux-design, /gate-check technical-setup 2026-05-26

- Test scaffold added: `tests/unit/`, `tests/integration/`, `tests/smoke/`, `tests/evidence/`, `tests/unit/example/test_smoke_example.gd`, `.github/workflows/tests.yml`.
- UX/accessibility scaffold added: `design/accessibility-requirements.md`, `design/ux/interaction-patterns.md`, `design/ux/hud.md`.
- Canonical `.Codex/docs/` handoff files restored from `.claude/docs/`.
- Gate report: `production/gates/technical-setup-gate-2026-05-26.md`.
- Gate verdict: **FAIL**.
- Hard blockers: missing `design/art/art-bible.md`, missing Singularity orchestration ADR, missing Corruption Rendering Pipeline ADR, ADR-0001 through ADR-0004 need Engine Compatibility sections, stale GDD wording remains, and GUT/project root are not executable yet.
- Remediation pass: hard blockers now addressed; the remaining gate step is to rerun `/architecture-review` and then `/gate-check technical-setup`.
- Test command evidence: `godot --headless --import` followed by `godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit` passes locally with 1 script, 1 test, and 1 assertion under Godot 4.6.3 / GUT 9.6.0.

## Session Extract — /architecture-review 2026-05-26 rerun

- Verdict: CONCERNS.
- Requirements at rerun time: 39 total — 31 covered, 8 partial, 0 gaps. After follow-up ADRs later in this session: 38 covered, 1 partial, 0 gaps.
- New TR-IDs registered: None.
- GDD revision flags: None.
- Top ADR gaps: None for Technical Setup gate. Follow-up ADRs for Hatchery, Fusion, Journal / Console, and Audio were completed later in this session.
- Engine specialist consultation: CONCERNS with no blockers; ADR-0011/control manifest updated to distinguish Forward+ rendering method, Windows D3D12 default backend, explicit Vulkan pinning if required, and OpenGL3 fallback evidence.
- Report: `docs/architecture/architecture-review-2026-05-26.md`.

## Session Extract — /gate-check technical-setup 2026-05-26 rerun

- Verdict: PASS.
- Director panel: Creative Director READY; Technical Director READY; Producer READY; Art Director READY.
- Required artifacts: 13 / 13 present.
- Quality checks: passed for core ADR coverage, technical preferences, accessibility tier, UX seed, ADR sections, deprecated API avoidance, high-risk engine domains, zero Foundation gaps, ADR dependency cycles, and executable GUT test setup.
- Carry-forward concerns at the time of the gate rerun: `production/stage.txt` still said `Production`, and implementation stories for Hatchery, Fusion, Journal / Console, or Audio Director needed follow-up ADRs first. Both were resolved later in this session.
- Report: `production/gates/technical-setup-gate-2026-05-26.md`.

## Session Extract — Pre-Production start 2026-05-26

- Stage corrected: `production/stage.txt` now says `Pre-Production`.
- Vertical slice started at `prototypes/dragon-forge-vertical-slice/`.
- Validation question: Does a player experience the hatch -> map -> battle -> reward Dragon Forge loop within 3-5 minutes without guidance?
- Slice scope: Forge Hub start, Root Egg hatch, Village Edge HAZARD node, one TELEGRAPH battle, Data Scrap reward, return to Forge.
- Current vertical slice status: ACCEPTABLE FOR PRE-PRODUCTION REPORTING after Revision 4X human retest. First playable scaffold parses under Godot 4.6.3, smoke runner reaches complete state with 65 Data Scraps, and user completed the original loop in under 1 minute. Revisions 1-4G improved mechanics, DragonSim asset integration, battle feedback, audio hooks, and explicit lore text; Revisions 4I-4X addressed representative visuals, Root/Admin battle assets, attack/reaction coverage, enemy-warning copy, audible scene-swapped music, raw WAV loop setup, and battle music tension. Final acceptance is recorded in `prototypes/dragon-forge-vertical-slice/PLAYTEST.md` and `production/playtests/playtest-2026-05-27-scott-vertical-slice.md`. A production carry-forward requirement now lives at `design/art/battle-animation-coverage.md`: every attack, defense, status, hurt, KO, and boss special for every dragon/NPC must have its own tracked animation coverage before implementation-ready combat stories. The schema now lives at `docs/architecture/battle-animation-manifest-schema.md`, and ADR-0007/control-manifest/architecture-registry require BattleDefinition + MoveDefinition to resolve actor/action clips through BattleAnimationManifest rather than hardcoded sprite branches. The old placeholder generator is guarded against accidental overwrite. Next action: move from slice patching into Pre-Production planning with `/create-epics`, then `/create-stories`, then `/sprint-plan`.
- Battle animation manifest implementation: initial Godot Resource classes now live under `src/battle/animation/` and `src/battle/data/`, with validator coverage at `tests/unit/battle/test_battle_animation_manifest_validator.gd`. The validator ties `BattleDefinition.animation_manifest_id`, resolved actor animation set IDs, and `MoveDefinition` move/action/class IDs to `BattleAnimationManifest` bindings; it fails missing base reaction clips, missing move bindings, wrong action classes, placeholder production bindings, manifest-ID mismatches, missing clip assets, missing preview evidence, and missing runtime capture evidence.
- First authored battle content fixture: `assets/battle/animation_manifests/root_wyrmling_vs_admin_protocol.tres`, `assets/battle/battles/village_edge_admin_protocol.tres`, and move Resources for Root Spark, Thorn Surge, Guarded Spark, and Data Leak now validate against real promoted frame-sequence sprites, dedicated generated reaction strips, preview sheets, VFX, and runtime captures. Test: `tests/integration/battle/test_root_admin_animation_content.gd`.
- Vertical-slice manifest runtime pass: `prototypes/dragon-forge-vertical-slice/assets/battle/` mirrors the Root/Admin fixture with prototype-local Resource scripts under `prototypes/dragon-forge-vertical-slice/src/battle_content/` to avoid duplicate root-project class registrations. `VerticalSliceController.gd` now resolves battle clip/VFX keys through the manifest for Root Spark, Thorn Surge, Guarded Spark, Data Leak, idle, telegraph, hurt, defend-hit, and KO presentation. The smoke test verifies manifest key resolution before completing the hatch -> map -> battle -> reward loop.
- CodeGraph status: usable for this Godot codebase after the 2026-05-27 repair. CodeGraph 0.9.6 now has a local lightweight GDScript extractor patch, `.gd` / `.gdshader` indexing works, `addons/gut` is filtered out, and `codegraph status /Users/Scott_1/df` reports 74 files, 2,022 nodes, 4,530 edges, and 63 GDScript files indexed. Caveat: the extractor is patched into the global CodeGraph install and may need reapplying after a future global npm update.
- Follow-up ADRs accepted before stories:
  - ADR-0012 Hatchery Pull Transaction And RNG Boundaries
  - ADR-0013 Fusion Anvil Transaction Boundaries
  - ADR-0014 Journal Console And Lore Delivery Resources
  - ADR-0015 Audio Event Routing And Mix Ownership
- Traceability updated: 39 requirements — 38 covered, 1 partial, 0 gaps. Remaining partial: Hub presentation composition, accepted as story-level unless implementation reveals hidden ownership.
- Pre-Production backlog status: Foundation epics and stories are now created for Save / Persistence, Input Router, Authored Content Registry, Scene Flow / Boot Pipeline, and Semantic Events / Payload Contracts. Sprint 01 planning is recorded in `production/sprints/sprint-01.md`, with machine-readable status in `production/sprint-status.yaml`. Producer sidecar review marked the scope feasible with medium integration risk and recommended deferring Core/Feature systems until this foundation path is stable. Next required action before implementation: run `/qa-plan sprint`, then `/story-readiness production/epics/save-persistence/story-001-save-data-resource.md`, then `/dev-story production/epics/save-persistence/story-001-save-data-resource.md`.
- QA planning status: Sprint 01 QA plan written to `production/qa/qa-plan-sprint-01-2026-05-27.md`. Story classifications are 4 Logic, 6 Integration, and 2 UI evidence stories. Next required action is story-readiness for `production/epics/save-persistence/story-001-save-data-resource.md`.
- Dev story status: `production/epics/save-persistence/story-001-save-data-resource.md` passed story-readiness and is In Progress. Implementation added `src/save/save_data.gd` plus `tests/unit/save/test_save_data_resource.gd`; the focused save unit suite and full unit/integration GUT suite pass locally. Next required action is `/code-review src/save/save_data.gd tests/unit/save/test_save_data_resource.gd`, then `/story-done production/epics/save-persistence/story-001-save-data-resource.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/save-persistence/story-001-save-data-resource.md` — SaveData Resource
- Implementation: `src/save/save_data.gd`, `src/dragon/dragon_record.gd`, `tests/unit/save/test_save_data_resource.gd`
- Test evidence: focused save suite passed with 9/9 tests and 203 assertions; full import-plus-unit/integration suite passed with 21/21 tests and 269 assertions.
- Code review: lead-programmer CONCERNS with no blockers; documentation and stale evidence-count concerns resolved before closure.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/save-persistence/story-002-save-transaction-commit-rollback.md`

## Session Extract — /dev-story 2026-05-27

- Story: `production/epics/save-persistence/story-002-save-transaction-commit-rollback.md` — Save Transaction Commit And Rollback
- Status: In Progress
- Implementation: `src/save/save_service.gd`, `src/save/save_transaction.gd`, `src/save/save_commit_result.gd`, and `tests/integration/save/test_save_transaction_commit_rollback.gd`
- Scope: SaveService now configures a canonical slot path, initializes a slot, opens isolated staged SaveTransaction copies using `duplicate_deep()`, commits via temp/backup/swap/reload validation, and supports debug failure injection for `after_temp_write_before_swap`.
- Test evidence: focused save transaction suite passed with 4/4 tests and 51 assertions; full import-plus-unit/integration suite passed with 25/25 tests and 320 assertions.
- Code review follow-up: SaveService now rejects invalid transaction objects before property access, returns typed SaveCommitResult values, types staged SaveData/SaveTransaction surfaces, and splits commit validation/temp-write/swap flow into smaller helpers.
- Notes: Temp and backup files use `*.tmp.tres` and `*.bak.tres` so Godot ResourceSaver/ResourceLoader keep a resource extension while preserving temp/backup semantics.
- Next recommended: `/code-review src/save/save_service.gd src/save/save_transaction.gd src/save/save_commit_result.gd tests/integration/save/test_save_transaction_commit_rollback.gd production/epics/save-persistence/story-002-save-transaction-commit-rollback.md`, then `/story-done production/epics/save-persistence/story-002-save-transaction-commit-rollback.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/save-persistence/story-002-save-transaction-commit-rollback.md` — Save Transaction Commit And Rollback
- Acceptance criteria: 3/3 passing, covered by `tests/integration/save/test_save_transaction_commit_rollback.gd`
- Test evidence: focused save transaction suite passed with 4/4 tests and 51 assertions; full import-plus-unit/integration suite passed with 25/25 tests and 320 assertions.
- Code review: initial CHANGES REQUIRED; required changes resolved before closure.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md`, then `/dev-story production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md`.

## Session Extract — /dev-story 2026-05-27

- Story: `production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md` — Commit Signals And Failure Hooks
- Status: In Progress
- Implementation: `src/save/save_service.gd` and `tests/integration/save/test_commit_signals_and_failure_hooks.gd`
- Scope: SaveService now emits `save_committed(result)` exactly once after successful commit promotion/reload validation, emits `save_failed(result)` on failed commit results, keeps `initialize_slot()` quiet, and gates failure injection behind `OS.is_debug_build()`.
- Test evidence: focused commit signal/failure hook suite passed with 4/4 tests and 18 assertions; full import-plus-unit/integration suite passed with 29/29 tests and 338 assertions.
- Notes: Signal tests disconnect lambda callables after commit to avoid RefCounted signal/capture cycles during GUT shutdown.
- Next recommended: `/code-review src/save/save_service.gd tests/integration/save/test_commit_signals_and_failure_hooks.gd production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md`, then `/story-done production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/save-persistence/story-003-commit-signals-and-failure-hooks.md` — Commit Signals And Failure Hooks
- Acceptance criteria: 3/3 passing, covered by `tests/integration/save/test_commit_signals_and_failure_hooks.gd`
- Test evidence: focused commit signal/failure hook suite passed with 4/4 tests and 18 assertions; full import-plus-unit/integration suite passed with 29/29 tests and 338 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/input-router/story-001-semantic-action-router.md`, then `/dev-story production/epics/input-router/story-001-semantic-action-router.md`.

## Session Extract — /dev-story 2026-05-27

- Story: `production/epics/input-router/story-001-semantic-action-router.md` — Semantic Action Router
- Status: In Progress
- Implementation: `src/input/input_router.gd`, `src/input/semantic_action_payload.gd`, and `tests/unit/input/test_semantic_action_router.gd`
- Scope: InputRouter now ensures canonical MVP InputMap action IDs, routes active-context input events into semantic payloads, exposes UI/Battle/Campaign Map contexts, tracks coarse input mode, and keeps raw hardware details out of feature-facing payloads.
- Test evidence: focused semantic action router suite passed with 5/5 tests and 57 assertions; full import-plus-unit/integration suite passed with 34/34 tests and 395 assertions.
- Notes: InputRouter extends Node so it can be promoted to a Foundation Autoload in the bootstrap story.
- Next recommended: `/code-review src/input/input_router.gd src/input/semantic_action_payload.gd tests/unit/input/test_semantic_action_router.gd production/epics/input-router/story-001-semantic-action-router.md`, then `/story-done production/epics/input-router/story-001-semantic-action-router.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/input-router/story-001-semantic-action-router.md` — Semantic Action Router
- Acceptance criteria: 3/3 passing, covered by `tests/unit/input/test_semantic_action_router.gd`
- Test evidence: focused semantic action router suite passed with 6/6 tests and 72 assertions; full import-plus-unit/integration suite passed with 35/35 tests and 410 assertions.
- Code review: APPROVED after tightening MVP default keyboard/gamepad bindings and typing `semantic_action(payload)` as `SemanticActionPayload`.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/input-router/story-003-godot-46-dual-focus.md`, then `/dev-story production/epics/input-router/story-003-godot-46-dual-focus.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/input-router/story-003-godot-46-dual-focus.md` — Godot 4.6 Dual Focus
- Acceptance criteria: 3/3 passing, covered by `tests/unit/input/test_dual_focus_input_router.gd` and `production/qa/evidence/input-dual-focus-evidence.md`
- Implementation: `src/input/input_router.gd`, `tests/unit/input/test_dual_focus_input_router.gd`, `production/qa/evidence/input-dual-focus-evidence.md`
- Test evidence: focused dual-focus suite passed with 3/3 tests and 25 assertions; input unit suite passed with 9/9 tests and 97 assertions; full import-plus-unit/integration suite passed with 38/38 tests and 435 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/authored-content-registry/story-001-content-registry-validation.md`, then `/dev-story production/epics/authored-content-registry/story-001-content-registry-validation.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/authored-content-registry/story-001-content-registry-validation.md` — Content Registry Validation
- Acceptance criteria: 4/4 passing, covered by `tests/unit/content/test_content_registry_validation.gd`
- Implementation: `src/content/content_definition.gd`, `src/content/content_registry.gd`, `src/content/content_registry_validation_result.gd`, `tests/unit/content/test_content_registry_validation.gd`
- Test evidence: focused content registry suite passed with 6/6 tests and 49 assertions; full import-plus-unit/integration suite passed with 44/44 tests and 484 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/scene-flow/story-001-scene-flow-safe-transitions.md`, then `/dev-story production/epics/scene-flow/story-001-scene-flow-safe-transitions.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/scene-flow/story-001-scene-flow-safe-transitions.md` — Scene Flow Safe Transitions
- Acceptance criteria: 4/4 passing, covered by `tests/integration/scene_flow/test_scene_flow_safe_transitions.gd`
- Implementation: `src/scene_flow/scene_flow_service.gd`, `src/scene_flow/scene_change_result.gd`, `tests/integration/scene_flow/test_scene_flow_safe_transitions.gd`, `tests/fixtures/scene_flow/setup_failure_screen.gd`
- Test evidence: focused scene-flow integration suite passed with 5/5 tests and 54 assertions; full import-plus-unit/integration suite passed with 49/49 tests and 538 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Sprint 01 must-have status: COMPLETE — SAVE-001, SAVE-002, SAVE-003, INPUT-001, INPUT-003, CONTENT-001, and SCENE-001 are all done.
- Next recommended: decide whether "done" means stop at Sprint 01 must-haves or continue into should-have stories: SCENE-002, EVENTS-001, and INPUT-002.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/scene-flow/story-002-bootstrap-service-order.md` — Bootstrap Service Order
- Acceptance criteria: 4/4 passing, covered by `tests/integration/bootstrap/test_bootstrap_service_order.gd`
- Implementation: `src/scene_flow/bootstrap_root.gd`, `src/scene_flow/bootstrap_result.gd`, `tests/integration/bootstrap/test_bootstrap_service_order.gd`, `tests/fixtures/bootstrap/bootstrap_focus_screen.gd`
- Test evidence: focused bootstrap suite passed with 3/3 tests and 26 assertions; full import-plus-unit/integration suite passed with 52/52 tests and 564 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Roadmap sidecar: Producer agent recommends EVENTS-001 next, then INPUT-002; SAVE-004 and INPUT-004 are timing-dependent nice-to-haves.
- Next recommended: `/story-readiness production/epics/semantic-events/story-001-semantic-event-contract-harness.md`, then `/dev-story production/epics/semantic-events/story-001-semantic-event-contract-harness.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/semantic-events/story-001-semantic-event-contract-harness.md` — Semantic Event Contract Harness
- Acceptance criteria: 4/4 passing, covered by `tests/integration/events/test_semantic_event_contract_harness.gd`
- Implementation: `src/events/semantic_event_contract.gd`, `src/events/semantic_event_payload.gd`, `src/events/semantic_event_emit_result.gd`, `tests/integration/events/test_semantic_event_contract_harness.gd`
- Test evidence: focused semantic event suite passed with 5/5 tests and 72 assertions; full import-plus-unit/integration suite passed with 57/57 tests and 636 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/input-router/story-002-dpad-confirm-cancel-flows.md`, then `/dev-story production/epics/input-router/story-002-dpad-confirm-cancel-flows.md`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/input-router/story-002-dpad-confirm-cancel-flows.md` — D-Pad Confirm Cancel Flows
- Acceptance criteria: 3/3 passing, covered by `tests/unit/input/test_dpad_confirm_cancel_contract.gd` and `production/qa/evidence/input-dpad-confirm-cancel-evidence.md`
- Implementation: `src/input/focus_navigation_contract.gd`, `tests/unit/input/test_dpad_confirm_cancel_contract.gd`, `production/qa/evidence/input-dpad-confirm-cancel-evidence.md`
- Test evidence: focused d-pad contract suite passed with 4/4 tests and 58 assertions; full import-plus-unit/integration suite passed with 61/61 tests and 694 assertions.
- Code review: APPROVED.
- Tech debt logged: None
- Sprint 01 should-have status: COMPLETE — SCENE-002, EVENTS-001, and INPUT-002 are all done.
- Next recommended: Continue nice-to-haves if desired: `production/epics/save-persistence/story-004-ending-id-load-projection.md`, then `production/epics/input-router/story-004-contextual-counter-routing.md`.

## Session Extract — /dev-story 2026-05-27

- Story: `production/epics/save-persistence/story-004-ending-id-load-projection.md` — Ending ID Load Projection
- Status: In Progress
- Readiness verdict: READY — accepted ADR-0001, current control manifest, dependency Story 001 complete, integration evidence path declared.
- Implementation plan: add a read-only load projection for Campaign Map post-game entry, preserving `ending_id` as the only persistent post-game authority and forbidding serialized `game_state`.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/save-persistence/story-004-ending-id-load-projection.md` — Ending ID Load Projection
- Acceptance criteria: 2/2 passing, covered by `tests/integration/save/test_ending_id_load_projection.gd`.
- Implementation: `src/save/save_state_projection.gd`, `src/save/save_service.gd`, `src/scene_flow/bootstrap_root.gd`, plus integration test updates that verify saved files directly instead of public mutable reads.
- Code review: CHANGES REQUIRED initially from GDScript specialist; blockers resolved by making canonical save loading internal, typing projection inputs, resetting projection state on configure, and updating story evidence status.
- Test evidence: focused save integration suite passed with 13/13 tests and 111 assertions; bootstrap suite passed with 3/3 tests and 26 assertions; full import-plus-unit/integration suite passed with 66/66 tests and 736 assertions.
- Next recommended: tighten `production/epics/input-router/story-004-contextual-counter-routing.md` acceptance/evidence coverage, then implement it as the last Sprint 01 nice-to-have.

## Session Extract — /dev-story 2026-05-27

- Story: `production/epics/input-router/story-004-contextual-counter-routing.md` — Contextual Counter Routing
- Status: In Progress
- Readiness repair: added four testable integration acceptance criteria and expanded QA cases for tritone-open, tritone-closed, disabled Defend, and no `battle_counter` action.
- Implementation boundary: input routing contract only; Mirror Admin phase behavior, Counter damage/effects, and battle legality remain out of scope.

## Session Extract — /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/input-router/story-004-contextual-counter-routing.md` — Contextual Counter Routing
- Acceptance criteria: 4/4 passing, covered by `tests/integration/input/test_contextual_counter_routing.gd`.
- Implementation: `src/input/input_router.gd` and `tests/integration/input/test_contextual_counter_routing.gd`.
- Code review: APPROVED WITH ISSUES initially from GDScript specialist; issues resolved by removing router-owned `tritone_window` state, keeping tritone timing with Singularity/Battle, tightening explicit typing, and updating story evidence.
- Test evidence: focused contextual counter suite passed with 4/4 tests and 33 assertions; input unit suite passed with 13/13 tests and 155 assertions; full import-plus-unit/integration suite passed with 70/70 tests and 769 assertions.
- Sprint 01 status: COMPLETE — all must-have, should-have, and nice-to-have stories are done.
- Next recommended: run `/team-qa sprint` or `/smoke-check`, then use `/sprint-status` and plan the next sprint from Core/Foundation follow-on stories.

<!-- QA RUN: 2026-05-27 | Sprint: sprint-01 | Verdict: APPROVED WITH CONDITIONS | Report: production/qa/qa-signoff-sprint-01-2026-05-27.md -->

## Session Extract — /create-epics layer: core 2026-05-27

- Verdict: COMPLETE
- Core epics created:
  - `production/epics/dragon-progression/EPIC.md`
  - `production/epics/economy-ledger/EPIC.md`
  - `production/epics/battle-engine/EPIC.md`
  - `production/epics/hatchery/EPIC.md`
  - `production/epics/fusion-engine/EPIC.md`
- `production/epics/index.md` now lists Core layer rows after the completed Foundation epics.
- Scope note: story files were intentionally not created in this pass. Run `/create-stories` per epic before Sprint 02 planning references implementation work.
- Review-mode note: `production/review-mode.txt` is `full`, but producer sidecar spawning was unavailable because the thread had already reached its agent limit; the local feasibility stance remains that Sprint 02 should start with Dragon Progression, Economy Ledger, and Battle Engine stories before Hatchery/Fusion implementation.
- Next recommended: `/create-stories dragon-progression`, then `/create-stories economy-ledger`, then `/create-stories battle-engine`.

## Session Extract — Core stories and Sprint 02 plan 2026-05-27

- Verdict: COMPLETE
- Created story files for three Core epics:
  - Dragon Progression: 7 stories (`DRAGON-001` through `DRAGON-007`)
  - Economy Ledger: 4 stories (`ECO-001` through `ECO-004`)
  - Battle Engine: 7 stories (`BATTLE-001` through `BATTLE-007`)
- Updated epic files with story tables:
  - `production/epics/dragon-progression/EPIC.md`
  - `production/epics/economy-ledger/EPIC.md`
  - `production/epics/battle-engine/EPIC.md`
- Updated `production/epics/index.md` story counts. At the time, Hatchery and Fusion Engine still had no story files; Hatchery stories were later generated on 2026-05-28.
- Sprint 02 planned at `production/sprints/sprint-02.md`; machine-readable current sprint state updated in `production/sprint-status.yaml`.
- Sprint 02 Must Have path:
  - `DRAGON-001` Stats, Stage, And Record Contract
  - `DRAGON-002` XP Loop And Resonance
  - `DRAGON-003` Post-Commit Progression Events
  - `ECO-001` Scrap Read, Affordability, And Results
  - `ECO-002` Scrap Spend Transaction Boundary
  - `BATTLE-001` Runtime Session And Payload Contracts
- Sprint 02 QA plan is now written at `production/qa/qa-plan-sprint-02-2026-05-27.md`. Next required action before implementation: `/story-readiness production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md`.
- Review-mode note: full sidecar gates were not spawned in this pass because the thread previously hit the agent limit. Use explicit `/code-review` and `/story-done` gates per story, or a fresh thread if full director sidecars are required.

<!-- QA-PLAN: 2026-05-27 | System: sprint-02 | Plan written: production/qa/qa-plan-sprint-02-2026-05-27.md -->

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md` - Stats, Stage, And Record Contract
- Status: In Progress; implementation complete and ready for `/code-review`.
- Implementation: added `src/dragon/dragon_stats.gd` and `src/dragon/dragon_progression_service.gd`.
- Test evidence: added `tests/unit/dragon/test_stats_stage_and_record_contract.gd`.
- Coverage: canonical level-1 stats for Fire/Ice/Storm/Stone/Venom/Shadow/Void, representative level/shiny formula outputs, monotonic and shiny-greater checks, floor order, stage boundaries and multipliers, SPD internal computation, defensive invalid level/element/shiny-multiplier calls, and no persisted `stage`.
- Verification: focused Dragon Progression suite passed with 7/7 tests and 4,627 assertions; full import plus unit/integration suite passed with 77/77 tests and 5,396 assertions.
- Next recommended: `/code-review src/dragon/dragon_stats.gd src/dragon/dragon_progression_service.gd tests/unit/dragon/test_stats_stage_and_record_contract.gd production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md`, then `/story-done production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/dragon-progression/story-001-stats-stage-and-record-contract.md` - Stats, Stage, And Record Contract
- Acceptance criteria: 7/7 passing, covered by `tests/unit/dragon/test_stats_stage_and_record_contract.gd`.
- Implementation: `src/dragon/dragon_stats.gd` and `src/dragon/dragon_progression_service.gd`.
- Test evidence: focused Dragon Progression suite passed with 7/7 tests and 4,627 assertions; full import plus unit/integration suite passed with 77/77 tests and 5,396 assertions.
- Code review: APPROVED; no required changes.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/dragon-progression/story-002-xp-loop-and-resonance.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/dragon-progression/story-002-xp-loop-and-resonance.md` - XP Loop And Resonance
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Implementation: `DragonProgressionService.apply_xp()` now applies XP only inside active staged `SaveTransaction` data, clamps awards to `XP_MAX_AWARD`, truncates float XP, rejects negative XP without mutation, preserves XP remainders, clears XP/charges at `MAX_LEVEL`, consumes Resonance charges one per level gained, and returns typed `XPApplyResult` data with pending `DragonProgressionEvent` values.
- New typed result/event shells: `src/dragon/xp_apply_result.gd` and `src/dragon/dragon_progression_event.gd`.
- Test evidence: focused XP/resonance suite passed with 7/7 tests and 305 assertions; full import-plus-unit/integration suite passed with 84/84 tests and 5,701 assertions.
- CodeGraph note: CodeGraph remains unusable for GDScript in this repo; direct inspection was used after checking index status.
- Next recommended: `/code-review src/dragon/dragon_progression_service.gd src/dragon/xp_apply_result.gd src/dragon/dragon_progression_event.gd tests/unit/dragon/test_xp_loop_and_resonance.gd production/epics/dragon-progression/story-002-xp-loop-and-resonance.md`, then `/story-done production/epics/dragon-progression/story-002-xp-loop-and-resonance.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/dragon-progression/story-002-xp-loop-and-resonance.md` - XP Loop And Resonance
- Acceptance criteria: 5/5 passing, covered by `tests/unit/dragon/test_xp_loop_and_resonance.gd`.
- Implementation: `src/dragon/dragon_progression_service.gd`, `src/dragon/xp_apply_result.gd`, `src/dragon/dragon_progression_event.gd`, and `tests/unit/dragon/test_xp_loop_and_resonance.gd`.
- Test evidence: focused XP/resonance suite passed with 7/7 tests and 305 assertions; full import plus unit/integration suite passed with 84/84 tests and 5,701 assertions.
- Code review: APPROVED; no required changes. Method-size guideline cleanup was applied before closure.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/dragon-progression/story-003-post-commit-progression-events.md`, then `/dev-story production/epics/dragon-progression/story-003-post-commit-progression-events.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/dragon-progression/story-003-post-commit-progression-events.md` - Post-Commit Progression Events
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY. ADR-0001, ADR-0002, and ADR-0006 are accepted; dependencies DRAGON-002 and Save/Persistence Story 003 are complete; required integration evidence path is declared.
- Implementation: SaveTransaction and SaveCommitResult now carry generic `post_commit_events`; SaveService copies those payloads into the success result after reload validation; DragonProgressionService queues XP result events onto the transaction and publishes typed `stats_updated`, `stage_advanced`, and `stage_iv_reached` signals only from successful `save_committed` callbacks.
- Test evidence: focused post-commit progression event suite passed with 4/4 tests and 36 assertions; dragon-focused unit/integration suite passed with 18/18 tests and 4,968 assertions; full import-plus-unit/integration suite passed with 88/88 tests and 5,737 assertions.
- CodeGraph note: CodeGraph remains unusable for GDScript in this repo; direct inspection was used after checking index status.
- Next recommended: `/code-review src/dragon/dragon_progression_service.gd src/save/save_transaction.gd src/save/save_commit_result.gd src/save/save_service.gd tests/integration/dragon/test_post_commit_progression_events.gd production/epics/dragon-progression/story-003-post-commit-progression-events.md`, then `/story-done production/epics/dragon-progression/story-003-post-commit-progression-events.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/dragon-progression/story-003-post-commit-progression-events.md` - Post-Commit Progression Events
- Acceptance criteria: 3/3 passing, covered by `tests/integration/dragon/test_post_commit_progression_events.gd` plus existing XP loop unit coverage for the single `stats_updated` criterion.
- Implementation: `src/dragon/dragon_progression_service.gd`, `src/dragon/dragon_progression_event.gd`, `src/dragon/xp_apply_result.gd`, `tests/integration/dragon/test_post_commit_progression_events.gd`, and the Save / Persistence post-commit event plumbing.
- Test evidence: focused post-commit progression event suite passed with 4/4 tests and 36 assertions; full import plus unit/integration suite passed with 88/88 tests and 5,737 assertions.
- Code review: APPROVED; no required changes.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md` - Scrap Read, Affordability, And Results
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY after scope-precision gaps were addressed; ADR-0009 is accepted; `TR-shop-002` is active; SaveData dependency is complete.
- TDD evidence: focused ECO-001 suite first failed because `EconomyLedger` and `EconomyResult` did not exist, then passed after implementation.
- Implementation: added `src/economy/economy_ledger.gd` and `src/economy/economy_result.gd`; `EconomyLedger` reads exact `player_scraps`, checks affordability without mutation, returns named `EconomyResult` data for validation failures, preserves exact balances above 999, and keeps staged Scrap mutation out of scope.
- Test evidence: focused Economy Ledger unit suite passed with 6/6 tests and 65 assertions; full import plus unit/integration suite passed with 94/94 tests and 5,802 assertions.
- Blockers: None.
- Next recommended: `/code-review src/economy/economy_ledger.gd src/economy/economy_result.gd tests/unit/economy/test_scrap_read_affordability_and_results.gd production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md`, then `/story-done production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/economy-ledger/story-001-scrap-read-affordability-and-results.md` - Scrap Read, Affordability, And Results
- Acceptance criteria: 4/4 passing, covered by `tests/unit/economy/test_scrap_read_affordability_and_results.gd`.
- Implementation: `src/economy/economy_ledger.gd`, `src/economy/economy_result.gd`, and `tests/unit/economy/test_scrap_read_affordability_and_results.gd`.
- Test evidence: focused Economy Ledger unit suite passed with 6/6 tests and 65 assertions; full import plus unit/integration suite passed with 94/94 tests and 5,802 assertions.
- Code review: APPROVED; no required changes.
- Tech debt logged: None
- Next recommended: `/story-readiness production/epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md` - Scrap Spend Transaction Boundary
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY with QA lead ADEQUATE. ADR-0001 and ADR-0009 are accepted; ECO-001 and Save Transaction Commit And Rollback dependencies are complete; required integration evidence path is declared.
- TDD evidence: focused ECO-002 suite first failed because `EconomyLedger.spend_scraps()` did not exist, then passed after implementation.
- Implementation: `EconomyLedger.spend_scraps(tx, amount, sink_id)` stages Scrap spends only on active `SaveTransaction.staged_save.player_scraps`; invalid transactions, negative amounts, and insufficient balances fail without mutation; successful results include balance-before/balance-after plus `sink_id` audit data.
- Test evidence: focused Economy spend integration suite passed with 5/5 tests and 45 assertions; full import plus unit/integration suite passed with 99/99 tests and 5,847 assertions.
- Blockers: None.
- Next recommended: `/code-review src/economy/economy_ledger.gd src/economy/economy_result.gd tests/integration/economy/test_scrap_spend_transaction_boundary.gd production/epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md`, then `/story-done production/epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md` - Scrap Spend Transaction Boundary
- Acceptance criteria: 5/5 passing, covered by `tests/integration/economy/test_scrap_spend_transaction_boundary.gd`.
- Implementation: `src/economy/economy_ledger.gd`, `src/economy/economy_result.gd`, and `tests/integration/economy/test_scrap_spend_transaction_boundary.gd`.
- Test evidence: focused Economy spend integration suite passed with 5/5 tests and 45 assertions; full import plus unit/integration suite passed with 99/99 tests and 5,847 assertions.
- Code review: APPROVED; no required changes.
- Tech debt logged: None.
- Review notes: Full review mode is configured, but delegated sidecar review was not spawned in this closure pass because sub-agent spawning requires an explicit delegation request in the current tool policy.
- Next recommended: `/story-readiness production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md` - Runtime Session And Payload Contracts
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY. QA lead and game-design sidecars both returned READY after readiness repair; ADR-0007 is accepted; `TR-battle-001` and `TR-battle-003` are active.
- TDD evidence: focused BATTLE-001 suite first failed because `src/battle/runtime/*` did not exist, then passed after implementation.
- Implementation: added a scene-owned `BattleRuntimeController` Node, one RefCounted `BattleSession`, typed setup/action/result/payload/delta contracts, scalar setup snapshotting on configure, explicit phase transitions, TELEGRAPH-only action acceptance, exactly-once `battle_completed(payload, delta)` emission, typed checkpoint/presentation payload shells, and no SaveService/SaveTransaction/SaveData dependency in runtime code.
- Test evidence: focused Battle Engine runtime integration suite passed with 7/7 tests and 771 assertions; full unit/integration suite passed with 106/106 tests and 6,618 assertions.
- GDScript sidecar: flagged the need for typed setup payloads instead of Dictionary setup and no debug Save fields in runtime; implementation was adjusted accordingly.
- Code review follow-up: tightened `BattleDurableDelta.phase_checkpoint` to `BattlePhaseCheckpointDelta`, `TurnResolvedPayload.presentation_events` to `Array[PresentationEventPayload]`, replaced loose completion tuple handoff with a boolean consume method plus typed accessors, snapshotted setup scalar values to preserve ADR-0007 read-only setup semantics, gated manual `RESOLUTION -> COMPLETE` transitions on the completion snapshot, asserted KO phase order, and strengthened save-boundary tests with an immutable `SaveData` fixture plus public API checks.
- Blockers: None.
- Next recommended: `/code-review src/battle/runtime/battle_runtime_controller.gd src/battle/runtime/battle_session.gd src/battle/runtime/battle_runtime_state.gd src/battle/runtime/battle_setup_payload.gd src/battle/runtime/battle_action.gd src/battle/runtime/battle_action_result.gd src/battle/runtime/battle_advance_result.gd src/battle/runtime/battle_start_result.gd src/battle/runtime/battle_ended_payload.gd src/battle/runtime/battle_durable_delta.gd src/battle/runtime/battle_phase_checkpoint_delta.gd src/battle/runtime/presentation_event_payload.gd src/battle/runtime/turn_resolved_payload.gd tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md`, then `/story-done production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/battle-engine/story-001-runtime-session-and-payload-contracts.md` - Runtime Session And Payload Contracts
- Acceptance criteria: 6/6 passing, covered by `tests/integration/battle_engine/test_runtime_session_and_payload_contracts.gd`.
- Test evidence: focused Battle Engine runtime integration suite passed with 7/7 tests and 771 assertions; full unit/integration suite passed with 106/106 tests and 6,618 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVED.
- Tech debt logged: None.
- Next recommended: All Must Have Sprint 02 stories are complete. Either run `/smoke-check sprint` to start sprint close-out, or pull a Should Have story starting with `/story-readiness production/epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md` - Damage, Type, Crit, And Stage Formulas
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY after formula-contract repair; `TR-battle-002` is active; ADR-0006 and ADR-0007 are accepted.
- TDD evidence: focused BATTLE-002 unit suite first failed because `src/battle/formulas/battle_formula_service.gd` did not exist, then passed after implementation.
- Implementation: added `BattleFormulaService` and `BattleDamageResult` under `src/battle/formulas/`; covered deterministic damage order, negative damage floor, crit/Defend ordering and constants, full 7x7 type matrix, stage/Elder multipliers, accuracy/Blind, stat scaling, and raw Battle XP.
- Test evidence: focused Battle Engine formula unit suite passed with 5/5 tests and 90 assertions; full unit/integration suite passed with 111/111 tests and 6,708 assertions.
- Scope notes: no runtime turn loop, status lifecycle, Defend cooldown legality, simultaneous KO resolution, reward settlement, XP application, Scrap application, or Resonance mutation implemented.
- Blockers: None.
- Next recommended: `/code-review src/battle/formulas/battle_formula_service.gd src/battle/formulas/battle_damage_result.gd tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd production/epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md`, then `/story-done production/epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md` - Damage, Type, Crit, And Stage Formulas
- Acceptance criteria: 6/6 passing, covered by `tests/unit/battle_engine/test_damage_type_crit_and_stage_formulas.gd`.
- Test evidence: focused Battle Engine formula unit suite passed with 5/5 tests and 90 assertions; full unit/integration suite passed with 111/111 tests and 6,708 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVE.
- Code review: APPROVED WITH SUGGESTIONS; only non-blocking notes for stronger typed dictionary/test annotations, helper doc comments, and direct roll-bound assertions.
- Tech debt logged: None.
- Next recommended: Continue Should Have scope with `/story-readiness production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md` or `/story-readiness production/epics/economy-ledger/story-003-scrap-reward-addition-boundary.md`; alternatively run `/smoke-check sprint` to begin Sprint 02 close-out.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/economy-ledger/story-003-scrap-reward-addition-boundary.md` - Scrap Reward Addition Boundary
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- Readiness verdict: READY after traceability repair; QA lead gate returned ADEQUATE/READY. `TR-map-001`, `TR-shop-002`, and `TR-shop-004` are active; ADR-0008 and ADR-0009 are accepted.
- TDD evidence: focused Economy integration suite first failed because `EconomyLedger.add_scraps()` did not exist, then passed after implementation.
- Implementation: added `EconomyLedger.add_scraps(tx, amount, source_id)` for staged, transaction-bound Scrap reward additions; reused `EconomyResult` named fields; test harness verifies authored rewards, Battle echo mismatch rejection, defeat no-op behavior, exact balances above 999, negative reward rejection, and OQ-SH01 provisional tuning boundaries.
- Test evidence: focused Economy integration suite passed with 9/9 tests and 109 assertions; full unit/integration suite passed with 115/115 tests and 6,772 assertions.
- Code review follow-up: expanded invalid transaction coverage for null, inactive, and missing-staged reward transactions; widened OQ-SH01 boundary checks to the reward helper, settlement harness source, and absence of the economy content lock artifact; typed result-producing EconomyLedger methods as `EconomyResult`.
- Scope notes: no Campaign Map node graph authoring, boss/hazard bonus calibration, HUD display, `BOSS_SCRAP_BONUS`/`HAZARD_SCRAP_BONUS` finalization, or economy content-lock artifact implemented.
- Blockers: None.
- Next recommended: `/code-review src/economy/economy_ledger.gd src/economy/economy_result.gd tests/integration/economy/test_scrap_reward_addition_boundary.gd production/epics/economy-ledger/story-003-scrap-reward-addition-boundary.md`, then `/story-done production/epics/economy-ledger/story-003-scrap-reward-addition-boundary.md`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/economy-ledger/story-003-scrap-reward-addition-boundary.md` - Scrap Reward Addition Boundary
- Acceptance criteria: 4/4 passing, covered by `tests/integration/economy/test_scrap_reward_addition_boundary.gd`.
- Test evidence: focused Economy integration suite passed with 9/9 tests and 109 assertions; full unit/integration suite passed with 115/115 tests and 6,772 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVED.
- Code review: APPROVED; required test coverage and API typing changes resolved before closure.
- Tech debt logged: None.
- Next recommended: Pull remaining Should Have scope with `/dev-story production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md`, or begin Sprint 02 close-out with `/smoke-check sprint`.

## Session Extract - /dev-story 2026-05-27

- Story: `production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md` - Dragon Creation And Source Helpers
- Status: In Progress; implementation and test evidence are complete, code review/story closure pending.
- TDD evidence: focused Dragon integration suite first failed because `FusionChildData` and `DragonCreationResult` were missing, then passed after implementation.
- Implementation: added `DragonCreationResult`, `FusionChildData`, Hatchery core creation, Fusion child creation, Singularity Void grant, and Hatchery duplicate XP routing through `DragonProgressionService` staged transactions.
- Test written: `tests/integration/dragon/test_dragon_creation_and_source_helpers.gd` with 4 test functions covering Hatchery creation/rejection, Fusion child creation/rejection, Singularity Void reserved story-roster grant, shiny immutability surface, and missing duplicate XP discard logging.
- Test evidence: focused Dragon integration suite passed with 8/8 tests and 118 assertions; full unit/integration suite passed with 119/119 tests and 6,854 assertions.
- Scope notes: no Hatchery RNG, Fusion formulas, Singularity boss settlement, UI, or roster-capacity enforcement beyond the reserved story roster entry.
- Blockers: None.
- Next recommended: `/code-review src/dragon/dragon_progression_service.gd src/dragon/dragon_creation_result.gd src/dragon/fusion_child_data.gd tests/integration/dragon/test_dragon_creation_and_source_helpers.gd production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md`, then `/story-done production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md`; after closure run `/smoke-check sprint`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md` - Dragon Creation And Source Helpers
- Acceptance criteria: 4/4 passing, covered by `tests/integration/dragon/test_dragon_creation_and_source_helpers.gd`.
- Test evidence: focused Dragon integration suite passed with 8/8 tests and 118 assertions; full unit/integration suite passed with 119/119 tests and 6,854 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVE.
- Code review: APPROVED after required detached snapshot and AC-DP76 coverage fixes.
- Tech debt logged: None.
- Next recommended: Begin Sprint 02 close-out with `/smoke-check sprint`, then `/team-qa sprint`.

## Session Extract - /story-done 2026-05-27

- Verdict: COMPLETE
- Story: `production/epics/battle-engine/story-004-telegraph-defend-and-defrag-delta.md` - Telegraph, Defend, And Defrag Delta
- Acceptance criteria: 5/5 passing, covered by `tests/integration/battle_engine/test_telegraph_defend_and_defrag_delta.gd`.
- Test evidence: focused BATTLE-004 integration suite passed with 7/7 tests and 86 assertions; adjacent Battle runtime/status/formula suite passed with 24/24 tests and 1,071 assertions; full unit/integration suite passed with 146/146 tests and 7,243 assertions.
- QA coverage gate: ADEQUATE.
- Lead programmer gate: APPROVED.
- Code review: APPROVED after required changes and doc-comment follow-up.
- Tech debt logged: None.
- Next recommended: Sprint 03 Must Have and Should Have stories are complete. Run `/smoke-check sprint`, then `/team-qa sprint`; optional Nice-to-have candidates are `production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md` and `production/epics/battle-engine/story-006-npc-action-selection-heuristics.md`.

## Session Extract - /smoke-check + /team-qa 2026-05-27

- Sprint: Sprint 03
- Smoke verdict: PASS WITH WARNINGS; report written to `production/qa/smoke-sprint-03-2026-05-27.md`.
- QA sign-off verdict: APPROVED WITH CONDITIONS; report written to `production/qa/qa-signoff-sprint-03-2026-05-27.md`.
- Automated evidence: full Godot/GUT unit + integration suite passed with 29 scripts, 146/146 tests, and 7,243 assertions; production shell launch exits 0.
- Delivered scope: SCENE-003, DRAGON-005, BATTLE-003, BATTLE-004, and BATTLE-007 all complete with automated evidence.
- Conditions: add explicit manual launch sign-off evidence for SCENE-003, add standalone source/content review evidence for BATTLE-007 before animation content lock or art-production expansion, and run manual frame-rate/performance smoke once a meaningful playable runtime path exists.
- Bugs: no S1/S2 bugs filed.
- Next recommended: `/retrospective sprint-03`, then decide whether to pull optional BATTLE-005/BATTLE-006 or plan the next sprint.

## Session Extract - /retrospective 2026-05-27

- Sprint: Sprint 03
- Report: `production/retrospectives/retro-sprint-03-2026-05-27.md`
- Completion: 5/7 planned stories overall; 5/5 Must/Should stories complete; BATTLE-005 and BATTLE-006 remained deferred Nice-to-haves.
- Quality outcome: QA sign-off APPROVED WITH CONDITIONS; no S1/S2 bugs filed.
- Key lesson: Sprint 03 succeeded by keeping Nice-to-haves as real buffer and by separating committed Must/Should completion from total planned scope.
- Action items: create explicit SCENE-003 manual launch sign-off, create BATTLE-007 source/content review evidence before content lock, add a playable runtime/performance-smoke story, keep handoff refresh in close-out, and choose BATTLE-005 vs BATTLE-006 based on next combat bottleneck.
- Next recommended: decide whether to pull optional BATTLE-005/BATTLE-006 or run next sprint planning.

## Session Extract - /dev-story BATTLE-005 + BATTLE-006 2026-05-27

- Stories: `production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md` and `production/epics/battle-engine/story-006-npc-action-selection-heuristics.md`.
- Status: In Progress; implementation and automated evidence are complete, code review/story closure pending.
- BATTLE-005 implementation: added typed `BattleSession` presentation, turn-resolved, and `battle_completed(payload, delta)` signals; IMPACT heal-before-damage resolution; KO completion at RESOLUTION; first-KO actor tracking for RECOIL declaration order; turn payload emission; and session-local completion emission without requiring listeners.
- BATTLE-006 implementation: added authored `MoveDefinition.power` / `is_reflect` fields and deterministic NPC action selection that prioritizes super-effective attacks, status moves, high-power fallback, random themed fallback, and Defend cooldown legality without mutating authored move Resources.
- Test evidence after required review fixes: focused BATTLE-005 suite passed with 5/5 tests and 357 assertions; focused BATTLE-006 suite passed with 6/6 tests and 30 assertions; combined focused suite passed with 11/11 tests and 387 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.
- Required review fixes addressed: replaced session `battle_ended(payload)` with `battle_completed(payload, delta)`, tightened runtime combatant/status/result typing, rejected enemy consumable actions, added BATTLE-005 coverage for turn-carried presentation events, legal Defrag Patch IMPACT timing, full completion payload/delta fields, and defeat payload behavior.
- Next recommended: rerun `/code-review src/battle/runtime/battle_session.gd src/battle/runtime/battle_advance_result.gd src/battle/runtime/battle_recoil_result.gd src/battle/data/move_definition.gd tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd tests/unit/battle_engine/test_npc_action_selection_heuristics.gd production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md production/epics/battle-engine/story-006-npc-action-selection-heuristics.md`, then `/story-done` for BATTLE-005 and BATTLE-006 before formal next-sprint commitment.

## Session Extract - Sprint 04 planning start 2026-05-28

- User request: pull BATTLE-005/BATTLE-006, then start next sprint planning.
- Planning artifact: `production/sprints/sprint-04.md` created as a Core transition sprint draft.
- Sprint status: `production/sprint-status.yaml` now tracks Sprint 04 with BATTLE-005 and BATTLE-006 as Must Have carryover stories, both still `in-progress`.
- Producer gate: PR-SPRINT returned CONCERNS. BATTLE-005/BATTLE-006 must be treated as Sprint 04 carryover closeout because Sprint 03 QA sign-off and retrospective explicitly excluded them.
- QA lead gate: Sprint 04 needs a narrow QA refresh for BATTLE-005/BATTLE-006, plus SCENE-003 manual launch evidence and BATTLE-007 source/content review evidence before phase-advancement claims.
- Planning posture: do not schedule DRAGON-006, DRAGON-007, or ECO-004 while blocked. Use Sprint 04 to close Battle formally, run `/qa-plan sprint`, generate Hatchery stories, readiness-gate the first Hatchery slice, and only then pull new implementation if the generated story is small and dependency-clean.
- Next recommended: rerun `/code-review src/battle/runtime/battle_session.gd src/battle/runtime/battle_advance_result.gd src/battle/runtime/battle_recoil_result.gd src/battle/data/move_definition.gd tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd tests/unit/battle_engine/test_npc_action_selection_heuristics.gd production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md production/epics/battle-engine/story-006-npc-action-selection-heuristics.md`, then `/story-done` for both Battle stories, then `/qa-plan sprint`.

## Session Extract - /story-done BATTLE-005 2026-05-28

- Verdict: COMPLETE
- Story: `production/epics/battle-engine/story-005-turn-resolution-and-presentation-events.md` - Turn Resolution And Presentation Events
- Acceptance criteria: 5/5 passing, covered by `tests/integration/battle_engine/test_turn_resolution_and_presentation_events.gd`.
- Test evidence: focused BATTLE-005 suite passed with 5/5 tests and 357 assertions; combined BATTLE-005/BATTLE-006 focused suite passed with 11/11 tests and 387 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.
- QA coverage gate: ADEQUATE via focused/adjacent automated coverage and prior approved `/code-review`.
- Lead programmer gate: APPROVED via `/code-review`.
- Tech debt logged: None.
- Next recommended: `/story-done production/epics/battle-engine/story-006-npc-action-selection-heuristics.md`, then `/qa-plan sprint`.

## Session Extract - /story-done BATTLE-006 2026-05-28

- Verdict: COMPLETE WITH NOTES
- Story: `production/epics/battle-engine/story-006-npc-action-selection-heuristics.md` - NPC Action Selection Heuristics
- Acceptance criteria: 6/6 covered by deterministic tests; optional manual majority-playtest evidence remains a Sprint 04 QA-delta advisory.
- Test evidence: focused BATTLE-006 suite passed with 6/6 tests and 30 assertions; combined BATTLE-005/BATTLE-006 focused suite passed with 11/11 tests and 387 assertions; adjacent Battle Engine slice passed with 42/42 tests and 1,590 assertions; full unit/integration suite passed with 157/157 tests and 7,682 assertions.
- QA coverage gate: ADEQUATE for logic coverage; manual playtest evidence remains optional QA delta.
- Lead programmer gate: APPROVED via `/code-review`.
- Tech debt logged: None.
- Next recommended: run `/qa-plan sprint` so Sprint 04 QA delta covers BATTLE-005/BATTLE-006 before Hatchery story work starts.

## Session Extract - /qa-plan sprint 2026-05-28

- Scope: Sprint 04, covering BATTLE-005/BATTLE-006 plus QA delta/evidence work.
- Plan written: `production/qa/qa-plan-sprint-04-2026-05-28.md`.
- Classification: BATTLE-005 is Integration; BATTLE-006 is Logic; QA-DELTA-BATTLE, EVIDENCE-03, and Hatchery story generation/readiness are evidence/planning work items.
- QA priorities: create Battle Sprint 04 delta evidence, close or explicitly carry SCENE-003 and BATTLE-007 evidence conditions, and add a Hatchery QA-plan addendum after story generation/readiness.
- Sprint status: Sprint 04 DoD checkbox for QA plan is complete.
- Next recommended: create `production/qa/evidence/battle-sprint-04-delta-evidence.md`, then `/create-stories hatchery`.

## Session Extract - Sprint 04 Battle QA Delta Evidence 2026-05-28

- Evidence written: `production/qa/evidence/battle-sprint-04-delta-evidence.md`.
- Focused BATTLE-005/BATTLE-006 regression: 2 scripts, 11/11 tests, 387 assertions.
- Adjacent Battle Engine slice: 7 scripts, 42/42 tests, 1,590 assertions.
- Full unit/integration suite: 31 scripts, 157/157 tests, 7,682 assertions. Expected Dragon defensive error/warning output is reported by GUT as ExpectedError.
- Sprint status: Sprint 04 DoD checkbox for Battle QA delta is complete.
- Remaining Sprint 04 evidence: SCENE-003 manual launch evidence and BATTLE-007 source/content evidence.
- Next recommended: `/create-stories hatchery`, then `/story-readiness` for the first Hatchery story.

## Session Extract - /create-stories hatchery 2026-05-28

- Epic: `production/epics/hatchery/EPIC.md`.
- Stories written: 7 under `production/epics/hatchery/`.
- Story split: 3 Logic, 3 Integration, 1 blocked UI/presentation evidence story.
- First implementation candidate: `production/epics/hatchery/story-001-pull-table-and-result-contracts.md`.
- QA gate note: review mode is `full`, but QL-STORY-READY sidecar could not spawn because the agent thread limit is currently reached; local decomposition kept criteria concrete and test evidence paths explicit.
- Sprint status: Hatchery story generation is complete; readiness gate for the first Hatchery story remains pending.
- Next recommended: `/story-readiness production/epics/hatchery/story-001-pull-table-and-result-contracts.md`.

## Session Extract - /story-done HATCHERY-001 2026-05-28

- Verdict: COMPLETE
- Story: `production/epics/hatchery/story-001-pull-table-and-result-contracts.md` - Pull Table And Result Contracts
- Acceptance criteria: 6/6 passing, covered by `tests/unit/hatchery/test_pull_table_and_result_contracts.gd`.
- Test evidence: focused Hatchery unit suite passed with 8/8 tests and 109 assertions; full unit/integration suite passed with 165/165 tests and 7,791 assertions.
- QA coverage gate: APPROVED WITH NOTES; authored `.tres` exact-value drift note was addressed with focused assertions before close-out.
- Lead programmer gate: APPROVED WITH NOTES; no blocking findings.
- Code review: APPROVED after required per-rarity element-total validation fix.
- Tech debt logged: None.
- Next recommended: `/story-readiness production/epics/hatchery/story-002-rarity-pity-and-shiny-roll-resolution.md`.
