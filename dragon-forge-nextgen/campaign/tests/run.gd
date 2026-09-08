extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Data=preload("res://campaign/data.gd")
const Store=preload("res://campaign/save_store.gd")
const Combat=preload("res://sim/combat.gd")
const Patterns=preload("res://campaign/patterns.gd")
const World=preload("res://campaign/world.gd")
var checks=0
var failures=0

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		printerr("FAIL "+description)
	else:
		print("PASS "+description)

func frames(n: int=3) -> void:
	for i in range(n):
		await physics_frame

func _run() -> void:
	_rules()
	_storage()
	_patterns()
	var w=World.new()
	w.test_mode=true
	root.add_child(w)
	await frames(8)
	check(ProjectSettings.get_setting("application/run/main_scene")=="res://campaign/main.tscn","F5 launches campaign, not inspection or the small prototype")
	check(w.campaign.room=="forge" and not w.dragon.active,"campaign starts at the hatchery")
	w.interact()
	check(w.dragon.active and w.campaign.hatched,"first interaction hatches Magma without requiring movement")
	check(w.campaign.salvage==30,"starter salvage awarded exactly once")
	w.dragon.position=Vector3(-7,0.1,2)
	check(w.buy_upgrade("plating"),"real anvil purchase succeeds")
	check(w.dragon.state.max_hp==140,"plating upgrades actual health")
	w.hud.close_overlay()
	check(not w.buy_upgrade("power"),"insufficient salvage cannot buy upgrade")
	check(not w.travel("memory-vault"),"cannot skip to later boss from Forge")
	for z in Data.ZONES:
		check(w.travel(z.entry),"enter sector "+z.id)
		await frames()
		check(w.level.definition.id==z.entry,"level loads correct shelter "+z.id)
		check(w.travel(z.path),"enter approach "+z.id)
		await frames()
		check(w.enemies.size()==1,"actual patrol spawned "+z.id)
		check(not w.travel(z.gate),"uncleared approach exit blocked "+z.id)
		await _clear(w)
		check(w.travel(z.gate),"cleared path unlocks junction "+z.id)
		await frames()
		check(not w.travel(z.boss),"guardian and relay gate enforce prerequisites "+z.id)
		await _clear(w)
		check(not w.travel(z.boss),"uncharged relay still blocks boss "+z.id)
		check(w.travel(z.cache),"optional branch opens after guardian "+z.id)
		await frames()
		var before=w.campaign.salvage
		w.dragon.position=Vector3(0,0.1,-6)
		w.interact()
		check(w.campaign.salvage==before+Data.ROOMS[z.cache].reward,"cache adds real salvage "+z.id)
		w.interact()
		check(w.campaign.salvage==before+Data.ROOMS[z.cache].reward,"cache cannot be farmed "+z.id)
		check(w.travel(z.gate),"optional branch returns to junction "+z.id)
		await frames()
		check(w.enemies.is_empty(),"cleared guardian does not respawn for farming "+z.id)
		for item in w.conduits:
			w.dragon.global_position=item.node.global_position+Vector3(0,0.1,4)
			w.dragon.aim=Vector3.FORWARD
			w.dragon.input_grace=0.0
			w.dragon.state=Combat.fresh(w.campaign.module)
			check(w.dragon.try_ability("breath"),"real first relay breath "+item.id)
			w.dragon.advance_combat(0.23)
			check(not w.campaign.relays.has(item.id),"one breath is insufficient "+item.id)
			w.dragon.advance_combat(2.5)
			check(w.dragon.try_ability("breath"),"real second relay breath "+item.id)
			w.dragon.advance_combat(0.23)
			check(w.campaign.relays.has(item.id),"actual spell contact powers relay "+item.id)
		check(w.travel(z.boss),"powered route reaches boss "+z.id)
		await frames()
		check(w.enemy.spec.id==z.id+"-boss","authored boss loaded "+z.id)
		check(not w.travel("forge"),"north return requires boss/core but pause retreat remains separate "+z.id)
		await _clear(w)
		check(not w.travel("forge"),"core must be collected before north return "+z.id)
		w.dragon.position=Vector3(0,0.1,-19)
		w.interact()
		check(w.campaign.cores.has(z.id),"actual pedestal grants core "+z.id)
		check(w.travel("forge"),"physical return portal reaches Forge "+z.id)
		await frames()
		w.dragon.position=Vector3(5,0.1,5)
		w.interact()
		check(paused and w.hud.overlay_kind=="restored","sector restoration pauses for reward "+z.id)
		check(w.campaign.installed.has(z.id),"sector installation committed "+z.id)
		w.hud.close_overlay()
		check(not Rules.normalize(w.campaign).is_empty(),"campaign state remains save-valid "+z.id)
	check(w.campaign.caches.size()==4,"all four side caches reachable")
	check(w.travel("singularity"),"all four cores open final encounter")
	await frames()
	check(w.enemy.spec.patterns.size()==3,"final boss combines learned patterns")
	await _clear(w)
	w.dragon.position=Vector3(0,0.1,-19)
	w.interact()
	check(w.campaign.finished and paused and w.hud.overlay_kind=="ending","real final interaction reaches campaign ending")
	w.return_to_forge()
	await frames()
	check(w.campaign.finished and w.campaign.room=="forge","post-ending exploration retains completion")
	check(w.campaign.visited.size()==22,"end-to-end traversal visits all 22 rooms")
	# Failure/retry, pause, moving input and state-preserving room transition checks.
	w.campaign=Rules.fresh()
	Rules.hatch(w.campaign)
	w.campaign.room="signal-approach"
	w.campaign.visited.append("signal-approach")
	w._enter_room("signal-approach",true)
	await frames(5)
	w.dragon.state.iframes=0
	w.dragon.receive_damage(1000)
	await frames(2)
	check(paused and w.hud.overlay_kind=="defeat","actual death opens retry screen")
	w.retry()
	await frames(5)
	check(not paused and w.dragon.state.hp==w.dragon.state.max_hp and w.repairs==2,"retry restores room health and charges")
	w.dragon.state.hp-=65
	check(w.repair() and w.repairs==1,"repair charge heals and spends actual resource")
	w.hud.set_pause(true)
	var locked=w.enemy.brain.timer
	await frames(3)
	check(w.enemy.brain.timer==locked and not w.repair(),"paused menus freeze combat and reject healing")
	w.hud.close_overlay()
	w.return_to_forge()
	await frames(3)
	w.dragon.input_grace=0
	var at=w.dragon.position
	Input.action_press("ng_up")
	await frames(25)
	Input.action_release("ng_up")
	check(w.dragon.position.z<at.z-1.0,"real keyboard action moves the guardian through the Forge")
	# Sample every built layout and require all exits/important points share a navigable graph.
	for r in Data.ROOMS.values():
		w.campaign.room=r.id
		w._enter_room(r.id,true)
		await frames(2)
		var start=Vector2i(roundi(r.spawn[0]/4),roundi(r.spawn[2]/4))
		for exit in r.exits:
			var goal=Vector2i(roundi(exit.at[0]/4),roundi(exit.at[2]/4))
			check(w.level.nav.get_id_path(start,goal).size()>0,"walkable portal path "+r.id+" -> "+exit.to)
		for relay in r.relays:
			var goal=Vector2i(roundi(relay.at[0]/4),roundi(relay.at[2]/4))
			check(w.level.nav.get_id_path(start,goal).size()>0,"relay is reachable "+relay.id)
	w.queue_free()
	await frames(3)
	print("CAMPAIGN_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func _clear(w) -> void:
	# Controlled damage verifies encounter/reward wiring, not balance or player skill.
	for foe in w.enemies.duplicate():
		check(foe.take_hit(20)<=20,"closed/open shield produces bounded damage "+foe.spec.id)
		foe.brain.open_window(10)
		w.dragon.position=foe.position+Vector3(0,0,2)
		w.dragon.aim=Vector3.FORWARD
		w.dragon.input_grace=0
		w.dragon.state=Combat.fresh(w.campaign.module)
		var old=foe.hp
		check(w.dragon.try_ability("burst"),"real cast accepted "+foe.spec.id)
		w.dragon.advance_combat(0.33)
		check(foe.hp<old,"authoritative contact damages real actor "+foe.spec.id)
		if is_instance_valid(foe) and foe.hp>0:
			foe.take_hit(10000,true)
	await frames(3)

func _rules() -> void:
	var s=Rules.fresh()
	check(not Rules.normalize(s).is_empty(),"fresh schema is valid")
	check(not Rules.travel(s,"field-locker"),"hatch precedes exploration")
	check(Rules.hatch(s) and not Rules.hatch(s),"hatch reward is idempotent")
	check(not Rules.upgrade(s,"unknown"),"unknown upgrade rejected")
	check(Rules.upgrade(s,"power") and s.salvage==0,"upgrade spends correct amount")
	for field in ["version","salvage","room","upgrades"]:
		var broken=s.duplicate(true)
		broken[field]=null
		check(Rules.normalize(broken).is_empty(),"malformed field rejected "+field)
	var future=s.duplicate(true)
	future.version=99
	check(Rules.normalize(future).is_empty(),"future save rejected")
	var duplicate=s.duplicate(true)
	duplicate.visited.append("forge")
	check(Rules.normalize(duplicate).is_empty(),"duplicate progress entries rejected")
	check(not Data.zone_unlocked(s,"final"),"final gate needs all four installed cores")

func _storage() -> void:
	var store=Store.new()
	store.path="user://campaign-test-only.json"
	store.import_legacy=false
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))
	var state=store.read_campaign()
	check(store.write_campaign(state),"fresh save written")
	var bytes=FileAccess.get_file_as_bytes(store.path)
	Rules.hatch(state)
	check(store.write_campaign(state),"second save committed")
	check(FileAccess.get_file_as_bytes(store.path+".bak")==bytes,"prior bytes preserved in backup")
	check(store.read_campaign()==state,"JSON roundtrip preserves normalized campaign")
	var f=FileAccess.open(store.path,FileAccess.WRITE)
	f.store_string("broken data")
	f.close()
	store.read_campaign()
	check(store.blocked and not store.write_campaign(state),"corrupt campaign cannot be silently overwritten")
	check(FileAccess.get_file_as_string(store.path)=="broken data","corrupt bytes unchanged")
	check(store.replace_with_fresh_campaign(),"confirmed New campaign can replace a blocked corrupt save")
	check(not store.blocked and store.read_campaign()==Rules.fresh(),"explicit replacement commits a readable current-schema campaign")
	check(FileAccess.get_file_as_string(store.path+".bak")=="broken data","explicit replacement backs up the exact corrupt bytes")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(store.path+suffix))

func _patterns() -> void:
	var beam=Patterns.lock("beam",Vector3.ZERO,Vector3(0,0,-4))
	check(Patterns.contains(beam,Vector3(0,0,-6)),"beam hits its marked lane")
	check(not Patterns.contains(beam,Vector3(3,0,-6)),"beam permits sideways evasion")
	var ring=Patterns.lock("ring",Vector3.ZERO,Vector3.FORWARD)
	check(not Patterns.contains(ring,Vector3(0,0,-1)),"ring center is genuinely safe")
	check(Patterns.contains(ring,Vector3(0,0,-4)),"ring marked band deals damage")
	check(not Patterns.contains(ring,Vector3(0,0,-8)),"outside ring is safe")
	var fan=Patterns.lock("fan",Vector3.ZERO,Vector3(0,0,-4))
	check(fan.circles.size()==3,"fan locks exactly three circles")
