# Systems Index: Dragon Forge

> **Status**: Approved
> **Created**: 2026-06-16
> **Last Updated**: 2026-06-16
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Dragon Forge is a turn-based, single-player monster-collector RPG (collect → fuse
→ battle) shipped as a feature-complete React 18 + Vite browser build. Its core
loop — **hatch a dragon → fight a type-matchup battle → earn Scraps and XP →
level/evolve or fuse → fight a harder battle → progress toward the Singularity
endgame** — requires a tightly interlocking set of systems: a turn-based combat
engine with an 8×8 type chart and status effects (the tactical core), a gacha
hatchery and fusion lab (acquisition), a level/evolution progression curve, a
dual-currency economy with shop/forge sinks, a campaign DAG and a layered
Singularity boss ladder (structured progression), a narrative/lore delivery layer
(the simulation-tragedy hook), and the foundation services every screen leans on:
a single `localStorage` save object, input/gamepad handling, and the root concept
and pillars that govern what ships. This index enumerates every shipped system,
sorts them by dependency layer, and records the actual build order — all 19 GDDs
are reverse-documented at **Status: Implemented** against the live browser build,
which `CLAUDE.md` designates as the source of truth.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Game Concept (root vision doc) | Core | Full Vision | Implemented | design/gdd/game-concept.md | — |
| 2 | Game Pillars | Meta | MVP | Implemented | design/gdd/game-pillars.md | Game Concept |
| 3 | Save & Persistence | Persistence | MVP | Implemented | design/gdd/save-and-persistence.md | Dragon Progression, Hatchery — Gacha Pull System, Economy & Rewards, Fusion, Journal & Milestones, Shop & Crafting, Forge & Skye, Daily Challenge, Campaign Map |
| 4 | Input & Gamepad | UI | MVP | Implemented | design/gdd/input-and-gamepad.md | Campaign Map, Forge & Skye |
| 5 | Dragon Progression | Progression | MVP | Implemented | design/gdd/dragon-progression.md | Combat, Fusion, Hatchery — Gacha Pull System |
| 6 | Combat (Battle Engine) | Gameplay | MVP | Implemented | design/gdd/combat.md | Dragon Progression, Economy & Rewards, Fusion, Singularity Endgame, Daily Challenge, Forge & Skye |
| 7 | Hatchery — Gacha Pull System | Progression | MVP | Implemented | design/gdd/hatchery-gacha.md | Dragon Progression, Save & Persistence |
| 8 | Fusion | Progression | MVP | Implemented | design/gdd/fusion.md | Combat, Save & Persistence, Shop & Crafting, Dragon Progression |
| 9 | Economy & Rewards | Economy | MVP | Implemented | design/gdd/economy.md | Combat, Hatchery — Gacha Pull System, Fusion, Shop & Crafting, Daily Challenge, Singularity Endgame, Forge & Skye |
| 10 | Shop & Crafting | Economy | Alpha | Implemented | design/gdd/shop-and-crafting.md | Hatchery — Gacha Pull System, Fusion, Economy & Rewards, Save & Persistence |
| 11 | Campaign Map | Progression | MVP | Implemented | design/gdd/campaign-map.md | Combat, Hatchery — Gacha Pull System, Save & Persistence, Economy & Rewards, Singularity Endgame |
| 12 | Daily Challenge | Progression | Alpha | Implemented | design/gdd/daily-challenge.md | Combat, Save & Persistence, Economy & Rewards |
| 13 | Forge & Skye (Companion + Relics) | Gameplay | Alpha | Implemented | design/gdd/forge-skye.md | Combat, Save & Persistence, Singularity Endgame, Economy & Rewards, Hatchery — Gacha Pull System, Narrative & Lore |
| 14 | Singularity Endgame | Gameplay | Full Vision | Implemented | design/gdd/singularity-endgame.md | Combat, Save & Persistence, Campaign Map |
| 15 | Narrative & Lore | Narrative | Vertical Slice | Implemented | design/gdd/narrative-and-lore.md | Save & Persistence, Singularity Endgame, Journal & Milestones, Combat |
| 16 | Journal & Milestones | Progression | Alpha | Implemented | design/gdd/journal-milestones.md | Save & Persistence, Economy & Rewards |
| 17 | Audio | Audio | MVP | Implemented | design/gdd/audio.md | Combat, Singularity Endgame |
| 18 | VFX, Animation & Accessibility | Core | MVP | Implemented | design/gdd/vfx-animation-accessibility.md | Combat, Singularity Endgame |
| 19 | Player Guidance & Onboarding | UI | MVP | Implemented | design/gdd/player-guidance-and-onboarding.md | Narrative & Lore, Forge & Skye, Campaign Map, Shop & Crafting |

> **Note on dependency normalization**: The reverse-documentation pass cited some
> dependencies by working slugs that differ from the canonical files on disk (e.g.
> `battle-engine.md`/`battle-combat.md`/`status-effects.md`/`elements.md` →
> `combat.md`; `hatchery.md` → `hatchery-gacha.md`; `relics.md`/`singularity-progress.md`/`new-game-plus.md`
> → resolved to `forge-skye.md` / `singularity-endgame.md`; `persistence.md` →
> `save-and-persistence.md`; `lore-canon.md` → `narrative-and-lore.md`; `shop.md`
> → `shop-and-crafting.md`). The table above uses the **real** canonical paths.
> Raw source-code paths listed as "deps" in the reverse-doc pass (e.g.
> `persistence.js`, `gameData.js`, `soundEngine.js`) are implementation references,
> not system dependencies, and are excluded from the dependency columns.

---

## Categories

| Category | Description | Systems in Dragon Forge |
|----------|-------------|-------------------------|
| **Core** | Foundation systems everything depends on | Game Concept, VFX/Animation/Accessibility |
| **Gameplay** | The systems that make the game fun | Combat, Forge & Skye, Singularity Endgame |
| **Progression** | How the player grows over time | Dragon Progression, Hatchery — Gacha, Fusion, Campaign Map, Daily Challenge, Journal & Milestones |
| **Economy** | Resource creation and consumption | Economy & Rewards, Shop & Crafting |
| **Persistence** | Save state and continuity | Save & Persistence |
| **UI** | Player-facing information displays | Input & Gamepad, Player Guidance & Onboarding |
| **Audio** | Sound and music systems | Audio |
| **Narrative** | Story and dialogue delivery | Narrative & Lore |
| **Meta** | Systems outside the core game loop | Game Pillars |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | Required for the core loop to function. Without these, you can't test "is this fun?" | First playable prototype | Design FIRST |
| **Vertical Slice** | Required for one complete, polished area. Demonstrates the full experience. | Vertical slice / demo | Design SECOND |
| **Alpha** | All features present in rough form. Complete mechanical scope, placeholder content OK. | Alpha milestone | Design THIRD |
| **Full Vision** | Polish, edge cases, nice-to-haves, and content-complete features. | Beta / Release | Design as needed |

---

## Dependency Map

[Systems sorted by dependency layer — design and build from top to bottom.
Foundation systems are at the top; presentation/polish wrappers are at the bottom.
Dependencies below point to systems in the same or higher layers; the few
same-layer references that form cycles are called out in the Circular Dependencies
section.]

### Foundation Layer (no system dependencies, or only on the root concept)

1. **Game Concept** — the root vision doc; every other system decomposes from it.
2. **Game Pillars** — depends on: Game Concept. The falsifiable design tests that
   govern what ships; no runtime dependencies.
3. **Save & Persistence** — the `localStorage` save object is the single source of
   truth passed to every screen. Foundationally, it depends on no other *runtime*
   system to exist, but its schema is the union of all systems' persisted state
   (so its GDD references them bidirectionally).
4. **Input & Gamepad** — depends on: Campaign Map, Forge & Skye (per-screen
   navigation contracts). A foundation service whose *contracts* are defined by the
   screens it drives.
5. **Dragon Progression** — depends on: Combat, Fusion, Hatchery — Gacha. The
   level/XP/evolution curve that defines the shared dragon entity's stats.

### Core Layer (depends on foundation)

1. **Combat (Battle Engine)** — depends on: Dragon Progression, Economy & Rewards,
   Fusion, Singularity Endgame, Daily Challenge, Forge & Skye. The tactical core:
   speed-ordered resolution, damage formula, 8×8 type chart, 8 status effects,
   adaptive NPC AI, charged moves, signature moves, atk/def buffs, two-dragon bench.
2. **Hatchery — Gacha Pull System** — depends on: Dragon Progression, Save &
   Persistence. Weighted rarity roll, 10-pull pity, 2% shiny, dupe-to-XP, permanent
   discovered flag.
3. **Fusion** — depends on: Combat, Save & Persistence, Shop & Crafting, Dragon
   Progression. 23-recipe ALCHEMY table, three stability tiers, parent consumption,
   Synthesis capstone (Void + Light).
4. **Economy & Rewards** — depends on: Combat, Hatchery — Gacha, Fusion, Shop &
   Crafting, Daily Challenge, Singularity Endgame, Forge & Skye. Dual-currency
   faucets/sinks, battle reward formula, daily streak multiplier, NG+ scaling.
5. **Campaign Map** — depends on: Combat, Hatchery — Gacha, Save & Persistence,
   Economy & Rewards, Singularity Endgame. 9-node DAG of NPC encounters bridging
   early play to the endgame.

### Feature Layer (depends on core)

1. **Shop & Crafting** — depends on: Hatchery — Gacha, Fusion, Economy & Rewards,
   Save & Persistence. Buy tab + Forge (Core-crafting) tab; primary economic sink.
2. **Daily Challenge** — depends on: Combat, Save & Persistence, Economy & Rewards.
   Deterministic daily stat-boosted NPC; 3× scraps / 2× XP + streak multiplier.
3. **Forge & Skye (Companion + Relics)** — depends on: Combat, Save & Persistence,
   Singularity Endgame, Economy & Rewards, Hatchery — Gacha, Narrative & Lore. Forge
   hub, 3-tier wrench, 7 Analog Relics, `getRelicBattleModifiers` contract, Felix
   dialogue, Captain's Log unlock predicates.
4. **Singularity Endgame** — depends on: Combat, Save & Persistence, Campaign Map.
   Six-stage corruption meter, gatekeeper → Singularity → Mirror Admin ladder,
   Light Dragon unlock, NG+, Corruption Remnants.
5. **Narrative & Lore** — depends on: Save & Persistence, Singularity Endgame,
   Journal & Milestones, Combat. Captain's Log fragments, Felix dialogue, terminal
   stage narrative, world canon.
6. **Journal & Milestones** — depends on: Save & Persistence, Economy & Rewards.
   Milestone definitions and Data Scrap reward chase.

### Presentation Layer (depends on features)

1. **Audio** — depends on: Combat, Singularity Endgame. All SFX categories,
   music-per-screen routing, element-tinted combat SFX, low-HP heartbeat,
   crossfade/immediate transitions, persisted mute/volume.
2. **VFX, Animation & Accessibility** — depends on: Combat, Singularity Endgame.
   GSAP battle animations, CSS sprite swaps, VFX projectile strips, corruption
   overlays, two-layer `prefers-reduced-motion` contract.
3. **Player Guidance & Onboarding** — depends on: Narrative & Lore, Forge & Skye,
   Campaign Map, Shop & Crafting. Terminal boot sequence, NavBar guidance chip
   (11-priority next-action decision chain).

### Polish Layer (depends on everything)

1. *(None as a distinct layer — polish in Dragon Forge is delivered inside the
   Presentation Layer systems: corruption-stage VFX, bespoke endgame audio/art, and
   the `prefers-reduced-motion` a11y contract. Outstanding polish is content debt —
   reused audio mp3s and recolored boss sprites — tracked in the project-stage
   report, not as a separate system.)*

---

## Recommended Design Order

[Because Dragon Forge is shipped, this is framed as the actual build / dependency
order: the sequence in which a system must be stable before the systems that lean
on it. Systems at the same layer can be built in parallel. Effort: S = 1 session,
M = 2-3 sessions, L = 4+ sessions.]

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | Game Concept (root vision doc) | Full Vision | Foundation | creative-director, game-designer | L |
| 2 | Game Pillars | MVP | Foundation | creative-director, game-designer | S |
| 3 | Save & Persistence | MVP | Foundation | technical-director, game-designer | L |
| 4 | Dragon Progression | MVP | Foundation | game-designer | M |
| 5 | Combat (Battle Engine) | MVP | Core | game-designer, technical-director | L |
| 6 | Hatchery — Gacha Pull System | MVP | Core | game-designer | M |
| 7 | Fusion | MVP | Core | game-designer | M |
| 8 | Economy & Rewards | MVP | Core | game-designer | M |
| 9 | Campaign Map | MVP | Core | game-designer | M |
| 10 | Shop & Crafting | Alpha | Feature | game-designer | M |
| 11 | Daily Challenge | Alpha | Feature | game-designer | S |
| 12 | Journal & Milestones | Alpha | Feature | game-designer | S |
| 13 | Singularity Endgame | Full Vision | Feature | creative-director, game-designer | L |
| 14 | Narrative & Lore | Vertical Slice | Feature | narrative-designer, creative-director | L |
| 15 | Forge & Skye (Companion + Relics) | Alpha | Feature | game-designer, narrative-designer | M |
| 16 | Input & Gamepad | MVP | Foundation | technical-director | S |
| 17 | Audio | MVP | Presentation | audio-director | M |
| 18 | VFX, Animation & Accessibility | MVP | Presentation | technical-art, game-designer | M |
| 19 | Player Guidance & Onboarding | MVP | Presentation | game-designer, narrative-designer | M |

> **Note on ordering vs. layer**: Input & Gamepad is a Foundation-category service
> but appears late in the build order because its per-screen navigation contracts
> can only be finalized once the screens (Campaign Map, Forge) exist. This is a
> "foundation in concept, integrated last" service — common for input layers.

---

## Circular Dependencies

The reverse-documented dependency graph contains several mutual references. These
are **not** true architectural cycles — they are bidirectional GDD cross-references
(required by the design-doc rules: "if system A depends on B, B's doc must mention
A") between systems that interoperate at runtime through the shared save object and
the battle engine's modifier contracts. They were resolved by layering at build
time (the engine exposes a stable interface that the dependent systems read), not
by simultaneous design.

- **Combat ↔ Dragon Progression** — Combat reads stats from the progression curve
  (`calculateStatsForLevel`); Progression's XP is awarded by Combat. *Resolution:
  Progression's stat/curve functions are a pure module the engine calls; XP award is
  a one-way write from Combat into the save. No runtime cycle.*
- **Combat ↔ Fusion** — Combat consumes fused offspring stats; Fusion uses Combat's
  `calculateStatsForLevel` / `getStageForLevel` to compute inheritance. *Resolution:
  shared pure stat helpers live in the battle-engine module; Fusion imports them,
  Combat does not import Fusion. One-way at the code level.*
- **Combat ↔ Economy & Rewards** — Combat emits rewards; Economy defines the reward
  formula Combat applies. *Resolution: reward formula is data/config the engine
  reads; clean one-way data dependency.*
- **Combat ↔ Forge & Skye** — Combat reads `getRelicBattleModifiers`; Forge defines
  relics that only matter in battle. *Resolution: Forge exposes a pure modifier
  contract the engine queries each battle; one-way.*
- **Combat ↔ Singularity Endgame** — Combat fights the boss ladder; Singularity
  defines bosses and gates them on Combat outcomes. *Resolution: boss definitions are
  data; Singularity progress flags are one-way writes from Combat outcomes.*
- **Campaign Map ↔ Singularity Endgame** — Campaign unlocks lead into the
  Singularity; Singularity's corruption meter reads campaign/collection progress.
  *Resolution: both read the shared save object; neither imports the other's logic.*
- **Narrative & Lore ↔ Journal & Milestones** — Narrative fragments unlock on
  milestone predicates; milestones reference narrative beats. *Resolution: both read
  save flags; unlock predicates are pure functions over the save, no cycle.*

**Conclusion: No true circular dependencies.** Every apparent cycle is a
bidirectional documentation reference resolved at runtime by (a) the single shared
save object as the integration point and (b) pure stat/modifier helper modules in
the battle engine that dependents import one-way.

---

## High-Risk Systems

[Carried forward from the Game Concept's "Biggest Risks (as a shipped product,
looking forward)" — these are the systems where the shipped implementation carries
the most design or correctness risk going forward, regardless of priority tier.]

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Dragon Progression | Technical (correctness) | Three disagreeing XP-per-level curves across `persistence.js`, `BattleScreen.jsx`, and `hatcheryEngine.js` mean the same dragon levels at different rates by source — the top credibility risk for a game aiming at "classic" tightness. | Consolidate to a single canonical curve owned by the progression GDD; add a test that all three sources agree. (Owner: progression GDD.) |
| Journal & Milestones / Singularity Endgame | Design (payoff void) | No milestones reference Singularity/Mirror Admin completion; beating the true final unlocks nothing tangible. The post-game chase is thin. | Add endgame milestones + a tangible post-game reward. (Owner: journal-milestones + economy GDDs.) |
| Singularity Endgame (art/audio) | Scope (identity debt) | Most endgame bosses reuse recolored NPC sprites and 5 mp3s cover 8 music slots — "the final boss is a recolored NPC," undercutting the climax. | Prioritize bespoke final-boss art/audio in the art/audio direction backlog. (Owner: art/audio direction.) |
| Combat (AUTO-battle + F2P surfaces) | Design (pillar conflict) | AUTO-battle lets the player win without engaging the matchup decision (violates the Mastery-over-spectatorship pillar); pity/daily-streak are F2P retention scaffolding grafted onto a single-player loop. | Resolve the open question: each surface earns its place against Pillar 4 or is cut. (Owner: game-concept + game-design.) |
| Build strategy (Browser vs Godot) | Scope | Dual-track browser + Godot rebuild violates scope discipline; risks splitting effort. | Decide a single canonical build (browser is current source of truth per `CLAUDE.md`). (Owner: creative-director + technical-director.) |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 19 |
| Design docs started | 19 |
| Design docs reviewed | 19 |
| Design docs approved | 19 (reverse-documented at Status: Implemented) |
| MVP systems designed | 12/12 |
| Vertical Slice systems designed | 1/1 |
| Alpha systems designed | 4/4 |
| Full Vision systems designed | 2/2 |

> All 19 systems are shipped and reverse-documented at **Status: Implemented**
> against the live browser build (`src/`), which `CLAUDE.md` designates as the
> source of truth for systems, balance, and content.

---

## Next Steps

- [x] Review and approve this systems enumeration (all systems Implemented)
- [ ] Resolve the four standing high-risk items above (XP-curve correctness,
      endgame payoff, final-boss identity debt, AUTO-battle/F2P pillar conflict)
- [ ] Resolve the single-canonical-build open question (browser vs Godot)
- [ ] Keep `Last Verified` dates current on each GDD as the build evolves
- [ ] Re-run this index if a new system is added (e.g., a Godot-only overworld
      system that has no browser counterpart)
