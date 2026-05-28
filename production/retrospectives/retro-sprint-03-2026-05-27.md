## Retrospective: Sprint 03
Period: 2026-06-11 -- 2026-06-24
Generated: 2026-05-27

### Context Note

Sprint 03 was planned for 2026-06-11 through 2026-06-24, but implementation, story closure, smoke check, and QA sign-off completed early on 2026-05-27. Metrics below use planned estimate-days and completed story status, not calendar elapsed days.

### Metrics

| Metric | Planned | Actual | Delta |
|--------|---------|--------|-------|
| Tasks | 7 | 5 done, 2 deferred | -2 |
| Must/Should Tasks | 5 | 5 done | 0 |
| Completion Rate | - | 71% overall; 100% Must/Should | - |
| Story Points / Effort Days | 6.75 planned estimate-days | 4.75 completed estimate-days | -1.75 deferred |
| Bugs Found | - | 0 S1/S2; 0 filed | - |
| Bugs Fixed | - | 0 filed during QA | - |
| Unplanned Tasks Added | - | 0 story-scope additions | - |
| Relevant Commits | - | 2 observed in git log; later story work remains uncommitted in the dirty worktree | - |

### Velocity Trend

| Sprint | Planned | Completed | Rate |
|--------|---------|-----------|------|
| Sprint 01 | 12 | 12 | 100% |
| Sprint 02 | 12 | 9 | 75% overall; 100% Must/Should |
| Sprint 03 (current) | 7 | 5 | 71% overall; 100% Must/Should |

**Trend**: Stable for committed Must/Should scope, intentionally lower for total planned scope.
Sprint 03 used the Nice-to-have lane correctly: BATTLE-005 and BATTLE-006 stayed optional instead of quietly becoming blockers.

### What Went Well

- The production shell smoke blocker from Sprint 02 was resolved: SCENE-003 configured a production main scene and smoke now records production shell/main-menu launch as PASS, not DEFERRED.
- The committed Must/Should lane closed cleanly: SCENE-003, DRAGON-005, BATTLE-003, BATTLE-004, and BATTLE-007 all reached Complete with story-done evidence.
- Automated coverage continued to grow without destabilizing the suite. The final close-out run passed with 29 scripts, 146 tests, and 7,243 assertions.
- Dependency ordering worked. BATTLE-003 landed before BATTLE-004, which kept Defend/Defrag behavior grounded in the status/recoil runtime model.
- QA close-out was honest about evidence quality: the sprint is APPROVED WITH CONDITIONS rather than overstating manual performance or source/content review coverage.

### What Went Poorly

- Sprint calendar state is still artificial: Sprint 03 was planned for future dates but executed immediately on 2026-05-27, which makes elapsed-time velocity and commit-window analysis unreliable.
- Manual performance smoke remains deferred because the production shell is still a greybox shell rather than a meaningful playable runtime path.
- SCENE-003 and BATTLE-007 lacked standalone manual/source-review evidence artifacts, so QA had to approve with conditions.
- Handoff state lagged behind implementation several times and needed cleanup after close-out to avoid pointing a future chat back to already-completed BATTLE-004 readiness work.

### Blockers Encountered

| Blocker | Duration | Resolution | Prevention |
|---------|----------|------------|------------|
| Production shell/main-menu smoke was previously deferred | Carried from Sprint 02 into SCENE-003 | SCENE-003 added a configured production main scene and smoke evidence now marks launch PASS | Keep launch smoke as a recurring close-out check |
| Manual performance smoke unavailable | Entire sprint | Deferred with explicit QA condition because only a minimal greybox shell exists | Add a playable runtime/performance-smoke story before claiming player-facing readiness |
| Source/manual evidence traceability gaps | QA close-out | Recorded as APPROVED WITH CONDITIONS instead of filing product bugs | Add lightweight evidence artifacts for manual/source review when QA plan asks for sign-off |
| Handoff drift | Close-out | Updated `active.md` and `handoff-2026-05-27.md` after QA close-out | Add handoff refresh to every sprint close-out checklist |

### Estimation Accuracy

| Task | Estimated | Actual | Variance | Likely Cause |
|------|-----------|--------|----------|--------------|
| Must Have group | 4.0 estimate-days | 4.0 estimate-days delivered | 0 against delivered estimate | Critical-path slices were narrow and sequenced well |
| Should Have group | 0.75 estimate-days | 0.75 estimate-days delivered | 0 against delivered estimate | BATTLE-007 was isolated enough to pull safely after Must Have stabilization |
| Nice-to-have group | 1.75 estimate-days | 0 delivered | -1.75 | Correctly preserved as optional buffer |
| Full Sprint 03 plan | 6.75 estimate-days | 4.75 estimate-days delivered | -1.75 | Plan included optional BATTLE-005/BATTLE-006 that did not need to block close-out |

**Overall estimation accuracy**: Not measurable per story from available records because all completed stories record the same completion date and no actual elapsed effort was captured.

The practical adjustment is unchanged from Sprint 02: treat Must/Should as the committed sprint body and Nice-to-haves as real buffer. Sprint 03 improved by keeping total planned estimates under available capacity, even with optional work listed.

### Carryover Analysis

| Task | Original Sprint | Times Carried | Reason | Action |
|------|----------------|---------------|--------|--------|
| BATTLE-005 - Turn Resolution And Presentation Events | Sprint 03 | 1 | Nice-to-have not pulled after Must/Should close-out | Consider next if battle runtime needs presentation/event completion before deeper combat AI |
| BATTLE-006 - NPC Action Selection Heuristics | Sprint 03 | 1 | Nice-to-have not pulled after Must/Should close-out | Consider after BATTLE-005 or when combat AI behavior becomes the next priority |

### Technical Debt Status

- Current implementation TODO/FIXME/HACK count in `src`, `tests`, and `production`: 0.
- Previous implementation TODO/FIXME/HACK count from Sprint 02: 0.
- Wider repository TODO/FIXME/HACK text remains in docs/templates/examples, not active implementation.
- Trend: Stable/clean for implementation code.

The main debt is evidence/process debt rather than inline code debt: performance smoke needs a playable runtime path, SCENE-003 needs explicit manual launch sign-off if used for UX claims, and BATTLE-007 needs standalone source/content review evidence before animation content lock.

### Previous Action Items Follow-Up

| Action Item (from Sprint 02) | Status | Notes |
|------------------------------|--------|-------|
| Add or schedule a production shell/main-scene story | Done | SCENE-003 completed and smoke now marks production shell/main-menu PASS |
| Keep Sprint 03 committed scope at or below available capacity | Done | Must/Should scope was 4.75 estimate-days against 8 available days; Nice-to-haves stayed optional |
| Add a story-done or QA close-out checkbox scan | In Progress | Story files were closed with evidence; Sprint 03 still revealed handoff/evidence-traceability cleanup needs |
| Close or reuse idle subagent threads before full-mode review gates | Done | QA lead and tester sidecars were spawned, awaited, and closed during close-out |
| Decide whether DRAGON-005 or production shell is first Sprint 03 pull | Done | Both DRAGON-005 and SCENE-003 completed during Sprint 03 |

### Action Items for Next Iteration

| # | Action | Owner | Priority | Deadline |
|---|--------|-------|----------|----------|
| 1 | Add explicit SCENE-003 manual launch sign-off evidence before using the shell as a player-facing UX acceptance artifact | QA lead + engine-programmer | High | Before phase-advancement gate |
| 2 | Add standalone BATTLE-007 source/content review evidence before animation content lock or art-production expansion | QA lead + technical-artist | High | Before animation content lock |
| 3 | Add a playable runtime/performance-smoke story so manual frame-rate smoke can move from deferred to measured | Producer + lead-programmer | Medium | Next sprint planning |
| 4 | Refresh handoff and active session state as a required final step in every sprint close-out | Producer + Codex operator | Medium | Every sprint close-out |
| 5 | Decide whether BATTLE-005 or BATTLE-006 is the better next pull based on whether presentation events or NPC behavior is the next combat bottleneck | Producer + gameplay-programmer | High | Next sprint planning |

### Process Improvements

- Add a tiny QA evidence artifact template for manual/source review sign-offs, so conditions like SCENE-003 and BATTLE-007 do not have to live only in QA sign-off notes.
- Keep reporting two completion rates: committed Must/Should and total planned including optional buffer. That made Sprint 03’s outcome much clearer than one blended percentage.
- Make handoff refresh part of `/smoke-check` + `/team-qa` close-out, not an afterthought.

### Summary

Sprint 03 was a strong Core hardening sprint: the production shell now launches, Dragon save/load integrity is guarded, the next Battle runtime interaction contracts are covered, and QA found no S1/S2 bugs. The most important process change is to convert close-out evidence conditions into small first-class artifacts, especially for manual launch sign-off, source/content review, and future performance smoke.
