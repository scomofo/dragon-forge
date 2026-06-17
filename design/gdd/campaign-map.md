# Campaign Map

> **Status**: Implemented
> **Author**: reverse-document (Claude)
> **Last Updated**: 2026-06-16
> **Last Verified**: 2026-06-16
> **Implements Pillar**: Structured Progression — a directed graph of encounters gives the player a clear goal ladder from first dragon to Singularity endgame.

## Summary

The Campaign Map is a directed acyclic graph (DAG) of nine NPC battle nodes arranged across a stylized "Elemental Matrix" backdrop. The player traverses the graph by defeating prerequisite nodes before unlocking downstream ones, with the route culminating in two boss-tier encounters. It is the primary structured-progression path in Dragon Forge, bridging the Hatchery's early free-play to the Singularity endgame.

> **Quick reference** — Layer: `Core` · Priority: `MVP` · Key deps: `battle-engine`, `persistence`, `hatchery`, `singularity`

---

## Overview

The Campaign Map presents nine battles as interactive nodes pinned to a percentage-coordinate canvas. Each node records an element affinity, a difficulty rating, an NPC enemy, and a set of prerequisite node IDs. A node is **locked** until all its prerequisites are cleared, **available** once they are, and **cleared** permanently after the player wins its battle. The player selects a node, picks one owned dragon from their roster as their "guardian," and launches a battle via `handleBeginCampaignBattle`. On victory, `recordNpcDefeat` writes the NPC ID to `save.defeatedNpcs`, and that single flag drives the entire lock/unlock graph on every subsequent render.

The map also displays a running "Signal Pressure" percentage — a cosmetic dread meter equal to `100 − (clearedCount / 9 × 100)` — that ties campaign progress to the Singularity's framing narrative without gating any mechanics.

---

## Player Fantasy

The player should feel like a growing force pushing through a hostile, digitally-corrupted world. Each node cleared should feel like reclaiming territory: the visual feedback shifts connections from dormant to active, and the telemetry panel updates in real time. Selecting a node and then choosing the right dragon for the matchup — inspecting NPC stats against guardian stats — should satisfy the Competence need (SDT): the player who reads elements and stat spreads makes meaningfully better choices than one who ignores them.

The boss nodes at the end of each branch should feel like gates, not just harder normal nodes. Their visual treatment (type badge "B," boss-tier difficulty label, higher reward preview) signals a qualitative shift.

Primary MDA aesthetics served: **Challenge** (escalating gate structure), **Discovery** (unlocking new routes and nodes), **Fantasy** (powering up a dragon squad and clearing a corrupted matrix).

---

## Detailed Design

### Core Rules

1. The campaign consists of exactly **9 nodes** defined in `src/campaignMap.js → CAMPAIGN_NODES`.
2. Each node has a stable string `id`, an NPC reference via `npcId`, a node `type` (`normal` | `elite` | `boss`), an `element`, a `difficulty` label, a `position` in percentage coordinates, a `prerequisiteIds` array, and a `rewardPreview` string.
3. Node state is computed fresh on every render from `save.defeatedNpcs` (array of NPC ID strings) and `save.campaign.clearedNodeIds` (array of node ID strings) — both routes are checked via `isCampaignNodeCleared` (`src/campaignMap.js:112–117`).
4. A node is **cleared** if `node.id ∈ save.campaign.clearedNodeIds` OR `node.npcId ∈ save.defeatedNpcs`.
5. A node is **available** if it is not cleared AND every node in its `prerequisiteIds` is cleared.
6. A node is **locked** if it is not cleared AND at least one prerequisite node is not cleared.
7. The player may **select** any node regardless of state; selection does not require the node to be available.
8. The player may only **begin battle** when `selectedState === 'available' AND selectedDragonId !== null` (`src/CampaignMapScreen.jsx:94`).
9. On entering battle, `handleBeginCampaignBattle` passes `{ dragonId, npcId, campaignNodeId: nodeId, returnScreen: SCREENS.MAP }` to `BattleScreen`. The `returnScreen` field ensures the player returns to the map on battle end (`src/App.jsx:112–122`).
10. On a win in `BattleScreen`, `recordNpcDefeat(npcId)` is called (`src/BattleScreen.jsx:962`), writing the NPC ID to `save.defeatedNpcs`. This is the sole persistence event for clearing a campaign node.
11. A cleared node cannot be re-entered from the Campaign Map screen (the "BEGIN BATTLE" button reads "NODE STABILIZED" and is disabled when `selectedState === 'cleared'`).
12. All 9 nodes may be revisited for inspection at any time; only the battle entry is blocked for cleared nodes.
13. In **New Game+**, `applyNewGamePlus` resets `save.defeatedNpcs = []`, which re-locks all campaign nodes while preserving the player's dragon collection, DataScraps, and cores (`src/persistence.js:424–432`).

### NPC Scaling Rule

When a battle is launched from the Campaign Map, `BattleScreen` calls `getScaledNpcStats(baseStats, baseLevel, playerLevel, save.ngPlus)`:

- Scale factor = `(1 + max(0, playerLevel − npcBaseLevel) × 0.04) × (1 + ngPlus × 0.25)`.
- This ensures that over-leveled players still face meaningful resistance, and NG+ runs are harder by a flat 25% per tier (`src/BattleScreen.jsx:39–43`).

### Node Graph Structure

The prerequisite graph forms two converging branches that merge at the final boss:

```
[signal-breach] ──────────┬──► [overflow-vent] ──► [crypto-lock] ──┬──► [hydra-spine] ──► [logic-core] ──► [recursive-gate] ──┐
                           │                                         │                                                            ├──► [protocol-vulture]
                           └──► [wraith-cache] ──► [siren-loop] ────┘                                         ────────────────────┘
```

Simplified textual path:
- **Left branch (fire/ice)**: signal-breach → overflow-vent → crypto-lock → hydra-spine → logic-core → recursive-gate → protocol-vulture
- **Right branch (shadow/venom)**: signal-breach → wraith-cache → siren-loop → hydra-spine → protocol-vulture (hydra-spine also depends on crypto-lock)

Both branches pass through `hydra-spine` (dual prerequisite: `crypto-lock` + `siren-loop`). The campaign cannot be completed without clearing both sub-branches.

### Dragon Selection (Guardian)

The "CHOOSE GUARDIAN" panel renders all dragons where `progress.owned === true`. The player taps or clicks one to set `selectedDragonId`. The panel displays the dragon's sprite, nickname/name, level, HP, and ATK. A "GUARDIAN LINK" readout shows the selected dragon's full computed stat block via `calculateStatsForLevel`.

If the player has no owned dragons the panel shows an empty state: "Pull a dragon from the Hatchery to enter the campaign." The Begin Battle button remains disabled until a dragon is selected.

### States and Transitions

| State | Entry Condition | Exit Condition | Player-Visible Behavior |
|-------|----------------|----------------|------------------------|
| `locked` | At least one prerequisite is not cleared | All prerequisites become cleared | Node orb shows "LOCK"; battle entry disabled; unlock hint shown in detail panel |
| `available` | All prerequisites cleared AND node not yet cleared | Player wins battle for this node's NPC | Node orb shows element icon; battle entry enabled when dragon selected |
| `cleared` | `recordNpcDefeat` called with this node's `npcId` | New Game+ reset | Node orb shows "OK"; battle entry shows "NODE STABILIZED" (disabled) |

Route links (SVG lines) become `active` (lit up) when their `fromId` node is cleared. The selected node and its adjacent links receive the `selected` CSS class, highlighting the current context.

### Gamepad Navigation

- **D-Pad / left stick direction**: calls `findDirectionalNode(CAMPAIGN_NODES, selectedNode.id, direction)` to spatially navigate to the nearest node in the pressed direction.
- **LB**: cycle dragon selection backward.
- **RB / Y**: cycle dragon selection forward.
- **A / START**: if no dragon selected, auto-select first owned dragon; if dragon already selected, begin battle.
- **B**: navigate back to `battleSelect` screen.

---

## Formulas

### Node Availability Check

```
isCleared(node) = node.id ∈ save.campaign.clearedNodeIds
               OR node.npcId ∈ save.defeatedNpcs

isAvailable(node) = !isCleared(node)
                 AND ∀ prereqId ∈ node.prerequisiteIds: isCleared(nodeById(prereqId))

state(node) = isCleared(node)   → 'cleared'
            | isAvailable(node) → 'available'
            | otherwise         → 'locked'
```

Source: `src/campaignMap.js:119–127`

### Signal Pressure

```
signalPressure = max(0, 100 − round((clearedCount / 9) × 100))
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `clearedCount` | int | 0–9 | derived from `nodeStates` | Count of nodes in `cleared` state |
| `signalPressure` | int | 0–100 | computed | Cosmetic "dread" percentage shown in map telemetry |

Source: `src/CampaignMapScreen.jsx:80`

**Note**: Signal Pressure is purely cosmetic display. It does not gate any mechanic, buff any enemy, or interact with the Singularity system. The `protocol-vulture` node's `rewardPreview` text reads "Singularity pressure reduced" but this is flavor copy only — no code path reads `signalPressure` to modify game state.

### NPC Stat Scaling

```
levelScale = 1 + max(0, playerLevel − npcBaseLevel) × 0.04
ngMultiplier = 1 + ngPlus × 0.25
scale = levelScale × ngMultiplier

scaledStat[key] = floor(baseStats[key] × scale)   [when scale ≠ 1]
scaledLevel = floor(npcBaseLevel × scale)          [when scale ≠ 1]
```

| Variable | Type | Range | Source | Description |
|----------|------|-------|--------|-------------|
| `playerLevel` | int | 1–50 | `save.dragons[dragonId].level` | Active guardian's current level |
| `npcBaseLevel` | int | 2–12 | NPC definition in `gameData.js` | NPC's design-intent level |
| `ngPlus` | int | 0–N | `save.ngPlus` | New Game+ tier |
| `scale` | float | 1.0+ | computed | Combined scaling multiplier |

Source: `src/BattleScreen.jsx:39–43`, `src/BattleScreen.jsx:126`

**Example**: Player level 10 vs. Firewall Sentinel (base level 2, HP 80). `levelScale = 1 + (10−2)×0.04 = 1.32`. NG+0: scale = 1.32, scaled HP = floor(80 × 1.32) = 105. NG+1: scale = 1.32 × 1.25 = 1.65, scaled HP = floor(80 × 1.65) = 132.

### Reward Scaling (New Game+)

```
xpGained_final = floor(xpGained × (1 + ngPlus × 0.25))
scrapsGained_final = floor(scrapsGained × (1 + ngPlus × 0.25))
```

Source: `src/BattleScreen.jsx:940–943`

### Core Drop

```
coreDropped = (random() < CORE_DROP_CHANCE)           [CORE_DROP_CHANCE = 0.60]
coreCount   = (random() < CORE_DOUBLE_CHANCE) ? 2 : 1 [CORE_DOUBLE_CHANCE = 0.20]
coreElement = npc.element
```

Source: `src/BattleScreen.jsx:972–975`, `src/shopItems.js:3–4`

---

## Edge Cases

| Scenario | Expected Behavior | Rationale |
|----------|------------------|-----------|
| Player has no owned dragons | Dragon picker shows empty-state message; Begin Battle button permanently disabled | Cannot enter battle without a guardian; empty state is reachable after fresh save |
| `save.campaign.clearedNodeIds` is undefined/null | `isCampaignNodeCleared` defaults to `[]` via optional chaining (`save?.campaign?.clearedNodeIds \|\| []`) | Defensive against saves from before the campaign system existed |
| `save.defeatedNpcs` is undefined | `migrateSave` adds `defeatedNpcs: []` on load | Forward-compat migration |
| All 9 nodes cleared | All nodes in `cleared` state; no `available` nodes; `firstActionable` falls back to `CAMPAIGN_NODES[0]`; `availableCount` displays 0 | Campaign complete state is a valid and persistent screen state |
| Player selects a locked node then attempts battle | `canBegin` is false because `selectedState !== 'available'`; button shows "SIGNAL LOCKED" (disabled) | State check at button level prevents any battle entry path |
| Player selects a cleared node then attempts battle | `canBegin` is false; button shows "NODE STABILIZED" (disabled) | Re-farming cleared nodes is intentionally blocked via Campaign Map; free-roam battle is available on the Battle Select screen |
| `hydra-spine` prerequisite: player has cleared `crypto-lock` but not `siren-loop` | `hydra-spine` remains locked; both prerequisites must be cleared | Dual-prerequisite gate enforced by `every()` in `getCampaignNodeState` |
| NPC has both `clearedNodeIds` AND `defeatedNpcs` entries | `isCampaignNodeCleared` returns true on the first match (OR logic); no double-counting | Legacy saves that used `clearedNodeIds` coexist safely with newer saves using `defeatedNpcs` |
| NG+ reset | All nodes revert to locked/available state; map renders fresh progression from signal-breach | `defeatedNpcs = []` in `applyNewGamePlus` drives the re-lock; dragon collection preserved |
| NPC level scaling when `playerLevel === npcBaseLevel` | `levelScale = 1 + 0 = 1`; `scale = 1 × ngMultiplier`; the `if (scale === 1)` branch in `getScaledNpcStats` returns base stats unchanged for NG+0 | Avoids unnecessary object allocation; base stats used as-is |
| NPC level scaling when `playerLevel < npcBaseLevel` | `max(0, ...)` clamps to 0; scale = 1 × ngMultiplier (no de-buff) | Lower-leveled players fight base-stat NPCs; the challenge is natural |

---

## Dependencies

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| Battle Engine (`battleEngine.js`) | Campaign Map depends on | Provides `calculateStatsForLevel`, `getStageForLevel` for guardian stat display and NPC scaling |
| Persistence (`persistence.js`) | Campaign Map depends on | Reads `save.defeatedNpcs`, `save.campaign.clearedNodeIds`, `save.ngPlus`; writes via `recordNpcDefeat` on battle win |
| Game Data (`gameData.js`) | Campaign Map depends on | NPC stat definitions (hp, atk, def, spd, level, element, moveKeys, signatureMoveKey) used to populate detail panel and drive battle |
| Hatchery (`hatcheryEngine.js`) | Campaign Map depends on | Dragons must be hatched/owned before they can be selected as a guardian |
| Battle Screen (`BattleScreen.jsx`) | Battle Screen depends on Campaign Map | Receives `campaignNodeId` in `battleConfig`; calls `recordNpcDefeat` on win; uses `getAvailableCampaignNodes` for post-battle context |
| Singularity (`singularityProgress.js`) | Singularity depends on Campaign Map | Campaign completion (specifically defeating `protocol_vulture`) is the narrative precursor to the Singularity arc; no hard code dependency found — progression is narrated, not gated |
| App Router (`App.jsx`) | App depends on Campaign Map | Mounts `CampaignMapScreen`; provides `onBeginCampaignBattle` callback; reads `returnScreen: SCREENS.MAP` to navigate back after battle |
| Gamepad Input (`gamepadInput.js`) | Campaign Map depends on | `findDirectionalNode` for spatial gamepad navigation |

---

## Tuning Knobs

All values live in source files. None are currently in a dedicated external data file in `assets/data/`.

| Parameter | Current Value | File:Line | Safe Range | Category | Effect of Increase | Effect of Decrease |
|-----------|--------------|-----------|------------|----------|-------------------|-------------------|
| NPC level scale per over-level | `0.04` (+4% per level above NPC) | `src/BattleScreen.jsx:42` | 0.01–0.10 | Feel | Harder catch-up fights; more incentive to level-match | Grinding levels provides less combat advantage; feels softer |
| NG+ stat multiplier per tier | `0.25` (+25% per NG+ tier) | `src/BattleScreen.jsx:43` | 0.10–0.50 | Curve | Steeper NG+ difficulty; discourages casual re-runs | Easier NG+ re-runs; reduces replayability friction |
| NG+ XP/scrap reward multiplier per tier | `0.25` (+25% per tier) | `src/BattleScreen.jsx:941–942` | 0.10–0.50 | Curve | Greater NG+ grind payoff; may over-inflate economy | Reduces NG+ reward incentive |
| Core drop chance | `0.60` (60%) | `src/shopItems.js:3` | 0.30–0.85 | Curve | More cores drop; fusion materials less scarce | Cores scarcer; fusion gated more aggressively |
| Core double chance | `0.20` (20%) | `src/shopItems.js:4` | 0.05–0.40 | Curve | More bulk core drops; flattens scarcity spikes | More consistent single-core drops |
| Stat display cap for stat bars | `130` | `src/CampaignMapScreen.jsx:30` | 100–200 | Feel | Bars compress at lower fill on high-stat enemies | Bars overflow at max for high-stat enemies |

---

## Visual/Audio Requirements

N/A — turn-based browser game. No frame-data, hitbox timing, or controller rumble.

| Event | Visual Feedback | Audio Feedback | Priority |
|-------|----------------|---------------|----------|
| Node selected | Scanner crosshair animates to node position; selected-map-card callout updates; detail panel refreshes | `playSound('mapNodeReach')` | High |
| Dragon selected | Dragon card highlights with `selected controller-focus` CSS class; Guardian Link panel updates with stats | `playSound('dragonSelect')` | High |
| Begin Battle pressed | Transition to BATTLE screen | `playSound('buttonClick')`, `playMusic('battleTense', true)` | High |
| Node cleared (post-battle return) | Node state flips to `cleared`; orb shows "OK"; route links from that node illuminate as `active` | Music transitions to `mapWander` on return | High |
| Available nodes count update | Telemetry "LIVE" counter updates; progress rail dot refreshes | None (reactive re-render) | Medium |

---

## Game Feel

N/A — turn-based browser game. Input-to-response latency, frame budgets, hit-stop, and controller rumble do not apply.

The map interaction is pointer/touch plus optional gamepad. The primary feel target is **responsive and legible**: selecting a node should immediately update the detail panel (synchronous React state update) with no perceivable lag, and the route highlight should make the player's position in the graph instantly readable. There is no animation delay on node selection — feedback is immediate.

---

## UI Requirements

| Information | Display Location | Update Frequency | Condition |
|-------------|-----------------|-----------------|-----------|
| `clearedCount / 9 STABILIZED` | Campaign map header (progress panel) | On every save reload | Always |
| Progress rail dots (one per node, colored by state) | Campaign map header | On save reload | Always |
| `availableCount LIVE` / `signalPressure% NOISE` / `element TRACE` | Map telemetry strip (bottom-left of canvas) | On node selection / save reload | Always |
| Node type badge (N / E / B) | Each node button | Static | Always |
| Node state orb (LOCK / element icon / OK) | Each node button | On save reload | Always |
| Selected node: label, description, enemy name, element, difficulty, reward | Detail panel (aside) | On node selection | Always |
| Enemy stat bars (HP, ATK, DEF, SPD vs. STAT_CAP=130) | Detail panel: signal-stat-stack | On node selection | If `selectedNpc.stats` exists |
| Route trace chain (prerequisite node chips) | Detail panel: selected-route-chain | On node selection | Always |
| Unlock hint (list prerequisite labels) | Detail panel: unlock-note | On node selection | When `selectedState === 'locked'` |
| Dragon picker (all owned dragons with stats) | Detail panel: campaign-dragon-list | On save reload | Always |
| Guardian Link (selected dragon full stat block) | Detail panel: guardian-link | On dragon selection | When dragon selected |
| Begin Battle button label | Detail panel: campaign-begin | On node/dragon selection | Always; label changes per state |

---

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| NPC stat scaling formula | `design/gdd/combat.md` | `getScaledNpcStats` and level-scale math | Rule dependency |
| `calculateStatsForLevel` for guardian display | `design/gdd/combat.md` | Stat computation for dragon progression | Data dependency |
| Core drop rates | `design/gdd/economy.md` | `CORE_DROP_CHANCE = 0.60`, `CORE_DOUBLE_CHANCE = 0.20` | Data dependency |
| `recordNpcDefeat` persistence contract | `design/gdd/save-and-persistence.md` | `save.defeatedNpcs` array write | Ownership handoff |
| Dragon ownership (`progress.owned`) | `design/gdd/hatchery-gacha.md` | Dragon availability for guardian selection | Rule dependency |
| NG+ reset (`applyNewGamePlus`) | `design/gdd/singularity-endgame.md` | `save.defeatedNpcs = []` and `save.ngPlus` increment | State trigger |
| Singularity entry narrative | `design/gdd/singularity-endgame.md` | Campaign completion as Singularity precursor framing | Rule dependency |

---

## Acceptance Criteria

### Functional

- [ ] A fresh save shows only `signal-breach` in `available` state; all other 8 nodes are `locked`.
- [ ] Winning a battle against `firewall_sentinel` transitions `overflow-vent` and `wraith-cache` to `available` (signal-breach cleared).
- [ ] `hydra-spine` remains `locked` until both `crypto-lock` and `siren-loop` are cleared; clearing only one is not sufficient.
- [ ] The Begin Battle button is disabled for `locked` and `cleared` nodes regardless of dragon selection.
- [ ] The Begin Battle button is disabled for an `available` node when no dragon is selected.
- [ ] The Begin Battle button is enabled only when `selectedState === 'available'` AND `selectedDragonId !== null`.
- [ ] `battleConfig.returnScreen` is set to `SCREENS.MAP`; after the battle (win or loss), the player returns to the Campaign Map.
- [ ] Winning `protocol-vulture`'s battle marks `protocol_vulture` in `save.defeatedNpcs`; `protocol-vulture` node shows `cleared` on next render.
- [ ] NG+ reset re-locks all 9 nodes (all states return to the fresh-save arrangement) while dragon collection is intact.
- [ ] Stat bars in the enemy signal panel never exceed 100% fill (capped at `STAT_CAP = 130`).
- [ ] NPC stat scaling: at player level 10 vs. Firewall Sentinel (base level 2), computed HP = `floor(80 × 1.32) = 105` at NG+0.
- [ ] NG+ stat bonus: same fight at NG+1 produces HP = `floor(80 × 1.65) = 132`.

### Experiential (Playtest Validation)

- [ ] Playtesters can read which nodes are locked/available/cleared without referring to any tutorial text.
- [ ] Playtesters navigate to a target node and understand why it is locked (the unlock-note lists the required prerequisites).
- [ ] Selecting different dragons before a fight produces a meaningful perceived difference in readout (stats change visibly).
- [ ] After completing all 9 nodes, playtesters report a sense of campaign closure (no "what do I do now?" confusion about Singularity entry).

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| Should re-cleared NG+ nodes grant rewards again or be one-shot? | Game Designer | Next NG+ balance pass | Currently: `recordNpcDefeat` is idempotent (no duplicate writes), but no reward is blocked by prior defeat — each battle through BattleScreen rewards normally regardless of prior clear status. May want an explicit re-clear reward distinct from first-clear. |
| Should Signal Pressure connect to a mechanical Singularity gate? | Game Designer | Singularity design pass | Currently cosmetic only. A design option: using campaign completion percentage to unlock early Singularity access could create meaningful strategic tension. |
| Should the campaign support partial-branch completion saves with explicit act structure? | Game Designer | Act 2 scope discussion | `save.flags.currentAct` exists in the persistence schema but is not read by campaign map logic; it defaults to 1 and is never incremented by campaign clears. If Act 2 is planned, this flag needs a trigger and the map needs act-gated node sets. |
