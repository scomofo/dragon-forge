extends SceneTree
const World = preload("res://campaign/world.gd")
const Rules = preload("res://campaign/progress.gd")
const Growth = preload("res://campaign/growth.gd")
const Combat = preload("res://campaign/guardian_combat.gd")
const Party = preload("res://campaign/party.gd")
const Store = preload("res://campaign/save_store.gd")
const Data = preload("res://campaign/data.gd")
const Enemy = preload("res://campaign/enemy.gd")
const Probe = preload("res://validation/foot_review.gd")
const Studio = preload("res://validation/character_inspection.gd")
var checks = 0
var failures = 0
var w

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, text: String) -> void:
	checks += 1
	if not ok: failures += 1
	print(("PASS " if ok else "FAIL ") + text)

func frames(count: int = 3) -> void:
	for i in range(count): await physics_frame

static func eligible() -> Dictionary:
	var c = Rules.fresh()
	Rules.hatch(c)
	for z in Data.ZONES.slice(0,2):
		for r in Data.ROOMS.values():
			if r.zone != z.id: continue
			c.visited.append(r.id)
			for foe in r.enemies: c.cleared.append(foe.id)
		c.cores.append(z.id)
		c.installed.append(z.id)
	c.ice_rescued = true
	Rules.hatch_ice(c)
	return c

func run() -> void:
	var c = Rules.fresh()
	check(Growth.points(c) == 0 and Growth.rank(c) == 1, "new campaign starts with zero bond")
	check(not Growth.select(c,"fire","flashfire"), "dormant guardian cannot evolve")
	Rules.hatch(c); c.room="signal-approach"; c.visited.append(c.room)
	check(Rules.defeat(c,"outer-patrol") and Growth.points(c)==20, "first patrol adds 20 shared bond")
	check(not Rules.defeat(c,"outer-patrol") and Growth.points(c)==20, "retry cannot farm bond")
	c=eligible()
	check(not Rules.normalize(c).is_empty(), "eligible journey is a valid campaign")
	check(Growth.points(c)==300 and Growth.rank(c)==3, "two sector journeys reach Bond III naturally without side caches")
	c.caches.append("maintenance-cache")
	check(Growth.points(c)==315, "optional cache gives 15 bond")
	var before=c.duplicate(true)
	check(not Growth.select(c,"ice","flashfire") and c==before, "wrong guardian specialization cannot mutate progress")
	check(not Growth.select(c,"void","aegis"), "unknown guardian rejected")
	c.room="frozen-vault"
	check(not Growth.select(c,"fire","flashfire"), "evolution unavailable outside the Forge")
	c.room="forge"
	check(Growth.select(c,"fire","flashfire"), "earned Magma evolution succeeds")
	check(not Growth.select(c,"fire","flashfire"), "repeated evolution request is idempotent")
	check(c.salvage==before.salvage and c.cleared==before.cleared, "evolution does not spend currency or erase progress")
	check(Growth.select(c,"ice","aegis") and Growth.ready_guardian(c)=="", "both owned guardians can evolve independently")
	check(not Rules.normalize(c).is_empty(), "selected evolution serializes safely")
	for version in [1,2]:
		var legacy=eligible();legacy.version=version;legacy.erase("evolutions")
		if version==1:
			for key in ["guardians","active_guardian","ice_rescued"]:legacy.erase(key)
		var migrated=Rules.normalize(legacy)
		check(migrated.version==4 and migrated.evolutions=={"fire":"","ice":""}, "version %d migrates without auto-evolving" % version)
		check(migrated.cleared==legacy.cleared and migrated.installed==legacy.installed and migrated.salvage==legacy.salvage, "version %d keeps milestones and salvage" % version)
		var store=Store.new();store.import_legacy=false;store.path="user://evolution-test-%d.json" % version
		var bytes=JSON.stringify(legacy,"  ")
		var f=FileAccess.open(store.path,FileAccess.WRITE);f.store_string(bytes);f.close()
		var loaded=store.read_campaign()
		check(FileAccess.get_file_as_string(store.path)==bytes and loaded.version==4, "migration never writes on load")
		check(store.write_campaign(loaded), "migrated version commits successfully")
		check(FileAccess.get_file_as_string(store.path+".bak")==bytes, "migration backup preserves original bytes")
		for suffix in ["",".bak",".tmp"]:
			if FileAccess.file_exists(store.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	for bad in [{},[],{"fire":true,"ice":""},{"fire":"aegis","ice":""},{"fire":"flashfire","ice":"aegis","void":""}]:
		var broken=c.duplicate(true);broken.evolutions=bad
		check(Rules.normalize(broken).is_empty(), "malformed evolution state rejected")
	var unearned=Rules.fresh();Rules.hatch(unearned);unearned.evolutions.fire="furnace"
	check(Rules.normalize(unearned).is_empty(), "unearned evolved save rejected")
	var unowned=eligible();unowned.guardians=["fire"];unowned.evolutions.ice="aegis"
	check(Rules.normalize(unowned).is_empty(), "unowned evolved guardian rejected")
	var future=c.duplicate(true);future.version=99
	check(Rules.normalize(future).is_empty(), "future save remains protected")
	var party=Party.new();party.rebuild(c)
	check(is_equal_approx(party.states.fire.max_hp,132.0) and is_equal_approx(party.states.ice.max_hp,118.8), "evolution applies ten percent health once")
	party.rebuild(c)
	check(is_equal_approx(party.states.fire.max_hp,132.0), "rebuild never stacks evolution bonus")
	check(is_equal_approx(Combat.technique_damage(party.states.fire,"claw"),26.4), "evolved technique damage is ten percent stronger")
	check(Combat.ABILITIES.breath.cooldown==2.4 and Combat.rule(party.states.fire,"breath").cooldown==1.8, "Flashfire uses a private cooldown override")
	for guardian in ["fire","ice"]:
		for spec in Growth.OPTIONS[guardian]:
			var state=Combat.fresh("",guardian);state.evolution=spec
			for move in Combat.ORDER:
				state.cooldowns.clear();state.heat=0;Combat.cancel_action(state)
				check(Combat.cast(state,move), spec+" casts "+move)
				var windup=Combat.rule(state,move).windup
				check(Combat.tick(state,windup-.001)=="", "evolution never advances contact early")
				check(Combat.tick(state,.002)==move and Combat.tick(state,1.0)=="", "evolved contact remains exactly once")
	w=World.new();w.test_mode=true;root.add_child(w);await frames(5)
	w.campaign=eligible();w._enter_room("forge",true);await frames(4)
	check(not w.choose_evolution("fire","flashfire"), "world rejects remote Nursery request")
	w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	w.hud.show_growth("fire")
	check(paused and w.hud.overlay_kind=="growth", "evolution selection pauses actual gameplay")
	check(w.choose_evolution("fire","flashfire") and w.hud.overlay_kind=="evolved", "UI evolution applies and shows result")
	check(w.dragon.rig.model.scene_file_path.ends_with("magma_evolved.glb"), "evolution loads the committed Crowned Magma mesh")
	var live=w.dragon.state
	check(Combat.rule(live,"breath").cooldown==1.8 and is_equal_approx(live.max_hp,132), "actual controller receives evolved rules")
	w.hud.close_overlay();w.dragon.input_grace=0
	check(w.dragon.try_ability("breath"), "actual evolved breath starts")
	check(is_equal_approx(w.dragon.state.cooldowns.breath,1.8), "Flashfire cooldown affects real casts")
	check(not w.choose_evolution("fire","furnace"), "in-progress attack rejects Nursery reconfiguration")
	w.dragon.advance_combat(.51)
	check(w.choose_evolution("fire","furnace"), "free specialization change after recovery")
	w.hud.close_overlay();w.dragon.input_grace=0
	w.dragon.try_ability("wall");w.dragon.advance_combat(.21)
	check(w.walls.size()==1 and is_equal_approx(w.walls[0].ttl,4.8), "Furnace Heart extends actual field lifetime")
	var field=w.walls[0]
	check(is_equal_approx(field.damage,15.4), "evolution strengthens snapshotted field damage")
	w.dragon.advance_combat(.30)
	check(w.choose_evolution("ice","deepwinter"), "reserve can evolve at Nursery without replacing active guardian")
	w.hud.close_overlay();w.dragon.input_grace=0;w.party.swap_remaining=0
	check(w.swap_guardian("ice"), "evolved reserve swaps through normal controller")
	check(w.dragon.rig.model.scene_file_path.ends_with("rime_evolved.glb"), "swap loads actual Aurora Rime export")
	check(w.walls[0].guardian=="fire" and w.walls[0].damage==field.damage, "reserve evolution and swap do not reassign field ownership")
	w._clear_encounter();await frames(2)
	var foe=Enemy.new();foe.spec={"id":"probe","name":"Probe","hp":500.0,"damage":12.0,"boss":false,"shield":false,"patterns":["slam"]};foe.target=w.dragon;foe.navigation=w
	w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*2
	foe.set_physics_process(false);w.enemies=[foe];w._select_enemy()
	w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD;w.dragon.mouse_aim=false
	check(w.dragon.try_ability("breath"), "evolved Rime casts through real input adapter")
	w.dragon.advance_combat(.29)
	check(is_equal_approx(foe.chilled,4.5) and is_equal_approx(foe.hp,467.0), "Deep Winter applies longer Chill at actual contact")
	w.dragon.advance_combat(.4);w.dragon.try_ability("wall");w.dragon.advance_combat(.25)
	var frost=w.walls[-1];foe.position=frost.at;foe.chilled=0
	w._tick_walls(.10)
	check(is_equal_approx(foe.chilled,4.5) and frost.guardian=="ice", "Deep Winter persists on field ticks")
	foe.queue_free();w.enemies=[];w.enemy=null
	w.dragon.advance_combat(.4);w.dragon.position=Vector3(6,.1,8)
	check(w.choose_evolution("ice","aegis"), "Aurora Rime can reconfigure at Nursery")
	w.hud.close_overlay();w.dragon.input_grace=0
	w.dragon.try_ability("burst");w.dragon.advance_combat(.21)
	check(is_equal_approx(w.dragon.state.ward,6.0), "Glacial Ward lasts six seconds in real combat state")
	w.dragon.advance_combat(.3);w.dragon.input_grace=0;w.party.swap_remaining=0;w.swap_guardian("fire")
	check(w.dragon.state.ward==0 and w.party.states.ice.ward>5, "extended ward stays with Rime in reserve")
	w.party.tick_reserve(.20,0)
	check(w.party.states.ice.ward<5.7, "reserve ward expires with simulation time")
	w._clear_encounter();w.return_to_forge();await frames(5)
	check(w.campaign.evolutions.fire=="furnace" and w.campaign.evolutions.ice=="aegis", "room return retains both evolution choices")
	# Probe independent skin vertices after real movement; never measure the IK targets alone.
	for guardian in ["fire","ice"]:
		w.hud.close_overlay();w.party.swap_remaining=0;w.dragon.input_grace=0
		if w.party.active_id!=guardian:w.swap_guardian(guardian)
		w.dragon.position=Vector3(0,.1,8);w.dragon.rig.reset_pose();w.dragon.input_grace=0
		await measure_feet(guardian)
	w.queue_free();await frames(4)
	var studio=Studio.new();root.add_child(studio);await frames(3)
	for index in [4,5]:
		studio.load_actor(index)
		var count=studio.get_child_count()
		for view in range(5):studio.set_view(view)
		check(studio.get_child_count()==count, "camera changes never instance duplicate evolved meshes")
		check(studio.feet.valid, "evolved studio uses independent sole probes")
		for clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:
			studio.select_clip(studio.clips.find(clip));studio.scrub(studio.player.get_animation(clip).length*.5)
			check(studio.clip==clip, "evolved studio samples "+clip)
	studio.queue_free();await frames(3)
	print("EVOLUTION_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func measure_feet(guardian: String) -> void:
	var probe=Probe.new();w.add_child(probe);probe.display_enabled=false
	check(probe.configure(w.dragon.rig.model,"magma_guardian" if guardian=="fire" else "ice_guardian"), "evolved sole probe configured "+guardian)
	var anchors={};var contacts=0;var worst=0.0;var clearance=INF
	w.dragon.mouse_aim=false
	Input.action_press("ng_up")
	for frame in range(100):
		await physics_frame
		if frame==38:Input.action_release("ng_up")
		if frame==55:w.dragon.try_ability("breath")
		var points=probe.points()
		var solver=w.dragon.rig.feet if guardian=="fire" else w.dragon.rig.planting
		for side in points:
			var center=Vector3.ZERO;var low=INF
			for p in points[side]:center+=p;low=minf(low,p.y)
			center/=points[side].size()
			var sample: Dictionary=solver.samples.get(side,{})
			if sample.get("planted",false):
				var key=side+str(sample.plant_id)
				if not anchors.has(key):anchors[key]=center
				worst=maxf(worst,Vector2(center.x-anchors[key].x,center.z-anchors[key].z).length());contacts+=1
			var hit=w.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(center+Vector3.UP,center-Vector3.UP,64))
			if not hit.is_empty():clearance=minf(clearance,low-hit.position.y)
	Input.action_release("ng_up")
	check(contacts>(100 if guardian=="fire" else 200), "genuine evolved stance coverage "+guardian)
	check(worst<.015 and clearance>=-.004, "evolved contact stays within 15mm drift / 4mm ground tolerance "+guardian)
	print("EVOLVED_CONTACT: %s samples=%d drift_m=%.6f clearance_m=%.6f" % [guardian,contacts,worst,clearance])
	probe.queue_free()
