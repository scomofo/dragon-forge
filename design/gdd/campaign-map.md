# Campaign Map

> **Status**: Approved
> **Author**: Skye / Claude Code agents
> **Last Updated**: 2026-05-24 (revision 5 — 2 blockers + 5 recommended revisions addressed: AC-CM15c corrected — expedition_field_kit NOT reset at HUB_RETURN, persists until Bulkhead departure (B1); FREE_ROAM uncleared BOSS nodes now show Replay? prompt — Rule 22 + AC-CM48 updated (B2); mid-expedition loadout screen roster clarification (R1); scar_nodes[] ownership added to Cross-GDD Contracts as Singularity forward contract (R2); Field Kit greying rule added to Rule 9a + AC-CM15d (R3); current_act/acts_unlocked naming noted as nice-to-have.)
> **Implements Pillar**: Explore

## Overview

The Campaign Map is Dragon Forge's progression spine: a fixed directed graph of 40+ named landmarks spanning four acts, from Village Edge to the Mainframe Crown. Each act corresponds to a distinct biome of the Rendered World's hardware bleed-through — jungle day, tundra edge, volcanic, and aurora — with the Hub's Bulkhead view silently updating to reflect the player's current act. Players move between landmarks via d-pad input, triggering curated encounters, navigating terrain hazards, collecting lore fragments, and clearing progression gates that require minimum dragon stage or collected element counts. The map also owns three critical cross-system contracts: the loadout rules governing how many dragons a player may bring per expedition, the zone-level boundaries that gate entry to high-level areas (preventing uncapped XP farming), and the HP recovery model between encounters. Reaching the Mainframe Crown unlocks the Singularity endgame arc; collecting all six elemental dragons stabilizes the Elemental Matrix and enables the final approach. Post-game, the map remains fully navigable in READ_ONLY_FREE_ROAM.

## Player Fantasy

The Campaign Map is where the Rendered World stops hiding.

The player enters as a handler — someone with a dragon, a destination, and a set of credentials she doesn't fully understand. She walks the map the way a field researcher walks a site: forward, careful, taking notes. The pastoral surface is real enough: jungle-thick buffer zones, salt flats that remember being plains, mountain peaks that look like peaks. She is allowed to believe in them for a while.

The belief erodes landmark by landmark. Not all at once — the map is honest in the way a dying machine is honest, in increments. The wheat field has wireframe seams. The "wind" at the Tundra of Silicon is fan exhaust. The snow is silicon wafer fragments, and the server rack she labeled "Frostspire" in her notes has frost on its heatsinks that the game never explains. She just walked in and saw it.

**The player should feel like they are reading the world's last pages.** Each act is a chapter they cannot un-read. Moving between landmarks is irreversible in tone even if the system permits backtracking — the feeling is that of a witness who can face forward or face backward, but cannot face away. The dragons are the only beings who can see what she sees and still walk with her anyway.

**Structural beats:**
- *The Firewall Gate (Act 1 → Act 2):* The d-pad press that changes the Bulkhead view forever. The map says "permission elevated." Skye didn't ask for this clearance. She had it.
- *The Village Edge return (mid-Act 1):* An optional discovery. The player walks back to the start and finds a villager sprite labeled "process suspended." Not deleted. Waiting. They leave and don't return.

**Designer test:** A landmark that is only an obstacle has failed. A landmark that the player remembers has earned its place.

## Detailed Design

### Core Rules

**Map Structure**
1. The Campaign Map is a stylized top-down 16-bit overworld. The player sees a pixelated overhead view; the player avatar (or dragon token) moves visibly between nodes along path connections.
2. The map is a **fixed directed node graph**: approximately 40–46 named landmarks across four acts, arranged with a primary forward path and optional side branches. Each node has 1–4 connections. Node connections correspond to cardinal d-pad directions (the adjacent node in a given direction is consistent with map geography).
3. Pressing d-pad toward a connected node moves the player to that node. Pressing d-pad in a direction with no connection is silently ignored.
4. The player may navigate backward freely. All acts remain accessible after first entry.
5. The player's current position is saved as `current_node_id` in save data. On load, the player resumes at that node.

**Landmark Types**
Each node has a `type` field that determines its behavior on player arrival:

| Type | Description |
|------|-------------|
| `COMBAT` | **First visit:** Battle begins automatically on arrival. Node data includes `enemy_element` and `enemy_level`. Battle resolves via Battle Engine. On victory, HP carries forward (no automatic restore). On defeat, see defeat rule (Rule 13). Node is added to `cleared_combat_nodes[]` on first victory. **Subsequent visits:** "Replay?" prompt shown (identical to cleared BOSS behavior) — player selects Yes to re-fight, No to remain at node. |
| `LORE` | No battle. Triggers a Captain's Log fragment unlock if the player meets the flag condition. Skippable — revisiting a cleared LORE node does nothing. |
| `GATE` | Act-boundary check node. Evaluates active dragon's stage against the act gate requirement. On pass: node transitions to traversable (one-time). On fail: in-world denial message appears ("Firewall Gate — [authentication reason]"). |
| `HUB_RETURN` | The Bulkhead node. Transitioning here opens the loadout screen and returns to the Hub. One exists per map. |
| `BOSS` | Multi-phase battle. Singularity-flagged bosses use Singularity-owned defeated flags and corruption settlement. Generic non-Singularity bosses use Campaign Map replay state. Does not heal active dragon between phases unless the owning boss system explicitly performs a pre-encounter restore. On defeat: return to the last non-BOSS node before the boss. |
| `CROWN` | Singularity ending node. Does not trigger Battle Engine. On arrival, enters the Crown flow owned by Singularity; after `ending_id != ""`, opens post-game terminal content. |
| `REST` | No encounter. Flavor/environmental — Weaver's Cache, Submerged Data Cache, dead-end vistas. No mechanical action required. |
| `HAZARD` | A COMBAT node modified by the current corruption class (see Corruption Hazards). Enemy gains a status effect or buff at class WARNING+. |

**Party Loadout and Dragon Management**
6. At the Bulkhead, the player selects 1–3 dragons for the expedition (slot 1 = active in battle, slots 2–3 = benched).
7. The player may freely swap which dragon occupies slot 1 at any landmark node, except during battle. Swapping costs nothing. **Swaps are limited to the 3 dragons loaded at expedition start (Bulkhead departure) — no dragon from the full roster outside the current expedition party may be added mid-expedition.** The loadout screen in mid-expedition mode shows only the 3 expedition slots; the full roster browser is not accessible until the player returns to the Hub.
8. **HP recovery:** All dragons in the loadout (slot 1 and benched) restore to full HP upon the player arriving at a **REST** node. HP does **not** automatically restore at COMBAT, LORE, GATE, HUB_RETURN, BOSS, or HAZARD nodes — HP carries forward between these nodes. Recovery at a REST node applies on arrival, before any other state is evaluated.
9. **Benched dragons:** Dragons occupying slots 2–3 are inactive. They do **not** earn XP during an expedition — only the slot-1 dragon earns XP through battle. Benched dragons **do** earn **+1 Resonance charge per expedition battle** fought by the slot-1 dragon (whether that battle is a win or a loss — the benched dragon witnesses the full encounter regardless of outcome). This Resonance accumulation is the catch-up mechanism described in dragon-progression.md: a player who rotates their roster can develop a secondary dragon more efficiently by benching it on expeditions where another dragon fights. The Loadout screen does not show XP counters for benched slots (they earn none), but does display their current Resonance charge count. *(Design rationale: XP is earned with what you fight — the bond deepens through shared danger. Resonance is earned through proximity and witness: a dragon that walks with you and watches every battle is changed by it, even if it did not strike a blow. This preserves the "earn with what you fight" principle for XP while honoring the Dragon Progression GDD's roster-rotation intent.)*

9a. **Field Kit (HP recovery consumable):** A shop-purchasable single-use item. At any landmark node in MAP_EXPLORE, the player may use their Field Kit to restore all loadout dragons (slots 1–3) to full HP — identical to REST node recovery. Each expedition may carry at most 1 Field Kit; it must be purchased at the Shop before departing from the Bulkhead. Using the Field Kit sets `expedition_field_kit = false` in save data. An expedition may begin with 0 Field Kits if the player chooses not to purchase one. Field Kit price: `FIELD_KIT_PRICE` Data Scraps (see Tuning Knobs). **Campaign Map must grey/disable the "Use Field Kit" MAP_EXPLORE action when all loadout dragons in slots 1–3 are already at their maximum HP** (`dragon.current_hp == dragon.max_hp` for all non-null party slots) — consistent with Emergency Patch and Cache Shard grey-out rules. The item is still purchasable at the Shop; Campaign Map evaluates the condition at the moment the action is presented. *(Forward contract to shop.md: the Shop must stock Field Kit as a purchasable item with price `FIELD_KIT_PRICE`. The Shop GDD owns pricing display and inventory UI; Campaign Map owns the use rule.)* *(Design rationale: COMBAT nodes auto-trigger — the player cannot avoid the encounter. The Field Kit gives the player an active HP management tool, making defeat attributable to genuine player error or calculated risk rather than unavoidable HP attrition. This preserves the XP defeat penalty as meaningful stakes without punishing the player for the deterministic structure of auto-trigger combat.)*

9b. **Cache Shard (XP consumable):** A shop-purchasable single-use item. At any landmark node in MAP_EXPLORE, the player may use the Cache Shard on the current slot-1 dragon. Campaign Map evaluates the Shop-owned Cache Shard formula at presentation time. If `party[0]` is at MAX_LEVEL or the formula would produce `actual_xp = 0`, the "Use Cache Shard" action is greyed/disabled with "Dragon cannot benefit"; the item remains in pack. On valid use, Campaign Map calls Dragon Progression `apply_xp(party[0], actual_xp)` and sets `expedition_cache_shard = false`.

9c. **Emergency Patch (single-dragon HP consumable):** A shop-purchasable single-use item. At any landmark node in MAP_EXPLORE, the player may use the Emergency Patch on the current slot-1 dragon. The action is enabled only when `party[0].current_hp < max(1, floor(party[0].max_hp × EMERGENCY_PATCH_FACTOR))`. On use, Campaign Map restores `party[0].current_hp` to that threshold and sets `expedition_emergency_patch = false`. It can revive a 0-HP slot-1 dragon between battles, but cannot be used during battle.

9d. **Expedition flag reset:** Campaign Map resets all four `expedition_*` item flags (`expedition_field_kit`, `expedition_defrag_patch`, `expedition_cache_shard`, `expedition_emergency_patch`) to `false` on Bulkhead departure and on defeat-return. Field Kit, Cache Shard, and Emergency Patch are consumed by Campaign Map in MAP_EXPLORE. Defrag Patch is consumed by Battle Engine in TELEGRAPH.

**Defeat Penalty Calibration Note:** The `XP_DEFEAT_PENALTY` (50%) is applied to `expedition_xp_earned`, then deducted from `dragon.xp` (within-level XP only). Any XP already consumed by level-ups during the expedition is permanently preserved — the penalty cannot cause de-leveling (see Rule 13). In practice, the effective maximum loss is bounded by the dragon's `dragon.xp` at time of defeat: a dragon that leveled up recently has low within-level XP, so the actual loss is often less than one level's cost. The Field Kit prevents the worst-case scenario where HP attrition through auto-trigger COMBAT chains leads to an unavoidable defeat that wastes accumulated progress.

**Zone Gating**
10. Act boundaries are enforced by GATE nodes. The gate requirement is evaluated at the moment the player attempts to cross into a new act. Once passed, the gate is marked `unlocked` in save data and is never re-evaluated.

| Act | Enemy Level Range | Gate Requirement | In-World Framing |
|-----|------------------|-----------------|-----------------|
| Act 1 | 1–15 | None (open) | — |
| Act 2 | 10–25 | Active dragon Stage II (level ≥ 10) | "Firewall Gate reads protocol signature — Hatchling allocation insufficient." |
| Act 3 | 20–40 | Active dragon Stage III (level ≥ 25) | "Mirror Admin Gate: full territorial allocation required." |
| Act 4 | 35–55 | `matrix_stabilized = true` (all 6 elements collected) | "Spine Access: minimum load-bearing allocation acknowledged." |

11. If the player's active dragon does not meet the stage requirement, the GATE node displays its denial message and blocks movement. The player must backtrack, swap dragons, or level up.
12. Gate unlock is permanent in save data — a player who entered Act 2 with a Stage II dragon can return to Act 1 and re-enter Act 2 without re-checking stage.

**Defeat**
13. If the player's active dragon's HP reaches 0 in battle, the battle ends in defeat. The player is returned to `previous_node_id` (the last non-BOSS node visited before the battle). All loadout dragons restore to full HP. **50% of `expedition_xp_earned` is deducted from the slot-1 dragon's stored XP** (rounded down; dragon XP floor is 0; `expedition_xp_earned` then resets to 0). **The deduction cannot cause de-leveling**: if the penalty would bring `dragon.xp` below 0, it is set to 0 and the dragon retains its current level. A dragon at Level 12 XP 10 that receives an 82 XP penalty ends at Level 12 XP 0, not Level 11. Any XP already consumed by level-ups during the expedition is permanently preserved. No Data Scraps are lost. *(Design rationale: COMBAT nodes auto-trigger — the player has no choice but to fight, so Scrap loss would punish unavoidable encounters. However, defeat must carry systemic weight to make combat feel meaningful. The XP penalty creates real stakes: time invested in the expedition is partially forfeit, and the player must fight their way back to where they were. Data Scraps are preserved because the player could not choose to avoid the encounter.)*
14. BOSS defeat exception: the player returns to the last non-BOSS node before the boss entry.
14a. **`previous_node_id` initialization and update rule:** At the start of every expedition, `previous_node_id` is initialized to the `node_id` of the HUB_RETURN node (Bulkhead). `previous_node_id` is updated when the player **departs** from a node — specifically, when the MAP_EXPLORE → MAP_TRAVEL transition fires (d-pad pressed toward a connected node), `previous_node_id` is set to the **current node's `node_id`** before travel begins, **unless the destination node is a BOSS node** (in which case `previous_node_id` retains its last value). This departure-based update ensures that defeating the player at a COMBAT node that auto-triggers on arrival returns them to the node they came FROM, not the COMBAT node itself (which would re-trigger the battle). Defeat recovery to the HUB_RETURN node does NOT auto-trigger the Hub transition — the player lands in MAP_EXPLORE at that node and must press Confirm normally.
14c. **`previous_node_id` update rule (summary):** Updated on departure from the current node toward a non-BOSS destination. Never updated when the destination is a BOSS node. Initialized to HUB_RETURN node_id at expedition start. See Rule 14a for full specification. This rule belongs in Detailed Rules (not just in the ACs) because implementers may work from this section without reading the AC set.

14b. **`expedition_xp_earned` tracking:** An integer session value (`expedition_xp_earned`) is initialized to 0 at expedition start (Bulkhead departure). It increments by `xp_earned` after every COMBAT or HAZARD battle victory. On defeat: `dragon.xp -= floor(expedition_xp_earned × 0.5)`; `expedition_xp_earned` resets to 0. On hub return: `expedition_xp_earned` resets to 0. `expedition_xp_earned` is included in save data so a save/load mid-expedition preserves the pending penalty pool.

**NPC Enemy Level**
15. Each COMBAT and HAZARD node has a hardcoded `enemy_level` in its node data. Enemy levels are authored per-node within the act's level range. The XP earned per battle uses the Battle Engine canonical formula: `max(1, floor(base_xp × float(enemy_level) / float(player_dragon_level)))`.
16. Act-level ranges serve as authoring guidelines. Individual nodes may fall at the low or high end of their act's range to create pacing variation.
17. **Path-level authoring constraint**: Within any act, higher-`enemy_level` COMBAT nodes must not be reachable before the player has encountered lower-`enemy_level` COMBAT nodes that precede them on the critical path. No shortcut within an act may connect the act's entry point directly to the act's highest-level nodes. This constraint is a **Level Designer authoring guideline enforced by graph validation tooling**, not by runtime game code. The over-leveling XP decay (Formula 1) discourages *backtracking by overleveled players*; it does not prevent *underleveled players from accessing high-level nodes via side branches*. Both safeguards are necessary; neither replaces the other.

**Matrix Stabilization**
18. `matrix_stabilized` is a one-way boolean flag in save data, default `false`.
19. The flag is evaluated on every dragon acquisition event (Hatchery pull, fusion completion). Condition: the player's roster contains at least one dragon of each of the six core elements (Fire, Ice, Storm, Stone, Venom, Shadow).
20. Once `matrix_stabilized` becomes `true`, it cannot be reset. Fusion consuming an element dragon does not revert the flag if it was already set.
21. When the flag transitions to `true`, the `matrix_stabilized()` signal is emitted. The Act 3→4 Spine Access gate becomes permanently traversable — no further re-evaluation occurs. The Singularity system also listens to this signal for its own endgame logic.

**Node Interaction Model**
22. The following table defines whether each node type activates automatically on player arrival or requires explicit player confirmation (Confirm button):

| Node Type | On Arrival | Requires Confirm? |
|-----------|-----------|-------------------|
| COMBAT (uncleared — not in `cleared_combat_nodes[]`) | Battle begins automatically | No |
| COMBAT (cleared — in `cleared_combat_nodes[]`) | "Replay?" prompt shown | Yes |
| HAZARD (uncleared) | Battle begins automatically | No |
| HAZARD (cleared) | "Replay?" prompt shown | Yes |
| BOSS (uncleared) | MAP_BOSS_TRANSITION state: sigil screen 2s, then battle | No |
| BOSS (cleared) | "Replay?" prompt shown | Yes |
| CROWN | Singularity Crown flow or post-game terminal | Confirm/cancel inside Crown UI |
| LORE (first visit — not in `visited_nodes[]`) | Captain's Log fragment auto-displays | No |
| LORE (revisit — in `visited_nodes[]`) | No event | No |
| GATE (unlocked) | Player passes through | No |
| GATE (locked) | MAP_GATE_DENIED fires, denial message shown | Confirm to dismiss |
| REST | No event; HP recovery fires for all loadout dragons | No |
| HUB_RETURN | Loadout screen opens | Yes (Confirm to activate) |

> **READ_ONLY_FREE_ROAM exception:** In `MAP_FREE_ROAM` state, all COMBAT, HAZARD, and BOSS nodes — whether cleared or uncleared — show a "Replay?" prompt before any battle begins. Nothing auto-triggers in FREE_ROAM. Mirror Admin node shows terminal readout instead of a Replay? prompt (see Rule 28).
> **CROWN exception:** CROWN nodes never show a Replay? prompt and never enter MAP_BOSS_TRANSITION. They route directly to Singularity's Crown flow, or to post-game terminal content after `ending_id` is set.

**Corruption Hazards**
23. The global corruption class (NOMINAL / ANOMALY / WARNING / ALERT / CRITICAL / BREACH) is owned and progressed by the Singularity GDD. Campaign Map reads the current class from save data on each map scene load.
24. Per-landmark effects by corruption class:

| Class | Campaign Map Effect |
|-------|-------------------|
| NOMINAL | No map effects. |
| ANOMALY | HAZARD nodes become visible on the overworld (distinct icon). |
| WARNING | HAZARD node battles: enemy gains a status effect at battle start (element-appropriate per node data). |
| ALERT | Threadfall Scars appear — select REST and LORE nodes become `SCAR` type: visually degraded, traversable, no encounter or content. |
| CRITICAL | Corruption-class visual filter applied to overworld rendering. |
| BREACH | Maximum degradation: Acts 1–2 aesthetics overridden with hardware-substrate render. SCAR node count increases. |

**Post-Game (READ_ONLY_FREE_ROAM)**
25. After any ending is reached, the player enters `READ_ONLY_FREE_ROAM` state.
26. Player may navigate all map nodes freely, re-examine LORE nodes, and re-fight COMBAT, HAZARD, and BOSS nodes for XP. In `MAP_FREE_ROAM`, **all COMBAT, HAZARD, and cleared BOSS nodes require a "Replay?" confirmation prompt** before the battle begins — nothing auto-fires (see Rule 22 FREE_ROAM exception). Dragon data (XP, level, stage) continues to accrue normally.
27. Hatchery, Fusion, Shop, and Save Lantern remain functional. Journal unlocks and flag-gated content remain accessible. HUB_RETURN node transitions to Hub normally.
28. The Mirror Admin (Singularity final boss) cannot be re-triggered. Its node shows a brief in-world readout instead: *"Process archived. Mirror Admin is no longer active."* Confirm dismisses the readout; no battle or Replay? prompt appears. Ending choice screens cannot be re-displayed. Singularity records `ending_id` (str, one of `{"total_restore", "the_patch", "hardware_override"}`) in save data; Campaign Map reads `ending_id != ""` as the condition that activates `MAP_FREE_ROAM` state on load — no separate flag field is required.

---

### States and Transitions

| State | Description | Input Accepted |
|-------|-------------|----------------|
| `MAP_EXPLORE` | Player at a landmark node on the overworld. | D-pad to adjacent node; confirm to interact |
| `MAP_TRAVEL` | Player avatar animating between nodes. | None (locked during transit) |
| `MAP_BOSS_TRANSITION` | 2-second auto-advancing transition screen (Singularity sigil, boss name). Fires on arrival at an uncleared BOSS node. | None (no input accepted; auto-advances to MAP_BATTLE after 2s) |
| `MAP_BATTLE` | Battle Engine active for this encounter. | Battle Engine input |
| `MAP_LORE_DISPLAY` | Captain's Log fragment reading. | Confirm to dismiss |
| `MAP_GATE_DENIED` | Gate node rejection message displayed. | Confirm to dismiss; player stays at current node |
| `MAP_HUB_TRANSITION` | Transitioning back to Hub (loadout screen open). | Loadout inputs |
| `MAP_FREE_ROAM` | Post-game read-only state. | All MAP_EXPLORE inputs |

State transition rules:
- `MAP_EXPLORE` → `MAP_TRAVEL`: d-pad pressed toward connected node; if the destination node is NOT a BOSS node, `previous_node_id` is set to the current node's `node_id` before travel begins
- `MAP_TRAVEL` → `MAP_EXPLORE`: travel animation completes; HP recovery triggers if node type is REST; node event evaluates
- `MAP_EXPLORE` → `MAP_BATTLE`: arrival at COMBAT (uncleared) or HAZARD (uncleared) node (auto-trigger, no confirm required)
- `MAP_EXPLORE` → `MAP_BOSS_TRANSITION`: arrival at uncleared BOSS node (auto-trigger)
- `MAP_EXPLORE` → Crown flow: arrival at CROWN node; Campaign Map calls Singularity and remains outside Battle Engine
- `MAP_BOSS_TRANSITION` → `MAP_BATTLE`: 2-second timer elapses (auto-advance, no input accepted during transition)
- `MAP_BATTLE` → `MAP_EXPLORE` (win): return to current node; HP carries forward; if node type is COMBAT or HAZARD, add `node_id` to `cleared_combat_nodes[]` (first-time win only — already-cleared nodes remain cleared); increment `expedition_xp_earned` by `xp_earned`
- `MAP_BATTLE` → `MAP_EXPLORE` (lose): return to `previous_node_id`; all loadout dragons restored to full HP; `floor(expedition_xp_earned × XP_DEFEAT_PENALTY)` deducted from slot-1 dragon XP; `expedition_xp_earned` resets to 0
- `MAP_EXPLORE` → `MAP_LORE_DISPLAY`: arrival at LORE node (first visit or revisit with content)
- `MAP_EXPLORE` → `MAP_GATE_DENIED`: arrival at GATE node, stage or matrix requirement not met
- `MAP_GATE_DENIED` → `MAP_EXPLORE`: player presses Confirm to dismiss denial message; player position stays at the GATE node itself (the gate node is the approach side of the passage). Player may freely navigate away from the gate node via d-pad.
- `MAP_EXPLORE` → `MAP_HUB_TRANSITION`: arriving at HUB_RETURN node and confirming

---

### Interactions with Other Systems

| System | Direction | Data Exchange |
|--------|-----------|---------------|
| Dragon Forge Hub | Bidirectional | Hub Bulkhead → Campaign Map (loadout: active dragon + bench slots). Campaign Map → Hub: `current_act` (int 1–4) written to save data on act gate pass. Return to Hub via `HUB_RETURN` node. |
| Battle Engine | Downstream consumer | Campaign Map initiates battle with: `enemy_level`, `enemy_element`, `player_dragon` (slot 1). Battle Engine returns `BattleEndedPayload` and `BattleDurableDelta`. Campaign Map applies Formula 1 decay to compute final `xp_earned`, calls Dragon Progression helpers for XP/Resonance, validates authored Scrap reward data, and applies Scrap rewards through EconomyLedger. Campaign Map owns final reward settlement on battle victory — the Shop and Hatchery are separate consumers of the same Scrap pool. |
| Dragon Progression | Bidirectional | Campaign Map reads `dragon.stage` and `dragon.level` for stage gate checks (Acts 1–3). Reads `stats_updated` signal to sync dragon stats after level-up. Stage threshold definitions (I–IV) must remain consistent with gate requirement values. Benched dragons earn no XP, but do earn +1 Resonance charge per expedition battle as specified in Rule 9 and AC-CM18. |
| Hatchery | Downstream trigger | After each pull, Campaign Map evaluates `matrix_stabilized` condition against roster. Hatchery must emit `dragon_acquired(dragon)` event that Campaign Map listens to. |
| Singularity | Bidirectional | Campaign Map emits `matrix_stabilized()` → Singularity receives for its own endgame logic (Act 3→4 gate is owned by Campaign Map, not Singularity). Singularity emits `corruption_class_changed(payload)` → Campaign Map updates hazard and SCAR presentation after save commit. Singularity provides boss definitions for BOSS nodes and Crown flow accessors for the CROWN node. |
| Journal / Console | Downstream trigger | Campaign Map emits `landmark_reached(node_id)` on LORE node arrival → Journal evaluates flag conditions for fragment delivery. |
| Save / Persistence | Bidirectional | Serializes Campaign Map-owned fields: `current_node_id`, `acts_unlocked[]`, `matrix_stabilized`, `visited_nodes[]`, `cleared_bosses[]` for generic non-Singularity bosses, `cleared_combat_nodes[]`, `loadout_hp[]`, `previous_node_id`, `unlocked_gates[]`, `expedition_xp_earned`, `gate_denial_count`, `expedition_field_kit`, `expedition_cache_shard`, and `expedition_emergency_patch`. Campaign Map reads Singularity-owned `scar_nodes[]`, `ending_id`, `gatekeeper_[id]_defeated`, and `mirror_admin_defeated` on load. Restores state on load. |
| Audio Director | Downstream consumer | Emits `act_entered(act_id)` on gate pass → Audio Director transitions music cue. Emits `node_type_entered(type)` on arrival for ambient SFX. |

**Data contract — node definition:**
```
{
  node_id: str,
  act: int (1–4),
  type: str (COMBAT|LORE|GATE|HUB_RETURN|BOSS|CROWN|REST|HAZARD),
                           // SCAR is a runtime overlay state, not a base type.
                           // A node is treated as SCAR if its node_id is in save_data.scar_nodes[].
                           // SCAR overrides display/behavior; the static `type` field is not mutated.
  connections: [{ direction: str ("north"|"south"|"east"|"west"), target_node_id: str }],
  enemy_element: str       (COMBAT/HAZARD only),
  enemy_level: int         (COMBAT/HAZARD only; range: 1–60 per act authoring; typical authored range 1–55),
  base_xp: int             (COMBAT/HAZARD only; default 25 = BASE_XP constant; may be authored higher for named encounters),
  hazard_status_effect: str (HAZARD only; the status effect applied to enemy at WARNING+ corruption class; authored per node; must match a valid Battle Engine status accepted by Singularity),
  crown_flow_id: str       (CROWN only; default "mainframe_crown"),
  lore_fragment_id: str    (LORE only),
  gate_act: int            (GATE only; 1–4; for Acts 1–3 stage gates only),
  gate_type: str           (GATE only; "stage" for Acts 1–3; "matrix" for Act 4 Spine Access gate),
  skye_note: str           (GATE only; optional; the Skye field-note text appended on second+ denial. Authored per gate node. Example: "My dragon isn't ready — I need to push further." If absent, first-denial lore text repeats on subsequent denials.),
  boss_id: str             (BOSS only; references a boss definition in Singularity GDD — forward contract pending Singularity design)
}
```

**SCAR overlay rule:** At scene load, Campaign Map reads `save_data.scar_nodes[]`. Any node whose `node_id` appears in this list is treated as SCAR: no encounter fires, visuals are overridden with SCAR appearance (corrupted tile, static noise, faint traversal path indicator), and no tooltip icon is shown. The node remains traversable.

**OQ-HUB-01 RESOLVED:** Max expedition party = 1–3 dragons; slot 1 = active; slots 2–3 = benched; no element/stage restriction on loadout selection; mid-expedition dragon swap = permitted at any landmark, free, not during battle.

## Formulas

### Formula 1 — XP per Battle

The XP formula is **canonical in battle-engine.md** and owned by that GDD. Campaign Map references it here for act-balance documentation, and extends it with an over-leveling decay rule to close the backtracking XP exploit identified during design review.

**Base formula:**
`xp_earned_raw = max(1, floor(base_xp × float(enemy_level) / float(player_dragon_level)))`

**Over-leveling decay** (applied when player level significantly exceeds enemy level):
```
decay_mult = XP_DECAY_MULT if player_dragon_level > (enemy_level + XP_DECAY_BAND) else 1.0
xp_earned  = max(1, floor(xp_earned_raw × decay_mult))
```

This ensures that farming content the player has substantially outleveled (e.g., backtracking to clear low-level nodes in earlier acts) yields diminishing returns. The check fires after `xp_earned_raw` is computed; min-1 is enforced on the final result.

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `base_xp` | int | 25 (default); per-node override must not exceed 50 | Base award per COMBAT/HAZARD node. The per-node `base_xp` field in map data is used when present; the global `BASE_XP` constant (Tuning Knobs, default 25) is the fallback when no override is authored. These are distinct values: `BASE_XP` is a global tuning constant; `base_xp` is a per-node authored field that may exceed the constant for named encounters only, up to 50. |
| `enemy_level` | int | 1–60 (authored per node; typical Act 4 ceiling 55, absolute upper bound 60) | Enemy dragon level from node data. |
| `player_dragon_level` | int | 1–60 | Active dragon's current level at battle entry. |
| `XP_DECAY_BAND` | int | 5 (default) | Levels beyond which the player must exceed the enemy before decay applies. See Tuning Knobs. |
| `XP_DECAY_MULT` | float | 0.25 (default) | Multiplier applied to `xp_earned_raw` when player level > enemy level + band. |
| `xp_earned` | int | 1–1500 (mathematical max at default base_xp; practical campaign max ~62 under path constraints, before decay) | XP awarded on battle victory. Min 1 enforced by `max()` on the final result. |

**Output range:** Mathematical min = 1 (guaranteed). Mathematical max = 1500 (base_xp=25, enemy_level=60, player_level=1). At BASE_XP safe-range ceiling of 50: 3000. **Practical campaign max** under path-authoring constraints (Rule 17) and decay: ~62 XP/battle (underleveled player vs act ceiling enemy, no decay since enemy > player).

**Key output table:**

| Scenario | Raw XP | Decay? | Final XP | Notes |
|----------|--------|--------|----------|-------|
| L1 vs L15 (Act 1 ceiling) | 375 | No (enemy > player) | 375 | Path-gated per Rule 17 — unreachable at L1 |
| L9 vs L15 (Act 1 ceiling, normal) | 41 | No | 41 | Reasonable Stage I ceiling reward |
| L10 vs L25 (Act 2 ceiling) | 62 | No (enemy > player) | 62 | Good Stage II challenge reward |
| L25 vs L40 (Act 3 ceiling) | 40 | No | 40 | Stage III entry, challenging |
| L30 vs L15 (backtrack to Act 1) | 12 | Yes (30 > 15+5) | 3 | Decay active — backtracking is inefficient |
| L49 vs L40 (Act 3, near end) | 20 | Yes (49 > 40+5=45) | 5 | Intentional thinning — encourages forward progress; decay fires, final XP = floor(20 × 0.25) = 5 |
| L60 vs L55 (Act 4 ceiling) | 22 | No (60 = 55+5; strict `>` not met) | 22 | Max-level play; nonzero XP |
| L60 vs L45 (Act 3, post-game backtrack) | 18 | Yes (60 > 45+5=50) | 4 | Post-game grind decay active |

**Approximate battles to reach Level 50 (Stage IV):** ~120–160 battles with typical forward progression, depending on which nodes are visited and in what order. (dragon-progression.md's ~186 figure is the equal-level mathematical baseline. The actual path-weighted campaign figure is **lower** than 186, because early battles against higher-level enemies yield above-average XP per battle. The previously stated ~200 figure was directionally incorrect.)

---

### Formula 2 — HP Recovery on REST Node Arrival

`dragon.current_hp = dragon.max_hp`

`dragon.max_hp = floor((base_hp + (dragon.level − 1) × 3) × shinyMult)` *(Dragon Progression GDD Formula 1)*

Applied to **all dragons in the current expedition loadout** (slots 1–3) upon arrival at a **REST node only**. HP does not automatically restore at COMBAT, LORE, GATE, HUB_RETURN, BOSS, or HAZARD nodes — HP carries between these nodes.

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `dragon.level` | int | 1–60 | Dragon's current level |
| `base_hp` | int | 85–120 | Element's base HP at level 1 |
| `shinyMult` | float | {1.0, 1.2} | 1.2 if dragon is shiny, else 1.0 |
| `dragon.current_hp` | int | 1–`max_hp` | HP set to `max_hp` on REST node arrival |

**Output:** `current_hp` fully restored. Cannot exceed `max_hp`. HP is also fully restored for all loadout dragons on expedition start (departing from Bulkhead).

**Ordering note:** If the slot-1 dragon leveled up during the preceding battle, `stats_updated` (including the updated `max_hp`) fires before defeat-recovery restore or REST-node restore applies. HP is always restored to the post-level-up `max_hp`, never a stale pre-level-up value.

---

### Formula 3 — Gate Check

Gates use two distinct check types depending on the act:

**Acts 1–3 (stage check):**
`dragon_stage = stage_for(dragon.level)`
`gate_passes = (dragon_stage >= required_stage_for_act)`

**Act 4 (matrix check):**
`gate_passes = (save_data.matrix_stabilized == true)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `dragon.level` | int | 1–60 | Active dragon's current level (Acts 1–3 only) |
| `dragon_stage` | int | 1–4 | Stage lookup: I=1-9, II=10-24, III=25-49, IV=50-60 |
| `required_stage_for_act` | int | 1–3 | Act 1=1 (open), Act 2=2, Act 3=3 |
| `matrix_stabilized` | bool | — | Must be `true` to pass Act 4 Spine Access gate |
| `gate_passes` | bool | — | `true` → gate unlocks permanently; `false` → denial message shown |

**Output:** Boolean. Stage check has no degenerate outputs — lookup always defined for levels 1–60. Matrix check is a boolean read — no degenerate outputs. Stage thresholds owned by dragon-progression.md; changes require updating this gate logic.

---

### Formula 4 — Matrix Stabilization Check

Boolean set-membership check. Documented as a specified computation for consistent implementation.

`matrix_stabilized = roster.has(FIRE) AND roster.has(ICE) AND roster.has(STORM) AND roster.has(STONE) AND roster.has(VENOM) AND roster.has(SHADOW)`

| Variable | Type | Description |
|----------|------|-------------|
| `roster.has(E)` | bool | `true` if any owned dragon has `element == E` |
| `matrix_stabilized` | bool | One-way latch in save data — once `true`, never reverts |

**Evaluation trigger:** Every dragon acquisition event (Hatchery pull, Fusion Engine output).
**One-way latch:** Fusing away an element dragon does not un-trigger the flag if it was already set.
**Signal emitted on** `false` → `true` transition: `matrix_stabilized()`.

**Signal guard:** The evaluation order is: (1) compute roster element coverage using the `roster.has(E)` check for all six elements, (2) only if all six are present **and** `matrix_stabilized` is not yet `true`, set the flag to `true` and emit the signal. This `if not matrix_stabilized` guard ensures the signal fires exactly once, regardless of concurrent acquisition events or deferred calls. Re-running the check when the flag is already `true` is a no-op.

## Edge Cases

Edge cases are organised into 7 categories matching the primary failure surfaces identified during design review.

### EC-NAV: Navigation

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-NAV-01 | Player inputs d-pad direction to a non-adjacent node | Blocked at input layer; no state change; cursor stays on current node |
| EC-NAV-02 | Player at a dead-end node (one connection only) | Only one direction shown as active; all other d-pad directions ignored |
| EC-NAV-03 | Player attempts to move during MAP_BATTLE state | State machine blocks input; MAP_BATTLE does not forward navigation events |
| EC-NAV-04 | Path leads to a GATE node the player cannot pass | GATE node is reachable and selectable; player moves TO the gate node (Rule 3 — d-pad moves to connected node). MAP_GATE_DENIED fires on arrival. After dismissal, **player remains at the GATE node in MAP_EXPLORE** (the gate node itself is the "approach side"). Player may navigate away via d-pad. Player does NOT automatically return to the previous node — they stay at the gate and choose their next move. |
| EC-NAV-05 | Player activates a HUB_RETURN node | Expedition state saved; MAP_HUB_TRANSITION fires; Dragon Forge Hub scene loaded |

### EC-BAT: Battle Outcomes

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-BAT-01 | Player defeats BOSS | Node flags as CLEARED; `boss_defeated(boss_id)` emitted; act unlock triggers |
| EC-BAT-02 | Player wins any COMBAT node | Player returns to MAP_EXPLORE at current node; HP carries forward (no automatic restore); XP and Scraps awarded to slot-1 dragon; `node_id` added to `cleared_combat_nodes[]` if not already present; `expedition_xp_earned` incremented by `xp_earned` |
| EC-BAT-03 | Simultaneous KO (both dragons reach 0 HP same turn) | Player wins per battle-engine.md rule; treated as COMBAT win; HP restore fires |
| EC-BAT-04 | Player loses BOSS battle | Same as COMBAT defeat: return to previous node, full HP, boss node not cleared |
| EC-BAT-05 | Active dragon levels up during battle; new level meets Stage gate requirement | Stage check uses post-battle level at gate-check time (stage always derived at check time, never locked at expedition start); gate is now passable |
| EC-BAT-06 | Active dragon reaches MAX_LEVEL (60) mid-battle | `apply_xp()` clamps at MAX_LEVEL; XP overflow discarded; no signal spam; battle continues normally |

### EC-LOAD: Loadout

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-LOAD-01 | Player attempts to begin expedition with 0 dragons | Bulkhead gate — campaign map scene never loads; player redirected to roster screen |
| EC-LOAD-02 | Expedition begins with only 1 dragon (slots 2–3 empty) | Valid; no mechanical impact on XP or Resonance — only slot 1 accrues these regardless |
| EC-LOAD-03 | Benched dragon was at MAX_LEVEL when expedition started | No XP or charge impact; benched dragons are passive. This case is a no-op. |
| EC-LOAD-04 | Player swaps dragon at a GATE node, new slot-1 has lower stage | Gate check reads slot-1 stage at traversal time; lower-stage dragon triggers MAP_GATE_DENIED |
| EC-LOAD-05 | "All dragons fainted" scenario | Impossible on the campaign map: only slot-1 (active) dragon battles; benched dragons never take HP damage; defeat fires only when slot-1 reaches 0 HP |

### EC-GATE: Gate Checks

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-GATE-01 | Slot-1 dragon is Stage IV attempting Act 2 gate | Stage IV ≥ Stage II; gate passes; no special case needed |
| EC-GATE-02 | Save/load mid-expedition at a GATE node | Player loads at gate node in MAP_EXPLORE; stage check re-runs when player attempts traversal; result is deterministic |
| EC-GATE-03 | Player meets the Act 2→3 gate (Stage III required), then later attempts the Act 3→4 gate with the same Stage III dragon | Acts 2→3 and Act 3→4 use **different** check types. Act 2→3 (Mirror Admin Gate) uses the stage check — Stage III dragon passes. Act 3→4 (Spine Access) uses the matrix check (`save_data.matrix_stabilized == true`) — dragon stage is irrelevant here. A Stage IV dragon with an incomplete 6-element roster still fails the Act 3→4 gate. |
| EC-GATE-04 | Player swaps to lower-stage dragon at GATE node, then attempts traversal | Gate check reads slot-1 stage at traversal time; lower-stage dragon fails; MAP_GATE_DENIED fires |
| EC-GATE-05 | Player cannot pass a gate | Player may explore remaining unvisited nodes in the current act, return to hub, or battle for XP; no state trap is possible |
| EC-GATE-06 | Player arrives at GATE node without sufficient stage or matrix (first visit) | MAP_GATE_DENIED fires; denial message shown; player confirms to dismiss; player remains on the approach side of the gate node |

### EC-MAT: Matrix Stabilization

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-MAT-01 | 6th core element acquired during expedition | `matrix_stabilized` latches immediately; `matrix_stabilized()` signal emits; Firewall Gate passage now possible |
| EC-MAT-02 | 6th element acquired while player is mid-map (not at hub) | Latch fires without interrupting current map state; no forced transition |
| EC-MAT-03 | Cross-element fusion produces a new element type | Fusion result checked against roster element coverage; if 6th unique element, Formula 4 latch fires |
| EC-MAT-04 | Player fuses away the last dragon of a previously-acquired element | `matrix_stabilized` is a one-way latch; never unsets; no re-check required |
| EC-MAT-05 | Legacy save loaded with `matrix_stabilized` field missing | Auto-latch silently via migration routine: derive element coverage from current roster; if ≥1 of each 6 elements, set `matrix_stabilized = true` directly in save data **without emitting the `matrix_stabilized()` signal** (emitting the signal would trigger the 2-second visual pulse — inappropriate for a save migration). The migration routine also directly adds the Spine Access gate `node_id` to `unlocked_gates[]` without relying on the signal. No player notification. This migration path bypasses the signal entirely; the signal fires only on in-session false→true transitions. |
| EC-MAT-06 | Player reaches Spine Access gate (Act 3→4) before matrix is stabilized | Gate check returns false; MAP_GATE_DENIED; player returned to approach node; in-world text shown; no lore fragment consumed |
| EC-MAT-07 | `matrix_stabilized = true`; player subsequently loses roster coverage of multiple elements | Latch is permanent; never re-evaluated; `matrix_stabilized` remains true |

### EC-SAVE: Save / Load

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-SAVE-01 | Save mid-expedition at a BOSS node | Save captures position, expedition state, loadout, and per-dragon HP; on load, player is at BOSS node in MAP_EXPLORE; BOSS battle has not started |
| EC-SAVE-02 | Concern that stale stage data could persist across saves | Not a risk: stage is derived from `dragon.level` at check time (Formula 3); never read from save data |
| EC-SAVE-03 | Legacy save missing `matrix_stabilized` field | See EC-MAT-05; handled at load time, silently |
| EC-SAVE-04 | Legacy save missing `scar_nodes[]` | Re-derive from current Singularity corruption class at load; no player impact |
| EC-SAVE-05 | Legacy save missing `acts_unlocked[]` | Default to `[1]`; player may lose act-unlock progress but never gains unauthorised access |
| EC-SAVE-06 | Corrupted expedition state on load | Treat as hub state; player returned to Dragon Forge Hub; loadout preserved |

### EC-XP: XP Economy Edge Cases

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-XP-01 | Player at Level 46+ blocked at Act 3 by incomplete `matrix_stabilized` (Act 4 gate locked). Act 3 ceiling enemies at Level 40; decay fires at L46 (46 > 45). XP yield ≈ 5 per battle. Player needs 200 XP/level for Stage IV. | Primary mitigation: Hatchery element soft-pity (OQ-CM06 cross-contract) should prevent extreme element drought keeping the player stuck. Secondary mitigation: the Field Kit (Rule 9a) allows the player to sustain longer expeditions and maximize battles per run. Tuning escape valve: if this scenario proves punishing in playtest, reduce `XP_DECAY_BAND` from 5 to 3 (pushing the decay threshold to player_level > enemy_level + 3, giving more room before decay fires against Act 3 ceiling enemies). Designer test: at Level 46 vs Level 40 enemy with `XP_DECAY_BAND = 5`, decay fires — 5 XP/battle. With `XP_DECAY_BAND = 3`: 46 > 43 → still fires. With `XP_DECAY_BAND = 7`: 46 > 47 → NO decay — 20 XP/battle. Raising band to 7 is the most effective dial for this scenario. |
| EC-XP-02 | Player defeats themselves multiple times in a single expedition. | Each defeat resets `expedition_xp_earned` to 0. The second defeat's penalty applies only to XP earned since the most recent reset — not total expedition XP. See AC-CM11c. |

---

### EC-SCAR: Corruption / SCAR Nodes

| ID | Scenario | Resolution |
|----|----------|------------|
| EC-SCAR-01 | LORE node becomes SCAR before player has read its lore fragment | In MVP, node type is fixed at graph load — dynamic mid-session node conversion is out of scope; flagged as OQ for post-MVP content pipeline |
| EC-SCAR-02 | SCAR node is a bridge node (sole traversable path between two landmarks) | Traversal is still possible; SCAR nodes have no content but are not impassable walls; connectivity is preserved. To communicate passability, the SCAR node's visual must include a faint path-connection indicator (e.g. a dim directional line) visible through the corruption overlay. |
| EC-SCAR-03 | Singularity reaches BREACH class, expanding SCAR node coverage | New SCAR nodes accepted silently; player notified via corruption-status HUD element, not per-node pop-ups; all SCAR nodes remain traversable |
| EC-SCAR-04 | Player is standing on a node as it becomes SCAR mid-session | Out of scope in MVP (dynamic node conversion not implemented); governed by EC-SCAR-01 authoring constraint |
| EC-SCAR-05 | HAZARD node at NOMINAL corruption class | Treated as standard COMBAT node; no hazard modifiers; enemy present at defined `enemy_level` |
| EC-SCAR-06 | HAZARD node at BREACH corruption class | Hazard modifier magnitude defers to Singularity GDD; Campaign Map guarantees the node remains traversable regardless of class tier |

## Dependencies

### Upstream Dependencies (Campaign Map depends on these)

| System | GDD Status | What Campaign Map Needs |
|--------|-----------|------------------------|
| Dragon Forge Hub | Approved | Loadout provisioning: the selected slot-1 dragon and bench slots (slots 2–3) at expedition start. Loadout rules are defined in this GDD (Section C, Rules 6–9) and resolve OQ-HUB-01 from dragon-forge-hub.md. |
| Battle Engine | Approved | Combat resolution: Campaign Map calls Battle Engine with `{enemy_level, enemy_element, player_dragon}` and receives `{battle_result, raw_xp_awarded, scraps_earned}`. Battle Engine owns the raw XP formula; Campaign Map owns over-level decay and final `xp_earned` application. |
| Dragon Progression | Approved | `dragon.stage` and `dragon.level` for gate checks (Formula 3). `apply_xp()` call for XP grant after battle. `stats_updated` signal to sync stat display after level-up. Stage threshold definitions (I–IV) must remain consistent with gate requirement values. |
| Singularity | Approved | Global corruption class (`NOMINAL` → `BREACH`) to determine per-node hazard modifiers and SCAR node designation. Boss definition data (`boss_id` → boss configuration). Crown flow accessors for the CROWN node. `corruption_class_changed(payload)` and `ending_resolved(ending_id)` signals as input. |
| Fusion Engine | Approved | Campaign Map must listen to a `fusion_complete(dragon)` event (or equivalent) from the Fusion Engine to trigger Formula 4 (matrix stabilization check) after a fusion output produces a new element type. The Fusion Engine GDD must specify this event. |

### Downstream Dependents (these depend on Campaign Map)

| System | GDD Status | What They Need From Campaign Map |
|--------|-----------|----------------------------------|
| Hatchery | Approved | The `matrix_stabilized()` signal — Hatchery does not consume it directly, but dragon acquisitions from Hatchery trigger Campaign Map's Formula 4 evaluation. Hatchery must emit a `dragon_acquired(dragon)` event that Campaign Map listens to. |
| Journal / Console | Approved | `landmark_reached(node_id)` signal — Journal evaluates lore fragment flag conditions on this event. Campaign Map owns the signal; Journal owns fragment delivery. |
| Save / Persistence | Approved | Serialization contract: Campaign Map owns the following fields in save data: `current_node_id` (str), `acts_unlocked[]` (int array — act numbers 1–4 that have been entered), `unlocked_gates[]` (str array — individual gate `node_id` values permanently passed), `matrix_stabilized` (bool), `visited_nodes[]` (str array), `cleared_bosses[]` (str array — `boss_id` values for generic non-Singularity bosses only), `cleared_combat_nodes[]` (str array — `node_id` values of COMBAT and HAZARD nodes where the player has won at least once; these nodes show "Replay?" on subsequent visits), `loadout_hp[]` (int array [slot1_hp, slot2_hp, slot3_hp] — current HP per slot at save time; written after REST-node restore and after expedition-start restore; reflects current mid-expedition HP), `previous_node_id` (str — last non-BOSS node visited; initialized to HUB_RETURN node_id at expedition start; used for defeat recovery), `expedition_xp_earned` (int — XP earned by slot-1 dragon since expedition start; resets to 0 on hub return or defeat; 50% deducted from dragon XP on defeat), `gate_denial_count` (dict — `{gate_node_id: int}` — tracks how many times each gate node has denied the player; persists across saves; lifetime counter, not session-scoped; used to determine first-denial vs. subsequent-denial Skye note), `expedition_field_kit`, `expedition_cache_shard`, and `expedition_emergency_patch`. Campaign Map reads but does not own Singularity's `scar_nodes[]`, `ending_id`, `gatekeeper_[id]_defeated`, or `mirror_admin_defeated` fields. |
| Audio Director | Approved | `act_entered(act_id)` signal on gate pass (triggers music cue transition). `node_type_entered(type)` signal on landmark arrival (triggers ambient SFX). Campaign Map does not make audio decisions — it emits signals; Audio Director responds. |
| Shop | Approved | Campaign Map reads `expedition_field_kit` from save data (bool). Shop sets this to `true` on purchase; Campaign Map sets it to `false` on use. Shop stocks Field Kit at price `FIELD_KIT_PRICE` Data Scraps. Shop GDD owns the purchase flow and pricing display; Campaign Map owns the use rule and save data field. |
| Dragon Forge Hub (bidirectional) | Approved | `current_act` (int 1–4) written to save data on gate pass. Hub Bulkhead reads this to update its zone display. |

### Cross-GDD Contracts Established by This GDD

- **OQ-HUB-01** (dragon-forge-hub.md): Loadout rules are fully defined in Section C, Rules 6–9. Dragon Forge Hub GDD should be updated to reference campaign-map.md as the authoritative loadout specification.
- **XP backtracking** (battle-engine.md open question): Two independent safeguards now address the XP exploit. (1) **Authoring constraint** (Rule 17): Level Designers must not create shortcuts that allow underleveled players to reach high-level nodes — enforced by graph validation tooling, not runtime code. (2) **Economic disincentive** (Formula 1 over-leveling decay): overleveled players farming lower-level nodes receive reduced XP (`XP_DECAY_MULT` applied when player level > enemy level + `XP_DECAY_BAND`). These address different vectors; neither replaces the other. The battle-engine.md open question can be marked resolved.
- **HP recovery contract** (battle-engine.md open question): HP recovers on REST node arrival only (Rule 8). Defeat recovery restores full HP to all loadout dragons as a loss consequence. This replaces the "full restore on every node" model considered during battle-engine.md design.
- **Benched dragon Resonance** (Dragon Progression GDD): Benched dragons (slots 2–3) do NOT earn XP during an expedition. They DO earn +1 Resonance charge per expedition battle (Rule 9), consistent with dragon-progression.md's Resonance catch-up design. Dragon Progression GDD should be updated to confirm: AC-DP92a covers XP (benched = no passive XP accumulation — correct); Resonance charges for benched dragons are awarded per-expedition-battle by Campaign Map. Campaign Map Rule 9 and AC-CM18 have been updated accordingly.
- **Element soft-pity contract** (hatchery.md — resolved): The Act 4 Spine Access gate requires `matrix_stabilized = true` (all 6 core elements collected). Hatchery implements element soft-pity: after 20 pulls without a specific element type, its probability increases linearly, reaching guaranteed at pull 40.
- **Matrix Concept LORE node** (journal.md): The Act 2 LORE node `lore_elemental_resonance` uses `lore_fragment_id: "elemental_resonance"`. Journal GDD defines this fragment ID and delivery contract.
- **`scar_nodes[]` population ownership** (singularity.md): Campaign Map reads `scar_nodes[]` from save data at scene load and overlays matching nodes as SCAR. Singularity owns writing `scar_nodes[]` atomically when corruption class increases; the lists are cumulative by class and authored in `SingularityData.tres`. Campaign Map never mutates the field directly. This fragment introduces the Elemental Matrix concept in-world. After the player reads it, the Campaign Map HUD gains a 6-element matrix tracker (see UI Requirements). The Journal GDD and narrative writers must author this fragment's content. The node must appear on the Act 2 map before the Act 2→3 gate, so the player encounters it before needing to prepare for the Act 4 requirement.

## Tuning Knobs

All values below are authored constants that can be adjusted by a designer. Safe ranges and ordering constraints are noted where applicable.

| Knob | Default | Safe Range | What It Affects | Owner |
|------|---------|-----------|----------------|-------|
| `MAP_NODE_COUNT` | 40–46 | 32–56 | Total landmark count across all acts. Below 32 makes the game feel short; above 56 creates navigation fatigue. | Level Designer |
| `ACT_NODE_DISTRIBUTION` | 14–16 / 10–12 / 8–10 / 6–8 | Act 1 ≥ 10, Act 4 ≥ 4 | Per-act node count. Act 1 must be the largest (player learning). Act 4 must be small (escalation and focus). | Level Designer |
| `ACT_COMBAT_NODE_MINIMUM` | Act 1: 8, Act 2: 6, Act 3: 5, Act 4: 3 | ≥ 3 per act | Minimum COMBAT+HAZARD nodes per act. Ensures XP economy is satisfiable within each act's range. Do not author below minimum without cross-checking Dragon Progression XP curve. | Level Designer |
| `ACT_BOSS_NODE_MINIMUM` | Act 1: 1, Act 2: 1, Act 3: 1, Act 4: 2 | ≥ 1 per act; Act 4 ≥ 2 | Minimum BOSS nodes per act. Each act must have at least one boss encounter to establish Singularity presence and progression stakes. Act 4 requires at least 2 (one gatekeeper boss before the Mirror Admin final boss). | Level Designer |
| `XP_DEFEAT_PENALTY` | 0.5 | 0.25–0.75 | Fraction of `expedition_xp_earned` deducted from the slot-1 dragon's stored XP on defeat. 0.5 = 50% of in-expedition XP is lost. Below 0.25 the penalty is negligible; above 0.75 a single defeat can erase significant out-of-expedition XP. | Systems Designer |
| `ACT_LORE_NODE_MINIMUM` | Act 1: 2, Act 2: 2, Act 3: 1, Act 4: 1 | ≥ 1 per act (except Act 4 optional) | Minimum LORE nodes per act. Ensures narrative beat density. | Level Designer |
| `ACT_REST_NODE_COUNT` | Act 1: 2, Act 2: 1, Act 3: 1, Act 4: 1 | 1–3 per act | Number of REST nodes per act. REST nodes are the only HP recovery points — too few creates brutal attrition; too many removes tension. | Level Designer |
| `BASE_XP` | 25 | 10–50 | Base XP awarded per COMBAT/HAZARD node (fallback only — nodes with an authored per-node `base_xp` field use that value instead). **`BASE_XP` does NOT affect nodes with per-node overrides**; a global rebalance must also audit all authored node overrides to avoid a bimodal XP distribution. Changes ripple into Dragon Progression's level curve. Tune jointly with `XP_PER_LEVEL` thresholds in Dragon Progression. | Systems Designer |
| `FIELD_KIT_PRICE` | 50 | 20–100 | Data Scrap cost to purchase a Field Kit at the Shop. Below 20 the item is trivially affordable and removes all HP tension. Above 100 the item costs more than the expected Scrap income from a short expedition, making it prohibitively expensive for early-game players. Tune against expected Scrap income per expedition at each act. | Economy Designer |
| `ACT1_ENEMY_LEVEL_RANGE` | 1–15 | 1–20 | Enemy level range for Act 1 nodes. Upper bound must leave meaningful catch-up room for early players. | Level Designer |
| `ACT2_ENEMY_LEVEL_RANGE` | 10–25 | 8–30 | Enemy level range for Act 2. Lower bound must overlap with Act 1 ceiling (prevents cliff at gate). | Level Designer |
| `ACT3_ENEMY_LEVEL_RANGE` | 20–40 | 15–45 | Enemy level range for Act 3. | Level Designer |
| `ACT4_ENEMY_LEVEL_RANGE` | 35–55 | 30–60 | Enemy level range for Act 4. Upper bound at 55 leaves the Level 60 cap as a reward — players reach MAX_LEVEL in Act 4 but aren't forced to farm it. | Level Designer |
| `ACT2_GATE_STAGE` | 2 (Stage II) | 2–3 | Minimum stage required to pass the Act 1 → Act 2 gate. Stage II (level ≥ 10) is the minimum believable gate; Stage III would block mid-game players unreasonably early. | Game Designer |
| `ACT3_GATE_STAGE` | 3 (Stage III) | 2–4 | Minimum stage for Act 2 → Act 3 gate. Stage III (level ≥ 25) ensures the player has a developed dragon before the mid-game difficulty spike. | Game Designer |
| `ACT4_GATE` | N/A — not stage-tunable | — | Act 3→4 (Spine Access) is a **matrix gate** (`matrix_stabilized == true`), not a stage gate. There is no stage requirement to tune. Collecting all 6 elements is the only unlock condition. **Do not add a stage threshold for Act 4.** | Game Designer |
| `XP_DECAY_BAND` | 5 | 3–10 | Levels by which player must exceed enemy level before over-leveling XP decay applies. Higher band = more generous before decay kicks in. Tune jointly with `XP_DECAY_MULT`. | Systems Designer |
| `XP_DECAY_MULT` | 0.25 | 0.1–0.5 | XP multiplier applied to `xp_earned_raw` when player level > enemy level + `XP_DECAY_BAND`. 0.25 = 25% of normal XP. Do not set above 0.5 — that would make backtracking only slightly less efficient, insufficient to discourage camping. | Systems Designer |
| `D_PAD_HOLD_THRESHOLD` | 0.25s | 0.15s–0.40s | Duration of d-pad press (in seconds) that distinguishes a "hold" (camera pan) from a "tap" (node cursor movement). Values below 0.15s are too sensitive — accidental pans during navigation. Values above 0.40s require noticeable intention to pan. | UX Designer |
| `CAMERA_PAN_SPEED` | 200px/s | 100–400px/s | Speed of player-initiated camera pan (d-pad hold). Below 100px/s panning feels sluggish for large maps. Above 400px/s panning overshoots content at typical map scales. Tune against map layout at maximum node count (46 nodes). | UX Designer |
| `MATRIX_ELEMENT_COUNT` | 6 | 6 (fixed) | Number of distinct elements required to stabilize the matrix. Hard-coded to match the 6 core elements — changing this would require redesigning the roster element set. **Do not tune.** | Game Designer |
| `EXPEDITION_SLOT_COUNT` | 3 | 1–3 | Maximum dragons per expedition. Hard lower bound is 1 (must be able to enter with 1 dragon). Hard upper bound is 3 (HUD and battle engine designed for this). **Do not exceed 3 without redesigning downstream UI.** | Game Designer |

### Ordering Constraints

1. **`BASE_XP` and Dragon Progression XP thresholds are jointly tuned.** Changing `BASE_XP` without updating Dragon Progression's `XP_PER_LEVEL` table will break the campaign arc estimate (~120–160 battles to Stage IV). Always retune together and re-run the Formula 1 key output table.
1b. **`XP_DECAY_BAND` and `XP_DECAY_MULT` are jointly tuned.** A wider band (higher `XP_DECAY_BAND`) requires a steeper penalty (lower `XP_DECAY_MULT`) to meaningfully discourage backtracking. Tune both, then verify the L30-vs-L15 row in the Formula 1 output table produces XP well below the equal-level baseline (25).
2. **Act level ranges must overlap at act boundaries.** `ACT1` upper bound must overlap with `ACT2` lower bound (and so on). A gap creates an XP cliff at the gate; an excessive overlap devalues progression.
3. **Gate stage requirements must be non-decreasing across acts.** `ACT2_GATE_STAGE ≤ ACT3_GATE_STAGE ≤ ACT4_GATE_STAGE`. Reversing this order creates trivially passable late gates.

## Visual/Audio Requirements

### Visual Requirements

**Overworld Map**
- Stylized top-down 16-bit pixel art overworld. Player avatar (or dragon token) visible on nodes; animated walk cycle plays during MAP_TRAVEL state.
- Each act has a distinct biome palette: Act 1 = jungle green/gold, Act 2 = tundra blue-white, Act 3 = volcanic red-orange, Act 4 = aurora purple-teal.
- As corruption class increases (ANOMALY → BREACH), a shader filter progressively desaturates and adds pixel-noise artifacts to the overworld rendering. At BREACH, Acts 1–2 tiles override to a hardware-substrate aesthetic (circuit trace texture, exposed phosphor).
- SCAR nodes: visually degraded — corrupted tile art, static noise overlay, no node icon. Distinct from functional nodes at a glance. SCAR nodes that serve as bridge nodes (sole path between two landmarks) must include a faint path-connection indicator (e.g. a dim directional line) visible through the corruption overlay, communicating traversability to the player. *(Visual story type — evidence: screenshot + lead sign-off before Done.)*
- **Camera behavior:** The camera is always centred on the player's current node in MAP_EXPLORE. During MAP_TRAVEL, the camera follows the player avatar with a smooth linear pan — the avatar is always in frame throughout travel. Camera transitions are animated (smooth follow), never instant cuts or jumps. At large map layouts (40+ nodes), off-screen content is revealed naturally by avatar movement; no minimap is shown. Player-initiated camera pan (d-pad hold) scrolls the view smoothly at a fixed speed (`CAMERA_PAN_SPEED`); releasing the hold button stops panning; cursor remains at the player's current node (panning does not move the cursor).
- HAZARD nodes visible as a distinct icon at ANOMALY class+.
- BOSS nodes use a unique icon (Singularity sigil) distinct from COMBAT nodes.

**Node Icons and States**
- Each node type has a unique overworld icon: sword (COMBAT), scroll (LORE), barrier (GATE), portal (HUB_RETURN), eye (BOSS), crown/terminal glyph (CROWN), flame/crystal (REST), hazard symbol (HAZARD).
- Visited nodes render at reduced brightness. Unvisited nodes at full brightness. CLEARED BOSS node uses a greyed-out version of the BOSS icon.
- The player's current node is highlighted with a pulsing ring or cursor indicator.
- GATE nodes in denied state: icon flashes red on MAP_GATE_DENIED; returns to normal after dismissal.

**HUD / Overlays**
- Corner HUD displays: current act number, active dragon's HP bar, Data Scrap count (or abbreviated if ≥ 1000 → "999+").
- Corruption class indicator: small signal-bar icon (0–5 bars) reflecting current class level. Visible at all times on the overworld.
- **Matrix element tracker** (conditional): After the player reads the `elemental_resonance` LORE fragment (authored in Act 2), a 6-slot element tracker appears in the HUD. Each slot shows a small element icon — filled for elements the player owns at least one dragon of, hollow for missing elements. No numbers, no percentages — visual only. The tracker is not present before the LORE fragment is read. Once visible, it persists for the remainder of the playthrough including READ_ONLY_FREE_ROAM.
- On `matrix_stabilized()` transition: full-screen pulse effect (minimum **2 seconds** — a slow white-to-transparent wash, not a single frame) combined with a HUD notification text ("Matrix stabilized — Spine Access unlocked") that persists for 5 seconds before fading. The pulse must be perceptible on LCD displays; a single-frame flash is not acceptable. The notification must not require player interaction to dismiss. No modal — the world reacts, not a pop-up. *(Accessibility requirement: the 5-second HUD text must provide durable non-audio feedback for players without audio output.)*

### Audio Requirements

**Music**
- Each act has a distinct ambient music cue. Transition fires on `act_entered(act_id)` signal.
  - Act 1: organic, layered — lush percussion, synth-wind; digital artifacts begin at ~60% through
  - Act 2: sparse, cold — bell tones, refrigerant hum, distant processing noise
  - Act 3: industrial rhythm — hammer percussion, drive circuit bass
  - Act 4: sparse, spacious — single sustained tone, occasional data-burst staccato
- `READ_ONLY_FREE_ROAM` state: same music as the player's final act, slowed to 85% speed with reverb tail.

**Ambient SFX**
- `node_type_entered(type)` fires on every landmark arrival; Audio Director maps types to ambient layers:
  - COMBAT: battle-ready sting (short, 0.5s)
  - LORE: soft chime
  - BOSS: low drone
  - REST: environmental calm (birds/fans/wind appropriate to act)
  - GATE: system-ping tone
  - SCAR: static crackle on arrival; no environmental layer

**State SFX**
- MAP_GATE_DENIED: rejection tone (two-note descending)
- `matrix_stabilized()` signal: ascending four-note resolve chord, non-diegetic
- Act gate pass: distinct "clearance granted" tone (ascending arpeggio)
- Dragon level-up during expedition: Dragon Progression handles this signal; Campaign Map does not play a separate level-up cue

## UI Requirements

**Map Screen Layout**
- Full-screen overworld view with HUD overlay. No sub-menus visible during MAP_EXPLORE.
- D-pad navigates the map cursor between adjacent nodes. Confirm (face button A/South) activates the current node.
- Node tooltip: resting cursor on a node for 0.5s displays node name and type. Does not show enemy level or lore content — discovery is part of the fantasy.
- No minimap. The full map is the screen. At high node counts (40+), the camera pans to keep the player node centred.

**Gate Denial Screen**
- On MAP_GATE_DENIED: in-world text panel appears (styled as a terminal readout). Displays the gate's in-world framing text (e.g., "Firewall Gate — authentication insufficient"). Dismiss with confirm button.
- **First denial (per gate per session):** lore framing only. No stat readout.
- **Second and subsequent denials at the same gate:** lore framing is appended with a brief Skye field-note in smaller text, styled as a handwritten annotation (e.g., "My dragon isn't ready. I need to push further — or find a stronger one." / "Still locked. The matrix isn't complete — I'm still missing something."). The field-note communicates that the player needs to grow their dragon or complete a roster goal without exposing raw stat values. The note wording is authored per gate node and stored in gate data alongside the lore framing text. First-visit lore purity is preserved.
- No stat requirements shown in either case. The lore-opacity design pillar is maintained.

**Loadout Screen (at Bulkhead / HUB_RETURN)**
- Three slot cards (slot 1 = ACTIVE, slots 2–3 = BENCHED). Each card shows: dragon portrait, element icon, stage, level, HP bar.
- Slot 1 is highlighted as the active battle slot. Slots 2–3 are clearly labelled BENCHED. No XP or charge counters are shown for benched slots — benched dragons earn no passive benefits during an expedition (see Rule 9).
- D-pad navigates between slot cards and the expedition party list (showing only the 3 dragons selected at expedition start — the full roster browser is not accessible mid-expedition; see Rule 7). Confirm to assign a dragon to the focused slot. Player must assign at least one dragon (slot 1) before embarking.
- Mid-expedition swap (at any landmark): same loadout screen opens in-place. No transition to Hub required.

**Boss Node Entry**
- On arrival at an uncleared BOSS node: brief transition screen with Singularity sigil and boss name. No skip. Auto-advances to battle after 2s.

**CROWN Node Entry**
- On arrival at Mainframe Crown before `ending_id` is set: Campaign Map calls Singularity's Crown flow and does not trigger Battle Engine or MAP_BOSS_TRANSITION.
- On arrival after `ending_id != ""`: the node opens post-game terminal content and never reopens relic selection.

**Act Transition**
- On successful gate pass: screen fade to black, then fade in to the new act biome. `act_entered(act_id)` fires on fade-out. No dialogue box — the world changes and the music changes.

**Post-Game (READ_ONLY_FREE_ROAM)**
- All nodes remain fully selectable. COMBAT, HAZARD, and BOSS nodes (except Mirror Admin) show a "Replay?" prompt before triggering any combat — nothing auto-fires in post-game.
- The Mirror Admin node shows an in-world terminal readout: *"Process archived. Mirror Admin is no longer active."* Confirm dismisses it; no combat or Replay? prompt appears.
- No new HUD elements are added in READ_ONLY_FREE_ROAM — the same HUD persists. The game does not add a "STORY COMPLETE" banner or overlay; the world's muted pace and the Mirror Admin's silence communicate the conclusion. The player cannot accidentally re-trigger the ending.

**Controller Support**
- All interactions must be operable via d-pad + 2 face buttons (confirm, cancel). No hover-only interactions.
- Camera pan (if map is larger than screen) uses left stick or d-pad hold; short tap navigates cursor. A "tap" is any d-pad press shorter than `D_PAD_HOLD_THRESHOLD` (default 0.25s, see Tuning Knobs). A "hold" at or beyond that threshold pans the camera instead. The threshold is tunable; see Tuning Knobs.
- Invalid d-pad direction (no adjacent node): cursor plays a brief visual nudge (cursor shifts slightly in the pressed direction then returns to center). This provides tactile feedback without implying navigation. No audio required.

## Acceptance Criteria

Each AC is independently verifiable. `AC-CM` prefix. Organised by subsystem.

### Navigation

| ID | Criterion |
|----|-----------|
| AC-CM01 | Pressing d-pad toward a connected adjacent node moves the player avatar to that node. |
| AC-CM02 | Pressing d-pad in a direction with no connection produces no state change and no audio feedback, but does trigger a brief visual cursor nudge (cursor shifts slightly in the pressed direction then snaps back). No node navigation occurs. |
| AC-CM03 | During MAP_BATTLE state, d-pad input does not trigger node navigation. |
| AC-CM04 | During MAP_TRAVEL state (avatar in motion), d-pad input is ignored. |
| AC-CM05 | Player may navigate backward to previously visited nodes in any act. |
| AC-CM06 | On HUB_RETURN node activation, the loadout screen opens and the player can return to Dragon Forge Hub. |

### Encounters and Battle Resolution

| ID | Criterion |
|----|-----------|
| AC-CM07 | Arriving at a COMBAT node for the **first time** (node not in `cleared_combat_nodes[]`) triggers a battle automatically with the node's authored `enemy_level` and `enemy_element`. On victory, the node's `node_id` is added to `cleared_combat_nodes[]`. |
| AC-CM07a | Arriving at a previously cleared COMBAT node (in `cleared_combat_nodes[]`) shows a "Replay?" prompt. Selecting Yes triggers the battle. Selecting No: no encounter fires; player remains at the node in MAP_EXPLORE state. The node is not removed from `cleared_combat_nodes[]` on replay win or loss. |
| AC-CM07b | Arriving at an unvisited LORE node automatically displays the Captain's Log fragment (no Confirm input required). The fragment is delivered and the node is marked visited in `visited_nodes[]`. |
| AC-CM07c | Arriving at a previously-visited LORE node produces no event: no fragment display, no Captain's Log update, no audio trigger. The node is traversable with no further interaction. |
| AC-CM08 | Arriving at a BOSS node triggers the configured boss battle. |
| AC-CM09 | After winning any COMBAT or HAZARD battle, XP is awarded first (per AC-CM14), then MAP_EXPLORE resumes at the current node with HP carrying forward (no automatic restore unless the node is a REST node). |
| AC-CM10 | After winning a generic non-Singularity BOSS battle, the `boss_id` is added to Campaign Map-owned `cleared_bosses[]` in save data; the node cannot be re-triggered without the "Replay?" confirmation prompt. Singularity gatekeepers and Mirror Admin do not write `cleared_bosses[]`; they use Singularity-owned `gatekeeper_[id]_defeated` and `mirror_admin_defeated` flags, while Campaign Map reads those flags to determine replay/archive presentation. |
| AC-CM10b | When a CLEARED BOSS node is activated and the player selects "No" on the Replay prompt, no encounter fires; the player remains at the node in MAP_EXPLORE state. |
| AC-CM11 | After losing any battle: (a) all loadout dragons are restored to full HP; (b) player is placed at `previous_node_id`; (c) `floor(expedition_xp_earned × XP_DEFEAT_PENALTY)` is subtracted from the slot-1 dragon's stored XP (floor; dragon XP minimum 0); (d) `expedition_xp_earned` resets to 0; (e) No Data Scraps are deducted. Boundary: if `expedition_xp_earned = 0` at time of defeat (no battles won yet), no XP is deducted. |
| AC-CM11b | `previous_node_id` is updated on **departure**, not arrival. When the player presses d-pad from node A toward node B (MAP_EXPLORE → MAP_TRAVEL fires): if B is not a BOSS node, `previous_node_id` is set to A's `node_id`. If B is a BOSS node, `previous_node_id` retains its current value. Verify: start at A → depart toward B (non-BOSS) → `previous_node_id` = A; depart from B toward C (BOSS) → `previous_node_id` stays A; defeat at C → player returns to A. Boundary: start at A → depart toward COMBAT D (non-BOSS) → `previous_node_id` = A; arrive at D (auto-battle fires) → lose → player returns to A (not D — D never updates `previous_node_id` because the update fired on departure FROM A, before the player arrived at D). |
| AC-CM11c | Multi-defeat XP window isolation: after a defeat resets `expedition_xp_earned` to 0, the second defeat's penalty applies only against XP earned since that reset — not total expedition XP. Verify: begin expedition → win battles earning 100 XP (`expedition_xp_earned` = 100) → defeat (50 XP deducted; `expedition_xp_earned` resets to 0) → win battles earning 60 XP (`expedition_xp_earned` = 60) → second defeat (30 XP deducted; `expedition_xp_earned` resets to 0). Total XP deducted: 80 (50+30), not floor(160 × 0.5) = 80 coincidentally — confirm via separate tracking that the second penalty pool was 60, not 160. |
| AC-CM12 | On entering any BOSS node, `previous_node_id` is recorded as the last non-BOSS node before that entry. On BOSS defeat, the player is placed at that recorded `previous_node_id`, not at the topologically nearest ancestor. |
| AC-CM13 | Losing a battle results in no loss of Data Scraps. XP penalty is applied per AC-CM11(c). |
| AC-CM14 | XP awarded after a COMBAT or HAZARD win is computed using the two-step Formula 1: `xp_raw = max(1, floor(base_xp × float(enemy_level) / float(player_dragon_level)))`, then `xp_earned = max(1, floor(xp_raw × decay_mult))` where `decay_mult = XP_DECAY_MULT` if `player_dragon_level > (enemy_level + XP_DECAY_BAND)`, else `1.0`. Boundary values: (a) equal levels, no decay → awards `base_xp`; (b) enemy=60, player=1, no decay → awards 1500; (c) player=1, enemy=1, no decay → awards `base_xp` (25); (d) player=30, enemy=15 → decay applies (30 > 20): xp_raw = floor(25×15/30) = 12, xp_earned = floor(12 × 0.25) = 3; (e) player=49, enemy=40 → decay applies (49 > 45): xp_raw = floor(25×40/49) = 20, xp_earned = floor(20 × 0.25) = 5. |
| AC-CM15 | A simultaneous KO (both dragons reach 0 HP in the same battle resolution step) is treated as a player win; XP award fires; HP carries forward (no automatic restore). |

### Loadout

| ID | Criterion |
|----|-----------|
| AC-CM15b | Field Kit use: if `expedition_field_kit == true` and the player activates the Field Kit at a landmark node, all loadout dragons (slots 1–3) are restored to full HP; `expedition_field_kit` is set to `false`. The Field Kit cannot be used if `expedition_field_kit == false` (already used or not purchased). If the player has not purchased a Field Kit (`expedition_field_kit == false` at expedition start), no option to use one is presented in the UI. |
| AC-CM15c | `expedition_xp_earned` reset on hub return: when the player activates HUB_RETURN and the loadout screen opens (beginning hub transition), `expedition_xp_earned` resets to 0 before the Hub scene loads. `expedition_field_kit` is **NOT** reset at HUB_RETURN — it persists through the hub visit and resets to `false` only at the next Bulkhead departure (consistent with Shop GDD flag semantics: the Shop must show Field Kit as "In Pack" when the player returns via HUB_RETURN with an unspent kit). Verify: win 3 battles (expedition_xp_earned = X, field_kit = true), return to Hub via HUB_RETURN — assert `expedition_xp_earned` is 0 AND `expedition_field_kit` remains `true` (Shop shows "In Pack"). Then depart on a new expedition — assert `expedition_xp_earned` is 0 and `expedition_field_kit` is `false` at expedition start (Bulkhead departure reset). |
| AC-CM15d | Field Kit grey-out: when `expedition_field_kit == true` and all non-null loadout dragons are at full HP (`dragon.current_hp == dragon.max_hp` for each non-null slot), the "Use Field Kit" MAP_EXPLORE action is greyed/disabled. The item remains in the player's inventory (`expedition_field_kit` stays `true`). Verify: purchase Field Kit → arrive at REST node (HP fully restored on arrival) → confirm "Use Field Kit" action is disabled/greyed. Arrive at a COMBAT node, sustain HP damage, win battle → confirm "Use Field Kit" action is now enabled. |
| AC-CM15e | Cache Shard MAP_EXPLORE use: when `expedition_cache_shard == true` and Shop's Cache Shard formula would grant `actual_xp > 0`, using the item calls Dragon Progression XP helpers and consumes `expedition_cache_shard` through ExpeditionInventoryLedger in the settlement transaction. If `party[0]` is at MAX_LEVEL or the formula would grant 0 XP, the action is greyed/disabled and the flag remains `true`. |
| AC-CM15f | Emergency Patch MAP_EXPLORE use: when `expedition_emergency_patch == true` and `party[0].current_hp < max(1, floor(party[0].max_hp × EMERGENCY_PATCH_FACTOR))`, using the item stages slot-1 HP restoration to that threshold and consumes `expedition_emergency_patch` through ExpeditionInventoryLedger in the settlement transaction. If slot-1 HP is already at or above the threshold, the action is greyed/disabled and the flag remains `true`. |
| AC-CM15g | Bulkhead departure and defeat-return reset all four expedition item flags (`expedition_field_kit`, `expedition_defrag_patch`, `expedition_cache_shard`, `expedition_emergency_patch`) through ExpeditionInventoryLedger. HUB_RETURN does not reset unspent expedition flags; the Shop displays unspent flags as "In Pack". |
| AC-CM16 | The player cannot launch an expedition with 0 dragons; the Bulkhead or loadout screen blocks entry and redirects to the roster. |
| AC-CM17 | An expedition with 1 dragon (slots 2–3 empty) launches successfully. |
| AC-CM17b | When the player confirms a loadout at the Bulkhead and begins an expedition, all dragons in slots 1–3 are restored to full HP before the campaign map scene loads. This applies regardless of their HP at the time of loadout selection. |
| AC-CM18 | Benched dragons (slots 2–3) do NOT earn XP during an expedition. Benched dragons DO earn +1 Resonance charge per expedition battle (each time the slot-1 dragon wins or loses a battle, all benched dragons gain 1 Resonance charge). Verify (win path): run an expedition with 1 benched dragon through 3 wins; benched dragon has +3 Resonance charges; +0 XP. Verify (defeat path): run an expedition where slot-1 loses 1 battle (defeat; player returns to previous node, full HP restore); benched dragon has +1 Resonance charge; +0 XP. (Inspect Resonance charge count via save data dict or debug property — the Loadout screen does not show XP counters for benched slots.) Verify (mixed): win 1 + lose 1 + win 1 = 3 total battles; benched dragon has +3 Resonance charges. |
| AC-CM19 | Dragon swap is available at any landmark node outside of battle; performing a swap costs nothing. |
| AC-CM20 | Dragon swap is not available during MAP_BATTLE state. |
| AC-CM21 | After swapping, the new slot-1 dragon is the one used in any subsequent battle on that node. |

### Zone Gates

| ID | Criterion |
|----|-----------|
| AC-CM22 | The Act 1 → Act 2 GATE node (Firewall Gate) passes if the slot-1 dragon is Stage II (level ≥ 10). The gate does NOT check `matrix_stabilized`. |
| AC-CM23 | The Act 2 → Act 3 GATE node (Mirror Admin Gate) passes if the slot-1 dragon is Stage III (level ≥ 25). |
| AC-CM24 | The Act 3 → Act 4 GATE node (Spine Access) passes if `save_data.matrix_stabilized = true`. Stage level is not checked for this gate. |
| AC-CM24b | The Spine Access gate (Act 3→4) permanently unlocks in `unlocked_gates[]` when `matrix_stabilized` first becomes `true` — even if the player has not yet physically reached the Spine Access node. On subsequent visits, the gate check reads `unlocked_gates[]` and passes immediately. |
| AC-CM25 | If a gate requirement is not met (stage insufficient for Acts 1–3, or matrix not stabilized for Act 4), MAP_GATE_DENIED fires; the in-world denial message is shown; the player confirms to dismiss. **Player remains at the GATE node in MAP_EXPLORE** — they do not automatically backtrack. The gate node is the "approach side"; the player may navigate away via d-pad. |
| AC-CM25b | A per-gate `gate_denial_count[gate_node_id]` (int) is stored in save data as a dict. **Always access via `gate_denial_count.get(gate_node_id, 0)` — never via direct `dict[key]` access** (direct access throws in GDScript if the key is absent, producing an S1 crash on a new save's first gate denial). On MAP_GATE_DENIED: if `gate_denial_count.get(gate_node_id, 0) == 0`, show lore framing text only; if `>= 1`, append the Skye field-note. `gate_denial_count[gate_node_id]` increments by 1 after each denial (creating the entry if absent). Counter is lifetime (not session-scoped) — persists across save/load cycles. A player who denies a gate once then saves, quits, and reloads will see the Skye field-note on their next denial. Verify: fresh save (empty dict) → deny gate → assert lore framing only, no crash, `gate_denial_count[gate_id] == 1`; save → reload → deny again → Skye field-note appears. |
| AC-CM26 | The gate denial message displays in-world lore framing text, not a stat readout. |
| AC-CM27 | Once a gate is passed, the gate's `node_id` is added to `unlocked_gates[]` in save data and the gate is not re-evaluated on subsequent visits. After a save/load cycle, the gate check reads `unlocked_gates[]` first; if the gate's `node_id` is present, the player passes immediately without re-running Formula 3. |
| AC-CM28 | A Stage IV dragon passes all stage-check act gates (Acts 1–3). The Act 4 Spine Access gate is still gated by `matrix_stabilized`, regardless of dragon stage. |
| AC-CM29 | After a dragon levels up mid-battle and its new stage meets the gate requirement, the gate is passable on next attempt. |

### Matrix Stabilization

| ID | Criterion |
|----|-----------|
| AC-CM30 | Acquiring the 6th unique core element (Fire, Ice, Storm, Stone, Venom, Shadow) sets `matrix_stabilized = true` in save data. |
| AC-CM30b | When `matrix_stabilized` transitions to `true`, the Act 3→4 Spine Access gate is added to `unlocked_gates[]` in save data. The player does not need to physically be at the gate for this unlock to record. |
| AC-CM31 | `matrix_stabilized()` signal is emitted exactly once, on the `false` → `true` transition. Re-running the stabilization check when the flag is already `true` does not re-emit the signal. |
| AC-CM32 | `matrix_stabilized` never reverts to `false` after being set, even if element coverage drops below 6. |
| AC-CM33 | Loading a legacy save with `matrix_stabilized` field absent: if the player's full roster contains ≥1 dragon of each of the 6 core elements, `matrix_stabilized` is silently set to `true` and the Spine Access gate is added to `unlocked_gates[]` via the migration routine — the `matrix_stabilized()` signal does NOT fire during migration. No notification is shown to the player. |
| ~~AC-CM34~~ | *Removed — previously drafted AC merged into AC-CM33 (legacy save migration covers both the absent-field and the already-set-true cases).* |
| AC-CM35 | Matrix stabilization check fires on every Hatchery pull completion and every Fusion Engine output. |
| AC-CM35b | When the `false` → `true` transition occurs: (1) `matrix_stabilized` is set to `true`, (2) Spine Access `node_id` is added to `unlocked_gates[]`, (3) `matrix_stabilized()` signal is emitted — all three occur within the same game tick, in that order. The signal does not fire if `matrix_stabilized` is already `true`. Unit test: trigger acquisition of 6th element; assert all three state changes are observable after a single event frame, in specified order. |

### Corruption / SCAR

| ID | Criterion |
|----|-----------|
| AC-CM36 | At NOMINAL corruption class, HAZARD nodes behave identically to COMBAT nodes (no hazard modifier). |
| AC-CM37 | At ANOMALY class, HAZARD nodes display a distinct icon on the overworld. |
| AC-CM38 | At WARNING class, HAZARD node battles begin with the enemy having a status effect applied. The specific status effect type and magnitude are defined per-node via the `hazard_status_effect` field in node data; they defer to the Singularity GDD's status effect vocabulary. |
| AC-CM38b | At ALERT corruption class, REST and LORE nodes designated by Singularity in `scar_nodes[]` render as SCAR overlays. On arrival at one of these SCAR-overlay nodes: no HP recovery fires, no lore fragment delivers, no encounter triggers. The node is traversable. |
| AC-CM39 | SCAR nodes are traversable (player can move through them); they trigger no encounter on arrival. |
| AC-CM40 | SCAR nodes display degraded visuals (corrupted tile, static noise overlay) and no node icon. *(Visual story type — evidence: screenshot + lead sign-off required before this AC can be marked Done.)* |
| AC-CM41 | A SCAR node that serves as the only path between two landmarks does not trap the player; traversal remains possible. |

### Save / Load

| ID | Criterion |
|----|-----------|
| AC-CM42 | Saving mid-expedition records all Campaign Map save fields: `current_node_id`, `acts_unlocked[]`, `unlocked_gates[]`, `matrix_stabilized`, `visited_nodes[]`, `cleared_bosses[]` for generic non-Singularity bosses, `cleared_combat_nodes[]`, `loadout_hp[]` (HP for all loadout slots; written to reflect current mid-expedition HP after any REST restore or expedition-start restore), `previous_node_id` (initialized to HUB_RETURN node_id at expedition start), `expedition_xp_earned`, `gate_denial_count[]`, `expedition_field_kit`, `expedition_cache_shard`, and `expedition_emergency_patch`. `scar_nodes[]`, `ending_id`, `gatekeeper_[id]_defeated`, and `mirror_admin_defeated` may be present in the save but are Singularity-owned and read-only to Campaign Map. |
| AC-CM43 | Loading a save places the player at the saved `current_node_id` in MAP_EXPLORE state. |
| AC-CM44 | Loading a save with missing `acts_unlocked[]` defaults to `[1]` (Act 1 open only). |
| AC-CM45 | Loading a save with missing `scar_nodes[]` re-derives SCAR node list from the current Singularity corruption class. |
| AC-CM46 | Loading a corrupted expedition state falls back to Hub state; loadout dragons are preserved. |

### Post-Game

| ID | Criterion |
|----|-----------|
| AC-CM47 | After any ending, Campaign Map reads Singularity-owned `ending_id` (str, one of `{"total_restore", "the_patch", "hardware_override"}`) from save data. On the next load, `ending_id != ""` is the condition that activates `MAP_FREE_ROAM` state — no separate flag field is used. If `ending_id` is absent/empty on load after an ending was reached, the save is treated as corrupted and falls back to Hub state. Campaign Map never writes `ending_id`. |
| AC-CM48 | In READ_ONLY_FREE_ROAM, all map nodes are navigable. Arriving at a COMBAT, HAZARD, or BOSS node — whether cleared or uncleared (except Mirror Admin — see AC-CM50) — displays a "Replay?" prompt. Selecting Yes begins the battle. Selecting No returns the player to MAP_EXPLORE at that node with no battle triggered. No COMBAT, HAZARD, or BOSS node auto-triggers in MAP_FREE_ROAM state, regardless of cleared status. |
| AC-CM49 | In READ_ONLY_FREE_ROAM, dragon XP, levels, and stages continue to accrue normally. |
| AC-CM50 | The Mirror Admin final boss cannot be re-triggered in READ_ONLY_FREE_ROAM. Activating the Mirror Admin node displays the terminal readout "Process archived. Mirror Admin is no longer active." Confirm dismisses it; no Replay? prompt and no battle appear. |
| AC-CM51 | The ending choice screen cannot be re-displayed in READ_ONLY_FREE_ROAM. |

### Controller / UI

| ID | Criterion |
|----|-----------|
| AC-CM52 | All Campaign Map interactions are completable using d-pad + two face buttons only. |
| AC-CM52b | Input duration is measured from button-down. (a) **Tap** (button released before `D_PAD_HOLD_THRESHOLD`): `cursor_moved` signal fires on button-up (button release). `camera_pan` does NOT fire. (b) **Hold** (button held for ≥ `D_PAD_HOLD_THRESHOLD` without releasing): `camera_pan` signal fires at the moment the threshold is crossed — the player does NOT need to release the button. `cursor_moved` does NOT fire. (c) A single d-pad press fires exactly one of the two signals, never both. (d) Releasing a held button after `camera_pan` has already fired does NOT trigger `cursor_moved`. Unit test: inject button-down, await 0.240s, inject button-up → assert only `cursor_moved` fires (tap). Inject button-down, await 0.260s (before button-up) → assert only `camera_pan` fires at the 0.250s threshold moment (default). Edge case: hold toward a blocked direction for ≥ threshold — `camera_pan` fires only; no `cursor_nudge` animation plays. |
| AC-CM52c | On `matrix_stabilized()` signal: a full-screen white pulse plays for a minimum of 2 seconds, and HUD text "Matrix stabilized — Spine Access unlocked" is displayed for 5 seconds before auto-fading. No player input is required to dismiss. *(Accessibility: the HUD text must be present even if audio output is disabled.)* |
| AC-CM53 | Node tooltips display after 500ms of cursor inactivity (no d-pad input received for 500ms while the cursor is on the node); tooltip shows node name and type only (no enemy level, no lore preview). Tooltip dismisses immediately on any d-pad input. |
| AC-CM54 | The HUD displays current act number, active dragon HP bar, Data Scrap count, and corruption class indicator at all times during MAP_EXPLORE. All four values update within one frame of the corresponding state change. Additionally: if the player has read the `elemental_resonance` LORE fragment (`"elemental_resonance"` is in `visited_nodes[]`), the HUD also displays the 6-element matrix tracker (filled icon = player owns ≥1 dragon of that element; hollow = missing). Matrix tracker updates on every dragon acquisition event. |
| AC-CM54b | **Matrix tracker negative case:** If the player owns ≥1 dragon of all 6 core elements but has NOT yet read the `elemental_resonance` LORE fragment (`"elemental_resonance"` is NOT in `visited_nodes[]`), the 6-slot matrix tracker is NOT present in the HUD. Verify: create save with full 6-element roster and `visited_nodes[]` not containing `"elemental_resonance"` — assert the matrix tracker node is not visible and not instantiated. A tracker appearing before the lore fragment is read is a failure even if all 6 elements are owned. |
| AC-CM55 | Data Scrap HUD shows exact count below 1000; shows "999+" at 1000 or above (consistent with dragon-forge-hub.md). Boundary values to test: 999 displays "999"; 1000 displays "999+"; 1001 displays "999+". |

## Open Questions

| ID | Question | Blocking? | Notes |
|----|----------|-----------|-------|
| OQ-CM01 | Dynamic node type conversion (LORE → SCAR mid-session) — is this a post-MVP content requirement? | No — MVP defers it | EC-SCAR-01 flags this. In MVP, node types are fixed at graph load. Post-MVP content patches may need a node-mutation system. |
| OQ-CM02 | Matrix stabilization lore timing — does the `matrix_stabilized()` signal trigger a Skye monologue or just a HUD update? | No — defers to Narrative Director | The GDD specifies a HUD pulse and no modal. Whether Skye speaks (Captain's Log entry, audio line) is a narrative decision. The event fires when all 6 elements are collected; the Spine Access gate (Act 3→4) unlocks as a consequence. |
| OQ-CM03 | BOSS phase count and defeat-between-phases recovery — if a BOSS has multiple phases, does the player's dragon HP persist from phase to phase? | No — defers to Singularity GDD | Singularity GDD owns boss definitions. Campaign Map specifies no HP recovery between phases; Singularity must clarify whether phases are a single continuous battle or sequential battles. |
| OQ-CM04 | **RESOLVED** — Act 4 gate uses `matrix_stabilized = true` (all 6 elements collected), not a stage requirement. This replaces the earlier draft's Stage III gate. The design rationale: Act 4 is narrative resolution; the gate is a story milestone (all elements gathered), not a grind milestone. |
| OQ-CM05 | Corruption class visual filter — does the shader apply globally (all acts) or only to the act the player is currently in? | No — defers to Technical Artist / Art Director | GDD specifies "overworld rendering" without constraining scope. A global filter is simpler; a per-act filter is more targeted. Resolve before Visual/Audio implementation begins. |
| OQ-CM06 | **RESOLVED** — Hatchery element soft-pity parameters are authored in hatchery.md: onset 20, guaranteed 40, with element drought counters and priority over Rare+ pity. | No | Campaign Map's matrix gate is no longer blocked by Hatchery drought mechanics. Future economy review may tune 20/40, but the implementation contract exists. |
