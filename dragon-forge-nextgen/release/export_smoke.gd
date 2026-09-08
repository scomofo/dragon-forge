extends Node
## Explicit opt-in package check. Never loads or writes the player's campaign/preferences.
const VoidContract = preload("res://release/void_contract.gd")
const ShadowContract = preload("res://release/shadow_contract.gd")
const World = preload("res://campaign/world.gd")
const Rules = preload("res://campaign/progress.gd")
const Data = preload("res://campaign/data.gd")
const Store = preload("res://campaign/save_store.gd")
const TrialStore = preload("res://campaign/trial_store.gd")
const Trials = preload("res://campaign/trials.gd")
const Bosses = preload("res://campaign/bosses/catalog.gd")
const Audio = preload("res://campaign/audio/director.gd")
const AudioCatalog = preload("res://campaign/audio/catalog.gd")
var failures = 0
var checks = 0
var output = ""
var w
var root: Window
var paused: bool:
	get: return get_tree().paused
	set(value): get_tree().paused = value

func quit(code: int = 0) -> void: get_tree().quit(code)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = get_tree().root
	if not OS.get_cmdline_user_args().has("--ci-release-check"):
		printerr("Package check requires explicit --ci-release-check.")
		quit(2)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report-dir="): output = arg.trim_prefix("--report-dir=")
	if output.is_empty() or not output.is_absolute_path():
		printerr("Package check requires an absolute --report-dir.")
		quit(2)
		return
	root.size = Vector2i(1280,720)
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + label)

func frames(n: int = 4) -> void:
	for i in range(n): await get_tree().process_frame

func shot(label: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await frames()
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(label + ".png")) == OK, "capture " + label)

func fixture() -> Dictionary:
	var s = Rules.fresh()
	Rules.hatch(s)
	s.visited = Data.ROOMS.keys()
	s.cleared = Data.encounter_ids()
	for z in Data.ZONES:
		s.cores.append(z.id)
		s.installed.append(z.id)
	s.ice_rescued = true
	s.lattice_recovered = true
	s.storm_forged = true
	s.stone_imprint_recovered = true
	s.stone_forged = true
	s.venom_culture_recovered = true
	s.venom_forged = true
	s.shadow_forged = true
	s.void_imprint_recovered = true
	s.void_forged = true
	s.finished = true
	s.guardians = ["fire","ice","storm","stone","venom","shadow","void"]
	s.loadout = ["fire","stone"]
	s.evolutions = {"fire":"flashfire","ice":"aegis","storm":"overcharge"}
	return s

func run() -> void:
	DirAccess.make_dir_recursive_absolute(output)
	check(ProjectSettings.get_setting("application/run/main_scene") == "res://campaign/main.tscn", "editor default entry is full campaign")
	if OS.has_feature("standalone"):
		check(get_parent().get_meta("standalone_entry",false), "export-only bootstrap dispatched explicit package check")
	check(ProjectSettings.get_setting("application/config/custom_user_dir_name") == "dragon-forge-nextgen-prototype", "original save-directory identity retained")
	if OS.get_cmdline_user_args().has("--expect-export"):
		check(not OS.has_feature("editor"), "running standalone template, not editor")
		check(not ResourceLoader.exists("res://campaign/tests/run.gd"), "development tests excluded from pack")
	var info = JSON.parse_string(FileAccess.get_file_as_string("res://release/build_info.json"))
	check(info is Dictionary and info.get("assets",[]).size() == 73, "pack build identity and 73 art/audio resources present")
	if not info is Dictionary: quit(1); return
	for path in info.assets:
		var resource = load(path)
		check(resource != null, "load packed asset " + path)
		if resource is PackedScene:
			var model = resource.instantiate()
			root.add_child(model)
			check(not model.find_children("*","MeshInstance3D",true,false).is_empty(), "imported mesh " + path)
			model.queue_free()
		elif resource is AudioStream:
			check(resource.get_length() > 1.0, "decode soundtrack " + path)
	await frames()
	# Instantiate the actual main scene, but isolate its storage before _ready.
	w = load("res://campaign/main.tscn").instantiate()
	w.test_mode = true
	root.add_child(w)
	await frames()
	w.title_open = true
	w.hud.show_title()
	await shot("01-exported-title")
	w.hud.close_overlay()
	w.title_open = false
	var s = fixture()
	check(not Rules.normalize(s).is_empty(), "prepared checkpoint is valid schema 9")
	for room in Data.ROOMS:
		w.campaign = s.duplicate(true)
		w.campaign.room = room
		for foe in Data.ROOMS[room].enemies: w.campaign.cleared.erase(foe.id)
		w._enter_room(room, true)
		await frames(2)
		check(is_instance_valid(w.level) and is_instance_valid(w.dragon.rig), "build packed room " + room)
		if room in Bosses.ROOMS:
			check(is_instance_valid(w.enemy) and w.enemy.visual.player != null, "imported boss rig " + room)
		if room in ["overflow-vent","protocol-throne"]:
			w.dragon.position = Vector3(0,.1,-5.8)
			w.camera_rig._process(1.0)
			paused = true
			await shot("02-" + room)
			paused = false
	w.campaign = s.duplicate(true)
	w._enter_room("forge",true)
	for pair in [["fire","ice"],["fire","storm"],["fire","stone"],["fire","venom"],["fire","shadow"],["fire","void"]]:
		w.campaign.loadout = pair
		w.campaign.active_guardian = "fire"
		w._enter_room("forge",true)
		w.dragon.input_grace = 0
		w.party.swap_remaining = 0
		w.swap_guardian(pair[1])
		check(w.party.active_id == pair[1] and w.dragon.guardian == pair[1] and is_instance_valid(w.dragon.rig), "packed guardian swap " + pair[1])
		if pair[1]=="shadow":ShadowContract.run(w,check)
	VoidContract.run(w,check)
	var audio = Audio.new()
	audio.test_mode = true
	root.add_child(audio)
	for role in AudioCatalog.TRACKS:
		check(audio.track(role) != null, "runtime soundtrack role " + role)
	audio.set_value("muted",true)
	audio.queue_free()
	# Exercise save migration using a unique temporary file, never the real save.
	var store = Store.new()
	store.import_legacy = false
	store.path = "user://release-check-%s.json" % str(Time.get_ticks_usec())
	for version in [5,7,8]:
		var old = s.duplicate(true)
		old.version = version
		old.active_guardian = "fire"
		old.erase("void_imprint_recovered")
		old.erase("void_forged")
		if version<8:old.erase("shadow_forged")
		if version == 5:
			old.guardians = ["fire","ice","storm"]
			old.loadout = ["fire","storm"]
			for key in ["stone_imprint_recovered","stone_forged","venom_culture_recovered","venom_forged"]:
				old.erase(key)
		elif version==7:
			old.guardians = ["fire","ice","storm","stone","venom"]
			old.loadout = ["fire","venom"]
		else:
			old.guardians=["fire","ice","storm","stone","venom","shadow"]
			old.loadout=["fire","shadow"]
		# Deliberate formatting checks byte preservation, not merely parsed equality.
		var bytes = JSON.stringify(old,"  ") + "\n"
		var temporary = FileAccess.open(store.path,FileAccess.WRITE)
		check(temporary != null,"temporary schema-%d save writable" % version)
		if temporary != null:
			temporary.store_string(bytes)
			temporary.close()
			var loaded = store.read_campaign()
			check(not store.blocked and loaded.version == 9 and not loaded.void_imprint_recovered and not loaded.void_forged, "schema-%d migrates to 9 without Void progress" % version)
			var expected = old.duplicate(true)
			expected.version = 9
			if version<8:expected.shadow_forged = false
			expected.void_imprint_recovered=false
			expected.void_forged=false
			if version == 5:
				for key in ["stone_imprint_recovered","stone_forged","venom_culture_recovered","venom_forged"]:
					expected[key] = false
			check(loaded == expected,"schema-%d preserves all earned progression" % version)
			check(FileAccess.get_file_as_string(store.path) == bytes,"load leaves schema-%d bytes intact" % version)
			check(store.write_campaign(loaded),"exported schema-%d migration writes successfully" % version)
			check(FileAccess.get_file_as_string(store.path+".bak") == bytes,"exported save backs up exact schema-%d bytes" % version)
			check(store.read_campaign() == expected,"schema-%d migration round-trips" % version)
		for suffix in ["", ".bak", ".tmp"]:
			if FileAccess.file_exists(store.path+suffix):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	# Trial records have a separate roster domain and must survive native packaging too.
	var trial_store = TrialStore.new()
	trial_store.path = "user://release-trial-check-%s.json" % str(Time.get_ticks_usec())
	var trial_id: String = Trials.DATA.keys()[0]
	for guardian in Rules.GUARDIAN_IDS:
		var records = trial_store.fresh()
		var pair = ["fire"] if guardian == "fire" else ["fire",guardian]
		check(trial_store.record(records,trial_id,1000,0,pair),"exported trial writes perfect clear with " + guardian)
		check(trial_store.record(records,trial_id,1500,9,pair),"exported trial writes later clear with " + guardian)
		var restored = trial_store.read_records()
		var record: Dictionary = restored.records.get(trial_id,{})
		check(record.get("clears") == 2 and record.get("best_ms") == 1000 and record.get("best_damage") == 0 and record.get("last_pair") == pair,"exported trial retains pair and perfect personal best with " + guardian)
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(trial_store.path+suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(trial_store.path+suffix))
	w.hud.close_overlay()
	w.queue_free()
	await frames(5)
	# Silent mixer drain before process teardown.
	await get_tree().create_timer(.3,true).timeout
	var result = {"checks":checks,"failures":failures,"os":OS.get_name(),"architecture":Engine.get_architecture_name(),"editor":OS.has_feature("editor"),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"build":info,"note":"Finite prepared-state package checks, not a human playthrough or target-device benchmark."}
	var f = FileAccess.open(output.path_join("package-check.json"),FileAccess.WRITE)
	if f != null: f.store_string(JSON.stringify(result,"  ")); f.close()
	print("EXPORT_SMOKE: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
