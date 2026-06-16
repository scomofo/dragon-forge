# Dragon Forge — Intensive Review vs the "NES-era AAA Hit" Bar

**Date**: 2026-06-16 · **Build reviewed**: browser (`src/`) @ `master` `141416b` · **Live**: https://scomofo.github.io/dragon-forge/

**Method**: Two parallel tracks, then cross-referenced.
1. **12-lens multi-agent review** — one studio specialist per lens (game-design, combat/systems, economy, UX, live-ops, art, narrative, audio, creative-direction, QA, tech, accessibility), each reading the relevant code, then **adversarial verification of every critical/high finding** by an independent skeptic, then a creative-director synthesis. *61 agents, ~3.19M tokens, 1,245 tool calls.* (QA and Accessibility lenses failed to return structured output; covered below from the live playthrough.)
2. **Live playthrough** — drove the running app via DOM/state introspection: fresh new-player run (intro → first free pull → first battle → reward loop) and an injected end-game save (all 9 dragons L50, Singularity complete, Mirror Admin defeated) to inspect endgame, economy, and sprite rendering.

> **Caveat on citations**: `file:line` references are as reported by the reviewing agents; a sample was hand-verified. Confirm exact lines at fix time.

---

## Overall verdict

> **Grade: C+** — *"a coherent, well-crafted game that has not yet decided to be a classic."*

The **feel layer and the premise genuinely clear the bar.** The mastery curve is built on a broken XP rule, the only skill surface is a 3-button "pick the biggest number," and the game ends with no reason to return — **but nearly every high-leverage fix is a data edit or a deletion, not a rebuild.**

**Biggest strategic risk — indecision about what the game IS.** Two divergent builds (browser + Godot, already drifted on caps/XP/endgame), free-to-play retention vocabulary (gacha pulls, pity, daily-streak multipliers, AUTO-battle) grafted onto a single-player loop that doesn't monetize, and no written design pillars. Scope gets decided by genre-default instead of by vision. You can't reach "timeless classic" by accident across two engines while the loop wears clothes that fight "hard to master."

**The "NES-era hit" framing, read honestly**: treat it as shorthand for **timeless craft** (tight feel, fair-deep difficulty, iconic readable identity, ruthless scope, compulsive loop) — *not* a mandate for literal pixel-art/chiptune. The game's DNA is a **1996 handheld JRPG-collector (Pokémon Red/Blue)**, not an NES action-platformer: type chart, gacha-as-encounters, fusion-as-evolution all echo it. Don't force pixel art — but the AI-illustration direction must clear two bars it currently doesn't: **silhouette readability** (can each dragon be ID'd as a black shape at thumbnail size?) and **cohesion across all elements + bosses**. The one place to lean into literal retro authenticity is **audio identity** and **onboarding discipline**.

---

## Per-lens grades

| Lens | Grade | One-line |
|------|:----:|----------|
| Core Loop & Fun | **C+** | Sound macro-loop, polished feel; micro-loop collapses to obvious turn-one play |
| Combat Depth & Balance | **C+** | Great presentation shell over a "pick highest number" decision layer |
| Economy & Progression | **C** | Tight early; mid/late economy structurally broken (no escalating faucet, no late sink) |
| New-Player Experience / UX | **C+** | Genuine craft (guidance chip, progressive nav); gated behind a lore wall + bullet-list tutorial |
| Endgame & Replayability | **D** | Real structure, but post-credits is architecturally hollow — ends with a whimper |
| Art Direction & Visual Identity | **C+** | Disciplined UI chrome; dragon art split-register, static, recolored-NPC bosses |
| Narrative, Theme & Cohesion | **C+** | Strong premise & atmosphere; payoff fires blanks (voiceless villain, dry lore) |
| Audio Identity & Feedback | **D** | Excellent procedural SFX; music layer functionally absent (5 tracks / 13 screens) |
| NES-era Vision Fit | **C+** | Right lineage (Pokémon), but no named target and F2P shorthand keeps creeping in |
| Technical Health & Performance | **C+** | Disciplined architecture; 135MB of PNGs, contradictory XP rules, thin test coverage |
| QA & Polish | *(agent failed)* | Covered below — XP-curve correctness bug is the headline |
| Accessibility | *(agent failed)* | Covered below — keyboard-only Forge, tiny fonts, colour-coded types, flash/shake |

---

## Top 12 issues (prioritised, cross-lens)

1. **🔴 CRITICAL — Three conflicting XP-per-level curves.** `persistence.js:171` ramps 50→290 via `addDragonXp`, but `BattleScreen.jsx:736` hardcodes flat 100 through a setter that bypasses it, and `hatcheryEngine.js:63` uses flat 100 too. The same 300 XP levels a dragon differently depending on its *source*. The mastery curve is literally built on sand, and every balance audit downstream is meaningless. **Fix (½ day)**: make `addDragonXp` the one authority; route battle-win + dupe-pull through it; add a "same XP, same level regardless of source" test.

2. **🟠 HIGH — Combat is one button deep, and AUTO skips even that.** Every dragon has 2 elemental moves + basic + Defend (`gameData.js:26-53`), one dragon deployed, no party/switch. Correct play ≈ "highest-power type-advantaged move." Defend rarely matters; basic is dead menu space. Then AUTO (`BattleScreen.jsx:503,1216`) runs the NPC AI on *your* turns and clears most content — telling the player the combat isn't worth engaging. **Fix**: add ONE real decision (a third signature move per species, *or* a 2-dragon bench with a turn-cost swap) **and** restrict AUTO to cleared/farm content — never bosses/daily/Singularity.

3. **🟠 HIGH — The endgame ends with a whimper.** `journalMilestones.js` has 16 entries, **zero** post-Singularity. After Mirror Admin falls nothing unlocks, the Remnants' "all defeated" flag is computed but never read, the economy dead-ends, and Synthesis (the most lore-loaded dragon) arrives with no ceremony. Replay scaling caps at +50% after 5 runs. **Fix (mostly data)**: 5 post-game milestones, an NG+ flag, raised replay cap + per-5-run reward, 1–2 post-game shop sinks, a Synthesis/all-Remnants ceremony.

4. **🔴 CRITICAL — Singularity bosses are recolored NPC sprites.** `singularityBosses.js`: Data Corruption / Memory Leak / Stack Overflow reuse `firewall_sentinel` / `bit_wraith` / `glitch_hydra` with `hue-rotate`; **The Singularity** reuses `recursive_golem` across all 3 phases, differentiated only by hue-rotate(15/60/180). Only Mirror Admin has bespoke art. *Bowser was never a recolored Goomba.* **Fix (art cost)**: bespoke idle+attack for the 4 reused bosses; minimum viable = 3 distinct silhouettes for the Singularity phases to sell escalation.

5. **🔴 CRITICAL — Macro audio identity is absent.** `soundEngine.js:630-638` resolves to 5 mp3s; `App.jsx:75-99` has fusion/journal/shop/stats/settings/forge **all** play `'hatchery'`; the Mirror Admin true-final shares `battleTense` with any sub-25%-HP normal fight; credits plays the boot theme. A final boss with no distinct music is the audio equivalent of no boss fanfare. **Fix**: ~4 tracks (boss/Mirror-Admin, forge, lore-calm, credits) + cache Audio elements to kill the re-instantiate gap on every nav. *(The procedural SFX engine is genuinely good — this is purely the music layer.)*

6. **🟠 HIGH — Shadow is the weakest attacker yet the sole Rare pull — and is double-punished at the climax.** `gameData.js:14`: shadow's offensive row sums 8.0 (lowest; void/light 9.5), with four 0.5× matchups. It's the only Rare-tier pull (`:337`, 15%), so the pity-guaranteed prize is statistically weaker than a lucky Common. Worse, shadow→light is 0.5 while Mirror Admin Phase 3 *is* Light. **Fix (one cell)**: change shadow→light 0.5→2.0 (light→shadow is already 2.0 — clean mutual super-effective, thematically apt).

7. **🟠 HIGH — Status effects are unbalanced 2–3×.** `gameData.js:346-357`: Freeze = guaranteed full turn skip; Burn = 8%/turn; Poison = 6%/turn — all at the same 30% apply rate. Freeze strictly dominates; DoTs are dead choices. **Fix (data)**: Burn 0.08→~0.15, Poison 0.06→~0.12; separately address Venom being the squishiest defender (column sum 10.0) it's handed to new players at 30%.

8. **🟠 HIGH — The best villain never speaks.** `singularityBosses.js:111`: the Mirror Admin's entire characterization is one (excellent) Felix quote — "a safety that forgot what it was protecting" — but zero in-battle dialogue across 3 phases. The Great Reset reads as a stat check. Captain's Log fragments are dry definitions (except the haunting Fragment 006 — proof the team can do better). **Fix (data)**: a `phaseDialogue` array of 3–5 terminal lines on phase transition; rewrite the weak log fragments on the Fragment-006 model.

9. **🟠 HIGH — First session opens with a lore wall, not a hook.** ~8–12s of typed boot lines + Felix before the CTA, skip behaving per-phase. **Live playthrough confirmed worse**: the boot sequence **replays in full on every page load**, even for a returning player with a complete save (only a small "click to skip"). Then the new player lands in the Hatchery behind a 5-bullet overlay (8px) referencing "the Matrix"/"Singularity"/a level-10 Fusion gate — teaching nothing. **Fix**: skippable on *any* input from frame 0 **and** persist an "intro seen" flag so returning players skip it; cut boot lines to ~3; replace the bullet overlay with one contextual prompt after the free pull.

10. **🟠 HIGH (your call) — Two divergent builds = no single "cartridge" to judge.** CLAUDE.md names browser the source of truth *and* maintains a parallel Godot rebuild that has already drifted on level cap, XP, and boss rewards — and issue #1 proves one rule can't stay consistent inside *one* React build. **Fix (decision, not code)**: pick ONE ship target, freeze/archive the other (recommended: browser canonical, Godot a future v2), document in a one-paragraph ADR so audits stop re-discovering drift.

11. **🟠 HIGH — Mid/late economy has no escalating faucet and no late sink.** Repeat income collapses to 7–32 scraps (×0.25 penalty), so grinding for a 900-scrap Wrench T3 or 500-scrap Shiny Charm has no satisfying path; every sink but the Daily is consumed before post-Singularity; XP Boosters become worthless at the L50 cap. **Live playthrough confirmed**: at ~53k scraps with a maxed roster, nothing meaningful is left to buy. **Fix (data)**: raise the repeat floor to 40–50%, add a Hard-rematch tier, add post-game sinks (Prestige Fusion/Pull), add a bulk-craft sink so the silent 99-core cap stops discarding drops.

12. **🟠 HIGH — VFX & silhouettes lack enforced identity.** `sprites.js:107-118`: RADIANT_BEAM and SOLAR_FLARE both source `storm_lightning.png` with hue-rotate — three elemental moves read identically; Light's golden identity is absent from its own VFX. No silhouette/body-plan spec across the 9 illustrated dragons. Plus `image-rendering:pixelated` on non-pixel illustrations (jagged, not crisp). **Fix**: remove `image-rendering:pixelated` (`DragonSprite.jsx:188`, `battle.css:544`); generate 2 bespoke VFX; run a silhouette-readability audit + write a per-element body-plan into the art bible.

---

## Live playthrough — what hands-on testing added

Behavioral grounding that the code review couldn't see, captured by driving the running app:

**Confirmed strengths (protect these):**
- **Onboarding flow is genuinely good in motion**: free first pull → guidance chip advances correctly (`NEXT: FREE PULL` → `FIRST BATTLE` → … → `ARCHIVE COMPLETE`) → nav **progressively discloses from 5 tabs (new player) to 10 (end-game)**. This is real NES-style gating.
- **Battle-select UX is above bar**: opponents **sorted by difficulty**, a **★ REC marker** on the first fight, and **per-dragon locked hints** ("Contain the Singularity", "Fuse Void and Light Dragon") — the old false "Pull from Hatchery" copy is gone.
- **Combat feel is tactile**: live "EDGE" type-matchup readout, status effects (Blind, Guard Break), crits, a combat feed, **Battle Rank (B)**, and AUTO mode — all working.
- **Art renders correctly in-app**: I pixel-sampled all 9 dragon canvases in the Journal — 64–81% opaque, ~0% stray green. The chroma-key works; **the green panel in the static `desktop.png` artifact is a Forge station, not a broken sprite.** Dragons are detailed, cohesive single-pose illustrations.
- **Endgame structure is real**: Singularity screen shows 4 bosses + Mirror Admin (TRUE FINAL, 3 phases) + 3 sequential Corruption Remnants, each with a Felix flavor quote. The Forge is a walkable, atmospheric hub (Anvil/relics+loadout, Console/log fragments, Felix, Save Lantern).

**Net-new findings (not surfaced by the code lenses):**
- **🟡 The intro replays on *every* load** (strengthens issue #9 — it's not just unskippable, it's re-shown every session).
- **🟡 Hidden accuracy + swingy misses.** In the "Easy" *recommended* first fight, Void Pulse **missed 3×** and the enemy crit for 23% of my HP on turn 1 — I finished at 17/90. Move tooltips show PWR and status-% but **never accuracy**, so misses feel arbitrary/unfair to a new player. A "fair" classic surfaces its odds; this hides them at the worst moment (the tutorial fight). *Fix (data/UX)*: show accuracy on the move card, and/or floor the recommended-fight accuracy higher.
- **🟡 The Forge hub is keyboard-only with zero clickable DOM affordances** (no exit/close button — pure WASD/Esc). A mouse/touch player can get stuck; this is also an accessibility gap (below).

---

## Coverage for the two failed lenses

**QA & Polish** (agent failed to return structured output):
- The **three-XP-curve bug (#1)** is fundamentally a correctness/QA failure — silent mis-leveling that no test guards.
- **Fusion temporarily reverts count-based milestone progress** (`persistence.js` `fuseDragons` sets parents `owned:false`; `journalMilestones.js` reads live counts) — low-severity but visible.
- **No `persistence.js` / `singularityProgress.js` test suites** — the most consequential code (save round-trip, `migrateSave` across historical shapes, boss-scaling invariants) is unguarded.
- Intro-replays-every-load (above) is a polish miss.

**Accessibility** (agent failed):
- **Keyboard-only Forge** with no clickable affordances (mouse/touch/switch-access gap).
- **Tiny uppercase fonts** (synthesis noted 7–9px) hurt low-vision readability.
- **Type system is colour-coded** (element colours + corruption filters) — needs a non-colour cue for colourblind players; the "EDGE" text readout helps but the roster/type chips lean on colour.
- **Flash/shake**: corruption-stage glitch effects + escalating screen shake (0→11) with no confirmed `prefers-reduced-motion` honouring — a photosensitivity risk.
- *These are quick wins*: reduce-motion media query, a colourblind-safe type indicator, a minimum font-size pass, and DOM buttons on the Forge stations.

---

## Roadmap

**Quick wins (data-only / <1 day, high leverage)**
- Type chart: shadow→light 0.5→2.0 (`gameData.js:14`).
- Status: Burn 0.08→0.15, Poison 0.06→0.12 (`gameData.js:347,351`).
- Remove `image-rendering:pixelated` from dragon canvases (`DragonSprite.jsx:188`, `battle.css:544`).
- Add 5 post-game milestones to `journalMilestones.js`.
- Add Mirror Admin `phaseDialogue` (3–5 terminal lines).
- Restrict AUTO-battle off bosses/daily/Singularity.
- Raise `REPLAY_CAP` toward ~1.5 + per-5-run core reward.
- Title skippable on any input from frame 0, persist "intro seen", cut boot lines to ~3.
- Add a `(REPEAT ×0.25)` label to the victory overlay so the income penalty teaches, not confuses.
- Show move **accuracy** on the move card (playthrough finding).

**Medium bets (½–2 days each)**
- **Fix the XP authority** (#1) — route all XP through `addDragonXp`; add the invariant test. *Foundation everything else stands on.*
- Add ONE real combat decision (third signature move *or* 2-dragon bench).
- Economy repair: higher repeat floor + Hard-rematch tier + post-game sinks.
- NG+ flag (reset `clearedNodeIds`, +20% enemies, new reward tier).
- ~4 music tracks + Audio caching.
- 6 Felix contextual triggers (first fusion/shiny/Singularity boss/Mirror-Admin/all-elements/Remnants).
- `persistence` + `singularityProgress` test suites.
- Reduce-motion + colourblind + min-font accessibility pass.

**Strategic moves (your call)**
- **Pick ONE build**; freeze/archive the other (recommend browser canonical); write the ADR.
- **Write 3–5 falsifiable pillars**; name **Pokémon Gen-1** as the north star + the singularity frame as the differentiator. (The implicit pillars — hardware-truth consonance, sympathetic villain, collection-has-consequence — are already strong; they just need to be written so scope stops defaulting to F2P convention.)
- **Decide the F2P-vocabulary question** against a mastery pillar: AUTO-battle, pity, daily-streak multipliers each earn their place or get cut.
- **Commission bespoke boss art** for the 4 recolored-NPC Singularity bosses.
- **Silhouette-readability audit** across all elements + bosses; per-element body-plan in the art bible.
- **Asset pipeline**: downscale PNGs to ~512² + WebP + vite image step + `manualChunks`. ~135MB → <~40MB for baseline "tight, responsive" load feel.

---

## What already clears the bar (protect in any scope cut)

- **The combat FEEL layer** — `battlePresentation.js` defines a full per-event timing model (anticipation/launch/impact-pause/recovery), escalating shake 0→11, hit-stop, damage-scaled pixel shake, hit-flicker, a heartbeat SFX only when the *player* is in danger, and music intensifying below 25% HP. Deliberate, NES-aware juice. This is the game's strongest claim to classic craft.
- **The procedural Web Audio SFX engine** — zero-weight, clean event schema, per-element pitch offsets, working heartbeat urgency. The NES-perfect part of the audio identity.
- **The premise & ludonarrative consonance** — "dragons are living software protocols defending a failing simulation" is internally consistent and reinforced everywhere (lore, Felix, type thematics, save-lantern-as-fiction). The tragic Mirror Admin and three player-agency endings are a legitimate Pokémon/JRPG-collector descendant.
- **The macro-loop & fixed-TTK boss scaler** — structurally sound; the scaler is a genuinely sophisticated, above-hobbyist solution.
- **The engine/presentation architecture** — pure-logic `battleEngine` with a real test suite, clean `*Engine.js`/`*Screen.jsx` split, `battlePresentation` isolated from `battleEngine`. More disciplined than typical web hobby projects.
- **The diegetic onboarding framing** — boot-sequence title + next-action guidance chip targeting real screens. Above-bar in concept; the problems are length/skippability, not the approach.

---

*Generated by a 12-lens multi-agent review (adversarially verified) cross-referenced with a live playthrough of the running build. Full machine-readable findings: workflow run `wf_e2bd5513-335`.*
