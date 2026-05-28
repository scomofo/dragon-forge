# Adoption Plan

> **Generated**: 2026-05-21
> **Project phase**: Production
> **Engine**: Godot 4.6 + GDScript (not yet configured in studio template)
> **Template version**: v1.0+

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

**Context:** The game exists and is substantially built at `/Users/Scott_1/DEV/DF/dragon-forge`.
The Godot port has all 12 screen scenes/scripts, all core sim modules, GUT test framework, and 5
passing test files. This plan is about extracting existing design knowledge into the studio
template format — not creating new design from scratch. Source material for every step already
exists in `dragon-forge/CLAUDE.md`, `dragon-forge/docs/superpowers/specs/`, and the implemented code.

---

## Step 1: Fix Blocking Gaps

### 1a. Configure the engine in the studio template
**Problem:** `.claude/docs/technical-preferences.md` has `[TO BE CONFIGURED]` for all engine fields.
ADR skills, story routing, and `/code-review` specialist dispatch silently fail without this.

**Fix:** Run `/setup-engine` — it will walk through Godot 4.6 + GDScript configuration and write
all fields in `technical-preferences.md`. Key answers ready:
- Engine: Godot 4.6
- Language: GDScript
- Target platform: Desktop / Windows
- Primary input: Gamepad (with keyboard fallback)
- Test framework: GUT

**Time:** 15 min
- [ ] `.claude/docs/technical-preferences.md` fully populated (no `[TO BE CONFIGURED]` in critical fields)

---

### 1b. Create the game concept document
**Problem:** `design/gdd/game-concept.md` is missing. Most studio skills check for it as a prerequisite.

**Fix:** Run `/brainstorm dragon-forge` — or create it manually using the content already in
`dragon-forge/CLAUDE.md` (Project Overview section) and `dragonsim/Dragon Simulator Master Specs.md`.
The concept is fully defined; this is just formalizing it into the template's expected location and format.

Core concept (ready to paste):
> Dragon Forge is a 16-bit retro RPG dragon simulator — hatch, forge, fuse, and battle. Players
> collect elemental dragons (Fire, Ice, Shadow, Storm, Venom, Stone), raise them through 4 evolution
> stages, fuse them for stat boosts, battle through 12 elemental arenas and a campaign map, and
> face the Singularity endgame arc. Supervised by Professor Felix. Desktop-first, controller-native
> Godot 4.6 production build porting from a feature-complete React browser game.

**Time:** 30 min
- [ ] `design/gdd/game-concept.md` created with all 8 required sections

---

## Step 2: Fix High-Priority Gaps

### 2a. Create the systems index
**Problem:** `design/gdd/systems-index.md` is missing. `/gate-check`, `/create-stories`, and
`/architecture-review` all depend on it for system enumeration and status tracking.

**Fix:** Create `design/gdd/systems-index.md` listing the known systems. All of these are
implemented in both the browser build and Godot port:

| System | Layer | Priority | Status |
|--------|-------|----------|--------|
| Battle Engine | Simulation | MVP | Designed |
| Hatchery | Simulation | MVP | Designed |
| Fusion Engine | Simulation | MVP | Designed |
| Dragon Forge | Simulation | MVP | Designed |
| Campaign Map | Progression | MVP | Designed |
| Singularity | Progression | MVP | Designed |
| Shop | Economy | MVP | Designed |
| Journal | Narrative | Supporting | Designed |
| Save / Persistence | Infrastructure | MVP | Designed |
| Audio Director | Presentation | Supporting | Designed |
| Input Router | Infrastructure | MVP | Designed |

Run `/design-system systems-index` or create manually using the table above as a starting point.

**Time:** 20 min
- [ ] `design/gdd/systems-index.md` created with correct column structure and valid status values

---

### 2b. Create GDDs for core systems
**Problem:** No GDDs exist in `design/gdd/`. `/create-stories` cannot generate stories and
`/architecture-review` cannot trace requirements without them.

**Source material available for each system:**
- Battle: `dragon-forge/docs/superpowers/specs/2026-03-27-dragon-forge-combat-design.md`
  + `2026-05-01-dragon-forge-battle-feel-pass-design.md` + `src/battleEngine.js`
- Hatchery: `dragon-forge/docs/superpowers/specs/2026-03-27-dragon-forge-hatchery-design.md`
  + `src/hatcheryEngine.js`
- Fusion: `dragon-forge/docs/superpowers/specs/2026-03-27-dragon-forge-status-fusion-design.md`
  + `src/fusionEngine.js`
- Campaign Map: `dragon-forge/docs/superpowers/specs/2026-05-01-dragon-forge-campaign-map-design.md`
- Singularity: `dragon-forge/docs/superpowers/specs/2026-03-27-dragon-forge-singularity-phase1-design.md`
  + phase2 + phase3

**Fix:** Run `/design-system [system-name]` for each MVP system. The spec files and code are the
source of truth — the GDD formalizes what's already decided into the 8-section template format.

**Time:** 1–2 sessions (can be done system by system; start with Battle and Hatchery)
- [ ] `design/gdd/battle-engine.md` — 8 sections complete, Acceptance Criteria present
- [ ] `design/gdd/hatchery.md`
- [ ] `design/gdd/fusion-engine.md`
- [ ] `design/gdd/dragon-forge.md` (the forge/upgrade screen system)
- [ ] `design/gdd/campaign-map.md`
- [ ] `design/gdd/singularity.md`
- [ ] `design/gdd/shop.md`
- [ ] `design/gdd/save-persistence.md`

---

### 2c. Create ADRs for decisions already made
**Problem:** No ADRs exist. `/story-readiness` ADR checks silently pass everything; `/architecture-review`
has nothing to bootstrap the TR registry from.

**Decisions already made that need ADRs:**
- Browser build → Godot 4.6 port strategy (the rebuild design spec is the source)
- GDScript as implementation language (not C#)
- GUT as test framework
- JSON data tables for content (not hardcoded GDScript constants)
- SaveData as Godot Resource (not JSON save file)
- Signal Bus autoload pattern for cross-system communication
- Desktop-only target (no web export)

**Fix:** Run `/architecture-decision` for each. Use the Godot rebuild design spec
(`dragon-forge/docs/superpowers/specs/2026-05-01-godot-rebuild-design.md`) as the primary source.

**Time:** 30 min per ADR (7 ADRs = ~3–4 hours; prioritise the port strategy ADR first)
- [ ] `docs/architecture/adr-0001-godot-port-strategy.md` — Status field present
- [ ] `docs/architecture/adr-0002-gdscript-language.md`
- [ ] `docs/architecture/adr-0003-gut-test-framework.md`
- [ ] `docs/architecture/adr-0004-json-data-tables.md`
- [ ] `docs/architecture/adr-0005-savedata-resource.md`
- [ ] `docs/architecture/adr-0006-signal-bus-autoload.md`
- [ ] `docs/architecture/adr-0007-desktop-only-target.md`

---

### 2d. Create the control manifest
**Problem:** `docs/architecture/control-manifest.md` is missing. Story generation has no layer
rules to enforce.

**Fix:** Run `/create-control-manifest` after ADRs exist (it reads from ADRs to build the manifest).

**Time:** 30 min
- [ ] `docs/architecture/control-manifest.md` created with Manifest Version stamp

---

## Step 3: Bootstrap Infrastructure

### 3a. Register existing requirements (populates tr-registry.yaml)
`tr-registry.yaml` exists as an empty stub. Running `/architecture-review` reads the GDDs and
ADRs to populate it with stable TR-IDs.

Run `/architecture-review` after Steps 2b and 2c are complete.
**Time:** 1 session
- [ ] `tr-registry.yaml` populated with TR-IDs for all GDD requirements

### 3b. Create sprint tracking file
Run `/sprint-plan update` — or `/sprint-plan` to plan the first formal sprint for the Godot port.
**Time:** 30 min
- [ ] `production/sprint-status.yaml` created

### 3c. Set authoritative project stage
`production/stage.txt` is already set to `Production` (written by `/start`). Validate with:
Run `/gate-check Production`
**Time:** 15 min
- [ ] Gate check passed or blockers documented

---

## Step 4: Medium-Priority Gaps

### 4a. Architecture traceability matrix
`docs/architecture/architecture-traceability.md` is missing. This is generated by `/architecture-review`
in Step 3a — no separate action needed. Verify it was written after that run.
- [ ] `docs/architecture/architecture-traceability.md` present after `/architecture-review`

---

## Step 5: Godot Port — What Remains

Once the studio is bootstrapped, the Godot port has these known gaps from the rebuild design spec:

**Missing scripts** (listed in design spec but not yet in `dragon-forge-godot/scripts/`):
- `scripts/sim/animation_engine.gd`
- `scripts/components/egg_sprite.gd`
- `scripts/components/npc_sprite.gd`
- `scripts/components/vfx_overlay.gd`
- `scripts/components/toast.gd`

**Missing data/ directory** (content tables not yet auto-translated from JS to JSON):
- `data/game_data.json`
- `data/forge_data.json`
- `data/shop_items.json`
- `data/singularity_bosses.json`
- `data/journal_milestones.json`
- `data/lore_canon.json`
- `data/felix_dialogue.json`
- `data/sprite_manifest.json`

**Art gaps** (from `dragon-forge/TODO.md`):
- 24 dragon evolution sprite sheets (6 elements × 4 stages)
- 10 NPC sprite sheets (5 NPCs × idle + attack)

Use `/create-stories` after Step 2b to generate implementable stories for the remaining port work,
then `/sprint-plan` to organise them into sprints.

---

## What to Expect from Existing Stories

No stories exist yet in this studio. When you generate them with `/create-stories`, they will be
fresh and linked to the GDDs and ADRs created in Steps 2b and 2c. Do not manually create stories
before the GDDs and ADRs are in place — the generator needs them to produce correct TR-ID references.

---

## Re-run

Run `/adopt` again after completing Steps 1–3 to verify all blocking and high gaps are resolved.
The new run will reflect the current state of the project.
