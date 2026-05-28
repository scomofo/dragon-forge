# Sprint 02 - 2026-05-28 to 2026-06-10

## Sprint Goal

Establish the first Core gameplay services on top of the completed Foundation layer: Dragon Progression, Economy Ledger, and the Battle runtime contract.

## Capacity

- Total days: 10
- Buffer: 2 days reserved for review, story-readiness repair, and Godot 4.6 integration drag
- Available: 8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| DRAGON-001 | [Stats, Stage, And Record Contract](../epics/dragon-progression/story-001-stats-stage-and-record-contract.md) | gameplay-programmer / godot-gdscript-specialist | 1.0 | Sprint 01 SaveData complete | Canonical stats, derived stage, shiny math, Void stat row, SPD internal stat, and defensive formula behavior pass unit coverage. |
| DRAGON-002 | [XP Loop And Resonance](../epics/dragon-progression/story-002-xp-loop-and-resonance.md) | gameplay-programmer | 1.5 | DRAGON-001 | XP thresholds, MAX_LEVEL cleanup, XP range invariants, XP_MAX_AWARD clamp, and Resonance charge consumption pass unit coverage. |
| DRAGON-003 | [Post-Commit Progression Events](../epics/dragon-progression/story-003-post-commit-progression-events.md) | gameplay-programmer / qa-tester | 1.0 | DRAGON-002, Save commit signals | Stage and stats events publish only after SaveTransaction commit success and never after injected failure. |
| ECO-001 | [Scrap Read, Affordability, And Results](../epics/economy-ledger/story-001-scrap-read-affordability-and-results.md) | gameplay-programmer | 0.5 | Sprint 01 SaveData complete | `EconomyLedger` read/affordability helpers return named results and preserve exact balances above 999. |
| ECO-002 | [Scrap Spend Transaction Boundary](../epics/economy-ledger/story-002-scrap-spend-transaction-boundary.md) | gameplay-programmer / qa-tester | 1.0 | ECO-001, Save transactions | Spend attempts mutate only staged transactions, cannot go negative, support exact-price spend, and roll back on commit failure. |
| BATTLE-001 | [Runtime Session And Payload Contracts](../epics/battle-engine/story-001-runtime-session-and-payload-contracts.md) | gameplay-programmer / godot-gdscript-specialist | 1.5 | Foundation Input Router, Semantic Events | Battle runtime is scene-local, TELEGRAPH-only for gameplay actions, returns typed payloads, and opens no save transactions. |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| DRAGON-004 | [Dragon Creation And Source Helpers](../epics/dragon-progression/story-004-dragon-creation-and-source-helpers.md) | gameplay-programmer | 1.0 | DRAGON-001, DRAGON-002 | Hatchery, Fusion, and Singularity creation helper contracts create canonical records and protect Void/shiny rules. |
| ECO-003 | [Scrap Reward Addition Boundary](../epics/economy-ledger/story-003-scrap-reward-addition-boundary.md) | gameplay-programmer | 0.75 | ECO-001 | Scrap rewards stage through EconomyLedger, preserve exact high balances, and do not deduct Scraps on defeat. |
| BATTLE-002 | [Damage, Type, Crit, And Stage Formulas](../epics/battle-engine/story-002-damage-type-crit-and-stage-formulas.md) | gameplay-programmer / systems-designer | 1.5 | BATTLE-001, DRAGON-001 | Damage, type, crit, Defend, stage, Elder branch, accuracy, and XP formulas pass unit coverage. |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| DRAGON-005 | [Save Load Integrity And Repair](../epics/dragon-progression/story-005-save-load-integrity-and-repair.md) | gameplay-programmer / qa-tester | 1.0 | DRAGON-001, DRAGON-002 | Invalid dragon records repair/discard according to GDD load rules and preserve derived stage after reload. |
| BATTLE-003 | [Status And Recoil Effects](../epics/battle-engine/story-003-status-and-recoil-effects.md) | gameplay-programmer | 1.0 | BATTLE-001, BATTLE-002 | Status apply, overwrite, DoT, Freeze, Paralysis, Guard Break, duration, and declaration-order rules pass unit coverage. |
| BATTLE-007 | [Animation Manifest Runtime Lookup](../epics/battle-engine/story-007-animation-manifest-runtime-lookup.md) | gameplay-programmer / technical-artist | 0.75 | BATTLE-001, existing manifest validator | Runtime clip lookup resolves through BattleAnimationManifest and does not hardcode move sprite paths. |

## Carryover From Previous Sprint

| Task | Reason | New Estimate |
|------|--------|--------------|
| None | Sprint 01 Foundation stories and QA sign-off are complete. | N/A |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|-------------|--------|------------|
| Dragon Progression service touches nested SaveData Resources and can leak staged mutations | Medium | High | Start with DRAGON-001/002 and verify staged isolation through SaveTransaction tests before downstream systems depend on it. |
| Battle Engine scope can balloon into full combat implementation | High | High | Keep BATTLE-001 to runtime/session/payload contracts; defer formulas/status/AI unless Must Have scope lands cleanly. |
| Economy Ledger is architecture-backed rather than a standalone GDD | Medium | Medium | Keep ECO stories narrow and trace to Shop/Campaign GDD requirements plus ADR-0009/control manifest. |
| Sprint 02 QA plan must stay aligned as stories change | Medium | Medium | Keep `production/qa/qa-plan-sprint-02-2026-05-27.md` in sync before any added or split story enters `/dev-story`. |
| Review mode is full but thread agent limit may block sidecar gates | Medium | Medium | Record local feasibility assumptions and run manual `/code-review` and `/story-done` gates per story. |

## Dependencies On External Factors

- Godot 4.6.3 local installation remains the implementation target.
- Sprint 02 QA plan is generated at `production/qa/qa-plan-sprint-02-2026-05-27.md` and must remain current if scope changes.
- Producer/QA sidecar agent spawning may require a fresh thread if full review gates are required.

## Definition Of Done For This Sprint

- [ ] All Must Have tasks completed.
- [ ] All Must Have stories pass `/story-done`.
- [ ] All Logic/Integration stories have passing unit/integration tests.
- [ ] `/smoke-check sprint` passes or documents why production shell smoke remains deferred.
- [ ] QA plan exists at `production/qa/qa-plan-sprint-02-2026-05-27.md`.
- [ ] QA sign-off report is APPROVED or APPROVED WITH CONDITIONS.
- [ ] No S1/S2 bugs in delivered Core services.
- [ ] Design/architecture documents updated for any deviations.
- [ ] Code review completed for each implemented story.

> QA Plan: `production/qa/qa-plan-sprint-02-2026-05-27.md`.

## Scope Check

If stories are added beyond this plan mid-sprint, run `/scope-check` on the affected epic before implementation continues.
