# Shop & Crafting

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: P1 — Collection Is the Heartbeat; P5 — Earned Mastery, Never Trivialized

## Summary

The Shop & Crafting system is a two-tab screen that converts battle-earned
resources (Data Scraps and Element Cores) into permanent or one-shot player
advantages. The Buy tab offers direct-purchase items; the Forge tab converts
Element Cores into higher-value crafted items. Together they form the primary
economic sink for the game's two resource types.

> **Quick reference** — Layer: `Feature` · Priority: `Alpha` · Key deps:
> `Hatchery, Fusion, Battle Rewards, Persistence`

## Overview

After winning battles, players accumulate Data Scraps (soft currency) and
element-typed Cores (consumable crafting materials). The Shop screen
(`src/ShopScreen.jsx`) presents two tabs: **BUY**, which trades Scraps for
items with immediate or deferred effects, and **FORGE**, which consumes Cores
(and optionally Scraps) to produce crafted items unavailable in the Buy tab.
Items in the Buy tab are purchased individually; items in the Forge tab
require a specific Core combination and may also require a target dragon.
All economy state lives in the `save` object under `dataScraps` and
`save.inventory`; mutations go through `persistence.js` helpers that
re-read/write `localStorage` atomically.

## Player Fantasy

The player should feel the weight of commitment: spending a finite pool of
Element Cores on an irreversible upgrade is a one-way door, and the Shop
is the place where that decision is made. Every core held in inventory
represents stored potential; the moment of converting them into a Stability
Matrix or an Elder Shard is the payoff — a decisive act, not a routine click.
(The broader loop of accumulating those cores belongs to the economy GDD;
this screen owns the moment you spend them.) The Buy tab
serves immediate gratification ("I need XP now"); the Forge tab serves the
satisfaction of long-term planning ("I've been saving six different cores
for this Void Fragment pull").

MDA target aesthetics: **Discovery** (finding and completing Core sets),
**Achievement** (spending toward a specific goal), **Expression** (choosing
which dragons to invest in).

## Detailed Design

### Core Rules

#### Buy Tab

1. The Buy tab displays exactly 5 purchasable items (defined in
   `src/shopItems.js`, `BUY_ITEMS` array). Items are shown regardless of
   whether the player can afford them; unaffordable items are rendered with a
   `.disabled` CSS class and are not clickable.
2. A player selects an item by clicking it. Items requiring a target dragon
   (`requiresTarget: true`) additionally require selecting a dragon from the
   target picker before the BUY button enables.
3. The Element Reroll (`requiresFused: true`) additionally filters the target
   picker to only show dragons whose `fusedBaseStats` is non-null — i.e.,
   dragons that have previously been fused.
4. On purchase: `spendScraps(item.cost)` deducts the cost from `dataScraps`,
   then the item effect is applied. The transaction is not atomic — if effect
   application crashes after `spendScraps`, scraps are lost. (No rollback
   mechanism exists in the current implementation.)
5. Non-stackable items (`stackable: false`) have no enforcement in the Buy tab
   — the player may purchase them multiple times if they have scraps.
   ("Non-stackable" is a flag for UI labeling, not a hard gate.)
6. XP Booster is the only stackable item; each purchase adds 3 battles to the
   `xpBoostBattles` counter, which stacks additively.

#### Forge Tab

1. The Forge tab displays exactly 4 recipes (`FORGE_RECIPES` array).
2. Affordability is determined by `canForge(recipe, save)`, which checks:
   a. `save.dataScraps >= recipe.scrapsCost`, AND
   b. The Core inventory satisfies the recipe's core requirement (see Core
      Requirements below).
3. Core requirements come in four mutually exclusive shapes:
   - `same: N` — requires N cores of a single element (any element qualifies;
     the first eligible element in `ELEMENTS_FOR_CORES` iteration order is used
     automatically).
   - `different: N` — requires at least 1 core each of N distinct elements.
   - `any: N` — requires N total cores across any element combination.
   - `allSix: true` — requires at least 1 core of every element in
     `ELEMENTS_FOR_CORES` (fire, ice, storm, stone, venom, shadow).
4. On forge: Scraps and Cores are consumed first, then the effect is applied.
   Core consumption for `different` and `any` recipes iterates
   `ELEMENTS_FOR_CORES` in fixed order (fire → ice → storm → stone → venom →
   shadow) and takes cores from whichever elements come first — the player
   cannot choose which cores are consumed.
5. Elder Shard (`grantXp` effect with `any: 5`) requires a target dragon
   selection in the Forge tab despite not having `requiresTarget: true` in the
   recipe definition; the UI handles this as a special case
   (`src/ShopScreen.jsx` lines 219–232).
6. Dragon Essence (`grantXpElement` effect with `same: 3`) automatically
   applies XP to a dragon of the matching element — no target selection is
   needed. The element is determined by `getForgeableElement(recipe, save)`.

#### Core Economy

1. Cores are earned by winning NPC battles. On each battle win, the system
   rolls `Math.random() < CORE_DROP_CHANCE` (0.60 = 60%). If the roll
   succeeds, the dropped core element matches the defeated NPC's element.
2. On a successful drop, `Math.random() < CORE_DOUBLE_CHANCE` (0.20 = 20%)
   determines whether 1 or 2 cores drop.
3. Cores are stored per-element in `save.inventory.cores`. Each element is
   capped at 99 via `Math.min(99, ...)` in `addCore()`.
4. The Shop screen's core inventory display shows all six forgeable elements
   (fire, ice, storm, stone, venom, shadow) regardless of whether the player
   holds any — elements with zero cores render with neutral styling.

### States and Transitions

| State | Entry Condition | Exit Condition | Behavior |
|-------|----------------|----------------|----------|
| No item selected | Screen opens; after purchase/forge | Player selects item card | Detail panel shows placeholder text |
| Item selected (no target needed) | Click affordably-priced item | Another selection; purchase | Detail panel shows item info + BUY/FORGE button |
| Item selected (target required) | Click item with `requiresTarget` | Another selection; purchase | Detail panel shows target picker; BUY/FORGE disabled until target chosen |
| Purchase success | Click enabled BUY/FORGE | 1500 ms | Success message overlay shown; selection cleared |
| XP Boost active | XP Booster purchased | `xpBoostBattles` reaches 0 | On-screen status bar shows remaining battle count |

### Interactions with Other Systems

**Battle system** (data flows in from Battle): On battle win, `BattleScreen.jsx`
calls `addCore(npcElement, coreCount)` when the drop roll succeeds. Also calls
`decrementXpBoost()` if `save.inventory.xpBoostBattles > 0`, multiplying
`xpGained` by 3 before the XP is applied.

**Hatchery** (Shop affects Hatchery): `pityReset` sets `save.pityCounter` to 9
(one below `PITY_THRESHOLD = 10`), so the next hatchery pull is guaranteed
Rare+. `exoticPull` (Void Fragment forge recipe) also calls
`updatePityCounter(9)` — both effects share the same mechanism and produce the
same result (guaranteed Rare+ on next pull, not a guaranteed Exotic
specifically).

**Fusion** (Shop affects Fusion): `stabilityBoost` sets `save.inventory.stabilityBoost`
to `true`. `FusionScreen.jsx` reads this flag and passes it to `executeFusion`,
which in turn passes it to `getStabilityTier`. If the stability tier is not
already `stable`, the boost promotes it by one tier (`unstable` → `normal`,
`normal` → `stable`). The flag is consumed (set to `false`) after a fusion
where it actually changes the tier; it is NOT consumed if the pair is already
`stable`.

**Persistence** (all shop actions write through): All mutations go through
`persistence.js` helpers. Each helper performs a full load-mutate-write cycle
on `localStorage` key `dragonforge_save`.

## Formulas

### XP Booster Multiplier

```
xpGained_boosted = xpGained_base * 3
```

Applied in `BattleScreen.jsx` line 904 after `calculateXpGain()` runs.
The booster consumes one charge per battle win (not per battle entry).

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| xpGained_base | integer | varies by NPC and level delta | battleEngine | XP before boost |
| xpGained_boosted | integer | 3× base | calculated | XP credited to the dragon |

**Expected effect**: XP Booster provides 3× XP on the next 3 battle wins.
Each purchase adds exactly 3 charges, stacking additively with existing charges.

### Element Reroll Variance

```
rerolled[stat] = base[stat] + floor(random() * variance * 2) - variance
where variance = floor(base[stat] * 0.2)
```

Applied in `ShopScreen.jsx` lines 46–48 for each stat key in `fusedBaseStats`.

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| base[stat] | integer | varies (dragon's fused base stat) | save.dragons[id].fusedBaseStats | Current stat value before reroll |
| variance | integer | floor(base[stat] * 0.2) | calculated | Maximum swing in either direction |
| rerolled[stat] | integer | base[stat] ± variance | calculated | New stat value after reroll |

**Expected output range**: Each stat moves by at most ±20% of its current fused
value. The distribution is uniform within that window (not Gaussian).

**Edge case**: If `base[stat]` is 0, variance is 0 and the stat is unchanged.
No minimum-value clamp is applied — a very low base stat could theoretically
reroll to a negative value if base[stat] < variance calculation allows it
(in practice fused base stats are all positive integers, so negative results
do not occur under normal play).

### Core Drop Probability

```
P(drop) = CORE_DROP_CHANCE = 0.60
P(double | drop) = CORE_DOUBLE_CHANCE = 0.20

Expected cores per battle win = 0.60 * (0.80 * 1 + 0.20 * 2) = 0.60 * 1.20 = 0.72
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| CORE_DROP_CHANCE | float | [0, 1] | `src/shopItems.js` line 3 | Probability a core drops at all |
| CORE_DOUBLE_CHANCE | float | [0, 1] | `src/shopItems.js` line 4 | Conditional probability of 2 cores given a drop |

**Expected cores per win**: 0.72 cores of the NPC's element.
**Core cap**: 99 per element (`persistence.js` line 325, `addCore`).

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player buys XP Booster with 0 scraps | `canAffordBuy` returns false; BUY button is disabled | Guard at `ShopScreen.jsx` line 19 |
| Player purchases multiple XP Boosters in sequence | `xpBoostBattles` increments by 3 each time (stacks) | `setXpBoost((save.inventory?.xpBoostBattles \|\| 0) + 3)` — ShopScreen line 28 |
| Pity Reset purchased when pityCounter already ≥ 9 | Sets counter to 9 again; effectively a no-op bonus | `updatePityCounter(9)` is unconditional |
| Void Fragment effect vs. Pity Reset effect | Both set pityCounter to 9; neither guarantees an Exotic — only Rare+ | `exoticPull` comment in `ShopScreen.jsx` line 123: "Set pity to max so next pull is guaranteed Rare+" |
| Stability Matrix purchased and applied to an already-stable fusion pair | Flag is NOT consumed; `FusionScreen.jsx` line 64 only calls `setStabilityBoost(false)` when `getStabilityTier(...) !== 'stable'` | Prevents wasting the boost on a pair that already gets the stable bonus |
| Element Reroll on a dragon without fusedBaseStats | Target picker (`requiresFused: true`) filters these dragons out; BUY button cannot be enabled | ShopScreen line 206: `!selectedItem.requiresFused \|\| save.dragons[el].fusedBaseStats` |
| Core cap reached (99 of an element) | Additional cores of that element are silently capped at 99 | `Math.min(99, ...)` in `addCore()`, persistence.js line 325 |
| Dragon Essence forged but no dragon of that element is owned | `addDragonXp` is called on the element key regardless of ownership; XP is applied to the save slot but the dragon is not owned | XP is not lost but provides no visible benefit until the dragon is obtained |
| Core consumption for `different` recipe — player has cores of only one element but count ≥ 3 | `canForge` checks `owned.length >= recipe.cores.different` where `owned` is distinct elements with ≥ 1 core; fails if only one element is present | `src/shopItems.js` line 114 |
| `any` recipe consumption depletes multiple elements | Iteration takes from fire first, then ice, then storm, etc. until N total consumed; player cannot control which elements are spent | Fixed iteration order in `ShopScreen.jsx` lines 90–100 |

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Battle Rewards | Battle → Shop | Provides Data Scraps (`addScraps`) and Element Cores (`addCore`) that fill shop economy faucets |
| Hatchery | Shop → Hatchery | Pity Reset and Void Fragment write `save.pityCounter`; Hatchery reads this on each pull |
| Fusion | Shop → Fusion | Stability Matrix writes `save.inventory.stabilityBoost`; FusionScreen reads this flag |
| Dragon Progression | Shop → Dragons | XP items call `addDragonXp` (persistence.js), feeding the canonical XP curve |
| Persistence | Shop → Persistence | All shop mutations go through `spendScraps`, `spendCores`, `setXpBoost`, `setStabilityBoost`, `addDragonXp`, `upgradeDragonShiny`, `updatePityCounter` |

## Tuning Knobs

| Parameter | Current Value | Safe Range | Category | File:Line | Effect of Increase | Effect of Decrease |
|-----------|--------------|------------|----------|-----------|-------------------|-------------------|
CORE_DROP_CHANCE and CORE_DOUBLE_CHANCE are tuning knobs owned by design/gdd/economy.md.

| Core cap per element | 99 | 20–99 | Gate | `persistence.js:325` | More inventory depth; later pressure to spend | Earlier pressure to spend cores; overflow waste if farming |
| XP Booster cost | 100 scraps | 50–300 | Curve | `shopItems.js:9` | Higher bar for XP acceleration | XP Booster becomes default early spend |
| XP Booster charges per purchase | 3 battles | 1–10 | Curve | `ShopScreen.jsx:28` | More value per purchase; less return trips | More granular purchasing |
| XP Booster multiplier | 3× | 1.5×–5× | Feel | `BattleScreen.jsx:904` | Stronger leveling burst | Weaker acceleration |
| Shiny Charm cost | 500 scraps | 200–1000 | Curve | `shopItems.js:22` | Cosmetic upgrade becomes long-term goal | Shiny variants become trivial to obtain |
| Pity Reset cost | 100 scraps | 50–200 | Curve | `shopItems.js:32` | Players hoard scraps for guaranteed pulls | Pity manipulation becomes routine |
| Element Reroll cost | 200 scraps | 100–400 | Curve | `shopItems.js:39` | Stat optimization is a late investment | Re-rolling becomes frequent early |
| Data Fragment cost | 50 scraps | 25–150 | Curve | `shopItems.js:49` | Targeted XP is expensive; farming preferred | Data Fragment becomes primary XP source |
| Element Reroll variance | ±20% of base stat | ±10%–±35% | Feel | `ShopScreen.jsx:46` | Higher swing; more gambling feel | Safer but less exciting rerolls |
| Dragon Essence XP | 200 | 100–400 | Curve | `shopItems.js:66` | Strong mid-game leveling from forging | Less incentive to grind for cores |
| Stability Matrix scrap cost | 100 | 0–300 | Curve | `shopItems.js:75` | Higher barrier to guaranteed-stable fusions | Stability boost becomes near-free |
| Elder Shard XP | 500 | 200–1000 | Curve | `shopItems.js:85` | Powerful late-game XP injection | Elder Shard becomes marginal vs. Dragon Essence |
| Elder Shard scrap cost | 300 | 100–600 | Curve | `shopItems.js:86` | High combined resource cost | Any-5-cores becomes frequent mid-game |
| Void Fragment scrap cost | 500 | 200–1000 | Curve | `shopItems.js:93` | Exotic-tier pull set requires major scrap investment | Void Dragon pull becomes available mid-game |

## Visual/Audio Requirements

N/A — turn-based browser game. The Shop screen plays `shopPurchase` sound on
every completed purchase or forge action. Item cards display an emoji icon.
No animation or timing-sensitive feedback is required.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Item selected | Card highlighted with `.selected` class | `buttonClick` sound | High |
| Item unaffordable | Card rendered with `.disabled` class; not clickable | None | High |
| Purchase / Forge completed | Success message ("X purchased!") shown for 1500 ms | `shopPurchase` sound | High |
| XP Boost active | Status bar beneath shop layout showing remaining charges | None | Medium |
| Core inventory | Six element badges always visible; non-zero counts styled with element color | None | Medium |

## Game Feel

N/A — turn-based browser game. Input latency, frame data, hit-stop, screen
shake, and controller rumble do not apply to this screen. The primary feel
concern is decision clarity: the player must immediately understand what they
are spending, what they are getting, and whether they can afford it.

### Feel Acceptance Criteria

- [ ] A player can determine whether they can afford any item within one glance
      at the item card (cost visible, disabled state clearly distinct)
- [ ] A player can identify which cores they hold without navigating away from
      the shop (core inventory strip always visible at top of shop layout)
- [ ] Purchase confirmation ("X purchased!") is legible before it fades

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| Data Scraps balance | NavBar | Every `refreshSave()` call | Always |
| Core inventory (all 6 elements) | Shop header strip | On screen load and after each forge | Always visible in shop |
| Item cost | Item card + BUY/FORGE button label | Static (data-driven) | On card render |
| XP Boost remaining charges | Bottom of shop layout | After each battle win that consumes a charge | Only when `xpBoostBattles > 0` |
| Target picker | Detail panel | On item selection | Only for items with `requiresTarget: true`, or Elder Shard in Forge tab |
| Success message | Detail panel | 1500 ms after purchase | After any successful buy or forge |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| Pity counter threshold | `design/gdd/hatchery-gacha.md` | `PITY_THRESHOLD = 10`; pity mechanics | Rule dependency |
| Stability tier promotion | `design/gdd/fusion.md` | `getStabilityTier` and `STABILITY_ORDER` | Rule dependency |
| Canonical XP curve | `design/gdd/dragon-progression.md` | `applyDragonXp` / `xpForLevel` | Data dependency |
| Core drop (battle win) | `design/gdd/economy.md` | `CORE_DROP_CHANCE`, `CORE_DOUBLE_CHANCE`, `addCore` | Data dependency |
| Data Scraps (battle win) | `design/gdd/economy.md` | `scrapsReward`, `addScraps` | Data dependency |

## Acceptance Criteria

- [ ] Purchasing an unaffordable item is blocked: BUY button is disabled, card
      is not clickable when `save.dataScraps < item.cost`
- [ ] XP Booster: after purchase, `save.inventory.xpBoostBattles` increases by
      exactly 3; on each of the next 3 battle wins, XP is tripled and the counter
      decrements by 1
- [ ] Pity Reset: after purchase, `save.pityCounter` equals 9; the next hatchery
      pull draws from Rare+ pool only
- [ ] Stability Matrix: after purchase, `save.inventory.stabilityBoost` is `true`;
      a subsequent fusion of an `unstable` pair produces `normal` tier, and a
      `normal` pair produces `stable` tier; the flag is `false` after use; flag
      is NOT consumed for an already-`stable` pair
- [ ] Element Reroll: each stat in `fusedBaseStats` after reroll is within
      ±20% of its pre-reroll value (inclusive); requires dragon with non-null
      `fusedBaseStats` to be selectable as target
- [ ] Dragon Essence (3 same-element cores): XP 200 is applied to a dragon of
      the forged element; 3 same-element cores are consumed from inventory
- [ ] Elder Shard (any 5 cores + 300 scraps): XP 500 is applied to the selected
      target dragon; exactly 5 cores total consumed, taken from elements in
      iteration order (fire → ice → storm → stone → venom → shadow); 300 scraps
      deducted
- [ ] Void Fragment (1 of each of 6 elements + 500 scraps): `pityCounter` set to 9;
      1 core of each element consumed; 500 scraps deducted
- [ ] Core cap: `save.inventory.cores[element]` never exceeds 99
- [ ] No hardcoded values in implementation (all costs/XP amounts come from
      `BUY_ITEMS` / `FORGE_RECIPES` data arrays in `shopItems.js`)

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Void Fragment grants Rare+ but not guaranteed Exotic — should the effect be renamed or clarified in UI copy? | Game Designer | — | Open |
| Non-stackable flag has no enforcement gate — intended as UI label only, or should future build add a hard purchase limit? | Game Designer | — | Open |
| `different` and `any` recipe core consumption iterates in fixed element order, giving the player no choice over which cores are spent — is this the desired UX? | Game Designer | — | Open |
