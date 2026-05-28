# Technical Preferences

<!-- Populated by /setup-engine. Updated as the user makes decisions throughout development. -->
<!-- All agents reference this file for project-specific standards and conventions. -->

## Engine & Language

- **Engine**: Godot 4.6
- **Language**: GDScript
- **Rendering**: Vulkan (primary), OpenGL3 compatibility fallback
- **Physics**: Jolt Physics (default in Godot 4.6)

## Input & Platform

<!-- Written by /setup-engine. Read by /ux-design, /ux-review, /test-setup, /team-ui, and /dev-story -->
<!-- to scope interaction specs, test helpers, and implementation to the correct input methods. -->

- **Target Platforms**: PC (Windows, macOS, Linux)
- **Input Methods**: Gamepad, Keyboard/Mouse
- **Primary Input**: Gamepad
- **Gamepad Support**: Full
- **Touch Support**: None
- **Platform Notes**: All UI must support d-pad/thumbstick navigation and face button activation. No hover-only interactions. Controller rumble via Input.start_joy_vibration().

## Naming Conventions

- **Classes**: PascalCase (e.g. `BattleEngine`)
- **Variables**: snake_case (e.g. `move_speed`)
- **Signals/Events**: snake_case past tense (e.g. `health_changed`)
- **Files**: snake_case matching class (e.g. `battle_engine.gd`)
- **Scenes/Prefabs**: PascalCase matching root node (e.g. `BattleScreen.tscn`)
- **Constants**: UPPER_SNAKE_CASE (e.g. `MAX_HEALTH`)

## Performance Budgets

- **Target Framerate**: 60fps
- **Frame Budget**: 16.6ms
- **Draw Calls**: 500 per frame
- **Memory Ceiling**: 2GB

## Testing

- **Framework**: GUT v9.x (Godot Unit Testing — installed at `addons/gut/`)
- **Minimum Coverage**: Core sim modules — `battle_engine`, `fusion_engine`, `hatchery_engine`, `save_io`, `singularity_progress`
- **Required Tests**: Combat formulas, fusion rules, hatchery randomisation, save round-trip

## Forbidden Patterns

<!-- Add patterns that should never appear in this project's codebase -->
- [None configured yet — add as architectural decisions are made]

## Allowed Libraries / Addons

<!-- Add approved third-party dependencies here -->
- GUT v9.x — unit testing framework (already installed at `dragon-forge-godot/addons/gut/`)

## Architecture Decisions Log

<!-- Quick reference linking to full ADRs in docs/architecture/ -->
- [No ADRs yet — use /architecture-decision to create one]

## Engine Specialists

<!-- Written by /setup-engine when engine is configured. -->
<!-- Read by /code-review, /architecture-decision, /architecture-review, and team skills -->
<!-- to know which specialist to spawn for engine-specific validation. -->

- **Primary**: godot-specialist
- **Language/Code Specialist**: godot-gdscript-specialist (all .gd files)
- **Shader Specialist**: godot-shader-specialist (.gdshader files, VisualShader resources)
- **UI Specialist**: godot-specialist (no dedicated UI specialist — primary covers all UI)
- **Additional Specialists**: godot-gdextension-specialist (GDExtension / native C++ bindings only)
- **Routing Notes**: Invoke primary for architecture decisions, ADR validation, and cross-cutting code review. Invoke GDScript specialist for code quality, signal architecture, static typing enforcement, and GDScript idioms. Invoke shader specialist for material design and shader code. Invoke GDExtension specialist only when native extensions are involved.

### File Extension Routing

<!-- Skills use this table to select the right specialist per file type. -->

| File Extension / Type | Specialist to Spawn |
|-----------------------|---------------------|
| Game code (.gd files) | godot-gdscript-specialist |
| Shader / material files (.gdshader, VisualShader) | godot-shader-specialist |
| UI / screen files (Control nodes, CanvasLayer) | godot-specialist |
| Scene / prefab / level files (.tscn, .tres) | godot-specialist |
| Native extension / plugin files (.gdextension, C++) | godot-gdextension-specialist |
| General architecture review | godot-specialist |
