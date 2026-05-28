# Sprint 03 - 2026-06-11 to 2026-06-24

## Sprint Goal

Turn the Core service layer into a smokeable production shell path while hardening Dragon save/load integrity and the next Battle runtime interaction contracts.

## Capacity

- Total days: 10
- Buffer: 2 days reserved for review, story-readiness repair, dependency drag, and Godot 4.6 integration work
- Available: 8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| SCENE-003 | [Production Shell Main Scene Smoke Path](../epics/scene-flow/story-003-production-shell-main-scene-smoke-path.md) | engine-programmer / godot-specialist | 1.0 | Scene Flow 001/002, Input Router 001/003 | Root `project.godot` launches a production main scene, opens a minimal Hub shell through SceneFlow, restores focus, and lets sprint smoke mark production shell launch as PASS instead of DEFERRED. |
| DRAGON-005 | [Save Load Integrity And Repair](../epics/dragon-progression/story-005-save-load-integrity-and-repair.md) | gameplay-programmer / qa-tester | 1.0 | DRAGON-001, DRAGON-002, Save / Persistence load projection | Invalid dragon records repair/discard deterministically, XP inconsistencies reset charges before repair, Void records preserve story identity, and derived stage state survives save-load. |
| BATTLE-003 | [Status And Recoil Effects](../epics/battle-engine/story-003-status-and-recoil-effects.md) | gameplay-programmer | 1.0 | BATTLE-001, BATTLE-002 | Status apply/overwrite, DoT, Freeze, Paralysis, Guard Break, duration, and declaration-order rules pass deterministic unit coverage. |
| BATTLE-004 | [Telegraph, Defend, And Defrag Delta](../epics/battle-engine/story-004-telegraph-defend-and-defrag-delta.md) | gameplay-programmer / qa-tester | 1.0 | BATTLE-001, BATTLE-003, Input Router contextual counter complete | Defend cooldown and Defrag Patch TELEGRAPH behavior work through typed runtime actions and durable deltas without direct SaveData mutation. |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| BATTLE-007 | [Animation Manifest Runtime Lookup](../epics/battle-engine/story-007-animation-manifest-runtime-lookup.md) | gameplay-programmer / technical-artist | 0.75 | BattleAnimationManifest validator/content fixture, BATTLE-001 | Runtime clip lookup resolves through BattleAnimationManifest IDs and contains no hardcoded move sprite/VFX paths. |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| BATTLE-005 | [Turn Resolution And Presentation Events](../epics/battle-engine/story-005-turn-resolution-and-presentation-events.md) | gameplay-programmer / qa-tester | 1.0 | BATTLE-001 through BATTLE-004 | KO ordering, long-loop stability, typed presentation profile signals, and final `battle_ended` behavior pass integration coverage. |
| BATTLE-006 | [NPC Action Selection Heuristics](../epics/battle-engine/story-006-npc-action-selection-heuristics.md) | gameplay-programmer / systems-designer | 0.75 | BATTLE-002, BATTLE-004 | NPC weighted action selection and Defend cooldown behavior pass deterministic seeded tests. |

## Carryover From Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| DRAGON-005 - Save Load Integrity And Repair | Sprint 02 Nice-to-have remained backlog; retro flagged it as likely prerequisite for robust shell/save work. | 1.0 |
| BATTLE-003 - Status And Recoil Effects | Sprint 02 Nice-to-have remained backlog and is needed before Defrag/turn-resolution stories. | 1.0 |
| BATTLE-007 - Animation Manifest Runtime Lookup | Sprint 02 Nice-to-have remained backlog and supports presentation readiness without depending on BATTLE-004. | 0.75 |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| SCENE-003 expands into final Hub/menu UX | Medium | High | Keep scope to smokeable production shell, stable screen ID, boot path, and focus restoration; defer final Hub presentation. |
| BATTLE-004 depends on BATTLE-003 landing cleanly | Medium | Medium | Pull BATTLE-003 before BATTLE-004 and do not start BATTLE-004 until status/recoil story-done evidence passes. |
| BATTLE-005 and BATTLE-006 depend on BATTLE-004 and could overload the sprint | Medium | Medium | Keep them Nice-to-have conditional pulls only after Must Have stories and BATTLE-007 are stable. |
| Sprint 03 has no QA plan yet | High | Medium | Run `/qa-plan sprint` before `/dev-story` so test expectations are defined up front. |
| Project calendar is ahead of actual sprint dates because Sprint 02 closed early | Medium | Low | Treat this as planning cadence only; update dates if the team starts Sprint 03 immediately. |

## Dependencies On External Factors

- Godot 4.6.3 local installation remains the implementation target.
- Production shell smoke needs a configured root main scene in `project.godot`.
- Full manual performance smoke still needs a real player-facing runtime path; SCENE-003 should unlock launch smoke first.
- Full-mode producer/QA gates may require closing unused subagent threads before delegation.

## Definition Of Done For This Sprint

- [x] All Must Have tasks completed.
- [x] All Must Have stories pass `/story-done`.
- [x] All Logic/Integration stories have passing unit/integration tests.
- [x] `/smoke-check sprint` passes with production shell/main-menu launch marked PASS, not DEFERRED.
- [x] QA plan exists at `production/qa/qa-plan-sprint-03-2026-05-27.md`.
- [x] QA sign-off report is APPROVED or APPROVED WITH CONDITIONS.
- [x] No S1/S2 bugs in delivered Core services or production shell launch path.
- [x] Design/architecture documents updated for any deviations.
- [x] Code review completed for each implemented story.

> QA Plan: `production/qa/qa-plan-sprint-03-2026-05-27.md`.
> Smoke Report: `production/qa/smoke-sprint-03-2026-05-27.md`.
> QA Sign-Off: `production/qa/qa-signoff-sprint-03-2026-05-27.md` - APPROVED WITH CONDITIONS.
> Retrospective: `production/retrospectives/retro-sprint-03-2026-05-27.md`.

## Scope Check

If stories are added beyond this plan mid-sprint, run `/scope-check` on the affected epic before implementation continues.

## Producer Gate

PR-SPRINT verdict: CONCERNS.

Producer guidance applied:
- Keep committed Must Have scope to SCENE-003, DRAGON-005, BATTLE-003, and BATTLE-004.
- Prioritize BATTLE-007 ahead of BATTLE-005/BATTLE-006 in the Should lane.
- Treat BATTLE-005 and BATTLE-006 as conditional pulls only after BATTLE-004 passes story-done.
- Keep SCENE-003 tightly scoped to main-scene shell smoke and do not let it become final Hub UX.
