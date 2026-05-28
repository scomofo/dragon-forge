# Hatchery

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-24
> **Implements Pillar**: Core Loop — Collect

## Overview

The Hatchery is Dragon Forge's dragon-collection system. Players spend Data Scraps at the Hatchery Ring to pull elemental dragon eggs, triggering an animated reveal that resolves into one of six elements across three rarity tiers — Common (50%: Fire, Ice), Uncommon (40%: Storm, Venom, Stone), and Rare (10%: Shadow). Void, the seventh element, is an anti-protocol encountered through a separate story-gated unlock after the six guardian protocols are collected; it does not appear in Hatchery pulls. Behind the reveal, the engine executes a weighted random draw against two pity systems: a Rare+ pity counter guarantees Shadow by pull 10, and a parallel element soft-pity system tracks each element independently — after 20 consecutive pulls without a specific element its probability begins a linear ramp, guaranteeing that element by pull 40 (ensuring Act 4's Elemental Matrix gate is always attainable). A 2% shiny chance fires independently on each pull. First pulls of each element unlock the dragon outright; duplicate pulls convert to XP (50 × rarity multiplier, credited to that dragon's level) and, if the pull was shiny, upgrade the dragon's shiny status even if it was previously unlocked as non-shiny. The Hatchery is the first contact moment between Skye and each of the world's guardian protocols — the beat where a new dragon joins the party and the player encounters its identity for the first time.

## Player Fantasy

*(`creative-director` not consulted — session rate limit. Flag for manual review before production.)*

The Hatchery is the game's first act of welcome. Before the dread of the Mirror Admin, before the urgency of the fracturing Matrix, there is this: Skye at the Hatchery Ring, spending the scraps she has, watching an egg crack open.

**The feeling is not "what will I get." It is "who is coming."**

The dragons of the Rendered World are guardian protocols — processes with teeth, memory, and opinions that predate the current instability. Pulling at the Hatchery is not shopping. It is the moment a fragment of the world's infrastructure decides to recognize you. The egg does not produce a tool. It introduces a character.

This creates two emotional beats woven into every pull:

**The wait** — the animation running, the element unrevealed. The player has committed scraps. The commitment is already made. Now they are simply present for the result.

**The recognition** — a Fire dragon who burns dead data; an Ice dragon who cold-stores what's worth keeping; a Shadow dragon hiding critical processes. When the element resolves, the player doesn't just see a stat block. They meet a role in a world's failing ecology — a piece of the system they are trying to save.

Shiny pulls belong to this register too. A shiny dragon carries a 1.2× stat multiplier, but the meaning is different: it is a dragon running at exceptional output, visually radiant, a rare instance of the world producing something that exceeds its own degraded baseline. Finding one feels like the world is still capable of surprise.

> **Designer test:** A Hatchery feature serves this fantasy if it deepens the sense of *meeting* rather than *acquiring*. An element-reveal animation that takes too long frustrates; one that has personality rewards. Mechanics that turn the Hatchery into a pure optimization loop (e.g., reroll systems, guaranteed targeting) drain the recognition feeling — the player stops meeting dragons and starts managing inventory.

> **Post-collection dependency**: The "who is coming" fantasy depends on there being someone new to meet. Once all six guardian protocols are owned, duplicate pulls break the emotional premise of this section. The *mechanical* post-collection experience is defined in E8. The *experiential* design — how the Hatchery communicates to a player with a complete collection, how Felix or the Hub acknowledge completion, whether post-collection pulls have any narrative framing — is owned by narrative-director. This Player Fantasy describes the experience for pulls 1 through last-new-dragon only.

## Detailed Rules

### Core Rules

1. **Pull Cost**: Each pull costs 50 Data Scraps (PULL_COST). Scraps are deducted before the outcome is determined. If the player has fewer than 50 Scraps, the pull button is unavailable (no partial or deferred pulls).

2. **Rarity Draw**: Each pull resolves against the following weighted table. Within a tier, each element has equal probability.

   | Tier | Elements | Tier Probability | Per-Element Probability | XP Multiplier |
   |------|----------|-----------------|------------------------|---------------|
   | Common | Fire, Ice | 50% | 25.0% each | 1× (50 XP) |
   | Uncommon | Storm, Venom, Stone | 40% | ~13.33% each | 2× (100 XP) |
   | Rare | Shadow | 10% | 10.0% | 3× (150 XP) |

   Void (the seventh dragon) is not in the standard pull pool. It is unlocked through a story-gated mechanism after all six guardian protocols are collected. See OQ-H05 and the Singularity GDD for the Void unlock design.

   > **Note — browser build divergence**: The browser implementation (`gameData.js`) uses Uncommon: 30%, Rare: 15%, Exotic: 5% (Void in pool). The Godot port uses the values above. The Godot port rates are canonical; the browser build update is tracked as a separate action (OQ-H06 closed).

3. **Rare+ Definition**: "Rare+" means any Rare-tier pull (Shadow). Shadow is the only element in the Rare tier in the standard pool. This is the threshold for pity counter reset and pity-forced outcomes.

4. **Pity System**: A pity counter tracks consecutive non-Rare pulls (stored in save data; persists across sessions).
   - At pull execution, the natural draw is resolved first. If the result is Rare (Shadow), pity is not triggered; the counter resets to 0 normally.
   - Only if the natural draw is non-Rare AND `pityCounter >= 9` is the result forced to Shadow. Pity force overrides the natural draw only when the natural draw fails to produce Rare.
   - The counter increments by 1 after each non-Rare result (natural or after pity-check passes).
   - The counter resets to 0 after any Rare result (natural or forced).
   - When the counter reaches 9 — meaning 9 consecutive non-Rare draws — the **next pull** (the 10th) is forced Shadow, regardless of natural draw result.
   - Pity-forced pulls receive the normal 2% shiny roll (no shiny penalty for pity).

4b. **Element Soft-Pity**: Each of the six standard elements has an independent drought counter — the number of consecutive pulls that did not produce that element. All six drought counters are stored in save data and persist across sessions.

   Pull resolution order (highest priority first):
   1. **Guaranteed threshold**: If any element's drought counter has reached `ELEMENT_SOFT_PITY_GUARANTEED` (40), that element is forced. If multiple elements are simultaneously at or above threshold, the element with the highest counter is forced; ties broken by priority order (Fire, Ice, Shadow, Stone, Storm, Venom).
   2. **Rare+ pity check**: If no element has reached the guaranteed threshold, Rule 4 applies as normal (pityCounter ≥ 9 and natural draw non-Rare → forced Shadow).
   3. **Ramp draw**: If neither guarantee fires, apply ramp bonuses for elements in the onset range (Formula 9) before performing the weighted draw.

   After each pull: reset `drought[drawn_element]` to 0; increment `drought[all_other_elements]` by 1.

   **Tier and pity-counter interaction**: A soft-pity-forced element determines its own tier (e.g., forced Stone is Uncommon). If soft-pity forces Shadow, the Rare+ pity counter resets to 0. If soft-pity forces any Common or Uncommon element, the Rare+ pity counter increments by 1.

5. **Shiny Protocol**: Each pull has an independent 2% chance of being shiny (SHINY_CHANCE). This roll applies to every pull — Common, Uncommon, Rare, and pity-forced — without exception.

6. **No First-Pull Guarantee**: All pulls, including the player's very first, follow standard probability rules with no special seeding.

7. **Outcome — New Dragon**: If the drawn element is not yet owned:
   - The dragon is marked owned.
   - If the pull is shiny, the dragon's shiny status is set to true.
   - The reveal sequence plays, introducing the dragon's identity.

8. **Outcome — Duplicate Dragon**: If the drawn element is already owned:
   - XP is awarded: `xpGained = 50 × rarityMultiplier`
   - XP accrues via Dragon Progression GDD Formula 4 — escalating per-stage threshold (50 / 80 / 120 / 200 XP per level across Stages I–IV). XP that would advance the dragon past MAX_LEVEL is discarded.
   - If the pull is shiny and the dragon's current shiny status is false, shiny is upgraded to true. Level and XP are preserved unchanged.
   - Both XP and shiny upgrade can apply on the same duplicate pull.

### States and Transitions

| State | Description |
|-------|-------------|
| IDLE | Player at Hatchery Ring; pull button visible; Scrap balance shown |
| CONFIRMING | Player pressed pull; awaiting cost confirmation |
| ANIMATING | 50 Scraps deducted; egg crack animation running; element unrevealed |
| RESOLVING | Outcome computed; reveal animation playing (element and shiny status shown) |
| RESULT_SHOWN | Dragon card displayed — new dragon intro or duplicate XP/shiny summary |
| RETURNING | Player dismissing result |

| Transition | Trigger |
|-----------|---------|
| IDLE → CONFIRMING | Player activates pull with ≥50 Scraps |
| IDLE → IDLE (blocked) | Player activates pull with <50 Scraps — error feedback shown, no state change |
| CONFIRMING → ANIMATING | Player confirms cost |
| CONFIRMING → IDLE | Player cancels confirmation |
| ANIMATING → RESOLVING | Egg animation completes (timed) |
| RESOLVING → RESULT_SHOWN | Reveal animation completes |
| RESULT_SHOWN → IDLE | Player dismisses result |

### Interactions with Other Systems

| System | Data Flow | Direction |
|--------|-----------|-----------|
| Save / Persistence | Scrap deduction, dragon owned/shiny, dragon XP/level, Rare+ pity counter, 6 element drought counters — written atomically per pull | Hatchery → Save |
| Dragon Progression | XP from duplicate pulls feeds dragon level formula; MAX_LEVEL is defined in Dragon Progression GDD | Hatchery → Dragon Progression |
| Shop | Data Scraps are shared currency; Shop is a Scrap source, Hatchery is a Scrap sink | Shop → Hatchery |
| Battle Engine | Owned dragons become available for party selection after unlock; no runtime interaction during pulls | Hatchery → Battle Engine |
| Dragon Forge Hub | Hub navigation transitions the player to the Hatchery pull UI; Hatchery Ring is a Hub landmark | Hub → Hatchery |
| Campaign Map | Element ownership drives `matrix_stabilized` check for Act 4 gate; Hatchery element soft-pity ensures all elements are reachable | Hatchery → Campaign Map |
| Audio Director | Pull events emit signals for music cue transitions and SFX triggers (egg crack, element reveal, shiny fanfare) | Hatchery → Audio |

## Formulas

### 1. Pull Cost

```
PULL_COST = 50  (Data Scraps)
```

### 2. Rarity Probabilities

```
P(Common)   = 0.50   →  P(Fire)   = 0.25,    P(Ice)   = 0.25
P(Uncommon) = 0.40   →  P(Storm)  ≈ 0.1333,  P(Venom) ≈ 0.1333,  P(Stone) ≈ 0.1333
P(Rare)     = 0.10   →  P(Shadow) = 0.10
```

Within each tier, elements are equally weighted.

### 3. Shiny Probability

```
P(shiny | any pull) = SHINY_CHANCE = 0.02

Applies to all pulls without exception — Common, Uncommon, Rare, and pity-forced.
```

### 4. Pity System

```
At pull execution:
  result = natural_draw()
  if pityCounter >= 9 and result != Rare:
      result = Shadow               # force only if natural wasn't Rare

After each pull:
  if result is Rare:  pityCounter = 0
  else:               pityCounter = pityCounter + 1

Pity-forced element selection:
  P(Shadow | pity forced) = 1.00   (Shadow is the only Rare-tier element in the standard pool)
```

Boundary check: at `pityCounter = 0`, the next 9 consecutive non-Rare+ pulls set the counter to 9; the 10th pull is forced.

### 5. Duplicate XP

```
xpGained = 50 × rarityMultiplier

rarityMultiplier:
  Common   → 1  →  xpGained =  50
  Uncommon → 2  →  xpGained = 100
  Rare     → 3  →  xpGained = 150
```

### 6. Level-Up (Hatchery XP Credit)

Hatchery delegates the full XP loop to Dragon Progression — no standalone level-up loop is defined here:

```
dragon_progression.apply_xp(dragon, xpGained)
```

This calls Dragon Progression GDD Formula 4, which handles: escalating per-stage thresholds (50 / 80 / 120 / 200 XP per level across Stages I–IV), the overflow guard (XP_MAX_AWARD clamp), Resonance effective-threshold reduction, `stage_iv_reached` signal emission, and MAX_LEVEL cleanup. Hatchery is a caller, not an owner, of this logic.

### 7. Natural Rare+ Probability (reference only)

```
P(natural Rare within N pulls) = 1 − (0.90)^N

  N=1:   10.0%
  N=5:   40.9%
  N=9:   61.3%  (pity fires on pull 10 for the remaining 38.7%)

Note: undefined at N ≥ PITY_THRESHOLD (10); pity guarantees Rare by pull 10.
```

### 8. Economy Reference Estimates (not runtime formulas)

```
Expected pulls to first obtain each element (geometric mean, simplified):
  Fire, Ice:           1 / 0.25    =  4.0 pulls each  →   8.0 total
  Storm, Venom, Stone: 1 / 0.1333  ≈  7.5 pulls each  →  22.5 total
  Shadow:              1 / 0.10    = 10.0 pulls
  ──────────────────────────────────────────────────────────────────
  Rough total (geometric mean):                         ≈  40.5 pulls → ~2,025 Scraps

Coupon-collector correction: geometric mean underestimates full-collection cost by 30–55%
due to duplicate pressure in late collection. Realistic estimate: 53–63 pulls → ~2,650–3,150 Scraps.

At 10–15 Scraps per battle: ~177–315 battles for full base collection (6 standard dragons).
Void is obtained through story-gated unlock — not Hatchery pulls.
```

### 9. Element Soft-Pity Ramp

Applies per element X when `ELEMENT_SOFT_PITY_ONSET ≤ drought[X] < ELEMENT_SOFT_PITY_GUARANTEED`.

```
step[X]       = drought[X] − ELEMENT_SOFT_PITY_ONSET
range         = ELEMENT_SOFT_PITY_GUARANTEED − ELEMENT_SOFT_PITY_ONSET
ramp_bonus[X] = (step[X] / range) × (1.0 − base_prob[X])
eff_prob[X]   = base_prob[X] + ramp_bonus[X]

Renormalise all 6 elements:
  total          = Σ eff_prob[i]   (across all 6 elements)
  final_prob[X]  = eff_prob[X] / total
```

Variable definitions:
- `drought[X]` — consecutive pulls without element X (tracked per-element; see Rule 4b)
- `base_prob[X]` — standard probability from Formula 2: Fire 0.25, Ice 0.25, Storm/Venom/Stone ≈ 0.1333, Shadow 0.10
- `ELEMENT_SOFT_PITY_ONSET` = 20
- `ELEMENT_SOFT_PITY_GUARANTEED` = 40

Worked example — Stone at drought = 30, all other elements below onset:
```
  step  = 30 − 20 = 10,  range = 40 − 20 = 20
  ramp_bonus[Stone] = (10 / 20) × (1.0 − 0.1333) = 0.50 × 0.8667 ≈ 0.4333
  eff_prob[Stone]   = 0.1333 + 0.4333 = 0.5667

  total ≈ 0.25 + 0.25 + 0.1333 + 0.1333 + 0.5667 + 0.10 = 1.4333
  final_prob[Stone] ≈ 0.5667 / 1.4333 ≈ 39.5%   (vs standard 13.3%)
```

Boundary checks:
```
  drought[X] = 20 (onset):   step = 0  → ramp_bonus[X] = 0  → no change from base probability
  drought[X] = 39 (one before guaranteed):
    Stone: ramp_bonus = (19/20) × 0.8667 ≈ 0.823 → eff_prob ≈ 0.956  (before normalisation)
  drought[X] ≥ 40: guaranteed via Rule 4b — formula not evaluated
```

## Edge Cases

**E1 — Insufficient Scraps**: If the player's Scrap balance drops below 50 between sessions (e.g., Scraps were spent at the Shop), the pull button is disabled and shows an error state. No pull executes.

**E2 — Exact 50-Scrap balance**: A player with exactly 50 Scraps may pull once. Post-pull their balance is 0. The pull button becomes disabled immediately.

**E3 — Natural Shadow when pity counter is at 9**: Pull execution checks the natural draw first. If Shadow is drawn naturally when `pityCounter == 9`, the result is a normal natural Shadow pull (2% shiny roll applies). Pity force is not triggered because the natural draw already produced Rare. The counter resets to 0. This is the correct behavior — pity force is applied only when the natural draw fails to produce Rare.

**E4 — Duplicate pull on a dragon at MAX_LEVEL**: XP is computed (`50 × rarityMultiplier`) and added to `dragon.xp`. The level-up loop exits immediately because `dragon.level < MAX_LEVEL` is false. After the loop, `dragon.xp` is set to 0. The dragon remains at MAX_LEVEL. Shiny upgrade still applies if the pull is shiny and the dragon's shiny status is false.

**E6 — Duplicate XP crosses MAX_LEVEL mid-loop**: XP is computed and added to `dragon.xp`. The `while` loop halts when `dragon.level == MAX_LEVEL`. After the loop, `dragon.xp` is set to 0. Any XP that would have accrued past MAX_LEVEL is discarded — a dragon cannot exceed MAX_LEVEL by any XP path.

**E7 — Shiny upgrade on a dragon at MAX_LEVEL**: Shiny status upgrades independently of level. A MAX_LEVEL dragon can still receive a shiny upgrade from a shiny duplicate pull. `dragon.xp` remains 0 (XP from the duplicate is computed then zeroed by the level-up formula); `dragon.level` remains MAX_LEVEL.

**E8 — Post-collection state (all 6 standard dragons owned)**: Every subsequent Hatchery pull is a duplicate. The mechanical result is correct (XP awarded per rarity, shiny upgrade if applicable). The pity system still functions normally. No special UI state is required; the result screen always shows the duplicate XP summary. **Design gap**: The "who is coming" player fantasy cannot deliver a meeting experience once all six dragons are owned. Post-collection pull framing (repeat encounters, discovery continuation, narrative response) is an open dependency on narrative-director — this system does not define it. Hatchery-only behavior during post-collection is mechanically complete; experiential design is tracked externally. Void, obtained via the story-gated unlock, follows the same duplicate rules if the player re-obtains it through that mechanism.

**E9 — Pull atomicity**: Scrap deduction and outcome application (dragon data, pity counter) are written to save data in a single atomic operation at pull resolution. If the application fails, the Scrap deduction is rolled back. A pull is never in a state where Scraps are spent but no outcome is recorded.

**E10 — Pity counter on a brand-new save**: A new player's pity counter initialises to 0. The first 9 pulls may all be Common/Uncommon; the 10th is forced Rare+. No special new-player exemption exists.

**E11 — Element soft-pity fires while Rare+ pity is also active**: If `drought[Stone] = 40` (element guaranteed) and `pityCounter = 9` (Rare+ pity ready), element soft-pity takes priority — Stone is forced. Stone is Uncommon; the Rare+ pity counter increments to 10. On the next pull, Rare+ pity fires (counter ≥ 9 → forced Shadow) unless another element guarantee again takes top priority. Two consecutive pity fires (Stone then Shadow) are correct behavior.

**E12 — Multiple elements at guaranteed threshold simultaneously**: If `drought[Storm] = 42` and `drought[Venom] = 40`, Storm is forced (highest counter). Venom's counter increments to 41 after the Storm pull, remains above the guaranteed threshold, and is eligible to trigger the next pull. Tie-break priority: Fire, Ice, Shadow, Stone, Storm, Venom.

**E13 — Shadow cannot reach element soft-pity onset**: Shadow's drought counter resets to 0 on every Shadow draw, including Rare+ pity-forced Shadow (which fires every ≤10 pulls). Since `PITY_THRESHOLD (10) < ELEMENT_SOFT_PITY_ONSET (20)`, Shadow's drought counter can never reach the onset threshold under normal operation. Shadow's element soft-pity ramp and guarantee are structurally unreachable — Shadow protection is already provided by Rare+ pity.

**E14 — Element drought counters on a new save**: All six element drought counters initialise to 0 on a new save. No element begins with any ramp or onset advantage.

## Dependencies

| System | GDD | Relationship | What Hatchery Needs |
|--------|-----|-------------|---------------------|
| Save / Persistence | `design/gdd/save-persistence.md` | Upstream | Atomic write API for Scrap balance, dragon owned/shiny/xp/level, pityCounter, and 6 element drought counters (drought_fire, drought_ice, drought_storm, drought_venom, drought_stone, drought_shadow) |
| Dragon Progression | `design/gdd/dragon-progression.md` | Upstream | MAX_LEVEL value; per-stage XP thresholds (50 / 80 / 120 / 200), `apply_xp()` behavior, and Resonance charge handling |
| Shop | `design/gdd/shop.md` | Upstream | Data Scraps earn rate (~10–15 per battle); Scraps as shared currency |
| Battle Engine | `design/gdd/battle-engine.md` | Downstream | Hatchery unlocks dragons that become selectable in party; no runtime coupling |
| Dragon Forge Hub | `design/gdd/dragon-forge-hub.md` | Upstream | Hub navigation triggers Hatchery entry; Hatchery Ring is a defined Hub landmark |
| Audio Director | `design/gdd/audio-director.md` | Downstream | Hatchery emits pull-phase signals; Audio subscribes for music transitions and SFX |
| Campaign Map | `design/gdd/campaign-map.md` | Downstream | Act 4 Matrix gate requires all 6 elements owned (`matrix_stabilized`); Campaign Map established element soft-pity contract (Rule 4b, Formula 9) to ensure no element is permanently out of reach |
| Narrative Director | `design/gdd/narrative-director.md` | Downstream | Post-collection encounter design; post-unlock Void narrative framing; Hatchery signals collection-completion events |

**Bidirectionality note**: Each dependency system's GDD should reference the Hatchery. Verify during `/review-all-gdds` that save-persistence, dragon-progression, shop, dragon-forge-hub, and audio-director acknowledge the Hatchery as a dependent system.

## Tuning Knobs

| Knob | Current Value | Safe Range | What It Affects |
|------|--------------|------------|-----------------|
| `PULL_COST` | 50 Scraps | 25–100 | Session length, Scrap sink rate; lower = faster collection, higher = harder gatekeeping |
| `PITY_THRESHOLD` | 10 (fires at pull 10) | 7–15 | Drought prevention; below 7, pity fires so often it cheapens natural Rare pulls; above 15, droughts feel punishing |
| `SHINY_CHANCE` | 2% | 1%–5% | Shiny rarity perception; below 1% shiny becomes folklore, above 5% shinies feel common |
| Common tier probability | 50% | 40%–60% | Common pull engagement; share shifts to/from Uncommon tier |
| Uncommon tier probability | 40% | 30%–50% | Uncommon pacing; adjust with Common to maintain sum = 100% |
| Rare (Shadow) probability | 10% | 5%–15% | Shadow accessibility; below ~5% drought prevention weakens significantly |
| Base XP per Common duplicate | 50 | 25–100 | Post-collection leveling pace; Common is the most frequent duplicate |
| XP multipliers | 1× / 2× / 3× | Must be strictly increasing | Tier differentiation for duplicate value; must remain 1 < 2 < 3 to preserve rarity signal |
| XP per stage thresholds | 50 / 80 / 120 / 200 | — | Owned by Dragon Progression GDD (Stages I–IV). Not tunable in Hatchery — change in Dragon Progression GDD only. |
| `ELEMENT_SOFT_PITY_ONSET` | 20 | 10–35 | Consecutive pulls without element X before its ramp begins. At 20, Common droughts (25% base) almost never trigger (~0.3% chance), Uncommon droughts (13.3%) trigger ~5.5% of the time — both feel like genuine insurance rather than a dominant mechanic. Below 10, ramp starts so early it materially changes the expected-value table. |
| `ELEMENT_SOFT_PITY_GUARANTEED` | 40 | 25–60 | Consecutive pulls without element X at which that element is forced. Must be > ONSET + 5 to allow a meaningful ramp window. Above 60, the guarantee rarely fires and the ramp does most of the work. Campaign Map contract specifies 40 — change both this GDD and campaign-map.md if adjusting. |

**Constraint**: Common + Uncommon + Rare probabilities must sum to exactly 1.0. Adjust in pairs.
**Constraint**: `ELEMENT_SOFT_PITY_GUARANTEED` must be strictly greater than `ELEMENT_SOFT_PITY_ONSET`.

## Visual/Audio Requirements

### Pull Animation Phases

| Phase | Visual | Audio |
|-------|--------|-------|
| IDLE | Egg resting on Hatchery Ring; ambient glow pulse | Ambient Hatchery hum |
| ANIMATING | Egg cracks radiate from center; element-colored light bleeds through fracture lines | Cracking SFX escalates over animation duration |
| RESOLVING | Shell fragments disperse; element color floods the frame; dragon silhouette emerges | Element-specific reveal sting |
| RESULT — new dragon | Dragon card slides in; full element palette on display | Intro fanfare (element-specific) |
| RESULT — duplicate | Compact XP counter animation; +XP numeric readout | Short confirmation chime |
| SHINY overlay | Radiant white burst before element reveal; persistent shimmer on dragon card | Shiny fanfare (distinct from intro) overlaid on element sting |

### Element Visual Language

Each element has a distinct color signature visible during the crack phase — the player reads the element before the card appears:

| Element | Color signature |
|---------|----------------|
| Fire | Deep orange-red with ember sparks |
| Ice | Pale blue-white with frost crystals |
| Storm | Yellow-violet with arc flickers |
| Venom | Acid green with droplet particles |
| Stone | Muted grey-brown with rubble chips |
| Shadow | Deep violet-black with void shimmer |
| Void | White-silver with prismatic refraction *(story-gate unlock reveal only — not a standard Hatchery pull)* |

### Shiny Visual Contract

A shiny pull produces a white burst frame before the element reveal (≤0.5s), then a persistent shimmer on the dragon card that persists in all collection views. Shiny must be visually distinguishable from non-shiny at a glance, including in low-light display conditions.

## UI Requirements

### Hatchery Ring Screen

- **Scrap balance**: Visible at all times in the Hatchery, updating immediately after each pull.
- **Pull button**: Three states — AVAILABLE (≥50 Scraps), DISABLED (<50 Scraps, greyed, non-interactive), CONFIRMING (awaiting confirm/cancel input).
- **Pity counter**: Not displayed to the player. The counter is an internal mechanic; surfacing it would convert the emotional wait into an optimization loop.
- **Pull button label**: Shows cost ("Pull — 50 Scraps") when available.

### Result Screen

- **New dragon result**: Full dragon card with element, name, lore role, and base stats. Shiny badge visible if applicable. "Add to party" shortcut. Dismiss returns to IDLE.
- **Duplicate result**: Compact card showing element, "+[N] XP", current level, level-up animation if leveled during this pull, and shiny badge if upgrade occurred. Dismiss returns to IDLE.
- **Result dismissal**: Gamepad: face button (confirm). Keyboard: Enter/Space. All dismissal paths return to IDLE.

### Accessibility

- Element color signatures must be supplemented with distinct shape/pattern indicators (not color alone) to support colorblind players.
- Pull animation must respect reduced-motion settings — an instant-resolve mode should be available, jumping directly to the result screen.

## Acceptance Criteria

### Pull Execution

- [ ] AC-H01: A pull with balance ≥50 Scraps deducts exactly 50 Scraps and produces an outcome.
- [ ] AC-H02: A pull with balance <50 Scraps neither deducts Scraps nor produces any outcome; the pull button is in DISABLED state.
- [ ] AC-H03: Post-pull balance equals pre-pull balance minus 50 (no over- or under-deduction).

### Rarity Distribution

- [ ] AC-H04: Over 10,000 simulated pulls with a fixed RNG seed, tier frequencies are within ±2% of targets: Common 50%, Uncommon 40%, Rare 10%.
- [ ] AC-H05: Over 10,000 pulls with a fixed RNG seed, each Common element (Fire, Ice) appears between 23%–27% of pulls.
- [ ] AC-H06: Over 10,000 pulls with a fixed RNG seed, each Uncommon element (Storm, Venom, Stone) appears between 11.33%–15.33% of pulls.

### Pity System

- [ ] AC-H07: After exactly 9 consecutive non-Rare pulls, the 10th pull always produces Rare (Shadow).
- [ ] AC-H08: The pity counter resets to 0 after any Rare+ pull (natural or forced).
- [ ] AC-H09: The pity counter increments by 1 after each Common or Uncommon pull.
- [ ] AC-H10: If `pityCounter == 9` and the natural draw is Rare (Shadow), the pull is treated as a natural pull — the 2% shiny roll applies normally, the counter resets to 0, and pity force is not triggered.
- [ ] AC-H11: The pity counter is written to save data after each pull; on load, `pityCounter` has the exact value it had when saved (verified by: save with counter at 7, reload, assert counter == 7).

### Shiny Protocol

- [ ] AC-H12: Over 10,000 pulls with a fixed RNG seed, the shiny rate is between 1%–3%.

### Dragon Unlock

- [ ] AC-H15: A pull for an unowned element sets `dragon.owned = true`.
- [ ] AC-H16: A shiny pull for an unowned element sets `dragon.shiny = true`.
- [ ] AC-H17: A non-shiny pull for an unowned element sets `dragon.shiny = false`.

### Duplicate XP

- [ ] AC-H18: A Common duplicate awards exactly 50 XP (`50 × 1`).
- [ ] AC-H19: An Uncommon duplicate awards exactly 100 XP (`50 × 2`).
- [ ] AC-H20: A Rare (Shadow) duplicate awards exactly 150 XP (`50 × 3`).
- [N/A] AC-H21: Void is not in the standard Hatchery pool. If Void duplicate handling is needed, this AC migrates to the Singularity GDD where Void acquisition is designed.
- [ ] AC-H22: A Stage I dragon (level 5, XP 30) receiving a Common duplicate (50 XP) levels up once via Dragon Progression Formula 4: 30 + 50 = 80; 80 − 50 = 30 remainder at Stage I threshold 50. Final: level 6, XP 30.
- [ ] AC-H23: A dragon at MAX_LEVEL (60) receiving any duplicate XP award does not level up; Dragon Progression Formula 4 discards the XP and sets `dragon.xp = 0`. Dragon remains at level 60.

### Shiny Upgrade on Duplicate

- [ ] AC-H24: A shiny pull on an owned non-shiny dragon sets `dragon.shiny = true` without changing `dragon.level` or `dragon.xp`.
- [ ] AC-H25: A non-shiny pull on an owned shiny dragon leaves `dragon.shiny = true` (no downgrade).
- [ ] AC-H26: Given `dragon.shiny = false`, `dragon.level = MAX_LEVEL`, `dragon.xp = 0`: a shiny duplicate pull sets `dragon.shiny = true`; `dragon.xp` remains 0 and `dragon.level` remains MAX_LEVEL.

### Atomicity and Post-Collection

- [ ] AC-H27 [Integration — requires stubbed save layer]: If save fails after Scrap deduction but before outcome is applied, on next load the player's balance is restored to its pre-pull value and no outcome is recorded.
- [ ] AC-H28: With all 6 standard dragons owned, every pull produces a duplicate XP outcome — no new-dragon intro sequences trigger.
- [ ] AC-H29: A shiny duplicate pull on an owned non-shiny dragon not at MAX_LEVEL awards XP (dragon.xp increases) and sets `dragon.shiny = true` in the same pull resolution — both effects apply, neither is skipped.

### Element Soft-Pity

- [ ] AC-H30: With `drought[Stone] = 39` (below guaranteed), a pull is NOT forced to Stone — the ramp draw executes. The result may naturally be Stone but is not certain.
- [ ] AC-H31: With `drought[Stone] = 40`, the next pull is forced to Stone regardless of the natural draw result.
- [ ] AC-H32: After any Stone pull (natural, ramp, or guaranteed), `drought[Stone] = 0` and each of the other five drought counters has incremented by 1.
- [ ] AC-H33: With `drought[Storm] = 42` and `drought[Venom] = 40`, Storm is forced (highest counter). Venom's counter increments to 41, remains above the guaranteed threshold, and can trigger the subsequent pull.
- [ ] AC-H34: A soft-pity-forced Shadow pull resets the Rare+ pity counter to 0. A soft-pity-forced Stone pull increments the Rare+ pity counter by 1.
- [ ] AC-H35: With `drought[Stone] = 40` and `pityCounter = 9` simultaneously, element soft-pity takes priority — Stone is forced. `pityCounter` increments to 10. The next pull fires Rare+ pity (Shadow), resetting `pityCounter` to 0.
- [ ] AC-H36: Over 10,000 simulated pulls with `drought[Stone]` held at 30 and all other drought counters below onset, Stone appears in 35%–45% of those pulls (Formula 9 expected value ≈ 39.5%; ±2σ tolerance).
- [ ] AC-H37: All 6 element drought counters are written to save data atomically with each pull. On load, all 6 counters match their pre-save values (verify: save with `drought[Fire] = 7`, `drought[Stone] = 19`, reload, assert both counters unchanged).
- [ ] AC-H38: Over 10,000 simulated pulls from pityCounter = 0, `drought[Shadow]` never reaches `ELEMENT_SOFT_PITY_ONSET` (20) — it resets via Rare+ pity every ≤10 pulls; max observed value must be ≤ 9.

## Open Questions

**OQ-H01 — MAX_LEVEL [RESOLVED]**: MAX_LEVEL = 60, owned by Dragon Progression GDD (confirmed 2026-05-22). AC-H23 is now unblocked. Hatchery delegates its XP cap logic to Dragon Progression Formula 4.

**OQ-H03 — Collection completion event**: No signal or narrative beat fires when the player collects the final dragon. Consider whether the Hub or Felix dialogue should react to full collection.

**OQ-H04 — Element soft-pity** *(Resolved 2026-05-24)*: Campaign Map revision 4 established a forward contract requiring per-element drought protection to ensure Act 4's Elemental Matrix gate is always attainable. Element soft-pity is now fully designed: Rule 4b, Formula 9, E11–E14, AC-H30–H38, and ELEMENT_SOFT_PITY_ONSET/GUARANTEED tuning knobs. The 20-pull onset and 40-pull guarantee are Campaign Map canonical values.

**OQ-H06 — Browser build divergence** *(Resolved)*: Godot port rates are canonical (Uncommon 40%, Rare 10%, no Exotic). Browser build update is tracked as a separate external action. No GDD change required.
