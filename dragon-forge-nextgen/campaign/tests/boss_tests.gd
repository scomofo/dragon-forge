extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Data=preload("res://campaign/data.gd")
const Patterns=preload("res://campaign/patterns.gd")
const Catalog=preload("res://campaign/bosses/catalog.gd")
const Rig=preload("res://campaign/bosses/rig.gd")
const Studio=preload("res://validation/character_inspection.gd")
const Arena=preload("res://validation/boss_arena.gd")
var checks=0
var failures=0
var contacts: Array=[]
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n: int=3) -> void:
	for i in range(n): await physics_frame
func pose(rig) -> Array:
	var result: Array=[]
	for i in range(rig.skeleton.get_bone_count()): result.append(rig.skeleton.get_bone_global_pose(i))
	return result
func run() -> void:
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.set_physics_process(false)
	w.dragon.set_physics_process(false)
	var seen={}
	for j in range(Catalog.ORDER.size()):
		w.campaign=Rules.fresh();Rules.hatch(w.campaign)
		w.campaign.room=Catalog.ROOMS[j];w.campaign.visited.append(w.campaign.room)
		w._enter_room(w.campaign.room,true);await frames()
		var foe=w.enemy
		foe.set_physics_process(false)
		check(foe.visual is Rig,"real campaign selects distinct boss rig / "+foe.spec.id)
		check(foe.visual.boss_id==Catalog.ORDER[j],"stable campaign ID selects correct model")
		var key=foe.visual.model.scene_file_path
		check(not seen.has(key),"unique imported resource / "+key);seen[key]=true
		check(foe.find_children("*","CollisionShape3D",true,false).size()==1,"presentation has no extra colliders")
		var collider=foe.find_children("*","CollisionShape3D",true,false)[0]
		check(is_equal_approx(collider.shape.radius,.7) and is_equal_approx(collider.shape.height,2.4),"unchanged target collider")
		check(foe.max_hp==float(foe.spec.hp),"unchanged authored health")
		foe.impact.connect(func(shape,amount): contacts.append({"shape":shape,"amount":amount,"clip":foe.visual.sampled_clip,"time":foe.visual.sampled_time}))
		var rig=foe.visual
		w.dragon.position=Vector3(0,.1,-5.8)
		w.camera_rig._process(1.0)
		var head_screen=w.camera_rig.camera.unproject_position(foe.position+Vector3.UP*Catalog.entry(foe.spec.id).height)
		check(head_screen.y>=175.0 and head_screen.y<=560.0,"boss head clears central combat HUD at standard engagement range")
		var tail_screen=w.camera_rig.camera.unproject_position(w.dragon.position+Vector3(0,.05,.6))
		check(tail_screen.y<=581.0,"player support area clears ability dock during boss framing")
		for kind in foe.spec.patterns:
			check(rig.player.has_animation("tell_"+kind) and rig.player.has_animation("strike_"+kind),"authored matching tell + strike / "+kind)
			rig._sample("tell_"+kind,1.0);var a=pose(rig)
			rig._sample("strike_"+kind,0.0);var b=pose(rig)
			var same=true
			for i in range(a.size()): same=same and a[i].is_equal_approx(b[i])
			check(same,"tell endpoint matches impact start exactly / "+kind)
			for reduced in [false,true]:
				w.dragon.position=foe.position+Vector3(0,0,4)
				foe.brain.mode="seek";foe.brain.enraged=false;foe.sequence=foe.spec.patterns.find(kind)
				foe.reduced_motion=reduced;foe.hp=foe.max_hp*(.25 if foe.spec.id=="singularity-final" else 1.0)
				foe.brain.enraged=foe.hp<=foe.max_hp*.5
				foe._begin_attack()
				var expected_duration=1.15 if foe.brain.enraged else 1.65
				var locked=foe.shape.duplicate(true)
				contacts.clear()
				check(is_equal_approx(foe.brain.locked_duration,expected_duration),"full-health tell duration unaffected by art or reduced motion")
				var hp=foe.hp
				check(foe.take_hit(10)==0 and foe.hp==hp,"closed shield remains authoritative")
				w.dragon.position+=Vector3(8,0,0)
				var ticks=0
				while contacts.is_empty() and ticks<104:
					foe._physics_process(1.0/60.0);ticks+=1
				check(contacts.size()==1 and absf(ticks/60.0-expected_duration)<.017,"one real contact after full windup")
				check(contacts[0].shape==locked,"moving target cannot bend the locked shape")
				check(contacts[0].clip=="strike_"+kind and contacts[0].time==0.0,"impact observers see actual strike frame zero")
				check(contacts[0].amount==float(foe.spec.damage),"damage untouched")
				check(foe.brain.vulnerable() and foe.shield.visible==false,"shield opens on real contact")
				check(foe.take_hit(10)==10,"counter damage lands in recovery")
				foe._physics_process(.25)
				check(contacts.size()==1,"no duplicate visual-generated damage")
				check(foe.tell.visible==false,"short impact outline expires in recovery")
				check(is_finite(rig.emission_origin().x),"animated core socket remains finite")
		# All imported animations sampled, not just idle beauty poses.
		for clip in rig.player.get_animation_list():
			if clip=="RESET":continue
			var finite=true
			for q in [0.0,.25,.5,.75,1.0]:
				rig._sample(clip,rig.player.get_animation(clip).length*q)
				for transform in pose(rig): finite=finite and transform.is_finite()
			check(finite,"finite stress samples / "+foe.spec.id+" / "+clip)
		if foe.spec.id=="singularity-final":
			check(Catalog.phase(foe.spec.id,foe.max_hp,foe.max_hp)==1 and Catalog.phase(foe.spec.id,foe.max_hp*.5,foe.max_hp)==2 and Catalog.phase(foe.spec.id,foe.max_hp*.25,foe.max_hp)==3,"three unchanged health thresholds")
			rig.phase_index=1;rig._sample("idle",0);var p1=pose(rig)
			rig.phase_index=3;rig._sample("idle",0);var p3=pose(rig)
			check(not p1[2].is_equal_approx(p3[2]),"final phase changes cage pose without moving collider")
			for ratio in [1.0,.5,.25]:
				foe.hp=foe.max_hp*ratio;foe.sequence=2;foe._begin_attack()
				check(foe.pattern==foe.spec.patterns[2%Catalog.phase(foe.spec.id,foe.hp,foe.max_hp)],"final phase preserves authored pattern unlocks")
		foe.take_hit(100000,true)
		check(rig.dying and rig.get_parent()==w.level,"death echo is detached cosmetic model")
		check(rig.find_children("*","CollisionObject3D",true,false).is_empty(),"dead echo cannot block or deal damage")
		await frames()
		check(not is_instance_valid(w.enemy),"death still clears encounter immediately")
		if is_instance_valid(rig): rig._process(.86)
		await frames()
		check(not is_instance_valid(rig),"cosmetic remains are bounded and cleaned up")
	# Ordinary enemies are not replaced by bosses.
	w.campaign=Rules.fresh();Rules.hatch(w.campaign);w.campaign.room="signal-approach";w._enter_room(w.campaign.room,true);await frames()
	check(not w.enemy.visual is Rig,"ordinary Sentinel path remains unchanged")
	w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	for i in range(5):
		# Nox occupies inspector slot 9; bosses now begin at slot 10.
		studio.load_actor(10+i)
		check(studio.actor_id==Catalog.ASSET_IDS[i] and studio.player!=null,"neutral/rim inspector loads boss / "+Catalog.ASSET_IDS[i])
		check(not studio.feet.valid,"no invented planted-foot measurement for non-foot rigs")
		studio.set_material(2);studio.set_material(0)
	studio.queue_free();await frames()
	var arena=Arena.new();root.add_child(arena);await frames()
	check(arena.test_mode and not arena.store.existed and arena.audio==null,"rehearsal never loads campaign/audio/preferences")
	for i in range(5):
		arena.select_boss(i);await frames()
		check(arena.enemy.spec.id==Catalog.ORDER[i],"rehearsal uses actual boss room and controller")
		arena.set_review_health(2)
		check(is_equal_approx(arena.enemy.hp,arena.enemy.max_hp*.25),"review-only health setup")
	arena.freeze_pending=true;arena.observe_frame()
	check(paused,"rehearsal pauses after contact observation")
	paused=false
	arena.hud.close_overlay();arena.queue_free();await frames()
	print("BOSS_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
