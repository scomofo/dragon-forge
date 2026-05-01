extends RefCounted
class_name WorldData

const SideQuestData := preload("res://scripts/sim/sidequest_data.gd")
const ServiceTicketData := preload("res://scripts/sim/service_ticket_data.gd")

const TUNDRA_VISUAL_PROFILE := {
	"aesthetic": "hardware_gothic",
	"sky_motif": "motherboard_constellations",
	"sky_color": Color("#050708"),
	"trace_color": Color("#54ff8b"),
	"ground_motif": "silicon_dust",
	"ground_color": Color("#edf6ff"),
	"dust_pixel_color": Color("#b7fffb"),
	"structure_motifs": ["rusted_capacitors", "jagged_heat_sinks", "copper_trace_roots"],
	"silhouette_color": Color("#3b312d"),
}

const CACHE_VAULT_VISUAL_PROFILE := {
	"aesthetic": "clinical_active_memory",
	"palette": {
		"deep_blue": Color("#071a3f"),
		"cyan": Color("#58dbff"),
		"stark_white": Color("#f8fbff"),
		"hollow_gray": Color("#56616f"),
	},
	"tile_glow": {
		"one": Color("#58dbff"),
		"zero": Color("#56616f"),
	},
	"binary_tiles": {
		"one": Color("#58dbff"),
		"zero": Color("#56616f"),
	},
	"parallax_layers": ["code_rain", "hex_memory_grid", "crt_scanlines"],
	"background_motif": "active_memory_cache_vault",
}

const WALL := {
	"id": "corruption_wall",
	"label": "Corruption Wall",
	"kind": "wall",
	"walkable": false,
	"description": "Jagged black geometry blocks the path.",
}

const START_POSITION := Vector2i(9, 10)

const OVERWORLD_ROWS := [
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
	"~~~~....ffff^^^^....~~~~~~~~....ffff^^....~~~~",
	"~~....fffff^^^^.....~~~~~~....ffff^^^^.....~~~",
	"~~..ffff....^^^...jjj~~~~...fffff^^^..sss..~~",
	"~...fff..dd.......jjjj~~...fff....^...ssss..~",
	"~..fff..dddd..fff..jjj~~..fff..hhhhh...ss...~",
	"~..ff..dddd..ffff...jjj...ff..hhhhhhh.......~",
	"~.....dddd..ffffff.............hhhhhhh..^^...~",
	"~~~......fff^^^^^^...====...ffffhhhh...^^^..~",
	"~~~~....ffff^^^^^...======...ffff.....^^^^..~",
	"~~~....ffff...^....========....fff.........~~",
	"~~....ffff.........========.....fff..sss...~~",
	"~~...ffff....sss....======...ll.....ssss...~~",
	"~....fff....sssss....====...llll....sss....~~",
	"~..mmmmm.....sss......==...llllll.........~~~",
	"~..mmmmm...........fff==...llllll..^^^....~~~",
	"~~..mmm....ffff...ffff==....llll..^^^^...~~~~",
	"~~~......fffff...fffff===.........^^^...~~~~~",
	"~~~~...fffff....ddddd..====...fff......~~~~~~",
	"~~~~~...fff....ddddddd...===..ffff...~~~~~~~~",
	"~~~~~~........ddddddddd...===...ff...~~~~~~~~",
	"~~~~~~~~....fffffdddd.....====......~~~~~~~~~",
	"~~~~~~~~~~..fffff......^^...====..~~~~~~~~~~~",
	"~~~~~~~~~~~~......^^^^^^^.....=..~~~~~~~~~~~~",
	"~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~",
]

const LANDMARKS := {
	Vector2i(6, 4): {
		"id": "digital_forge",
		"label": "Digital Forge",
		"kind": "forge",
		"description": "The primordial reactor where dragon code first learned to breathe.",
		"hatchery_flow": true,
		"hatchery_id": "quantum_incubation_ring",
	},
	Vector2i(8, 10): {
		"id": "skye_start",
		"label": "Village Edge",
		"kind": "field",
		"description": "A pastoral sector buckles under a tear in the rendered sky.",
	},
	Vector2i(10, 10): {
		"id": "testing_fields",
		"label": "Testing Fields",
		"kind": "field",
		"description": "Four Forge nations once tested dragon protocols here under Felix's sleepless supervision.",
	},
	Vector2i(13, 10): {
		"id": "forge_lab",
		"label": "Felix Workshop",
		"kind": "lab",
		"description": "A green-lit safe workshop under the village: save, train, socket Anvil relics, and enter the Cooling Intake hardware dungeon.",
		"lore_signal": "Astraeus telemetry leaks through Felix's basement instruments whenever Skye gets close.",
		"skye_objective": "Use the Forge as a stable route before Mirror Admin classifies Skye as corrupted memory.",
		"dungeon_id": "cooling_intake",
	},
	Vector2i(17, 10): {
		"id": "firewall_gate",
		"label": "Firewall Gate",
		"kind": "gate",
		"description": "A defensive process has become a stone-armored guardian of the first corrupted sector.",
		"lore_signal": "Mirror Admin converted a safety firewall into a guardian against living contradiction.",
		"skye_objective": "Prove the first guardian route can be repaired without deleting the people inside it.",
		"encounter": {
			"enemy_id": "firewall_sentinel",
			"title": "Firewall Gate Encounter",
		},
	},
	Vector2i(15, 8): {
		"id": "checksum_ring",
		"label": "Checksum Ring",
		"kind": "arena",
		"arena": true,
		"arena_rule": "checksum_flux",
		"arena_rule_label": "Checksum Flux: even turns burn the enemy and grant Focus.",
		"arena_reward": {
			"scraps": 90,
			"technique_id": "cinderComet",
			"label": "Cinder Comet combat routine",
		},
		"description": "A cracked stone dueling ring where failed validation routines take physical form.",
		"encounter": {
			"enemy_id": "corrupt_drake",
			"title": "Checksum Ring Arena",
		},
	},
	Vector2i(21, 9): {
		"id": "overgrown_buffer",
		"label": "Overgrown Buffer",
		"kind": "jungle",
		"description": "Directory trees knot into a canopy of flickering green code. The sky above is no sky at all, only a cracked viewport.",
		"lore_signal": "The Pastoral Render is fraying here, exposing hardware roots beneath the forest myth.",
		"skye_objective": "Recover enough living memory for the dragon protocols to hold this sector together.",
		"hazard": "Packet Loss Fog curls between branches of executable leaves.",
		"npcs": ["texture_seeker"],
		"sidequests": ["rerender_portrait"],
	},
	Vector2i(23, 8): {
		"id": "overflow_pipe",
		"label": "Overflow Pipe",
		"kind": "hardware",
		"description": "A massive coolant tunnel vents steam in timed blasts, launching the Root Dragon toward the upper Hardware Husk route.",
		"hazard": "Pressure Cycle: mistimed launches throw Skye into hot coolant backwash.",
		"map_feature": "jump_pad",
		"scanline": true,
	},
	Vector2i(27, 8): {
		"id": "vault_first_rack",
		"label": "Vault of the First Rack",
		"kind": "hardware",
		"description": "Inside the Star-Shaper, fiber-optic veins run along narrow halls. A vertical LED array repeats five tones in light instead of speech.",
		"lore_signal": "B.I.O.S. is speaking from the Astraeus hardware layer in constrained light-and-tone packets.",
		"skye_objective": "Establish the first stable hardware handshake before the Great Reset countdown reacquires signal.",
		"scanline": true,
		"npc": "BIOS",
		"mission": "mission_09",
		"encounter": {
			"enemy_id": "scrap_wraith",
			"title": "Defend the Boot-Up",
		},
	},
	Vector2i(24, 12): {
		"id": "scrap_pit_arena",
		"label": "Scrap Pit Arena",
		"kind": "arena",
		"arena": true,
		"arena_rule": "scrap_surge",
		"arena_rule_label": "Scrap Surge: loose shrapnel damages both sides after each exchange.",
		"arena_reward": {
			"scraps": 120,
			"key_item": "scrap_pit_sigil",
			"label": "Scrap Pit Sigil",
		},
		"description": "Jagged maintenance parts form a pit around a humming delete sigil.",
		"encounter": {
			"enemy_id": "scrap_wraith",
			"title": "Scrap Pit Arena",
		},
	},
	Vector2i(5, 15): {
		"id": "mint_menagerie",
		"label": "Archive Paddock",
		"kind": "archive",
		"description": "A preservation paddock where Elder Cache recites read-only lore beside B.I.O.S.'s professional condition scanner.",
		"mission": "mission_06",
		"npcs": ["elder_cache"],
	},
	Vector2i(11, 13): {
		"id": "great_salt_flats",
		"label": "Great Salt Flats",
		"kind": "salt",
		"description": "A pale, unrendered expanse where traction fails and dragon stamina drains across the long relay route.",
		"hazard": "Low traction. Pedal-assist modulation keeps kinetic recovery online.",
		"mission": "mission_07",
		"sidequests": ["unauthorized_manual"],
	},
	Vector2i(23, 13): {
		"id": "manual_override",
		"label": "Manual Override",
		"kind": "hardware",
		"description": "The John Deere 8R Technical Manual matches the latch geometry perfectly. Felix goes pale when the mundane diagram opens the holy door.",
		"scanline": true,
		"artifact": "root_password",
	},
	Vector2i(29, 9): {
		"id": "cpu_heatsink",
		"label": "CPU Heat Sink",
		"kind": "hardware",
		"description": "A colossal heat sink glows like a molten sun. Magma-class dragons tremble at the edge of an Overclocked state.",
		"scanline": true,
		"artifact": "overclocked_state",
		"npc": "BIOS",
		"mission": "mission_05",
	},
	Vector2i(27, 15): {
		"id": "lunar_cooling_pool",
		"label": "Lunar Cooling Pool",
		"kind": "field",
		"description": "Silver mist condenses around cold-storage mirrors.",
	},
	Vector2i(31, 15): {
		"id": "lunar_sector",
		"label": "Lunar Sector",
		"kind": "lunar",
		"description": "The wind is silent until the Lunar Dragon listens. Packet fragments hide inside MIDI-like frequencies.",
			"mission": "mission_08",
	},
	Vector2i(33, 16): {
		"id": "lunar_resonance_bowl",
		"label": "Resonance Bowl",
		"kind": "arena",
		"arena": true,
		"arena_rule": "lunar_resonance",
		"arena_rule_label": "Lunar Resonance: guarding harmonizes; hesitation lets the mote repair.",
		"arena_reward": {
			"scraps": 110,
			"technique_id": "nightNeedle",
			"label": "Night Needle combat routine",
		},
		"description": "A circular crater of black-and-white stone amplifies every roar into hostile harmonics.",
		"encounter": {
			"enemy_id": "lunar_mote",
			"title": "Resonance Bowl Arena",
		},
	},
	Vector2i(34, 18): {
		"id": "piano_key_ridge",
		"label": "Piano-Key Ridge",
		"kind": "lunar",
		"description": "A dark ridge of alternating black and white data stone. Secrets answer in notes, not words.",
	},
	Vector2i(18, 3): {
		"id": "deepwood_fragment",
		"label": "Fragmented Deepwood",
		"kind": "jungle",
		"description": "Forest chunks float apart like a broken memory page. Root Access outlines their missing addresses in green light.",
		"mission": "mission_10",
		"admin_node": true,
	},
	Vector2i(9, 4): {
		"id": "high_render_valley",
		"label": "High-Render Valley",
		"kind": "field",
		"description": "A pastoral valley tries to render in impossible detail, except the wheat has lost its skin and glows as green wireframe.",
		"npcs": ["wireframe_farmer"],
		"sidequests": ["wireframe_harvest"],
		"admin_node": true,
	},
	Vector2i(12, 4): {
		"id": "directory_tree_loop",
		"label": "Directory Tree Loop",
		"kind": "jungle",
		"description": "A merchant caravan walks in a perfect circle around a branching tree of file paths.",
		"npcs": ["path_merchant"],
		"sidequests": ["stuck_path"],
		"admin_node": true,
	},
	Vector2i(7, 9): {
		"id": "glitch_loom",
		"label": "Glitch Loom",
		"kind": "field",
		"description": "A village loom plays a distorted MIDI lullaby while weaving cloth with jagged, painful edges.",
		"npcs": ["glitch_weaver"],
		"sidequests": ["corrupted_lullaby"],
	},
	Vector2i(9, 10): {
		"id": "new_landing",
		"label": "New Landing",
		"kind": "field",
		"description": "A town of stale-but-living assets stands in the Garbage Collector's path. The blacksmith hammers a sword that never finishes.",
		"mission": "mission_11",
		"admin_node": true,
		"npcs": ["looping_blacksmith"],
		"sidequests": ["memory_leak", "ghost_in_the_well"],
	},
	Vector2i(2, 22): {
		"id": "null_edge",
		"label": "Null Edge",
		"kind": "wall",
		"description": "A half-rendered person stands at the map's edge, surrounded by UI artifacts and missing texture warnings.",
		"walkable": true,
		"hazard": "Null-pointer drift: lingering here makes the interface unstable.",
		"npcs": ["null_pointer_pete"],
		"sidequests": ["asset_recovery"],
	},
	Vector2i(14, 10): {
		"id": "update_monolith",
		"label": "Update Monolith",
		"kind": "hardware",
		"description": "A stone pillar blinks with a deadpan message: CHECKING FOR UPDATES... SYSTEM UP TO DATE.",
		"scanline": true,
		"admin_node": true,
	},
	Vector2i(20, 9): {
		"id": "sentinel_404_gate",
		"label": "404 Sentinel Gate",
		"kind": "gate",
		"description": "A guard stands so rigidly at the Southern Partition edge that reality treats him as an invisible wall.",
		"npcs": ["sentinel_404"],
		"sidequests": ["sentinel_404"],
		"admin_node": true,
	},
	Vector2i(12, 13): {
		"id": "ghost_tractor_trace",
		"label": "Ghost Tractor Trace",
		"kind": "salt",
		"description": "Faint green tire tracks cross the flats. During system resets, Felix swears a 16-bit tractor renders here.",
		"artifact": "ghost_tractor_trace",
	},
	Vector2i(17, 6): {
		"id": "z_fighting_ridge",
		"label": "Z-Fighting Ridge",
		"kind": "archive",
		"description": "Two mountain textures flicker over each other, unable to decide which surface is real.",
		"hazard": "Z-Fighting: dragons stutter here and stamina drains twice as fast.",
	},
	Vector2i(19, 7): {
		"id": "southern_partition_gate",
		"label": "Southern Partition Gate",
		"kind": "gate",
		"description": "A red binary curtain climbs from the jungle floor to the skybox. Only a rusted physical access port ignores the permission check.",
		"hazard": "Firewall Reset: direct contact de-rezzes Skye back to the last safe restore point.",
		"requires_relic_code": "10MM-WRENCH",
		"dungeon_id": "southern_partition_airlock",
		"admin_node": true,
		"sidequests": ["great_breakout"],
	},
	Vector2i(20, 6): {
		"id": "tundra_of_silicon",
		"label": "Tundra of Silicon",
		"kind": "kernel",
		"description": "Beyond the breached jungle wall, white silicon dust drifts beneath the Mainframe Spine like frozen circuitry.",
		"lore_signal": "Mirror Admin is weaponizing zero-fill cache as weather across the exposed Astraeus layer.",
		"skye_objective": "Shelter the dragon protocols through White-Out Purge and find Unit 01 before the route is wiped clean.",
		"hazard": "Cold Data: flight traction stays high, but Magma-Core heat drains into the whiteout.",
		"hazard_id": "white_out_purge",
		"npcs": ["unit_01"],
		"sidequests": ["recover_unit_01_logs"],
		"admin_node": true,
		"visual_profile": TUNDRA_VISUAL_PROFILE,
	},
	Vector2i(22, 6): {
		"id": "great_buffer_vault",
		"label": "Great Buffer Vault",
		"kind": "kernel",
		"description": "A white-walled storage bank half-buried in silicon dust. The Optical Lens is locked behind purge-timed alcoves.",
		"hazard": "White-Out Purge cycles through the vault interior.",
		"hazard_id": "white_out_purge",
		"dungeon_id": "great_buffer",
		"artifact": "optical_lens",
		"admin_node": true,
		"visual_profile": CACHE_VAULT_VISUAL_PROFILE,
	},
	Vector2i(22, 5): {
		"id": "physical_relay",
		"label": "Physical Relay",
		"kind": "hardware",
		"description": "A rib of analog shipframe rises out of the frozen buffer. White-out purges break against it like weather.",
		"artifact": "physical_relay",
		"scanline": true,
		"admin_node": true,
		"visual_profile": TUNDRA_VISUAL_PROFILE,
	},
	Vector2i(23, 5): {
		"id": "mirror_admin_gate",
		"label": "Mirror Admin Gate",
		"kind": "kernel",
		"description": "A white-glass eye hangs over the Tundra exit, rewriting the purge cycle into a boss chamber until Skye seals the shielded port.",
		"hazard": "Sector Purge: parity scan lanes become white-out walls unless Skye reaches a shielded port.",
		"hazard_id": "white_out_purge",
		"dungeon_id": "mirror_admin_gate",
		"artifact": "admin_shard",
		"scanline": true,
		"admin_node": true,
		"visual_profile": CACHE_VAULT_VISUAL_PROFILE,
	},
	Vector2i(21, 5): {
		"id": "glitch_hunter_black_market",
		"label": "Glitch-Hunter Market",
		"kind": "hardware",
		"description": "Inside a hollow heat sink, illegal sub-routines trade in soldered miracles and pretend the blinking red audit light is decorative.",
		"hazard": "Admin Sweep: linger too long and the market folds itself into a fan shadow.",
		"npcs": ["glitch_hunter_pulse", "glitch_hunter_shard"],
		"sidequests": ["black_market_overclock", "shard_purge_shield"],
		"scanline": true,
		"admin_node": true,
		"visual_profile": TUNDRA_VISUAL_PROFILE,
	},
	Vector2i(24, 4): {
		"id": "mainframe_spine_base",
		"label": "Mainframe Spine Base",
		"kind": "kernel",
		"description": "The mountain resolves into a vertical server rack. Its lower floors gleam with modern render passes and cold security light.",
		"lore_signal": "The Astraeus stack is visible now: modern render passes below, legacy code above, raw permission at the Crown.",
		"skye_objective": "Carry the repaired guardian signal upward before Mirror Admin can lock the Spine into rollback.",
		"mission": "mission_13",
		"artifact": "optical_lens",
		"dungeon_id": "logic_core",
		"admin_node": true,
	},
	Vector2i(25, 3): {
		"id": "legacy_peak",
		"label": "Legacy Peak",
		"kind": "kernel",
		"description": "At the top of the Mainframe Spine, the world sheds polygons and speaks in raw green ASCII.",
		"hazard": "Legacy Collision: blocky surfaces snap in and out of solidity.",
		"encounter": {
			"enemy_id": "root_sentinel",
			"title": "Root Sentinel",
		},
		"artifact": "floppy_disk_backup",
		"admin_node": true,
	},
	Vector2i(26, 2): {
		"id": "mainframe_crown",
		"label": "Mainframe Crown",
		"kind": "kernel",
		"description": "Above the Legacy Peak, the sky is raw system logs and a gold-plated drive waits for the Original Seed Backup.",
		"lore_signal": "The Great Reset is no longer a warning here; it is a pending system choice.",
		"skye_objective": "Choose whether Skye restores, patches, or overrides the world the Astraeus still remembers.",
		"artifact": "floppy_disk_backup_drive",
		"mission": "mission_restoration",
		"scanline": true,
		"admin_node": true,
	},
	Vector2i(26, 4): {
		"id": "skybox_leak",
		"label": "Sky-Box Leak",
		"kind": "lunar",
		"description": "A hole in the blue sky shows the black server void beyond the pastoral shell.",
		"hazard": "Void Draft: infinite vertical lift, but cold damage gathers fast.",
		"admin_node": true,
	},
	Vector2i(22, 16): {
		"id": "floating_point_cliffs",
		"label": "Floating Point Cliffs",
		"kind": "archive",
		"description": "Rocks hover inches above their shadows. Strong dragons could move them into bridges.",
		"hazard": "Floating Point Drift: platforms slide out of alignment.",
		"admin_node": true,
	},
	Vector2i(19, 11): {
		"id": "dead_pixel_void",
		"label": "Dead Pixel",
		"kind": "wall",
		"description": "A black square of unrendered space refuses every lighting pass.",
		"walkable": true,
		"hazard": "Dead Pixel: stepping too close scrapes HP from active dragons.",
	},
	Vector2i(31, 6): {
		"id": "kernel_core",
		"label": "Kernel Core",
		"kind": "kernel",
		"description": "A zero-gravity cathedral of light. The laws of physics hang as visible logic lines beneath a sky of scrolling system events.",
		"scanline": true,
		"mission": "mission_12",
		"admin_node": true,
		"encounter": {
			"enemy_id": "sys_admin",
			"title": "Sys-Admin Rollback",
		},
	},
	Vector2i(35, 8): {
		"id": "root_directory",
		"label": "Root Directory",
		"kind": "kernel",
		"description": "The innermost permission table waits here. A dragon consciousness can become the new Security Daemon.",
		"scanline": true,
		"admin_node": true,
	},
}

const TERRAIN_BY_CHAR := {
	".": {
		"label": "Grasslands",
		"kind": "field",
		"walkable": true,
		"description": "Open overworld grass hums beneath Skye's boots.",
		"danger": 4.0,
		"wild_encounter": {
			"enemy_id": "firewall_sentinel",
			"title": "Stray Firewall Probe",
		},
	},
	"=": {
		"label": "Old Access Road",
		"kind": "field",
		"walkable": true,
		"description": "A bright access road threads between corrupted regions.",
		"danger": 1.0,
	},
	"f": {
		"label": "Directory Forest",
		"kind": "jungle",
		"walkable": true,
		"description": "Trees fork like recursive directory structures.",
		"danger": 10.0,
		"wild_encounter": {
			"enemy_id": "corrupt_drake",
			"title": "Recursive Drake Ambush",
		},
	},
	"j": {
		"label": "Overgrown Buffer",
		"kind": "jungle",
		"walkable": true,
		"description": "Dense executable leaves flicker with unfinished draw calls.",
		"hazard": "Packet Loss Fog: movement here feels unstable.",
		"danger": 14.0,
		"wild_encounter": {
			"enemy_id": "scrap_wraith",
			"title": "Packet Loss Wraith",
		},
	},
	"^": {
		"label": "Checksum Peaks",
		"kind": "archive",
		"walkable": true,
		"description": "Grey peaks rise like compressed data shards.",
		"danger": 11.0,
		"wild_encounter": {
			"enemy_id": "corrupt_drake",
			"title": "Checksum Drake",
		},
	},
	"d": {
		"label": "Manual Desert",
		"kind": "salt",
		"walkable": true,
		"description": "Paper-pale sand is etched with maintenance diagrams.",
		"danger": 7.0,
		"wild_encounter": {
			"enemy_id": "firewall_sentinel",
			"title": "Manual Index Sentinel",
		},
	},
	"s": {
		"label": "Great Salt Flats",
		"kind": "salt",
		"walkable": true,
		"description": "A slick white plain drains momentum from every step.",
		"danger": 13.0,
		"wild_encounter": {
			"enemy_id": "scrap_wraith",
			"title": "Salt Static Wraith",
		},
	},
	"h": {
		"label": "Hardware Husk",
		"kind": "hardware",
		"walkable": true,
		"description": "Brushed metal juts through the simulated world like exposed bone.",
		"scanline": true,
		"danger": 16.0,
		"wild_encounter": {
			"enemy_id": "scrap_wraith",
			"title": "Maintenance Drone Attack",
		},
	},
	"l": {
		"label": "Lunar Shelf",
		"kind": "lunar",
		"walkable": true,
		"description": "Moonlit basalt records the wind in hidden frequencies.",
		"danger": 12.0,
		"wild_encounter": {
			"enemy_id": "lunar_mote",
			"title": "Lunar Packet Mote",
		},
	},
	"m": {
		"label": "Magma Marsh",
		"kind": "forge",
		"walkable": true,
		"description": "Hot pixels pulse below a cracked crust.",
		"danger": 12.0,
		"wild_encounter": {
			"enemy_id": "firewall_sentinel",
			"title": "Thermal Firewall",
		},
	},
	"a": {
		"label": "Battle Arena",
		"kind": "arena",
		"walkable": true,
		"description": "A cleared circle of hostile code waits for a challenger.",
	},
	"~": {
		"label": "Deep Ocean",
		"kind": "water",
		"walkable": false,
		"description": "The ocean is too deep to cross without a flight mount.",
	},
}

static func create_world_state(position: Vector2i = START_POSITION) -> Dictionary:
	return {
		"player": {
			"name": "Skye",
			"position": position,
		},
		"tiles": _build_world_tiles(),
	}

static func get_current_tile(world: Dictionary) -> Dictionary:
	var position: Vector2i = world["player"]["position"]
	var rows: Array = world["tiles"]
	if position.y < 0 or position.y >= rows.size():
		return WALL
	var row: Array = rows[position.y]
	if position.x < 0 or position.x >= row.size():
		return WALL
	return row[position.x]

static func get_world_encounter(world: Dictionary) -> Variant:
	return get_current_tile(world).get("encounter", null)

static func get_tile_danger(tile: Dictionary) -> float:
	return float(tile.get("danger", 0.0))

static func get_wild_encounter(tile: Dictionary) -> Variant:
	return tile.get("wild_encounter", null)

static func get_tile_at(world: Dictionary, position: Vector2i) -> Dictionary:
	return _get_tile_at(world, position)

static func get_navigation_alerts(world: Dictionary, profile: Dictionary = {}) -> Array:
	var alerts: Array = []
	var rows: Array = world.get("tiles", [])
	for y in rows.size():
		var row: Array = rows[y]
		for x in row.size():
			var tile: Dictionary = row[x]
			for quest_id in tile.get("sidequests", []):
				var quest := SideQuestData.get_sidequest(str(quest_id))
				if quest.is_empty():
					continue
				if profile.get("key_items", []).has(quest.get("reward_item", "")):
					continue
				var severity := _navigation_alert_severity(str(quest_id), tile, profile)
				var ticket := ServiceTicketData.ticket_for_sidequest(str(quest_id), quest, tile, severity)
				alerts.append({
					"position": Vector2i(x, y),
					"tile_id": tile.get("id", ""),
					"label": quest.get("title", tile.get("label", "System Alert")),
					"ticket_id": ticket.get("id", ""),
					"severity": severity,
					"icon": ticket.get("icon", "!"),
					"color": ticket.get("color", Color.WHITE),
					"type": ticket.get("type", "OPTIMIZATION"),
				})
			if tile.get("hazard", "") != "" and tile.get("sidequests", []).is_empty():
				alerts.append({
					"position": Vector2i(x, y),
					"tile_id": tile.get("id", ""),
					"label": tile.get("label", "Hazard"),
					"ticket_id": "HAZARD_%s" % tile.get("id", ""),
					"severity": 0.62,
					"icon": "!",
					"color": Color("#00ffff"),
					"type": "OPTIMIZATION",
				})
	alerts.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a.get("severity", 0.0)) > float(b.get("severity", 0.0))
	)
	return alerts

static func get_next_alert_waypoint(world: Dictionary, profile: Dictionary = {}) -> Vector2i:
	var alerts := get_navigation_alerts(world, profile)
	if alerts.is_empty():
		return Vector2i(-1, -1)
	return alerts[0].get("position", Vector2i(-1, -1))

static func move_player(world: Dictionary, direction: String) -> Dictionary:
	var deltas := {
		"north": Vector2i(0, -1),
		"south": Vector2i(0, 1),
		"east": Vector2i(1, 0),
		"west": Vector2i(-1, 0),
	}
	var delta: Vector2i = deltas.get(direction, Vector2i.ZERO)
	var next_position: Vector2i = world["player"]["position"] + delta
	var next_tile := _get_tile_at(world, next_position)
	if next_tile.is_empty() or not next_tile.get("walkable", false):
		return world

	var next_world := world.duplicate(true)
	next_world["player"]["position"] = next_position
	return next_world

static func move_player_to(world: Dictionary, position: Vector2i) -> Dictionary:
	var next_tile := _get_tile_at(world, position)
	if next_tile.is_empty() or not next_tile.get("walkable", false):
		return world
	var next_world := world.duplicate(true)
	next_world["player"]["position"] = position
	return next_world

static func _get_tile_at(world: Dictionary, position: Vector2i) -> Dictionary:
	var rows: Array = world["tiles"]
	if position.y < 0 or position.y >= rows.size():
		return {}
	var row: Array = rows[position.y]
	if position.x < 0 or position.x >= row.size():
		return {}
	return row[position.x]

static func _build_world_tiles() -> Array:
	var rows: Array = []
	for y in OVERWORLD_ROWS.size():
		var row: Array = []
		var line: String = OVERWORLD_ROWS[y]
		for x in line.length():
			var position := Vector2i(x, y)
			if LANDMARKS.has(position):
				var landmark: Dictionary = LANDMARKS[position].duplicate(true)
				landmark["walkable"] = true
				row.append(landmark)
			else:
				row.append(_terrain_tile(line[x], position))
		rows.append(row)
	return rows

static func _terrain_tile(symbol: String, position: Vector2i) -> Dictionary:
	var terrain: Dictionary = TERRAIN_BY_CHAR.get(symbol, TERRAIN_BY_CHAR["~"])
	if not terrain.get("walkable", false):
		var wall := WALL.duplicate(true)
		wall["id"] = "ocean_%d_%d" % [position.x, position.y]
		wall["label"] = terrain["label"]
		wall["kind"] = terrain["kind"]
		wall["description"] = terrain["description"]
		return wall
	var tile := terrain.duplicate(true)
	tile["id"] = "tile_%d_%d" % [position.x, position.y]
	return tile

static func _navigation_alert_severity(quest_id: String, tile: Dictionary, profile: Dictionary) -> float:
	if quest_id == "memory_leak" and not profile.get("mission_flags", []).has("mission_11_complete"):
		return 0.95
	if quest_id == "asset_recovery" or tile.get("hazard", "") != "":
		return 0.76
	return 0.58
