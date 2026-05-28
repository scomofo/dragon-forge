# Singularity

> **Status**: Approved
> **Author**: Skye (user) + Claude Code agents
> **Last Updated**: 2026-05-26
> **Implements Pillar**: Agency (ending choice); Dread (corruption arc)

## Overview

Singularity is Dragon Forge's endgame arc, triggered when the Elemental Matrix stabilizes (`matrix_stabilized = true` — all six elemental dragons collected). The system owns three interlocking responsibilities: the **corruption state machine** (the global degradation of the Rendered World across six escalating classes, from NOMINAL to BREACH, visible across the Campaign Map as HAZARD intensification, SCAR node proliferation, and hardware-substrate rendering bleed-through); the **boss sequencer** (three elemental gatekeeper battles through the Mainframe Spine preceding the Mirror Admin final fight); and the **ending gate** (reading the player's relic ownership flags at Mainframe Crown to resolve one of three world-reshaping outcomes, then writing `ending_id` to save data and committing the world to READ_ONLY_FREE_ROAM).

The corruption arc runs in parallel with the player's Spine approach: each gatekeeper defeat advances the corruption class by one tier. Campaign Map reads the current class on every scene load and transforms map behavior accordingly — HAZARD node icons appear, REST and LORE nodes scar over (ALERT class), the overworld visual filter degrades (CRITICAL), and at BREACH the pastoral-fantasy aesthetic is overridden by exposed hardware-substrate rendering. The Mirror Admin fight occurs at BREACH — maximum world degradation — and executes all three of its phases (PARITY → OVERCLOCK → KERNEL_PANIC) in sequence with no HP restore between phases. After the Mirror Admin is defeated, the player receives the Void dragon and faces the final choice at Mainframe Crown.

Singularity provides boss definitions consumed by Campaign Map BOSS nodes (via `boss_id` string keys), listens for Campaign Map's `matrix_stabilized()` trigger, emits `corruption_class_changed(payload)` consumed by Campaign Map and Audio Director, stages `scar_nodes[]`, `ending_id`, and the Void dragon grant through SaveTransaction-backed service helpers, and exposes the scar list Campaign Map uses to overlay corrupted traversal on affected nodes.

## Player Fantasy

The Singularity arc delivers two braided fantasies that the game has been building in parallel since the first hatch.

**The Caretaker:** The player is the only person in the Rendered World who knows the house is burning down and can still hold a door open while it does. The corruption arc does not feel like a damage counter — it feels like specific loss. REST nodes that were warm landmarks start showing their polygon seams. Lanterns that animated in 60-frame curves loop in 4. Felix's idle lines shift tense. The pastoral world is not breaking; it is *thinning*, and the player is the only one watching it happen in real time. Each gatekeeper fight is another door closing, another layer peeled. The emotional register during the Spine approach is not dread — dread is paralysis — it is protective resolve: *you stay because they need you to*.

**The Last Sysadmin:** Simultaneously, the player is the only person in the Rendered World who has been promoted. Corruption classes are not weather; they are a status board that only Skye and the Mirror Admin share a language for. Every class advance is the player *escalating on purpose* — forcing the Admin to surface, pulling the Great Reset forward into a confrontation they can control. The fight against the Mirror Admin at BREACH is a meeting between two people who read the world the same way, disagreeing about whether it can be saved or must be wiped. PARITY → OVERCLOCK → KERNEL_PANIC is the Admin's own escalation protocol: it negotiates, then overwhelms, then crashes the conversation entirely.

**The ending as prior commitment with agency for overcommitment:** Mainframe Crown does not sell the player a last-minute answer. It asks Skye to show what she already carried out of the Forge. If the player owns exactly one relic — 10mm Wrench, Diagnostic Lens, or Kernel Blade — the ending is archaeological discovery: they learn what they have been choosing through every Scrap spent, every expedition packed, every fight committed to. If the player deliberately bought multiple relics, Crown presents a final agency moment among those prior commitments: the player chose to keep more than one future alive, and now must name which tool they trust. If the player owns no relics, Crown refuses the ending gate and sends them back to Unit 01/Shop at normal relic prices; there is no discounted or free Crown relic.

> **Audio-director brief (Framing C — The Wrong Song):** The Mirror Admin's tritone weakness — 6 semitones above its current target frequency — should be treated as the game's thematic centre point, not an incidental mechanic. The corruption classes are audio degradation (bit-crush, sample-rate reduction) layered over visual degradation. The Void dragon is the dissonant note that does not belong and cannot be un-heard. This brief belongs to the Audio Director GDD before implementation begins.

## Detailed Design

### Core Rules

#### Activation

1. Singularity activates when Campaign Map reports `matrix_stabilized = true` in save data and emits `matrix_stabilized()`. Campaign Map owns this flag and signal because it owns the Elemental Matrix gate and Mainframe Spine unlock. The flag is one-way; it never resets.
2. On activation, Singularity requests Campaign Map to unlock the Mainframe Spine path and place the four BOSS nodes (three gatekeepers + Mirror Admin) and the Mainframe Crown CROWN node using the keys defined in Core Rule 10 and Rule 27. Singularity must treat repeated `matrix_stabilized()` emissions as idempotent.

#### Corruption State Machine

3. The corruption class is a global enum with six ordered values: `NOMINAL → ANOMALY → WARNING → ALERT → CRITICAL → BREACH`. It can only advance forward, never retreat.
4. The corruption class is owned by Singularity, stored in save data as `corruption_class`, and broadcast via `corruption_class_changed(new_class: CorruptionClass)` whenever it advances.
5. Advance triggers (in order): Gatekeeper 1 defeat → ANOMALY; Gatekeeper 2 defeat → WARNING; Gatekeeper 3 defeat → ALERT; Mirror Admin PARITY→OVERCLOCK phase transition → CRITICAL; Mirror Admin OVERCLOCK→KERNEL_PANIC phase transition → BREACH.
6. Mirror Admin defeat does NOT advance the corruption class. The class remains at BREACH through the ending gate sequence and all of READ_ONLY_FREE_ROAM.
7. Corruption class advance, the corresponding `scar_nodes[]` update, and the save-data write are performed atomically in a single save commit. If the save fails, both the class advance and the scar list update are rolled back and the player is notified. Singularity owns the serialized `scar_nodes[]` field; Campaign Map reads that saved list and may also call `singularity.get_scar_nodes_for_class(class) → Array[NodeID]` to rebuild or validate it during migration/debug flows.

#### Campaign Map Corruption Effects

| Class | Map Effect |
|---|---|
| NOMINAL | No change. |
| ANOMALY | HAZARD node icons appear on all HAZARD nodes. No random encounter rate changes occur; Campaign Map remains a fixed node graph. |
| WARNING | At battle start on HAZARD nodes, enemies gain the node's authored `hazard_status_effect`. Valid MVP status IDs are Battle Engine's single-slot statuses: Burn, Freeze, Paralyze, Guard Break, Poison, Blind. |
| ALERT | REST and LORE nodes begin scarring over. They remain traversable but lose their normal content/recovery behavior. Scar overlay applied per `get_scar_nodes_for_class(ALERT)`. |
| CRITICAL | Overworld visual filter degrades. Additional scar nodes applied per `get_scar_nodes_for_class(CRITICAL)`. |
| BREACH | Pastoral-fantasy aesthetic replaced by hardware-substrate rendering. All remaining non-essential nodes scarred. |

8. Campaign Map reads serialized `scar_nodes[]` on every scene load to determine the active scar overlay. The serialized list must match the pre-authored cumulative list for the current class in Singularity resource data (a `Dictionary[CorruptionClass, Array[NodeID]]` in `SingularityData.tres`).
9. Scar nodes are additive across classes: the list for CRITICAL includes all ALERT scars plus new ones. Each class's list is the full cumulative set, not a delta.

#### Boss Sequencer

10. The Mainframe Spine contains four Campaign Map BOSS nodes keyed by map-level `boss_id` string: `"gatekeeper_fire"`, `"gatekeeper_ice"`, `"gatekeeper_shadow"`, `"mirror_admin"`. Node traversal order is fixed (linear spine — no branching). Mirror Admin's internal phase profiles use separate `combat_profile_id` values and must not be used as Campaign Map node keys.
11. Gatekeeper boss definitions (BossDefinition Resource):
    - `gatekeeper_fire`: element=Fire, is_elder=false, corruption_advance=true (→ANOMALY on defeat)
    - `gatekeeper_ice`: element=Ice, is_elder=false, corruption_advance=true (→WARNING on defeat)
    - `gatekeeper_shadow`: element=Shadow, is_elder=false, corruption_advance=true (→ALERT on defeat)
12. Each gatekeeper is an authored encounter — fixed level, stats, and special move defined in their BossDefinition. Specific values are Tuning Knobs (Section G).
13. `can_access_mirror_admin() → bool`: returns true only if all three gatekeepers are defeated (`gatekeeper_fire_defeated AND gatekeeper_ice_defeated AND gatekeeper_shadow_defeated` in save data). Campaign Map enforces this gate; the Mirror Admin BOSS node is locked until it passes.
14. Gatekeeper defeat grants XP and Scraps via the standard Battle Engine post-battle reward flow. These rewards accumulate normally; spending continues in the Shop between Spine battles.

#### Mirror Admin — INIT

15. On entering the Mirror Admin BOSS node, before PARITY begins, Campaign Map/Singularity settlement restores all expedition loadout dragons to full HP. This is presented as B.I.O.S. forcing a diagnostic baseline, not Unit 01: `"DIAGNOSTIC BASELINE INITIALIZED. ALL SYSTEMS NOMINAL."` This eliminates the soft-lock risk of entering with critically low HP while preserving Unit 01's fixed Shop-counter role.
16. The Mirror Admin encounter is a single continuous Battle Engine boss encounter with mutable phase profiles. Battle Engine does not emit `battle_ended`, grant rewards, or return to Campaign Map between PARITY, OVERCLOCK, and KERNEL_PANIC. Manual saving is disabled while the encounter is active. Because CRITICAL and BREACH corruption commits occur at phase transitions, Singularity must also commit a Mirror Admin phase checkpoint at each durable phase transition. If the app closes after a successful phase checkpoint commit, the player reloads from the latest committed phase checkpoint, not the original pre-boss save. A design that always reloads pre-boss would require deferring CRITICAL/BREACH durable corruption commits until final encounter settlement; that hybrid model is forbidden by ADR-0007.

#### Mirror Admin — PARITY Phase

17. PARITY: The Mirror Admin scans the player's active lead dragon element and adopts that element for the duration of the phase. It uses standard Battle Engine AI (no scripted override).
18. PARITY→OVERCLOCK transition: triggered when Mirror Admin HP crosses the phase threshold (Tuning Knob — default 50% of base HP). On transition, the system advances corruption to CRITICAL, plays a 2-second cutscene beat, and begins OVERCLOCK automatically. No consumable use is permitted between phases.

#### Mirror Admin — OVERCLOCK Phase

19. OVERCLOCK: The Mirror Admin adopts its canonical element (Fire) regardless of player lead element. Fire represents sterilization/reset protocol, not ordinary elemental affinity. It uses a single-target high-aggression AI profile: Attack weight 70%, Status weight 20%, Defend weight 10%, preferring super-effective or highest-power available attacks. No multi-target attacks are introduced in MVP.
20. OVERCLOCK→KERNEL_PANIC transition: triggered when Mirror Admin HP crosses a second phase threshold (Tuning Knob — default 25% of base HP). On transition, the system advances corruption to BREACH, plays a 2-second cutscene beat, and begins KERNEL_PANIC automatically. No consumable use between phases.

#### Mirror Admin — KERNEL_PANIC Phase

21. KERNEL_PANIC: The Mirror Admin abandons weighted Battle Engine AI entirely. It executes a fixed scripted move sequence, looping: `kernel_panic_attack_primary → kernel_panic_status_desync → kernel_panic_attack_secondary → kernel_panic_defend_reset`. The status action applies Guard Break only; it must not apply Freeze or Paralyze because those skip the TELEGRAPH input needed for the tritone counter. The loop repeats until the Mirror Admin is defeated or the player is defeated.
22. Phase gates preserve the intended PARITY → OVERCLOCK → KERNEL_PANIC read. Mirror Admin cannot be reduced below the next phase threshold before that phase has entered. If a hit or DoT would reduce HP below `overclock_threshold_hp` during PARITY, HP is clamped to `overclock_threshold_hp`, PARITY ends, and OVERCLOCK begins. If the same damage event would also cross `kernel_panic_threshold_hp`, HP is then clamped to `kernel_panic_threshold_hp` and KERNEL_PANIC begins. Mirror Admin can only be KO'd after KERNEL_PANIC has begun and its phase-entry presentation/state settlement has completed.
23. Phase transition checks run after IMPACT damage and after each RECOIL DoT tick, before Battle Engine RESOLUTION would settle KO. On every phase transition, player and boss statuses, pending skip registrations, and Defend cooldowns are cleared. Mirror Admin is immune to Freeze, Paralyze, and Blind; Burn, Poison, and Guard Break may apply but are cleared at phase transitions.
24. Tritone weakness is player-facing during KERNEL_PANIC. After each `kernel_panic_status_desync` action, Singularity opens `tritone_window = true` for the player's next TELEGRAPH input only. During this window, the normal Defend command becomes contextual **Counter**. Counter is available even if Defend would otherwise be on cooldown; resolving Counter applies normal Defend damage reduction for that turn, then sets the standard Defend cooldown afterward.
25. If the player selects Counter during `tritone_window`, Battle Engine resolves `tritone_counter`: Mirror Admin takes `max(1, floor(mirror_admin_base_hp × TRITONE_COUNTER_DAMAGE_RATIO))` bypassing DEF, type, crit, miss, and normal move-on-hit effects. The scripted loop advances past the next Admin Defend entry to the following Attack; no Admin Defend action or Defend cooldown is applied. If the player selects any non-Counter action, the window closes without penalty and the loop continues normally. If the player's TELEGRAPH is skipped by a status effect, the window closes with no counter and no skipped Admin action.
26. On Mirror Admin defeat, no corruption advance occurs. The system atomically writes `mirror_admin_defeated = true` and the Void dragon grant to save data, keeps the Mirror Admin BOSS node in the traversal graph as an archived terminal interaction, and emits `mirror_admin_defeated` after the commit succeeds.

#### Void Dragon Acquisition

27. On `mirror_admin_defeated`, the Void dragon is automatically added to the player's story roster. No player input is required. B.I.O.S. delivers one voice line (content is Open Question OQ-SG02; register: system notification, not reward or celebration).
28. Void dragon schema:
    - `dragon_id`: `"void_dragon"` (canonical)
    - `element`: Void
    - `level`: 30 (Stage III — provisional, OQ-SG03)
    - `base_hp`: 80 (provisional, OQ-SG03)
    - `base_atk`: 40 (canonical — established by creative-director)
    - `base_def`: 20 (provisional, OQ-SG03)
    - `base_spd`: 36 (provisional, OQ-SG03)
    - `is_shiny`: false (permanent — Void dragon cannot be shiny)
    - `type_effectiveness`: 1.0× neutral vs. all elements (provisional, OQ-SG04)
29. The Void dragon is visible at Crown as proof that the Admin's protocol was disrupted, but it is not itself an ending selector. It participates in battles after ending resolution and occupies a reserved `story_roster` slot outside normal Hatchery/Fusion capacity.

#### Ending Gate

30. After the Void dragon is granted, the player is navigated to Mainframe Crown. Mainframe Crown is a CROWN node type (not BOSS — forward contract to Campaign Map GDD: add CROWN to the node type table and state machine). CROWN does not auto-fire MAP_BOSS_TRANSITION.
31. `can_attempt_ending() → bool`: returns true if `mirror_admin_defeated = true AND relic_count >= 1`. Campaign Map enforces the Mirror Admin gate; Singularity enforces the relic gate. If the player has defeated Mirror Admin but owns no relics, Crown displays `get_no_relic_denial_text()`, leaves `ending_id` empty, and returns the player to MAP_EXPLORE so they may backtrack to Unit 01/Shop and buy a relic at normal Shop prices.
32. Relic check on CROWN arrival:
    - **0 relics**: Crown is blocked. No emergency purchase exists at Crown. The denial message directs the player back to Unit 01/Shop without naming an ending.
    - **1 relic**: The relic is automatically presented. The archaeological fantasy is intact — the player learns what they chose. The Mirror Admin residual process speaks its relic-specific final line.
    - **2–3 relics**: All owned relics are displayed. The player selects one. This is explicit final agency among prior commitments: the player chose to keep multiple futures alive earlier, and Crown now asks which one Skye trusts. The Mirror Admin residual process's relic-specific final line fires for whichever relic is selected.
33. Relic-specific Admin final lines are delivered by a residual Mirror Admin process, not a still-active boss. Content is OQ-SG06, to be written by Writer GDD:
    - 10mm Wrench → `"Ah. The Wrench. I should have guessed."`
    - Diagnostic Lens → `[Writer GDD]`
    - Kernel Blade → `[Writer GDD]`
34. After relic selection/presentation, the residual Admin final line must be marked complete before `ending_id` is committed. Ending IDs: `"total_restore"` (10mm Wrench), `"the_patch"` (Diagnostic Lens), `"hardware_override"` (Kernel Blade). The ending cutscene fires based on `ending_id`.
35. `get_ending_denial_text() → String`: returns the contextually appropriate denial message if the player attempts to access Crown before `mirror_admin_defeated` (e.g., `"CROWN NODE REQUIRES CLEARANCE. MIRROR ADMIN DIAGNOSTIC INCOMPLETE."`).
36. `get_no_relic_denial_text() → String`: returns the contextually appropriate denial message if the player has defeated Mirror Admin but owns no relics (e.g., `"RESTORATION TOOL NOT REGISTERED. RETURN TO UNIT 01."`).

#### Post-Game

37. After `ending_id` is written, the world commits to `READ_ONLY_FREE_ROAM`. `ending_id != ""` is the authoritative post-game flag; Singularity does not serialize a separate `game_state = "post_game"` field. Campaign Map derives `MAP_FREE_ROAM` from non-empty `ending_id`.
38. The `restored_gold_code` shader overlay is applied to all current and future dragon sprites in the roster display, battle renderer, hatchery, and post-game detail views. Layering order: base sprite → shiny tint (if `is_shiny = true`) → gold-code overlay. The overlay is a cosmetic shader with no stat effect. All dragons including the Void dragon receive the overlay.
39. Post-game presentation is ending-specific:
    - `"total_restore"`: Felix, Weaver, Unit 01, and the active pre-ending dragon are archived from active memory; Shop becomes an automated archive terminal, not Unit 01 at the counter.
    - `"the_patch"`: Felix, Weaver, Unit 01, B.I.O.S., and dragons remain recognized citizens; Shop remains Unit 01-operated.
    - `"hardware_override"`: Mirror Admin is silenced, Threadfall persists, and NPC availability remains unstable but accessible through glitch-terminal variants.
40. The Mirror Admin's BOSS node on the Spine map remains in the graph but opens an archived terminal readout displaying post-game stats/content (exact content is OQ-SG07).
41. XP and Scrap accrual continue normally in READ_ONLY_FREE_ROAM for replay-eligible COMBAT, HAZARD, and gatekeeper BOSS nodes. Mirror Admin never replays. Replay reward caps are owned by Campaign Map/Battle reward data, but Singularity requires defeated flags and corruption advances to remain unchanged by replay.
42. Post-game shop access remains available according to the ending-specific presentation in Rule 39. Unowned relics are hidden or shown as archived/inert memorabilia after `ending_id != ""`; they cannot be purchased after an ending is committed.
43. `gatekeeper_[id]_defeated` and `mirror_admin_defeated` flags remain true permanently. Re-entering cleared gatekeeper BOSS nodes uses Campaign Map's Replay prompt; replay victories do not rewrite defeated flags, advance corruption, or re-emit first-time milestone signals.

### States and Transitions

#### Corruption Class

| State | Enter Condition | Map Effect Summary | Exits To |
|---|---|---|---|
| NOMINAL | Game start (default) | No change | ANOMALY (Gatekeeper 1 defeated) |
| ANOMALY | Gatekeeper 1 defeated | HAZARD icons visible; fixed graph unchanged | WARNING (Gatekeeper 2 defeated) |
| WARNING | Gatekeeper 2 defeated | HAZARD battle-start enemy status effect | ALERT (Gatekeeper 3 defeated) |
| ALERT | Gatekeeper 3 defeated | REST/LORE nodes begin scarring | CRITICAL (Mirror Admin PARITY→OVERCLOCK) |
| CRITICAL | Mirror Admin PARITY→OVERCLOCK | Overworld filter degrades | BREACH (Mirror Admin OVERCLOCK→KERNEL_PANIC) |
| BREACH | Mirror Admin OVERCLOCK→KERNEL_PANIC | Hardware-substrate rendering; maximum scar | (terminal — no exit) |

#### Mirror Admin Phase

| Phase | `combat_profile_id` | HP Pool | Element | AI Mode | Corruption Advance |
|---|---|---|---|---|---|
| PARITY | `"mirror_admin_parity"` | Full base HP | Mirrors player lead | Standard Battle Engine AI | None |
| OVERCLOCK | `"mirror_admin_overclock"` | Continues from PARITY (no restore) | Fire (canonical) | High-aggression AI profile | CRITICAL (on phase enter) |
| KERNEL_PANIC | `"mirror_admin_kernel_panic"` | Continues from OVERCLOCK (no restore) | Fire (canonical) | Fixed scripted sequence | BREACH (on phase enter) |

#### Ending Gate

| State | Condition | Player Input | Next State |
|---|---|---|---|
| CROWN_BLOCKED | `mirror_admin_defeated = false` | None — Crown inaccessible | CROWN_ARRIVE (on mirror_admin_defeated) |
| CROWN_ARRIVE | `mirror_admin_defeated = true` | Enters CROWN node | ZERO_RELIC / ONE_RELIC / MULTI_RELIC |
| ZERO_RELIC | 0 relics owned | Denial text only; return to MAP_EXPLORE | CROWN_ARRIVE after Shop relic purchase |
| ONE_RELIC | Exactly 1 relic owned | Relic automatically presented; no input | ENDING_RESOLVE |
| MULTI_RELIC | 2–3 relics owned | Player selects one relic from owned set | ENDING_RESOLVE |
| ENDING_RESOLVE | Relic selected | None — `ending_id` committed; cutscene fires | (terminal — READ_ONLY_FREE_ROAM) |

### Interactions with Other Systems

| System | Direction | Interface |
|---|---|---|
| **Campaign Map** | Bidirectional | Campaign Map owns `matrix_stabilized` and emits `matrix_stabilized()`; Singularity listens and requests Spine boss placement/unlock plus Mainframe Crown placement. Singularity emits `corruption_class_changed(payload)` and `ending_resolved(ending_id)`, owns serialized `scar_nodes[]` mutation through SaveTransaction-backed settlement, and exposes: `can_access_mirror_admin() → bool`, `get_scar_nodes_for_class(class) → Array[NodeID]`, `can_attempt_ending() → bool`, `get_ending_denial_text() → String`, and `get_no_relic_denial_text() → String`. Campaign Map owns the CROWN node type and must not route it through MAP_BOSS_TRANSITION. |
| **Battle Engine** | Singularity → Battle Engine | Singularity provides BossDefinition Resources for all four Spine bosses (consumed via map-level `boss_id` key). Mirror Admin's internal phase resources use `combat_profile_id`; Battle Engine keeps one continuous encounter open while Singularity changes phase profile, clamps phase thresholds, opens the tritone counter window, and suppresses `battle_ended` until final KO or player defeat. |
| **Dragon Progression** | Singularity → Dragon Progression | Void dragon uses a reserved story-roster slot with `element = Void`, neutral type treatment, and standard XP/stat progression after acquisition. Hatchery/Fusion must not generate Void or shiny Void. |
| **Shop** | Shop → Singularity | Shop is the only normal source for relic ownership flag activation (`relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned`) through its purchase transaction. Singularity reads these flags at Crown arrival and never stages an emergency relic flag or discounted Crown purchase. Shop does not call Singularity directly. |
| **Save/Persistence** | Bidirectional | Singularity owns these save-data fields: `corruption_class`, `scar_nodes[]`, `mirror_admin_defeated`, `gatekeeper_[id]_defeated` (×3), `ending_id`, and Void story-roster grant state. Campaign Map owns `matrix_stabilized` and derives `MAP_FREE_ROAM` from `ending_id`. Save/Persistence must guarantee atomic write for corruption class advance + `scar_nodes[]`, Mirror Admin defeat + Void grant, and ending commit. |
| **Audio Director** | Singularity → Audio Director | Singularity emits transition/audio requests with old/new class, trigger source, boss/phase context, phase-skip flag, and transition beat IDs. During `tritone_counter`, Audio Director plays the 6-semitone counter-tone required by Core Rules 24–25. Audio Director subscribes to drive music/sfx transitions and corruption degradation. |
| **Journal/Console** | Singularity → Journal | Singularity emits milestone signals (`gatekeeper_defeated(boss_id)`, `mirror_admin_defeated`, `ending_resolved(ending_id)`) that Journal/Console subscribes to for lore fragment delivery. |

### Signal Schemas

| Signal | Owner | Payload | Consumers | Notes |
|---|---|---|---|---|
| `matrix_stabilized()` | Campaign Map | none | Singularity | Fires when Campaign Map detects all six elemental dragons collected and sets its persistent matrix flag. Singularity handling is idempotent. |
| `corruption_class_changed(payload)` | Singularity | `{ old_class: StringName, new_class: StringName, trigger_source: StringName, boss_id: StringName, phase_from: StringName, phase_to: StringName, is_phase_skip: bool, transition_beat_id: StringName }` | Campaign Map, Audio Director | Queued during state settlement and emitted only after the save commit for the new class + `scar_nodes[]` succeeds. |
| `gatekeeper_defeated(boss_id)` | Singularity/Battle settlement | `boss_id: StringName` using `"gatekeeper_fire"`, `"gatekeeper_ice"`, or `"gatekeeper_shadow"` | Journal/Console, Campaign Map | Emitted after post-battle rewards and the defeated flag are committed. |
| `mirror_admin_defeated()` | Singularity/Battle settlement | none | Campaign Map, Audio Director, Journal/Console | Emitted after the atomic commit that stages `mirror_admin_defeated = true` and grants the Void dragon. |
| `ending_resolved(ending_id)` | Singularity | `ending_id: StringName` using `"total_restore"`, `"the_patch"`, or `"hardware_override"` | Campaign Map, Journal/Console, Audio Director | Emitted after the relic-specific final line completes and `ending_id` is committed. |
| `mirror_admin_phase_changed(payload)` | Singularity | `{ phase_from: StringName, phase_to: StringName, current_hp: int, threshold_hp: int, is_phase_skip: bool }` | Battle Engine UI, Audio Director | Emitted after phase state is settled. |
| `tritone_window_changed(is_open, reason)` | Singularity | `is_open: bool`, `reason: StringName` (`opened`, `counter_resolved`, `missed`, `telegraph_skipped`, `expired`) | Battle Engine UI, Audio Director | Drives visual Counter affordance and audio telegraph/cancel cues. |
| `tritone_counter_resolved(payload)` | Singularity/Battle settlement | `{ target_pitch_id: StringName, counter_pitch_id: StringName, damage: int, skipped_admin_action: StringName }` | Audio Director, Battle Engine UI | Counter pitch is six semitones above target pitch. |
| `hazard_status_primed(payload)` | Singularity/Campaign Map | `{ node_id: StringName, hazard_status_effect: StringName, corruption_class: StringName }` | Battle Engine, Audio Director | Fired before HAZARD battle start at WARNING+. |

### Data Contracts

| Resource/Data | Owner | Required Fields | Consumers |
|---|---|---|---|
| `SingularityData.tres` | Singularity | `scar_class_definitions: Array[ScarClassDefinition]`, `boss_definitions: Array[BossDefinition]`, `mirror_admin_phase_profiles: Array[MirrorAdminPhaseProfile]`, `ending_definitions: Array[EndingDefinition]` | Campaign Map, Battle Engine, Save/Persistence |
| `ScarClassDefinition` | Singularity Resource | `corruption_class: StringName`, `scar_node_ids: Array[StringName]`, `protected_node_ids: Array[StringName]` | Singularity, Campaign Map validation |
| `BossDefinition` | Singularity Resource | `boss_id: StringName`, `display_name: String`, `element: StringName`, `level: int`, `boss_stage_mult: float`, `base_xp: int`, `scrap_reward: int`, `replay_reward_policy: StringName`, `corruption_advance: StringName`, `combat_profile_id: StringName` | Battle Engine, Campaign Map |
| `MirrorAdminPhaseProfile` | Singularity Resource | `combat_profile_id: StringName`, `phase: StringName`, `element_rule: StringName`, `ai_profile: StringName`, `scripted_loop: Array[StringName]`, `target_pitch_id: StringName`, `tritone_window_rule: StringName`, `phase_threshold_ratio: float` | Battle Engine, Audio Director |
| `EndingDefinition` | Singularity Resource | `ending_id: StringName`, `relic_flag: StringName`, `cutscene_id: StringName`, `post_game_profile_id: StringName`, `survivorship_profile_id: StringName` | Campaign Map, Journal/Console, Audio Director |
| `SaveData` fields | Save/Persistence | `corruption_class`, `scar_nodes[]`, `gatekeeper_[id]_defeated`, `mirror_admin_defeated`, `void_dragon_granted`, `ending_id` | Singularity, Campaign Map, Journal/Console |

## Formulas

### F-1: Boss Base Stat Formula

**Purpose:** Determines the base stat for any gatekeeper or Mirror Admin boss at a given
level and stat category.

**Variables:**

| Variable | Type | Source | Description |
|---|---|---|---|
| `dragon_base_stat(element, stat)` | Int | Dragon Progression GDD | Level-1 base stat for the given element and stat. Must be ≥ 1 for all element/stat combinations. |
| `STAT_INCREMENT` | Int | Dragon Progression GDD | 3 stat points per level after level 1. |
| `BOSS_STAT_MULT` | Float | Tuning Knob | Global boss difficulty multiplier. Default 1.5, safe range 1.0–2.0 |
| `element` | Enum | BossDefinition | Fire, Ice, or Shadow (gatekeepers); Fire or mirrored player element (Mirror Admin) |
| `stat` | Enum | BossDefinition | hp, atk, def, or spd |
| `level` | Int | BossDefinition (Tuning Knob) | Boss level, 1–60. Mirror Admin defaults to 55. |
| `boss_stage_mult` | Float | BossDefinition | Battle Engine damage `stageMult` for the boss. Defaults to Dragon Progression stage for `level`; Mirror Admin level 55 uses 1.4. This is used only by Battle Engine damage, not by stat generation. |

**Formula:**
```
level_scaled_stat(element, stat, level) =
    floor(dragon_base_stat(element, stat) + ((level - 1) × STAT_INCREMENT))

boss_base_stat(element, stat, level) =
    max(1, floor(level_scaled_stat(element, stat, level) × BOSS_STAT_MULT))
```

**Invariant:** `dragon_base_stat(element, stat) ≥ 1` for all element/stat combinations
(Dragon Progression GDD must enforce). Bosses are never shiny, so the Dragon Progression
`shinyMult` is not applied. Dragon Progression's `stageMult` remains a combat damage
multiplier and must not be used to scale boss HP/ATK/DEF/SPD.

**Expected output ranges** (base stat 40 reference, `BOSS_STAT_MULT = 1.5`):

| Level | Level-scaled stat | Boss stat |
|---|---|---|
| 1 | 40 | 60 |
| 30 | 127 | 190 |
| 55 | 202 | 303 |

**Example Calculation** (Gatekeeper Fire, level=20, stat=atk,
hypothetical `dragon_base_stat(Fire, atk)=28`):
```
level_scaled_atk = floor(28 + ((20 - 1) × 3)) = 85
BOSS_STAT_MULT = 1.5    [default]
boss_base_atk = max(1, floor(85 × 1.5)) = 127
```

**Mirror Admin level note:** Mirror Admin level defaults to 55 to produce a credible
endgame HP pool from Dragon Progression's level-based stat curve without incorrectly
borrowing combat-stage damage multipliers for stat generation. At Fire `base_hp = 110`,
the level-scaled HP is `272` and Mirror Admin base HP is `408`. PARITY mirrors the
player lead's element for type display and type effectiveness only; Mirror Admin's HP,
ATK, DEF, SPD, thresholds, and reward profile remain based on canonical Fire boss stats.

**Dependency:** `dragon_base_stat(element, stat)` values and `STAT_INCREMENT = 3` are
owned by the approved Dragon Progression GDD. Singularity only applies boss-specific
encounter tuning through `BOSS_STAT_MULT`.

---

### F-2: Mirror Admin Phase Transition Thresholds

**Purpose:** HP values at which the Mirror Admin transitions between PARITY, OVERCLOCK,
and KERNEL_PANIC phases.

**Variables:**

| Variable | Type | Description |
|---|---|---|
| `mirror_admin_base_hp` | Int | Computed via F-1: element=Fire, stat=hp, level=Mirror Admin level |
| `OVERCLOCK_THRESHOLD_RATIO` | Float | Tuning Knob. Default 0.5, safe range 0.3–0.7 |
| `KERNEL_PANIC_THRESHOLD_RATIO` | Float | Tuning Knob. Default 0.25, safe range 0.1–0.4. Must be strictly less than `OVERCLOCK_THRESHOLD_RATIO`. |
| `current_hp` | Int | Mirror Admin's current HP during combat |

**Formulas:**
```
overclock_threshold_hp    = max(1, floor(mirror_admin_base_hp × OVERCLOCK_THRESHOLD_RATIO))
kernel_panic_threshold_hp = max(1, floor(mirror_admin_base_hp × KERNEL_PANIC_THRESHOLD_RATIO))

Transition fires when: current_hp ≤ threshold_hp
```

The `max(1, …)` floor guarantees thresholds never collapse to 0 regardless of HP pool size.

**Startup invariant (assert on load):**
```
assert(KERNEL_PANIC_THRESHOLD_RATIO < OVERCLOCK_THRESHOLD_RATIO)
```
Runtime config overrides must validate before applying.

**Phase gate rule:** If a single damage application reduces `current_hp` from above
`overclock_threshold_hp` to at or below `kernel_panic_threshold_hp`, both transitions
settle in the same logic tick, but HP is clamped at each phase gate. State settlement order:
1. Clamp HP to `overclock_threshold_hp`; set phase = OVERCLOCK
2. Commit CRITICAL corruption state
3. Clamp HP to `kernel_panic_threshold_hp`; set phase = KERNEL_PANIC
4. Commit BREACH corruption state
5. Emit queued transition signals after all required save commits succeed

Mirror Admin cannot be KO'd until KERNEL_PANIC phase-entry settlement completes. This
preserves the Admin's negotiation → overwhelm → crash fantasy even when player damage
would otherwise one-shot through thresholds.

**Expected outputs** (mirror_admin_base_hp = 408, level=55, Fire base_hp=110):

| Threshold | Formula | Result |
|---|---|---|
| OVERCLOCK trigger | max(1, floor(408 × 0.5)) | 204 HP |
| KERNEL_PANIC trigger | max(1, floor(408 × 0.25)) | 102 HP |

**Example Calculation:**
```
mirror_admin_base_hp = 408, OVERCLOCK_THRESHOLD_RATIO = 0.5,
KERNEL_PANIC_THRESHOLD_RATIO = 0.25

overclock_threshold_hp    = max(1, floor(408 × 0.5))  = 204
kernel_panic_threshold_hp = max(1, floor(408 × 0.25)) = 102
```

---

### F-3: Crown Relic Availability

**Purpose:** Determines whether Mainframe Crown can resolve an ending.

**Variables:**

| Variable | Type | Description |
|---|---|---|
| `relic_wrench_owned` | Bool | Shop-owned persistent flag for 10mm Wrench. |
| `relic_lens_owned` | Bool | Shop-owned persistent flag for Diagnostic Lens. |
| `relic_blade_owned` | Bool | Shop-owned persistent flag for Kernel Blade. |

**Expressions:**
```
relic_count =
    int(relic_wrench_owned) + int(relic_lens_owned) + int(relic_blade_owned)

can_attempt_ending =
    mirror_admin_defeated == true AND relic_count >= 1
```

There is no Crown relic purchase, discount, or free allocation. Relic flags are written
only by Shop/Save-Persistence purchase transactions. With `relic_count == 0`, Crown
shows denial text and returns the player to map control.

**Expected outcomes:**

| relic_count | Crown result |
|---|---|
| 0 | Blocked; no `ending_id` written. |
| 1 | Owned relic auto-presented. |
| 2–3 | Owned relics displayed for final selection. |

---

### F-4: Void Dragon Stat Block (Authored Fixed Values)

**Purpose:** Canonical level-1 base stats for the Void dragon. These authored base values
enter the standard Dragon Progression level formula; they are not produced by Hatchery or
Fusion because the Void dragon arrives fully formed at the moment of world-change.

| Stat | Value | Status |
|---|---|---|
| `base_hp` | 80 | Provisional (OQ-SG03) |
| `base_atk` | 40 | **Canonical** (creative-director) |
| `base_def` | 20 | Provisional (OQ-SG03) |
| `base_spd` | 36 | Provisional (OQ-SG03) |
| `level` | 30 | Provisional (OQ-SG03) |
| `is_shiny` | false | **Canonical** (permanent invariant) |

Level=30 is Stage III (levels 25–49). In-play stats at acquisition are computed from the
base values above using Dragon Progression's normal level-scaling formula. Stats continue
scaling if XP is applied post-game.

**Invariant:** `is_shiny = false` must be enforced by Dragon Progression at the schema
level for `dragon_id = "void_dragon"`. Shiny generation logic must explicitly exclude Void.

---

### F-5: Tritone Counter Damage

**Purpose:** Defines the optional KERNEL_PANIC counter created by Mirror Admin's
tritone weakness.

**Variables:**

| Variable | Type | Description |
|---|---|---|
| `mirror_admin_base_hp` | Int | Computed via F-1 before phase thresholds are applied. |
| `TRITONE_COUNTER_DAMAGE_RATIO` | Float | Tuning Knob. Default 0.08, safe range 0.05-0.12. Must be less than `KERNEL_PANIC_THRESHOLD_RATIO`. |

**Formula:**
```
tritone_counter_damage =
    max(1, floor(mirror_admin_base_hp × TRITONE_COUNTER_DAMAGE_RATIO))
```

The damage bypasses DEF and type effectiveness because it is a protocol disruption, not
an elemental attack. It must not crit, miss, or trigger normal move-on-hit effects.
Startup config validation must assert `TRITONE_COUNTER_DAMAGE_RATIO < KERNEL_PANIC_THRESHOLD_RATIO`
so one counter cannot exceed the entire intended KERNEL_PANIC HP window at safe-range extremes.

## Edge Cases

**EC-SG-01 — Gatekeeper skipped via save manipulation or Campaign Map bug:**
`can_access_mirror_admin()` checks `gatekeeper_fire_defeated AND gatekeeper_ice_defeated
AND gatekeeper_shadow_defeated` from save data on every Mirror Admin node access attempt.
If any flag is false, the node remains locked regardless of physical position on the Spine.
No gatekeeper can be retroactively marked defeated by skipping; only Singularity's
post-battle settlement stages these flags after receiving Battle Engine payloads.

**EC-SG-02 — Session crash between corruption class advance and save commit:**
Corruption advance and serialized `scar_nodes[]` update are atomic (Core Rule 7). If a crash occurs
mid-commit, the pre-advance class is restored from the last clean save. The player
re-defeats the gatekeeper or re-crosses the phase threshold on the next session; the
advance fires again correctly. Because `corruption_class` and `scar_nodes[]` are committed
in the same transaction, there is no risk of a scar state/class mismatch after a partial
write.

**EC-SG-03 — Party enters Mirror Admin node with 0 HP on all dragons (e.g., loaded a
save with a full-KO state):**
INIT restores all party HP to full before the PARITY phase begins (Core Rule 15). The
restore fires on node-enter, unconditionally, before any combat logic executes. A party
at 0 HP is not in combat — the restoration precedes the first Battle Engine call. Full-KO
save states are theoretically possible if a crash occurs mid-battle elsewhere on the Spine;
INIT handles this case.

**EC-SG-04 — Player exits the Crown node without completing relic selection:**
If the player navigates away from Mainframe Crown mid-flow (back input, game crash),
`mirror_admin_defeated = true` persists and `can_attempt_ending()` still returns true on
re-entry. The ending gate restarts from the beginning: relic count is re-checked,
zero relics re-show the denial, one relic auto-presents, and multiple relics re-open the
selection row. No partial ending state is committed — `ending_id` is only committed after a
relic is confirmed and its residual Admin line completes. Re-entry is always safe.

**EC-SG-05 — Player reaches Crown with zero relics:**
The Crown denial path stages no save changes. It does not deduct Scraps, set relic flags,
open a relic purchase UI, or commit an ending. The player remains free to backtrack to
Unit 01/Shop and buy a relic at normal price. Re-entering Crown re-reads the current
relic flags from save data.

**EC-SG-06 — Player owns all three relics at Crown:**
All three relics are displayed in the selection screen. The player must explicitly select
one. The selected relic's `ending_id` is written. The other two relics remain as owned
items in the player's inventory through READ_ONLY_FREE_ROAM — they have no
post-game mechanical function. Only one ending fires per playthrough.

**EC-SG-07 — Void dragon granted when dragon roster is at maximum capacity:**
The Void dragon is granted automatically and must not be silently dropped. Resolution:
the Void dragon occupies a reserved story-roster slot outside the normal roster capacity
limit. Dragon Progression GDD is the authoritative owner of roster capacity rules and
must preserve this story-slot grant path for `dragon_id = "void_dragon"`.

**EC-SG-08 — Single hit reduces Mirror Admin HP through both phase thresholds
simultaneously (phase skip):**
Both phase transitions settle in order using the phase-gate rule defined in F-2:
PARITY→OVERCLOCK (emit CRITICAL), then OVERCLOCK→KERNEL_PANIC (emit BREACH). The Mirror
Admin may not take an OVERCLOCK combat turn in this edge case, but the player still sees
a legible intermediate state change before KERNEL_PANIC begins. The full 2-second
OVERCLOCK beat may be shortened; it must not be silently skipped.

**EC-SG-09 — Consumable use during KERNEL_PANIC vs. between phases:**
The "no consumables between phases" restriction (Core Rule 18, 20) applies only to the
2-second transition beat between phases — not within a phase. During KERNEL_PANIC combat
itself, the player may use consumables normally. The Mirror Admin's fixed scripted sequence
does not interact with or detect player consumable use.

**EC-SG-09a — Player uses an item during a tritone window:**
Only Defend resolves `tritone_counter`. If the player uses a consumable or any non-Defend
action during `tritone_window = true`, the window closes, the action resolves normally, and
the Mirror Admin continues its scripted loop. No counter damage is applied and no penalty is
added.

**EC-SG-10 — Player attempts Mirror Admin while severely underleveled:**
Singularity does not gate Mirror Admin access by player level — only by
`can_access_mirror_admin()` (all three gatekeepers defeated). An underleveled party will
likely be defeated by the Mirror Admin. Defeat returns the player to the last save point;
they may grind, return, and retry. The Mirror Admin's HP and thresholds are fixed for the
session — no level scaling based on player progress after the encounter is entered.

**EC-SG-11 — Player re-enters Crown node in READ_ONLY_FREE_ROAM:**
If `ending_id != ""` (ending already resolved), the Crown node displays post-game terminal
content (OQ-SG07) rather than the relic selection flow. `can_attempt_ending()` is not
called — the node-enter handler checks `ending_id` first and short-circuits to post-game
mode. The relic selection screen is never shown again after an ending is committed.

**EC-SG-12 — `matrix_stabilized()` fires while player is mid-traversal on the Spine:**
If the sixth dragon is collected during a session where the player is already on the
Mainframe Spine, Campaign Map owns the `matrix_stabilized` save flag and emits
`matrix_stabilized()` mid-session. Singularity must handle this signal at any point and
request BOSS placement idempotently: BOSS nodes for all four Spine bosses must be placed on
the next scene load if not already present. Already-traversed nodes are not re-added.
This is a forward contract to Campaign Map GDD — it must specify its `matrix_stabilized()`
emission and Spine placement handler as scene-load-safe.

**EC-SG-13 — OVERCLOCK_THRESHOLD_RATIO and KERNEL_PANIC_THRESHOLD_RATIO set to equal
values via runtime config override (startup assert bypassed):**
If the ratios are equal, both thresholds share the same HP value. On reaching that HP,
the PARITY→OVERCLOCK transition fires, and immediately (same tick) the OVERCLOCK→KERNEL_PANIC
condition also evaluates as true — because `current_hp ≤ overclock_threshold_hp` implies
`current_hp ≤ kernel_panic_threshold_hp` when they are equal. The phase-skip logic handles
this correctly: state is advanced through OVERCLOCK to KERNEL_PANIC in one tick. The fight
effectively has no OVERCLOCK phase. This is unintended but not catastrophic — the startup
assert is the primary guard. Any config pipeline that bypasses it must be treated as a bug.

**EC-SG-14 — Gatekeeper defeated while Mirror Admin fight is in progress (impossible
by design, verified):**
Gatekeepers are defeated before Mirror Admin is accessible (`can_access_mirror_admin()` gate).
The four Spine nodes are linear — the player cannot re-enter a completed gatekeeper node
while inside the Mirror Admin fight. This edge case cannot occur and requires no runtime handling.

## Dependencies

Dependencies are bidirectional where noted. Support GDD contracts are Approved as of
the 2026-05-26 lean blocker-clearing review pass.

### Upstream (Singularity reads from these systems)

**Dragon Progression GDD**
- Singularity reads: dragon element/stat schema (for Void dragon
  schema compatibility), level-based stat formula with `STAT_INCREMENT = 3` (for boss stat F-1), `xp_threshold_for()`
  (used in post-battle XP flow for gatekeepers, via Battle Engine)
- Singularity requires Dragon Progression to enforce: `dragon_base_stat(element, stat) ≥ 1` for
  all elements including Void; `is_shiny = false` for `dragon_id = "void_dragon"`; reserved
  story-roster slot for mandatory story dragons (EC-SG-07)
- Dragon Progression references Singularity as the upstream story grant for Void and the downstream consumer of its schema and stat formula.

**Shop GDD** *(Approved — Revision 4, 2026-05-26)*
- Singularity reads: `relic_wrench_owned`, `relic_lens_owned`, `relic_blade_owned` flags
  (from save data, written by Shop)
- Shop is a pure upstream source — it does not call Singularity directly
- Shop GDD already references Singularity in its Cross-GDD Contracts section

**Save/Persistence GDD** *(Approved — lean contract draft, 2026-05-26)*
- Singularity reads: all its own save-data fields on session load
  (`corruption_class`, `scar_nodes[]`, `mirror_admin_defeated`,
  `gatekeeper_[id]_defeated` ×3, `void_dragon_granted`, `ending_id`)
- Singularity requires Save/Persistence to guarantee: atomic write for corruption class
  advance + `scar_nodes[]`; atomic write for Mirror Admin defeat + Void dragon grant;
  single-write commit for `ending_id`
- Save/Persistence references Singularity as its most complex atomic-write consumer and defines the required failure injection hooks.

---

### Downstream (these systems read from Singularity)

**Campaign Map GDD** *(Approved — Revision 5, 2026-05-24)*
- Campaign Map owns: `matrix_stabilized` save flag and `matrix_stabilized()` signal
- Campaign Map reads: serialized `scar_nodes[]`, `corruption_class_changed(payload)` (signal),
  `ending_resolved(ending_id)` (signal), `can_access_mirror_admin()`, `get_scar_nodes_for_class()`
  for migration/debug validation, `can_attempt_ending()`, `get_ending_denial_text()`
- Campaign Map provides: Spine BOSS node infrastructure, BOSS node auto-fire behavior
- **Campaign Map contract requirements:**
  - CROWN node type is distinct from BOSS and does not auto-fire MAP_BOSS_TRANSITION
  - Specify `matrix_stabilized()` emission and Spine placement handler as scene-load-safe (EC-SG-12)
  - Preserve Campaign Map ownership of `scar_nodes[]` consumption while Singularity owns serialized mutation through SaveTransaction-backed settlement
- Campaign Map GDD references Singularity and now includes the CROWN node type handoff.

**Battle Engine GDD** *(Approved)*
- Battle Engine reads: BossDefinition Resources for all four Spine bosses (via map-level `boss_id` key) and Mirror Admin phase profiles (via `combat_profile_id`)
- Battle Engine provides: combat execution for all boss phases plus `BattleEndedPayload` / `BattleDurableDelta` settlement output. Singularity commits `gatekeeper_[id]_defeated` and `mirror_admin_defeated` through Save / Persistence.
- **Battle Engine contract requirements:**
  - KERNEL_PANIC scripted move sequence:
    `kernel_panic_attack_primary → kernel_panic_status_desync → kernel_panic_attack_secondary → kernel_panic_defend_reset`
  - `tritone_counter` execution window and damage resolution (Core Rules 24-25 / F-5)
  - High-aggression AI profile for OVERCLOCK phase: Attack 70%, Status 20%, Defend 10%
  - Synchronous vs. deferred signal handling guarantee (to satisfy F-2 phase-skip listener rule)

**Dragon Progression GDD** *(Approved)*
- Dragon Progression reads: Void dragon entry written by Singularity to save data
- Dragon Progression provides: standard level-scaling formula applied to Void dragon's
  authored base stats post-game

**Mirror Admin**
- Mirror Admin is not a separate GDD for the current architecture. Its encounter design,
  phase state, tritone weakness, and boss data contracts are owned by Singularity. The
  systems index may keep a Mirror Admin tracking row for visibility, but implementation
  should reference this GDD unless the team later decides to split the boss into its own
  approved document.

**Audio Director GDD** *(Approved — lean contract draft, 2026-05-26)*
- Audio Director reads: `corruption_class_changed(payload)` and `mirror_admin_defeated` signals
- Audio Director provides: music/SFX transitions keyed to corruption class; tritone counter-tone
  playback (6 semitones above Mirror Admin's target tone); audio degradation layering
  (per Player Fantasy Framing C brief)
- Audio Director references Singularity as the source of its primary corruption, phase, and tritone signals.

**Journal/Console GDD** *(Approved — lean contract draft, 2026-05-26)*
- Journal reads: `gatekeeper_defeated(boss_id)`, `mirror_admin_defeated`,
  `ending_resolved(ending_id)` signals
- Journal provides: lore fragment delivery triggered by these milestones
- Journal references Singularity as a milestone event source and owns terminal readout delivery.

**Input Router GDD** *(Approved — lean contract draft, 2026-05-26)*
- Input Router provides: d-pad navigation, face-button confirm/cancel, and battle-action input
  semantics for Crown flow, boss entry screens, KERNEL_PANIC loop display, and `tritone_window`
  Defend selection
- Singularity requires Input Router to preserve controller-only completion for all Crown and
  Mirror Admin flows; no hover-only or keyboard-only path may be required
- Input Router references Singularity as an endgame UI/input consumer and defines controller-only completion rules.

---

### Visual/Shader Systems *(governed by ADR-0011)*
- The `restored_gold_code` shader overlay is a rendering dependency. Shader must be
  applied to all dragon sprites on `ending_id != ""` load. This is governed by the
  Corruption Rendering Pipeline ADR and implemented as presentation-only visual state,
  not gameplay state.

## Tuning Knobs

All knobs marked **Provisional** are subject to revision after Dragon Progression
GDD and Campaign Map pacing are finalized. Knobs marked **Canonical** are locked.

### Boss Difficulty

| Knob | Default | Safe Range | Gameplay Effect |
|---|---|---|---|
| `BOSS_STAT_MULT` | 1.5 | 1.0–2.0 | Global multiplier on all boss stats after Dragon Progression level scaling (F-1). Lower values ease all Spine bosses simultaneously; higher values increase across the board. Do not multiply by `stageMult`; that value belongs to combat damage calculation, not boss stat generation. |
| Gatekeeper Fire level | 20 *(provisional)* | 10–29 (Stage II) | Sets Gatekeeper 1 stats via F-1. Should be set so a typical player arriving at Fire with a mid-game party faces a meaningful challenge. Adjust after Dragon Progression XP curve is finalized. |
| Gatekeeper Ice level | 30 *(provisional)* | 25–44 (Stage III) | Sets Gatekeeper 2 stats via F-1. Player should have one or more Stage III dragons by this point. |
| Gatekeeper Shadow level | 40 *(provisional)* | 25–44 (Stage III) | Sets Gatekeeper 3 stats via F-1. Final pre-Mirror Admin fight; player should have a full Stage III party. |
| Mirror Admin level | 55 *(provisional)* | 50–60 | Sets Mirror Admin HP and phase threshold values via F-1 and F-2. Lowering level reduces the level-scaled HP/ATK/DEF/SPD curve directly. |

### Mirror Admin Phase Thresholds

| Knob | Default | Safe Range | Gameplay Effect |
|---|---|---|---|
| `OVERCLOCK_THRESHOLD_RATIO` | 0.5 | 0.3–0.7 | HP ratio that triggers PARITY→OVERCLOCK. Higher values give PARITY a shorter window; lower values extend it. Must be strictly greater than `KERNEL_PANIC_THRESHOLD_RATIO`. |
| `KERNEL_PANIC_THRESHOLD_RATIO` | 0.25 | 0.1–0.4 | HP ratio that triggers OVERCLOCK→KERNEL_PANIC. Lower values extend OVERCLOCK; higher values shorten it. Must be strictly less than `OVERCLOCK_THRESHOLD_RATIO`. At 0.4 (max), OVERCLOCK has only a 10% HP window between the thresholds — nearly no OVERCLOCK phase. |
| `TRITONE_COUNTER_DAMAGE_RATIO` | 0.08 | 0.05–0.12 | Percent of Mirror Admin base HP dealt by a successful KERNEL_PANIC Defend counter during `tritone_window`. Higher values make the weakness more central; lower values keep it as a useful but optional mastery mechanic. |

**Ordering invariant (enforced at startup):** `KERNEL_PANIC_THRESHOLD_RATIO < OVERCLOCK_THRESHOLD_RATIO`. Do not violate.

### Crown Relic Availability

| Knob | Default | Safe Range | Gameplay Effect |
|---|---|---|---|
| `MIN_RELICS_FOR_CROWN` | 1 | 1 (fixed) | Minimum owned relic count required to resolve an ending at Mainframe Crown. If the player owns 0 relics, Crown denies resolution and returns to MAP_EXPLORE. Relic acquisition remains owned by Shop at normal prices. Do not add a Crown fallback purchase. |

### Void Dragon Stats *(all provisional except `base_atk` and `is_shiny`)*

| Knob | Default | Status | Safe Range | Gameplay Effect |
|---|---|---|---|---|
| `base_hp` | 80 | Provisional (OQ-SG03) | 60–120 | Void dragon HP at acquisition (level=30, Stage III). Should be comparable to or slightly above a Stage III player dragon HP of the same tier. |
| `base_atk` | 40 | **Canonical** | — | Set by creative-director. Do not change without CD approval. |
| `base_def` | 20 | Provisional (OQ-SG03) | 15–40 | Void dragon DEF at acquisition. |
| `base_spd` | 36 | Provisional (OQ-SG03) | 25–50 | Void dragon SPD at acquisition. |
| Void dragon level | 30 | Provisional (OQ-SG03) | 25–49 (Stage III) | Affects starting in-play stats and XP accrual baseline. Raising above 49 promotes to Stage IV (mult=1.4), significantly boosting in-play stats. |

### Map Corruption (Authored Data — Not Numeric Knobs)

The scar node lists per corruption class (`get_scar_nodes_for_class()`) are authored
as a `Dictionary[CorruptionClass, Array[NodeID]]` in `SingularityData.tres`. These are
not numeric tuning knobs — they are level-design decisions about which Campaign Map nodes
scar over at each tier. Authoring these lists requires Campaign Map node IDs, which are
not available until Campaign Map layout is finalized.

| Class | Affected Node Types | Authoring Status |
|---|---|---|
| NOMINAL | None | N/A |
| ANOMALY | None (HAZARD icons added, nodes not scarred) | N/A |
| WARNING | None (status effect added to HAZARD battles, nodes not scarred) | N/A |
| ALERT | REST and LORE nodes begin scarring | Authored below |
| CRITICAL | Additional nodes scar (includes ALERT scars) | Authored below |
| BREACH | Maximum scar — all remaining non-essential nodes | Authored below |

Protected node IDs must never be written to `scar_nodes[]`: `hub_return_bulkhead`,
`act4_spine_access_gate`, `mainframe_crown`, `mainframe_spine_entry`,
`boss_gatekeeper_fire`, `boss_gatekeeper_ice`, `boss_gatekeeper_shadow`,
`boss_mirror_admin`, and `lore_elemental_resonance`.

| Class | Cumulative `scar_node_ids` |
|---|---|
| ALERT | `rest_weavers_cache_act2`, `lore_process_suspended_village` |
| CRITICAL | ALERT list + `rest_frostspire_cache`, `lore_captains_log_03`, `rest_coolant_pool_act3` |
| BREACH | CRITICAL list + `lore_weaver_fragment`, `rest_aurora_observation_deck`, `lore_captains_log_04` |

Campaign Map graph authoring must reserve these node IDs or provide a migration alias
table before implementation stories are created. The list is intentionally cumulative
and excludes the Matrix Concept LORE node so the matrix tracker cannot be lost to scarring.

### Scripted Sequence (KERNEL_PANIC)

The KERNEL_PANIC move loop is canonical:
`kernel_panic_attack_primary → kernel_panic_status_desync → kernel_panic_attack_secondary → kernel_panic_defend_reset`.
The status action applies Guard Break only. The Admin Defend entry is a normal Defend action
unless skipped by a successful tritone counter. The tritone counter window after each
`kernel_panic_status_desync` action is canonical and uses F-5; only exact player-facing
label/icon polish and final audio assets are deferred to UI/Audio implementation.

## Visual/Audio Requirements

### Corruption Class Presentation

Singularity owns the corruption class and the presentation intent for each tier.
Campaign Map, Battle Engine, Audio Director, and rendering systems consume the
class and apply the actual screen-specific effects.

| Class | Visual Requirement | Audio Requirement |
|---|---|---|
| NOMINAL | No corruption overlay. Pastoral fantasy layer remains intact. | Normal act music and ambience. |
| ANOMALY | HAZARD icons become visible on the Campaign Map. Subtle pixel shear appears at the edge of the overworld frame for 0.5s when the class changes. | A short data chirp layers over current map ambience. No music degradation yet. |
| WARNING | HAZARD battle-start status effect is telegraphed with a corrupted enemy outline before combat begins. | Battle intro gains bit-crushed transient. HAZARD status apply SFX must be audible even if combat starts quickly. |
| ALERT | Authored REST and LORE nodes scar over. SCAR nodes show static/noise overlay and no functional node icon. | REST/LORE ambience cuts out on scarred nodes; arrival produces a dry static crackle. |
| CRITICAL | Global overworld filter degrades: desaturation, pixel noise, unstable scanline cadence. Battle screen receives a matching corruption border. | Current music loses sample rate and adds intermittent dropouts. Dropouts must not obscure required feedback tones. |
| BREACH | Pastoral layer is replaced by hardware-substrate rendering on affected screens: exposed circuitry, server-rack silhouettes, phosphor glow, broken sky geometry. | Mirror Admin music enters final degradation state. Low sustained hardware tone remains under all UI, including Crown flow. |

Corruption-class transitions are not modal. They are world reactions: a short
visual/audio beat plays, the HUD updates, and player control resumes automatically.
The transition beat should not exceed 2 seconds except where a specific cutscene
beat is already defined for Mirror Admin phase transitions.

### Boss and Phase Presentation

Gatekeeper bosses use the normal Battle Engine presentation profiles with a
Singularity overlay: black-code edge treatment, BOSS node sigil, and corruption
class indicator visible before battle start.

Mirror Admin phase presentation:

| Phase | Visual Requirement | Audio Requirement |
|---|---|---|
| INIT | Diagnostic baseline sweep crosses all party HP bars before PARITY starts. HP restoration is visible as a full-bar refill, not a silent state correction. | B.I.O.S. line: "DIAGNOSTIC BASELINE INITIALIZED. ALL SYSTEMS NOMINAL." followed by a clean system tone. |
| PARITY | Mirror Admin element display mirrors the player's active lead element. The UI must show the mirrored element immediately before the first TELEGRAPH phase. | Music is controlled and symmetrical; mirrored element layer may borrow the player's element timbre. |
| OVERCLOCK | Mirror Admin element display snaps to Fire. Phase transition uses a 2-second cutscene beat with screen shear and red/orange overclock pulse. | Music accelerates or thickens. CRITICAL corruption cue fires on phase enter. |
| KERNEL_PANIC | UI shows a looping scripted-sequence indicator (`Attack -> Status -> Attack -> Defend`) without revealing exact move names unless Battle Engine later makes them player-facing. When `tritone_window = true`, Defend receives a distinct counter affordance. Visual rhythm should feel broken and mechanical. | BREACH cue fires on phase enter. Music becomes unstable but required TELEGRAPH/Confirm/cancel tones remain legible. Successful `tritone_counter` plays the 6-semitone counter-tone over the Admin motif. |

If a single damage event crosses both thresholds, phase gates clamp HP and settle each
state in order: CRITICAL/OVERCLOCK first, then BREACH/KERNEL_PANIC. The presentation
may shorten the intermediate OVERCLOCK beat, but it must still show a legible state
change before KERNEL_PANIC begins. The player should understand that two system states
advanced, not watch a false phase that never occurred.

### Ending and Crown Presentation

Mainframe Crown is quiet, not celebratory. The Crown screen uses hardware-substrate
visual language with a high-contrast relic focus area. The relic presentation differs
by relic count:

- 0 relics: Crown displays denial text and returns the player to MAP_EXPLORE; no relic choice, price, or fallback purchase appears.
- 1 relic: the owned relic is presented automatically; no selection menu is shown.
- 2-3 relics: owned relics appear in a compact selection row; unowned relics do not appear.

Relic-specific Mirror Admin final lines must play before `ending_id` is committed.
The line is a narrative beat, so no other idle/ambient dialogue should interrupt it.

### Void Dragon and Post-Game Presentation

Void dragon acquisition is presented as a system insertion, not a reward fanfare.
The roster receives the Void entry automatically after Mirror Admin defeat. B.I.O.S.
delivers one system-notification line (content OQ-SG02). The Void dragon appears with
neutral type treatment and no shiny sparkle.

After an ending resolves, all dragon sprites receive the `restored_gold_code` overlay
in roster, battle, hatchery, and any post-game detail views. Layering order is:
base sprite -> shiny tint (if any) -> restored_gold_code overlay. The overlay must be
visually distinct from shiny and have no stat implication.

Post-game terminals replace completed boss and Crown interactions. Terminal content
is textual with low-key hardware ambience; no battle intro, Replay prompt, or relic
selection presentation is shown for Mirror Admin or Crown after `ending_id != ""`.

### Accessibility and Controller Presentation

All visual state changes must have non-audio confirmation: HUD class indicator,
phase label, terminal text, or visible state change. Audio cues may enrich but never
be the only way to know a class, phase, or ending gate state changed.

All Singularity UI must support d-pad navigation and face-button confirm/cancel.
No hover-only affordances. Any timed visual beat longer than 0.5s must be skippable
only when skipping cannot bypass a required save commit or state transition.

## UI Requirements

### Campaign Map and HUD

- The Campaign Map HUD displays the current corruption class as a six-step indicator
  (`NOMINAL`, `ANOMALY`, `WARNING`, `ALERT`, `CRITICAL`, `BREACH`) or an equivalent
  signal-bar icon with accessible text.
- The corruption indicator updates within one frame of `corruption_class_changed(payload)`.
- At `matrix_stabilized = true`, Spine Access becomes visibly unlocked on the map.
  The map must not require the player to visit the gate before showing that the path
  is available.
- CROWN node uses a unique icon distinct from BOSS, GATE, LORE, REST, COMBAT, HAZARD,
  HUB_RETURN, and SCAR.
- CROWN node does not auto-trigger battle transitions and does not show "Replay?".
- SCAR nodes derived from Singularity render as Campaign Map SCAR overlays and remain
  traversable.

### Boss Entry and Battle UI

- Gatekeeper BOSS entry shows boss name, element, and corruption-class consequence
  before battle begins. It must be clear that defeating the boss advances corruption.
- Mirror Admin entry shows a diagnostic baseline state before the PARITY phase.
- Mirror Admin battle UI must display current phase: PARITY, OVERCLOCK, or KERNEL_PANIC.
- PARITY phase UI displays the mirrored element currently adopted by Mirror Admin.
- OVERCLOCK phase UI displays canonical Fire element and a high-aggression warning.
- KERNEL_PANIC phase UI displays the scripted loop position in a compact indicator.
- During `tritone_window`, Defend displays a distinct counter-ready state. The label may remain
  "Defend", but the affordance must communicate that this input will resolve `tritone_counter`.
- Between Mirror Admin phases, no consumable menu is available. During KERNEL_PANIC
  combat itself, normal in-phase action rules apply unless Battle Engine later revises
  consumable availability.

### Crown Relic Flow

The Crown flow has four UI states:

| UI State | Trigger | UI Requirement |
|---|---|---|
| CROWN_BLOCKED | `mirror_admin_defeated = false` | Crown is inaccessible; denial text is shown if player attempts access. |
| ZERO_RELIC | 0 relics owned | Crown displays `get_no_relic_denial_text()` and exits to MAP_EXPLORE with `ending_id` unchanged. |
| ONE_RELIC | Exactly 1 relic owned | Relic is presented automatically. No selection menu. Player confirms after the Mirror Admin final line. |
| MULTI_RELIC | 2-3 relics owned | Only owned relics are displayed. Player selects exactly one. |

Zero-relic UI:
- Displays denial text only; no relic list, price, free authorization, or confirmation dialog appears.
- Confirm/cancel dismisses the denial and returns to MAP_EXPLORE at Mainframe Crown.
- The player may backtrack to Unit 01/Shop to buy one or more relics at normal prices, then return to Crown.

Multi-relic UI:
- Uses a horizontal d-pad row.
- Left/right stop at row ends; no wrap.
- Confirm selects the focused relic.
- Cancel returns to Crown arrival state only if `ending_id` has not been written.

### Ending Resolution and Post-Game UI

- Once `ending_id` is committed, the ending choice UI cannot re-open in the same save.
- On load with `ending_id != ""`, Crown immediately opens the post-game terminal view.
- Mirror Admin node opens a post-game terminal readout and never shows the Battle Engine
  BOSS entry screen.
- Post-game terminal content must include enough text to communicate that the process
  is archived and READ_ONLY_FREE_ROAM is active. Exact content is OQ-SG07.
- Roster/battle/hatchery UI must show the restored gold-code overlay without changing
  stat displays or shiny labels.

## Acceptance Criteria

### Activation and Matrix Stabilization

| ID | Criterion |
|----|-----------|
| AC-SG01 | When Campaign Map sets `matrix_stabilized` from `false` to `true` and emits `matrix_stabilized()`, Singularity activates exactly once. Re-running the activation check while `matrix_stabilized = true` does not emit duplicate activation state or duplicate BOSS-node placement requests. |
| AC-SG02 | On Singularity activation, the system requests placement/unlock of exactly four Spine bosses keyed as `"gatekeeper_fire"`, `"gatekeeper_ice"`, `"gatekeeper_shadow"`, and `"mirror_admin"`, plus exactly one CROWN node keyed as `"mainframe_crown"`. Missing, duplicate, or misspelled keys are failures. |
| AC-SG03 | `matrix_stabilized` never resets to `false` after Singularity activation, even if roster element coverage later changes. |
| AC-SG04 | Loading a save with Campaign Map's `matrix_stabilized = true` and no active Singularity runtime state reconstructs Singularity state from save data without re-emitting first-time activation presentation. |

### Corruption Class

| ID | Criterion |
|----|-----------|
| AC-SG05 | Default corruption class on a new save is `NOMINAL`. Campaign Map receives no SCAR node list at NOMINAL except an empty list. |
| AC-SG06 | Defeating Gatekeeper Fire advances corruption from NOMINAL to ANOMALY, writes the new class to save data, and emits `corruption_class_changed(ANOMALY)` exactly once. |
| AC-SG07 | Defeating Gatekeeper Ice advances corruption from ANOMALY to WARNING, writes the new class to save data, and emits `corruption_class_changed(WARNING)` exactly once. |
| AC-SG08 | Defeating Gatekeeper Shadow advances corruption from WARNING to ALERT, writes the new class to save data, and emits `corruption_class_changed(ALERT)` exactly once. |
| AC-SG09 | Mirror Admin PARITY -> OVERCLOCK transition advances corruption to CRITICAL and emits `corruption_class_changed(CRITICAL)` exactly once. |
| AC-SG10 | Mirror Admin OVERCLOCK -> KERNEL_PANIC transition advances corruption to BREACH and emits `corruption_class_changed(BREACH)` exactly once. |
| AC-SG11 | Corruption class is monotonic. Attempting to set a lower class than the current class is ignored or rejected; save data remains at the higher class. |
| AC-SG12 | `get_scar_nodes_for_class(class)` returns a cumulative list: the CRITICAL list includes all ALERT scar nodes, and the BREACH list includes all CRITICAL scar nodes. A class list that loses prior scar nodes is a failure. |
| AC-SG13 | Corruption class advance, `scar_nodes[]`, and save write are atomic. Inject a save failure during advance: after rollback/reload, both `corruption_class` and serialized `scar_nodes[]` reflect the pre-advance class. |
| AC-SG14 | If a single hit crosses both Mirror Admin thresholds in one tick, CRITICAL is emitted before BREACH, final phase is KERNEL_PANIC, and final corruption class is BREACH. |

### Gatekeepers and Mirror Admin Access

| ID | Criterion |
|----|-----------|
| AC-SG15 | `can_access_mirror_admin()` returns false when any one of `gatekeeper_fire_defeated`, `gatekeeper_ice_defeated`, or `gatekeeper_shadow_defeated` is false. Test all three single-missing cases independently. |
| AC-SG16 | `can_access_mirror_admin()` returns true only when all three gatekeeper flags are true. |
| AC-SG17 | Defeating each gatekeeper stages only that gatekeeper's defeated flag through Singularity settlement and does not stage `mirror_admin_defeated`. |
| AC-SG18 | Gatekeeper defeat grants XP and Scraps through the standard Battle Engine reward path. Singularity does not bypass or duplicate the reward calculation. |
| AC-SG19 | Re-entering a defeated gatekeeper node before post-game uses the Campaign Map cleared-BOSS Replay prompt. Selecting No keeps the player at the node; selecting Yes starts replay combat without rewriting defeated flags or advancing corruption again. |

### Mirror Admin Phases

| ID | Criterion |
|----|-----------|
| AC-SG20 | On Mirror Admin encounter entry, all party members are restored to full HP before the first PARITY turn begins. Verify with a party containing at least one 0-HP dragon. |
| AC-SG21 | The Mirror Admin INIT restore occurs exactly once per encounter. Manual saving is disabled while Mirror Admin is active. Closing the app before any phase checkpoint commit reloads the last pre-boss save. Closing after a successful PARITY→OVERCLOCK or OVERCLOCK→KERNEL_PANIC checkpoint commit reloads the latest committed phase checkpoint, including phase ID, boss HP, player HP, turn count, and cleared transient statuses/cooldowns. A save that commits CRITICAL/BREACH corruption without matching checkpoint data is invalid. |
| AC-SG22 | PARITY phase reads the player's active lead element and sets Mirror Admin's element to match before the first TELEGRAPH phase. |
| AC-SG23 | PARITY -> OVERCLOCK triggers when Mirror Admin current HP is less than or equal to `overclock_threshold_hp`. Boundary: HP exactly equal to threshold triggers the transition; excess damage is clamped so HP cannot pass the next gate before OVERCLOCK state settlement occurs. |
| AC-SG24 | OVERCLOCK phase sets Mirror Admin element to Fire regardless of player lead element. |
| AC-SG25 | OVERCLOCK -> KERNEL_PANIC triggers when Mirror Admin current HP is less than or equal to `kernel_panic_threshold_hp`. Boundary: HP exactly equal to threshold triggers the transition; Mirror Admin cannot be KO'd until KERNEL_PANIC entry settlement completes. |
| AC-SG26 | No consumable menu or player action prompt appears during the 2-second phase-transition beats between PARITY/OVERCLOCK and OVERCLOCK/KERNEL_PANIC. |
| AC-SG27 | KERNEL_PANIC uses the scripted action loop order `kernel_panic_attack_primary -> kernel_panic_status_desync -> kernel_panic_attack_secondary -> kernel_panic_defend_reset`. Over 8 Mirror Admin turns in KERNEL_PANIC, observed action categories are exactly Attack, Status, Attack, Defend, Attack, Status, Attack, Defend. |
| AC-SG28 | On Mirror Admin defeat, `mirror_admin_defeated = true` and the Void dragon grant are staged in one atomic save commit, `mirror_admin_defeated` signal emits exactly once after commit success, and no additional corruption advance occurs. |

### Crown and Ending Gate

| ID | Criterion |
|----|-----------|
| AC-SG29 | `can_attempt_ending()` returns false before `mirror_admin_defeated = true`, false after Mirror Admin defeat with 0 relics, and true only when `mirror_admin_defeated = true` and `relic_count >= 1`. |
| AC-SG30 | Attempting to access Crown before Mirror Admin defeat displays `get_ending_denial_text()` and does not enter the relic flow. |
| AC-SG31 | Crown node does not trigger MAP_BOSS_TRANSITION or Battle Engine entry. It enters Crown UI flow only. |
| AC-SG32 | With 0 relics owned after Mirror Admin defeat, Crown displays `get_no_relic_denial_text()`, stages no relic flag, stages no `ending_id`, deducts no Scraps, and returns to MAP_EXPLORE. |
| AC-SG33 | With 0 relics owned, no Crown UI path can create, discount, or grant a relic. Only Shop purchase at normal price can change `relic_*_owned` flags. |
| AC-SG34 | After the player backtracks and buys a relic at Shop, re-entering Crown re-evaluates relic count from current save data and proceeds through ONE_RELIC or MULTI_RELIC as appropriate. |
| AC-SG35 | With exactly 1 relic owned, Crown presents that relic automatically and does not show a relic selection menu. |
| AC-SG36 | With 2 or 3 relics owned, Crown displays only owned relics and requires the player to select exactly one. Unowned relics are not displayed. |
| AC-SG37 | The relic-specific residual Admin final line completes before commit. Then selecting/presenting 10mm Wrench commits `ending_id = "total_restore"`, Diagnostic Lens commits `ending_id = "the_patch"`, and Kernel Blade commits `ending_id = "hardware_override"`. |
| AC-SG38 | `ending_id` is written in a single save commit and is the only persistent post-game authority. No serialized `game_state = "post_game"` field exists. A partial state with cutscene played but `ending_id` absent is a failure. |
| AC-SG39 | If the player exits Crown before relic confirmation, no `ending_id` is written. Re-entering Crown restarts the relic count check from current save data. |

### Void Dragon

| ID | Criterion |
|----|-----------|
| AC-SG40 | On Mirror Admin defeat, the Void dragon is added to the roster automatically without player input. |
| AC-SG41 | The Void dragon entry uses `dragon_id = "void_dragon"`, `element = Void`, `base_atk = 40`, and `is_shiny = false`. |
| AC-SG42 | The Void dragon cannot be generated as shiny by Hatchery, Fusion, debug grant, save migration, or any post-game reward path. Runtime verification must attempt at least one non-Singularity grant path and confirm `is_shiny` remains false or grant is rejected. |
| AC-SG43 | Void dragon type effectiveness is neutral (1.0x) against every core element, and every core element is neutral (1.0x) against Void in MVP. |
| AC-SG44 | If normal roster capacity is full, Void dragon grant succeeds via reserved story-dragon slot or equivalent mechanism. A grant failure, dropped dragon, or overwritten existing dragon is a failure. |

### Post-Game

| ID | Criterion |
|----|-----------|
| AC-SG45 | After any ending, loading the save with `ending_id != ""` enters READ_ONLY_FREE_ROAM/post-game state. |
| AC-SG46 | In post-game, Crown node opens post-game terminal content and never reopens relic selection. |
| AC-SG47 | In post-game, Mirror Admin node opens post-game terminal content and never re-enters combat. |
| AC-SG48 | Gatekeeper defeated flags and `mirror_admin_defeated` remain true permanently after ending resolution. |
| AC-SG49 | XP and Scrap accrual continue normally in READ_ONLY_FREE_ROAM replay battles except Mirror Admin, which never replays. Verify a post-game combat/gatekeeper replay grants rewards without rewriting story flags, advancing corruption, or re-emitting first-time signals. |
| AC-SG50 | Shop remains accessible in post-game according to the ending-specific presentation profile; owned relic flags remain owned, unowned relics cannot be newly purchased after `ending_id` is committed, and no relic flag is reset by ending resolution. |
| AC-SG51 | The `restored_gold_code` overlay appears on all dragon sprites in roster, battle, and hatchery after `ending_id != ""` loads. It does not change any displayed stat value. |

### Visual, Audio, and UI

| ID | Criterion |
|----|-----------|
| AC-SG52 | Corruption HUD indicator updates within one frame of each `corruption_class_changed(payload)` signal. |
| AC-SG53 | Every corruption class transition has both a visual confirmation and an audio cue. With audio muted, the visual confirmation alone communicates the new class. |
| AC-SG54 | Mirror Admin phase label displays PARITY, OVERCLOCK, or KERNEL_PANIC during the corresponding phase and updates before the next player input opportunity. |
| AC-SG55 | KERNEL_PANIC UI displays scripted loop position. In a four-action cycle, the displayed position advances once per Mirror Admin action and wraps after Defend. |
| AC-SG56 | All Crown relic-flow interactions are completable using d-pad plus confirm/cancel face buttons only. No mouse hover or keyboard-only action is required. |
| AC-SG57 | Multi-relic selection d-pad navigation stops at row ends and does not wrap. Boundary test: press left at first relic and right at last relic; focus remains in place. |
| AC-SG58 | Zero-relic Crown denial is visible as text. Audio cue alone is insufficient, and no price/free-authorization messaging appears. |
| AC-SG59 | Post-game terminal views are dismissible with face-button confirm/cancel and return the player to MAP_EXPLORE at the same node. |
| AC-SG60 | After each Mirror Admin `Status` action in KERNEL_PANIC, `tritone_window` opens for exactly one player TELEGRAPH input and then closes. |
| AC-SG61 | Selecting Defend during `tritone_window` resolves `tritone_counter`, applies F-5 damage bypassing DEF/type/crit/miss, skips the next Mirror Admin Defend action, applies the normal Defend damage reduction for that turn, starts the normal Defend cooldown afterward, and plays the Audio Director counter-tone. |
| AC-SG62 | Selecting any non-Defend action during `tritone_window` resolves that action normally, closes the window, applies no counter damage, and does not skip Mirror Admin's next scripted action. |
| AC-SG63 | During `tritone_window`, Defend has a visible counter-ready affordance. With audio muted, the player can still identify the counter opportunity. |

## Open Questions

| ID | Question | Blocking? | Notes |
|----|----------|-----------|-------|
| OQ-SG01 | What final authored move names, animations, and damage powers map to `kernel_panic_attack_primary`, `kernel_panic_status_desync`, `kernel_panic_attack_secondary`, and `kernel_panic_defend_reset`? | No — blocks content polish, not implementation shape | Loop order, Guard Break status, Defend behavior, and tritone counter interaction are canonical. |
| OQ-SG02 | What is the B.I.O.S. voice line when the Void dragon is granted? | No — blocks final narrative polish, not mechanics | Register must be system notification, not reward/celebration. Writer/Journals should own final wording. |
| OQ-SG03 | Are the provisional Void dragon stats final: HP 80, DEF 20, SPD 36, level 30? | No — blocks balance lock, not schema implementation | `base_atk = 40`, `is_shiny = false`, Stage III level range, and story-roster grant are canonical. |
| OQ-SG04 | Should Void remain permanently neutral against all elements after post-game, or gain a post-MVP special matchup? | No — MVP uses neutral 1.0x both ways | Battle Engine and Dragon Progression now include Void as a story element with neutral type chart treatment. |
| OQ-SG05 | Which authored HAZARD nodes use which valid status IDs? | No — blocks content data, not vocabulary | Valid MVP status IDs are Battle Engine's existing single-slot statuses: Burn, Freeze, Paralyze, Guard Break, Poison, Blind. |
| OQ-SG06 | What are the final Mirror Admin relic-specific lines for Diagnostic Lens and Kernel Blade? | No — blocks final narrative polish | Wrench line is currently authored. Lens and Blade must be written by Writer GDD. |
| OQ-SG07 | What content appears in post-game terminal readouts at Crown and archived Mirror Admin node? | No — blocks post-game content polish | Terminal must communicate READ_ONLY_FREE_ROAM and process archived state. Exact stats/content deferred. |
| OQ-SG08 | What UI label should the reserved story-roster slot use when normal roster capacity is full? | No — blocks UI copy polish, not safe grant | Dragon Progression owns the reserved story slot; Singularity requires the Void grant to succeed even at normal capacity. |
| OQ-SG09 | Should the CRITICAL/BREACH visual filter apply globally to all acts immediately, or only to the active act/current screen? | No — implementation/art direction decision | Campaign Map OQ-CM05 already defers this. Global is simpler; per-act is more targeted. |
| OQ-SG10 | **RESOLVED** — authored SCAR node IDs are listed in Map Corruption. | No | Campaign Map must reserve those IDs or provide migration aliases before implementation stories are created. |
| OQ-SG11 | Should a player who owns multiple relics be allowed to back out after seeing the multi-relic selection screen? | No — UX policy decision | Current UI allows cancel only before `ending_id` is written. Review whether narrative pressure should remove cancel at this point. |
| OQ-SG13 | Does OVERCLOCK need bespoke move names beyond the weighted high-aggression profile? | No — blocks content polish, not AI implementation | Canonical weights are Attack 70%, Status 20%, Defend 10%, single-target only. |
| OQ-SG14 | **RESOLVED** — Save/Persistence defines debug failure injection hooks for corruption advance, Mirror Admin defeat + Void grant, and ending commit. | No | See save-persistence.md failure injection points. |
