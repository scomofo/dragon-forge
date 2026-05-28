# Sprint 04 - 2026-06-25 to 2026-07-08

## Sprint Goal

Close the pulled Battle runtime stories with formal review and QA delta evidence, then prepare the next Core implementation lane by generating and readiness-gating Hatchery stories.

## Capacity

- Total days: 10
- Buffer: 2 days reserved for review, QA delta work, story-readiness repair, and scope churn from newly generated Hatchery stories
- Available: 8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| BATTLE-005 | [Turn Resolution And Presentation Events](../epics/battle-engine/story-005-turn-resolution-and-presentation-events.md) closeout | gameplay-programmer / qa-tester | 0.0 complete | Closed 2026-05-28 | `/code-review`, `/story-done`, and Sprint 04 Battle QA delta evidence passed. |
| BATTLE-006 | [NPC Action Selection Heuristics](../epics/battle-engine/story-006-npc-action-selection-heuristics.md) closeout | gameplay-programmer / systems-designer | 0.0 complete | Closed 2026-05-28 | `/code-review`, `/story-done`, and deterministic NPC-selection QA delta evidence passed. |
| QA-DELTA-BATTLE | Sprint 04 Battle QA delta and smoke refresh | qa-lead / qa-tester | 0.0 complete | Closed 2026-05-28 | Sprint QA evidence explicitly includes the two pulled Battle stories, since Sprint 03 sign-off excluded them. |
| EVIDENCE-03 | Sprint 03 condition evidence closeout | qa-lead / engine-programmer / technical-artist | 0.5 | Sprint 03 QA sign-off conditions | SCENE-003 manual launch sign-off and BATTLE-007 standalone source/content review evidence exist before phase-advancement claims. |
| HATCHERY-STORIES | Create Hatchery implementation stories | producer / gameplay-programmer | 0.0 complete | Closed 2026-05-28 | `/create-stories hatchery` produced seven bounded story files with clear acceptance criteria, dependencies, and test evidence requirements. |
| HATCHERY-READINESS | Readiness-gate the first Hatchery slice | producer / qa-lead / gameplay-programmer | 0.5 | HATCHERY-STORIES | First Hatchery story passes `/story-readiness` or has a concrete repair list before implementation begins. |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| FUSION-STORIES | Create Fusion Engine implementation stories | producer / gameplay-programmer | 0.5 | Fusion GDD approved, ADR-0013 approved | `/create-stories fusion-engine` produces bounded story files for later Core planning. |
| HATCHERY-001 | First small Hatchery implementation slice | gameplay-programmer / qa-tester | TBD after story creation | HATCHERY-STORIES and HATCHERY-READINESS | Only pulled if the generated first story is dependency-clean and fits remaining Sprint 04 capacity. |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| PERF-SMOKE-STORY | Draft playable runtime/performance smoke story | producer / lead-programmer / qa-lead | 0.5 | Production shell path exists | A future story captures the path needed to move manual frame-rate smoke from deferred to measured. |

## Carryover From Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| BATTLE-005 - Turn Resolution And Presentation Events | Pulled after Sprint 03 QA sign-off and retrospective; formal review, story closure, and Sprint 04 Battle QA delta evidence completed on 2026-05-28. | 0.0 remaining |
| BATTLE-006 - NPC Action Selection Heuristics | Pulled after Sprint 03 QA sign-off and retrospective; formal review, story closure, and Sprint 04 Battle QA delta evidence completed on 2026-05-28. | 0.0 remaining |
| Sprint 03 QA conditions | Sprint 03 was approved with conditions for SCENE-003 manual launch evidence, BATTLE-007 source/content review evidence, and future performance smoke. | 1.0 total planning/evidence allowance |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Sprint 03 evidence conditions could linger into Sprint 04 close-out | Medium | Medium | Create or explicitly carry SCENE-003 manual launch evidence and BATTLE-007 source/content evidence before QA sign-off. |
| Fusion epic is ready but has no story files; Hatchery stories still need readiness | Medium | High | Readiness-gate Hatchery Story 001 before implementation; create Fusion stories later if scope allows. |
| Remaining existing Core story files are blocked | High | Medium | Do not schedule DRAGON-006, DRAGON-007, or ECO-004 until their presentation, cross-system, Campaign Map, and evidence dependencies exist. |
| Hatchery QA addendum could be skipped after readiness | Medium | Medium | If Story 001 is pulled for implementation, refresh QA scope for that story before `/dev-story`. |
| Sprint calendar dates remain ahead of actual execution | Medium | Low | Treat dates as planning cadence unless the team resets calendar tracking. |

## Dependencies On External Factors

- Sprint 03 QA sign-off does not cover BATTLE-005 or BATTLE-006 because both were pulled afterward.
- Hatchery implementation scope now depends on `/story-readiness` output for the first generated story.
- Fusion implementation scope depends on `/create-stories fusion-engine` output.
- DRAGON-006, DRAGON-007, and ECO-004 remain blocked and should not be pulled until their upstream systems/evidence exist.

## Definition Of Done For This Sprint

- [x] BATTLE-005 passes code review and `/story-done`.
- [x] BATTLE-006 passes code review and `/story-done`.
- [x] Sprint 04 QA delta includes BATTLE-005 and BATTLE-006.
- [ ] SCENE-003 manual launch evidence exists or remains explicitly tracked as an open condition.
- [ ] BATTLE-007 source/content review evidence exists or remains explicitly tracked as an open condition.
- [ ] First Hatchery story readiness gate passes or has a concrete repair list.
- [x] QA plan exists at `production/qa/qa-plan-sprint-04-*.md`.
- [ ] `/smoke-check sprint` passes before close-out.
- [ ] QA sign-off report is APPROVED or APPROVED WITH CONDITIONS.
- [ ] No S1 or S2 bugs in delivered features.
- [ ] Code review completed for each implemented story.

> Sprint 04 QA plan exists at `production/qa/qa-plan-sprint-04-2026-05-28.md`. Add a Hatchery QA-plan addendum after story-readiness if new implementation scope is pulled.

## Scope Check

If Hatchery or Fusion implementation stories are added after story generation, run `/scope-check` on the affected epic before implementation continues.

## Producer Gate

PR-SPRINT verdict: CONCERNS.

Producer guidance applied:
- Treat BATTLE-005 and BATTLE-006 as Sprint 04 carryover Must Have closeout, not completed Sprint 03 work.
- Require formal `/code-review`, `/story-done`, and QA delta/smoke coverage before claiming those stories delivered.
- Use Sprint 04 to transition from Battle closure into Hatchery story generation and readiness.
- Do not schedule DRAGON-006, DRAGON-007, or ECO-004 while their dependencies remain blocked.
- Keep first Hatchery implementation conditional until generated stories prove small and dependency-clean.
