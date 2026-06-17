# Game Pillars

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: N/A — this *is* the pillar document; it is the parent every other GDD's "Implements Pillar" header points back to.

## Summary

This document names the 5 design pillars that the **shipped browser build of Dragon Forge** actually embodies, derived backwards from the live `src/` implementation and the design-sprint decision log in `docs/`. Each pillar is falsifiable, creates tension with at least one other pillar, carries a design test for resolving real decisions, and is grounded in code-level evidence. These are not aspirations — they are the rules the game already follows. Every other GDD in `design/gdd/` declares which of these pillars it implements; this is the spine that keeps those declarations honest.

> **Quick reference** — Layer: `Foundation` · Priority: `MVP` · Key deps: `None` (pillars are upstream of every system)

---

## Overview

Dragon Forge is a turn-based, sprite-based browser game (React 18 + Vite) about collecting, fusing, and battling dragons inside a failing digital simulation. The player is Skye, an operator bonding dragons — living guardian protocols — to keep a rendered pastoral world from being "restored" (deleted) by the overprotective Mirror Admin safety process. The game shipped without a formal pillars document; its pillars were implicit but remarkably coherent across the type chart, fusion alchemy, lore canon, Felix's dialogue, the Singularity endgame arc, and the accessibility layer. This document makes them explicit so that future scope decisions are made by vision rather than by genre-default.

**North star comp**: 1996 handheld JRPG-collector (Pokémon Red/Blue). The type chart, gacha-as-encounters, and fusion-as-evolution are direct descendants. The differentiator is the simulation-corruption frame — the "and also": *"It's a creature-collector type-battler, AND ALSO every fantasy element is secretly a piece of failing software, and saving the world means deciding what is allowed to survive a reboot."*

The 5 pillars, in priority order:

1. **Collection Is the Heartbeat**
2. **Every Fight Is a Readable Type-Puzzle**
3. **The Myth Is Hardware** (ludonarrative consonance)
4. **The Endgame Escalates Into Corruption**
5. **Earned Mastery, Never Trivialized** (accessibility + anti-grind)

---

## Player Fantasy

Across a session, the player should feel the arc: **curiosity → comprehension → mastery → consequence.** A new player pulls their first dragon (curiosity), learns that "fire beats ice, but this enemy is shadow" (comprehension), assembles a roster that can read and counter any matchup (mastery), and finally confronts a tragic antagonist where the question is not "can I win" but "what do I choose to save" (consequence).

Primary MDA aesthetics served, in order: **Discovery** (the world's true nature and the fusion combination space are secrets to be uncovered), **Challenge** (mastery of the type system and roster building), **Fantasy** (becoming the operator who keeps a world alive), and **Narrative** (the tragic Mirror Admin arc told through play, not cutscenes).

---

## The Pillars

### Pillar 1 — Collection Is the Heartbeat

**One-sentence definition:** The compulsion to acquire, complete, and grow a roster of distinct dragons is the primary engine of play; every other system feeds the collection or is fed by it.

**What it means:** Dragon Forge is a collector first and a battler second. The loop's center of gravity is the act of *getting a new dragon* — by pull, by fusion, or by clearing the endgame. Battle, economy, and progression all exist to fuel acquisition and to give acquired dragons somewhere to grow.

**How the game delivers it:**
- The hatchery gacha rolls across four rarity tiers (`gameData.js:353-357`: Common 50% → Uncommon 30% → Rare 15% → Exotic 5%) with a 10-pull pity ceiling (`gameData.js:362`, `hatcheryEngine.js:5-14`) so completion is always reachable, never purely luck-gated.
- Duplicate pulls convert into roster *growth* rather than waste — a duplicate routes 50× the rarity multiplier in XP through the canonical curve (`hatcheryEngine.js:63-64`, `applyDragonXp` in `persistence.js:194`), so collecting more deepens what you own.
- Fusion is a second acquisition path: combining two dragons can discover new elements and the unique `synthesis` result from `light + void` (`fusionEngine.js:1-25`), turning the collection into a combinatorial discovery space.
- The Journal milestones track collection completionism — owning elements, reaching shiny/level thresholds — as explicit goals (`journalMilestones.js`).
- A shiny variant system (`SHINY_CHANCE = 0.02`, `gameData.js:361`) adds a long-tail collection chase on top of base completion.

**Anti-pillar (what we deliberately avoid):** *We do NOT make battle the point and collection the reward.* Many RPGs treat creatures as disposable loadout slots. Dragon Forge refuses to make any dragon a throwaway — even fusion, which consumes parents, is framed as a deliberate, weighty choice rather than a feed mechanic. We also avoid pay-to-collect: the gacha vocabulary exists, but the pity counter and free first pull (`HatcheryScreen.jsx` first-game bypass) guarantee a fair completion path with zero monetization.

**Design test:** *If we're debating whether a new system should reward the player with a consumable buff or with a new/grown dragon, this pillar says we choose the dragon.* When a feature must justify its existence, the test is: "Does this make the player want one more dragon, or grow the ones they have?"

---

### Pillar 2 — Every Fight Is a Readable Type-Puzzle

**One-sentence definition:** Combat is a fair, legible chess of elemental matchups where the right answer is knowable in advance and victory comes from reading the board, not from twitch or hidden math.

**What it means:** Battles are won by understanding the 8×8 type chart and bringing the right element, not by reaction speed or memorizing invisible numbers. The game's job is to make the matchup *readable* — to surface the information the player needs to make the puzzle solvable.

**How the game delivers it:**
- A complete, balanced 8-element type chart (`gameData.js:8-17`) where every element has at least one 2.0× super-effective target and at least one weakness — verified exhaustively in `battleEngine.test.js`. Recent balance passes closed the worst asymmetries: `shadow → light` is now 2.0× (mutual super-effective with light, thematically "shadow consumes radiance"), and DoT status effects were rebalanced toward control (Burn 0.15, Poison 0.12 — `gameData.js:366,370`) so type and status choices both carry weight.
- An in-battle "EDGE" type-matchup readout tells the player the matchup before they commit, and move cards surface power and status chance — the puzzle is solvable with the information given.
- The fixed-time-to-kill boss scaler keeps fights tuned to a deliberate length so the puzzle reads cleanly at every progression point rather than collapsing into a one-shot or a grind.
- A 2-dragon bench with a half-rate reserve trains alongside the active dragon (`BattleScreen.jsx:944-945`) — adding a real switch/loadout decision layer to the puzzle without breaking legibility.
- Status effects are distinct, readable verbs (Freeze = skip, Burn/Poison = DoT, Guard Break/Blind/Dazzle = debuff, Glitch = randomize — `gameData.js:365-373`), each with an icon, so the board state is always legible.

**Anti-pillar (what we deliberately avoid):** *We do NOT hide the odds or reward reflex.* This is a turn-based puzzle, not an action game — there is no frame-data, no input timing, no twitch skill. We avoid "gotcha" combat where the right answer is unknowable until after you lose.

**Design test:** *If we're debating between adding combat depth via a hidden mechanic versus a visible, learnable one, this pillar says we choose the visible one.* The test: "Could a thoughtful player, given the information on screen, deduce the right move? If not, the design fails this pillar."

---

### Pillar 3 — The Myth Is Hardware (Ludonarrative Consonance)

**One-sentence definition:** Every fantasy element has a precise systems-layer truth — dragons are protocols, bosses are software failures, the villain is a safety process — and mechanics and story say the same thing at every moment.

**What it means:** Dragon Forge has a double reading. On the surface it is a pastoral dragon-tamer fantasy; underneath, it is a story about a failing simulation. The game's signature strength is that these two layers never contradict each other — the mechanics *are* the metaphor. This is the single most distinctive thing about the game and its strongest claim to being a coherent authored work rather than a genre exercise.

**How the game delivers it:**
- The fiction is wired into the data, not just the flavor text. Dragons are "living guardian protocols"; their lore reads as both myth and diagnostics (`gameData.js:329-336` — e.g. shadow "reads as a gap in the data," void "a tear in the simulation itself").
- The endgame bosses are literally named software failures: Data Corruption, Memory Leak, Stack Overflow, and the Singularity (`singularityBosses.js`), and the final antagonist is the Mirror Admin — "a safety that forgot what it was protecting."
- The villain is a tragedy, not a monster: the Mirror Admin "began as a kindness," protection learned too literally. Felix repeatedly frames the antagonist sympathetically (`felixDialogue`, `loreCanon`). The sympathetic-antagonist read is load-bearing for the whole narrative.
- The corruption stage is a system-wide state that drives visual filters and music (`App.jsx:190` applies `corruption-stage-N`; `singularityProgress.js:7-29`) — the world *visibly* destabilizes as the simulation fails, so the player feels the fiction through the chrome.
- The save lantern, the CRT Captain's Log terminal, and the boot sequence are all diegetic — even the act of saving is in-fiction (`design/gdd/narrative-and-lore.md`).

**Anti-pillar (what we deliberately avoid):** *We do NOT let mechanics contradict the story.* If the story says "every life matters" but the mechanics reward disposable creatures, players feel the dissonance even if they can't name it. We avoid pasting a sci-fi skin over generic fantasy systems — the simulation frame must be true at the mechanical level (corruption stage, fusion-consumes-parents-as-moral-weight, dragons-as-protocols) or it isn't worth having. We also avoid a cartoon villain; the antagonist's tragedy is non-negotiable.

**Design test:** *If we're debating a new mechanic or content piece, this pillar says we choose the version that also reads as a true statement about the simulation.* The test: "Does the mythic surface and the hardware truth tell the same story here? If a mechanic only works as fantasy or only as software, it fails."

---

### Pillar 4 — The Endgame Escalates Into Corruption

**One-sentence definition:** The game does not end at "collected them all"; it escalates collection and campaign progress into rising stakes, a multi-phase tragic final boss, and a permanent narrative consequence the player chooses.

**What it means:** Dragon Forge has a real third act. The Singularity arc converts the player's accumulated collection and campaign milestones into visible, escalating danger, then caps the power fantasy with a confrontation that is about *choice and consequence* rather than just stat checks. The endgame is where the collection pillar and the consonance pillar pay off together.

**How the game delivers it:**
- A six-stage corruption ladder (`singularityProgress.js:7-29`) that escalates based on the player's own progress — owning more dragons, having a level-50 elder, and clearing the gatekeeper NPCs each push the world further toward breach (Dormant → Anomaly → Signal Growing → Matrix Unstable → Breach Imminent → The Singularity).
- A gatekeeper sequence (four corruption NPCs) leading to a 3-phase final boss, then the Mirror Admin true-final, then three sequential Corruption Remnants (`singularityBosses.js`, `design/gdd/singularity-endgame.md`).
- Post-Singularity milestones now exist and read endgame flags — `singularityComplete`, `mirrorAdminDefeated`, and `remnantDefeated` are tracked and surfaced as Journal goals (`journalMilestones.js:171,181,186-191`), so beating the true final actually unlocks recognition rather than ending in silence.
- The `synthesis` dragon (`light + void`, `fusionEngine.js:23-24`) is the collection's apex result, reserved as a late, lore-loaded payoff.
- Three endings honor player agency — Total Restore / Patch / Hardware Override trade hardware stability against who survives in memory. There is no "correct" ending; the arc's climax is a values choice.

**Anti-pillar (what we deliberately avoid):** *We do NOT end with a whimper.* The endgame must not be an architecturally hollow "you win, the end." We avoid a final boss that is mechanically identical to a normal fight (the 3-phase structure and bespoke Mirror Admin art exist precisely to make the climax feel like a climax). We also avoid a single "correct" ending that retroactively makes the player's choices meaningless — the three endings must remain genuine trade-offs.

**Design test:** *If we're debating whether to invest in pre-endgame breadth or in deepening the Singularity payoff, this pillar says protect the payoff first.* The test: "Does beating the true final boss feel like a culmination of everything collected and learned, and does the player's final choice carry weight? If the ending is interchangeable or empty, it fails."

---

### Pillar 5 — Earned Mastery, Never Trivialized (Accessibility + Anti-Grind)

**One-sentence definition:** The game is fair and accessible to all players, but it never lets convenience features skip the one skill surface that makes it a game — mastery must be earned, and access must never cost difficulty.

**What it means:** Two commitments held in tension. First, *accessibility by default*: the game adapts to player needs (motion sensitivity, etc.) without watering down the experience. Second, *earned mastery*: convenience systems (auto-battle, repeat-clear income) exist for player comfort but are walled off from the high-stakes moments, so the player can never opt out of the game's core challenge at the moments that matter most. Accessibility lowers the floor; the mastery wall holds the ceiling.

**How the game delivers it:**
- AUTO-battle is explicitly a farm convenience and is forbidden on high-stakes fights — the `autoBattleAllowed` gate blocks it for Singularity and Mirror Admin battles (`BattleScreen.jsx:282-287`), with the in-code rationale: "AUTO-battle is a farm convenience; it must never trivialize high-stakes fights."
- The XP curve is a single canonical authority — every XP source (battle wins, duplicate pulls, shop items) routes through `applyDragonXp` (`persistence.js:194-204`, `BattleScreen.jsx:944`, `hatcheryEngine.js:64`) capped at level 50, so a dragon levels identically no matter where the XP came from. Mastery progression is honest: the same effort yields the same growth.
- A repeat-clear income penalty discourages mindless grinding while a daily challenge offers a bounded, fair return loop — the economy nudges toward engagement over autopilot.
- Accessibility is wired at the system level: the game honors `prefers-reduced-motion` (`animationEngine.js`, `styles/base.css`) — recent work killed the corruption glitch/flicker and battle screen-shake under reduced-motion settings — so the spectacle adapts rather than excludes.

**Anti-pillar (what we deliberately avoid):** *We do NOT let a player skip the skill surface and still win the fights that are supposed to test them.* Free-to-play retention vocabulary (auto-battle, pity, daily-streak) is allowed only where it serves comfort, never where it replaces mastery — each such feature must earn its place against this pillar or be cut. We also avoid the inverse failure: making the game accessible by making it trivial. Reduced-motion changes presentation, never difficulty. And we avoid hidden or source-dependent progression math that makes "earned" mastery a lie (the single canonical XP curve is the guarantee against this).

**Design test:** *If we're debating whether a convenience feature should apply to a boss fight, this pillar says no.* The test: "Does this feature let the player win a challenge the game intends them to engage with, without engaging? If so, wall it off. Conversely: does an accessibility option change difficulty rather than presentation? If so, it's the wrong fix."

---

## Pillar Tension Map

Good pillars conflict. These are the productive tensions the team adjudicates:

| Tension | Pillars in conflict | How it resolves |
|---------|--------------------|-----------------|
| Collection wants the player to *have* every dragon; mastery wants every dragon *earned* | P1 vs P5 | Pity guarantees completion is reachable (P1) but duplicates grant XP through the honest curve, so having and growing stay distinct (P5). |
| Readable combat wants legibility; corruption endgame wants escalating spectacle and chaos | P2 vs P4 | The Glitch/randomize status and corruption visuals raise stakes, but the EDGE readout and fixed-TTK scaler keep the matchup itself legible (P2 caps how chaotic P4 may get). |
| Consonance wants every system to serve the fiction; collection wants gacha breadth | P3 vs P1 | Gacha is reframed in-fiction (eggs = protocol instantiation) and pity removes monetization — the collection engine must read as true to the simulation, not as a storefront. |
| Accessibility wants the spectacle to adapt down; consonance wants the world to *visibly* decay | P5 vs P3 | Reduced-motion preserves the corruption *state* and color while removing the flicker/shake — the fiction survives, the photosensitivity risk does not. |

If a proposed change resolves cleanly in favor of one pillar with no tension at all, it is probably too safe to matter — or it is quietly violating a pillar that isn't in the room.

---

## Anti-Pillars (Consolidated)

The "no"s that protect the "yes"es, collected for quick reference:

1. **No pay-to-win / pay-to-collect.** The gacha vocabulary exists, but the pity counter, free first pull, and absence of monetization mean money never buys progression. (Protects P1, P5.)
2. **No twitch combat / hidden odds.** Turn-based puzzle, not action game. The right move must be deducible from on-screen information. (Protects P2.)
3. **No sci-fi skin over generic fantasy.** The simulation frame must be true at the mechanical level or it isn't worth having. (Protects P3.)
4. **No cartoon villain.** The antagonist's tragedy is load-bearing and non-negotiable. (Protects P3, P4.)
5. **No whimper ending / no single correct ending.** The endgame is a real third act with genuine values trade-offs. (Protects P4.)
6. **No trivializing convenience on high-stakes fights.** AUTO-battle and farm aids are walled off from bosses and the Singularity. (Protects P5.)
7. **No access-via-trivialization.** Accessibility changes presentation, never difficulty. (Protects P5.)
8. **No two-cartridge indecision (strategic).** A timeless classic is ONE tight artifact; the browser build is the canonical ship target. (Protects all pillars — scope discipline.)

---

## Dependencies

Pillars are upstream of every system; this table records which GDDs declare each pillar so the spine stays verifiable.

| Pillar | Declared by (Implements Pillar header) |
|--------|----------------------------------------|
| P1 — Collection Is the Heartbeat | `design/gdd/hatchery-gacha.md`, `design/gdd/fusion.md`, `design/gdd/journal-milestones.md`, `design/gdd/dragon-progression.md` |
| P2 — Every Fight Is a Readable Type-Puzzle | `design/gdd/combat.md`, `design/gdd/dragon-progression.md` |
| P3 — The Myth Is Hardware | `design/gdd/narrative-and-lore.md`, `design/gdd/forge-skye.md` |
| P4 — The Endgame Escalates Into Corruption | `design/gdd/singularity-endgame.md`, `design/gdd/campaign-map.md` |
| P5 — Earned Mastery, Never Trivialized | `design/gdd/vfx-animation-accessibility.md`, `design/gdd/economy.md`, `design/gdd/daily-challenge.md`, `design/gdd/audio.md` |

> **Maintenance note**: several existing GDDs used legacy pillar names in their headers (e.g. "Collection Fantasy", "Mastery & Collection Growth", "World-as-Living-System", "Arcade Spectacle / Accessible by Default"). These mapped onto P1, P1/P5, P3, and P5 respectively. Headers were aligned to the canonical P1–P5 names above on 2026-06-16.

## Tuning Knobs

Pillars are not numerically tuned, but each is *anchored* by specific values whose drift would break the pillar. These are the load-bearing constants — change them and you change what the game is.

| Pillar | Anchoring value(s) | Current | Where it lives | What breaks if it drifts |
|--------|-------------------|---------|----------------|--------------------------|
| P1 | Pity threshold | 10 | `gameData.js:362` | Too high → collection feels luck-gated, not reachable; too low → no acquisition tension. |
| P1 | Rarity distribution | 50/30/15/5 | `gameData.js:353-357` | Flattening removes the discovery thrill; steepening makes completion feel grindy. |
| P2 | Type chart cells | 8×8, all balanced | `gameData.js:8-17` | A 0-weakness or 0-super-effective element makes the puzzle unsolvable or trivial. |
| P2 | Status balance | Burn 0.15 / Poison 0.12 / Freeze skip | `gameData.js:366-373` | If control strictly dominates DoT, the status puzzle collapses to one answer. |
| P4 | Corruption stage thresholds | owned≥2/4/6, elder L50, all-NPC | `singularityProgress.js:18-28` | Mistuning makes escalation feel arbitrary instead of earned. |
| P5 | XP curve | `50 + (level-1)*5`, cap 50 | `persistence.js:188,197-202` | A second curve (source-dependent leveling) makes "earned" mastery a lie. |
| P5 | AUTO-battle allow-list | excludes Singularity/Mirror Admin | `BattleScreen.jsx:284-287` | Widening it to bosses lets players skip the skill surface. |

## Acceptance Criteria

A pillar is "working" when the game can be tested against it. These are the falsifiable checks:

- [ ] **P1**: A new player reaches a full base-element collection through play alone (pulls + pity + fusion) without spending money — there is no monetization path. (Verify: `HatcheryScreen` first-game free pull + `hatcheryEngine.js:5-14` pity.)
- [ ] **P2**: For any battle, a player who can see the EDGE readout and move cards can identify a non-losing move without trial-and-error. Every element has ≥1 super-effective target and ≥1 weakness. (Verify: `battleEngine.test.js` type-chart assertions.)
- [ ] **P3**: Every shipped dragon, boss, and major mechanic has a coherent reading as both myth and software. No content piece reads as fantasy-only or software-only. (Verify: `gameData.js:329-336` lore, `singularityBosses.js` boss names, corruption-stage class application.)
- [ ] **P4**: Defeating the Mirror Admin unlocks recognition (post-game milestones fire) and presents a genuine three-way ending choice with no "correct" answer. (Verify: `journalMilestones.js:171,181,186-191`.)
- [ ] **P5a (mastery)**: AUTO-battle is impossible on Singularity and Mirror Admin fights. (Verify: `BattleScreen.jsx:284-287`.)
- [ ] **P5b (honesty)**: The same XP amount produces the same level regardless of source (battle / pull / shop). (Verify: single `applyDragonXp` authority, `persistence.js:194`.)
- [ ] **P5c (accessibility)**: With `prefers-reduced-motion` set, corruption glitch/flicker and battle shake are suppressed while difficulty is unchanged. (Verify: `animationEngine.js`, `styles/base.css`.)

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Collection acquisition + pity drives P1 | `design/gdd/hatchery-gacha.md` | Rarity tiers, pity threshold | Rule dependency |
| Fusion as second acquisition path (P1, P4 synthesis) | `design/gdd/fusion.md` | `light + void → synthesis` recipe | Rule dependency |
| Type-chart legibility underpins P2 | `design/gdd/combat.md` | 8×8 type chart + status effects | Data dependency |
| Honest XP curve underpins P5 | `design/gdd/dragon-progression.md` | `applyDragonXp` single-authority curve | Rule dependency |
| Consonance / sympathetic villain underpins P3 | `design/gdd/narrative-and-lore.md` | Mirror Admin framing, lore canon | Rule dependency |
| Endgame escalation + endings underpins P4 | `design/gdd/singularity-endgame.md` | Corruption ladder, 3-phase boss, endings | State trigger |
| Accessibility + anti-grind underpins P5 | `design/gdd/vfx-animation-accessibility.md` | `prefers-reduced-motion` handling | Rule dependency |

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|------------|
| Align legacy "Implements Pillar" headers across existing GDDs to the canonical P1–P5 names | creative-director | Next GDD pass | Open — mapping recorded in Dependencies maintenance note |
| Confirm browser as sole canonical build and freeze Godot per anti-pillar #8 (strategic, user's call) | user / creative-director | — | Open — strongest single scope-discipline decision against the "one tight artifact" goal |
