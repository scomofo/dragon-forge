# Dragon Forge

Dragon Forge is a Godot 4.6 / GDScript game project about collecting,
progressing, and battling elemental dragons. This repository contains the
current production implementation, design source, sprint evidence, and automated
test coverage for the rebuild.

## Current Status

- Engine: Godot 4.6
- Main scene: `res://scenes/bootstrap/BootstrapRoot.tscn`
- Active lane: Sprint 04 Hatchery
- Latest handoff: `production/session-state/handoff-2026-05-28-hatchery-005.md`
- Current next action: code review and story closure for
  `production/epics/hatchery/story-005-dragon-unlock-duplicate-xp-and-shiny-upgrade.md`

The active session state is tracked in `production/session-state/active.md`.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `src/` | Runtime GDScript systems for battle, dragon progression, economy, hatchery, save, input, content, and scene flow |
| `scenes/` | Godot scenes, including bootstrap and hub shell |
| `assets/` | Runtime art/content assets used by Godot |
| `design/` | GDDs, art direction, UX notes, and design registry files |
| `docs/architecture/` | ADRs, control manifest, traceability, and technical architecture docs |
| `production/` | Epics, stories, sprint plans, QA evidence, retrospectives, and handoffs |
| `tests/` | GUT unit, integration, smoke, fixtures, and evidence tests |
| `tools/` | Project automation and validation helpers |
| `prototypes/` | Earlier browser prototype and vertical-slice exploration |

## Running Tests

The project uses GUT for Godot tests. From the repository root:

```bash
godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit \
  -gdir=res://tests/integration \
  -ginclude_subdirs \
  -gexit
```

Focused suites can be run by passing the specific script path with `-gtest`,
for example:

```bash
godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd \
  -gtest=res://tests/integration/hatchery/test_dragon_unlock_duplicate_xp_and_shiny_upgrade.gd \
  -gexit
```

## Development Notes

- Keep gameplay logic in `src/` and tests in `tests/` matched to the story or
  system being changed.
- Story work should update the relevant file under `production/epics/` and
  record evidence in the appropriate QA or session-state document.
- Runtime systems should follow the architecture and ADRs under
  `docs/architecture/`.
- The current automation/workflow helper files are project tooling, not the
  product identity of this repository.

## License

See `LICENSE`.
