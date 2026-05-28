# Project Upgrade Notes

This repository is the Dragon Forge game project. It is not an upstream
template distribution, so upgrades should be treated as project migrations.

## Before Upgrading

1. Read `production/session-state/active.md` for the current work lane.
2. Check `production/sprints/` for active sprint commitments.
3. Review relevant ADRs and control manifest rules under `docs/architecture/`.
4. Run the current focused and broad GUT suites so you have a clean baseline.

## Safe Upgrade Shape

- Keep engine, addon, and tooling updates in their own commits.
- Keep gameplay behavior changes tied to a story or bug.
- Record migration evidence in `production/qa/evidence/` or the affected story.
- Update `project.godot`, import metadata, and test fixtures together when an
  engine change requires it.

## Current Engine

Dragon Forge is pinned to Godot 4.6 in `project.godot` and
`docs/engine-reference/godot/VERSION.md`.

## Verification

After an upgrade, run:

```bash
godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit \
  -gdir=res://tests/integration \
  -ginclude_subdirs \
  -gexit
```

Then run any smoke or manual checks called out by the active sprint plan.
