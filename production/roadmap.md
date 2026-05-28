# Dragon Forge Production Roadmap

**Last Updated**: 2026-05-28
**Stage**: Pre-Production
**Engine**: Godot 4.6
**Planning Horizon**: Sprint 04 closeout through first internally playable Core loop
**Source of Truth**: `production/session-state/active.md`, `production/sprint-status.yaml`, `production/sprints/sprint-04.md`, `production/epics/index.md`

---

## 1. Current Position

Dragon Forge is in Pre-Production. Foundation systems are largely implemented; Core systems are partially implemented and currently centered on Battle, Dragon Progression, Economy Ledger, and Hatchery service work.

The active lane is **Sprint 04 - smoke and QA closeout**:

- BATTLE-005 and BATTLE-006 are complete and have Sprint 04 Battle delta evidence.
- HATCHERY-004 is complete with transaction boundary evidence.
- HATCHERY-005 is complete with story-done closure and recorded automated evidence.
- Sprint 04 still needs smoke, QA sign-off, and an explicit decision on SCENE-003/BATTLE-007 carry-forward evidence.

### Immediate Active Handoff

1. Run `/smoke-check sprint` to create the Sprint 04 smoke report.
2. Run `/team-qa sprint` after smoke exists.
3. Resolve or explicitly carry forward SCENE-003 manual launch evidence and BATTLE-007 source/content evidence during QA sign-off.

---

## 2. Roadmap Operating Rules

These rules decide what may enter a sprint:

1. **Finish sprint closeout before opening new implementation lanes**: Sprint 04 smoke and QA precede HATCHERY-006, Fusion, Dragon presentation, Economy content lock, or UI work.
2. **Service before presentation**: Core services and deterministic tests land before UI/reveal/audio polish.
3. **One cross-system integration risk at a time**: do not combine Hatchery event publication, Fusion commit, Campaign reward, and UI reveal work in the same sprint unless prior lanes are closed.
4. **Blocked means blocked**: DRAGON-006, DRAGON-007, ECO-004, and HATCHERY-007 require an unblock condition before scheduling.
5. **QA gates are roadmap gates**: smoke, QA sign-off, and story-done evidence decide whether the roadmap advances.
6. **Carry-forward must be explicit**: deferred SCENE-003, BATTLE-007, and performance-smoke evidence must appear in sprint plans or sign-offs, not only in session notes.
7. **Every step stays traceable**: roadmap items must reference a story, epic, GDD, ADR, sprint, QA report, or session handoff.

---

## 3. Now / Next / Later Summary

| Horizon | Focus | What changes when complete | Do not start until |
|---|---|---|---|
| Now | Sprint 04 smoke and QA closeout | Current Hatchery implementation lane is deliverable scope; smoke and QA can close Sprint 04. | HATCHERY-005 story-done complete. |
| Next | HATCHERY-006 post-commit events and preview contract | Hatchery service becomes non-UI complete and can support UI/reveal work later. | HATCHERY-005 complete and Sprint 04 smoke/QA resolved. |
| Next | Fusion story breakdown | Fusion epic becomes schedulable with concrete story files. | Sprint 04 closed, or explicitly chosen as a planning-only lane. |
| Later | Fusion Core implementation | Fusion preview/commit service becomes part of the Core loop. | Fusion stories are created and readiness-gated. |
| Later | Economy/Campaign content lock preparation | Reward and economy authored content can support broader loop testing. | ECO-004 blockers resolved and reward routes are testable. |
| Later | Presentation unlock and UI/reveal work | Dragon/Hatchery presentation stories can move from blocked to ready. | Core service events and UX specs are stable. |
| Later | Playable Core loop slice | Shell + Hatchery + Dragon + Battle + Economy + Fusion become smokeable together. | Hatchery and Fusion Core services are stable enough for integration. |

---

## 4. Milestone Roadmap

| Order | Milestone | Goal | Entry Criteria | Exit Criteria | Primary Artifacts |
|---:|---|---|---|---|---|
| 0 | Sprint 04 Closeout | Finish active Hatchery implementation and close Battle carryover evidence. | HATCHERY-005 implementation exists; BATTLE-005/BATTLE-006/HATCHERY-004 are complete. | HATCHERY-005 code review and story-done complete; Sprint 04 smoke exists; QA sign-off is APPROVED or APPROVED WITH CONDITIONS; SCENE-003/BATTLE-007 evidence is resolved or carried forward. | `production/session-state/active.md`, `production/sprints/sprint-04.md`, `production/qa/qa-plan-sprint-04-2026-05-28.md` |
| 1 | Hatchery Service Completion | Complete non-UI Hatchery service behavior. | HATCHERY-005 complete; HATCHERY-006 readiness passes. | HATCHERY-006 complete; pull preview and post-commit events obey save transaction boundaries; Hatchery slice tests pass. | `production/epics/hatchery/story-006-post-commit-events-and-preview-contract.md`, `design/gdd/hatchery.md`, ADR-0012 |
| 2 | Fusion Story Breakdown | Convert Fusion epic into implementable stories. | Sprint 04 closed or planning-only capacity exists; ADR-0013 accepted. | `/create-stories fusion-engine` creates bounded stories with acceptance criteria, dependencies, and evidence requirements. | `production/epics/fusion-engine/EPIC.md`, `design/gdd/fusion-engine.md`, ADR-0013 |
| 3 | Fusion Core Implementation | Implement deterministic Fusion preview and commit services. | Fusion stories are readiness-gated. | Formula preview/commit share one path; parent validation and atomic child creation/removal are tested; Elder authority is traceable. | Fusion story files, `docs/architecture/adr-0013-fusion-anvil-transaction-boundaries.md` |
| 4 | Economy/Campaign Content Lock Preparation | Prepare authored reward/economy content for loop testing. | Core reward consumers are clear; ECO-004 blockers are understood. | Authored economy/reward content has validation evidence; reward routes are ready for Campaign Map integration. | `production/epics/economy-ledger/story-004-economy-content-lock-evidence.md`, Campaign Map GDD, Shop GDD |
| 5 | Presentation Dependency Unlock | Define presentation contracts needed for blocked Dragon and Hatchery UI stories. | Hatchery/Fusion events are stable enough to consume; UX scope is known. | DRAGON-006 and HATCHERY-007 have unblock evidence or repair lists; UI/reveal evidence is testable. | `production/epics/dragon-progression/story-006-progression-presentation-contract.md`, `production/epics/hatchery/story-007-hatchery-ring-ui-and-reveal-evidence-contract.md`, UX specs |
| 6 | Playable Core Loop Slice | Connect shell, progression, battle, hatchery, economy, and fusion into an internal loop. | Core services expose stable contracts; smoke path is defined. | A smokeable internal loop exists; no open S1/S2 bugs block the loop; regression suite covers the critical path. | Sprint plans, smoke reports, regression suite, vertical-slice evidence |
| 7 | Pre-Production Gate Review | Decide whether the project can advance toward Production. | Core loop slice exists; major QA conditions are resolved or accepted. | `/gate-check` reports PASS or CONCERNS with accepted conditions; architecture/design traceability has no blocking gaps. | `production/gates/`, `docs/architecture/architecture-review-*.md`, QA sign-offs |

---

## 5. Sprint Candidate Backlog

Use this backlog for near-term sprint planning. Pull from the top unless a gate explicitly redirects the team.

| Priority | Candidate | Type | Status | Recommended sprint slot | Entry Gate | Done Means |
|---:|---|---|---|---|---|---|
| 1 | HATCHERY-005 closeout | Integration / review | Complete | Sprint 04 | Implementation exists; tests recorded locally. | `/code-review` and `/story-done` complete; status is Complete. |
| 2 | Sprint 04 smoke + QA closeout | QA / release gate | Active next | Finish in Sprint 04 | HATCHERY-005 is Complete. | Smoke report exists; QA sign-off exists; S1/S2 status is known. |
| 3 | SCENE-003 manual launch evidence | Evidence | Carry-forward candidate | Sprint 04 closeout or next QA cleanup slice | Production shell can be launched manually or covered by accepted evidence. | Evidence file exists or carry-forward is explicitly accepted. |
| 4 | BATTLE-007 source/content evidence | Evidence | Carry-forward candidate | Sprint 04 closeout or next QA cleanup slice | Animation manifest source/content review is scoped. | Evidence proves manifest-ID lookup and no move-name VFX branches, or carry-forward is accepted. |
| 5 | HATCHERY-006 post-commit events and preview contract | Integration | Ready | Next implementation sprint | HATCHERY-005 complete; Sprint 04 closed. | Post-commit event and preview contract tests pass; no UI scope included. |
| 6 | Fusion story generation | Planning | Ready | Next planning slot | Sprint 04 closed or planning-only capacity approved. | Fusion story files exist and are readiness-gateable. |
| 7 | Fusion first implementation slice | Logic / integration | Pending stories | After Fusion story generation | First Fusion story is READY. | Focused Fusion tests pass and story closes. |
| 8 | ECO-004 content lock evidence | Evidence / data | Blocked | After reward/content routes are stable | Blocker cleared. | Economy content validation evidence exists. |
| 9 | DRAGON-006 presentation contract | Presentation contract | Blocked | After event consumers are stable | UX/presentation contract scope defined. | Presentation contract tests/evidence exist. |
| 10 | HATCHERY-007 ring UI/reveal evidence | UI | Blocked | After HATCHERY-006 and UX readiness | HATCHERY-006 complete; reveal UX ready. | UI/reveal acceptance evidence exists. |

---

## 6. Dependency Gates

### Gate A: Sprint 04 Can Close

Required:

- HATCHERY-005 is Complete.
- Sprint 04 smoke report exists.
- Sprint 04 QA sign-off exists.
- SCENE-003 manual launch evidence is resolved or explicitly carried forward.
- BATTLE-007 source/content evidence is resolved or explicitly carried forward.
- No S1/S2 bugs remain open for delivered Sprint 04 scope.

If Gate A fails, do not start HATCHERY-006 or Fusion implementation.

### Gate B: Hatchery Service Is Non-UI Complete

Required:

- HATCHERY-001 through HATCHERY-006 are Complete.
- Pull tables, rarity pity, element soft-pity, Scrap spend, duplicate XP, shiny upgrade, rollback, preview, and post-commit event behavior all have focused evidence.
- HATCHERY-007 remains out of scope unless the UX/reveal lane is explicitly opened.

If Gate B passes, Hatchery can support Core loop integration and later UI reveal work.

### Gate C: Fusion Can Enter Implementation

Required:

- `/create-stories fusion-engine` has produced story files.
- First Fusion story passes `/story-readiness`.
- Fusion preview/commit boundaries remain aligned with ADR-0013.
- Dragon Progression dependencies for Elder/child creation are clear.

If Gate C fails, keep Fusion planning-only.

### Gate D: Presentation Work Can Start

Required:

- Service-level event contracts are stable enough to consume.
- UX specs identify screen/flow behavior for the relevant presentation work.
- Manual/visual evidence expectations are defined before implementation.

If Gate D fails, do not pull DRAGON-006 or HATCHERY-007.

---

## 7. Recommended Next Sprint Shapes

These are not commitments; they are ready-to-use shapes for `/sprint-plan` once Sprint 04 closes.

### Option 1: Hatchery Completion Sprint (Recommended)

**Goal**: Finish non-UI Hatchery service behavior.

**Likely scope**:

- HATCHERY-006 post-commit events and preview contract.
- Sprint 04 carry-forward evidence cleanup if not already resolved.
- Hatchery smoke/regression refresh.

**Avoid**:

- HATCHERY-007 UI/reveal implementation.
- Fusion implementation.
- Dragon presentation contracts.

### Option 2: Planning + Evidence Sprint

**Goal**: Reduce future uncertainty without pulling another risky integration story.

**Likely scope**:

- `/create-stories fusion-engine`.
- SCENE-003 manual launch evidence.
- BATTLE-007 source/content evidence.
- Readiness-gate HATCHERY-006 or first Fusion story.

**Avoid**:

- Multiple implementation stories.
- UI/reveal work.

### Option 3: Fusion Kickoff Sprint

**Goal**: Start Fusion Core only after stories are generated and ready.

**Likely scope**:

- First Fusion story from generated story set.
- Focused Fusion formula/validation tests.
- No broader Core loop integration yet.

**Avoid**:

- Campaign reward/content lock work.
- Dragon presentation work.
- Hatchery UI work.

---

## 8. Blocked / Do Not Pull Yet

| Item | Current Status | Why blocked | Unblock condition |
|---|---|---|---|
| DRAGON-006 - Progression Presentation Contract | Blocked | Presentation contract dependencies are not ready. | UX/presentation event scope is defined and testable. |
| DRAGON-007 - Cross-System XP Source Contracts | Blocked | Cross-system XP sources are not all implemented. | Hatchery/Fusion/Campaign XP routes are available for integration validation. |
| ECO-004 - Economy Content Lock Evidence | Blocked | Content lock evidence depends on broader authored reward/catalog readiness. | Campaign/shop/economy authored content validation path exists. |
| HATCHERY-007 - Hatchery Ring UI And Reveal Evidence Contract | Blocked | UI/reveal presentation evidence should follow service contract completion. | HATCHERY-006 post-commit/preview contract is complete and UX scope is ready. |

---

## 9. Evidence Ledger

| Evidence Need | Current Roadmap Treatment | Target Artifact |
|---|---|---|
| Sprint 04 smoke | Required before Sprint 04 closeout. | `production/qa/smoke-sprint-04-*.md` |
| Sprint 04 QA sign-off | Required after smoke and scope decision. | `production/qa/qa-signoff-sprint-04-*.md` |
| SCENE-003 manual launch evidence | Resolve or explicitly carry forward. | `production/qa/evidence/scene-003-manual-launch-evidence.md` |
| BATTLE-007 source/content evidence | Resolve or explicitly carry forward. | `production/qa/evidence/battle-007-animation-manifest-source-content-evidence.md` |
| HATCHERY-005 focused evidence | Preserved in story-done evidence; rerun in Godot-enabled environment if needed for final QA. | HATCHERY-005 story + test output |
| Hatchery slice evidence after HATCHERY-006 | Required before Hatchery service completion. | Hatchery test run output / QA evidence |
| Fusion story readiness evidence | Required before Fusion implementation. | Fusion story-readiness report(s) |

---

## 10. Roadmap Maintenance Rules

Update this file whenever one of the following changes:

- A sprint closes or a new sprint is planned.
- An epic gains new stories.
- A blocked story becomes ready.
- QA sign-off adds, resolves, or carries forward a condition.
- The active implementation lane changes in `production/session-state/active.md`.

When updating:

- Keep roadmap items traceable to source artifacts.
- Move completed items into the relevant sprint/QA/retro artifacts rather than growing this file indefinitely.
- Preserve the blocked-work table until each blocker is resolved by a concrete artifact.
