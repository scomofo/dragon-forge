# Archived production scaffold

These files were archived on **2026-06-16** because they were **orphan scaffold**, not a record of
pending work. They came from the Game Studios framework merge (`1cf25f0`) and describe a
story-driven Godot effort against a service/transaction architecture (`src/hatchery/…`,
`src/dragon/…`, `design/gdd/hatchery.md`, ADR-0006/0012) that **was never built in this repo**.

The functionality the HATCHERY-005 story describes — new-pull unlock + shiny, duplicate XP
(50/100/150 by rarity), level cap, shiny upgrade-no-downgrade — is **already shipped** in the real
engines: `dragon-forge-godot/scripts/sim/hatchery_engine.gd` (`apply_pull_result()`) and the mirror
`src/hatcheryEngine.js` (`applyPullResult()`). The story's two "blocking" code-review fixes are moot
against that implementation (it's a pure copy→mutate→return function with no scrap spend, no
`unknown_rarity` path, and no transaction to roll back).

`production/session-state/active.md` was archived specifically because the SessionStart hook read it
and told every new session to "continue where you left off" on a story that was already complete.

See `production/project-stage-report.md` (2026-06-16) for the full verification.

## Contents
- `session-state-active.md` — was `production/session-state/active.md`
- `epics-hatchery/` — was `production/epics/hatchery/`
- `hatchery-005-code-review-2026-05-28.md` — was `production/qa/`

Kept in place (genuine historical records, not active pointers): `production/qa/sprint-04-closeout-notes-2026-05-28.md`, `production/session-logs/`.
