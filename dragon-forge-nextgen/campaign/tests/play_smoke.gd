extends SceneTree
## Bounded non-cheating controller policy. Actual actor clocks, guard, attacks and repairs.
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Data=preload("res://campaign/data.gd")
const Combat=preload("res://sim/combat.gd")
var w
var failures=0
var rows: Array=[]
func _initialize() -> void:
	call_deferred("_run")
func _move(direction: Vector3) -> void:
	for key in ["ng_left","ng_right","ng_up","ng_down"]:
		Input.action_release(key)
	if direction.x>0:Input.action_press("ng_right",minf(1,direction.x))
	if direction.x<0:Input.action_press("ng_left",minf(1,-direction.x))
	if direction.z>0:Input.action_press("ng_down",minf(1,direction.z))
	if direction.z<0:Input.action_press("ng_up",minf(1,-direction.z))
func _run() -> void:
	w=World.new();w.test_mode=true;root.add_child(w)
	for i in range(3):await physics_frame
	Rules.hatch(w.campaign)
	for room_id in ["signal-approach","overflow-vent","singularity"]:
		w.campaign=Rules.fresh();Rules.hatch(w.campaign)
		if room_id=="singularity":
			for z in Data.ZONES:
				w.campaign.cleared.append(z.id+"-boss")
				w.campaign.cores.append(z.id)
				w.campaign.installed.append(z.id)
		w.campaign.room=room_id;w.campaign.visited.append(room_id)
		w._enter_room(room_id,true)
		var ticks=0
		while is_instance_valid(w.enemy) and w.dragon.state.hp>0 and ticks<3600:
			await physics_frame
			ticks+=1
			var foe=w.enemy
			if not is_instance_valid(foe):break
			var delta: Vector3=foe.position-w.dragon.position;delta.y=0
			w.dragon.mouse_aim=false
			w.dragon.aim=delta.normalized()
			_move(delta.normalized() if delta.length()>2.0 else Vector3.ZERO)
			var open=foe.brain.vulnerable() or not foe.spec.shield
			if open:
				Input.action_release("ng_guard")
				for id in ["burst","breath","claw"]:
					if delta.length()<=Combat.ABILITIES[id].range and Combat.rejection(w.dragon.state,id)=="":
						w.dragon.try_ability(id)
						break
			else:Input.action_press("ng_guard")
			if w.dragon.state.hp<w.dragon.state.max_hp-60:w.repair()
		_move(Vector3.ZERO);Input.action_release("ng_guard")
		var success=not is_instance_valid(w.enemy) and w.dragon.state.hp>0
		if not success:failures+=1
		var row={"room":room_id,"won":success,"simulation_seconds":ticks/60.0,"remaining_hp":w.dragon.state.hp,"repair_charges":w.repairs}
		rows.append(row);print("CONTROLLER_PLAY "+JSON.stringify(row))
		w.hud.close_overlay()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/campaign"))
	var f=FileAccess.open("res://artifacts/campaign/controller-play.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"note":"Scripted guard/counter policy, not human playtesting or a balance verdict. No direct damage, forced vulnerability, unlimited healing or time-scale changes.","results":rows},"\t"));f.close()
	w.queue_free();await physics_frame
	print("CAMPAIGN_CONTROLLER_PLAY: %d failures"%failures)
	quit(1 if failures else 0)
