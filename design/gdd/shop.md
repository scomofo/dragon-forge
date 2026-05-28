# Shop

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-26 (Revision 4)
> **Implements Pillar**: Core Loop — Explore / Collect

## Overview

The Shop is the Dragon Forge's primary Scrap-spending outlet, operated by Unit 01 — The Kernel — a slowly awakening android stationed at the Dragon Forge Hub. Players spend Data Scraps earned in battle to stock expedition loadouts with consumables (including the Field Kit, the sole mid-expedition HP recovery tool) and, over the course of the campaign, to acquire analog relics later recognized by the Mainframe Crown.

Mechanically, the Shop is a purchase-validation and transaction requester: it reads the player's Scrap balance from a save snapshot, confirms each transaction, and requests a SaveTransaction that spends Scraps through EconomyLedger while setting the relevant purchase flag through Shop/ExpeditionInventoryLedger helpers. The Shop is accessible from the Dragon Forge Hub at any time between expeditions and is not accessible once the player has departed through the Bulkhead. Its inventory is fully deterministic — no random stock rotation — with fixed Data Scrap prices per item.

The economy it sits within has one primary income stream (Data Scraps from battle, ~10–15 per battle) and three Scrap sinks: Hatchery pulls (50 Scraps each), Field Kit purchases, and relic acquisition for endgame progression.

## Player Fantasy

The Field Kit is the reason most players come. The wrench is the reason most players return.

Unit 01 keeps both behind the same counter, in the same quiet light. Unit 01 does not distinguish between them. To Unit 01, the Field Kit is fifty Scraps, and the wrench is more, and the diagnostic lens is more still, and each was placed in inventory at a moment Unit 01 does not remember. Unit 01 only knows they are to be released to the bearer when the bearer has the means. That is the protocol Unit 01 still runs.

The player buys the Field Kit because the next expedition needs it. The player buys the wrench because — the player cannot say. It catches the eye. It feels like it matters. They have seen one somewhere, in the Workshop, in a fragment of the Captain's Log, or in something the world has not yet shown them directly. They buy it. Unit 01 confirms the transaction. The wrench goes into the bag.

The counter is where Skye spends what the world gave her. Unit 01 stands behind it — always behind it — hands flat, eyes neutral. It speaks the same lines it has always spoken. But the relics it keeps are different from the consumables, in a way that Unit 01 cannot articulate and the player will feel before they understand: the Field Kit is *stocked*. The relics are *kept*. Something, somewhere, asked Unit 01 to hold them for the right person. Unit 01 has not been told when that will be.

Months of play later, the wrench will be placed on a different counter. The world will change. And the player will remember the day they bought it from a unit that did not tell them what it was for — because Unit 01 did not know, and neither did the player, and the world was still choosing what shape it wanted to be in at the end.

> **Designer test:** A Shop feature serves this fantasy if it makes the relics feel like objects that *recognize* the player rather than products the player is browsing. A feature that explains a relic's narrative purpose fails. A feature that lets the player buy a future they cannot yet articulate passes. The Field Kit earns its place by being ordinary: without it, the relics do not register as strange.

## Detailed Design

### Core Rules

1. **Access**: The Shop is accessible from the Dragon Forge Hub between expeditions. It is not accessible after the player has departed through the Bulkhead until they have returned via a `HUB_RETURN` node. Unit 01 / The Kernel operates the counter at all times while the Hub is accessible.

2. **Currency**: All purchases are denominated in Data Scraps (`player_scraps`). The player's live Scrap balance is displayed in the Hub HUD at all times. The Shop reads directly from save data — no separate "Shop balance" exists.

3. **Inventory**: The Shop stocks exactly 7 items in fixed positions. The inventory never rotates, restocks, or changes. Items fall into two categories:
   - **Consumables** (4): per-expedition items, capped at 1 of each per expedition
   - **Analog Relics** (3): one-time unique purchases; once owned, the item remains visible as "Owned" and cannot be purchased again

4. **Expedition boundary**: An expedition begins at Bulkhead departure and ends at the next Bulkhead departure. A player who returns to the Hub mid-expedition via a `HUB_RETURN` node **may repurchase** consumables they have already used during that expedition. All consumable flags reset to `false` at each Bulkhead departure.

5. **Consumable save state**: Each consumable has a corresponding expedition boolean: `expedition_field_kit`, `expedition_defrag_patch`, `expedition_cache_shard`, `expedition_emergency_patch`. Shop purchase settlement sets each to `true` through ExpeditionInventoryLedger; Campaign Map/Singularity settlement consumes or resets flags through source-specific ledger helpers. Battle Engine reports Defrag Patch use in its durable delta and never writes the flag directly. All four flags reset to `false` at Bulkhead departure regardless of prior state.

6. **Relic availability**: The three analog relics do not appear in Unit 01's inventory until the player has first passed the Act 2 gate (`acts_unlocked` contains 2). Before this, only the four consumables are visible. After Act 2 entry, relics appear and remain visible until an ending is committed. Purchased relics show "Owned"; unowned relics become archived/inert after `ending_id != ""` and cannot be purchased post-ending.

7. **Relic persistence**: Each relic is a one-way boolean (`relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned`). Once set to `true`, this flag is never reset. Relics are not consumed by reaching the Mainframe Crown.

8. **Transaction atomicity**: Each purchase spends the item price through EconomyLedger and sets the relevant flag in a single atomic SaveTransaction. Partial states (Scraps deducted, flag not set) are never valid. If the save commit fails after staging, the transaction is rolled back.

9. **Insufficient funds / already owned**: A purchase attempted with fewer Scraps than the price is refused without deduction. A repeated purchase of an already-owned relic triggers a distinct Unit 01 response but no transaction.

10. **Scrap floor**: `player_scraps` cannot go below 0 by any transaction.

11. **Scrap carry-over**: `player_scraps` persists between expeditions. There is no hard cap on Scrap accumulation; save data stores the actual integer value. The Hub HUD displays the exact balance up to 999; balances above 999 display as "999+". The displayed cap is UI-only — the underlying value is always accurate.

12. **Soft-lock prevention**: BOSS nodes and major HAZARD nodes in Acts 3–4 award elevated Scrap amounts (see Tuning Knobs: `BOSS_SCRAP_BONUS`, `HAZARD_SCRAP_BONUS`). These bonuses ensure the Act 3 critical path reliably yields enough Scraps to cover the cheapest relic (175) alongside normal collection play, without requiring dedicated farming sessions.

### Item Catalog

| # | Item | Category | Price | Effect | Cap | Use Timing |
|---|------|----------|-------|--------|-----|------------|
| 1 | Field Kit | Consumable | 50 Scraps | Full HP restore, all loadout dragons (slots 1–3); identical to REST node recovery. Sets `expedition_field_kit = true`. | 1/expedition | MAP_EXPLORE: any landmark node |
| 2 | Defrag Patch | Consumable | 35 Scraps | Remove the currently active status effect from slot-1 dragon. If no status effect is active, the item is consumed with no effect. Sets `expedition_defrag_patch = true`. | 1/expedition | In-battle: "Use Defrag Patch" action in TELEGRAPH |
| 3 | Cache Shard | Consumable | 50 Scraps | Grant XP to `party[0]` dragon via `apply_xp()`, capped so stage transition is never possible. XP awarded = `min(100, cap)`. Sets `expedition_cache_shard = true`. | 1/expedition | MAP_EXPLORE: any landmark node |
| 4 | Emergency Patch | Consumable | 45 Scraps | Restore `party[0]` dragon to 50% of max HP (floor: 1) at any MAP_EXPLORE landmark node (usable between battles, not during). Sets `expedition_emergency_patch = true`. | 1/expedition | MAP_EXPLORE: any landmark node |
| 5 | 10mm Wrench | Analog Relic | 175 Scraps | Analog relic recognized at Mainframe Crown. No immediate gameplay effect. Sets `relic_wrench_owned = true`. Internal ending mapping: Total Restore. | 1 (unique) | Available after Act 2 gate until ending commit |
| 6 | Diagnostic Lens | Analog Relic | 200 Scraps | Analog relic recognized at Mainframe Crown. No immediate gameplay effect. Sets `relic_lens_owned = true`. Internal ending mapping: The Patch. | 1 (unique) | Available after Act 2 gate until ending commit |
| 7 | Kernel Blade | Analog Relic | 225 Scraps | Analog relic recognized at Mainframe Crown. No immediate gameplay effect. Sets `relic_blade_owned = true`. Internal ending mapping: Hardware Override. | 1 (unique) | Available after Act 2 gate until ending commit |

### States and Transitions

| State | Description |
|-------|-------------|
| `SHOP_CLOSED` | Player at Hub, not interacting with Unit 01 |
| `BROWSING` | Player at Unit 01's counter; all visible items displayed; d-pad navigation active |
| `ITEM_FOCUSED` | One item focused; name and price shown |
| `DWELL_REVEAL` | Player holding Confirm ≥ 400ms; full item description displayed; no purchase initiated |
| `CONFIRMING` | Player short-pressed Confirm (< 400ms); confirmation dialog shown with projected post-purchase balance |
| `PURCHASING` | Atomic save write executing |
| `TRANSACTION_COMPLETE` | Consumable write succeeded; balance updated; Unit 01 response; return to BROWSING |
| `RELIC_TRANSACTION_COMPLETE` | Relic write succeeded; balance updated; Unit 01 hands lift from counter surface; pause; Unit 01 relic-specific response; return to BROWSING |
| `INSUFFICIENT_FUNDS` | Refused — brief feedback; return to ITEM_FOCUSED |
| `ALREADY_OWNED` | Duplicate relic attempt — Unit 01 distinct response; no transaction |

| Transition | Trigger |
|-----------|---------|
| `SHOP_CLOSED` → `BROWSING` | Player activates Unit 01 station |
| `BROWSING` ↔ `ITEM_FOCUSED` | D-pad left/right (single row; stops at edges; no wrap) |
| `ITEM_FOCUSED` → `DWELL_REVEAL` | Confirm held ≥ 400ms — input consumed; does not advance to CONFIRMING |
| `DWELL_REVEAL` → `ITEM_FOCUSED` | Confirm released OR Back/Cancel pressed |
| `ITEM_FOCUSED` → `ITEM_FOCUSED` | Confirm on "In Pack" item — brief audio tone; no state change |
| `ITEM_FOCUSED` → `CONFIRMING` | Confirm short-pressed (< 400ms) on affordable, unowned, not-in-pack item |
| `ITEM_FOCUSED` → `INSUFFICIENT_FUNDS` | Confirm short-pressed with insufficient Scraps |
| `ITEM_FOCUSED` → `ALREADY_OWNED` | Confirm short-pressed on already-purchased relic |
| `CONFIRMING` → `PURCHASING` | Second Confirm press |
| `CONFIRMING` → `ITEM_FOCUSED` | Cancel |
| `PURCHASING` → `TRANSACTION_COMPLETE` | Save write succeeds; item was a consumable |
| `PURCHASING` → `RELIC_TRANSACTION_COMPLETE` | Save write succeeds; item was an analog relic |
| `TRANSACTION_COMPLETE` → `BROWSING` | Unit 01 response completes |
| `RELIC_TRANSACTION_COMPLETE` → `BROWSING` | Unit 01 pause and relic response completes |
| `ALREADY_OWNED` → `BROWSING` | Player presses any face button after Unit 01 response |
| `BROWSING` → `SHOP_CLOSED` | Player navigates away or presses Back |

### Interactions with Other Systems

| System | Direction | Interface |
|--------|-----------|-----------|
| Save / Persistence | Bidirectional | Reads `player_scraps`, `acts_unlocked`, `relic_*_owned` on open; commits Shop purchase transactions that stage `player_scraps` + relevant flag atomically through EconomyLedger and ExpeditionInventoryLedger |
| Campaign Map | Downstream consumer + flag reset owner | Reads `expedition_field_kit`, `expedition_cache_shard`, and `expedition_emergency_patch` to drive MAP_EXPLORE node affordances; consumes and resets flags through ExpeditionInventoryLedger. **Campaign Map's Bulkhead departure handler resets all four `expedition_*` flags to `false`.** Campaign Map's defeat-return handler also resets all four flags. Campaign Map applies battle Scrap rewards through EconomyLedger using authored encounter rewards. |
| Dragon Progression | Downstream caller | Cache Shard calls `apply_xp(party[0], capped_xp)` — capped value never causes stage transition; call is skipped when `actual_xp = 0` |
| Battle Engine | Downstream consumer | Reads `expedition_defrag_patch` to offer Defrag Patch action in TELEGRAPH phase; reports use in `BattleDurableDelta`. Campaign Map or Singularity settlement clears the flag through ExpeditionInventoryLedger. Battle Engine GDD specifies the in-battle action contract. |
| Dragon Forge Hub | Embedded | Shop is a Hub station; Hub navigation routes to Shop; Hub HUD displays live `player_scraps` |
| Singularity | Downstream reader | Reads `relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned` for ending availability at Mainframe Crown. Shop is the only normal writer of these flags; Singularity must not create discounted/free Crown relics. |

### Unit 01 Voice Profile

Unit 01's dialogue lines below are implementation-ready draft lines. Writers may revise exact wording, but must preserve the **character logic** specified here. This is not a suggestion — departing from this profile undermines the Player Fantasy.

**Knowledge state**: Unit 01 can read and recite transaction records (what has been purchased, what the bearer currently carries, what items are in inventory at what price). Unit 01 cannot interpret intent, meaning, or context. Unit 01 does not remember placing the relics or being instructed to hold them. Unit 01 does not know what the relics are for.

**Register per state:**

| State | Register | What Unit 01 knows | What Unit 01 does NOT do |
|-------|----------|--------------------|--------------------------|
| TRANSACTION_COMPLETE (consumable) | Procedural confirmation — flat, neutral, transactional | Item transferred; Scraps deducted | Express warmth, satisfaction, or farewell |
| TRANSACTION_COMPLETE (Field Kit) | Same as above | Expedition supply confirmed | Note that the player might need it |
| RELIC_TRANSACTION_COMPLETE | Same register as consumable, delivered after the involuntary pause | Item transferred; Scraps deducted | Acknowledge the pause; explain the relic; speculate about its purpose |
| INSUFFICIENT_FUNDS | Statement of shortfall — no sympathy, no apology | Current balance; item price | Offer alternatives; suggest farming; express regret |
| ALREADY_OWNED | States the record fact — does not interpret the query | Bearer carries this item | Express confusion; ask why the player is asking; recognize that it matters |
| Ambient/idle | Low-frequency, low-register status outputs | Unit 01's current operational state | Establish personality; make jokes; show warmth or melancholy |

**Prohibitions (all states):**
- Unit 01 does not speculate about endings, relics' purposes, or narrative significance.
- Unit 01 does not express emotions about transactions. The relic response is distinguished by Unit 01's involuntary gesture — not by Unit 01 saying something that implies awareness.
- Unit 01 does not produce ambient lines during RELIC_TRANSACTION_COMPLETE or ALREADY_OWNED. Idle lines must be suppressed in these states.
- Unit 01 does not welcome, thank, or farewell the player. These are protocols, not interactions.

**Designer test for any Unit 01 line**: Would this line still make sense coming from a unit that does not know what a relic is for? If not, revise.

### Unit 01 Draft Line Set

| State | Line |
|---|---|
| TRANSACTION_COMPLETE (generic consumable) | "TRANSFER COMPLETE. SCRAP BALANCE UPDATED." |
| TRANSACTION_COMPLETE (Field Kit) | "FIELD KIT ALLOCATED. EXPEDITION FLAG SET." |
| TRANSACTION_COMPLETE (Defrag Patch) | "DEFRAG PATCH ALLOCATED. SINGLE USE REGISTERED." |
| TRANSACTION_COMPLETE (Cache Shard) | "CACHE SHARD ALLOCATED. TARGET INDEX: ACTIVE SLOT." |
| TRANSACTION_COMPLETE (Emergency Patch) | "EMERGENCY PATCH ALLOCATED. FIELD USE ONLY." |
| RELIC_TRANSACTION_COMPLETE (10mm Wrench) | "ANALOG TOOL RELEASED. BEARER RECORD UPDATED." |
| RELIC_TRANSACTION_COMPLETE (Diagnostic Lens) | "DIAGNOSTIC OBJECT RELEASED. BEARER RECORD UPDATED." |
| RELIC_TRANSACTION_COMPLETE (Kernel Blade) | "KERNEL OBJECT RELEASED. BEARER RECORD UPDATED." |
| INSUFFICIENT_FUNDS | "SCRAP BALANCE INSUFFICIENT. TRANSFER REFUSED." |
| ALREADY_OWNED (generic relic) | "RECORD INDICATES BEARER ALREADY CARRIES THIS OBJECT." |
| ALREADY_OWNED (10mm Wrench) | "RECORD INDICATES BEARER ALREADY CARRIES THE WRENCH." |
| ALREADY_OWNED (Diagnostic Lens) | "RECORD INDICATES BEARER ALREADY CARRIES THE LENS." |
| ALREADY_OWNED (Kernel Blade) | "RECORD INDICATES BEARER ALREADY CARRIES THE BLADE." |
| Ambient/idle 1 | "COUNTER PROTOCOL ACTIVE." |
| Ambient/idle 2 | "INVENTORY RECORDS STABLE." |
| Ambient/idle 3 | "RELEASE CONDITIONS AWAITING INPUT." |

---

## Formulas

### 1. Cache Shard XP Grant (stage-transition-safe)

```
CACHE_SHARD_BASE_XP = 100

-- Target: dragon = party[0] at the moment of use
-- Guard: item does nothing at MAX_LEVEL (apply_xp would discard the XP anyway)
if dragon.level == MAX_LEVEL:
    return

-- XP distance from current state to the start of the next stage boundary level.
-- Call xp_threshold_for(dragon.level) for the per-level XP cost rather than inlining
-- 50/80/120: if Dragon Progression tunes a stage threshold, inline constants would
-- cause silent stage crossings at the wrong level. The function call prevents drift.
-- Stage IV has no stage boundary to protect; grant full base XP immediately.
-- This branch must be evaluated AFTER the MAX_LEVEL early-return guard above.
if dragon.stage == IV:
    apply_xp(party[0], CACHE_SHARD_BASE_XP)
    return

boundary_level =
    10   if dragon.stage == I   (levels 1-9)
    25   if dragon.stage == II  (levels 10-24)
    50   if dragon.stage == III (levels 25-49)

-- Note: xp_threshold_for() returns a flat cost per level within a stage (50/80/120 for
-- Stages I/II/III respectively). All levels within a stage share the same threshold, so
-- multiplying by (boundary_level - dragon.level) correctly sums the remaining XP span.
-- If Dragon Progression introduces variable per-level costs within a stage, this formula
-- must be updated.
xp_to_boundary = (boundary_level - dragon.level) × xp_threshold_for(dragon.level) - dragon.xp

cap        = max(0, xp_to_boundary - 1)
actual_xp  = min(CACHE_SHARD_BASE_XP, cap)

-- Skip the call entirely when nothing would be granted; do NOT call apply_xp(party[0], 0)
if actual_xp > 0:
    apply_xp(party[0], actual_xp)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `CACHE_SHARD_BASE_XP` | int | 100 (constant) | Maximum XP the Cache Shard can grant before stage-boundary cap |
| `dragon.level` | int | 1–60 | Dragon's current level |
| `dragon.xp` | int | 0–(threshold−1) | Dragon's banked XP within the current level |
| `dragon.stage` | int | 1–4 | Current stage (derived from level) |
| `xp_to_boundary` | int | 1–(stage_threshold × remaining_levels) | XP needed to reach the start of the next stage boundary level from current state (Stages I–III only; Stage IV uses early return before this variable is assigned) |
| `cap` | int | 0–(xp_to_boundary−1) | Maximum safe grant; 0 means item grants nothing at this state |
| `actual_xp` | int | 0–100 | Value passed to `apply_xp`; 0 is valid (item wasted) |

**Output range:** `actual_xp` is in [0, 100]. Returns 0 (no effect) for MAX_LEVEL dragons and dragons with `dragon.xp == xp_threshold_for(dragon.level) - 1`; Stage IV dragons at levels 50–59 receive the full base XP because no stage boundary remains to protect.

**Worked examples:**

| Dragon state | xp_to_boundary | cap | actual_xp | Result |
|---|---|---|---|---|
| Level 8, XP 0 (Stage I) | (10−8)×50−0 = 100 | 99 | 99 | Advances to L9 XP 49 — does NOT enter Stage II |
| Level 9, XP 0 (Stage I) | (10−9)×50−0 = 50 | 49 | 49 | Stays at L9 XP 49 |
| Level 9, XP 49 (Stage I) | (10−9)×50−49 = 1 | 0 | 0 | No XP granted (item wasted at boundary) |
| Level 24, XP 79 (Stage II) | (25−24)×80−79 = 1 | 0 | 0 | No XP granted |
| Level 49, XP 119 (Stage III) | (50−49)×120−119 = 1 | 0 | 0 | No XP granted |
| Level 15, XP 40 (Stage II) | (25−15)×80−40 = 760 | 759 | 100 | Full 100 XP granted; normal level advancement |
| Level 60 (MAX_LEVEL) | — | — | 0 | Early-return guard fires; no call to apply_xp |

> **Known degenerate state**: When `xp_to_boundary == 1`, `cap = 0` and `actual_xp = 0`. The item is consumed but grants nothing. The UI should grey out or show a warning when the dragon is in this state.

---

### 2. Emergency Patch HP Restoration

```
EMERGENCY_PATCH_FACTOR = 0.5

-- Target: dragon = party[0] at the moment of use (MAP_EXPLORE node context — not in-battle)
target_hp = max(1, floor(dragon.max_hp × EMERGENCY_PATCH_FACTOR))

if dragon.current_hp < target_hp:
    dragon.current_hp = target_hp
-- If dragon.current_hp >= target_hp: no change
-- (expedition_emergency_patch flag is still cleared — item is consumed regardless)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `EMERGENCY_PATCH_FACTOR` | float | 0.5 (constant) | Target HP as a fraction of max HP |
| `dragon.max_hp` | int | ≥1 | Dragon's maximum HP (base HP + level scaling) |
| `dragon.current_hp` | int | 0–max_hp | Dragon's current HP at moment of use |
| `target_hp` | int | 1–max_hp | Restoration target; `max(1,...)` guard ensures minimum of 1 |

**Output range:** `dragon.current_hp` after use is in [`max(current_hp, 1)`, `max_hp`]. Never exceeds `max_hp`; never reduces current HP below its existing value.

**Worked examples:**

| max_hp | current_hp | target_hp | Result |
|--------|------------|-----------|--------|
| 110 (Fire) | 30 | 55 | Restore to 55 (+25 HP) |
| 110 (Fire) | 60 | 55 | No change (60 ≥ 55) — item consumed, 0 HP restored |
| 110 (Fire) | 110 (full) | 55 | No change — item wasted at full HP |
| 1 (edge) | 0 | max(1, floor(0.5)) = 1 | Restore to 1 |
| 1 (edge) | 1 (full) | 1 | No change |

> **Campaign Map forward contract**: Emergency Patch is a MAP_EXPLORE action (used at landmark nodes between battles, not during combat). The Campaign Map GDD must specify: (a) whether the "Use Emergency Patch" action is offered when `expedition_emergency_patch = false`, (b) whether the action is greyed when `current_hp ≥ target_hp`, and (c) whether 0-HP (fainted) dragons are valid targets at a MAP_EXPLORE node. The Shop GDD owns the formula; Campaign Map owns action availability and greying logic.

### 3. Field Kit HP Restore

```
-- Target: all dragons in party slots 0, 1, 2 (full expedition loadout)
-- Identical to REST node recovery — Campaign Map REST handler is the authoritative reference
-- Precondition: party is a fixed-length array of exactly 3 elements; empty slots hold null.
-- A party array shorter than 3 elements will throw an out-of-bounds error on party[2].
-- Campaign Map is responsible for guaranteeing this array contract.
for each dragon in [party[0], party[1], party[2]]:
    if dragon != null:
        dragon.current_hp = dragon.max_hp

-- No partial restore; no floor guard needed (max_hp is always ≥ 1)
-- Empty party slots (dragon = null) are skipped without error
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `dragon.current_hp` | int | 0–max_hp | Dragon's current HP; set to max_hp on restore |
| `dragon.max_hp` | int | ≥1 | Dragon's maximum HP (base HP + level scaling) |

**Output range:** `dragon.current_hp = dragon.max_hp` for each non-null party member. Empty slots produce no change. Never reduces HP.

**Worked examples:**

| Party state | current_hp before | current_hp after |
|---|---|---|
| slot-1: Fire L10 (max_hp 110), current 50 | 50 | 110 |
| slot-2: Water L5 (max_hp 90), fainted (0) | 0 | 90 |
| slot-3: empty (null) | — | skipped |
| All party members at full HP | all at max_hp | no change |

> **REST node cross-reference**: The Field Kit formula is explicitly identical to the Campaign Map REST node recovery. If REST node behavior changes (e.g., partial heal, exclude fainted), this formula must be updated to match or the divergence must be a deliberate design decision.

---

## Edge Cases

### EC-1: Transaction Atomicity

**EC-1.1 Save write failure during PURCHASING:** If the save write fails, the transaction rolls back by reloading from disk. `player_scraps` is restored to its pre-purchase value; the flag is not set. The PURCHASING state surfaces a brief error message before returning to BROWSING. No partial state (Scraps deducted, flag not set) is ever persisted.

**EC-1.2 Force-quit during PURCHASING:** The on-disk save is always the last completed atomic write. If the player force-quits while PURCHASING is executing, the game reloads to the pre-transaction state on next launch. The transaction either completed fully or did not happen.

---

### EC-2: Expedition Boundary

**EC-2.1 Defeat-return to Hub:** When a player is defeated mid-expedition and returns to the Hub via the defeat path, all four `expedition_*` flags reset to `false`. This is treated identically to a normal Bulkhead departure for flag purposes. The player may repurchase any consumable before re-departing.

**EC-2.2 HUB_RETURN node — used items:** A player returning via `HUB_RETURN` who has used a consumable (flag = `false`) may repurchase it. The 1/expedition cap is per-item and tracks flag state, not purchase count within an expedition.

**EC-2.3 HUB_RETURN node — unspent consumable ("In Pack"):** If a player returns via `HUB_RETURN` with a consumable still unused (flag = `true`), the Shop displays that item as **"In Pack"** — grayed out and non-purchasable. The player cannot hold two of the same consumable. This state clears only when the item is used (flag reset by the consuming system) or the next Bulkhead departure resets all flags.

**EC-2.4 Mixed in-pack state at HUB_RETURN:** A player may return with some consumables used (purchasable) and others still in pack (blocked). Each item is evaluated independently by its flag. The Shop displays a mixed state: items at normal price alongside items showing "In Pack."

---

### EC-3: Cache Shard XP Boundary

**EC-3.1 Dragon at MAX_LEVEL (level 60):** The early-return guard fires. `apply_xp` is not called. The item is consumed and `expedition_cache_shard` is set; no XP is granted. **Campaign Map must grey the "Use Cache Shard" MAP_EXPLORE action** when `party[0]` is at MAX_LEVEL, displaying a "Dragon cannot benefit" tooltip. Shop does not validate this condition at purchase time.

**EC-3.2 actual_xp = 0 (stage-boundary degenerate state):** When `cap = 0`, `actual_xp = 0`. The `apply_xp` call is **skipped entirely** — not called with 0 — to avoid triggering Resonance charge accounting or stat-update signals with a zero-value argument. The item is consumed and the flag is set. No XP is granted. **Campaign Map owns the grey-out logic for this state**: before offering the "Use Cache Shard" MAP_EXPLORE action, Campaign Map must evaluate whether `actual_xp` would be 0 (dragon is one XP from a stage boundary or at MAX_LEVEL) and grey the action with a "Dragon cannot benefit" tooltip. The Shop UI displays the item as purchasable regardless of the slot-1 dragon's XP state — Shop does not validate slot-1 occupancy or XP position.

**EC-3.3 Stage IV dragon (levels 50–59):** The Stage IV early-return branch fires before the boundary computation. `apply_xp(party[0], CACHE_SHARD_BASE_XP)` is called directly; full 100 XP is granted. The MAX_LEVEL guard above must precede this branch — Level 60 is also Stage IV, so if the MAX_LEVEL guard fires first (as coded), Level 60 correctly returns early with no XP granted. If the Stage IV branch were evaluated first, a Level 60 dragon would be passed to Dragon Progression's `apply_xp` which would silently discard it — a silent dependency the explicit branching order prevents.

**EC-3.4 Near-boundary Stage I dragon (e.g., level 8 XP 0):** `xp_to_boundary = (10 − 8) × 50 − 0 = 100`, `cap = 99`, `actual_xp = 99`. Dragon advances to Level 9 XP 49. Does NOT enter Stage II. The algebraic formula handles this case correctly.

**EC-3.5 Slot-1 dragon swapped before Cache Shard use:** The item always targets the current slot-1 dragon at the moment of use (Campaign Map node action). If the player swaps loadout at a HUB_RETURN before using the shard, the new slot-1 dragon receives the XP. No special handling required; this is expected behavior.

---

### EC-4: Emergency Patch HP Boundary

**EC-4.1 Dragon at 0 HP (fainted in a previous battle):** Emergency Patch is used at a MAP_EXPLORE node between battles. `target_hp = max(1, floor(max_hp × 0.5)) ≥ 1`. Since `0 < target_hp`, the restore fires: `dragon.current_hp = target_hp`. The Emergency Patch can revive a dragon that fainted in a prior battle. Campaign Map must not pre-filter 0-HP dragons from the MAP_EXPLORE action target — fainted dragons are valid targets.

**EC-4.2 Dragon at full HP:** `target_hp ≤ current_hp`. No change. Item consumed, `expedition_emergency_patch` cleared. 0 HP restored. Campaign Map **must** grey the action when `current_hp ≥ target_hp` to prevent waste.

**EC-4.3 Dragon with max_hp = 1:** `target_hp = max(1, floor(1 × 0.5)) = max(1, 0) = 1`. Dragon is restored to 1 HP (or unchanged if already there). The `max(1, ...)` guard ensures the target is never zero.

**EC-4.4 Dragon with current_hp exactly at target_hp:** `current_hp ≥ target_hp`. No change. Item consumed. Identical behavior to EC-4.2.

---

### EC-5: Scrap Economy Boundaries

**EC-5.1 Purchase at exact Scrap count:** If `player_scraps = item_price`, the purchase is valid. `player_scraps = 0` post-transaction. Zero is the Scrap floor; this is a legal post-purchase state.

**EC-5.2 player_scraps = 0:** All items show insufficient funds. The Shop remains accessible and browsable. Unit 01 still provides ambient responses. Nothing is purchasable.

**EC-5.3 Scraps earned while Shop is open:** Scraps cannot be earned while the Shop is open — the player must be at the Hub, not on expedition. The balance displayed is stable for the duration of a Shop session; no live-refresh mechanism is required.

---

### EC-6: Relic Visibility and Gate Transitions

**EC-6.1 acts_unlocked = {1} (Act 2 not yet entered):** Shop displays the 4-item layout (consumables only). No relics are visible. No empty slots, no locked placeholders, no visual hint that further inventory exists.

**EC-6.2 Normal Act 2 unlock (acts_unlocked contains 2):** Relics appear at the next Shop open. The check is `acts_unlocked.has(2)`. All three relics are visible in slots 5–7 at their listed prices; none marked Owned until purchased.

**EC-6.3 Corrupt save — acts_unlocked = {1, 3} (flag 2 absent):** `acts_unlocked.has(2)` returns `false`. Relics remain hidden. Intentional: the strict membership check prevents relic access based on a corrupt or gate-skipping save state. The ordinal `max(acts_unlocked) >= 2` form is not used.

**EC-6.4 All relics owned, returning player:** All three relic slots display "Owned." Consumables remain purchasable. Confirm on any owned relic triggers ALREADY_OWNED and a distinct Unit 01 response. No transaction occurs.

**EC-6.5 Act 2 gate passed between Shop visits:** The `acts_unlocked.has(2)` check runs on Shop open (save data read). Relics appear immediately the first time the player opens the Shop after passing the Act 2 gate. No separate notification or transition animation is defined — the relics simply exist on the counter when the player arrives.

**EC-6.6 Post-ending unowned relics:** If `ending_id != ""`, unowned relic slots are not purchasable. They may be hidden or shown as archived/inert memorabilia according to Singularity's ending-specific post-game presentation profile. Owned relic flags remain true and are never consumed by the ending.

---

### EC-7: State Machine Input Handling

**EC-7.1 Rapid double-confirm during PURCHASING:** PURCHASING is a locked state. Additional inputs during the save write are ignored. The state machine does not advance until TRANSACTION_COMPLETE or rollback.

**EC-7.2 Confirm on item player cannot afford:** Transition goes directly from ITEM_FOCUSED to INSUFFICIENT_FUNDS. The confirmation dialog is not shown for unaffordable items. Brief feedback fires; state returns to ITEM_FOCUSED.

**EC-7.3 Confirm on already-owned relic:** Transition goes to ALREADY_OWNED. Unit 01 delivers a distinct response (not the standard insufficient-funds line). No transaction occurs. State returns to BROWSING after the response completes — a face button press is required to dismiss (unlike INSUFFICIENT_FUNDS, which auto-dismisses). This is intentional: ALREADY_OWNED carries a narrative beat that warrants the player completing it deliberately.

**EC-7.4 Cancel in CONFIRMING:** Returns to ITEM_FOCUSED. No transaction. `player_scraps` unchanged. The projected post-purchase balance shown in the dialog is discarded.

---

### EC-8: Layout and Display States

**EC-8.1 4-item pre-Act-2 layout:** The Shop shows only the four consumables (slots 1–4). No empty slots, no locked indicators, no visual suggestion that more items exist. The counter is simply the counter.

**EC-8.2 Post-Act-2 layout with all relics purchased:** All 7 items are visible. Relics (slots 5–7) display as "Owned" and are non-purchasable. The Shop remains functional for consumable purchases.

**EC-8.3 Empty expedition party (no dragons assigned to loadout):** Cache Shard and Emergency Patch may be purchased regardless of party state. Flags are set on purchase; the consuming systems (Dragon Progression, Battle Engine) handle the no-dragon context at the moment of use. The Shop does not validate slot-1 occupancy before completing a transaction.

## Dependencies

### Upstream (Shop reads from these systems)

| System | Dependency | Interface |
|--------|-----------|-----------|
| Save / Persistence | Shop reads `player_scraps`, `acts_unlocked`, `relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned`, and all four `expedition_*` flags on open | Save data read |
| Dragon Forge Hub | Hub navigation routes to Shop; Hub HUD displays live `player_scraps` | Hub station embedding |
| Campaign Map | Campaign Map's battle-end settlement applies authored Scrap rewards through EconomyLedger — this is the primary Scrap income stream Shop depends on | EconomyLedger reward settlement |

### Downstream (these systems read what Shop writes)

| System | Dependency | Interface |
|--------|-----------|-----------|
| Save / Persistence | Shop stages `player_scraps` + one flag per transaction in a single atomic operation through EconomyLedger/ExpeditionInventoryLedger; rollback on commit failure | Atomic SaveTransaction |
| Campaign Map | Reads `expedition_field_kit` and `expedition_cache_shard` to drive MAP_EXPLORE node affordances; consumes each flag through ExpeditionInventoryLedger on use; **Campaign Map's Bulkhead departure handler resets all four `expedition_*` flags to `false`**; Campaign Map's defeat-return handler also resets all four flags | Flag read / ledger consume / ledger reset |
| Battle Engine | Reads `expedition_defrag_patch` to offer the Defrag Patch action in the TELEGRAPH phase; reports flag consumption in `BattleDurableDelta`. Campaign Map or Singularity settlement commits the flag clear. Battle Engine GDD specifies the action timing and no-status consume case. | Flag read / settlement delta |
| Dragon Progression | Cache Shard calls `apply_xp(dragon, capped_xp)` — only called when `actual_xp > 0`; never called with 0 — *forward contract: Dragon Progression GDD must confirm apply_xp is a no-op for 0 is unnecessary (call is skipped)* | Function call |
| Singularity | Reads `relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned` to determine ending availability at the Mainframe Crown | Flag read |

### Cross-GDD Contracts

| Contract | This GDD owns | Other GDD must specify |
|----------|--------------|----------------------|
| Defrag Patch in-battle action | Purchase-to-true flag settlement (Shop); effect rule: removes the currently active status effect — if no active effect exists, item consumed with no effect (Shop) | Action availability, greying when no active status effect is present, durable consumption delta, and single-slot status clearing (Battle Engine); final flag clear is committed by Campaign Map/Singularity settlement |
| Emergency Patch MAP_EXPLORE action | Formula: target_hp = max(1, floor(max_hp × 0.5)); revival permitted when current_hp = 0; used at MAP_EXPLORE nodes only | Whether a 0-HP dragon is a valid MAP_EXPLORE action target; greying when current_hp ≥ target_hp; flag clear on use (Campaign Map) |
| Field Kit HP restore | Formula: dragon.current_hp = dragon.max_hp for all party members; identical to REST node recovery | REST node behavior specification — if REST changes, Field Kit must also change or the divergence must be explicit (Campaign Map) |
| Journal / Forge Console narrative priming | Player Fantasy: relics must feel like recognition, not discovery. Relies on player having encountered a relic in lore (Captain's Log or Forge Console fragment) before Act 2 gate | Journal GDD must include at least one lore fragment referencing a relic item before the Act 2 gate point; this is a load-bearing narrative forward contract for Shop Player Fantasy |
| Cache Shard apply_xp call | Formula, boundary guard, skip-when-zero rule | `apply_xp` interface and behavior; `xp_threshold_for(level)` must be a **public** exported function returning the XP cost per level — not a private method. Both Dragon Progression GDD and implementation must list it as part of the public API (Dragon Progression) |
| Field Kit HUB_RETURN repurchase | Flag semantics: purchasable when flag = false, "In Pack" when flag = true | `HUB_RETURN` node: which systems reset flags and when (Campaign Map) |
| Relic flags at Mainframe Crown | Flags are never reset; persistence is one-way | Ending gate check uses these flags (Singularity) |
| No Crown emergency relics | Shop is the sole normal purchase writer for `relic_*_owned` flags | Singularity may read relic flags and deny zero-relic Crown access, but must not sell, discount, grant, or create relic ownership at Crown |
| Expedition flag reset ownership | Shop only sets flags to `true` on purchase; never resets them | Campaign Map owns reset of all four flags at Bulkhead departure and defeat-return. Campaign Map resets `expedition_field_kit`, `expedition_cache_shard`, `expedition_emergency_patch` on use at MAP_EXPLORE nodes. Battle Engine reports `expedition_defrag_patch` consumption from TELEGRAPH in `BattleDurableDelta`; Campaign Map or Singularity settlement commits the flag clear through ExpeditionInventoryLedger. |

## Tuning Knobs

### Item Prices

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `FIELD_KIT_PRICE` | 50 | 30–80 | Field Kit cost; primary HP-recovery expenditure per expedition |
| `DEFRAG_PATCH_PRICE` | 35 | 20–60 | Defrag Patch cost; cheapest consumable — lower bound on "quick relief" spend |
| `CACHE_SHARD_PRICE` | 50 | 30–80 | Cache Shard cost; competes with Field Kit for same price slot; increase if players skip healing |
| `EMERGENCY_PATCH_PRICE` | 45 | 25–70 | Emergency Patch cost; in-battle safety net; raise if players over-rely on it |
| `RELIC_WRENCH_PRICE` | 175 | 120–250 | Cost of the Total Restore ending relic |
| `RELIC_LENS_PRICE` | 200 | 140–275 | Cost of The Patch ending relic |
| `RELIC_BLADE_PRICE` | 225 | 160–300 | Cost of the Hardware Override ending relic |

### Economy Calibration

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `BOSS_SCRAP_BONUS` | 25 (provisional) | 10–60 | Elevated Scrap reward on BOSS nodes in Acts 3–4; primary soft-lock prevention lever |
| `HAZARD_SCRAP_BONUS` | 10 (provisional) | 5–30 | Elevated Scrap reward on major HAZARD nodes in Acts 3–4; secondary soft-lock prevention |

> **Calibration target**: Act 3 mandatory-node critical path (minimum viable run through Acts 3–4) must yield ≥200 Scraps surplus above normal consumable expenditure, ensuring the cheapest relic (175 Scraps) is reachable without dedicated farming. Provisional values (BOSS_SCRAP_BONUS = 25, HAZARD_SCRAP_BONUS = 10) are estimates; both must be validated against Campaign Map Act 3 mandatory encounter distribution data once available. See OQ-SH01.
>
> **Sink-competition design intent**: The ≥200 Scrap surplus target assumes the player has engaged in moderate Hatchery use through Acts 1–2 (estimated 20–30 pulls, ~1,000–1,500 Scraps). The design does not expect players to choose between Hatchery pulls and relic purchases — both are intended to be viable in a normal playthrough. If playtesting reveals Hatchery spending crowds out relic acquisition, BOSS_SCRAP_BONUS is the primary lever. **This assumption must be validated against Campaign Map Act 1–2 battle count and average Hatchery pull cadence data.**
>
> **Bad-luck floor**: The Scrap drop model (~10–15 per battle) has no guaranteed floor or mercy mechanic. The design accepts this variance and relies on BOSS/HAZARD bonuses as the primary soft-lock prevention. If playtesting reveals Act 3 Scrap famine (players unable to afford any relic despite normal play), adding a minimum per-battle Scrap floor (e.g., 8 Scraps guaranteed) is the preferred fix. Document this decision when Campaign Map integration data is available.

### Input Timing

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `DWELL_REVEAL_THRESHOLD` | 400 ms | 300–600 ms | Minimum Confirm hold duration before DWELL_REVEAL activates; disambiguates hold (description reveal) from short-press (purchase). Must also be exposed as a **player accessibility setting** — players with motor control differences must be able to raise this threshold or disable dwell entirely (making Confirm always short-press) |

### Formula Constants

| Knob | Default | Safe Range | Affects |
|------|---------|------------|---------|
| `CACHE_SHARD_BASE_XP` | 100 | 50–150 | Maximum XP Cache Shard can grant before the stage-boundary cap reduces it |
| `EMERGENCY_PATCH_FACTOR` | 0.5 | 0.25–0.75 | Target HP as a fraction of max HP for Emergency Patch restore |

### Ordering Constraints

1. All three relic prices must be distinct and form a meaningful cost ladder — do not set two to the same value or reverse the order without considering player expectation at the Mainframe Crown.
2. `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS` must be calibrated jointly against Hatchery pull cost (50 Scraps) and the cheapest relic price (`RELIC_WRENCH_PRICE`). The Act 3 mandatory path must yield enough surplus Scraps to afford the wrench after reasonable Hatchery spending, without requiring farming.
3. `EMERGENCY_PATCH_PRICE` must always be set **below** `FIELD_KIT_PRICE`. At extreme tuning values, an Emergency Patch (50% HP restore to party[0] only) priced above the Field Kit (full HP restore to entire party) would be dominated — no rational player buys it. The safe ranges for both items already express this ordering; do not tune them in isolation.

## Visual/Audio Requirements

### Visual

- **Unit 01 / The Kernel**: Humanoid android design — weathered chassis, soft-lit face panel, neutral posture. Eyes neither warm nor cold. Hands flat on counter. Should read as "the unit still running the protocol" — not threatening, not welcoming.
- **Shop counter / environment**: Low-lit station inset into the Hub wall. Consumables on the left side of the counter, slightly forward; relic slots on the right side, set slightly further back. Pre-Act-2, right side of counter is bare — same counter, less on it.
- **"In Pack" state**: Item slot shows a small visual indicator (closed-bag icon or similar). Grayed-out price. Not a lock — it's in the bag, not denied.
- **"Owned" state**: Relic slot shows faint glow around item with "OWNED" indicator replacing the price. Item should look *placed*, not *locked*.
- **TRANSACTION_COMPLETE**: Brief visual confirmation — item lifts from counter into player's inventory in a simple one-step animation. Unit 01's eyes track the movement.
- **RELIC_TRANSACTION_COMPLETE**: Unit 01 raises hands ~15mm from the counter surface before the relic lifts. Hands remain raised for 0.5–1.0s during the relic-specific response. Hands return to flat after the response completes. This is the only non-standard Unit 01 animation in the Shop — it should read as involuntary recognition, not deliberate ceremony. Art Director must confirm the exact lift distance and timing in the character animation spec.
- **INSUFFICIENT_FUNDS**: Item slot briefly flashes; Scrap balance display shakes once. No dramatic negative feedback — Unit 01 states the shortfall quietly.

### Audio

- **Purchase success**: Clean mechanical confirm tone — a brief chime or latch sound. Not celebratory. Unit 01 doesn't celebrate transactions.
- **"In Pack" / INSUFFICIENT_FUNDS**: Single flat tone, lower pitch than success. No buzzer.
- **ALREADY_OWNED relic**: A slightly different tone — Unit 01's response line carries this moment. The audio must not undercut the narrative beat.
- **RELIC_TRANSACTION_COMPLETE**: A tone distinct from standard purchase success — lower, sustained, not celebratory. Pairs with Unit 01's relic-specific line. The transition from RELIC_TRANSACTION_COMPLETE to BROWSING should feel like a moment that passed, not a moment that was performed.
- **Shop ambient**: Low mechanical hum from Unit 01's chassis. Subtle — the silence of a unit waiting.
- **Relic reveal (first time relics appear)**: No fanfare. They are simply there. No audio sting on first open post-Act-2.

---

## UI Requirements

### Navigation

- D-pad navigation moves focus between item slots in a single horizontal row.
- Left at slot 1 stops (no wrap). Right at the last visible slot stops (no wrap). No circular navigation.
- Pre-Act-2: 4-item layout (slots 1–4). Post-Act-2: 7-item layout (slots 1–7; consumables 1–4, relics 5–7, visually grouped).
- **Dwell-reveal**: Holding Confirm ≥ 400ms (`DWELL_REVEAL_THRESHOLD`) on a focused item activates DWELL_REVEAL — full item description is shown; no purchase is initiated. The input is consumed by the hold; releasing Confirm returns to ITEM_FOCUSED without advancing to CONFIRMING.
- **Short-press purchase**: Confirm held < 400ms on an affordable, unowned, not-in-pack item advances to CONFIRMING.
- Confirm on an unaffordable item (short-press) advances directly to INSUFFICIENT_FUNDS.
- Confirm on an "In Pack" item (short-press) produces a brief audio tone; state remains ITEM_FOCUSED.
- Cancel / Back exits to SHOP_CLOSED from BROWSING.

### Balance Display

- Live `player_scraps` balance is shown in the Hub HUD at all times while in the Hub.
- In CONFIRMING, the dialog shows the projected post-purchase balance (current balance − price).
- In ITEM_FOCUSED, the price is displayed alongside the item name. No projected balance until CONFIRMING.

### "In Pack" Display

- When `expedition_flag = true`, the item slot replaces the Scrap price with "IN PACK" (or equivalent) in a distinct color.
- The Confirm interaction is disabled for "In Pack" items — d-pad can still navigate to them, but Confirm produces a brief audio tone and no state change. No Unit 01 dialogue line fires.

### "Owned" Display (Relics)

- Purchased relics display the item name with "OWNED" replacing the price.
- Confirm on an owned relic triggers ALREADY_OWNED and Unit 01's distinct response.
- Owned relics are never removed from the display.

### Relic Transaction Visual

- **RELIC_TRANSACTION_COMPLETE**: Unit 01's hands lift from the counter surface before the relic item animates into the player's inventory. Hands return to flat after the relic-specific response completes. This animation is distinct from the standard TRANSACTION_COMPLETE item-lift animation.

### Confirmation Dialog

- Layout: item name, full item description (identical to DWELL_REVEAL text), price, current balance, projected balance, [Confirm] [Cancel] options.
- Confirm advances to PURCHASING; Cancel returns to ITEM_FOCUSED.
- Dialog does not appear for unaffordable items (state goes to INSUFFICIENT_FUNDS directly).

---

## Acceptance Criteria

### Access

**AC-SH01**: Activating the Unit 01 station in the Dragon Forge Hub opens the Shop (transitions to BROWSING state) when the player has not yet departed through the Bulkhead this expedition. Verified by: interact with Unit 01 → Shop opens → player_scraps and item list are displayed correctly.

**AC-SH02**: After Bulkhead departure, the Unit 01 station interaction prompt does not render — no activation indicator or UI element is visible at the Unit 01 station position. Verified by: depart Bulkhead → return to Dragon Forge Hub area via any path that allows Hub access → confirm no interaction prompt is displayed at the Unit 01 station. This persists until the player returns via `HUB_RETURN`, completes the expedition, or is defeated.

**AC-SH03**: At a `HUB_RETURN` node, the Unit 01 station is active. The player can: browse all items, purchase affordable unowned items, view "In Pack" for unspent consumables, and navigate to SHOP_CLOSED. All transaction and flag-read behaviors are identical to a non-expedition Hub visit.

**AC-SH04**: Shop is not accessible during battle or during Campaign Map node traversal (while moving between nodes or at a non-HUB node).

### Layout

**AC-SH05**: Before `acts_unlocked.has(2)`, the Shop displays exactly 4 items (consumables only). No empty slots, locked slots, or `???` placeholders are shown.

**AC-SH06**: After `acts_unlocked.has(2)`, the Shop displays exactly 7 items: 4 consumables and 3 relics.

**AC-SH07**: When `acts_unlocked.has(2)` is true, Shop displays the 10mm Wrench (175 Scraps), Diagnostic Lens (200 Scraps), and Kernel Blade (225 Scraps) in slots 5–7 with their correct names and prices.

**AC-SH08**: Relic gate boundary — three cases verified independently: (a) `acts_unlocked = {1}` → 4-item layout, no relics visible; (b) `acts_unlocked = {1, 2}` → 7-item layout, relics visible; (c) `acts_unlocked = {1, 3}` → 4-item layout, relics hidden (strict `has(2)` check, ordinal threshold not used).

### Transactions

**AC-SH09**: Purchasing a consumable spends the item price through EconomyLedger and stages the corresponding `expedition_*` flag to `true` through ExpeditionInventoryLedger. Atomicity verified by: complete a consumable purchase → force-quit the game during TRANSACTION_COMPLETE before the screen returns to BROWSING → relaunch → confirm `player_scraps` reflects the deduction AND the flag equals `true`. A partial state (Scraps deducted but flag not set, or flag set but Scraps unchanged) is a test failure.

**AC-SH10**: Purchasing an analog relic spends the item price through EconomyLedger and stages the corresponding `relic_*_owned` flag to `true` through the Shop purchase transaction. Atomicity verified by: complete a relic purchase → force-quit during RELIC_TRANSACTION_COMPLETE → relaunch → confirm `player_scraps` reflects the deduction AND `relic_*_owned = true`. A partial state is a test failure.

**AC-SH11**: After a successful purchase, the displayed Scrap balance equals the pre-purchase balance minus the item price (verified against save data).

**AC-SH12**: A purchase attempted with `player_scraps < item_price` is refused. `player_scraps` is unchanged. The relevant flag is not set.

**AC-SH13**: Precondition: set `relic_wrench_owned = true` via debug save fixture. With the wrench owned, press Confirm (short-press) on the 10mm Wrench slot. Verify: (a) state transitions to ALREADY_OWNED; (b) Unit 01 response line does not match the approved INSUFFICIENT_FUNDS dialogue string and audio tone differs from the INSUFFICIENT_FUNDS tone (audio sign-off required); (c) `player_scraps` is unchanged after the response; (d) pressing any face button (A/B/X/Y) returns to BROWSING. No transaction occurs.

**AC-SH14**: `player_scraps` never goes below 0 by any Shop transaction.

**AC-SH15**: A purchase with `player_scraps` exactly equal to `item_price` succeeds. `player_scraps = 0` after the transaction.

**AC-SH16**: If the save write fails during PURCHASING, the transaction rolls back. **Requires the `save_io` debug write-failure injection mechanism to be specified in the Save / Persistence GDD before this test can be executed.** Two sub-paths must be tested: (a) In-session rollback: inject write failure during PURCHASING → state returns to BROWSING with a brief error message → without relaunching, confirm `player_scraps` and flag are unchanged. (b) Force-quit path: inject write failure during PURCHASING → force-quit the game → relaunch → open Shop → confirm `player_scraps` equals the pre-purchase value and the relevant flag is not set.

### State Machine

**AC-SH17**: Short-pressing Confirm (< 400ms) on an item the player cannot afford transitions directly from ITEM_FOCUSED to INSUFFICIENT_FUNDS. The confirmation dialog is not shown. After the brief INSUFFICIENT_FUNDS feedback (item slot flash + balance shake), the state automatically returns to ITEM_FOCUSED with the same item still focused. No player input is required to dismiss INSUFFICIENT_FUNDS.

**AC-SH18**: Pressing Cancel in CONFIRMING returns to ITEM_FOCUSED. `player_scraps` is unchanged.

**AC-SH19**: During PURCHASING, all Shop navigation and action inputs (d-pad, Confirm, Cancel/Back) are ignored. The state does not advance until the save write completes or fails. Non-Shop platform inputs (e.g., system/home button) are not affected by this rule.

**AC-SH20**: TRANSACTION_COMPLETE returns to BROWSING after Unit 01's response completes.

**AC-SH21**: Back/Cancel in BROWSING returns to SHOP_CLOSED.

**AC-SH22**: Pressing Confirm on an owned relic in ITEM_FOCUSED transitions to ALREADY_OWNED — not INSUFFICIENT_FUNDS, even if the player also lacks the funds. After Unit 01's response, any button press returns to BROWSING.

### Consumable Flags and Expedition Boundary

**AC-SH23**: Campaign Map's Bulkhead departure handler resets all four `expedition_*` flags through ExpeditionInventoryLedger as part of the departure sequence, regardless of their prior state. Verified by: purchase a consumable → depart Bulkhead → open Shop → confirm item is purchasable (flag is false).

**AC-SH24**: At a `HUB_RETURN` node, a consumable with its flag = `true` (unspent) displays as "In Pack." Confirm on an "In Pack" item produces a brief audio tone and keeps the state at ITEM_FOCUSED (self-loop). No purchase dialog appears; no transaction occurs. D-pad navigation can still move focus to other items.

**AC-SH25**: At a `HUB_RETURN` node, a consumable with its flag = `false` (used or not yet purchased this expedition) is available to purchase at its listed price.

**AC-SH26**: Campaign Map's defeat-return handler resets all four `expedition_*` flags through ExpeditionInventoryLedger when the player is returned to the Hub via the defeat path. All consumables are purchasable before the next Bulkhead departure.

**AC-SH27**: The Shop only requests purchase-time `expedition_*` flag activation through ExpeditionInventoryLedger. All other changes to these flags (consuming, resetting at departure, resetting on defeat-return) are requested by Campaign Map or Singularity through source-specific ledger helpers after Battle reports any durable delta. No Shop code path resets an `expedition_*` flag.

### Relic Persistence

**AC-SH28**: Each `relic_*_owned` flag, once set to `true`, is never reset by any system (Shop, Campaign Map, Singularity, save-load).

**AC-SH29**: Reaching the Mainframe Crown does not reset any relic flag.

**AC-SH30**: A purchased relic displays as "Owned" on all subsequent Shop visits in the same and subsequent sessions.

**AC-SH31**: All three `relic_*_owned` flags survive a save-load cycle with their values intact.

**AC-SH31a**: After `ending_id != ""`, attempting to focus or confirm an unowned relic cannot enter CONFIRMING or PURCHASING. The slot is hidden or shown as archived/inert according to the ending profile, and `relic_*_owned` remains false.

### Cache Shard Formula

**AC-SH32**: Cache Shard XP is granted to the dragon at `party[0]` (index 0 of the expedition party array) at the moment the item is used at a MAP_EXPLORE node. If the player reordered the party at a preceding `HUB_RETURN`, the current `party[0]` receives the XP.

**AC-SH33**: Cache Shard used on a MAX_LEVEL (level 60) dragon: `apply_xp` is not called; `expedition_cache_shard` is set to `false` by the consuming system; no XP is added to the dragon.

**AC-SH34**: Cache Shard on a dragon exactly one XP below a stage boundary (`xp_to_boundary = 1`, `cap = 0`, `actual_xp = 0`): `apply_xp` is not called; the item is consumed; no XP is granted.

**AC-SH35**: Cache Shard on a Stage IV dragon (level 50–59): `actual_xp = 100`; full 100 XP is granted via `apply_xp`.

**AC-SH36**: Cache Shard on a Level 8, XP 0 (Stage I) dragon: `actual_xp = 99`; dragon advances to Level 9 XP 49; Stage II is NOT entered.

**AC-SH37**: No Cache Shard use causes a dragon to cross a stage boundary in a single `apply_xp` call.

**AC-SH38**: When `actual_xp = 0`, `apply_xp` is not invoked. Verified by checking that Dragon Progression signals (`stats_updated`, `stage_iv_reached`) do not fire on a zero-grant Cache Shard use.

### Emergency Patch Formula

**AC-SH39**: Emergency Patch used at a MAP_EXPLORE landmark node sets `dragon.current_hp = max(1, floor(dragon.max_hp × 0.5))` for `party[0]` when `current_hp` is below that threshold.

**AC-SH40**: Emergency Patch on a `party[0]` dragon at 0 HP (fainted from a prior battle), used at a MAP_EXPLORE node: `dragon.current_hp` is set to `max(1, floor(dragon.max_hp × 0.5))`. Verified by reading `dragon.current_hp` immediately after the action resolves — it must equal the formula output.

**AC-SH41**: Emergency Patch on a `party[0]` dragon at full HP, used at a MAP_EXPLORE node: `current_hp` is unchanged. The item is consumed (`expedition_emergency_patch` cleared to `false`).

**AC-SH42**: Emergency Patch at a MAP_EXPLORE node when `current_hp ≥ target_hp`: `current_hp` is unchanged. Item is consumed.

**AC-SH43**: Emergency Patch never reduces `current_hp` below its value before use.

**AC-SH44**: Emergency Patch on a dragon with `max_hp = 1`, used at a MAP_EXPLORE node — two sub-cases: (a) `current_hp = 0`: dragon restored to `current_hp = 1`; (b) `current_hp = 1`: no change. In both cases the item is consumed.

### Economy Boundaries

**AC-SH45**: With `player_scraps = 0`, every item in the Shop displays INSUFFICIENT_FUNDS on Confirm. No purchase is possible.

**AC-SH46**: The Scrap balance displayed in the Hub HUD matches `player_scraps` in save data. No discrepancy after any transaction.

**AC-SH47**: The Shop item catalog is fixed: 7 items with fixed names, prices, and slot positions for the lifetime of a save file. The number of items *displayed* varies by acts_unlocked gate (4 before Act 2, 7 after), but the underlying catalog never changes. No item name, price, or slot assignment changes during a session.

### Input Timing and State Machine

**AC-SH48**: Holding Confirm on a focused item for ≥ 400ms activates DWELL_REVEAL — the full item description is displayed. The hold input is consumed: releasing Confirm returns to ITEM_FOCUSED without advancing to CONFIRMING. **This AC requires automated input simulation** (GUT test injecting a precisely-timed hold event) for the boundary case. Manual proxy: holding Confirm for approximately 1 second (clearly above threshold) shows the description and releasing does not open a confirmation dialog.

**AC-SH49**: Short-pressing Confirm (< 400ms) on a focused, affordable, unowned, not-in-pack item advances to CONFIRMING. Short press must be unambiguously distinguished from DWELL_REVEAL hold (≥ 400ms). Manual proxy: a tap lasting approximately 200ms results in CONFIRMING, not DWELL_REVEAL. The precise boundary case (exactly 399ms vs. exactly 400ms) requires automated input simulation and cannot be verified manually.

**AC-SH50**: On RELIC_TRANSACTION_COMPLETE, Unit 01's hands animate upward from the counter surface before the relic item lifts. The raised-hand state is maintained for 0.5–1.0s during the relic-specific response. Hands return to flat after the response completes. The animation does not play for consumable purchases (TRANSACTION_COMPLETE).

**AC-SH51**: Emergency Patch is not available as an in-battle action during the TELEGRAPH phase. It is only available as a MAP_EXPLORE landmark node action. Verified by confirming no "Use Emergency Patch" action appears in the Battle Engine TELEGRAPH action list regardless of `expedition_emergency_patch` flag state.

**AC-SH52**: In CONFIRMING, the projected post-purchase balance displayed equals `player_scraps - item_price`. Verified by: note `player_scraps` from save data, note item price from item catalog, advance to CONFIRMING for that item, confirm the displayed projected balance equals `player_scraps - item_price`. An implementation that displays `player_scraps` unmodified, or an incorrect subtraction, is a test failure.

**AC-SH53**: D-pad left at slot 1 stops navigation — focus remains at slot 1 and does not wrap to the last visible slot. D-pad right at the last visible slot stops navigation — focus remains at the last slot and does not wrap to slot 1. Verified in both 4-item (pre-Act-2) and 7-item (post-Act-2) layouts.

**AC-SH54**: With `player_scraps = 1000` (or any value > 999), the Hub HUD displays "999+" rather than the exact integer. The underlying `player_scraps` save value is unaffected — verifying save data after this display state confirms the actual integer is stored correctly. A transaction from this state (e.g., purchasing a 50-Scrap item with player_scraps = 1000) results in `player_scraps = 950` and the HUD updates accordingly.

**AC-SH55**: During RELIC_TRANSACTION_COMPLETE, no ambient or idle Unit 01 audio line fires before the relic-specific response begins or after it completes. Verified by confirming no ambient audio event triggers between the PURCHASING→RELIC_TRANSACTION_COMPLETE transition and the return to BROWSING. Idle line suppression must also hold during ALREADY_OWNED — no ambient line fires before, during, or after Unit 01's ALREADY_OWNED response.

---

## Open Questions

**OQ-SH01** [OPEN — Tuning]: What are the correct values for `BOSS_SCRAP_BONUS` and `HAZARD_SCRAP_BONUS`? These depend on Campaign Map Act 3 mandatory encounter distribution and average Scrap earn per run. Cannot be set until Campaign Map node data is available from playtesting.

**OQ-SH02** [OPEN — Art]: Unit 01 / The Kernel visual design is not yet defined beyond prose description. Art Director must spec the android aesthetic before UI/environment work begins. Blocks Visual Requirements implementation.

**OQ-SH03** [RESOLVED — Battle Engine forward contract]: Battle Engine GDD now specifies Defrag Patch as the MVP in-battle consumable action in TELEGRAPH, including status-clear timing, flag consumption, and no-status consumption behavior. Emergency Patch remains a MAP_EXPLORE action only.

**OQ-SH04** [RESOLVED — Narrative draft]: Unit 01 draft lines are now specified in the Unit 01 Voice Profile section for standard purchase, relic purchase, INSUFFICIENT_FUNDS, ALREADY_OWNED, and ambient/idle. Senior writer may polish wording, but implementation no longer blocks on missing line coverage.
