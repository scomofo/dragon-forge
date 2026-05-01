# Godot Production Return Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `dragon-forge-godot/` the active Dragon Forge production runtime and port the useful browser lore gains into Godot first.

**Architecture:** Keep the browser build as a reference prototype only. Add a small Godot lore canon module, then surface it through the existing Godot world, story, and battle scenes without rewriting the current spine. Preserve the Godot simulation-first structure: `scripts/sim/*` owns data/rules, `scripts/world/*` and `scripts/battle/*` render and interact.

**Tech Stack:** Godot 4.6, GDScript, existing Godot scenes under `dragon-forge-godot/scenes`, existing sim modules under `dragon-forge-godot/scripts/sim`, headless smoke test via `dragon-forge-godot/scripts/tests/sim_smoke.gd`.

---

## File Structure

- Create: `dragon-forge-godot/scripts/sim/lore_canon.gd`  
  Shared Skye/Felix/Astraeus/Mirror Admin canon and short display lines.
- Modify: `dragon-forge-godot/scripts/sim/story_data.gd`  
  Pull Skye opening and B.I.O.S./Felix language from the canon module.
- Modify: `dragon-forge-godot/scripts/sim/world_data.gd`  
  Add map/mission lore signals to key locations using canon terms.
- Modify: `dragon-forge-godot/scripts/world/world_scene.gd`  
  Display the new lore signal/objective lines in the existing world action/objective UI.
- Modify: `dragon-forge-godot/scripts/battle/battle_scene.gd`  
  Add brief battle intro/victory barks from canon for Mirror Admin/security daemon encounters only.
- Modify: `dragon-forge-godot/scripts/tests/sim_smoke.gd`  
  Assert the Godot runtime exposes Skye, Astraeus, Mirror Admin, guardian protocols, and Great Reset copy.

## Task 1: Add Shared Godot Lore Canon

**Files:**
- Create: `dragon-forge-godot/scripts/sim/lore_canon.gd`
- Test: `dragon-forge-godot/scripts/tests/sim_smoke.gd`

- [ ] **Step 1: Create the canon module**

```gdscript
extends RefCounted
class_name LoreCanon

const PLAYER := {
	"name": "Skye",
	"role": "dragon handler and emerging system administrator",
	"premise": "Skye begins inside a mythic rendered world and learns it is powered by the ancient Astraeus hardware layer.",
}

const FELIX := {
	"name": "Professor Felix",
	"role": "forge-keeper, mentor, and frantic technical operator",
	"tone": "warm, precise, anxious, and practical under pressure",
}

const WORLD := {
	"rendered_world": "The pastoral fantasy layer is a rendered world, beautiful because people were meant to live inside it.",
	"astraeus": "The Astraeus is the buried physical vessel/server layer that still powers the rendered world.",
	"mirror_admin": "Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion.",
	"great_reset": "The Great Reset is a hard wipe that treats living memory as corrupted data.",
}

const DRAGON_PROTOCOL := {
	"summary": "Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back.",
}

const OPENING_BOOT_LINES := [
	"> ASTRAEUS EMERGENCY WAKE SEQUENCE",
	"> OPERATOR SIGNAL FOUND: SKYE",
	"> RENDERED WORLD LAYER: UNSTABLE",
	"> ELEMENTAL GUARDIAN PROTOCOLS: DORMANT",
	"> MIRROR ADMIN OVERRIDE: ACTIVE",
	"> GREAT RESET COUNTDOWN: SIGNAL LOST",
]

static func captain_log_fragments() -> Array[Dictionary]:
	return [
		{"id": "001", "title": "The Rendered World", "body": WORLD.rendered_world},
		{"id": "002", "title": "The Mirror Admin", "body": WORLD.mirror_admin},
		{"id": "003", "title": "Skye Signal", "body": "Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys."},
		{"id": "004", "title": "Guardian Protocols", "body": DRAGON_PROTOCOL.summary},
		{"id": "005", "title": "Great Reset", "body": WORLD.great_reset},
	]
```

- [ ] **Step 2: Run the smoke test to confirm current baseline**

Run:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`.

- [ ] **Step 3: Add smoke assertions for canon**

Append to `dragon-forge-godot/scripts/tests/sim_smoke.gd` in the existing assertion section:

```gdscript
const LoreCanon := preload("res://scripts/sim/lore_canon.gd")

func _assert_lore_canon() -> void:
	assert(LoreCanon.PLAYER.name == "Skye")
	assert(str(LoreCanon.WORLD.astraeus).contains("Astraeus"))
	assert(str(LoreCanon.WORLD.mirror_admin).contains("Mirror Admin"))
	assert(str(LoreCanon.WORLD.great_reset).contains("Great Reset"))
	assert(str(LoreCanon.DRAGON_PROTOCOL.summary).contains("protocols"))
	assert(LoreCanon.captain_log_fragments().size() >= 5)
```

Call `_assert_lore_canon()` from the smoke test entrypoint after other sim-data assertions.

- [ ] **Step 4: Run the smoke test**

Expected: PASS, exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add dragon-forge-godot/scripts/sim/lore_canon.gd dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Add Godot lore canon module"
```

## Task 2: Surface Lore In World/Story Data

**Files:**
- Modify: `dragon-forge-godot/scripts/sim/story_data.gd`
- Modify: `dragon-forge-godot/scripts/sim/world_data.gd`
- Test: `dragon-forge-godot/scripts/tests/sim_smoke.gd`

- [ ] **Step 1: Import the canon into story data**

At the top of `story_data.gd`, add:

```gdscript
const LoreCanon := preload("res://scripts/sim/lore_canon.gd")
```

Add:

```gdscript
static func opening_boot_lines() -> Array[String]:
	var lines: Array[String] = []
	for line in LoreCanon.OPENING_BOOT_LINES:
		lines.append(str(line))
	return lines

static func felix_first_contact_lines() -> Array[String]:
	return [
		"Skye. Good. You can hear me.",
		"The world you know is rendered over the old Astraeus hardware.",
		"Mirror Admin is trying to preserve us by erasing us.",
		"The dragons are living guardian protocols. If they bond to you, they can hold the Matrix together.",
	]
```

- [ ] **Step 2: Add world-data lore signals**

In `world_data.gd`, for the existing New Landing, Felix Workshop, Southern Partition, Tundra, Mainframe, and Crown location dictionaries, add these keys:

```gdscript
"lore_signal": "Astraeus telemetry is leaking through the Pastoral Render.",
"skye_objective": "Skye must stabilize this route before Mirror Admin can classify it as corrupted memory.",
```

Use location-specific copy where the file already has matching mission/act context.

- [ ] **Step 3: Add smoke assertions**

In `sim_smoke.gd`, add assertions that `StoryData.opening_boot_lines()` contains `SKYE`, `ASTRAEUS`, `MIRROR ADMIN`, and that at least one world location has `lore_signal` containing `Astraeus`.

- [ ] **Step 4: Run smoke test**

Expected: PASS, exit code `0`.

- [ ] **Step 5: Commit**

```powershell
git add dragon-forge-godot/scripts/sim/story_data.gd dragon-forge-godot/scripts/sim/world_data.gd dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Surface Skye lore in Godot world data"
```

## Task 3: Render Lore In Existing Godot UI

**Files:**
- Modify: `dragon-forge-godot/scripts/world/world_scene.gd`
- Modify: `dragon-forge-godot/scripts/battle/battle_scene.gd`
- Test: `dragon-forge-godot/scripts/tests/sim_smoke.gd`

- [ ] **Step 1: Show world lore signal in the action panel**

In `world_scene.gd`, find the action/objective panel refresh function that reads selected/current location data. After the primary description text is assigned, append:

```gdscript
if location.has("lore_signal"):
	_action_lines.append("[SYS] %s" % str(location["lore_signal"]))
if location.has("skye_objective"):
	_action_lines.append("[SKYE] %s" % str(location["skye_objective"]))
```

Use the actual local array/property name from the panel refresh function. Keep the display read-only; do not add new interaction state.

- [ ] **Step 2: Add battle barks only for Admin/security encounters**

In `battle_scene.gd`, add a helper:

```gdscript
func _lore_bark_for_enemy(enemy_id: String, victory: bool = false) -> String:
	if not enemy_id.contains("mirror") and not enemy_id.contains("daemon") and not enemy_id.contains("sentinel"):
		return ""
	if victory:
		return "Skye forced one more route to stay real."
	return "Mirror Admin pressure rising. Guardian protocol handshake required."
```

Call it when a battle starts and when a battle resolves, using the existing floating text/log mechanism. If the helper returns `""`, do nothing.

- [ ] **Step 3: Run smoke test and one headless scene load**

Run:

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\DF\dragon-forge-godot' --quit-after 1
```

Expected: both exit code `0`.

- [ ] **Step 4: Commit**

```powershell
git add dragon-forge-godot/scripts/world/world_scene.gd dragon-forge-godot/scripts/battle/battle_scene.gd dragon-forge-godot/scripts/tests/sim_smoke.gd
git commit -m "Render Skye lore in Godot world and battles"
```

## Self-Review

- Spec coverage: The plan restores Godot as the production runtime, adds a shared canon module, ports browser lore gains into Godot data, and renders that lore through existing UI surfaces.
- Placeholder scan: No TBD/TODO placeholders. Each task names files, commands, expected results, and concrete code snippets.
- Scope check: This is intentionally a narrow bridge back to Godot. It does not attempt to port every browser polish pass or rebuild art/audio in one step.
