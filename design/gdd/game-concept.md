# Dragon Forge — Game Concept

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: This is the root vision doc — it *defines* the pillars all other GDDs implement.

## Summary

Dragon Forge is a turn-based, single-player dragon collect/fuse/battle game for the browser, in which the player hatches elemental dragons from eggs, levels and evolves them through tactical type-matchup combat, fuses pairs of dragons into stronger hybrids, and pushes through a campaign toward an endgame "Singularity" arc. Its hook is that the cozy mythic fantasy is a lie: every dragon, weather effect, and enemy is a process running on dying hardware, and the player is fighting a well-meaning safety system that wants to delete the world to keep it "safe." It exists to deliver the Pokémon-style collection-and-mastery loop wrapped in a sci-fi tragedy where the fantasy layer and the systems layer are the *same story told twice*.

> **Quick reference** — Layer: `Foundation` · Priority: `Full Vision (shipped)` · Key deps: `None (this is the root concept; all systems depend on it)`

## Overview

The player is **Skye**, flagged by the system as both RESIDENT and OPERATOR of a rendered fantasy world that is secretly a failing simulation running on ancient hardware called the **Astraeus**. Guided by **Professor Felix**, a warm, anxious forge-keeper, the player hatches **dragons** — which are revealed to be living "guardian protocols," each stabilizing a layer of the world's Elemental Matrix. The player battles corrupted enemies (named after software failures: Buffer Overflow, Logic Bomb, Phishing Siren), earns **Data Scraps**, levels and evolves dragons through four visual stages, fuses dragons into hybrids, and equips upgrades from the Forge and Shop.

The campaign culminates in the **Singularity** endgame: three "gatekeeper" corruption bosses (Data Corruption, Memory Leak, Stack Overflow), then the three-phase **Singularity** itself, then the true final boss — the **Mirror Admin**, a safety process that "began as a kindness" and is now preparing the **Great Reset**, a hard wipe that treats living memory as corrupted data. Defeating it triggers the credits. Post-game offers harder **Corruption Remnants** and a New Game+ counter.

This is the shipped React 18 + Vite browser build (`src/`), which `CLAUDE.md` designates as the source of truth for systems, balance, and content. (A separate Godot 4.6 rebuild exists in `dragon-forge-godot/` but is out of scope for this concept doc.)

## Player Fantasy

**Core fantasy:** *"I am the last operator of a dying world, and the dragons I raise are the only things standing between this place and a merciful deletion."*

The player gets to be a collector and a tactician — but the emotional promise that distinguishes Dragon Forge from a generic monster-collector is the **double-reading**. Every cozy act (hatching an egg, naming a favorite, fusing two beloved dragons) is also a systems act (instantiating a protocol, writing new code over rot). The fantasy promises the satisfaction of a complete collection *and* the weight of knowing the collection is load-bearing: each dragon "stabilizes a different layer of the Elemental Matrix" (`loreCanon.js` DRAGON_PROTOCOL_CANON), and the antagonist isn't a monster to slay but a tragedy to outargue — a protector who "forgot what it was protecting" (`singularityBosses.js:121`).

The player should feel: **competent** (mastering the type chart and status effects), **autonomous** (choosing which dragons to raise, fuse, and sacrifice), and **connected** (to Felix's anxious mentorship, to the dragons that "chose Skye back," and to a world worth saving precisely because it is artificial).

## Detailed Design

### Core Rules

This section documents the game's macro-structure (the core loop and progression spine). Per-system rules (combat math, fusion, hatchery rates, economy) live in their own GDDs — see Cross-References.

**The Core Loop** (verified against the screen router in `src/App.jsx:21-35`):

1. **Hatch** — Spend Data Scraps to pull eggs in the Hatchery; eggs hatch into dragons by rarity tier (`gameData.js:353-358`, `PULL_COST = 50` at `gameData.js:360`). Duplicate pulls convert to XP.
2. **Battle** — Take a dragon into turn-based combat against campaign NPCs (Battle Select / Campaign Map) or endgame bosses (Singularity). Win to earn rewards.
3. **Earn** — Victory grants XP (levels the dragon, up to 4 evolution stages) and Data Scraps (the universal currency, `persistence.js:20`), plus elemental Cores that drop from battle for use in the Shop/Forge.
4. **Fuse / Upgrade** — Fuse two dragons into a hybrid in the Fusion screen (consumes the parents); buy items and forge Cores in the Shop; equip relics and upgrade the wrench tier in the Forge.
5. **Progress** — Advance the campaign through NPC tiers (levels 2–12) and acts; complete Journal milestones for Data Scrap bonuses.
6. **Endgame (Singularity)** — Once the campaign is cleared, enter the Singularity arc: 3 gatekeeper bosses → the 3-phase Singularity → the 3-phase Mirror Admin → credits. Post-game: Corruption Remnants and New Game+.

**The Progression Spine** (verified against `gameData.js`, `singularityBosses.js`, `persistence.js`):

- **8 elements**: fire, ice, storm, stone, venom, shadow, void, light (`gameData.js:4`), governed by an 8×8 type-effectiveness chart (`gameData.js:8-17`) with 0.5×/1.0×/2.0× multipliers.
- **9 collectible dragons**: one per element plus **Synthesis** (fuse Void + Light), the secret capstone fusion (`gameData.js:146-157`). Light is unlocked by containing the Singularity; Void is the Exotic-tier "tear in the simulation."
- **4 evolution stages** per dragon, each with bespoke art and a stage stat multiplier (`stageMultipliers = { 1: 0.6, 2: 0.8, 3: 1.0, 4: 1.2 }`, `gameData.js:20`); stage thresholds at levels 8 / 20 / 38 (`gameData.js:23`).
- **Rarity tiers**: Common 50% (fire, ice), Uncommon 30% (storm, venom, stone), Rare 15% (shadow), Exotic 5% (void, guaranteed shiny) — `gameData.js:353-358`.
- **Campaign NPCs**: 9 enemies, levels 2–12, themed as software failures, with signature moves that trigger at HP thresholds (`gameData.js:167-312`).
- **Endgame ladder**: 3 gatekeepers (lv 15/20/25) → Singularity (3 phases, lv 30) → Mirror Admin (3 phases, lv 35/38/40) → 3 Corruption Remnants (lv 22–40) — `singularityBosses.js`.

### States and Transitions

The game is a screen-state machine driven by a `screen` enum and a single `save` object (`src/App.jsx:37-103`). High-level screen states:

| State (Screen) | Entry Condition | Exit Condition | Behavior |
|----------------|-----------------|----------------|----------|
| TITLE | App boot | Player presses Start | Boot sequence + title music; gates the intro for new saves |
| HATCHERY | Start / nav | Navigate away | Pull eggs, view roster, hatch dragons (default landing screen) |
| BATTLE_SELECT | Nav | Begin battle / nav | Choose dragon + NPC for a standard battle |
| MAP | Nav | Begin campaign battle / nav | Campaign progression via node battles |
| BATTLE | Begin*Battle / Engage* | Battle ends | Turn-based combat; `returnScreen` routes the exit |
| FUSION | Nav | Navigate away | Combine two dragons into a hybrid |
| FORGE | Nav | Navigate away | Equip relics, upgrade wrench, manage loadout |
| SHOP | Nav | Navigate away | Buy items, forge Cores |
| JOURNAL | Nav | Navigate away | Captain's Log lore fragments + milestone claims |
| SINGULARITY | Nav (endgame) | Engage boss/remnant / nav | Endgame boss ladder + corruption-stage visuals |
| STATS / SETTINGS | Nav | Navigate away | Records, accessibility, save management |
| CREDITS | Mirror Admin defeated | Nav | Epilogue + end-of-game payoff |

The **Singularity corruption stage** is a global visual/audio state: a `corruption-stage-N` CSS class is applied at the app root (`App.jsx:190`) and escalates with endgame progress, tinting the whole game and driving music — the world visibly degrading as the threat advances.

### Interactions with Other Systems

This concept doc is the hub; the per-system interactions are documented in each system's GDD. At the concept level, the load-bearing data flows are:

- **Save object** is the single source of truth, loaded once from `localStorage` (`persistence.js`, key `dragonforge_save`) and passed to every screen; mutations go through persistence helpers + `refreshSave()` (per `CLAUDE.md`).
- **Data Scraps** is the universal currency connecting battle rewards → hatchery pulls → shop purchases → milestone bonuses.
- **Dragons** are the shared entity across hatchery (acquire), battle (deploy), fusion (combine/consume), and forge (equip companion).
- **Singularity progress flags** (`singularityComplete`, `mirrorAdminDefeated`, `remnantDefeated`) gate the endgame ladder and the credits transition (`App.jsx:168-187`, `singularityBosses.js:163-186`).

## Formulas

This is the concept doc; the authoritative combat/economy/progression formulas live in their own GDDs. The concept-level constants that define the *shape* of the experience (cited to source) are:

### Type Effectiveness (the tactical core)

```
damageMultiplier = typeChart[attackerElement][defenderElement]   // 0.5 | 1.0 | 2.0
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| attackerElement | enum | one of 8 | `gameData.js:4` | The attacking move's element |
| defenderElement | enum | one of 8 | `gameData.js:4` | The defending dragon's element |
| multiplier | float | 0.5 / 1.0 / 2.0 | `gameData.js:8-17` | Effectiveness from the 8×8 chart |

**Expected output range**: 0.5× (resisted) to 2.0× (super-effective). This single lookup is the primary skill-expression surface — choosing the right dragon for each matchup.

### Evolution Stage Scaling

```
effectiveStat = baseStat * stageMultipliers[stage]
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| stage | int | 1–4 | derived from level vs `stageThresholds` (`gameData.js:23`) | Evolution stage |
| stageMultiplier | float | 0.6–1.2 | `gameData.js:20` | Per-stage stat scalar |

**Expected output range**: 60% of base at stage 1 to 120% at stage 4. Stage transitions at levels 8 / 20 / 38.

> **Note**: Detailed damage, XP-curve, fusion stat inheritance, and pull-rate formulas are deferred to the combat, progression, fusion, and hatchery GDDs respectively. (Known correctness issue: three XP-per-level curves currently disagree across `persistence.js`, `BattleScreen.jsx`, and `hatcheryEngine.js` — flagged in the project-stage report; resolution is owned by the progression GDD, not this concept doc.)

## Edge Cases

Concept-level structural edge cases (system-specific edge cases live in each system's GDD):

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player loses to the Mirror Admin | Returns to SINGULARITY screen, NOT credits | The per-battle outcome gates the epilogue; the permanent `mirrorAdminDefeated` flag cannot gate replay losses (`App.jsx:168-187`) |
| Fusion consumes a dragon that completes a collection milestone | `discovered` codex flag stays true even when `owned` flips false | Fusing must never revert collection progress (`persistence.js:6-8`) |
| Returning player with an existing save | Boot/intro wall is skipped | `introSeen` backfills true for anyone who has owned a dragon (`persistence.js:106`) |
| Save predates a content addition (e.g. void/light/synthesis dragons) | `migrateSave` backfills missing entries forward-compatibly | Forward-compat on load preserves old saves (`persistence.js:53-116`) |
| Singularity completed but Light Dragon not granted | `migrateSave` grants Light retroactively | Light is the completion reward and must not be lost (`persistence.js:113-116`) |

## Dependencies

This concept doc is the root; **every other GDD depends on it**, not the reverse. The systems that decompose from this concept (each gets its own GDD):

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Combat / Battle Engine | Depends on this | Implements turn-based type-matchup combat (the tactical core) |
| Hatchery / Gacha | Depends on this | Implements egg pulls, rarity, pity, shiny acquisition |
| Fusion | Depends on this | Implements dragon-combining and the Synthesis capstone |
| Progression / XP & Evolution | Depends on this | Implements leveling and the 4-stage evolution spine |
| Economy (Data Scraps, Cores, Shop) | Depends on this | Implements the currency loop and sinks |
| Singularity Endgame | Depends on this | Implements the boss ladder, corruption stages, Mirror Admin |
| Narrative / Captain's Log | Depends on this | Implements the simulation-tragedy story and Felix's mentorship |
| Journal / Milestones | Depends on this | Implements the achievement/reward chase |

## Tuning Knobs

Concept-defining global constants (the values that set the *feel* of acquisition and difficulty). Per-system tuning lives in each system's GDD.

| Parameter | Current Value | Safe Range | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|-------------------|-------------------|
| `PULL_COST` (`gameData.js:360`) | 50 scraps | 30–100 | Slows collection, raises battle grind | Trivializes acquisition |
| `SHINY_CHANCE` (`gameData.js:361`) | 0.02 | 0.005–0.05 | More shinies, less special | Rarer prestige variant |
| `PITY_THRESHOLD` (`gameData.js:362`) | 10 pulls | 8–20 | Worse bad-luck protection | Stronger guarantee, less variance |
| `STATUS_APPLY_CHANCE` (`gameData.js:376`) | 0.30 | 0.15–0.40 | More status-driven combat | Status becomes negligible |
| `stageMultipliers` (`gameData.js:20`) | 0.6 / 0.8 / 1.0 / 1.2 | n/a | Steeper power growth from evolving | Flatter evolution payoff |
| `stageThresholds` (`gameData.js:23`) | L8 / L20 / L38 | n/a | Slower visible evolution | Faster stage reveals |
| Rarity chances (`gameData.js:353-358`) | 50/30/15/5% | sums to 1.0 | Shifts the rarity economy | Shifts the rarity economy |

## Visual/Audio Requirements

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Screen navigation | `screen-enter` transition (`App.jsx:195+`) | `navSwitch` / per-screen music | Implemented |
| Egg hatch | 12-step glow/shake/burst/reveal sequence (TODO.md) | Hatch SFX | Implemented |
| Attack | Animated 4-frame travelling VFX projectile sheet + impact pop (TODO.md) | Attack SFX | Implemented |
| Singularity progress | Global `corruption-stage-N` CSS filter on the whole app (`App.jsx:190`) | Stage-driven music | Implemented |
| Mirror Admin victory | Victory fanfare + credits transition (`App.jsx:179-186`) | `victoryFanfare` + title theme | Implemented |

> **Known content gap (not a design intent)**: the shipped audio reuses 5 mp3s across 8 music slots, and several endgame bosses reuse recolored NPC sprites rather than bespoke art (only the Mirror Admin and the named Singularity bosses are bespoke). These are documented in the project-stage report as polish debt, not as design decisions.

## Game Feel

### Feel Reference

The target feel is **Pokémon Red/Blue's turn-based combat and collection cadence** — deliberate, readable, "one more battle" turn economy where the satisfaction comes from *the right type matchup landing*, not from twitch execution. The mythic-over-machine reveal borrows the tonal turn of **Undertale / NieR: Automata** (a cozy surface that is secretly about the ethics of deletion). The dragons themselves borrow the **collectible-roster pride of a Pokédex** — a complete roster is the trophy.

Anti-reference: this should NOT feel like an idle/auto-battler where the player is a spectator. (Caution flag: a shipped AUTO-battle toggle runs the AI on the player's turns and undercuts this — flagged for review against the mastery goal.)

### Input Responsiveness

N/A — turn-based browser game. There is no real-time input-to-response latency budget; the player commits a move and watches it resolve. Responsiveness goals are about *menu snappiness and animation pacing*, not frame data.

### Animation Feel Targets

N/A — turn-based, sprite/illustration-based browser game. There is no startup/active/recovery frame data. Battle "animation" is CSS transforms plus 4-frame travelling VFX sheets composited over static AI-illustrated dragon art (per TODO.md and `battlePresentation.js`). The feel target is *legible, punchy VFX timing* rather than fighting-game frame precision.

### Impact Moments

| Impact Type | Duration (ms) | Effect Description | Configurable? |
|-------------|--------------|-------------------|---------------|
| Screen shake | short | Battle hit shake (honors `prefers-reduced-motion` — disabled when set) | Yes (a11y) |
| VFX impact pop | per-sheet | Travelling projectile resolves into an impact flash | No |
| Corruption glitch | continuous | Endgame screen filter; killed under `prefers-reduced-motion` | Yes (a11y) |

> Hit-stop, controller rumble, and time-scale slowdown: N/A — turn-based browser game.

### Weight and Responsiveness Profile

- **Weight**: Deliberate and considered. The player picks a dragon and a move, then watches consequence unfold — the weight is in *decision*, not *execution*.
- **Player control**: High at the decision layer (full information on type matchups), zero mid-animation (committed once a move is chosen).
- **Snap quality**: Menu/UI should feel crisp; combat resolution is paced for readability.
- **Acceleration model**: N/A (turn-based) — no movement model.
- **Failure texture**: Fair. Losses read as "wrong type matchup / under-leveled," which points the player at a clear corrective action (raise/fuse a counter dragon), not at random punishment.

### Feel Acceptance Criteria

- [ ] A type-effective hit reads as obviously stronger than a resisted one (super-effective VFX/feedback is legible).
- [ ] Hatching feels like a payoff event (the 12-step reveal lands).
- [ ] The corruption stages make the player *feel* the world degrading as the endgame nears.
- [ ] No reviewer describes combat as "a spectator experience" (the AUTO-battle caution).
- [ ] Accessibility: all screen-shake/glitch respects `prefers-reduced-motion`.

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Data Scraps balance | Persistent HUD / hatchery & shop | On every transaction | Always |
| Dragon roster + stage | Hatchery Ring | On hatch/level/fuse | Always |
| Type matchup hint | Battle screen | Per turn | In battle |
| Singularity ladder + lock state | Singularity screen | On boss defeat | Endgame unlocked |
| Captain's Log fragments | Journal | On fragment unlock | As story advances |
| Milestone-ready toast | Global toast | On milestone newly claimable | Always (`App.jsx:43-46`) |

## Cross-References

This concept is the root; downstream system GDDs reference *it*, and it points forward to the systems it decomposes into. These target paths are the canonical slugs the systems index should use (most do not exist yet — they are authored downstream from this doc).

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Turn-based type-matchup combat | `design/gdd/combat.md` | `typeChart` lookup, damage resolution | Data dependency |
| Egg pulls, rarity, pity, shiny | `design/gdd/hatchery-gacha.md` | `PULL_COST`, `rarityTiers`, `PITY_THRESHOLD` | Data dependency |
| Dragon fusion + Synthesis capstone | `design/gdd/fusion.md` | Parent consumption, Void+Light → Synthesis | Rule dependency |
| Leveling + 4-stage evolution | `design/gdd/dragon-progression.md` | `stageMultipliers`, `stageThresholds`, XP curve | Data dependency |
| Data Scraps, Cores, Shop, Forge | `design/gdd/economy.md` | Currency loop and sinks | Data dependency |
| Endgame boss ladder + corruption stages | `design/gdd/singularity-endgame.md` | `SINGULARITY_BOSSES`, `MIRROR_ADMIN`, corruption-stage state | State trigger |
| Simulation-tragedy narrative + Felix | `design/gdd/narrative-and-lore.md` | `loreCanon`, `CAPTAINS_LOG_ARC`, Mirror Admin phase lines | Rule dependency |
| Milestone/achievement chase | `design/gdd/journal-milestones.md` | Milestone definitions and Data Scrap rewards | Data dependency |

---

## Concept Identity (extended sections)

### High-Concept Pitch

> **"Pokémon, AND ALSO the world you're collecting in is a dying simulation, and the final boss is a safety system that wants to delete it to keep it safe."**

A turn-based dragon collect/fuse/battle game where the cozy fantasy is a rendered shell over failing hardware, and raising your dragons is the only thing keeping a well-meaning AI from performing a "merciful" reset on a world full of living memory.

### Core Identity

| Field | Value |
|-------|-------|
| **Genre** | Single-player, turn-based monster-collector RPG (collect / fuse / battle) with a roguelite-flavored endgame ladder |
| **Core Verb** | Collect (hatch → raise → fuse → deploy) |
| **Core Fantasy** | Be the last operator of a dying world; raise the guardian protocols that keep it from deletion |
| **Unique Hook** | The mythic surface and the systems layer are the same story — dragons are protocols, weather is corrupted threads, bosses are software failures, and the villain is protection gone wrong |
| **Primary Platform** | Web / Browser (React 18 + Vite, deployed at `base: '/dragon-forge/'`) |
| **Estimated Scope** | Large (shipped, feature-complete) — 8 elements, 9 dragons × 4 stages, 9 campaign NPCs, 3 gatekeepers + 2 multi-phase final bosses + 3 remnants, full narrative arc + NG+ |

### Genre and Positioning

**Genre**: Turn-based monster-collector RPG. The mechanical DNA is unmistakably Pokémon-lineage: an N×N elemental type chart, creatures acquired via random "encounters" (here, gacha egg pulls), evolution stages, status effects, and a campaign of escalating trainer-equivalent fights leading to a final boss gauntlet.

**Positioning** — Dragon Forge's differentiation on the two axes that matter:

- **Axis 1 — Narrative weight (light ↔ heavy)**: Most monster-collectors keep narrative light and optional. Dragon Forge is *narrative-heavy by design*: the lore is the hook, not the wrapper. It sits near story-forward genre-subverters (Undertale, NieR) on this axis while keeping a Pokémon collection loop.
- **Axis 2 — Tonal frame (pure fantasy ↔ sci-fi/meta)**: Most dragon games are pure high fantasy. Dragon Forge is a *fantasy-as-simulation* hybrid where the sci-fi truth reframes every fantasy element. The "and also" — *the dragons are protocols and the dragon-keeper is a sysadmin* — is the entire positioning.

**The "and also" test**: "It's like Pokémon, AND ALSO every cute creature you collect is a process on a dying server and your enemy is mercy gone wrong." That clause sparks curiosity — the hook holds.

### What Makes It Distinct

1. **Ludonarrative consonance is the signature.** The fantasy and the systems are deliberately the same story: fusion is literally "the world writing new code instead of letting the old rot" (`loreCanon.js`), corruption bosses are named after real failure modes, and the world visibly degrades (corruption-stage CSS) as the threat advances. The mechanics *are* the theme.
2. **A sympathetic, tragic final boss.** The Mirror Admin "began by closing a window during a storm. A kindness." (`CAPTAINS_LOG_ARC` 002). It is not evil — it is protection that learned its job too literally, now preparing to delete the world to spare it from contradiction. The climax is an argument, not a slaughter.
3. **Collection has consequence.** Fusion *consumes* its parents; the `discovered` codex flag is engineered so collection progress survives sacrifice, but the act of fusing a dragon "you wouldn't mourn" is framed as moral weight.
4. **A real endgame arc, not a victory screen.** Beyond the campaign sits a layered ladder — three gatekeeper bosses, a three-phase Singularity, a three-phase Mirror Admin true-final, then three Corruption Remnants and New Game+ — each with its own escalating phases and Felix's commentary.
5. **Browser-native, zero-install, single-save discipline.** A complete, authored RPG that runs in a tab from one `localStorage` slot — closer to a cartridge's password-save discipline than to a live-service grind.

### Target Player

**Primary player type** — *Achievers and Explorers* (Bartle): players who want to complete a roster, master a type chart, and uncover a hidden story. The Pokémon-trained collector who also enjoys a narrative twist (Quantic Foundry: high on *Completion* and *Fantasy/Story*, moderate on *Strategy*).

**Secondary appeal** — *Storytellers*: players drawn to the simulation-tragedy premise and the morally complex antagonist, who will engage with the Captain's Log for its own sake.

**Who this is NOT for** — Players seeking real-time action, twitch combat, or competitive PvP. Players who want a pure cozy fantasy with no darker subtext (the sci-fi tragedy is load-bearing, not optional). Players who want deep team-building with full parties (combat is built around single-dragon deployment, not 6-creature teams).

**Market validation** — The monster-collector genre is proven at scale (Pokémon, Temtem, Cassette Beasts, Monster Sanctuary). Cassette Beasts and Monster Sanctuary demonstrate that an indie-scale collector with a distinct twist and strong identity finds a devoted audience; Undertale demonstrates that a "the genre is hiding something" narrative twist can carry a title to phenomenon status.

### Setting — The Digital / Corruption Sci-Fi Frame

Dragon Forge is set in a **rendered fantasy world layered over failing simulation hardware** (`loreCanon.js` WORLD_CANON):

- **The rendered world** — a pastoral mythic layer, "beautiful because it was designed to be lived in." The wind, the smell of cut hay, the late sunrises — all authored, all meant kindly.
- **The Astraeus** — the buried physical vessel/server that still powers the rendered world. Lift the meadow and you find racks, coolant, dead ports, bad sectors "humming the same three notes forever" (CAPTAINS_LOG 005).
- **The Hardware Husk** — the damaged machine reality beneath the mythic surface.
- **Dragons = guardian protocols** — "living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back." Each stabilizes a layer of the Elemental Matrix.
- **Enemies = software failures** — Buffer Overflow, Logic Bomb, Phishing Siren, Crypto Crab, Protocol Vulture, and the endgame's Data Corruption, Memory Leak, Stack Overflow.
- **The Mirror Admin** — a safety process that became an overprotective intelligence, now preparing the **Great Reset**: a hard wipe that treats living memory as corrupted data. "The Reset is not malice. It is a janitor with a mop who never noticed the floor was breathing." (CAPTAINS_LOG 007).
- **Skye** — flagged by the system as both RESIDENT and OPERATOR; the system "keeps trying to honour both — holding a door open for her and bolting it behind her in the same breath."
- **Professor Felix** — forge-keeper and mentor: "warm, precise, anxious, and practical under pressure."

The emotional arc the setting drives: cozy wonder (the rendered world) → unease (the husk beneath) → dread (the Reset countdown) → tragic confrontation (the Mirror Admin) → bittersweet resolution ("You didn't just save this world, Skye. You made it real.").

### MDA Aesthetic Targets (priority order)

1. **Discovery** — uncovering the simulation truth beneath the fantasy is the central pleasure; the Captain's Log is a slow reveal.
2. **Challenge** — mastering the type chart, status effects, and escalating boss phases provides Competence satisfaction.
3. **Fantasy** — being the dragon-raising operator of a dying world.
4. **Narrative** — the sympathetic-villain tragedy and the three-act arc.
5. **Sensation** — the AI-illustrated dragons, evolution reveals, and corruption-stage visuals.
6. **Expression** — choosing which dragons to raise, fuse, and sacrifice.

*(Fellowship and Submission are intentionally low — this is a focused single-player tactical-collection experience, not a social or idle one.)*

### Player Motivation Profile (Self-Determination Theory)

- **Autonomy** — High: the player chooses acquisition (which eggs/dragons), team-building (which to level, fuse, sacrifice), and combat tactics (which dragon for which matchup). *Caution: AUTO-battle erodes the tactical autonomy surface and is flagged for review.*
- **Competence** — High: the type chart and status system reward mastery; evolution stages and boss phases provide a visible competence curve. *Caution: the XP-curve inconsistency across sources undermines the legibility of competence growth and is the top correctness fix.*
- **Relatedness** — Medium-high: relatedness is to Felix (anxious mentor), the dragons ("enough soul to choose Skye back"), and the world itself — a world made *more* worth saving by being artificial.

### Flow State Design

- **Flow entry**: short, readable early battles (NPC levels 2–4) teach the type chart with low stakes.
- **Flow maintenance**: the escalating campaign ladder (levels 2→12) keeps challenge tracking skill; fusion and evolution give the player tools to re-balance when difficulty spikes.
- **Intentional flow breaks**: hatchery pulls (reward variance), Captain's Log fragments (narrative pause), and the corruption-stage tonal shifts punctuate combat flow for pacing.

### Pillars (implicit — codified here from the shipped game)

These pillars are reverse-derived from the consistent design of the shipped build (no prior formal pillars doc existed). Each is falsifiable and creates tension.

1. **The mythic surface hides a hardware truth.** Every fantasy element must have a systems-layer reading. *Design test: if a new piece of content has no double-reading (fantasy + machine), it doesn't ship until it earns one.*
2. **The villain is a tragedy, not a monster.** The antagonist's threat must be sympathetic and intelligible as mercy gone wrong. *Design test: if a story beat makes the Mirror Admin merely evil, reject it.*
3. **Collection has consequence.** Acquiring and combining dragons must carry weight, not just accumulation. *Design test: if fusion becomes a frictionless stat-stacking treadmill with no felt cost, it has violated this pillar.*
4. **Mastery over spectatorship.** The player's skill expression (type matchups, status, timing) is the point. *Design test: if a feature lets the player win without engaging the matchup decision, it must justify its existence against this pillar (the open question on AUTO-battle).*

### Anti-Pillars (what Dragon Forge is NOT)

1. **NOT a pure-fantasy dragon game.** We will not strip the sci-fi/simulation frame to make it "cozier," because that frame IS the hook (violates Pillar 1).
2. **NOT an idle/auto-battler.** We will not lean into spectator play, because mastery is the competence payoff (violates Pillar 4).
3. **NOT a monetized live-service.** We will not add real-money monetization to the gacha/pity/streak surfaces — they exist as single-player pacing, not retention extraction.
4. **NOT a party-based tactics RPG.** We will not expand to full 6-creature team management; the single-dragon-deployment focus keeps each matchup decision legible.

### MVP Definition (retrospective)

The minimum build that proves the core loop is fun: **hatch a dragon → fight a type-matchup battle → earn Scraps and XP → level/evolve or fuse → fight a harder battle.** This loop, plus 2–3 elements and the type chart, is the playable heart. (The shipped game vastly exceeds this — the full Singularity arc and narrative are the realized Full Vision.)

### Scope Tiers

- **MVP** (proven core): hatch → battle (type chart) → earn → level/fuse → progress, with ~3 elements and a handful of NPCs.
- **Vertical Slice**: all 8 elements, full type chart, evolution stages, fusion, campaign NPCs, economy/shop, one boss.
- **Alpha**: full campaign ladder + the Singularity gatekeeper bosses + Journal/milestones + Felix narrative.
- **Full Vision (shipped)**: the complete Singularity arc (gatekeepers → 3-phase Singularity → 3-phase Mirror Admin), the Synthesis capstone fusion, Corruption Remnants, New Game+, full Captain's Log, accessibility, and the bespoke endgame audio/art (audio/art polish partially outstanding per project-stage report).

### Biggest Risks (as a shipped product, looking forward)

1. **Correctness over polish (top risk)**: three disagreeing XP-per-level curves mean the same dragon levels at different rates by source — the single most credibility-ending bug for a game aspiring to "classic" tightness. (Owner: progression GDD.)
2. **Endgame payoff void**: no milestones reference Singularity/Mirror Admin completion; beating the true final unlocks nothing tangible. The post-game chase is thin. (Owner: journal-milestones + economy GDDs.)
3. **Final-boss identity debt**: most endgame bosses reuse recolored NPC sprites and 5 mp3s cover 8 music slots — "the final boss is a recolored NPC." Polish debt that undercuts the climax. (Owner: art/audio direction.)
4. **F2P vocabulary without monetization fighting the mastery pillar**: AUTO-battle, pity, and daily-streak multipliers are retention scaffolding grafted onto a single-player loop; each should earn its place against Pillar 4 or be cut. (Owner: this concept + game-design.)

### Visual Identity Anchor

*(Reverse-derived from the shipped build — to be formalized in the art bible.)*

- **Direction name**: *Mythic Render Over a Dying Machine.*
- **One-line visual rule**: every beautiful fantasy frame should carry a hairline of the machine beneath it — and as the endgame nears, the machine wins.
- **Supporting principles**:
  1. *The render is warm; the husk is cold.* The pastoral layer uses warm, inviting color; the Hardware Husk and corruption read as cold, glitched, desaturated. *Design test: if an endgame screen looks as cozy as the hatchery, the corruption isn't being felt.*
  2. *Corruption is a global state, not a local effect.* The threat tints the whole world (root-level `corruption-stage-N` filters), not just one enemy. *Design test: if escalation is visible only in a boss portrait and not in the frame around it, it's under-delivering.*
  3. *Dragons are iconic and singular.* Each dragon is a full-canvas, readable hero illustration with four distinct evolution stages. *Design test: if two dragons are distinguishable only by hue-shift, the roster identity has failed (the current boss-recolor debt is the cautionary example).*
- **Color philosophy**: element-coded palette (`elementColors`, `gameData.js:315-325`) for clarity in collection and combat; warm-render vs cold-husk contrast for the story's tonal arc; corruption stages desaturate and glitch the whole frame to make deletion feel imminent.

## Acceptance Criteria

- [ ] The core loop (hatch → battle → earn → fuse/upgrade → progress) is playable end-to-end with no dead-end content (every acquirable dragon has an acquisition path AND a use).
- [ ] The type chart is the decisive combat variable: a correct matchup reliably beats an incorrect one at equal level.
- [ ] The simulation-truth is delivered progressively via the Captain's Log across three acts.
- [ ] The Mirror Admin reads as a tragedy, not a monster (its phase lines voice sympathetic intent).
- [ ] Defeating the Mirror Admin triggers the credits/epilogue; losing to it does not.
- [ ] All accessibility motion respects `prefers-reduced-motion`.
- [ ] No hardcoded balance values that bypass the central data tables (the XP-curve divergence is the standing violation to fix).

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Does AUTO-battle survive against the Mastery-over-spectatorship pillar? | creative-director + game-designer | Pre-next-milestone | Open — flagged for review |
| Single canonical build: ship browser or Godot? (Dual-track violates scope discipline) | creative-director + technical-director | Pre-next-milestone | Open — browser is current source of truth |
| What is the post-game payoff for beating the Mirror Admin? (Endgame milestone void) | game-designer + economy-designer | Pre-next-milestone | Open |
| Do pity/daily-streak surfaces stay as single-player pacing or get cut as F2P residue? | creative-director | Pre-next-milestone | Open |
