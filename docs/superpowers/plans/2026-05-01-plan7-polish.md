# Dragon Forge Godot Rebuild — Plan 7: Polish

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the Godot build to a shippable v0.1 slice — controller support with rumble, screen transitions, properly mixed audio buses, tuned element particles, a headless smoke suite that covers all screens, and a clean git tag.

**Architecture:** Polish layers are additive — they wrap existing systems without replacing them. `InputMap` actions already exist; this plan wires rumble on top. Screen transitions are handled by an `AnimationPlayer` added to `scenes/main.tscn` and called from `_hide_all_screens` / `_on_screen_navigate` in `scripts/main.gd`. Audio buses `Music` and `SFX` were created in Plan 5 Task 7; this plan sets their default volumes and verifies AudioDirector routes to them. Particles live in `scenes/battle/battle_scene.tscn`; this plan tunes their `GPUParticles2D` export params per element. The smoke suite (`scripts/tests/sim_smoke.gd`) gains screen-load and no-error assertions. GUT engine tests run unchanged as a regression gate.

**Tech Stack:** Godot 4.6, GDScript, `AnimationPlayer`, `GPUParticles2D`, `Input.start_joy_vibration()`, `AudioServer`, headless `--script` runner.

**Prerequisite:** Plans 4 and 5 complete — all screens are playable, `scenes/main.tscn` exists, `scripts/main.gd` has `_hide_all_screens()` and `_on_screen_navigate()`, audio buses `Music` and `SFX` exist in `default_bus_layout.tres`, and all sim engine tests pass under `scripts/tests/sim_smoke.gd`.

---

## Task 1: Controller Support + Rumble

Ensure every InputMap action responds to a connected gamepad and add physical feedback on hit, KO, and crit.

**Files:**
- Modify: `dragon-forge-godot/scripts/battle/battle_scene.gd`
- Modify: `dragon-forge-godot/scripts/sim/signal_bus.gd`

- [ ] **Step 1.1 — Verify InputMap actions cover gamepad**

Open Godot editor → Project → Project Settings → Input Map. Confirm these actions exist and have both keyboard and joypad bindings:

| Action       | Keyboard    | Joypad              |
|--------------|-------------|---------------------|
| `confirm`    | Enter / Z   | Button 0 (A/Cross)  |
| `cancel`     | Escape / X  | Button 1 (B/Circle) |
| `ui_up`      | Up          | D-pad up / Left stick up |
| `ui_down`    | Down        | D-pad down / Left stick down |
| `ui_left`    | Left        | D-pad left          |
| `ui_right`   | Right       | D-pad right         |
| `attack_1`   | Z / Space   | Button 2 (X/Square) |
| `attack_2`   | X           | Button 3 (Y/Triangle) |

If any joypad binding is missing, add it in the editor and save the project. The input map is stored in `project.godot`.

- [ ] **Step 1.2 — Add rumble helper to battle_scene.gd**

In `dragon-forge-godot/scripts/battle/battle_scene.gd`, add this helper after the existing `func _ready()`:

```gdscript
# --- Rumble ---
func _rumble(weak: float, strong: float, duration: float) -> void:
	# Fires on all connected joypads (supports hot-plug).
	for device in Input.get_connected_joypads():
		Input.start_joy_vibration(device, weak, strong, duration)
```

- [ ] **Step 1.3 — Call rumble on hit, crit, and KO**

Locate the section of `battle_scene.gd` where battle results are applied (the function that receives the `resolve_attack` result dictionary from `CombatRules`). Add rumble calls:

```gdscript
# After a successful hit resolves:
if result.get("hit", false):
	var effectiveness: float = float(result.get("effectiveness", 1.0))
	if result.get("remaining_hp", 1) <= 0:
		# KO
		_rumble(0.6, 1.0, 0.5)
	elif effectiveness >= 2.0:
		# Super-effective crit
		_rumble(0.4, 0.8, 0.25)
	else:
		# Normal hit
		_rumble(0.2, 0.3, 0.1)
```

Use the actual variable name for the result dictionary in that function; do not create a new one.

- [ ] **Step 1.4 — Test with keyboard fallback (no gamepad required)**

Run the game in the editor (F5). Fight a battle. Confirm no GDScript errors. With a connected gamepad, verify rumble fires on a hit.

- [ ] **Step 1.5 — Commit**

```powershell
git add dragon-forge-godot/scripts/battle/battle_scene.gd dragon-forge-godot/project.godot
git commit -m "Add controller rumble for hit, crit, and KO (Plan 7)"
```

---

## Task 2: Screen Transitions

Add a 0.2 s fade-to-black between all screen changes.

**Files:**
- Modify: `dragon-forge-godot/scenes/main.tscn`
- Modify: `dragon-forge-godot/scripts/main.gd`

- [ ] **Step 2.1 — Add fade overlay to `main.tscn`**

In the Godot editor, open `scenes/main.tscn`. Add as the last child of the root `Control` (so it renders on top of everything):

```
ColorRect (id: fade_overlay)
  color: Color(0, 0, 0, 0)   # starts transparent
  anchors: full-rect (PRESET_FULL_RECT)
  mouse_filter: MOUSE_FILTER_IGNORE
AnimationPlayer (id: anim_player)
  # Animations defined in Step 2.2
```

Save the scene.

- [ ] **Step 2.2 — Create fade animations**

In the Godot editor, select `anim_player`. Create two animations:

**`fade_out`** (length 0.2 s):
- Track: `fade_overlay:modulate:a`
- Key at t=0.0: value `0.0`
- Key at t=0.2: value `1.0`
- Easing: linear

**`fade_in`** (length 0.2 s):
- Track: `fade_overlay:modulate:a`
- Key at t=0.0: value `1.0`
- Key at t=0.2: value `0.0`
- Easing: linear

Save the scene.

- [ ] **Step 2.3 — Use animations in `main.gd`**

Add at the top of `scripts/main.gd`:

```gdscript
@onready var anim_player: AnimationPlayer = $anim_player
```

Replace the existing `_on_screen_navigate` function body with a version that awaits the fade:

```gdscript
func _on_screen_navigate(target: String, context: Dictionary) -> void:
	# Fade out
	anim_player.play("fade_out")
	await anim_player.animation_finished
	# Switch screens
	_hide_all_screens()
	match target:
		"world":
			world_scene.visible = true
			_play_music_context("world_wandering")
		"battle":
			battle_scene.visible = true
			_play_music_context("battle_tension")
			battle_scene.start_battle(player_profile, context.get("npc_id", "firewall_sentinel"), context)
		"campaign_map":
			campaign_map_scene.visible = true
			campaign_map_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		"shop":
			shop_scene.visible = true
			shop_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		"forge":
			forge_scene.visible = true
			forge_scene.open(SaveIO.load_save())
			_play_music_context("forge_ambient")
		"journal":
			journal_scene.visible = true
			journal_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		"stats":
			stats_scene.visible = true
			stats_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		"settings":
			settings_scene.visible = true
			settings_scene.open(SaveIO.load_save())
			_play_music_context("world_wandering")
		"singularity":
			singularity_scene.visible = true
			singularity_scene.open(SaveIO.load_save())
			_play_music_context("singularity_tension")
		_:
			world_scene.visible = true
			_play_music_context("world_wandering")
	# Fade in
	anim_player.play("fade_in")
```

Also apply the same fade-out/in wrapper to `_on_encounter_requested` and `_on_battle_closed`:

```gdscript
func _on_encounter_requested(enemy_id: String, context: Dictionary = {}) -> void:
	anim_player.play("fade_out")
	await anim_player.animation_finished
	world_scene.visible = false
	battle_scene.visible = true
	_play_music_context("battle_tension")
	battle_scene.start_battle(player_profile, enemy_id, context)
	anim_player.play("fade_in")

func _on_battle_closed() -> void:
	anim_player.play("fade_out")
	await anim_player.animation_finished
	battle_scene.visible = false
	world_scene.visible = true
	_play_music_context("world_wandering")
	world_scene.set_profile(player_profile)
	anim_player.play("fade_in")
```

- [ ] **Step 2.4 — Verify in editor**

Run F5. Navigate from the world to a battle and back. Confirm a smooth 0.2 s black fade occurs on each transition with no flicker.

- [ ] **Step 2.5 — Commit**

```powershell
git add dragon-forge-godot/scenes/main.tscn dragon-forge-godot/scripts/main.gd
git commit -m "Add 0.2s fade-to-black screen transitions (Plan 7)"
```

---

## Task 3: Audio Mixing

Verify AudioDirector routes to the correct buses and set sensible default volumes.

**Files:**
- Modify: `dragon-forge-godot/scripts/sim/audio_director.gd`
- Modify: `dragon-forge-godot/default_bus_layout.tres`

- [ ] **Step 3.1 — Set default bus volumes**

In the Godot editor, open Project → Audio → Bus Layout. Set:

- Master: 0 dB
- Music:  −3 dB  (slightly below master to leave headroom for SFX)
- SFX:    0 dB

Save. This writes to `default_bus_layout.tres`.

- [ ] **Step 3.2 — Verify AudioDirector sends music to Music bus**

Open `dragon-forge-godot/scripts/sim/audio_director.gd`. Find `_prime_music_runtime()` (or whichever function assigns the `AudioStreamPlayer` for music). Confirm it sets the player's `bus` property to `"Music"`:

```gdscript
# Ensure this line exists inside _prime_music_runtime or _ensure_players:
music_player.bus = "Music"
sfx_player.bus = "SFX"
```

If those assignments are missing, add them. If the players are created with `AudioStreamPlayer.new()`, add the bus assignment immediately after `.new()`.

- [ ] **Step 3.3 — Verify SFX bus assignment for battle SFX**

Open `dragon-forge-godot/scripts/battle/battle_scene.gd`. Any `AudioStreamPlayer` nodes used for hit/crit/KO sounds should set `bus = "SFX"`. If they are child nodes in the scene tree, set the `Bus` property in the Godot editor's Inspector panel.

- [ ] **Step 3.4 — Manual audio check in editor**

Run F5. Start a battle. In the Godot editor Audio panel (bottom panel → Audio), verify the Music bus VU meter moves during `battle_tension` music and the SFX bus moves on hit sounds. Confirm adjusting the Settings screen music slider changes the Music bus level live.

- [ ] **Step 3.5 — Commit**

```powershell
git add dragon-forge-godot/scripts/sim/audio_director.gd dragon-forge-godot/default_bus_layout.tres
git commit -m "Set default audio bus volumes and verify AudioDirector bus routing (Plan 7)"
```

---

## Task 4: Particle Tuning

Tune each element's `GPUParticles2D` node in the battle scene to use the new particle textures from Plan 6 and match element colors from `gameData`.

**Files:**
- Modify: `dragon-forge-godot/scenes/battle/battle_scene.tscn`

Element color reference (from `src/gameData.js`):

| Element | Primary   | Glow      |
|---------|-----------|-----------|
| fire    | `#ff6622` | `#ff8844` |
| ice     | `#44aaff` | `#66ccff` |
| storm   | `#aa66ff` | `#cc88ff` |
| stone   | `#aa8844` | `#ccaa66` |
| venom   | `#44cc44` | `#66ee66` |
| shadow  | `#8844aa` | `#aa66cc` |

- [ ] **Step 4.1 — Open battle_scene.tscn in the editor**

Open `scenes/battle/battle_scene.tscn`. Locate the `GPUParticles2D` nodes — there should be one per element or one shared node that is configured at runtime by `battle_scene.gd`. If it is runtime-configured, locate the function that sets particle properties.

- [ ] **Step 4.2 — Set particle textures**

For each element's `GPUParticles2D` node (or in the runtime setup function), set:

```gdscript
# Example for fire — repeat per element:
particles_node.texture = load("res://assets/vfx/particle_fire.png")
```

If particles are configured by a `ParticleProcessMaterial`, set the texture via:

```gdscript
var mat := particles_node.process_material as ParticleProcessMaterial
mat.color = Color("#ff6622")         # primary
mat.color_ramp = _make_element_gradient("fire")
```

- [ ] **Step 4.3 — Apply per-element tuning**

For each `GPUParticles2D` (or `CPUParticles2D`) node in the battle scene, set these properties to match element feel:

| Property             | fire  | ice   | storm | stone | venom | shadow |
|----------------------|-------|-------|-------|-------|-------|--------|
| `amount`             | 40    | 30    | 50    | 25    | 35    | 45     |
| `lifetime`           | 0.6   | 0.8   | 0.4   | 1.0   | 0.7   | 0.9    |
| `speed_scale`        | 1.4   | 0.8   | 1.8   | 0.6   | 1.0   | 1.2    |
| `spread` (degrees)   | 45    | 30    | 60    | 20    | 40    | 50     |

If these properties are set in a GDScript function rather than directly on nodes, update the matching dictionary or `match` block in `battle_scene.gd` to add per-element particle config. Example pattern:

```gdscript
const PARTICLE_CONFIG := {
	"fire":   { "amount": 40, "lifetime": 0.6, "speed_scale": 1.4, "spread": 45.0, "texture": "res://assets/vfx/particle_fire.png",   "color": Color("#ff6622") },
	"ice":    { "amount": 30, "lifetime": 0.8, "speed_scale": 0.8, "spread": 30.0, "texture": "res://assets/vfx/particle_ice.png",    "color": Color("#44aaff") },
	"storm":  { "amount": 50, "lifetime": 0.4, "speed_scale": 1.8, "spread": 60.0, "texture": "res://assets/vfx/particle_storm.png",  "color": Color("#aa66ff") },
	"stone":  { "amount": 25, "lifetime": 1.0, "speed_scale": 0.6, "spread": 20.0, "texture": "res://assets/vfx/particle_stone.png",  "color": Color("#aa8844") },
	"venom":  { "amount": 35, "lifetime": 0.7, "speed_scale": 1.0, "spread": 40.0, "texture": "res://assets/vfx/particle_venom.png",  "color": Color("#44cc44") },
	"shadow": { "amount": 45, "lifetime": 0.9, "speed_scale": 1.2, "spread": 50.0, "texture": "res://assets/vfx/particle_shadow.png", "color": Color("#8844aa") },
}

func _configure_particles(element: String) -> void:
	var cfg: Dictionary = PARTICLE_CONFIG.get(element, PARTICLE_CONFIG["fire"])
	$particles.amount = int(cfg["amount"])
	$particles.lifetime = float(cfg["lifetime"])
	$particles.speed_scale = float(cfg["speed_scale"])
	var mat := $particles.process_material as ParticleProcessMaterial
	if mat != null:
		mat.spread = float(cfg["spread"])
		mat.color = cfg["color"]
	$particles.texture = load(str(cfg["texture"]))
```

Call `_configure_particles(element)` wherever the battle scene activates a move's VFX.

- [ ] **Step 4.4 — Visual review in editor**

Run F5, start a battle with a fire dragon. Fire a move. Confirm orange particle burst. Repeat with one other element. Particles should be visually distinct.

- [ ] **Step 4.5 — Commit**

```powershell
git add dragon-forge-godot/scenes/battle/battle_scene.tscn dragon-forge-godot/scripts/battle/battle_scene.gd
git commit -m "Tune element particles with textures and per-element config (Plan 7)"
```

---

## Task 5: Smoke Test Suite

Extend `scripts/tests/sim_smoke.gd` to cover all screens and provide a fast headless no-error gate.

**Files:**
- Modify: `dragon-forge-godot/scripts/tests/sim_smoke.gd`

- [ ] **Step 5.1 — Add screen instantiation assertions**

If Plan 5 Task 9 was not completed, add the following to `sim_smoke.gd` now. If it was already added, skip to Step 5.2.

```gdscript
const CampaignMapScreen := preload("res://scenes/screens/campaign_map_screen.tscn")
const ShopScreen        := preload("res://scenes/screens/shop_screen.tscn")
const ForgeScreen       := preload("res://scenes/screens/forge_screen.tscn")
const JournalScreen     := preload("res://scenes/screens/journal_screen.tscn")
const StatsScreen       := preload("res://scenes/screens/stats_screen.tscn")
const SettingsScreen    := preload("res://scenes/screens/settings_screen.tscn")
const SingularityScreen := preload("res://scenes/screens/singularity_screen.tscn")

func _assert_all_screens_load() -> void:
	for scn in [CampaignMapScreen, ShopScreen, ForgeScreen, JournalScreen, StatsScreen, SettingsScreen, SingularityScreen]:
		var inst := scn.instantiate()
		assert(inst != null, "screen scene instantiates without error")
		inst.free()
```

Call `_assert_all_screens_load()` from `_init()`.

- [ ] **Step 5.2 — Add SaveIO round-trip assertion**

If not already present from Plan 5 Task 1, add:

```gdscript
const SaveIO := preload("res://scripts/sim/save_io.gd")

func _assert_save_io() -> void:
	var state := SaveIO._default_save()
	assert(SaveIO.get_scraps(state) == 0)
	state = SaveIO.add_scraps(state, 100)
	assert(SaveIO.get_scraps(state) == 100)
	state = SaveIO.spend_scraps(state, 40)
	assert(SaveIO.get_scraps(state) == 60)
	state = SaveIO.add_inventory_item(state, "hp_potion", 2)
	assert(int(SaveIO.get_inventory(state).get("hp_potion", 0)) == 2)
	state = SaveIO.mark_boss_defeated(state, "data_corruption")
	assert(SaveIO.get_singularity_progress(state)["defeated"].has("data_corruption"))
```

- [ ] **Step 5.3 — Add main scene transition readiness assertion**

```gdscript
const MainScene := preload("res://scenes/main.tscn")

func _assert_main_scene_ready() -> void:
	var inst := MainScene.instantiate()
	assert(inst != null)
	assert(inst.has_node("anim_player"), "main scene has AnimationPlayer for transitions")
	assert(inst.has_node("fade_overlay"), "main scene has fade_overlay ColorRect")
	inst.free()
```

Call `_assert_main_scene_ready()` from `_init()`.

- [ ] **Step 5.4 — Add combat rules regression assertion**

```gdscript
const CombatRules := preload("res://scripts/sim/combat_rules.gd")

func _assert_combat_rules() -> void:
	# Fire is super-effective vs ice
	var eff := CombatRules.get_effectiveness("fire", "ice")
	assert(eff == 2.0, "fire vs ice is 2.0x")
	# Stone is neutral vs shadow
	var eff2 := CombatRules.get_effectiveness("stone", "shadow")
	assert(eff2 == 1.0, "stone vs shadow is 1.0x")
	# Full attack resolve smoke check
	var atk := { "atk": 28, "stage": 3, "element": "fire" }
	var def_target := { "hp": 100, "def": 20, "element": "ice" }
	var move := { "power": 65, "accuracy": 100, "element": "fire" }
	var result := CombatRules.resolve_attack(atk, def_target, move, 0.5)
	assert(result["hit"] == true)
	assert(result["damage"] > 0)
```

- [ ] **Step 5.5 — Run full smoke test headless**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`, all assertions pass, no GDScript errors in output.

If any assertion fails, fix the underlying issue before proceeding to Task 6.

- [ ] **Step 5.6 — Commit**

```powershell
git add dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Extend smoke test suite to cover all screens and core systems (Plan 7)"
```

---

## Task 6: Final GUT Engine Test Run

Confirm no engine-level regressions from all polish work.

- [ ] **Step 6.1 — Run GUT tests headless**

If GUT is installed in the project (`addons/gut/`):

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit
```

Expected: all tests pass, exit code `0`.

If GUT is not installed, run the sim_smoke.gd script as the regression gate (already done in Task 5).

- [ ] **Step 6.2 — Run headless scene load**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --quit-after 1
```

Expected: exit code `0`, no errors or warnings about missing scripts/scenes/assets.

- [ ] **Step 6.3 — Fix any regressions before proceeding**

If either command above fails, investigate the error output, fix the issue in the relevant script or scene, and re-run before moving to Task 7.

---

## Task 7: Commit + Tag v0.1-godot-slice

- [ ] **Step 7.1 — Verify git status is clean**

```powershell
git status
```

Expected: nothing to commit, working tree clean. If there are uncommitted changes from any of Tasks 1–6, commit them now with a descriptive message before tagging.

- [ ] **Step 7.2 — Run smoke test one final time**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`.

- [ ] **Step 7.3 — Tag the release**

```powershell
git tag -a v0.1-godot-slice -m "Dragon Forge Godot v0.1 — all screens playable, particles tuned, controller support, audio mixed"
```

- [ ] **Step 7.4 — Confirm tag**

```powershell
git tag --list "v0.1*"
git show v0.1-godot-slice --stat
```

Expected: tag appears, commit summary looks correct.

- [ ] **Step 7.5 — Done**

The Godot build is now at v0.1-godot-slice:
- All 7 supporting screens navigate correctly.
- Gamepad works across all menus and battle with rumble feedback.
- Screen transitions fade 0.2 s between every view switch.
- Music plays on the Music bus, SFX on the SFX bus, both adjustable from Settings.
- Battle particles are element-colored with tuned emission, lifetime, and speed.
- Full headless smoke suite passes in CI with a single command.
