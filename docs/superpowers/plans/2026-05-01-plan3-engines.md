# Dragon Forge Godot Rebuild — Plan 3: Engine Ports

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port all pure simulation engines from JavaScript to GDScript with GUT tests that mirror the existing vitest cases exactly. All tests must pass before Plan 4 (screens) begins.

**Architecture:** Each engine is a static GDScript class with no scene dependencies. GUT tests use assert_eq/assert_true/assert_almost_eq. The vitest cases are the acceptance spec — same inputs, same expected outputs.

**Tech Stack:** Godot 4.6, GDScript, GUT (gdUnit4 or gut-godot)

**Prerequisite:** Plan 2 complete.

---

## File Structure

New files created by this plan:

```
dragon-forge-godot/
  scripts/sim/
    game_data.gd              # constants: typeChart, moves, stageMultipliers, STATUS_EFFECTS, rarityTiers, etc.
    battle_engine.gd          # port of src/battleEngine.js
    fusion_engine.gd          # port of src/fusionEngine.js
    hatchery_engine.gd        # port of src/hatcheryEngine.js
    singularity_progress.gd   # port of src/singularityProgress.js
  tests/
    test_battle_engine.gd     # GUT mirror of src/battleEngine.test.js
    test_fusion_engine.gd     # GUT mirror of src/fusionEngine.test.js
    test_hatchery_engine.gd   # GUT mirror of src/hatcheryEngine.test.js
    test_singularity_progress.gd
```

**Headless test command:**
```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd
```

---

## Task 0: Shared Data Module (`game_data.gd`)

This module holds all constants referenced by the four engines. Write it first; every subsequent task depends on it.

**File:** `dragon-forge-godot/scripts/sim/game_data.gd`

- [ ] **Step 0.1 — Create `game_data.gd`**

```gdscript
extends RefCounted
class_name GameData

# ── ELEMENTS ────────────────────────────────────────────────────────────────
const ELEMENTS: Array = ["fire", "ice", "storm", "stone", "venom", "shadow", "void"]

# ── TYPE CHART ───────────────────────────────────────────────────────────────
# typeChart[attacker][defender] = multiplier
const TYPE_CHART: Dictionary = {
    "fire":   { "fire": 0.5, "ice": 2.0, "storm": 1.0, "stone": 0.5, "venom": 2.0, "shadow": 1.0, "void": 1.0 },
    "ice":    { "fire": 0.5, "ice": 0.5, "storm": 2.0, "stone": 1.0, "venom": 1.0, "shadow": 2.0, "void": 1.0 },
    "storm":  { "fire": 1.0, "ice": 0.5, "storm": 0.5, "stone": 2.0, "venom": 1.0, "shadow": 2.0, "void": 1.0 },
    "stone":  { "fire": 2.0, "ice": 1.0, "storm": 0.5, "stone": 0.5, "venom": 2.0, "shadow": 1.0, "void": 1.0 },
    "venom":  { "fire": 0.5, "ice": 1.0, "storm": 1.0, "stone": 0.5, "venom": 0.5, "shadow": 2.0, "void": 1.0 },
    "shadow": { "fire": 1.0, "ice": 0.5, "storm": 0.5, "stone": 1.0, "venom": 0.5, "shadow": 0.5, "void": 1.0 },
    "void":   { "fire": 1.0, "ice": 1.0, "storm": 1.0, "stone": 1.0, "venom": 1.0, "shadow": 1.0, "void": 1.0 },
}

# ── STAGE MULTIPLIERS ────────────────────────────────────────────────────────
const STAGE_MULTIPLIERS: Dictionary = { 1: 0.5, 2: 0.75, 3: 1.0, 4: 1.4 }

# ── STAGE THRESHOLDS ─────────────────────────────────────────────────────────
const STAGE_THRESHOLDS: Dictionary = { 2: 10, 3: 25, 4: 50 }

# ── CRIT ─────────────────────────────────────────────────────────────────────
const CRIT_CHANCE: float = 0.10
const CRIT_MULTIPLIER: float = 1.5

# ── STATUS EFFECTS ───────────────────────────────────────────────────────────
# type: "dot" | "skip" | "maySkip" | "debuff" | "randomize"
const STATUS_EFFECTS: Dictionary = {
    "fire":   { "name": "Burn",        "duration": 2, "type": "dot",       "value": 0.08 },
    "ice":    { "name": "Freeze",      "duration": 1, "type": "skip",      "value": 1.0  },
    "storm":  { "name": "Paralyze",    "duration": 2, "type": "maySkip",   "value": 0.5  },
    "stone":  { "name": "Guard Break", "duration": 2, "type": "debuff",    "value": 0.4  },
    "venom":  { "name": "Poison",      "duration": 2, "type": "dot",       "value": 0.06 },
    "shadow": { "name": "Blind",       "duration": 2, "type": "debuff",    "value": 0.3  },
    "void":   { "name": "Glitch",      "duration": 1, "type": "randomize", "value": 1.0  },
}
const STATUS_APPLY_CHANCE: float = 0.30

# ── MOVES ─────────────────────────────────────────────────────────────────────
const MOVES: Dictionary = {
    "magma_breath":     { "name": "Magma Breath",     "element": "fire",    "power": 65, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
    "flame_wall":       { "name": "Flame Wall",        "element": "fire",    "power": 55, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
    "frost_bite":       { "name": "Frost Bite",        "element": "ice",     "power": 60, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
    "blizzard":         { "name": "Blizzard",          "element": "ice",     "power": 70, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
    "lightning_strike": { "name": "Lightning Strike",  "element": "storm",   "power": 70, "accuracy": 90,  "can_apply_status": true,  "is_reflect": false },
    "thunder_clap":     { "name": "Thunder Clap",      "element": "storm",   "power": 55, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
    "rock_slide":       { "name": "Rock Slide",        "element": "stone",   "power": 60, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
    "earthquake":       { "name": "Earthquake",        "element": "stone",   "power": 75, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
    "acid_spit":        { "name": "Acid Spit",         "element": "venom",   "power": 60, "accuracy": 100, "can_apply_status": true,  "is_reflect": false },
    "toxic_cloud":      { "name": "Toxic Cloud",       "element": "venom",   "power": 70, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
    "shadow_strike":    { "name": "Shadow Strike",     "element": "shadow",  "power": 65, "accuracy": 95,  "can_apply_status": true,  "is_reflect": false },
    "void_pulse":       { "name": "Void Pulse",        "element": "shadow",  "power": 75, "accuracy": 85,  "can_apply_status": true,  "is_reflect": false },
    "void_rift":        { "name": "Void Rift",         "element": "void",    "power": 80, "accuracy": 80,  "can_apply_status": true,  "is_reflect": false },
    "null_reflect":     { "name": "Null Reflect",      "element": "void",    "power": 0,  "accuracy": 100, "can_apply_status": false, "is_reflect": true  },
    "basic_attack":     { "name": "Basic Attack",      "element": "neutral", "power": 40, "accuracy": 100, "can_apply_status": false, "is_reflect": false },
}

# ── RARITY TIERS (hatchery) ──────────────────────────────────────────────────
const RARITY_TIERS: Array = [
    { "name": "Common",   "chance": 0.50, "elements": ["fire", "ice"],                "multiplier": 1, "guaranteed_shiny": false },
    { "name": "Uncommon", "chance": 0.30, "elements": ["storm", "venom", "stone"],    "multiplier": 2, "guaranteed_shiny": false },
    { "name": "Rare",     "chance": 0.15, "elements": ["shadow"],                     "multiplier": 3, "guaranteed_shiny": false },
    { "name": "Exotic",   "chance": 0.05, "elements": ["void"],                       "multiplier": 5, "guaranteed_shiny": true  },
]
const PULL_COST: int      = 50
const SHINY_CHANCE: float = 0.02
const PITY_THRESHOLD: int = 10

# ── SINGULARITY ───────────────────────────────────────────────────────────────
const BASE_ELEMENTS: Array    = ["fire", "ice", "storm", "stone", "venom", "shadow"]
const BASE_NPC_IDS: Array     = ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
const SINGULARITY_STAGES: Array = [
    { "stage": 0, "name": "Dormant",           "description": "The Elemental Matrix is stable." },
    { "stage": 1, "name": "Anomaly Detected",  "description": "Strange readings in the Matrix." },
    { "stage": 2, "name": "Signal Growing",    "description": "Something is feeding on elemental energy." },
    { "stage": 3, "name": "Matrix Unstable",   "description": "The Matrix is destabilizing." },
    { "stage": 4, "name": "Breach Imminent",   "description": "Defenses are failing." },
    { "stage": 5, "name": "The Singularity",   "description": "The Singularity has breached the Matrix." },
]
```

- [ ] **Step 0.2 — Commit**
  ```
  git add dragon-forge-godot/scripts/sim/game_data.gd
  git commit -m "Add Godot GameData constants module (Plan 3 step 0)"
  ```

---

## Task 1: Battle Engine

Port `src/battleEngine.js` → `dragon-forge-godot/scripts/sim/battle_engine.gd`.  
Write the GUT test file first (red), then implement until green.

### Step 1.1 — Write failing GUT test

**File:** `dragon-forge-godot/tests/test_battle_engine.gd`

- [ ] **Create `tests/test_battle_engine.gd`**

```gdscript
extends GutTest

const BattleEngine = preload("res://scripts/sim/battle_engine.gd")
const GameData     = preload("res://scripts/sim/game_data.gd")

# ── get_type_effectiveness ───────────────────────────────────────────────────

func test_fire_super_effective_vs_ice() -> void:
    assert_eq(BattleEngine.get_type_effectiveness("fire", "ice"), 2.0)

func test_fire_not_effective_vs_stone() -> void:
    assert_eq(BattleEngine.get_type_effectiveness("fire", "stone"), 0.5)

func test_neutral_attacker_returns_1() -> void:
    assert_eq(BattleEngine.get_type_effectiveness("neutral", "fire"), 1.0)

func test_unknown_defender_returns_1() -> void:
    assert_eq(BattleEngine.get_type_effectiveness("fire", "neutral"), 1.0)

# void type chart — all 1.0
func test_void_attacking_any_is_neutral() -> void:
    for el in ["fire", "ice", "shadow", "void"]:
        assert_eq(BattleEngine.get_type_effectiveness("void", el), 1.0,
                  "void vs %s should be 1.0" % el)

func test_any_attacking_void_is_neutral() -> void:
    for el in ["fire", "ice", "shadow"]:
        assert_eq(BattleEngine.get_type_effectiveness(el, "void"), 1.0,
                  "%s vs void should be 1.0" % el)

# ── calculate_damage ─────────────────────────────────────────────────────────
# attacker: atk=28, element='fire', stage=3
# defender: def=20, element='ice', defending=false
# move: element='fire', power=65, accuracy=100
# baseDamage = (28*1.0*2) - (20*0.5) = 46
# typedDamage = 46 * 2.0 = 92
# non-crit range: floor(92*0.85)=78 .. floor(92*1.0)=92
# crit range: floor(78*1.5)=117 .. floor(92*1.5)=138

func test_super_effective_damage_range() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 3 }
    var defender := { "def": 20, "element": "ice", "defending": false }
    var move     := { "element": "fire", "power": 65, "accuracy": 100 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    assert_true(result.hit, "should hit at accuracy 100")
    assert_eq(result.effectiveness, 2.0)
    assert_true(result.damage >= 78 and result.damage <= 138,
                "damage %d should be in [78,138]" % result.damage)

func test_defending_halves_damage() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 3 }
    var defender := { "def": 20, "element": "ice", "defending": true }
    var move     := { "element": "fire", "power": 65, "accuracy": 100 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    # non-crit: 39..46; crit: 58..69
    assert_true(result.damage >= 39 and result.damage <= 69,
                "defending damage %d should be in [39,69]" % result.damage)

func test_stage_multiplier_applied() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 1 }
    var defender := { "def": 20, "element": "ice", "defending": false }
    var move     := { "element": "fire", "power": 65, "accuracy": 100 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    # baseDamage=(28*0.5*2)-(20*0.5)=18; typed=36; non-crit:30..36; crit:45..54
    assert_true(result.damage >= 30 and result.damage <= 54,
                "stage 1 damage %d should be in [30,54]" % result.damage)

func test_minimum_1_damage() -> void:
    var attacker := { "atk": 1,   "element": "fire", "stage": 1 }
    var defender := { "def": 100, "element": "fire", "defending": true }
    var move     := { "element": "fire", "power": 65, "accuracy": 100 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    assert_eq(result.damage, 1)

func test_accuracy_zero_always_misses() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 3 }
    var defender := { "def": 20, "element": "ice",  "defending": false }
    var move     := { "element": "fire", "power": 65, "accuracy": 0 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    assert_false(result.hit)
    assert_eq(result.damage, 0)

func test_is_critical_is_bool() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 3 }
    var defender := { "def": 20, "element": "ice",  "defending": false }
    var move     := { "element": "fire", "power": 65, "accuracy": 100 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    assert_true(result.is_critical == true or result.is_critical == false)

func test_miss_cannot_be_critical() -> void:
    var attacker := { "atk": 28, "element": "fire", "stage": 3 }
    var defender := { "def": 20, "element": "ice",  "defending": false }
    var move     := { "element": "fire", "power": 65, "accuracy": 0 }
    var result   := BattleEngine.calculate_damage(attacker, defender, move)
    assert_false(result.is_critical)

# ── get_stage_for_level ───────────────────────────────────────────────────────

func test_stage_1_below_10() -> void:
    assert_eq(BattleEngine.get_stage_for_level(1), 1)
    assert_eq(BattleEngine.get_stage_for_level(9), 1)

func test_stage_2_levels_10_to_24() -> void:
    assert_eq(BattleEngine.get_stage_for_level(10), 2)
    assert_eq(BattleEngine.get_stage_for_level(24), 2)

func test_stage_3_levels_25_to_49() -> void:
    assert_eq(BattleEngine.get_stage_for_level(25), 3)
    assert_eq(BattleEngine.get_stage_for_level(49), 3)

func test_stage_4_level_50_plus() -> void:
    assert_eq(BattleEngine.get_stage_for_level(50), 4)
    assert_eq(BattleEngine.get_stage_for_level(99), 4)

# ── calculate_xp_gain ─────────────────────────────────────────────────────────

func test_xp_equal_levels() -> void:
    assert_eq(BattleEngine.calculate_xp_gain(50, 10, 10), 50)

func test_xp_higher_enemy() -> void:
    assert_eq(BattleEngine.calculate_xp_gain(50, 5, 10), 100)

func test_xp_lower_enemy() -> void:
    assert_eq(BattleEngine.calculate_xp_gain(50, 10, 5), 25)

func test_xp_minimum_1() -> void:
    assert_true(BattleEngine.calculate_xp_gain(50, 99, 1) >= 1)

# ── calculate_stats_for_level ─────────────────────────────────────────────────

func test_stats_at_level_1() -> void:
    var base   := { "hp": 110, "atk": 28, "def": 20, "spd": 18 }
    var result := BattleEngine.calculate_stats_for_level(base, 1, false)
    assert_eq(result, { "hp": 110, "atk": 28, "def": 20, "spd": 18 })

func test_stats_level_5_adds_12_each() -> void:
    var base   := { "hp": 110, "atk": 28, "def": 20, "spd": 18 }
    var result := BattleEngine.calculate_stats_for_level(base, 5, false)
    assert_eq(result, { "hp": 122, "atk": 40, "def": 32, "spd": 30 })

func test_shiny_1_2x_multiplier_level_1() -> void:
    var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
    var result := BattleEngine.calculate_stats_for_level(base, 1, true)
    assert_eq(result, { "hp": 120, "atk": 24, "def": 24, "spd": 24 })

func test_shiny_after_level_scaling() -> void:
    var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
    var result := BattleEngine.calculate_stats_for_level(base, 5, true)
    assert_eq(result, { "hp": 134, "atk": 38, "def": 38, "spd": 38 })

func test_non_shiny_no_change() -> void:
    var base   := { "hp": 100, "atk": 20, "def": 20, "spd": 20 }
    var result := BattleEngine.calculate_stats_for_level(base, 1, false)
    assert_eq(result, { "hp": 100, "atk": 20, "def": 20, "spd": 20 })

# ── apply_status ──────────────────────────────────────────────────────────────

func test_apply_burn_from_fire() -> void:
    var result := BattleEngine.apply_status("fire")
    assert_eq(result, { "effect": "fire", "turns_left": 2 })

func test_apply_status_neutral_returns_null() -> void:
    assert_eq(BattleEngine.apply_status("neutral"), null)

func test_apply_freeze_1_turn() -> void:
    var result := BattleEngine.apply_status("ice")
    assert_eq(result, { "effect": "ice", "turns_left": 1 })

# ── process_status_tick ───────────────────────────────────────────────────────

func test_burn_dot_damage() -> void:
    var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "fire", "turns_left": 2 } }
    var result := BattleEngine.process_status_tick(state)
    assert_eq(result.hp, 92)
    assert_eq(result.status.turns_left, 1)
    assert_eq(result.status_event, { "type": "dot", "damage": 8, "effect_name": "Burn", "expired": false })

func test_poison_dot_damage() -> void:
    var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "venom", "turns_left": 2 } }
    var result := BattleEngine.process_status_tick(state)
    assert_eq(result.hp, 94)
    assert_eq(result.status.turns_left, 1)

func test_status_expires_at_zero_turns() -> void:
    var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "fire", "turns_left": 1 } }
    var result := BattleEngine.process_status_tick(state)
    assert_eq(result.hp, 92)
    assert_eq(result.status, null)
    assert_true(result.status_event.expired)

func test_no_status_returns_unchanged() -> void:
    var state  := { "hp": 100, "max_hp": 100, "status": null }
    var result := BattleEngine.process_status_tick(state)
    assert_eq(result.hp, 100)
    assert_eq(result.status_event, null)

func test_non_dot_status_no_damage() -> void:
    var state  := { "hp": 100, "max_hp": 100, "status": { "effect": "stone", "turns_left": 2 } }
    var result := BattleEngine.process_status_tick(state)
    assert_eq(result.hp, 100)
    assert_eq(result.status.turns_left, 1)

# ── pick_npc_move ─────────────────────────────────────────────────────────────

func test_pick_npc_move_returns_valid_key() -> void:
    var keys   := ["rock_slide", "earthquake"]
    var result := BattleEngine.pick_npc_move(keys, "stone", "fire", null)
    assert_true(["rock_slide", "earthquake", "basic_attack"].has(result),
                "pick_npc_move returned unknown key: %s" % result)

func test_pick_npc_move_favors_super_effective() -> void:
    # stone vs fire: rock_slide and earthquake are both stone (2x vs fire)
    var keys := ["rock_slide", "earthquake"]
    var super_effective_count := 0
    for _i in range(50):
        var key  := BattleEngine.pick_npc_move(keys, "stone", "fire", null)
        var move := GameData.MOVES.get(key, GameData.MOVES["basic_attack"])
        var eff  := BattleEngine.get_type_effectiveness(move["element"], "fire")
        if eff > 1.0:
            super_effective_count += 1
    assert_true(super_effective_count > 25,
                "super-effective moves chosen only %d/50 times" % super_effective_count)

# ── resolve_turn ──────────────────────────────────────────────────────────────

func _player_state() -> Dictionary:
    return {
        "name": "Magma Dragon", "element": "fire", "stage": 3,
        "hp": 100, "max_hp": 110, "atk": 28, "def": 20, "spd": 18, "defending": false,
        "status": null, "reflecting": false,
    }

func _npc_state() -> Dictionary:
    return {
        "name": "Firewall Sentinel", "element": "stone", "stage": 3,
        "hp": 130, "max_hp": 130, "atk": 18, "def": 32, "spd": 8, "defending": false,
        "status": null, "reflecting": false,
    }

func test_resolve_turn_returns_player_npc_events() -> void:
    var result := BattleEngine.resolve_turn(
        _player_state(), _npc_state(), "magma_breath", "rock_slide", [], [])
    assert_true(result.has("player"))
    assert_true(result.has("npc"))
    assert_true(result.has("events"))
    assert_true(result.events.size() >= 2)

func test_faster_combatant_attacks_first() -> void:
    # player spd=18 > npc spd=8
    var result := BattleEngine.resolve_turn(
        _player_state(), _npc_state(), "magma_breath", "rock_slide", [], [])
    assert_eq(result.events[0].attacker, "player")
    assert_eq(result.events[1].attacker, "npc")

func test_defend_action_sets_event() -> void:
    var result := BattleEngine.resolve_turn(
        _player_state(), _npc_state(), "defend", "rock_slide", [], [])
    var defend_event := null
    for ev in result.events:
        if ev.get("action") == "defend":
            defend_event = ev
            break
    assert_not_null(defend_event, "no defend event found")

func test_ko_stops_second_attack() -> void:
    var weak_npc := _npc_state()
    weak_npc.hp = 1
    var result := BattleEngine.resolve_turn(
        _player_state(), weak_npc, "basic_attack", "rock_slide", [], [])
    assert_eq(result.npc.hp, 0)
    var npc_attacks := 0
    for ev in result.events:
        if ev.get("attacker") == "npc" and ev.get("action") == "attack":
            npc_attacks += 1
    assert_eq(npc_attacks, 0, "NPC should not attack after being KO'd")

# ── null_reflect ──────────────────────────────────────────────────────────────

func _void_player() -> Dictionary:
    return {
        "name": "Void Dragon", "element": "void", "stage": 3,
        "hp": 75, "max_hp": 75, "atk": 34, "def": 12, "spd": 30,
        "status": null, "defending": false, "reflecting": false,
    }

func _fire_npc() -> Dictionary:
    return {
        "name": "Test NPC", "element": "fire", "stage": 3,
        "hp": 100, "max_hp": 100, "atk": 20, "def": 20, "spd": 10,
        "status": null, "defending": false, "reflecting": false,
    }

func test_null_reflect_reflects_damage() -> void:
    var result := BattleEngine.resolve_turn(
        _void_player(), _fire_npc(), "null_reflect", "basic_attack", [], [])
    var reflect_event := null
    var npc_attack_event := null
    for ev in result.events:
        if ev.get("action") == "reflect":
            reflect_event = ev
        if ev.get("attacker") == "npc" and ev.get("action") == "attack":
            npc_attack_event = ev
    assert_not_null(reflect_event, "no reflect event found")
    assert_eq(reflect_event.attacker, "player")
    assert_not_null(npc_attack_event, "no npc attack event found")
    assert_true(npc_attack_event.get("reflected", false), "attack should be reflected")
    assert_eq(result.player.hp, 75, "player hp unchanged — damage reflected away")
    assert_true(result.npc.hp < 100, "npc takes reflected damage")

func test_reflect_vs_defend_no_damage() -> void:
    var result := BattleEngine.resolve_turn(
        _void_player(), _fire_npc(), "null_reflect", "defend", [], [])
    assert_eq(result.player.hp, 75)
    assert_eq(result.npc.hp, 100)

# ── glitch status ─────────────────────────────────────────────────────────────

func test_glitch_turn_resolves_normally() -> void:
    var player := _player_state()
    player.status = { "effect": "void", "turns_left": 1 }
    var npc := _npc_state()
    var result := BattleEngine.resolve_turn(
        player, npc, "basic_attack", "basic_attack",
        ["magma_breath", "flame_wall"], ["rock_slide"])
    assert_true(result.events.size() > 0)
    var player_event := null
    for ev in result.events:
        if ev.get("attacker") == "player":
            player_event = ev
            break
    assert_not_null(player_event, "player should have acted even under Glitch")
```

### Step 1.2 — Implement `battle_engine.gd`

**File:** `dragon-forge-godot/scripts/sim/battle_engine.gd`

- [ ] **Create `scripts/sim/battle_engine.gd`**

```gdscript
extends RefCounted
class_name BattleEngine

const GameData = preload("res://scripts/sim/game_data.gd")

# ─────────────────────────────────────────────────────────────────────────────
# get_type_effectiveness(attacker_element, defender_element) -> float
# ─────────────────────────────────────────────────────────────────────────────
static func get_type_effectiveness(attacker_element: String, defender_element: String) -> float:
    if not GameData.TYPE_CHART.has(attacker_element):
        return 1.0
    var row: Dictionary = GameData.TYPE_CHART[attacker_element]
    return row.get(defender_element, 1.0)

# ─────────────────────────────────────────────────────────────────────────────
# calculate_damage(attacker, defender, move) -> Dictionary
# Returns: { damage, effectiveness, hit, is_critical }
# attacker: { atk, element, stage }
# defender: { def, element, defending }
# move:     { element, power, accuracy }
# ─────────────────────────────────────────────────────────────────────────────
static func calculate_damage(attacker: Dictionary, defender: Dictionary, move: Dictionary) -> Dictionary:
    # Accuracy check
    var accuracy_roll: float = randf() * 100.0
    if accuracy_roll > move.get("accuracy", 100):
        return { "damage": 0, "effectiveness": 1.0, "hit": false, "is_critical": false }

    var stage_mult: float  = GameData.STAGE_MULTIPLIERS.get(attacker.get("stage", 3), 1.0)
    var base_damage: float = (attacker.get("atk", 0) * stage_mult * 2.0) - (defender.get("def", 0) * 0.5)
    var effectiveness: float = get_type_effectiveness(move.get("element", "neutral"), defender.get("element", "neutral"))
    var typed_damage: float = base_damage * effectiveness

    if defender.get("defending", false):
        typed_damage *= 0.5

    var roll: float       = 0.85 + randf() * 0.15
    var final_damage: int = maxi(1, int(typed_damage * roll))

    var is_critical: bool = randf() < GameData.CRIT_CHANCE
    if is_critical:
        final_damage = int(final_damage * GameData.CRIT_MULTIPLIER)

    return { "damage": final_damage, "effectiveness": effectiveness, "hit": true, "is_critical": is_critical }

# ─────────────────────────────────────────────────────────────────────────────
# get_stage_for_level(level) -> int
# ─────────────────────────────────────────────────────────────────────────────
static func get_stage_for_level(level: int) -> int:
    if level >= GameData.STAGE_THRESHOLDS[4]: return 4
    if level >= GameData.STAGE_THRESHOLDS[3]: return 3
    if level >= GameData.STAGE_THRESHOLDS[2]: return 2
    return 1

# ─────────────────────────────────────────────────────────────────────────────
# calculate_xp_gain(base_xp, player_level, enemy_level) -> int
# ─────────────────────────────────────────────────────────────────────────────
static func calculate_xp_gain(base_xp: int, player_level: int, enemy_level: int) -> int:
    var ratio: float = float(enemy_level) / float(player_level)
    return maxi(1, int(base_xp * ratio))

# ─────────────────────────────────────────────────────────────────────────────
# calculate_stats_for_level(base_stats, level, shiny) -> Dictionary
# base_stats: { hp, atk, def, spd }
# ─────────────────────────────────────────────────────────────────────────────
static func calculate_stats_for_level(base_stats: Dictionary, level: int, shiny: bool = false) -> Dictionary:
    var bonus: int   = (level - 1) * 3
    var mult: float  = 1.2 if shiny else 1.0
    return {
        "hp":  int((base_stats.get("hp",  0) + bonus) * mult),
        "atk": int((base_stats.get("atk", 0) + bonus) * mult),
        "def": int((base_stats.get("def", 0) + bonus) * mult),
        "spd": int((base_stats.get("spd", 0) + bonus) * mult),
    }

# ─────────────────────────────────────────────────────────────────────────────
# apply_status(move_element) -> Variant  (Dictionary or null)
# Returns: { effect, turns_left } or null
# ─────────────────────────────────────────────────────────────────────────────
static func apply_status(move_element: String) -> Variant:
    if not GameData.STATUS_EFFECTS.has(move_element):
        return null
    var effect: Dictionary = GameData.STATUS_EFFECTS[move_element]
    return { "effect": move_element, "turns_left": effect["duration"] }

# ─────────────────────────────────────────────────────────────────────────────
# process_status_tick(combatant_state) -> Dictionary
# combatant_state must have: hp, max_hp, status (dict or null)
# Returns copy of state with hp, status, status_event updated.
# ─────────────────────────────────────────────────────────────────────────────
static func process_status_tick(combatant_state: Dictionary) -> Dictionary:
    var result: Dictionary = combatant_state.duplicate(true)
    if combatant_state.get("status") == null:
        result["status_event"] = null
        return result

    var effect_key: String = combatant_state["status"]["effect"]
    var effect: Dictionary = GameData.STATUS_EFFECTS[effect_key]
    var hp: int            = combatant_state.get("hp", 0)
    var damage: int        = 0
    var turns_left: int    = combatant_state["status"]["turns_left"] - 1
    var expired: bool      = turns_left <= 0

    if effect["type"] == "dot":
        damage = maxi(1, int(combatant_state.get("max_hp", hp) * effect["value"]))
        hp     = maxi(0, hp - damage)

    result["hp"] = hp
    result["status"] = null if expired else { "effect": effect_key, "turns_left": turns_left }
    result["status_event"] = {
        "type":        effect["type"],
        "damage":      damage,
        "effect_name": effect["name"],
        "expired":     expired,
    }
    return result

# ─────────────────────────────────────────────────────────────────────────────
# pick_npc_move(npc_move_keys, npc_element, player_element, player_status) -> String
# ─────────────────────────────────────────────────────────────────────────────
static func pick_npc_move(npc_move_keys: Array, npc_element: String,
        player_element: String, player_status: Variant) -> String:

    # Filter out reflect moves
    var filtered_keys: Array = []
    for key in npc_move_keys:
        var move: Dictionary = GameData.MOVES.get(key, {})
        if not move.get("is_reflect", false):
            filtered_keys.append(key)

    var available_keys: Array = filtered_keys.duplicate()
    if not available_keys.has("basic_attack"):
        available_keys.append("basic_attack")

    # Super-effective moves
    var super_effective: Array = []
    for key in available_keys:
        var move: Dictionary = GameData.MOVES.get(key, {})
        if move.size() > 0 and get_type_effectiveness(move.get("element", "neutral"), player_element) > 1.0:
            super_effective.append(key)

    if super_effective.size() > 0 and randf() < 0.7:
        return super_effective[randi() % super_effective.size()]

    # Status-applying moves when target has no status
    if player_status == null and randf() < 0.4:
        var status_moves: Array = []
        for key in filtered_keys:
            var move: Dictionary = GameData.MOVES.get(key, {})
            if move.get("can_apply_status", false):
                status_moves.append(key)
        if status_moves.size() > 0:
            return status_moves[randi() % status_moves.size()]

    # Prefer higher-power moves (60% chance)
    if filtered_keys.size() > 1 and randf() < 0.6:
        var sorted: Array = filtered_keys.duplicate()
        sorted.sort_custom(func(a, b):
            return GameData.MOVES.get(b, {}).get("power", 0) < GameData.MOVES.get(a, {}).get("power", 0)
        )
        return sorted[0]

    # Otherwise random from themed or all moves
    var preferred: Array = filtered_keys if filtered_keys.size() > 0 and randf() < 0.7 else available_keys
    return preferred[randi() % preferred.size()]

# ─────────────────────────────────────────────────────────────────────────────
# resolve_turn(player_state, npc_state, player_move_key, npc_move_key,
#              player_move_keys, npc_move_keys) -> Dictionary
# Returns: { player, npc, events }
# ─────────────────────────────────────────────────────────────────────────────
static func resolve_turn(
        player_state: Dictionary, npc_state: Dictionary,
        player_move_key: String,  npc_move_key: String,
        player_move_keys: Array,  npc_move_keys: Array) -> Dictionary:

    var player: Dictionary = player_state.duplicate(true)
    var npc:    Dictionary = npc_state.duplicate(true)
    player["defending"]  = false
    npc["defending"]     = false
    var events: Array = []

    var player_first: bool = player.get("spd", 0) >= npc.get("spd", 0)

    var first_label:  String = "player" if player_first else "npc"
    var second_label: String = "npc"    if player_first else "player"
    var first_move:   String = player_move_key if player_first else npc_move_key
    var second_move:  String = npc_move_key    if player_first else player_move_key

    # Glitch: randomize move for first actor
    var first_state: Dictionary = player if player_first else npc
    if first_state.get("status", null) != null and first_state["status"].get("effect") == "void":
        var glitch_keys: Array = player_move_keys if player_first else npc_move_keys
        if glitch_keys.size() > 0:
            first_move = glitch_keys[randi() % glitch_keys.size()]

    # Glitch: randomize move for second actor
    var second_state: Dictionary = npc if player_first else player
    if second_state.get("status", null) != null and second_state["status"].get("effect") == "void":
        var glitch_keys: Array = npc_move_keys if player_first else player_move_keys
        if glitch_keys.size() > 0:
            second_move = glitch_keys[randi() % glitch_keys.size()]

    # Resolve first actor
    _resolve_action(first_label, first_move, player, npc, events, player_move_keys, npc_move_keys)

    # Check KO before second actor
    var first_target: Dictionary = npc if first_label == "player" else player
    if first_target.get("hp", 0) > 0:
        _resolve_action(second_label, second_move, player, npc, events, player_move_keys, npc_move_keys)

    # Status ticks (alive combatants only)
    if player.get("hp", 0) > 0 and player.get("status") != null:
        var tick := process_status_tick(player.merge({ "max_hp": player_state.get("max_hp", player.get("max_hp", 0)) }, true))
        player["hp"]     = tick["hp"]
        player["status"] = tick["status"]
        if tick.get("status_event") != null:
            var ev: Dictionary = tick["status_event"].duplicate()
            ev["attacker"] = "status"
            ev["target"]   = "player"
            events.append(ev)

    if npc.get("hp", 0) > 0 and npc.get("status") != null:
        var tick := process_status_tick(npc.merge({ "max_hp": npc_state.get("max_hp", npc.get("max_hp", 0)) }, true))
        npc["hp"]     = tick["hp"]
        npc["status"] = tick["status"]
        if tick.get("status_event") != null:
            var ev: Dictionary = tick["status_event"].duplicate()
            ev["attacker"] = "status"
            ev["target"]   = "npc"
            events.append(ev)

    player["reflecting"] = false
    npc["reflecting"]    = false

    return { "player": player, "npc": npc, "events": events }

# ─────────────────────────────────────────────────────────────────────────────
# _resolve_action — internal helper (mutates player/npc via reference via Array wrapper)
# Using in/out pattern: player and npc are modified in place (Dictionaries are reference-like
# when passed to inner static functions that receive them directly — but GDScript static funcs
# do NOT share scope). We pass them as explicit ref params and reassign in the caller above.
# ─────────────────────────────────────────────────────────────────────────────
static func _resolve_action(
        actor_label: String, move_key: String,
        player: Dictionary, npc: Dictionary,
        events: Array,
        player_move_keys: Array, npc_move_keys: Array) -> void:

    var actor_state:  Dictionary = player if actor_label == "player" else npc
    var target_state: Dictionary = npc    if actor_label == "player" else player

    # Freeze: skip entirely
    if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "ice":
        events.append({ "attacker": actor_label, "action": "statusSkip", "status_name": "Freeze" })
        return

    # Paralyze: 50% chance to skip
    if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "storm":
        if randf() < GameData.STATUS_EFFECTS["storm"]["value"]:
            events.append({ "attacker": actor_label, "action": "statusSkip", "status_name": "Paralyze" })
            return

    # Defend
    if move_key == "defend":
        actor_state["defending"] = true
        if actor_label == "player": player.merge(actor_state, true)
        else:                       npc.merge(actor_state, true)
        events.append({ "attacker": actor_label, "action": "defend", "damage": 0, "effectiveness": 1.0, "hit": true })
        return

    var move_data: Dictionary = GameData.MOVES.get(move_key, {})
    var move:      Dictionary = move_data if move_data.size() > 0 else GameData.MOVES["basic_attack"]

    # Reflect: set reflecting flag
    if move.get("is_reflect", false):
        actor_state["reflecting"] = true
        if actor_label == "player": player.merge(actor_state, true)
        else:                       npc.merge(actor_state, true)
        events.append({
            "attacker": actor_label, "action": "reflect",
            "move_name": move["name"], "move_key": move_key,
            "damage": 0, "effectiveness": 1.0, "hit": true,
        })
        return

    # Apply Guard Break debuff to effective DEF
    var effective_def: float = target_state.get("def", 0)
    if target_state.get("status", null) != null and target_state["status"].get("effect") == "stone":
        effective_def = int(effective_def * (1.0 - GameData.STATUS_EFFECTS["stone"]["value"]))

    # Apply Blind debuff to effective accuracy
    var effective_accuracy: float = move.get("accuracy", 100)
    if actor_state.get("status", null) != null and actor_state["status"].get("effect") == "shadow":
        effective_accuracy = maxf(0.0, effective_accuracy - GameData.STATUS_EFFECTS["shadow"]["value"] * 100.0)

    var damage_result: Dictionary = calculate_damage(
        { "atk": actor_state.get("atk", 0), "element": actor_state.get("element", "neutral"), "stage": actor_state.get("stage", 3) },
        { "def": effective_def,              "element": target_state.get("element", "neutral"), "defending": target_state.get("defending", false) },
        { "element": move.get("element", "neutral"), "power": move.get("power", 40), "accuracy": effective_accuracy }
    )

    # Reflect: damage redirected to attacker
    if target_state.get("reflecting", false):
        if damage_result["hit"]:
            var new_self_hp: int = maxi(0, actor_state.get("hp", 0) - damage_result["damage"])
            actor_state["hp"] = new_self_hp
            target_state["reflecting"] = false
            if actor_label == "player": player.merge(actor_state, true)
            else:                       npc.merge(actor_state, true)
            if actor_label == "player": npc.merge(target_state, true)
            else:                       player.merge(target_state, true)
            events.append({
                "attacker": actor_label, "action": "attack",
                "move_name": move["name"], "move_key": move_key,
                "damage": damage_result["damage"], "effectiveness": damage_result["effectiveness"],
                "hit": true, "reflected": true, "is_critical": damage_result["is_critical"],
                "target_hp": new_self_hp,
            })
        else:
            target_state["reflecting"] = false
            if actor_label == "player": npc.merge(target_state, true)
            else:                       player.merge(target_state, true)
            events.append({
                "attacker": actor_label, "action": "attack",
                "move_name": move["name"], "move_key": move_key,
                "damage": 0, "effectiveness": damage_result["effectiveness"],
                "hit": false, "target_hp": target_state.get("hp", 0),
            })
        return

    var new_target_hp: int = maxi(0, target_state.get("hp", 0) - damage_result["damage"])
    target_state["hp"] = new_target_hp
    if actor_label == "player": npc.merge(target_state, true)
    else:                       player.merge(target_state, true)

    # Status application roll
    var applied_status_name: Variant = null
    if damage_result["hit"] and move.get("can_apply_status", false) and randf() < GameData.STATUS_APPLY_CHANCE:
        var status: Variant = apply_status(move.get("element", "neutral"))
        if status != null:
            target_state["status"] = status
            if actor_label == "player": npc.merge(target_state, true)
            else:                       player.merge(target_state, true)
            applied_status_name = GameData.STATUS_EFFECTS[status["effect"]]["name"]

    events.append({
        "attacker":       actor_label,
        "action":         "attack",
        "move_name":      move["name"],
        "move_key":       move_key,
        "damage":         damage_result["damage"],
        "effectiveness":  damage_result["effectiveness"],
        "hit":            damage_result["hit"],
        "is_critical":    damage_result["is_critical"],
        "target_hp":      new_target_hp,
        "applied_status": applied_status_name,
    })
```

### Step 1.3 — Run tests and verify green

- [ ] **Run GUT headless:**
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_battle_engine.gd
  ```
  All tests must pass (0 failures) before proceeding.

### Step 1.4 — Commit

- [ ] **Commit:**
  ```
  git add dragon-forge-godot/scripts/sim/battle_engine.gd dragon-forge-godot/tests/test_battle_engine.gd
  git commit -m "Add Godot BattleEngine + GUT tests passing (Plan 3 step 1)"
  ```

---

## Task 2: Fusion Engine

Port `src/fusionEngine.js` → `dragon-forge-godot/scripts/sim/fusion_engine.gd`.

### Step 2.1 — Write failing GUT test

**File:** `dragon-forge-godot/tests/test_fusion_engine.gd`

- [ ] **Create `tests/test_fusion_engine.gd`**

```gdscript
extends GutTest

const FusionEngine = preload("res://scripts/sim/fusion_engine.gd")

# ── get_fusion_element ────────────────────────────────────────────────────────

func test_same_element_fusion_returns_self() -> void:
    assert_eq(FusionEngine.get_fusion_element("fire",   "fire"),   "fire")
    assert_eq(FusionEngine.get_fusion_element("shadow", "shadow"), "shadow")

func test_fire_plus_ice_is_storm() -> void:
    assert_eq(FusionEngine.get_fusion_element("fire", "ice"), "storm")
    assert_eq(FusionEngine.get_fusion_element("ice",  "fire"), "storm")

func test_fire_plus_venom_is_shadow() -> void:
    assert_eq(FusionEngine.get_fusion_element("fire",  "venom"), "shadow")
    assert_eq(FusionEngine.get_fusion_element("venom", "fire"),  "shadow")

func test_fusion_element_is_commutative() -> void:
    assert_eq(FusionEngine.get_fusion_element("ice",    "storm"),
              FusionEngine.get_fusion_element("storm",  "ice"))
    assert_eq(FusionEngine.get_fusion_element("stone",  "shadow"),
              FusionEngine.get_fusion_element("shadow", "stone"))

# ── get_stability_tier ────────────────────────────────────────────────────────

func test_same_element_is_stable() -> void:
    assert_eq(FusionEngine.get_stability_tier("fire", "fire"), "stable")

func test_opposing_elements_are_unstable() -> void:
    assert_eq(FusionEngine.get_stability_tier("fire",  "ice"),    "unstable")
    assert_eq(FusionEngine.get_stability_tier("storm", "stone"),  "unstable")
    assert_eq(FusionEngine.get_stability_tier("venom", "shadow"), "unstable")

func test_non_opposing_different_is_normal() -> void:
    assert_eq(FusionEngine.get_stability_tier("fire",  "storm"), "normal")
    assert_eq(FusionEngine.get_stability_tier("ice",   "venom"), "normal")

# ── calculate_fusion_stats ────────────────────────────────────────────────────
# parentA: hp=100, atk=30, def=20, spd=20
# parentB: hp=80,  atk=20, def=30, spd=10
# avg:     hp=90,  atk=25, def=25, spd=15
# fused(1.1x): hp=99, atk=27, def=27, spd=16

func test_normal_fusion_10pct_bonus() -> void:
    var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
    var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
    assert_eq(FusionEngine.calculate_fusion_stats(a, b, "normal"),
              { "hp": 99, "atk": 27, "def": 27, "spd": 16 })

func test_stable_fusion_25pct_bonus() -> void:
    var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
    var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
    assert_eq(FusionEngine.calculate_fusion_stats(a, b, "stable"),
              { "hp": 123, "atk": 33, "def": 33, "spd": 20 })

func test_unstable_fusion_hp_penalty_atk_bonus() -> void:
    var a := { "hp": 100, "atk": 30, "def": 20, "spd": 20 }
    var b := { "hp": 80,  "atk": 20, "def": 30, "spd": 10 }
    assert_eq(FusionEngine.calculate_fusion_stats(a, b, "unstable"),
              { "hp": 79, "atk": 29, "def": 27, "spd": 16 })

# ── execute_fusion ────────────────────────────────────────────────────────────

func test_execute_fusion_element_and_stability() -> void:
    var a := { "id": "fire", "element": "fire",
               "stats": { "hp": 110, "atk": 28, "def": 20, "spd": 18 },
               "level": 12, "shiny": false }
    var b := { "id": "ice",  "element": "ice",
               "stats": { "hp": 100, "atk": 24, "def": 26, "spd": 20 },
               "level": 10, "shiny": false }
    var result := FusionEngine.execute_fusion(a, b)
    assert_eq(result.element,        "storm")
    assert_eq(result.stability_tier, "unstable")
    assert_true(result.fused_base_stats.has("hp"))
    assert_eq(result.level, 1)
    assert_false(result.shiny)

func test_execute_fusion_inherits_shiny_from_parent_a() -> void:
    var a := { "id": "fire",  "element": "fire",  "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 12, "shiny": true  }
    var b := { "id": "storm", "element": "storm", "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 12, "shiny": false }
    assert_true(FusionEngine.execute_fusion(a, b).shiny)

func test_execute_fusion_stage_iv_elder_when_both_stage_iii() -> void:
    var a := { "id": "fire", "element": "fire",
               "stats": { "hp": 200, "atk": 50, "def": 40, "spd": 40 }, "level": 30, "shiny": false }
    var b := { "id": "fire", "element": "fire",
               "stats": { "hp": 200, "atk": 50, "def": 40, "spd": 40 }, "level": 25, "shiny": false }
    assert_eq(FusionEngine.execute_fusion(a, b).level, 50)

func test_execute_fusion_stays_level_1_if_not_both_stage_iii() -> void:
    var a := { "id": "fire", "element": "fire",
               "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 24, "shiny": false }
    var b := { "id": "fire", "element": "fire",
               "stats": { "hp": 100, "atk": 20, "def": 20, "spd": 20 }, "level": 25, "shiny": false }
    assert_eq(FusionEngine.execute_fusion(a, b).level, 1)
```

### Step 2.2 — Implement `fusion_engine.gd`

**File:** `dragon-forge-godot/scripts/sim/fusion_engine.gd`

- [ ] **Create `scripts/sim/fusion_engine.gd`**

```gdscript
extends RefCounted
class_name FusionEngine

# ALCHEMY table — sorted key lookup (e.g. "fire_ice" not "ice_fire")
const ALCHEMY: Dictionary = {
    "fire_fire":     "fire",
    "ice_ice":       "ice",
    "storm_storm":   "storm",
    "stone_stone":   "stone",
    "venom_venom":   "venom",
    "shadow_shadow": "shadow",
    "fire_ice":      "storm",
    "fire_storm":    "fire",
    "fire_stone":    "stone",
    "fire_venom":    "shadow",
    "fire_shadow":   "fire",
    "ice_storm":     "ice",
    "ice_stone":     "stone",
    "ice_venom":     "venom",
    "ice_shadow":    "shadow",
    "stone_storm":   "storm",
    "storm_venom":   "venom",
    "shadow_storm":  "shadow",
    "stone_venom":   "venom",
    "shadow_stone":  "stone",
    "shadow_venom":  "shadow",
}

const OPPOSING_PAIRS: Array = [
    ["fire",  "ice"],
    ["storm", "stone"],
    ["venom", "shadow"],
]

# ─────────────────────────────────────────────────────────────────────────────
# get_fusion_element(element_a, element_b) -> String
# ─────────────────────────────────────────────────────────────────────────────
static func get_fusion_element(element_a: String, element_b: String) -> String:
    var key: String = _sorted_key(element_a, element_b)
    return ALCHEMY.get(key, element_a)

# ─────────────────────────────────────────────────────────────────────────────
# get_stability_tier(element_a, element_b) -> String  ("stable"|"normal"|"unstable")
# ─────────────────────────────────────────────────────────────────────────────
static func get_stability_tier(element_a: String, element_b: String) -> String:
    if element_a == element_b:
        return "stable"
    for pair in OPPOSING_PAIRS:
        if (element_a == pair[0] and element_b == pair[1]) or \
           (element_a == pair[1] and element_b == pair[0]):
            return "unstable"
    return "normal"

# ─────────────────────────────────────────────────────────────────────────────
# calculate_fusion_stats(stats_a, stats_b, stability_tier) -> Dictionary
# ─────────────────────────────────────────────────────────────────────────────
static func calculate_fusion_stats(stats_a: Dictionary, stats_b: Dictionary, stability_tier: String) -> Dictionary:
    var avg := {
        "hp":  (stats_a.get("hp",  0) + stats_b.get("hp",  0)) / 2.0,
        "atk": (stats_a.get("atk", 0) + stats_b.get("atk", 0)) / 2.0,
        "def": (stats_a.get("def", 0) + stats_b.get("def", 0)) / 2.0,
        "spd": (stats_a.get("spd", 0) + stats_b.get("spd", 0)) / 2.0,
    }

    var fused := {
        "hp":  int(avg["hp"]  * 1.1),
        "atk": int(avg["atk"] * 1.1),
        "def": int(avg["def"] * 1.1),
        "spd": int(avg["spd"] * 1.1),
    }

    match stability_tier:
        "stable":
            fused["hp"]  = int(fused["hp"]  * 1.25)
            fused["atk"] = int(fused["atk"] * 1.25)
            fused["def"] = int(fused["def"] * 1.25)
            fused["spd"] = int(fused["spd"] * 1.25)
        "unstable":
            fused["hp"]  = int(fused["hp"]  * 0.8)
            fused["atk"] = int(fused["atk"] * 1.1)

    return fused

# ─────────────────────────────────────────────────────────────────────────────
# execute_fusion(parent_a, parent_b) -> Dictionary
# parent: { id, element, stats{hp,atk,def,spd}, level, shiny }
# ─────────────────────────────────────────────────────────────────────────────
static func execute_fusion(parent_a: Dictionary, parent_b: Dictionary) -> Dictionary:
    var element:          String     = get_fusion_element(parent_a.get("element", "fire"), parent_b.get("element", "fire"))
    var stability_tier:   String     = get_stability_tier(parent_a.get("element", "fire"), parent_b.get("element", "fire"))
    var fused_base_stats: Dictionary = calculate_fusion_stats(
        parent_a.get("stats", {}), parent_b.get("stats", {}), stability_tier)
    var shiny: bool = parent_a.get("shiny", false) or parent_b.get("shiny", false)

    var both_stage_iii: bool = parent_a.get("level", 0) >= 25 and parent_b.get("level", 0) >= 25
    var level: int = 50 if both_stage_iii else 1

    return {
        "element":          element,
        "stability_tier":   stability_tier,
        "fused_base_stats": fused_base_stats,
        "shiny":            shiny,
        "level":            level,
        "xp":               0,
        "parent_a_id":      parent_a.get("id", ""),
        "parent_b_id":      parent_b.get("id", ""),
    }

# ─────────────────────────────────────────────────────────────────────────────
# _sorted_key — internal
# ─────────────────────────────────────────────────────────────────────────────
static func _sorted_key(a: String, b: String) -> String:
    var parts := [a, b]
    parts.sort()
    return "%s_%s" % [parts[0], parts[1]]
```

### Step 2.3 — Run tests

- [ ] **Run GUT headless:**
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_fusion_engine.gd
  ```

### Step 2.4 — Commit

- [ ] **Commit:**
  ```
  git add dragon-forge-godot/scripts/sim/fusion_engine.gd dragon-forge-godot/tests/test_fusion_engine.gd
  git commit -m "Add Godot FusionEngine + GUT tests passing (Plan 3 step 2)"
  ```

---

## Task 3: Hatchery Engine

Port `src/hatcheryEngine.js` → `dragon-forge-godot/scripts/sim/hatchery_engine.gd`.

### Step 3.1 — Write failing GUT test

**File:** `dragon-forge-godot/tests/test_hatchery_engine.gd`

- [ ] **Create `tests/test_hatchery_engine.gd`**

```gdscript
extends GutTest

const HatcheryEngine = preload("res://scripts/sim/hatchery_engine.gd")
const GameData       = preload("res://scripts/sim/game_data.gd")

# ── roll_rarity ───────────────────────────────────────────────────────────────

func test_roll_rarity_returns_valid_object() -> void:
    var result := HatcheryEngine.roll_rarity(0)
    assert_true(result.has("name"),       "missing name")
    assert_true(result.has("elements"),   "missing elements")
    assert_true(result.has("multiplier"), "missing multiplier")

func test_roll_rarity_forces_rare_plus_at_pity() -> void:
    var rare_or_exotic_count := 0
    for _i in range(50):
        var result := HatcheryEngine.roll_rarity(9)
        if result["name"] == "Rare" or result["name"] == "Exotic":
            rare_or_exotic_count += 1
    assert_eq(rare_or_exotic_count, 50, "pity=9 must always yield Rare+")

func test_roll_rarity_valid_name_at_normal_pity() -> void:
    var valid_names := ["Common", "Uncommon", "Rare", "Exotic"]
    for _i in range(20):
        assert_true(valid_names.has(HatcheryEngine.roll_rarity(0)["name"]))

# ── roll_element ──────────────────────────────────────────────────────────────

func test_roll_element_from_uncommon_tier() -> void:
    var tier := { "name": "Uncommon", "elements": ["storm", "venom", "stone"], "multiplier": 2 }
    for _i in range(20):
        assert_true(["storm", "venom", "stone"].has(HatcheryEngine.roll_element(tier)))

func test_roll_element_single_element_tier() -> void:
    var tier := { "name": "Rare", "elements": ["shadow"], "multiplier": 3 }
    assert_eq(HatcheryEngine.roll_element(tier), "shadow")

# ── roll_shiny ────────────────────────────────────────────────────────────────

func test_roll_shiny_returns_bool() -> void:
    var result := HatcheryEngine.roll_shiny(false)
    assert_true(result == true or result == false)

func test_roll_shiny_guaranteed_always_true() -> void:
    for _i in range(20):
        assert_true(HatcheryEngine.roll_shiny(true))

# ── execute_pull ──────────────────────────────────────────────────────────────

func test_execute_pull_result_shape() -> void:
    var result := HatcheryEngine.execute_pull(0)
    assert_true(result.has("element"),          "missing element")
    assert_true(result.has("rarity_name"),      "missing rarity_name")
    assert_true(result.has("rarity_multiplier"),"missing rarity_multiplier")
    assert_true(result.has("shiny"),             "missing shiny")
    assert_true(result.has("new_pity_counter"),  "missing new_pity_counter")

func test_execute_pull_resets_pity_on_rare_plus() -> void:
    var result := HatcheryEngine.execute_pull(9)
    assert_eq(result.new_pity_counter, 0)

func test_execute_pull_increments_pity_on_common_or_uncommon() -> void:
    var found_non_rare := false
    for _i in range(100):
        var result := HatcheryEngine.execute_pull(0)
        if result.rarity_name == "Common" or result.rarity_name == "Uncommon":
            assert_eq(result.new_pity_counter, 1)
            found_non_rare = true
            break
    assert_true(found_non_rare, "never got a Common/Uncommon in 100 pulls")

# ── apply_pull_result ─────────────────────────────────────────────────────────

func _base_save_with_fire_unowned() -> Dictionary:
    return {
        "dragons":      { "fire": { "level": 1, "xp": 0, "owned": false, "shiny": false } },
        "data_scraps":  100,
        "pity_counter": 0,
    }

func _base_save_with_fire_owned() -> Dictionary:
    return {
        "dragons":      { "fire": { "level": 1, "xp": 0, "owned": true, "shiny": false } },
        "data_scraps":  100,
        "pity_counter": 0,
    }

func test_apply_pull_unlocks_new_dragon() -> void:
    var save := _base_save_with_fire_unowned()
    var pull := { "element": "fire", "rarity_name": "Common", "rarity_multiplier": 1, "shiny": false, "new_pity_counter": 1 }
    var result := HatcheryEngine.apply_pull_result(save, pull)
    assert_true(result.save.dragons.fire.owned)
    assert_true(result.is_new)
    assert_eq(result.xp_gained, 0)

func test_apply_pull_merges_duplicate_with_xp() -> void:
    var save := _base_save_with_fire_owned()
    var pull := { "element": "fire", "rarity_name": "Uncommon", "rarity_multiplier": 2, "shiny": false, "new_pity_counter": 1 }
    var result := HatcheryEngine.apply_pull_result(save, pull)
    assert_false(result.is_new)
    assert_eq(result.xp_gained, 100)
    assert_eq(result.save.dragons.fire.xp, 0)
    assert_eq(result.save.dragons.fire.level, 2)

func test_apply_pull_upgrades_to_shiny_on_duplicate() -> void:
    var save := {
        "dragons":      { "shadow": { "level": 5, "xp": 20, "owned": true, "shiny": false } },
        "data_scraps":  100,
        "pity_counter": 0,
    }
    var pull := { "element": "shadow", "rarity_name": "Rare", "rarity_multiplier": 3, "shiny": true, "new_pity_counter": 0 }
    var result := HatcheryEngine.apply_pull_result(save, pull)
    assert_true(result.save.dragons.shadow.shiny)

func test_apply_pull_updates_pity_counter() -> void:
    var save := _base_save_with_fire_unowned()
    save.pity_counter = 3
    var pull := { "element": "fire", "rarity_name": "Common", "rarity_multiplier": 1, "shiny": false, "new_pity_counter": 4 }
    var result := HatcheryEngine.apply_pull_result(save, pull)
    assert_eq(result.save.pity_counter, 4)

func test_apply_pull_levels_up_on_excess_xp() -> void:
    var save := {
        "dragons":      { "fire": { "level": 1, "xp": 80, "owned": true, "shiny": false } },
        "data_scraps":  100,
        "pity_counter": 0,
    }
    var pull := { "element": "fire", "rarity_name": "Exotic", "rarity_multiplier": 5, "shiny": false, "new_pity_counter": 0 }
    var result := HatcheryEngine.apply_pull_result(save, pull)
    # 80 existing xp + 250 gained = 330; 330/100 = 3 level-ups remainder 30
    assert_eq(result.save.dragons.fire.level, 4)
    assert_eq(result.save.dragons.fire.xp, 30)
    assert_eq(result.xp_gained, 250)
```

### Step 3.2 — Implement `hatchery_engine.gd`

**File:** `dragon-forge-godot/scripts/sim/hatchery_engine.gd`

- [ ] **Create `scripts/sim/hatchery_engine.gd`**

```gdscript
extends RefCounted
class_name HatcheryEngine

const GameData = preload("res://scripts/sim/game_data.gd")

# ─────────────────────────────────────────────────────────────────────────────
# roll_rarity(pity_counter) -> Dictionary  (a rarity tier entry from RARITY_TIERS)
# ─────────────────────────────────────────────────────────────────────────────
static func roll_rarity(pity_counter: int) -> Dictionary:
    # Pity: force Rare+ when counter hits threshold-1
    if pity_counter >= GameData.PITY_THRESHOLD - 1:
        var rare_and_above: Array = []
        for tier in GameData.RARITY_TIERS:
            if tier["name"] == "Rare" or tier["name"] == "Exotic":
                rare_and_above.append(tier)
        var total_chance: float = 0.0
        for tier in rare_and_above:
            total_chance += tier["chance"]
        var roll: float = randf() * total_chance
        for tier in rare_and_above:
            roll -= tier["chance"]
            if roll <= 0.0:
                return tier
        return rare_and_above[rare_and_above.size() - 1]

    # Normal roll
    var roll: float = randf()
    for tier in GameData.RARITY_TIERS:
        roll -= tier["chance"]
        if roll <= 0.0:
            return tier
    return GameData.RARITY_TIERS[GameData.RARITY_TIERS.size() - 1]

# ─────────────────────────────────────────────────────────────────────────────
# roll_element(rarity_tier) -> String
# ─────────────────────────────────────────────────────────────────────────────
static func roll_element(rarity_tier: Dictionary) -> String:
    var elements: Array = rarity_tier.get("elements", ["fire"])
    return elements[randi() % elements.size()]

# ─────────────────────────────────────────────────────────────────────────────
# roll_shiny(guaranteed_shiny) -> bool
# ─────────────────────────────────────────────────────────────────────────────
static func roll_shiny(guaranteed_shiny: bool) -> bool:
    if guaranteed_shiny:
        return true
    return randf() < GameData.SHINY_CHANCE

# ─────────────────────────────────────────────────────────────────────────────
# execute_pull(pity_counter) -> Dictionary
# Returns: { element, rarity_name, rarity_multiplier, shiny, new_pity_counter }
# ─────────────────────────────────────────────────────────────────────────────
static func execute_pull(pity_counter: int) -> Dictionary:
    var rarity_tier: Dictionary = roll_rarity(pity_counter)
    var element:     String     = roll_element(rarity_tier)
    var shiny:       bool       = roll_shiny(rarity_tier.get("guaranteed_shiny", false))

    var is_rare_plus: bool = rarity_tier["name"] == "Rare" or rarity_tier["name"] == "Exotic"
    var new_pity:     int  = 0 if is_rare_plus else pity_counter + 1

    return {
        "element":          element,
        "rarity_name":      rarity_tier["name"],
        "rarity_multiplier": rarity_tier["multiplier"],
        "shiny":            shiny,
        "new_pity_counter": new_pity,
    }

# ─────────────────────────────────────────────────────────────────────────────
# apply_pull_result(save, pull) -> Dictionary
# save must contain: dragons (dict), pity_counter
# Returns: { save (deep copy), is_new, xp_gained }
# ─────────────────────────────────────────────────────────────────────────────
static func apply_pull_result(save: Dictionary, pull: Dictionary) -> Dictionary:
    var new_save: Dictionary = save.duplicate(true)
    var dragon:   Dictionary = new_save["dragons"][pull["element"]]
    var is_new:   bool       = false
    var xp_gained: int       = 0

    if not dragon.get("owned", false):
        dragon["owned"] = true
        if pull.get("shiny", false):
            dragon["shiny"] = true
        is_new = true
    else:
        xp_gained = 50 * pull.get("rarity_multiplier", 1)
        dragon["xp"] += xp_gained
        var xp_per_level: int = 100
        while dragon["xp"] >= xp_per_level:
            dragon["xp"]    -= xp_per_level
            dragon["level"] += 1
        if pull.get("shiny", false) and not dragon.get("shiny", false):
            dragon["shiny"] = true

    new_save["pity_counter"] = pull.get("new_pity_counter", 0)

    return { "save": new_save, "is_new": is_new, "xp_gained": xp_gained }
```

### Step 3.3 — Run tests

- [ ] **Run GUT headless:**
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_hatchery_engine.gd
  ```

### Step 3.4 — Commit

- [ ] **Commit:**
  ```
  git add dragon-forge-godot/scripts/sim/hatchery_engine.gd dragon-forge-godot/tests/test_hatchery_engine.gd
  git commit -m "Add Godot HatcheryEngine + GUT tests passing (Plan 3 step 3)"
  ```

---

## Task 4: Singularity Progress

Port `src/singularityProgress.js` → `dragon-forge-godot/scripts/sim/singularity_progress.gd`.

### Step 4.1 — Write failing GUT test

**File:** `dragon-forge-godot/tests/test_singularity_progress.gd`

- [ ] **Create `tests/test_singularity_progress.gd`**

```gdscript
extends GutTest

const SingularityProgress = preload("res://scripts/sim/singularity_progress.gd")

# Helper: build a save dict
func _save(owned_elements: Array = [], defeated_npcs: Array = [],
           has_elder: bool = false, singularity_complete: bool = false) -> Dictionary:
    var dragons := {}
    for el in ["fire", "ice", "storm", "stone", "venom", "shadow"]:
        dragons[el] = {
            "owned": owned_elements.has(el),
            "level": 50 if (has_elder and owned_elements.has(el)) else 1,
        }
    return {
        "dragons":             dragons,
        "defeated_npcs":       defeated_npcs,
        "singularity_complete": singularity_complete,
    }

# ── get_singularity_stage ─────────────────────────────────────────────────────

func test_stage_0_no_dragons() -> void:
    assert_eq(SingularityProgress.get_singularity_stage(_save()), 0)

func test_stage_1_two_owned() -> void:
    assert_eq(SingularityProgress.get_singularity_stage(_save(["fire", "ice"])), 1)

func test_stage_2_four_owned() -> void:
    assert_eq(SingularityProgress.get_singularity_stage(
        _save(["fire", "ice", "storm", "stone"])), 2)

func test_stage_3_six_owned() -> void:
    assert_eq(SingularityProgress.get_singularity_stage(
        _save(["fire", "ice", "storm", "stone", "venom", "shadow"])), 3)

func test_stage_4_has_elder() -> void:
    assert_eq(SingularityProgress.get_singularity_stage(
        _save(["fire"], [], true)), 4)

func test_stage_5_all_base_npcs_defeated() -> void:
    var npcs := ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
    assert_eq(SingularityProgress.get_singularity_stage(_save([], npcs)), 5)

func test_singularity_complete_returns_3() -> void:
    # singularityComplete overrides — returns 3 per JS spec
    assert_eq(SingularityProgress.get_singularity_stage(
        _save([], [], false, true)), 3)

# ── is_singularity_unlocked ───────────────────────────────────────────────────

func test_not_unlocked_without_all_npcs() -> void:
    assert_false(SingularityProgress.is_singularity_unlocked(
        _save([], ["firewall_sentinel"])))

func test_unlocked_when_all_base_npcs_defeated() -> void:
    var npcs := ["firewall_sentinel", "bit_wraith", "glitch_hydra", "recursive_golem"]
    assert_true(SingularityProgress.is_singularity_unlocked(_save([], npcs)))

func test_unlocked_when_singularity_complete() -> void:
    assert_true(SingularityProgress.is_singularity_unlocked(
        _save([], [], false, true)))
```

### Step 4.2 — Implement `singularity_progress.gd`

**File:** `dragon-forge-godot/scripts/sim/singularity_progress.gd`

- [ ] **Create `scripts/sim/singularity_progress.gd`**

```gdscript
extends RefCounted
class_name SingularityProgress

const GameData = preload("res://scripts/sim/game_data.gd")

# ─────────────────────────────────────────────────────────────────────────────
# get_singularity_stage(save) -> int  (0–5)
# save: { dragons{el:{owned,level}}, defeated_npcs[], singularity_complete }
# ─────────────────────────────────────────────────────────────────────────────
static func get_singularity_stage(save: Dictionary) -> int:
    if save.get("singularity_complete", false):
        return 3

    var owned_count: int = 0
    for el in GameData.BASE_ELEMENTS:
        if save.get("dragons", {}).get(el, {}).get("owned", false):
            owned_count += 1

    var has_elder: bool = false
    for el in save.get("dragons", {}).keys():
        var d: Dictionary = save["dragons"][el]
        if d.get("owned", false) and d.get("level", 0) >= 50:
            has_elder = true
            break

    var defeated_npcs: Array = save.get("defeated_npcs", [])
    var all_npcs_defeated: bool = true
    for npc_id in GameData.BASE_NPC_IDS:
        if not defeated_npcs.has(npc_id):
            all_npcs_defeated = false
            break

    if all_npcs_defeated: return 5
    if has_elder:         return 4
    if owned_count >= 6:  return 3
    if owned_count >= 4:  return 2
    if owned_count >= 2:  return 1
    return 0

# ─────────────────────────────────────────────────────────────────────────────
# is_singularity_unlocked(save) -> bool
# ─────────────────────────────────────────────────────────────────────────────
static func is_singularity_unlocked(save: Dictionary) -> bool:
    if save.get("singularity_complete", false):
        return true
    var defeated_npcs: Array = save.get("defeated_npcs", [])
    for npc_id in GameData.BASE_NPC_IDS:
        if not defeated_npcs.has(npc_id):
            return false
    return true
```

### Step 4.3 — Run tests

- [ ] **Run GUT headless:**
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gtest=res://tests/test_singularity_progress.gd
  ```

### Step 4.4 — Commit

- [ ] **Commit:**
  ```
  git add dragon-forge-godot/scripts/sim/singularity_progress.gd dragon-forge-godot/tests/test_singularity_progress.gd
  git commit -m "Add Godot SingularityProgress + GUT tests passing (Plan 3 step 4)"
  ```

---

## Task 5: Full Suite Green Gate

Run all four test files at once. Zero failures is the gate condition for Plan 4.

- [ ] **Step 5.1 — Run full suite:**
  ```powershell
  & 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gdir=res://tests/
  ```

- [ ] **Step 5.2 — Confirm output shows 0 failures.** If any test fails, fix it before proceeding. GUT exits with a non-zero code on failure — CI can use this.

- [ ] **Step 5.3 — Final commit:**
  ```
  git add -A
  git commit -m "Plan 3 complete: all engine GUT tests green (battle, fusion, hatchery, singularity)"
  ```

---

## Notes for implementers

### GUT installation
If GUT is not yet installed in the Godot project, add it as an addon before running any tests:
1. Download `gut-godot` release zip from https://github.com/bitwes/Gut/releases
2. Extract `addons/gut/` into `dragon-forge-godot/addons/gut/`
3. Enable in Project Settings → Plugins → GUT

### GDScript dictionary mutation vs. copy
GDScript Dictionaries are passed by reference in function calls but `duplicate(true)` deep-copies. In `resolve_turn` and `_resolve_action`, the pattern is to mutate the `player`/`npc` Dictionaries in place using `.merge(patch, true)` — this overwrites only the keys present in `patch`, preserving unrelated keys. This matches the JavaScript spread-merge pattern (`{ ...state, hp: newHp }`).

### camelCase → snake_case mapping
| JS key          | GDScript key       |
|-----------------|--------------------|
| `turnsLeft`     | `turns_left`       |
| `isCritical`    | `is_critical`      |
| `statusEvent`   | `status_event`     |
| `effectName`    | `effect_name`      |
| `canApplyStatus`| `can_apply_status` |
| `isReflect`     | `is_reflect`       |
| `rarityName`    | `rarity_name`      |
| `newPityCounter`| `new_pity_counter` |
| `rarityMultiplier` | `rarity_multiplier` |
| `xpGained`      | `xp_gained`        |
| `isNew`         | `is_new`           |
| `fusedBaseStats`| `fused_base_stats` |
| `stabilityTier` | `stability_tier`   |
| `parentAId`     | `parent_a_id`      |
| `parentBId`     | `parent_b_id`      |
| `guaranteedShiny` | `guaranteed_shiny` |
| `singularityComplete` | `singularity_complete` |
| `defeatedNpcs`  | `defeated_npcs`    |

### Random-dependent tests
Tests that call `roll_rarity`, `roll_element`, `roll_shiny`, `pick_npc_move`, or `calculate_damage` multiple times use the same approach as the vitest suite: run N iterations and assert statistical properties. These tests are non-deterministic by design — if they flake, the threshold N or the minimum count should be reviewed, not weakened.

### `void` element edge cases
`void` deals 1.0× against all elements and receives 1.0× from all elements. This is explicitly encoded in `TYPE_CHART` and verified in `test_void_attacking_any_is_neutral` / `test_any_attacking_void_is_neutral`.

### Status tick key difference
`processStatusTick` in JS returns `statusEvent: { type, damage, effectName, expired }`.  
The GDScript port uses snake_case: `status_event: { type, damage, effect_name, expired }`.  
The test file uses snake_case keys accordingly.
