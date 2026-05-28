# Contributing to Dragon Forge

Dragon Forge is an active Godot 4.6 game project. Contributions should be
small, testable, and tied to a story, bug, or clearly described gameplay need.

## Good Contributions

- Fix a reproducible gameplay, tooling, or test failure.
- Implement a scoped story from `production/epics/`.
- Improve assertions, fixtures, or QA evidence for an existing system.
- Clarify design, architecture, or production docs without changing scope.

Avoid broad rewrites, unrelated cleanup, or template/tooling churn in the same
change as gameplay work.

## Local Checks

Run the relevant focused GUT suite first, then the broader unit/integration
suite when the change touches shared runtime behavior:

```bash
godot --headless --path . \
  -s res://addons/gut/gut_cmdln.gd \
  -gdir=res://tests/unit \
  -gdir=res://tests/integration \
  -ginclude_subdirs \
  -gexit
```

Include the exact test command and result summary in the pull request or story
handoff.

## Code Style

- Follow the existing GDScript style in nearby files.
- Prefer typed payload/result objects for runtime boundaries.
- Keep save mutations inside transaction helpers.
- Keep UI/presentation concerns out of core service logic.
- Add only the comments that make non-obvious behavior easier to maintain.

## Pull Requests

Pull requests should include:

- The story, bug, or design document that motivated the change.
- A concise summary of runtime behavior changed.
- Focused test evidence and any broader regression evidence.
- Known limits or intentionally deferred scope.

Use conventional commit messages when possible, such as:

```text
feat: add hatchery duplicate shiny upgrade settlement
fix: prevent staged save mutation leak on pull failure
docs: update sprint handoff for hatchery review
```
