# Dragon Forge — Master Architecture Overview

**Status:** Living document
**Last verified:** 2026-06-16
**Owner:** Technical Director
**Scope:** Whole-project technical vision — browser build (source of truth) + Godot runtime (production spine)

This document is the top-level map of how Dragon Forge is built. It explains the
browser build's architecture, the dual-build relationship with the Godot runtime,
and how each Accepted Architecture Decision Record (ADR) governs concrete systems.
For the *why* behind any single decision, follow the link into its ADR; for the
*what the feature does*, follow the link into its GDD.

---

## 1. System at a glance

Dragon Forge is a turn-based, monster-collecting browser game (hatch → fuse →
battle → Singularity endgame) shipped as **two parallel implementations of the
same simulation**:

| Build | Path | Role | Status |
|---|---|---|---|
| **Browser** | `src/`, `index.html`, `vite.config.js` | React 18 + Vite. The live, deployed game (`base: '/dragon-forge/'`). **Canonical source of truth** for systems, balance, content. | Feature-complete, deployed |
| **Godot runtime** | `dragon-forge-godot/` | Godot 4.6 production spine. Re-implements the same sim in GDScript and adds an overworld the web build lacks. | In progress |
| **Reborn** | `dragon-forge-reborn/` | Built artifacts only, no source. Ignore unless explicitly working on it. | Artifact-only |

The architectural through-line across both builds: **pure, serializable
simulation logic is kept strictly separate from presentation**, and **all player
progress is a single derived-from-primitives save object**. Those two invariants
are what make the game unit-testable in plain Node and portable from web to Godot.

---

## 2. Browser build architecture

### 2.1 Layer diagram

```
+===========================================================================+
|  PERSISTENCE                  localStorage  key: "dragonforge_save"        |
|  src/persistence.js   DEFAULT_SAVE schema | migrateSave (forward-compat)   |
|  ~40 read-modify-write mutators | loadSave/writeSave (crash-proof)         |
|                          [ADR-0003] [ADR-0009] [ADR-0010]                  |
+===========================================================================+
                                   ^  |  loadSave() once
                  helper + refresh |  v  single `save` object
+---------------------------------------------------------------------------+
|  APPLICATION SHELL                            src/App.jsx                  |
|  useState(loadSave()) -> single `save` | screen enum switcher             |
|  handleNavigate / handleBeginBattle / handleEngageBoss -> battleConfig     |
|  corruption-stage-N CSS class computed on render (derived, never stored)   |
|                                   [ADR-0010]                               |
+---------------------------------------------------------------------------+
        |  save prop fan-out + persistence helpers + refreshSave()
        v
+---------------------------------------------------------------------------+
|  PRESENTATION LAYER  —  *Screen.jsx React shells                          |
|  BattleScreen  HatcheryScreen  FusionScreen  ForgeScreen  ShopScreen      |
|  CampaignMapScreen  SingularityScreen  JournalScreen  Title/Settings/...  |
|  Owns: UI state, DOM refs, GSAP animation, sound, persistence side effects |
|  Helpers: NavBar, Toast, DragonSprite, NpcSprite, VfxOverlay, DamageNumber |
+---------------------------------------------------------------------------+
   |  serializable data in/out          |  reads tables (read-only)
   v                                     v
+--------------------------------+   +-------------------------------------+
|  ENGINE LAYER (pure logic)     |   |  PRESENTATION-LOGIC (pure)          |
|  battleEngine.js               |   |  battlePresentation.js              |
|    resolveTurn -> {player,npc, |-->|    getBattlePresentationProfile()   |
|      events}  effectiveAttack  |   |    (engine events -> display)       |
|  fusionEngine  hatcheryEngine  |   |  playerGuidance.js (11-step chain)  |
|  benchLogic  campaignMap       |   |  singularityProgress.js             |
|  dailyChallenge  xp/replay     |   |    scaleBossForPlayer (fixed-TTK)   |
|  No React / DOM / persistence  |   |  utils.js  assetUrl()               |
|  [ADR-0002] [ADR-0008]         |   |  [ADR-0007] [ADR-0006]              |
+--------------------------------+   +-------------------------------------+
   |  reads
   v
+---------------------------------------------------------------------------+
|  CONTENT / DATA-TABLE MODULES  (declarative tables + co-located pure      |
|  derive helpers; no mutation / RNG / persistence)            [ADR-0004]   |
|  gameData (moves, dragons, npcs, typeChart, STATUS_EFFECTS, scalars)      |
|  singularityBosses  shopItems  forgeData  journalMilestones  loreCanon    |
|  felixDialogue  sprites                                                    |
+---------------------------------------------------------------------------+
   |  /assets/...-rooted URLs resolved through assetUrl()
   v
+---------------------------------------------------------------------------+
|  ASSET PIPELINE                                              [ADR-0005]   |
|  public/assets/  (tracked, Vite-served at base) = browser source of truth |
|  assetManifest.test.js asserts every content-table URL existsSync()       |
+---------------------------------------------------------------------------+
```

### 2.2 The four load-bearing patterns

**1. Screen-switcher shell with a single save object.**
`src/App.jsx` holds the entire app in `useState(loadSave())`. A `screen` enum
selects which `*Screen.jsx` renders; the same `save` object is fanned out as a
prop to every screen. Battles are entered by setting `battleConfig` (via
`handleBeginBattle` / `handleBeginCampaignBattle` / `handleEngageBoss`) then
switching to the BATTLE screen; the `returnScreen` field on `battleConfig` is how
`handleBattleEnd` knows where to return. Mutations are made by screens calling
persistence helpers, then `refreshSave()` to re-read storage and re-render. No
Redux / Zustand / Context. ([ADR-0003](./adr-0003-single-localstorage-save-migrate.md), [ADR-0010](./adr-0010-deterministic-save-derived-progression.md))

**2. Pure engines, separated from React shells.**
`*Engine.js` modules import no React, DOM, or persistence — they take plain data
in and return plain data out. The load-bearing contract is the serializable
`{ player, npc, events }` object returned by `battleEngine.resolveTurn()`; the
shell walks those events through `battlePresentation.getBattlePresentationProfile()`
to choreograph the turn. This keeps balance unit-testable in Node (no jsdom) and
presentation swappable without risking combat outcomes. Each rules engine has a
`.test.js` sibling. ([ADR-0002](./adr-0002-engine-presentation-separation.md))

**3. Content as data-table modules.**
All dragons, moves, NPCs, bosses, shop items, forge recipes, relics, milestones,
and lore are plain ES-module tables, kept separate from the engines that
interpret them. Co-located *pure* derive helpers (`canForge`, `checkMilestones`,
`getRelicBattleModifiers`) read tables + a save snapshot read-only; mutation, RNG,
and persistence stay in the engines. New content usually means editing a table,
not an engine. ([ADR-0004](./adr-0004-content-as-data-modules.md))

**4. Save is primitive facts; everything else is derived on read.**
The save persists only primitive facts (`dragons[].owned/.level`,
`defeatedNpcs[]`, `singularityComplete`, `flags.fragmentsUnlocked[]`, etc.).
Every progression value, unlock gate, world-stage, and guidance hint is computed
as a pure function of the save at read time and never stored — including the
root `corruption-stage-N` CSS class, recomputed every render. The one
deliberate exception is the permanent `discovered` flag (§3, ADR-0009).
([ADR-0010](./adr-0010-deterministic-save-derived-progression.md))

---

## 3. Dual-build relationship (browser ↔ Godot)

The two builds are kept in deliberate parity, not merged:

- **Source of truth:** the browser build's systems, balance, and content are
  canonical. The Godot runtime re-implements the same simulation in GDScript.
- **Mirrored simulation:** `src/battleEngine.js` ↔
  `dragon-forge-godot/scripts/sim/battle_engine.gd`,
  `src/gameData.js` ↔ `scripts/sim/game_data.gd`. They share identical
  damage / type-chart formulas. Web→Godot porting map: rules → `scripts/sim/`
  (stateless), screen controllers → `scripts/screens/`, world nodes →
  `scripts/world/`.
- **What Godot adds:** a one-zone overworld slice (`scripts/world/`) the web
  build does not have — the Godot build's gameplay differentiator.
- **Test isolation:** `vite.config.js` excludes `dragon-forge-godot/**` from the
  Vitest run so the two test surfaces never collide.
- **Parity hazards to watch:** any decision that hand-inverts a formula must be
  ported in lockstep. The clearest example is fixed-TTK boss scaling
  ([ADR-0007](./adr-0007-fixed-ttk-boss-scaling.md)): `scaleBossForPlayer`
  hand-inverts the damage constants from `battleEngine.calculateDamage`, and the
  Godot port re-implements the scaler **minus** the replay multiplier — these
  must be kept in sync by hand.
- **Art:** tracked per build. `public/assets/` is the browser source of truth;
  `dragon-forge-godot/assets/` is the Godot copy carrying `.import` UID sidecars;
  the repo-root `assets/` is gitignored generator scratch. A sprite used by both
  builds must be added to both trees.
  ([ADR-0001](./adr-0001-dual-build-browser-godot.md), [ADR-0005](./adr-0005-browser-asset-pipeline.md))

```
        BROWSER BUILD (canonical)              GODOT RUNTIME (spine + overworld)
   +-----------------------------+        +-------------------------------------+
   | src/*Engine.js   (rules)    | ~~~~~> | scripts/sim/*.gd     (stateless)    |
   | src/gameData.js  (tables)   | ~~~~~> | scripts/sim/game_data.gd            |
   | src/*Screen.jsx  (shells)   | ~~~~~> | scripts/screens/*.gd (Control)      |
   | (no overworld)              |        | scripts/world/*.gd   (NEW overworld)|
   | App.jsx screen router       | ~~~~~> | scripts/main.gd      screen router  |
   | public/assets/  (truth)     | =====> | dragon-forge-godot/assets/ (+.import)|
   +-----------------------------+        +-------------------------------------+
            ~~~> re-implemented in parity      ===> art copied per-build
```

---

## 4. ADR → systems map

Each Accepted ADR and the systems it governs, with the GDD(s) that specify the
feature behaviour. All paths are relative to repo root `C:/dev/dragon-forge/`.

| ADR | Governs (systems / code) | Primary GDD(s) |
|---|---|---|
| [ADR-0001 — Dual build: React/Vite + Godot 4.6](./adr-0001-dual-build-browser-godot.md) | Whole-project structure; source-of-truth rule; web→Godot porting map; per-build art trees | [game-concept](../../design/gdd/game-concept.md), [game-pillars](../../design/gdd/game-pillars.md) |
| [ADR-0002 — Engine / presentation separation](./adr-0002-engine-presentation-separation.md) | `battleEngine`, `fusionEngine`, `hatcheryEngine`, `battlePresentation`; the `{player,npc,events}` turn contract; node-testability | [combat](../../design/gdd/combat.md), [vfx-animation-accessibility](../../design/gdd/vfx-animation-accessibility.md) |
| [ADR-0003 — Single localStorage save + migrateSave](./adr-0003-single-localstorage-save-migrate.md) | `persistence.js` (DEFAULT_SAVE, migrateSave, ~40 mutators), `App.jsx` useState/refreshSave; no external state lib | [save-and-persistence](../../design/gdd/save-and-persistence.md) |
| [ADR-0004 — Content as data-table modules](./adr-0004-content-as-data-modules.md) | `gameData`, `singularityBosses`, `shopItems`, `forgeData`, `journalMilestones`, `loreCanon`, `felixDialogue`, `sprites` + co-located pure derive helpers | [combat](../../design/gdd/combat.md), [fusion](../../design/gdd/fusion.md), [shop-and-crafting](../../design/gdd/shop-and-crafting.md), [forge-skye](../../design/gdd/forge-skye.md), [narrative-and-lore](../../design/gdd/narrative-and-lore.md) |
| [ADR-0005 — public/assets/ source of truth; per-build art trees](./adr-0005-browser-asset-pipeline.md) | `utils.js` `assetUrl()`, `sprites.js` strip() VFX resolution, `assetManifest.test.js`; three-tree art contract | [vfx-animation-accessibility](../../design/gdd/vfx-animation-accessibility.md) |
| [ADR-0006 — Economy faucet/sink: first-clear full / repeat ×0.25, keep daily ×3](./adr-0006-economy-faucet-sink-policy.md) | `BattleScreen.jsx` VICTORY reward branch, per-content defeat tracking in `persistence.js`, `dailyChallenge.js` ×3 + streak cap | [economy](../../design/gdd/economy.md), [daily-challenge](../../design/gdd/daily-challenge.md) |
| [ADR-0007 — Fixed-TTK boss scaling from real player stats](./adr-0007-fixed-ttk-boss-scaling.md) | `singularityProgress.js` `scaleBossForPlayer`; `App.jsx` handleEngageBoss/handleEngageRemnant; consumed by `BattleScreen.initBattle`; Godot parity (minus replay multiplier) | [combat](../../design/gdd/combat.md), [singularity-endgame](../../design/gdd/singularity-endgame.md) |
| [ADR-0008 — Combined attack-up cap (MAX_ATK_MULTIPLIER)](./adr-0008-combined-attack-up-cap.md) | `battleEngine.js` `effectiveAttack` (charge ×1.4 × buff ×1.3, clamped 1.5×), sole call site in `resolveAction`; `gameData` buff/charge flags | [combat](../../design/gdd/combat.md) |
| [ADR-0009 — Permanent discovered codex flag](./adr-0009-discovered-codex-flag.md) | `persistence.js` schema + migrateSave backfill + retroactive grant; `hatcheryEngine.applyPullResult`; `fuseDragons` parent preservation; `journalMilestones` discovered-vs-owned counts | [hatchery-gacha](../../design/gdd/hatchery-gacha.md), [journal-milestones](../../design/gdd/journal-milestones.md) |
| [ADR-0010 — Deterministic save-derived progression](./adr-0010-deterministic-save-derived-progression.md) | `singularityProgress.js` getSingularityStage/isSingularityUnlocked; `playerGuidance.js` 11-priority chain; `App.jsx` corruption-stage class on render; no persisted derived flags | [singularity-endgame](../../design/gdd/singularity-endgame.md), [player-guidance-and-onboarding](../../design/gdd/player-guidance-and-onboarding.md) |

> **GDD note:** the ADR write-ups for ADR-0004, ADR-0008, and ADR-0010 were
> authored when `design/gdd/combat.md` and
> `design/gdd/player-guidance-and-onboarding.md` did not yet exist and were
> referenced by path. Both files **now exist on disk** and are linked above. The
> economy ADR (ADR-0006) references `dailyChallenge.js`; the daily-challenge GDD
> is at [`design/gdd/daily-challenge.md`](../../design/gdd/daily-challenge.md).

---

## 5. GDD index

Specifications for what each system does (the ADRs above cover *how it is
architected*). All exist under [`design/gdd/`](../../design/gdd/):

**Foundation:** [game-concept](../../design/gdd/game-concept.md),
[game-pillars](../../design/gdd/game-pillars.md),
[dragon-progression](../../design/gdd/dragon-progression.md),
[save-and-persistence](../../design/gdd/save-and-persistence.md),
[input-and-gamepad](../../design/gdd/input-and-gamepad.md)

**Core:** [combat](../../design/gdd/combat.md),
[hatchery-gacha](../../design/gdd/hatchery-gacha.md),
[fusion](../../design/gdd/fusion.md),
[economy](../../design/gdd/economy.md),
[campaign-map](../../design/gdd/campaign-map.md),
[singularity-endgame](../../design/gdd/singularity-endgame.md),
[shop-and-crafting](../../design/gdd/shop-and-crafting.md),
[daily-challenge](../../design/gdd/daily-challenge.md),
[journal-milestones](../../design/gdd/journal-milestones.md)

**Feature / Presentation:** [forge-skye](../../design/gdd/forge-skye.md),
[narrative-and-lore](../../design/gdd/narrative-and-lore.md),
[audio](../../design/gdd/audio.md),
[vfx-animation-accessibility](../../design/gdd/vfx-animation-accessibility.md),
[player-guidance-and-onboarding](../../design/gdd/player-guidance-and-onboarding.md)

---

## 6. Architectural invariants (do-not-break list)

These are the contracts every change must preserve. Violating one is an
architecture-gate concern, not a code-review nit.

1. **Engines stay pure.** No React/DOM/persistence import inside any `*Engine.js`
   or pure-logic module. The `{player,npc,events}` turn object stays serializable. (ADR-0002)
2. **One save, one key.** All progress in `dragonforge_save`; mutations go
   through `persistence.js` helpers; `migrateSave` is additive/idempotent. (ADR-0003)
3. **Stable content IDs are a save contract.** Renaming a dragon/move/boss id
   requires a `migrateSave` step. (ADR-0004, ADR-0009)
4. **Don't persist derived state.** Progression, unlocks, world-stage, and
   guidance are pure functions of the save, computed on read. (ADR-0010)
5. **`discovered` is monotonic.** Set true on first-ever ownership, never
   reverted; collection milestones count `discovered`, roster prestige counts `owned`. (ADR-0009)
6. **Asset URLs go through `assetUrl()`** and must exist under `public/assets/`;
   `assetManifest.test.js` is the guard against silent 404s. (ADR-0005)
7. **Coupled-formula files change together.** `scaleBossForPlayer` hand-inverts
   `calculateDamage` constants — edit both, in both builds. (ADR-0007)
8. **Attack-up sources funnel through `effectiveAttack`** and respect
   `MAX_ATK_MULTIPLIER`. (ADR-0008)

---

## 7. Where to start reading

- **The shell / control flow:** `src/App.jsx`
- **The save schema:** `src/persistence.js` (`DEFAULT_SAVE`, `migrateSave`)
- **Combat truth:** `src/battleEngine.js` + `src/battleEngine.test.js`
- **Content tables:** `src/gameData.js`
- **Godot parity entry:** `dragon-forge-godot/scripts/main.gd`,
  `dragon-forge-godot/scripts/sim/`
- **Decision history:** [`docs/architecture/`](.) (ADR-0001 … ADR-0010)
