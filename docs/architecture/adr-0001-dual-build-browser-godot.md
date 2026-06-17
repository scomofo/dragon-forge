# ADR-0001: Two Parallel Implementations — React/Vite Browser Build + Godot 4.6 Runtime

## Status

Accepted

## Date

2026-06-16

## Last Verified

2026-06-16

## Decision Makers

Reverse-documented from implementation

## Summary

Dragon Forge ships as two parallel implementations of the same game simulation: a feature-complete React 18 + Vite browser build (`src/`) that serves as the deployed design lab and source of truth for systems and balance, and a Godot 4.6 runtime (`dragon-forge-godot/`) that re-implements the same simulation in GDScript to grow a longer-term RPG overworld plus authored battle scenes. This ADR documents why the project maintains two codebases rather than a single shared engine, and the conventions that keep them coherent.

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | React 18.3 + Vite 6 (browser build, primary) / Godot 4.6 (runtime, secondary) |
| **Domain** | Core / Scripting |
| **Knowledge Risk** | LOW — browser build is React 18 + Vite 6, well within training data. The Godot 4.6 side carries MEDIUM risk and is governed by its own ADRs. |
| **References Consulted** | `CLAUDE.md` (Project Overview), `vite.config.js`, `package.json`, `dragon-forge-godot/project.godot`, `src/battleEngine.js`, `dragon-forge-godot/scripts/sim/battle_engine.gd` |
| **Post-Cutoff APIs Used** | None on the browser side. The Godot runtime targets `config/features=PackedStringArray("4.6")`; any 4.6-specific behaviour is verified per its own ADRs. |
| **Verification Required** | None for the browser build. For cross-build parity, see the "Validation Criteria" section (sim modules must produce equivalent results). |

> **Note**: If Knowledge Risk is MEDIUM or HIGH, this ADR must be re-validated if the
> project upgrades engine versions. Flag it as "Superseded" and write a new ADR.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None — this is the foundational structural decision for the repository. |
| **Enables** | Any ADR that concerns the Godot overworld, authored battle scenes, or web→Godot porting conventions; any ADR that treats the browser build as the canonical balance/content source. |
| **Blocks** | None |
| **Ordering Note** | This ADR establishes that "browser build is source of truth for systems, balance, and content." Subsequent ADRs about gameplay systems should state which build(s) they apply to. |

## Context

### Problem Statement

Dragon Forge needs to be (a) shippable and iterable *now* as a deployed web experience for rapid design iteration, and (b) buildable into a longer-term RPG with an explorable overworld and authored, scene-driven battles — capabilities that are awkward to grow inside a hand-rolled React/DOM/CSS presentation layer. A single technology choice forces a trade between fast web iteration and the engine affordances (scene tree, 2D nodes, physics areas, autoloads) that the overworld vision needs. The decision could not be deferred: the browser build was already deployed and feature-complete, and the overworld work needed a real engine to start.

### Current State

The repository contains two complete, independently runnable game implementations plus one build-artifacts-only folder:

1. **Browser build (`src/`, `index.html`, `vite.config.js`)** — React 18 + Vite, deployed at `base: '/dragon-forge/'`. Feature-complete: hatchery/gacha, fusion, battle, campaign map, shop/crafting, daily challenge, Singularity endgame, journal milestones, narrative/lore. This is the live design lab and the declared source of truth for systems, balance, and content.
2. **Godot runtime (`dragon-forge-godot/`)** — Godot 4.6 project (`project.godot`, `config/features=PackedStringArray("4.6")`). Re-implements the same simulation in GDScript under `scripts/sim/`, with UI screen controllers under `scripts/screens/` and a one-zone overworld slice under `scripts/world/`. Reuses art from the browser build (`dragon-forge-godot/assets/`).
3. **`dragon-forge-reborn/`** — built artifacts only, no source; ignored unless explicitly targeted.

The two builds mirror each other module-for-module on the simulation side. Examples from the code:
- `src/battleEngine.js` ↔ `dragon-forge-godot/scripts/sim/battle_engine.gd` — same type-effectiveness lookup, same stage-multiplier damage formula, same crit model.
- `src/gameData.js` ↔ `dragon-forge-godot/scripts/sim/game_data.gd` (type chart, stage multipliers/thresholds, crit constants).
- `src/hatcheryEngine.js` ↔ `scripts/sim/hatchery_engine.gd`; `src/fusionEngine.js` ↔ `scripts/sim/fusion_engine.gd`; `src/singularityProgress.js` ↔ `scripts/sim/singularity_progress.gd`; `src/loreCanon.js` ↔ `scripts/sim/lore_canon.gd`.

The browser build has *no* overworld; the Godot build adds one (`scripts/world/world_screen.gd`, `player_dragon.gd`, `encounter_zone.gd`, `boss_gate.gd`). That overworld is the Godot build's intended gameplay differentiator, not a port.

There is nothing "wrong" with the current approach — this ADR is reverse-documenting a decision already embodied in shipped structure — but the duplication does carry an ongoing parity cost (see Consequences/Risks).

### Constraints

- **Deployment**: The web build must continue to deploy to a sub-path (`base: '/dragon-forge/'`) on static hosting (GitHub Pages-style), with all runtime assets resolvable under that base.
- **Engine**: The overworld vision (explorable 2D map, walk/fly character body, encounter trigger areas, gated boss nodes) maps naturally onto a scene-tree engine with 2D nodes and physics areas — Godot 4.6 — and poorly onto hand-built React/CSS.
- **Team/resource**: Solo/indie development. Two codebases must be maintainable by one person; the structural conventions must minimize the cognitive cost of keeping them in sync.
- **Compatibility**: Art is shared. The browser build's art under `public/assets/` is the source of truth; the Godot build keeps its own tracked copy under `dragon-forge-godot/assets/` because Godot's `.import` UID sidecars must travel with the files.
- **Testing**: The web build uses Vitest with `environment: 'node'` (engine modules are pure JS, no jsdom). The Godot build uses headless smoke tests (`scripts/tests/sim_smoke.gd`) and the GUT addon. The test toolchains are necessarily separate.

### Requirements

- The deployed web experience must remain fast to iterate (hot-reload, plain JS engine modules, node-runnable unit tests).
- The long-term build must support an explorable overworld and authored battle scenes.
- Both builds must agree on game rules and balance: equivalent inputs to `battleEngine`/`battle_engine`, `fusionEngine`/`fusion_engine`, etc. should produce equivalent outcomes.
- One build (the browser build) must be unambiguously canonical for systems/balance/content so the two never silently diverge on rules.
- Porting a system from web → Godot must follow a predictable mapping so parity work is mechanical, not creative.

## Decision

Maintain **two parallel implementations** of Dragon Forge in one repository, with a clear source-of-truth hierarchy and a fixed web→Godot mapping:

- **Browser build (`src/`)** is the **canonical** implementation for game systems, balance, and content. Design and balance changes land here first.
- **Godot runtime (`dragon-forge-godot/`)** re-implements the same simulation in GDScript and is the home of the overworld + authored-scene RPG direction. It is not a thin port; it adds capabilities the web build does not have.
- **`dragon-forge-reborn/`** is build output only and is out of scope.

The two builds are kept coherent by mirroring the web build's "pure engine vs. presentation" split into Godot's directory conventions, and by sharing art (with per-build tracked copies).

### Architecture

```
                         Dragon Forge (one repo)
                                  |
        +-------------------------+--------------------------+
        |                                                    |
  BROWSER BUILD (canonical)                          GODOT RUNTIME (long-term RPG)
  React 18 + Vite 6                                  Godot 4.6 (project.godot)
  base: '/dragon-forge/'                             main_scene = scenes/main.tscn
        |                                                    |
   App.jsx (screen switcher,                          scripts/main.gd (screen router)
   single `save` object)                                    |
        |                                              scripts/screens/*.gd  (Control)
   *Screen.jsx (presentation)                                |
        |                                              scripts/sim/*.gd  (pure logic)  <== mirrors src/*Engine.js
   *Engine.js (pure logic) ----- same rules/balance ---  battle_engine, fusion_engine,
   battleEngine, fusionEngine,        (parity)            hatchery_engine, game_data,
   hatcheryEngine, gameData,                              singularity_progress, lore_canon
   singularityProgress, loreCanon                              |
        |                                              scripts/world/*.gd  (overworld — NEW,
   persistence.js (localStorage)                          no web equivalent)
        |                                              autoloads: SignalBus, AudioDirector,
   public/assets/ (art source of truth) -- copied -->  InputRouter, SaveIO
                                                        dragon-forge-godot/assets/ (+ .import)
```

### Key Interfaces

The "contract" this decision creates is the **web→Godot porting mapping** and the **source-of-truth rule**, not a runtime API:

```
SOURCE-OF-TRUTH RULE
  systems / balance / content        -> author in src/ first (browser build)
  overworld / authored scenes        -> Godot-only; no web counterpart required

WEB -> GODOT PORTING MAP
  data / rules (stateless)           src/<name>Engine.js   -> dragon-forge-godot/scripts/sim/<name>_engine.gd
  content tables (no logic)          src/gameData.js, etc. -> scripts/sim/game_data.gd, etc.
  screen controller (presentation)   src/<Name>Screen.jsx  -> scripts/screens/<name>_screen.gd  (extends Control)
  reusable UI node                   (React component)     -> scripts/components/<name>.gd
  top-level screen routing           src/App.jsx           -> scripts/main.gd
  world-only behaviour               (none)                -> scripts/world/*.gd

PARITY CONTRACT (sim modules)
  Given equivalent inputs, sim modules in both builds must produce
  equivalent results — e.g. battleEngine.calculateDamage(...) and
  BattleEngine.calculate_damage(...) share the same formula:
    base = atk * stageMult * 2 - def * 0.5
    typed = base * typeEffectiveness  (×0.5 if defending)
    final = max(1, floor(typed * roll[0.85..1.0])); crit ×CRIT_MULTIPLIER

ART CONTRACT
  browser source of truth            public/assets/        (served at deploy base via assetUrl('/assets/...'))
  godot copy (must include .import)  dragon-forge-godot/assets/
  shared sprite                      add to BOTH trees
  repo-root assets/                  gitignored scratch only
```

### Implementation Guidelines

- Land systems/balance/content changes in `src/` first; replicate to `dragon-forge-godot/scripts/sim/` as a follow-up, keeping formulas and constants identical.
- In Godot, keep `scripts/sim/` stateless (no scene/node references) so it stays a faithful mirror of the pure `src/*Engine.js` modules and remains headless-testable (`sim_smoke.gd`).
- Do not back-port the overworld into the web build. The overworld is the Godot build's reason to exist; the web build stays a screen-switcher design lab.
- When adding a sprite used by both builds, place it in `public/assets/` *and* `dragon-forge-godot/assets/`; commit the Godot `.import` sidecars with it.
- Keep test toolchains separate (Vitest node env for web; GUT/headless smoke for Godot). Cross-build parity is verified by comparing outputs of mirrored sim functions, not by a shared test runner.

## Alternatives Considered

### Alternative 1: Single Godot build (port the web game and delete `src/`)

- **Description**: Make Godot 4.6 the only implementation; rebuild the deployed experience as a Godot web export and retire the React/Vite build.
- **Pros**: One codebase, no parity burden, single test toolchain, one art tree.
- **Cons**: Loses the fast web iteration loop (hot reload, trivial deploy to a static sub-path, plain-JS node-run tests). Godot's HTML5 export is heavier and less friction-free for a "design lab" that already ships. Throws away a feature-complete, deployed build.
- **Estimated Effort**: High (full reimplementation + re-validation of all balance) before regaining current functionality.
- **Rejection Reason**: The browser build is already deployed and feature-complete and is the fastest place to iterate on systems/balance. Collapsing to Godot now would trade a working asset for risk and delay with no near-term player-facing gain.

### Alternative 2: Single web build (extend React/Vite to do the overworld)

- **Description**: Keep only `src/`; build the explorable overworld, walk/fly movement, encounter areas, and gated boss nodes in React/DOM/CSS (or canvas/WebGL).
- **Pros**: One codebase, one deploy, keeps the fast web loop.
- **Cons**: Hand-rolling a 2D scene tree, character physics, trigger areas, and authored scenes in the browser re-invents exactly what Godot gives for free. High long-term complexity and maintenance for the differentiating feature.
- **Estimated Effort**: High and open-ended (effectively building a 2D game engine inside React).
- **Rejection Reason**: The overworld + authored-scene direction is precisely where an engine's scene tree, 2D nodes (`CharacterBody2D`), and physics areas (`Area2D`) pay off. Forcing it into React would maximize the cost of the part of the vision that most needs an engine.

### Alternative 3: Shared core extracted to a common language/transpile

- **Description**: Extract the pure simulation into one shared source (e.g. shared JS consumed by both, or a transpile/codegen step) so rules live in exactly one place.
- **Pros**: Eliminates sim-parity drift by construction.
- **Cons**: Godot runs GDScript, not JS; bridging requires either a JS runtime in Godot, a codegen/transpile pipeline, or contorting both builds to a lowest common denominator. Adds a fragile build dependency and obscures both codebases for a solo developer.
- **Estimated Effort**: Medium-high to build and maintain the bridge/codegen; ongoing toolchain risk.
- **Rejection Reason**: For a solo project, a documented manual mirror (idiomatic JS in `src/`, idiomatic GDScript in `scripts/sim/`) plus a parity contract is simpler and more maintainable than a codegen bridge. The duplication is small, stateless, and well-bounded.

## Consequences

### Positive

- The deployed web build stays a fast, low-friction iteration surface for systems, balance, and content — the canonical place to make game-rule decisions.
- The Godot build can pursue overworld/authored-scene gameplay using engine-native affordances without distorting the web build.
- Clear source-of-truth and porting conventions make cross-build work mechanical rather than ad hoc.
- Each build keeps a toolchain suited to it (Vitest node env; Godot headless/GUT), and stateless sim modules in both builds are independently and cheaply testable.

### Negative

- **Duplication / parity cost**: every systems or balance change must be replicated from `src/` into `scripts/sim/`, and the two can silently drift if not disciplined.
- **Double art tracking**: shared sprites must be placed in two trees (`public/assets/` and `dragon-forge-godot/assets/`, the latter with `.import` sidecars).
- **Two skill contexts**: contributors must hold both React/JS and Godot/GDScript conventions in mind.
- **No single end-to-end test**: parity is verified by comparing mirrored function outputs, not one suite.

### Neutral

- The repo carries two runnable games plus a build-artifacts folder (`dragon-forge-reborn/`); newcomers must learn which build is canonical for what.
- The Godot build is intentionally *ahead* in one area (overworld) and the web build is *ahead* in being feature-complete/deployed; "parity" only applies to the shared simulation, not the whole product.

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Sim drift: balance change lands in `src/` but not in `scripts/sim/` (or vice versa) | High | Medium | Source-of-truth rule (web first); mirror as an explicit follow-up; keep `scripts/sim/` stateless so functions map 1:1; headless `sim_smoke.gd` parity checks. |
| Art divergence: sprite added to one tree only | Medium | Medium | CLAUDE.md "Cross-build notes" rule (add to both trees, commit `.import`); `public/assets/` is canonical for the web build. |
| Effort dilution: solo dev split across two stacks slows both | Medium | Medium | Browser build is feature-complete; Godot work is the growth area, so attention is naturally staged rather than concurrent. |
| Godot 4.6 knowledge risk (near/post training cutoff) | Medium | Medium | Govern Godot-specific decisions in their own ADRs with verification; keep `scripts/sim/` engine-agnostic to limit exposure. |
| Reviewer confusion about which build a change targets | Low | Low | ADRs and PRs state the target build explicitly; this ADR establishes the convention. |

## Performance Implications

This is a structural/organizational decision, not a runtime change to either build; it does not alter the frame-time, memory, or load budgets of code that already exists. Budgets are owned per build.

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (frame time) | unchanged | unchanged | Web: 16.7ms (60fps) target; Godot: per its own ADRs |
| Memory | unchanged | unchanged | Per build; no shared-process overhead (separate runtimes) |
| Load Time | unchanged | unchanged | Web: deployed static bundle under `/dragon-forge/`; Godot: native/export |
| Network (if applicable) | N/A | N/A | Both builds are single-player; no networking |

## Migration Plan

No migration: this ADR documents a structure already present in the shipped repository. The conventions below are already in force.

1. Browser build remains canonical for systems/balance/content — no change required.
2. New systems are authored in `src/`, then mirrored into `dragon-forge-godot/scripts/sim/` following the porting map — already practiced.
3. Shared art is placed in both `public/assets/` and `dragon-forge-godot/assets/` — already practiced.

**Rollback plan**: If maintaining two builds proves unsustainable, collapse to a single build by adopting Alternative 1 (Godot-only) or Alternative 2 (web-only) and superseding this ADR. Because the simulation is duplicated as stateless modules, the surviving build already contains a complete copy of the rules, lowering rollback cost.

## Validation Criteria

- [ ] Browser build runs and deploys under `base: '/dragon-forge/'` (`npm run build` / `npm run preview`).
- [ ] Godot build launches from `scenes/main.tscn` and passes the headless smoke test (`scripts/tests/sim_smoke.gd`).
- [ ] Mirrored sim functions agree on outputs for equivalent inputs — e.g. `battleEngine` damage/type-effectiveness vs. `battle_engine.gd` `calculate_damage` / `get_type_effectiveness` produce the same results for the same stats and moves.
- [ ] Every sprite referenced by both builds exists in both `public/assets/` and `dragon-forge-godot/assets/` (with `.import` sidecars in the Godot tree).
- [ ] Each ADR/PR touching a game system states which build(s) it applies to.

## GDD Requirements Addressed

<!-- This section is MANDATORY. Every ADR must trace back to at least one GDD
     requirement, or explicitly state it is a foundational decision with no GDD
     dependency. Traceability is audited by /architecture-review. -->

Foundational — this is a repository-structure decision with no single GDD owner. It does not implement one system; it establishes *where and how* every system is implemented across two builds. The table below shows the cross-cutting systems whose GDDs both builds realize (browser canonical; Godot mirrors the simulation and adds the overworld). There is no `design/gdd/game-concept.md` in the repository at the time of writing; the per-system GDDs below collectively stand in for it.

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/campaign-map.md` | Campaign progression | Structured progression path from first dragon to Singularity | Browser build implements it canonically (`src/campaignMap.js`); Godot mirrors via `scripts/screens/campaign_map_screen.gd` and adds the explorable overworld (`scripts/world/`) as the long-term framing. |
| `design/gdd/hatchery-gacha.md` | Hatchery / Gacha | Acquire dragons via hatchery rolls | Shared rules in `src/hatcheryEngine.js` ↔ `scripts/sim/hatchery_engine.gd` under the source-of-truth + parity contract. |
| `design/gdd/fusion.md` | Fusion | Combine dragons per fusion rules | Shared rules in `src/fusionEngine.js` ↔ `scripts/sim/fusion_engine.gd`. |
| `design/gdd/dragon-progression.md` | Dragon progression | Leveling/stage thresholds and stat growth | Shared formulas/constants in `gameData.js`/`battleEngine.js` ↔ `game_data.gd`/`battle_engine.gd`/`dragon_progression.gd` (e.g. stage thresholds, stage multipliers). |
| `design/gdd/shop-and-crafting.md` | Shop / Crafting | Economy sinks and item crafting | Shared content tables (`shopItems`, `forgeData`) ↔ Godot `scripts/screens/shop_screen.gd` / `forge_screen.gd`. |
| `design/gdd/journal-milestones.md` | Journal milestones | Milestone reactions and narrative beats | `src/journalMilestones.js` / `loreCanon.js` ↔ `scripts/sim/lore_canon.gd`, mirrored as content. |
| `design/gdd/narrative-and-lore.md` | Narrative / Singularity endgame | Endgame corruption arc and lore canon | `src/singularityProgress.js` ↔ `scripts/sim/singularity_progress.gd`; both builds drive the same Singularity progression. |
| `design/gdd/audio.md` | Audio | Per-screen music/sfx on navigation | `src/soundEngine.js` (web) ↔ Godot `AudioDirector` autoload (`scripts/sim/audio_director.gd`). |

> Enables: all per-system ADRs to declare which build they target, and all
> Godot-specific ADRs (overworld, authored scenes, autoloads) to build on the
> "Godot mirrors the sim, owns the overworld" framing established here.

## Related

- Establishes conventions referenced by `CLAUDE.md` ("Project Overview", "Godot runtime", "Cross-build notes").
- Browser build evidence: `vite.config.js` (`base: '/dragon-forge/'`, `dragon-forge-godot/**` excluded from tests), `package.json`, `src/battleEngine.js`, `src/gameData.js`.
- Godot build evidence: `dragon-forge-godot/project.godot` (Godot 4.6, autoloads, `main_scene`), `scripts/sim/battle_engine.gd`, `scripts/sim/game_data.gd`, `scripts/world/*.gd`, `scripts/main.gd`, `scripts/tests/sim_smoke.gd`.
- Future ADRs: any decision about the Godot overworld, authored battle scenes, or the web→Godot porting toolchain depends on this ADR.
