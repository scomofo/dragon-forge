# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: GUT v9.x
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-05-26

## Directory Layout

```text
tests/
  unit/           # Isolated tests for formulas, state machines, and logic
  integration/    # Cross-system and save/load tests
  smoke/          # Critical path checklist for smoke-check gates
  evidence/       # Screenshot logs and manual sign-off records
```

## Running Tests

From the Godot project root:

```bash
godot --headless --import
godot --headless --path . -s res://addons/gut/gut_cmdln.gd -gdir=res://tests/unit -gdir=res://tests/integration -ginclude_subdirs -gexit
```

The import step registers GUT's global classes before the command-line runner executes. The test command expects GUT at `res://addons/gut/`, matching the project technical preferences.

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[scenario]_[expected]()`
- **Example**: `battle_damage_test.gd` -> `test_base_attack_returns_expected_damage()`

## Story Type To Evidence

| Story Type | Required Evidence | Location |
|---|---|---|
| Logic | Automated unit test | `tests/unit/[system]/` |
| Integration | Integration test or playtest doc | `tests/integration/[system]/` |
| Visual/Feel | Screenshot and lead sign-off | `tests/evidence/` |
| UI | Manual walkthrough or interaction evidence | `tests/evidence/` |
| Config/Data | Smoke check pass | `production/qa/` |

## CI

Tests run on pull requests and pushes to `main`. Failed tests should block merge.
