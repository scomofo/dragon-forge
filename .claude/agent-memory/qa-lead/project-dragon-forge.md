---
name: project-dragon-forge
description: Dragon Forge project overview — engine, testing framework, QA standards, and key GDDs in scope
metadata:
  type: project
---

Dragon Forge is a Godot 4.6 indie game (GDScript) with a 49-agent Claude Code studio architecture. Testing uses GUT v9.x at `addons/gut/`. Unit tests go in `tests/unit/[system]/`, integration tests in `tests/integration/[system]/`, QA evidence in `production/qa/evidence/`.

**Why:** Shift-left QA is enforced — Logic and Integration stories require test evidence before Done. Visual/Feel/UI stories require documented manual evidence.

**How to apply:** Always classify story type before QA planning. Logic stories (formulas, state machines, AI) are BLOCKING gates — no test file = not Done. Integration stories (multi-system) require integration test or documented playtest. Visual/Feel/UI are ADVISORY gates.

Core systems with required test coverage: `battle_engine`, `fusion_engine`, `hatchery_engine`, `save_io`, `singularity_progress`.

GDDs live at `design/gdd/`. Key GDDs reviewed so far: `fusion-engine.md` (Designed, 2026-05-22), `battle-engine.md` (Approved, 2026-05-21), `dragon-progression.md`, `hatchery.md`.
