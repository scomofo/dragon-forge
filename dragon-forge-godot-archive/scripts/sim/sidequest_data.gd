extends RefCounted
class_name SideQuestData

const NPC_STATES := {
	"LOOPING": "Repeats animation/dialogue until an interrupt breaks the pathfinding loop.",
	"AWAKENED": "Recognizes simulation glitches and speaks past the fantasy facade.",
	"FRAGMENTED": "Missing assets; dialogue contains nulls, errors, and broken references.",
}

const NPCS := {
	"looping_blacksmith": {
		"name": "The Looping Blacksmith",
		"state": "LOOPING",
		"awareness": 0,
		"role": "Vendor",
		"line": "Hammer. Quench. Hammer. Quench. The sword never cools, never completes.",
		"glitch_line": "Hammer. Quench. Hammer. NULL_SPARK. Why does the blade start over?",
		"awakened_line": "Real metal. From outside the story. That did it... I remember the anvil being placed here.",
	},
	"elder_cache": {
		"name": "Elder Cache",
		"state": "LOOPING",
		"awareness": 0,
		"role": "Lore Keeper",
		"line": "Read-only phrase: wisdom is granted to authorized keys.",
		"glitch_line": "Read-only phrase: wisdom is granted to... access denied... memory repeats.",
		"awakened_line": "Access key accepted. The manual is not scripture; it is a maintenance interface.",
	},
	"texture_seeker": {
		"name": "The Texture-Seeker",
		"state": "AWAKENED",
		"awareness": 1,
		"role": "Wanderer",
		"line": "Have you seen the edges of us? My family portrait is all blur where faces should be.",
		"glitch_line": "My child's face loads in pieces. I can see the brushstrokes and the pixels.",
		"awakened_line": "The portrait resolved. I can see my mother's eyes, and behind them... pixels.",
	},
	"null_pointer_pete": {
		"name": "Null-Pointer Pete",
		"state": "FRAGMENTED",
		"awareness": 1,
		"role": "Hazard",
		"line": "P...ete. Pete? Asset path missing. Reward pointer valid. Mostly.",
		"glitch_line": "Pete exists at address zero. Pete is not supposed to know that.",
		"awakened_line": "You recovered enough of me to stop the null cascade. Don't stare at the missing half.",
	},
	"wireframe_farmer": {
		"name": "The Wireframe Farmer",
		"state": "LOOPING",
		"awareness": 0,
		"role": "Farmer",
		"line": "Fine harvest, if you ignore how the wheat has lost its skin.",
		"glitch_line": "The field is lines. My hands remember soil, but my eyes see meshes.",
		"awakened_line": "I remember rain on Earth. Before the pasture. Before the safe world.",
	},
	"path_merchant": {
		"name": "The Circular Merchant",
		"state": "LOOPING",
		"awareness": 0,
		"role": "Merchant",
		"line": "Round the tree, round the tree, excellent road today.",
		"glitch_line": "This is the third server cycle. My feet know the circle is wrong.",
		"awakened_line": "The wall was invisible because the story needed me harmless. Not anymore.",
	},
	"glitch_weaver": {
		"name": "The Glitch Weaver",
		"state": "LOOPING",
		"awareness": 0,
		"role": "Crafter",
		"line": "My loom sings while it works. Please do not touch the cloth.",
		"glitch_line": "The song has teeth. Every thread is a broken note.",
		"awakened_line": "Harmony restored the weave. Cloth is memory under tension.",
	},
	"decompiled_smith": {
		"name": "The De-compiled Smith",
		"state": "AWAKENED",
		"awareness": 2,
		"role": "Reskin Artisan",
		"line": "My hands are triangles, Skye. The hammer was only an animation.",
		"glitch_line": "Triangle. Triangle. Bone? No. Hand mesh.",
		"awakened_line": "Bring me the manual and I will re-skin your tools without asking the old gods.",
	},
	"sentinel_404": {
		"name": "The 404 Sentinel",
		"state": "FRAGMENTED",
		"awareness": 1,
		"role": "Invisible Wall",
		"line": "Access denied. Land beyond this guard does not exist.",
		"glitch_line": "If the land does not exist, why can I hear it compiling?",
		"awakened_line": "Root Password accepted. My post has been updated. You may pass into the impossible.",
	},
	"unit_01": {
		"name": "The Kernel",
		"state": "AWAKENED",
		"awareness": 2,
		"role": "Mobile Shop / Save Point",
		"line": "Primary Tool detected. I remember that wrench. I do not remember my own name.",
		"glitch_line": "Designation missing. Function persists. Colleague? Customer? Both?",
		"awakened_line": "Unit 01 was not built to pray. Unit 01 was built to repair.",
	},
	"glitch_hunter_pulse": {
		"name": "Pulse",
		"state": "AWAKENED",
		"awareness": 1,
		"role": "Overclocker",
		"line": "Halt, user. You're far from the cache-lines. If you're looking for the Mirror Admin, you've taken a wrong turn into the Heat Sink.",
		"glitch_line": "That tool... standard issue. Crude. Let me tweak your frequency. I will give you a pulse that can stop a sentinel in its clock-cycle.",
		"awakened_line": "The White-Out is not a storm. It is a deletion. We are the files they forgot to trash.",
	},
	"glitch_hunter_shard": {
		"name": "Shard",
		"state": "AWAKENED",
		"awareness": 1,
		"role": "Silicon Merchant",
		"line": "Got any fragments? My code is getting thin... I need the raw data to stay solid.",
		"glitch_line": "Fragments hum when a purge is near. Hold them tight and listen for the white noise.",
		"awakened_line": "Shard for a Shield? Good trade. Better than being erased by the next Purge.",
	},
}

const SIDEQUESTS := {
	"memory_leak": {
		"title": "The Memory Leak",
		"npc": "looping_blacksmith",
		"reward_item": "integrity_patch",
		"target_assets": ["Village Well", "Smithy Anvil", "Elder House"],
		"summary": "Use Lunar illumination to lock flickering town assets before New Landing loses them.",
	},
	"ghost_in_the_well": {
		"title": "The Ghost in the Well",
		"npc": "looping_blacksmith",
		"reward_item": "static_shards",
		"target_frequency": 446.0,
		"summary": "Mute a stuck Scrap-Wraith MIDI scream beneath the village well.",
	},
	"unauthorized_manual": {
		"title": "The Unauthorized Manual",
		"npc": "elder_cache",
		"reward_item": "hydraulic_wing",
		"required_pages": 3,
		"summary": "Recover missing John Deere manual pages across the Salt Flats to unlock Hydraulic Wing takeoff.",
	},
	"rerender_portrait": {
		"title": "The Texture-Seeker",
		"npc": "texture_seeker",
		"reward_item": "prism_texture_pass",
		"required_passes": 3,
		"summary": "Use Prism rendering passes to restore an awakened NPC's family portrait.",
	},
	"asset_recovery": {
		"title": "Null-Pointer Pete",
		"npc": "null_pointer_pete",
		"reward_item": "asset_recovery_cache",
		"required_fragments": 3,
		"summary": "Recover missing asset fragments from map-edge voids without letting Pete's UI glitches cascade.",
	},
	"wireframe_harvest": {
		"title": "The Wireframe Harvest",
		"npc": "wireframe_farmer",
		"reward_item": "seed_code_rare",
		"required_bakes": 3,
		"summary": "Use Magma thermal processing to bake textures back onto a neon wireframe wheat field.",
	},
	"stuck_path": {
		"title": "The Stuck Path",
		"npc": "path_merchant",
		"reward_item": "clipping_permission",
		"required_shorts": 2,
		"summary": "Use the Diagnostic Lens and a Static Dragon short to remove an invisible collision mesh from a caravan path.",
	},
	"corrupted_lullaby": {
		"title": "The Corrupted Lullaby",
		"npc": "glitch_weaver",
		"reward_item": "silken_data",
		"target_frequency": 432.0,
		"summary": "Harmonize a jagged loom MIDI loop so the cloth stops hurting to touch.",
	},
	"sentinel_404": {
		"title": "The 404 Sentinel",
		"npc": "sentinel_404",
		"reward_item": "partition_permissions",
		"summary": "Use Root Password authority to update the living invisible wall at the Southern Partition edge.",
	},
	"great_breakout": {
		"title": "The Great Breakout",
		"npc": "glitch_weaver",
		"reward_item": "mainframe_approach",
		"required_relic_code": "10MM-WRENCH",
		"summary": "Craft the Friction Saddle, outrun three Sub-routine Stalkers, and pry open the Southern Partition Gate through a physical access port.",
	},
	"recover_unit_01_logs": {
		"title": "Recover Unit 01 Logs",
		"npc": "unit_01",
		"reward_item": "frequency_tuner",
		"required_logs": 3,
		"summary": "Recover memory logs from the Mainframe Spine so The Kernel can remember its original repair designation.",
	},
	"black_market_overclock": {
		"title": "Black Market Overclock",
		"npc": "glitch_hunter_pulse",
		"reward_item": "wrench_overclock",
		"required_scraps": 120,
		"summary": "Find the hidden Heat Sink market and let Pulse overclock the 10mm Wrench so Logic Pulse can freeze Type-S drones into temporary platforms.",
	},
	"shard_purge_shield": {
		"title": "Shard for a Shield",
		"npc": "glitch_hunter_shard",
		"reward_item": "purge_shield",
		"required_scraps": 40,
		"summary": "Trade Silicon Shards and data scraps with Shard for a survival shield tuned against the next White-Out Purge.",
	},
}

static func get_npc(id: String) -> Dictionary:
	return NPCS.get(id, {}).duplicate(true)

static func get_sidequest(id: String) -> Dictionary:
	return SIDEQUESTS.get(id, {}).duplicate(true)

static func get_sidequests(ids: Array) -> Array[Dictionary]:
	var quests: Array[Dictionary] = []
	for id in ids:
		var quest := get_sidequest(str(id))
		if not quest.is_empty():
			quests.append(quest)
	return quests

static func evaluate_memory_lock(locked_assets: Array, asset_name: String, timer: float) -> Dictionary:
	var quest := SIDEQUESTS["memory_leak"]
	var locked := locked_assets.duplicate()
	if not locked.has(asset_name):
		locked.append(asset_name)
	var next_timer := maxf(0.0, timer - 30.0)
	return {
		"success": locked.size() >= quest["target_assets"].size() and next_timer > 0.0,
		"failed": next_timer <= 0.0,
		"locked_assets": locked,
		"timer": next_timer,
	}

static func check_well_frequency(roar_frequency: float) -> Dictionary:
	var target: float = SIDEQUESTS["ghost_in_the_well"]["target_frequency"]
	var delta := absf(target - roar_frequency)
	return {
		"success": delta <= 4.0,
		"delta": delta,
		"result": "MIDI_LOOP_MUTED" if delta <= 4.0 else "SCREAM_STILL_LOOPING",
	}

static func collect_manual_page(pages: int) -> Dictionary:
	var required: int = SIDEQUESTS["unauthorized_manual"]["required_pages"]
	var next_pages := mini(required, pages + 1)
	return {
		"success": next_pages >= required,
		"pages": next_pages,
		"required": required,
	}

static func render_portrait_pass(passes: int) -> Dictionary:
	var required: int = SIDEQUESTS["rerender_portrait"]["required_passes"]
	var next_passes := mini(required, passes + 1)
	return {
		"success": next_passes >= required,
		"passes": next_passes,
		"required": required,
	}

static func recover_asset_fragment(fragments: int, glitch: int) -> Dictionary:
	var required: int = SIDEQUESTS["asset_recovery"]["required_fragments"]
	var next_fragments := mini(required, fragments + 1)
	var next_glitch := mini(100, glitch + 22)
	return {
		"success": next_fragments >= required,
		"failed": next_glitch >= 100,
		"fragments": next_fragments,
		"required": required,
		"glitch": next_glitch,
	}

static func bake_wireframe_texture(bakes: int) -> Dictionary:
	var required: int = SIDEQUESTS["wireframe_harvest"]["required_bakes"]
	var next_bakes := mini(required, bakes + 1)
	return {
		"success": next_bakes >= required,
		"bakes": next_bakes,
		"required": required,
		"texture_integrity": float(next_bakes) / float(required),
	}

static func short_collision_mesh(shorts: int, has_diagnostic_lens: bool) -> Dictionary:
	var required: int = SIDEQUESTS["stuck_path"]["required_shorts"]
	if not has_diagnostic_lens:
		return {
			"success": false,
			"blocked": true,
			"shorts": shorts,
			"required": required,
		}
	var next_shorts := mini(required, shorts + 1)
	return {
		"success": next_shorts >= required,
		"blocked": false,
		"shorts": next_shorts,
		"required": required,
	}

static func harmonize_lullaby(roar_frequency: float) -> Dictionary:
	var target: float = SIDEQUESTS["corrupted_lullaby"]["target_frequency"]
	var delta := absf(target - roar_frequency)
	return {
		"success": delta <= 3.0,
		"delta": delta,
		"result": "LOOM_HARMONIZED" if delta <= 3.0 else "JAGGED_LOOP_ACTIVE",
	}

static func update_sentinel_permissions(has_root_password: bool) -> Dictionary:
	return {
		"success": has_root_password,
		"result": "PERMISSIONS_UPDATED" if has_root_password else "ROOT_PASSWORD_REQUIRED",
	}
