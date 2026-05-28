# Fusion Engine

> **Status**: Approved
> **Author**: Scott + agents
> **Last Updated**: 2026-05-22
> **Implements Pillar**: Core Loop — Collect and Grow / Attachment

## Overview

Fusion Engine is the stat inheritance and evolution system governing what happens when a player places two dragons into the Anvil at the Dragon Forge Hub. Both parents are permanently consumed — the player previews the result, then makes an informed commitment they cannot undo. The resulting fused dragon inherits its element from the designated primary parent, and its base stats are derived from a weighted combination of both parents' level-1 base stats, scaled by a stability modifier: a same-element fusion gains a +25% stability bonus applied to all inherited stats, while opposing-element pairings incur an HP penalty on the fused output (all other stats are unaffected). Stability represents how cleanly the two protocols integrated at the Astraeus layer — same-element fusions cohere naturally; opposing-element pairings resist merge. The fused dragon begins at Stage I regardless of parent stages: it is a new protocol instance, and its trust must be earned again from scratch. The single exception is the Elder form — when both parents are at Stage IV, the Anvil produces an Elder instead of a standard fused dragon. An Elder carries a distinct fifth-tier combat multiplier beyond Stage IV's 1.4× and a unique visual form; the Astraeus recognizes it as a distinct protocol class, not merely a stronger dragon. From the player's perspective, Fusion is the game's highest-weight decision: sacrifice two dragons you have raised to produce a third that may be stronger than either. The emotional gravity of that choice — and the payoff when an Elder emerges — is the primary moment this system serves.

## Player Fantasy

The fantasy of the Fusion Engine is the compression of two protocols into one. The Anvil does not destroy the parent dragons. It collapses them — folds their base allocations into a third instance dense enough to carry both. They are no longer separate entities the player can fight with. They are no longer in the registry. But they are not gone in the way deletion would mean gone. They are running inside the new dragon, throttled all the way back to Stage I, waiting for that dragon to earn the trust that lets them surface again.

This is why a fused dragon begins at Stage I no matter what its parents reached. The protocol it carries is denser than a freshly-hatched egg, but the Astraeus does not let density bypass trust. Every fused dragon must walk the same road — earn the throttle off, watch its sprite change at the same thresholds, surface its inherited allocation gradually. What the player witnesses across the next ten battles is a Hatchling carrying more than a Hatchling should.

The parents' investment is not invisible. For every fusion — Elder or otherwise — the parents' actual level at compression time shapes the child's starting allocation. Parents who reached Stage IV before the Anvil contribute more than parents who did not. The difference is measurable, not cosmetic.

Felix is present at the Anvil for every fusion. He does not comment. He witnesses. His silence is part of the weight — the player does not need to be told that what is happening is significant.

A same-element fusion is the cleanest compression. Two Fire protocols fold into one without resistance — the stability bonus is the Astraeus rewarding a clean compaction. An opposing-element fusion is two protocols that disagree about what kind of process they are. They compress, but the merge leaves a fault line the new dragon carries as a wound in its HP allocation. The Anvil permits it. The Mirror Admin notices.

The Elder is what happens when the compression is not just clean but complete. When both parents have reached Stage IV in the player's hands, the Anvil does not produce a Hatchling at all. It produces an Elder — a fifth-tier form that exists because the Astraeus, for the first time in this player's run, has enough fully-allocated source material to write a protocol class beyond Stage IV. Felix has read about Elders in fragments of pre-Reset documentation. He has never seen one rendered. When the Elder emerges, Felix speaks. It is the only time he does.

The Elder does not feel like a reward. It feels like the system showing the player something it was holding in reserve.

> Designer test: A Fusion Engine feature serves this fantasy if it makes the player feel that the parents persist inside the new dragon, throttled, rather than feeling that the parents have been spent for an upgrade. If a feature makes Fusion feel like an exchange — give two dragons, receive one stronger dragon — the framing has drifted. Fusion is a compression, not a transaction. The Elder is recognition, not a reward tier.

## Detailed Design

### Core Rules

**Fusion Participants**

1. Fusion requires exactly two dragons from the player's party. The player designates one as the *primary parent* and one as the *secondary parent*.
2. Both parents are permanently removed from the player's party and registry at the moment of confirmation. This action is irreversible.
3. There is no minimum level, stage, or XP requirement. Any two party dragons are fusion-eligible.

**Child Element**

4. The fused child inherits its element from the primary parent. The secondary parent's element does not transfer. Primary/secondary designation affects element inheritance only — it does not affect stat weighting.

**Child Starting State**

5. The fused child begins at Stage I, level 1, 0 XP, `shiny = false`, `battle_charges = 0`. Regardless of what stages the parents reached, the child is a new protocol instance — trust is not inherited.

**Stat Inheritance**

6. The child's four base stats (HP, ATK, DEF, SPD) are derived from the **level-1 canonical base stats** of both parents — the values defined in the Dragon Progression GDD base stat table. The Anvil reads each protocol's core allocation, not its accumulated combat record. A Stage IV parent and a Stage I parent of the same element contribute the same canonical base value, but not the same final child stat — parent level at fusion time contributes a level bonus (Rule 7).

7. For each of the four stats, inheritance is computed in two steps:
   - **Canonical average**: `canonical_avg = floor((primary_level1_stat + secondary_level1_stat) / 2)`
   - **Level bonus**: `level_bonus = floor(avg_parent_level / MAX_LEVEL × canonical_avg × LEVEL_BONUS_MULT)`, where `avg_parent_level = floor((P1.level + P2.level) / 2)`, `MAX_LEVEL = 60`, `LEVEL_BONUS_MULT = 0.10`
   - **Result**: `child_stat = canonical_avg + level_bonus`

   At both parents level 1, `level_bonus = 0`. At both parents MAX_LEVEL, `level_bonus` contributes at most 10% of the canonical average per stat.

8. These inherited values become the child's level-1 base stats. Dragon Progression's `+3/level` scaling applies from level 2 onward using these values as the new baseline.

**Stability Modifier**

9. After stat averaging, a stability modifier is applied based on element match:

   **Same-element** (primary and secondary share the same element): Apply a +25% stability bonus to all four stats:
   `child_stat = floor(child_stat × 1.25)` *(applied as a second floor operation, after the averaging floor)*

   **Cross-element** (primary and secondary differ): Apply a −15% HP penalty to HP only. ATK, DEF, and SPD are unaffected:
   `child_hp = max(1, floor(child_hp × 0.85))`

10. The same-element bonus and cross-element penalty are mutually exclusive. Every fusion triggers exactly one.

**Shiny Status**

11. The fused child's shiny status is always `false`. Parental shiny status does not transfer. The compression writes a new protocol instance; the 1.2× allocation signal does not survive the merge.

**Elder Unlock**

12. If and only if both parents are at Stage IV (level ≥ 50) at the time of fusion, the Anvil produces an Elder rather than a standard fused child.

13. The Elder uses the identical stat inheritance formula as any other fusion, including the stability modifier. A same-element Stage IV pair produces an Elder with the +25% bonus; a cross-element Stage IV pair produces an Elder with the −15% HP penalty.

14. The Elder begins at Stage I, level 1, and progresses through all stages identically to any other dragon. When the Elder reaches Stage IV (level 50), its combat stage multiplier is `ELDER_STAGE_MULT = 1.75` rather than the standard 1.4×. This is the Elder's only mechanical distinction beyond its unique visual form.

15. The Elder carries `is_elder = true` in its data record. The Battle Engine reads this flag to apply `ELDER_STAGE_MULT` in place of the standard Stage IV multiplier.

16. Felix witnesses every fusion in silence. Felix speaks only when an Elder is produced — this is the only Anvil sequence in which he does.

### States and Transitions

| State | Description | Player Can Act |
|-------|-------------|----------------|
| IDLE | No fusion in progress. Anvil accepts input. | Yes |
| PARENT_SELECTED | One parent assigned. Awaiting second parent and primary designation. | Yes |
| PREVIEW | Both parents assigned. System computes and displays: child element, preview stats, stability classification (CLEAN / FAULT LINE), Elder flag if applicable. Player may cancel. | Yes (cancel allowed) |
| CONFIRM | Player confirms. Irreversible from this point. | No |
| RESOLVING | Stats calculated, parent records removed, child record written. Felix sequence plays (Elder: speaks; standard: silence). | No |
| COMPLETE | Child added to party. Anvil returns to IDLE. | Yes |

**Cancel window**: The player may cancel at any point before CONFIRM. Once CONFIRM is entered, the fusion cannot be interrupted or reversed.

**Data guard**: If a parent record cannot be located in save data at CONFIRM time, fusion is blocked, an error is logged, and the registry is unchanged. The Anvil returns to IDLE.

### Interactions with Other Systems

| System | Direction | Data In | Data Out |
|--------|-----------|---------|----------|
| Dragon Progression | Upstream | Level-1 canonical base stat table (HP, ATK, DEF, SPD per element) | — |
| Dragon Progression | Downstream | — | New dragon record: `{element, base_hp, base_atk, base_def, base_spd, level=1, xp=0, shiny=false, battle_charges=0, is_elder=bool}` |
| Battle Engine | Downstream | — | Exports `ELDER_STAGE_MULT = 1.75`; exports `is_elder` flag on dragon records for stage multiplier lookup |
| Save / Persistence | Downstream | — | Remove both parent records; write child record. Operations are atomic — no partial writes. |
| Dragon Forge Hub | Upstream | Primary parent ID, secondary parent ID, primary designation, confirmation signal | — |
| Dragon Forge Hub | Downstream | — | `fusion_complete(child_data)` signal; `elder_emerged(child_data)` signal (Elder only — Felix dialogue trigger) |

**Exported constants** (consumed by other systems):

| Constant | Value | Consumer |
|----------|-------|----------|
| `ELDER_STAGE_MULT` | 1.75 | Battle Engine |
| `CROSS_ELEMENT_HP_PENALTY` | 0.85 | Internal to Fusion Engine |
| `SAME_ELEMENT_STABILITY_BONUS` | 1.25 | Internal to Fusion Engine |

## Formulas

### Formula 1: Stat Inheritance (Canonical Average + Level Bonus)

Applies to all four stats independently: HP, ATK, DEF, SPD.

**Variables:**
- `P1_stat` — primary parent's level-1 canonical base stat (Dragon Progression GDD table)
- `P2_stat` — secondary parent's level-1 canonical base stat
- `P1.level` — primary parent's actual level at fusion time (1–60)
- `P2.level` — secondary parent's actual level at fusion time (1–60)
- `MAX_LEVEL` = 60
- `LEVEL_BONUS_MULT` = 0.10

```
Step 1: canonical_avg    = floor((P1_stat + P2_stat) / 2)
Step 2: avg_parent_level = floor((P1.level + P2.level) / 2)
Step 3: level_bonus      = floor(avg_parent_level / MAX_LEVEL × canonical_avg × LEVEL_BONUS_MULT)
Step 4: child_stat       = canonical_avg + level_bonus
```

*Output range:* Canonical base stats are positive integers (HP: 85–120, ATK: 22–32, DEF: 11–24, SPD: 8–32). Level bonus is non-negative: minimum 0 (both parents level 1), maximum `floor(canonical_avg × LEVEL_BONUS_MULT)` (both parents MAX_LEVEL). All outputs are positive integers; no output can be zero or negative.

*Level bonus range check:* At LEVEL_BONUS_MULT = 0.10, the bonus is at most floor(120 × 0.10) = 12 HP, floor(32 × 0.10) = 3 ATK, floor(24 × 0.10) = 2 DEF, floor(32 × 0.10) = 3 SPD — added on top of the canonical average before the stability modifier.

---

### Formula 2: Same-element Stability Bonus

Applies when `primary_element == secondary_element`. Applied to all four stats after Formula 1.

**Variables:**
- `child_stat` — Formula 1 output for each stat
- `SAME_ELEMENT_STABILITY_BONUS` = 1.25

```
child_stat = floor(child_stat × SAME_ELEMENT_STABILITY_BONUS)
```

*Two floor operations occur per stat: one in Formula 1, one here. This can produce a fractional loss of ≤1 per stat from rounding — intentional behavior.*

---

### Formula 3: Cross-element HP Penalty

Applies when `primary_element != secondary_element`. Applied to HP only after Formula 1. ATK, DEF, and SPD use Formula 1 output directly with no modification.

**Variables:**
- `child_hp` — Formula 1 output for HP
- `CROSS_ELEMENT_HP_PENALTY` = 0.85 (retain 85%)

```
child_hp = max(1, floor(child_hp × CROSS_ELEMENT_HP_PENALTY))
```

*The `max(1, ...)` guard ensures minimum 1 HP. No negative outputs are possible.*

---

### Formula 4: Elder Condition

```
is_elder = (primary_parent.level >= 50) AND (secondary_parent.level >= 50)
```

Stage IV is defined as level ≥ 50 in Dragon Progression. The level field is the authoritative check — stage enum is derived from it.

---

### Formula 5: Child Stat at Level N

Once the child's level-1 base stats are set (Formulas 1–3), Dragon Progression's standard scaling governs all future growth:

```
stat(level) = floor((inherited_base_stat + (level − 1) × 3) × shinyMult)
```

where `inherited_base_stat` is this system's output, `shinyMult = 1.0` always (fused child is never shiny), and `level` is the child's current level. This formula is owned by Dragon Progression GDD — the Fusion Engine provides `inherited_base_stat` as input.

---

### Worked Examples

**Example 1: Same-element Fire + Fire — both parents at level 50 (Stage IV Elder)**

| Step | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Canonical level-1 (Fire) | 110 / 110 | 28 / 28 | 16 / 16 | 22 / 22 |
| Formula 1 Step 1 (canonical avg) | 110 | 28 | 16 | 22 |
| Formula 1 Step 3 (level bonus, both L50) | +9 → 119 | +2 → 30 | +1 → 17 | +1 → 23 |
| Formula 2 (+25% same-element) | **148** | **37** | **21** | **28** |
| Elder check | both level ≥ 50 → `is_elder = true` | | | |

Level bonus calculation (HP): `avg_parent_level = floor((50+50)/2) = 50`; `level_bonus = floor(50/60 × 110 × 0.10) = floor(9.17) = 9`

Child: Stage I, level 1, HP 148, ATK 37, DEF 21, SPD 28, element: Fire, `is_elder = true`

At Stage IV (level 50, Formula 5): HP = floor((148 + 49×3) × 1.0) = **295**
Unfused Fire at same level: floor((110 + 49×3)) = **257** — permanent +38 HP advantage.

---

**Example 2: Cross-element Storm (primary) + Stone (secondary)**

| Step | HP | ATK | DEF | SPD |
|------|----|-----|-----|-----|
| Canonical level-1 | Storm 90 / Stone 120 | 30 / 22 | 13 / 24 | 32 / 8 |
| Formula 1 (average) | floor(210/2) = 105 | floor(52/2) = 26 | floor(37/2) = 18 | floor(40/2) = 20 |
| Formula 3 (HP penalty) | max(1, floor(105 × 0.85)) = **89** | — | — | — |

Child: Stage I, level 1, HP 89, ATK 26, DEF 18, SPD 20, element: Storm, `is_elder = false`

---

**Boundary check — minimum HP output (worst case)**

Weakest cross-element HP blend: Storm (HP 90) + Shadow (HP 85)
- Formula 1: floor((90 + 85) / 2) = floor(87.5) = **87**
- Formula 3: max(1, floor(87 × 0.85)) = max(1, floor(73.95)) = **73 HP**

73 HP is below any level-1 pure dragon's floor (Shadow's 85 is the lowest). This is intentional — the fault line wound can place the child below the weakest pure dragon. It is not zero and cannot be negative.

---

**Boundary check — maximum stat output (same-element)**

Shadow + Shadow, ATK:
- Formula 1: floor((32 + 32) / 2) = 32
- Formula 2: floor(32 × 1.25) = **40 ATK**

At level 60 (Formula 5): floor((40 + 177) × 1.0) = **217 ATK**
Unfused Shadow at level 60: floor((32 + 177)) = **209** — permanent +8 ATK advantage through max level.

---

**Elder combat output check**

Same-element Shadow + Shadow Elder — both parents at level 50 (Stage IV):
- Shadow canonical ATK: 32; `canonical_avg = 32`; `level_bonus = floor(50/60 × 32 × 0.10) = 2`; pre-stability ATK = 34
- Formula 2 (+25%): `floor(34 × 1.25) = 42` inherited ATK
- At level 50 (Formula 5): ATK = floor((42 + 49×3) × 1.0) = **189**
- Battle Engine (Stage IV Elder): 189 × `ELDER_STAGE_MULT` (1.75) × 1.5 = **496** (attack component before DEF subtraction, elemental modifier, and variance)

Unfused Shadow at Stage IV (level 50):
- ATK: floor((32 + 49×3)) = **179**
- Battle Engine: 179 × 1.4 × 1.5 = **376**

Elder delivers **+32% attack component** at level 50 over an unfused Stage IV. No new OHKO thresholds introduced beyond what Stage IV already produces.

## Edge Cases

### 1. Input Validation

**EC-FE-01: Player attempts to fuse a dragon with itself (same dragon ID in both slots)**
The Anvil must reject this. The UI should prevent selecting an already-selected dragon for the second slot. If both slots somehow receive the same dragon ID (save data inconsistency), the CONFIRM step validates that `primary_id != secondary_id` and blocks fusion.

**EC-FE-02: One or both parents are removed from the registry between PREVIEW and CONFIRM**
If a parent is not found in save data at CONFIRM time, fusion is blocked, an error is logged, and no registry changes are made. The Anvil returns to IDLE. This guards against data races (e.g., if another system somehow removes a dragon mid-Anvil flow — theoretical but must be handled defensively).

**EC-FE-03: Player has fewer than two dragons in the party**
The Anvil UI is inaccessible — the selection step should not be enterable with only one party dragon. If enforced at the UI layer, this case should not reach the Fusion Engine. If it does, the engine returns an error and performs no action.

### 2. Elder Boundary Cases

**EC-FE-04: Both parents exactly at level 50 (Stage IV minimum)**
`is_elder = true`. Level 50 is the Stage IV entry point per Dragon Progression. The Elder condition is inclusive of level 50.

**EC-FE-05: One parent at level 50, one at level 49**
`is_elder = false`. Level 49 is Stage III. The child is a standard fused dragon. No Elder is produced. No partial Elder state exists.

**EC-FE-06: Both parents at level 60 (MAX_LEVEL)**
`is_elder = true`. MAX_LEVEL satisfies level ≥ 50. This is the highest-investment Elder case and produces identical formula outputs to any other Stage IV fusion — the Elder's mechanics do not scale with the parents' exact level, only with whether they cleared Stage IV.

**EC-FE-07: Same-element pair at Stage IV — Elder + same-element bonus**
Both conditions apply: `is_elder = true` AND same-element bonus (+25%) activates. The Elder receives both. This is the highest possible output from the Fusion Engine and is intentional — it is the reward for the highest-investment path.

**EC-FE-08: Cross-element pair at Stage IV — Elder + HP penalty**
Both conditions apply: `is_elder = true` AND cross-element penalty (−15% HP) activates. The Elder carries a fault line. The player chose to produce a cross-element Elder; the wound travels with it.

### 3. Stat Calculation Edge Cases

**EC-FE-09: Odd sum in Formula 1 (floor truncation)**
When `P1_stat + P2_stat` is odd, `floor((P1 + P2) / 2)` discards the 0.5. Example: Storm HP 90 + Shadow HP 85 = 175 → floor(87.5) = 87. The child HP is 87, not 88. This is defined behavior — floor is intentional.

**EC-FE-10: Same-element bonus applied after averaging identical parents**
When both parents share the same element and identical stat values, Formula 1 produces the element's canonical base stat. Formula 2 then applies +25% to that value. The result is identical to `floor(canonical_stat × 1.25)` — no special case needed.

**EC-FE-11: Cross-element HP penalty producing a value below any pure dragon's level-1 floor**
The minimum cross-element HP output is 73 (Storm + Shadow blend with penalty). Shadow's level-1 HP is 85 — the game's lowest pure base. A fused child at 73 HP at level 1 is legal. The `max(1, ...)` guard in Formula 3 ensures no further degradation.

**EC-FE-12: SPD inheritance where both parents have identical SPD**
`floor((SPD + SPD) / 2) = SPD`. Same-element bonus applies if same-element: `floor(SPD × 1.25)`. No degenerate case — arithmetic is stable.

### 4. Shiny Edge Cases

**EC-FE-13: Both parents are shiny**
Child `shiny = false`. The compression strips the aesthetic signal regardless of parental shiny count. Two shiny parents produce a non-shiny child. This is intentional.

**EC-FE-14: One parent shiny, one not**
Child `shiny = false`. Same rule applies.

**EC-FE-15: PREVIEW displays child stats**
The PREVIEW state displays the child's base stats (Formulas 1–3) with no shiny multiplier applied. The preview is accurate — the child is never shiny.

### 5. Save and Persistence Edge Cases

**EC-FE-16: Game crash or process kill during RESOLVING**
RESOLVING uses an atomic write sequence: the child record is written to save data before either parent record is deleted. If the process terminates after the child is written but before parents are deleted, the next load detects the orphaned parent records alongside the new child and completes the deletion to reach a clean post-fusion state. If the process terminates before the child is written, both parents remain — the fusion is safely rolled back to the pre-fusion state. No save state exists where both parents are absent and no child is present. See Save / Persistence GDD for load-time detection and repair.

**EC-FE-17: Loading a save with an `is_elder = true` dragon at Stage I, II, or III**
The `is_elder` flag persists across all stages. The Elder multiplier (1.75×) only activates when the dragon is at Stage IV in combat. At earlier stages, the Elder uses standard stage multipliers (0.5×, 0.75×, 1.0×). The flag is a property of the dragon record, not of its current stage.

**EC-FE-18: Save data from before `is_elder` field existed (migration)**
Dragons loaded from an older save format without the `is_elder` field default to `is_elder = false`. A dragon cannot retroactively become an Elder. See Save / Persistence GDD for field migration rules.

### 6. UI and Flow Edge Cases

**EC-FE-19: Player cancels during PREVIEW**
Cancellation during PREVIEW discards the preview computation. No registry changes have occurred — parents remain in the party. The Anvil returns to IDLE. No data is written.

**EC-FE-20: Player swaps primary/secondary designation in PREVIEW**
The child's element changes (primary determines element). Stats do not change (50/50 weighting is symmetric). The stability classification (CLEAN / FAULT LINE) does not change — it depends on whether the two parents share an element, which is independent of which slot is designated primary. Swapping cannot make a cross-element pair same-element or vice versa. The system recomputes only the element label. The Elder check is also unaffected — it requires both parents at Stage IV, which is not a function of primary/secondary designation.

**EC-FE-21: PREVIEW stability classification vs. narrative framing**
"CLEAN" in the PREVIEW label means same-element fusion — no HP penalty. "FAULT LINE" means cross-element — HP penalty applied. These labels map directly to the stability mechanic and are not narrative text; they are system state indicators for the player.

## Dependencies

### Systems this GDD depends on (upstream)

| System | GDD | What Fusion Engine consumes |
|--------|-----|-----------------------------|
| Dragon Progression | `design/gdd/dragon-progression.md` | Level-1 canonical base stat table (HP, ATK, DEF, SPD per element); `stat(level)` scaling formula; Stage IV level threshold (50); MAX_LEVEL (60); `battle_charges` and `shiny` fields on the dragon data contract |
| Battle Engine | `design/gdd/battle-engine.md` | Stage multiplier lookup structure (Fusion Engine adds `is_elder` flag and `ELDER_STAGE_MULT` constant that Battle Engine consumes — bidirectional dependency) |
| Save / Persistence | `design/gdd/save-persistence.md` | Atomic save operation guarantees; save-repair protocol for incomplete RESOLVING writes; field migration rules for `is_elder` |
| Dragon Forge Hub | `design/gdd/dragon-forge-hub.md` | Anvil activation input (parent IDs, primary designation, confirmation signal); Felix dialogue trigger routing |

### Systems this GDD affects (downstream)

| System | GDD | What Fusion Engine exports |
|--------|-----|---------------------------|
| Battle Engine | `design/gdd/battle-engine.md` | `ELDER_STAGE_MULT = 1.75` constant; `is_elder` flag on dragon records for stage multiplier lookup |
| Dragon Forge Hub | `design/gdd/dragon-forge-hub.md` | `fusion_complete(child_data)` signal; `elder_emerged(child_data)` signal (Elder only) |
| Dragon Progression | `design/gdd/dragon-progression.md` | New dragon records with inherited `base_hp`, `base_atk`, `base_def`, `base_spd` values — these feed directly into Dragon Progression's `stat(level)` formula |

### Dragon data contract addition

The Fusion Engine adds one field to the dragon data contract defined in Dragon Progression GDD:

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `is_elder` | bool | `true` / `false` | Set at fusion time. True only if both parents were at Stage IV. Controls whether Battle Engine applies `ELDER_STAGE_MULT` instead of standard Stage IV multiplier. Persists for the dragon's lifetime. |

### Cross-GDD Contracts

The Fusion Engine's design creates three forward contracts with other GDDs that must be resolved before implementation:

**Contract 1 — Dragon Progression: per-dragon base stat fields**
Fused children receive inherited base stats (HP, ATK, DEF, SPD) computed by this GDD's Formulas 1–3. Dragon Progression's `stat(level)` formula must use these per-dragon stored values, not a canonical element-keyed lookup, for fused dragons. Dragon Progression GDD must add `base_hp`, `base_atk`, `base_def`, `base_spd` fields to the dragon data contract. Hatched dragons continue to use canonical table values; fused dragons use their stored computed values.

**Contract 2 — Dragon Progression: `is_elder` serialization**
Dragon Progression GDD must add `is_elder: bool` (default `false`) to the dragon data contract and save format. Save migration must default existing records to `false`. This GDD declares the field; Dragon Progression owns the serialization.

**Contract 3 — Battle Engine: Elder tier in stage multiplier table**
The Battle Engine's stage multiplier table currently has four tiers (0.5×/0.75×/1.0×/1.4×). A fifth tier must be added: when `is_elder = true` AND dragon is at Stage IV, the multiplier is `ELDER_STAGE_MULT = 1.75` (imported from this GDD's exported constants). Battle Engine GDD must be revised to document this branch in its damage formula and stage multiplier table.

### Exported constants

| Constant | Value | Defined in | Consumed by |
|----------|-------|------------|-------------|
| `ELDER_STAGE_MULT` | 1.75 | Fusion Engine | Battle Engine |
| `SAME_ELEMENT_STABILITY_BONUS` | 1.25 | Fusion Engine | Internal only |
| `CROSS_ELEMENT_HP_PENALTY` | 0.85 | Fusion Engine | Internal only |

## Tuning Knobs

| Knob | Current Value | Safe Range | Effect |
|------|--------------|------------|--------|
| `SAME_ELEMENT_STABILITY_BONUS` | 1.25 | 1.10 – 1.40 | Multiplier applied to all four inherited stats on same-element fusion. Lower values make same-element fusions feel less rewarding; higher values risk making same-element the only viable path. At 1.0, same-element fusion produces no bonus — cross-element is strictly worse (HP penalty with no offset). |
| `CROSS_ELEMENT_HP_PENALTY` | 0.85 (retain 85%) | 0.70 – 0.95 | HP retention multiplier for cross-element fusions. Lower values make the fault line more severe; higher values make it negligible. At 1.0, cross-element fusions carry no penalty — the system reduces to "same-element bonus only." |
| `ELDER_STAGE_MULT` | 1.75 | 1.50 – 2.00 | Combat stage multiplier for Elder dragons at Stage IV, replacing the standard 1.4×. Below 1.50, the Elder is indistinguishable from a strong Stage IV dragon in combat feel. Above 2.00, Elder starts to produce degenerate one-shot scenarios even against high-DEF opponents on neutral typing. Current value produces approximately +32% attack component advantage at level 50 vs unfused Stage IV. |
| `ELDER_LEVEL_THRESHOLD` | 50 | 40 – 55 | Minimum level both parents must reach to unlock the Elder condition. Lowering reduces investment requirement; raising past 55 approaches MAX_LEVEL (60) and makes Elder nearly exclusive to completionists. Currently aligned with Stage IV entry (Dragon Progression defines Stage IV at level 50). **Ordering constraint: must always equal or exceed the Stage IV entry level in Dragon Progression GDD.** |
| `LEVEL_BONUS_MULT` | 0.10 | 0.05 – 0.20 | Scales the level bonus in Formula 1. At 0.10, parents at MAX_LEVEL contribute at most 10% of the canonical average per stat as a bonus. Below 0.05, the level bonus is imperceptibly small and loses the "investment visible" purpose. Above 0.20, the bonus begins to rival the stability modifier in magnitude — a same-element Elder fusion of two Level-60 parents would gain ~+32% over the canonical average before Formula 2 applies, which may cause balance outliers. |

### Ordering Constraints

1. `ELDER_LEVEL_THRESHOLD` must equal or exceed the Stage IV entry level in Dragon Progression GDD (currently 50). If Dragon Progression changes the Stage IV threshold, this knob must be updated in tandem.

2. `SAME_ELEMENT_STABILITY_BONUS` should always exceed 1.0, and the net same-element advantage should exceed the net cross-element penalty in expected combat value — otherwise players have no incentive to pursue clean compressions over cross-element arbitrage. Current values (1.25 bonus, 0.85 HP retention) satisfy this constraint across all element pairings.

3. `LEVEL_BONUS_MULT` combined with `SAME_ELEMENT_STABILITY_BONUS` must not produce a same-element Elder fusion output that exceeds the Battle Engine's OHKO threshold against the highest-DEF opponent on neutral typing at Stage IV. Verify against the Battle Engine damage formula when adjusting either knob.

## Visual/Audio Requirements

### Visual

**Anvil activation sequence:**
- Parent dragons displayed side by side in the Anvil UI. Both should be visually present until the CONFIRM state is entered — the player should see what they are sacrificing.
- On CONFIRM, parent sprites animate into the Anvil (element-appropriate collapse or dissolve — art direction deferred to Dragon Forge Hub GDD).
- Child sprite appears at Stage I (Hatchling form) after RESOLVING completes. Same reveal animation used for newly hatched eggs is acceptable here — the child is new.

**Stability classification display (PREVIEW state):**
- CLEAN fusion (same-element): visual indicator should communicate harmony — matching glow, resonance effect between parent sprites. Color palette follows the shared element.
- FAULT LINE fusion (cross-element): visual indicator should communicate tension — two different element colors, slight visual interference or "static" between the parent sprites. The indicator communicates risk, not failure.

**Elder emergence:**
- The Elder's production sequence is visually distinct from a standard fusion. Specific animation requirements deferred to Dragon Forge Hub GDD. At minimum: the standard child sprite reveal is replaced by the Elder's distinct fifth-tier visual form — this is a mandatory art gate.
- Elder visual form must be distinguishable from all Stage IV sprites. The Astraeus recognizes the Elder as a distinct protocol class; the visual must communicate this without text labels. Art direction for Elder visual deferred to Art Director gate (see Acceptance Criteria).

**Stage I child label:**
- Fused child at Stage I carries no special label distinguishing it from a regular hatch visually. The "carrying more than a Hatchling should" quality is felt through stat comparison, not a visual badge.

### Audio

**Standard fusion (RESOLVING):**
- Audio event: `fusion_complete` — layered from both parents' elemental audio signatures resolving into the child's element signature. Specific cue composition deferred to Audio Director GDD.
- CLEAN fusion: resolution feels cohesive. FAULT LINE fusion: resolution includes a brief dissonant moment before settling — the fault line has an audio expression.

**Elder emergence:**
- Audio events: Both `fusion_complete` AND `elder_emerged` fire for Elder fusions. `fusion_complete` fires universally on every RESOLVING completion; `elder_emerged` fires additively for Elder fusions only. Audio Director sequences them: `fusion_complete` fires first (universal resolution cue), then `elder_emerged` fires (fifth-tier event cue). Do not suppress `fusion_complete` for Elders.
- `elder_emerged` must be distinct from `fusion_complete` — not merely a louder version of the standard cue. Composition deferred to Audio Director GDD.
- Felix's Elder dialogue fires after the `elder_emerged` cue settles — sequencing owned by Dragon Forge Hub presentation layer.

**Anvil ambient:**
- No audio requirement specific to Fusion Engine. Ambient is a Dragon Forge Hub / Audio Director concern.

## UI Requirements

### Anvil Screen Layout

**Parent slots:**
- Two parent dragon slots displayed side by side. Each slot shows: dragon sprite (at current stage/level), element icon, name, current level, current stage label.
- One slot is designated PRIMARY (element transfer) and one SECONDARY. The player can swap designation without clearing the slots.
- An empty slot must be visually distinct from a filled slot. The Anvil is not activatable until both slots are filled.

**PREVIEW panel:**
- Displayed once both slots are filled. Shows:
  - Child element (inherits from primary)
  - Child preview stats: HP, ATK, DEF at level 1 (SPD is not displayed — internal-only per Dragon Progression GDD)
  - Stability classification badge: **CLEAN** (same-element) or **FAULT LINE** (cross-element)
  - Elder flag: if both parents are Stage IV, display an **ELDER** indicator in the preview
  - Stat comparison: child preview stats shown alongside primary parent's level-1 canonical stats — communicates whether the fusion is an upgrade or a lateral move
  - Shiny sacrifice warning: if one or both parents are shiny, PREVIEW displays: "One or both parents are shiny. Shiny status will not transfer." This warning is shown in the PREVIEW panel before CONFIRM. No hard block — the player may proceed — but the warning must appear whenever a shiny parent is involved.
- Child shiny status is not shown in PREVIEW (child is never shiny — no shiny indicator needed)

**Confirmation prompt:**
- The CONFIRM step requires an explicit secondary action (e.g., hold to confirm or a two-step confirm) to prevent accidental irreversible fusions.
- PREVIEW for Stage I + Stage I parents (both at level 1) should include a note: "Both parents are at Stage I. Fusion is permanent." No hard block — the player may proceed — but the framing must not obscure the irreversibility.

### Stat Display Rules

- HP, ATK, DEF displayed in PREVIEW. SPD not shown anywhere in the Fusion Engine UI.
- Stats shown are the child's level-1 inherited values (post-stability modifier). Dragon Progression's level scaling is not previewed — the player sees where the dragon starts, not where it will be.
- If the child's preview HP is lower than the primary parent's level-1 base HP, the HP value is displayed in the fault-line color (visual treatment deferred to Art Director).

### Elder UI Requirements

- The ELDER indicator in PREVIEW must appear before the player confirms. The player must see they are producing an Elder before committing.
- The Elder indicator is not shown if only one parent is Stage IV — partial Elder conditions do not exist.
- Post-fusion, the Elder's Stage I sprite in the party is identical to a standard Stage I sprite of its element. The Elder visual distinction only manifests at Stage IV — art gate required before the Stage IV Elder sprite is implemented.

### Accessibility

- Stability classification (CLEAN / FAULT LINE) must be communicated through both color and text label — not color alone.
- The confirmation prompt for irreversible fusion must be fully navigable by gamepad (d-pad + face button) without pointer input.

## Acceptance Criteria

### Core Fusion Rules

**AC-FE01**: When the player confirms a fusion, both parent dragon records are removed from the party registry. Neither parent appears in the party roster after RESOLVING completes.

**AC-FE02**: After a successful fusion, the party contains exactly one new dragon record with the fused child's computed stats, element, and level-1 starting state.

**AC-FE03**: The fused child's element matches the primary parent's element regardless of secondary parent element.

**AC-FE04**: The fused child's level is 1 regardless of either parent's level.

**AC-FE05**: The fused child's XP is 0 regardless of either parent's XP.

**AC-FE06**: The fused child's `shiny` field is `false` regardless of whether either or both parents were shiny.

**AC-FE07**: The fused child's `battle_charges` is 0.

### Stat Inheritance — Formula 1

**AC-FE08**: Given Fire (HP 110) + Ice (HP 100), both parents at level 1 (level_bonus = 0), the pre-penalty child HP from Formula 1 = floor((110+100)/2) = **105**. (Verify at the formula boundary, before penalty application.)

**AC-FE09**: Given Storm (ATK 30) + Stone (ATK 22), both parents at level 1 (level_bonus = 0), child ATK = floor((30+22)/2) = **26**.

**AC-FE10**: Given Shadow (SPD 28) + Ice (SPD 14), both parents at level 1 (level_bonus = 0), child SPD = floor((28+14)/2) = **21**.

**AC-FE11**: Formula 1 uses level-1 canonical base stats, not parents' current leveled stats. Integration test: Storm (primary, level 50) + Stone (secondary, level 1), cross-element. `canonical_avg HP = floor((90+120)/2) = 105`; `avg_parent_level = floor((50+1)/2) = 25`; `level_bonus = floor(25/60 × 105 × 0.10) = floor(4.375) = 4`; pre-penalty HP = 109; after Formula 3: `max(1, floor(109 × 0.85)) = max(1, 92) = **92**`. If the engine incorrectly used Storm's leveled HP at level 50 instead of its canonical 90, the result will differ — this test exposes that bug.

### Same-element Stability Bonus — Formula 2

**AC-FE12**: Same-element Stone + Stone: child HP = floor(floor((120+120)/2) × 1.25) = floor(120 × 1.25) = **150**.

**AC-FE13**: Same-element Shadow + Shadow: child ATK = floor(floor((32+32)/2) × 1.25) = floor(32 × 1.25) = **40**.

**AC-FE14**: The same-element bonus applies to all four stats (HP, ATK, DEF, SPD) — not HP only.

**AC-FE15**: A same-element fusion does not apply any HP penalty. Only Formula 2 activates.

### Cross-element HP Penalty — Formula 3

**AC-FE16**: Cross-element Storm (HP 90) + Shadow (HP 85): child HP = max(1, floor(floor((90+85)/2) × 0.85)) = max(1, floor(87 × 0.85)) = max(1, 73) = **73**.

**AC-FE17**: Cross-element Fire (HP 110) + Ice (HP 100): child HP = max(1, floor(105 × 0.85)) = max(1, floor(89.25)) = **89**.

**AC-FE18**: The cross-element penalty applies to HP only. ATK, DEF, and SPD from Formula 1 are unmodified by Formula 3. Verify ATK and DEF are identical pre- and post-penalty for a cross-element pair.

**AC-FE19**: A cross-element fusion does not apply the same-element bonus. Only Formula 3 activates.

**AC-FE20**: The `max(1, ...)` guard ensures child HP is never 0 or negative. Test with the minimum-HP pairing (Storm HP 90 + Shadow HP 85): output is 73, not 0.

### Elder Condition — Formula 4

**AC-FE21**: When both parents are at level 50, the fused child's `is_elder = true`.

**AC-FE22**: When one parent is at level 50 and the other at level 49, the fused child's `is_elder = false`.

**AC-FE23**: When both parents are at level 1, `is_elder = false`.

**AC-FE24**: When both parents are at MAX_LEVEL (60), `is_elder = true`.

**AC-FE25**: A same-element Stage IV pair produces `is_elder = true` AND Formula 2 applies (both conditions active simultaneously). Numeric anchor: Fire + Fire, both level 50 → HP 148, ATK 37, DEF 21, SPD 28, `is_elder = true`.

**AC-FE26**: A cross-element Stage IV pair produces `is_elder = true` AND Formula 3 applies (HP penalty present on the Elder).

### Elder Combat Multiplier

**AC-FE27**: An Elder dragon at Stage IV uses `ELDER_STAGE_MULT = 1.75` in the Battle Engine stage multiplier — not the standard 1.4×.

**AC-FE28**: An Elder dragon at Stage I uses 0.5×. At Stage II: 0.75×. At Stage III: 1.0×. The `is_elder` flag does not modify stage multipliers below Stage IV.

**AC-FE29**: *(Code review gate, not QA criterion)* The Battle Engine reads `ELDER_STAGE_MULT` from the Fusion Engine's exported constant — no hardcoded 1.75 literal in the Battle Engine source. Verify during implementation code review; not independently testable by a QA tester without source access.

### Formula 5 — Child Stat Scaling

**AC-FE30**: Same-element Fire + Fire Elder child, both parents at level 50 (inherited HP 148) at level 50: HP = floor((148 + 49×3) × 1.0) = **295**.

**AC-FE31**: Cross-element Storm/Stone child (inherited HP 89) at level 10: HP = floor((89 + 9×3) × 1.0) = **116**.

### Anvil State Transitions

**AC-FE32**: The Anvil cannot enter PREVIEW state with fewer than two parent dragons assigned.

**AC-FE33**: Cancellation during PREVIEW leaves both parents in the party. No registry changes are made. Save data is unmodified.

**AC-FE34**: After CONFIRM, the player cannot cancel the fusion. The system proceeds to RESOLVING regardless of input.

**AC-FE35**: After COMPLETE, both parent dragons are absent from the party and the child dragon is present.

**AC-FE36**: Swapping PRIMARY/SECONDARY designation in PREVIEW changes the child's element label but does not change the stat preview values (50/50 weighting is symmetric).

### Data Integrity

**AC-FE37**: If a parent record is not found in save data at CONFIRM time, fusion is blocked, an error is logged, no registry changes are made, and the Anvil returns to IDLE.

**AC-FE38**: Fusing a dragon with itself (same dragon ID in both slots) is rejected. No registry changes are made.

**AC-FE39**: After successful fusion, the save file contains the child record and both parent records are absent. The atomic write order (child written before parents deleted) guarantees that no save state exists where both parents are absent and no child is present — verify by inspecting save file contents at each write step during integration testing.

**AC-FE40**: A save file loaded after a fusion round-trips correctly: child `is_elder`, `base_hp`, `base_atk`, `base_def`, `base_spd`, `level`, `xp`, `shiny`, and `battle_charges` all match values at the time of fusion.

### Migration

**AC-FE42**: Dragon records loaded from a save format predating the `is_elder` field have `is_elder` default to `false`. No existing dragon becomes an Elder on migration.

### UI

**AC-FE43**: PREVIEW displays HP, ATK, and DEF at level 1 for the child. SPD is not shown in any Fusion Engine UI state.

**AC-FE44**: PREVIEW displays "CLEAN" for same-element fusions and "FAULT LINE" for cross-element fusions. Classification is communicated via both text label and visual indicator — not color alone.

**AC-FE45**: The ELDER indicator appears in PREVIEW when and only when both parents are at level ≥ 50. It does not appear when one parent is at level 49.

**AC-FE46**: CONFIRM requires a secondary action beyond a single button press (hold or two-step). A single unintentional input cannot trigger confirmation.

**AC-FE47**: When both parents are at level 1, PREVIEW displays: "Both parents are at Stage I. Fusion is permanent."

**AC-FE48**: The Anvil UI is fully navigable by gamepad (d-pad + face button) with no pointer input required.

**AC-FE49**: When child preview HP is lower than the primary parent's level-1 canonical base HP, the HP display uses the fault-line color treatment.

### Visual / Audio

**AC-FE50**: The `fusion_complete` audio event fires on every successful RESOLVING completion.

**AC-FE51**: The `elder_emerged` audio event fires on RESOLVING completion when `is_elder = true`. It does not fire for standard fusions.

**AC-FE52**: Felix's Elder dialogue fires after `elder_emerged`. Felix does not speak during any standard fusion sequence.

**AC-FE53**: The Elder's Stage IV sprite is visually distinct from all standard Stage IV element sprites of the same element. **[Art Director gate — blocked until Elder Stage IV art is delivered.]**

### Level Bonus

**AC-FE54**: Given Fire + Fire, both parents at level 60 (MAX_LEVEL): `level_bonus HP = floor(60/60 × 110 × 0.10) = floor(11) = 11`; pre-stability HP = 121; after Formula 2: `floor(121 × 1.25) = 151`. Given Fire + Fire, both parents at level 1: `level_bonus HP = 0`; pre-stability HP = 110; after Formula 2: `floor(110 × 1.25) = 137`. Verify that the level 60 output (151) strictly exceeds the level 1 output (137) — the level bonus is measurably observable.

### PREVIEW Display

**AC-FE55**: PREVIEW displays child stats alongside the primary parent's level-1 canonical stats for all three displayed stats (HP, ATK, DEF). A player can read directly from the PREVIEW whether the fusion output is numerically higher, equal, or lower than the primary parent's canonical base.

**AC-FE56**: When one or both parents are shiny, PREVIEW displays: "One or both parents are shiny. Shiny status will not transfer." This warning appears before CONFIRM and is not suppressible. When neither parent is shiny, no shiny warning appears.

### Elder Signal Coverage

**AC-FE57**: When an Elder fusion completes (RESOLVING), both `fusion_complete` and `elder_emerged` signals fire. For a standard (non-Elder) fusion, `fusion_complete` fires and `elder_emerged` does not fire. Verify signal firing order: `fusion_complete` fires before `elder_emerged`.

## Open Questions

**OQ-FE01 — Mirror Admin signal (unresolved)**
The Player Fantasy states "The Anvil permits it. The Mirror Admin notices" regarding cross-element fusions. Does opposing-element fusion — or Elder emergence — emit a signal that the Mirror Admin system responds to mechanically? Verify with `design/gdd/mirror-admin.md` whether this interaction is already specified. If not, determine whether it belongs in this GDD, the Mirror Admin GDD, or as a narrative-only beat handled through Felix's silence.

**OQ-FE02 — Inventory limit interaction (unresolved)**
The game has no currently specified party size cap. If a party cap is introduced, a player at cap cannot receive a fused child — but both parents have already been consumed at CONFIRM. Define the policy: does fusion confirm only succeed if the post-fusion party size is within cap? Or does fusion temporarily allow over-cap to deliver the child? See Save / Persistence GDD for inventory scope.

**OQ-FE03 — Dragon Progression GDD note correction (deferred)**
The Dragon Progression GDD contains the note "Stone remains competitive at Stage IV." Boundary analysis during Fusion Engine design found that a level-60 Shadow OHKOs a level-60 Stone at neutral typing (339 damage vs 297 HP), contradicting this note. A Dragon Progression revision pass should correct it — not a Fusion Engine issue, flagged here as the discovering document.

**OQ-FE04 — Elder lore fragment unlock (unresolved)**
The Journal / Console GDD specifies 7 lore fragments with flag/stat unlock conditions. Does Elder emergence (`elder_emerged` signal) trigger one of these fragments? If so, the Journal GDD should list `elder_emerged` as a flag condition. If not, confirm that the Elder sequence is fully handled by Felix's dialogue with no Journal entry.
