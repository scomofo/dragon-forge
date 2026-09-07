extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Catalog=preload("res://campaign/bosses/catalog.gd")
const Studio=preload("res://validation/character_inspection.gd")
const Arena=preload("res://validation/boss_arena.gd")
const OUT="res://artifacts/bosses/captures"
var failures=0
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("run")
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func shot(name_text: String) -> void:
	await frames();await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+name_text+".png")!=OK:failures+=1
	print("BOSS_CAPTURE "+name_text)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.hud.show_title();await shot("00-title");w.hud.close_overlay();w.title_open=false
	for i in range(5):
		w.campaign=Rules.fresh();Rules.hatch(w.campaign)
		w.campaign.room=Catalog.ROOMS[i];w.campaign.visited.append(w.campaign.room)
		w._enter_room(w.campaign.room,true);await frames()
		var e=w.enemy
		w.dragon.position=Vector3(0,.1,-5.8);w.dragon.rotation.y=0
		w.camera_rig.position=w.dragon.position
		w.hud.toast_remaining=0
		e.set_physics_process(false);w.dragon.set_physics_process(false)
		e.visual.rotation.y=PI;e.visual._sample("idle",0)
		w.camera_rig._process(1.0) # Settle the actual gameplay framing before freezing.
		paused=true
		await shot("%s-1-gameplay"%Catalog.ASSET_IDS[i])
		e._begin_attack();e.brain.timer=e.brain.locked_duration*.22
		e.visual.animate(0,e.brain,0,w.reduced_motion);e.tell.visible=true
		await shot("%s-2-tell"%Catalog.ASSET_IDS[i])
		e.brain.mode="recover";e.brain.timer=2.0;e.shield.visible=false;e.visual.contact_now()
		await shot("%s-3-contact"%Catalog.ASSET_IDS[i])
		e.visual._sample("open",.5);e.tell.visible=false
		await shot("%s-4-open"%Catalog.ASSET_IDS[i])
		if i==4:
			for phase in [2,3]:
				e.hp=e.max_hp*(.5 if phase==2 else .25);e.visual.phase_index=phase;e.visual._sample("idle",0)
				await shot("singularity-phase-%d"%phase)
		paused=false
	w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	var picker: OptionButton=studio.find_children("*","OptionButton",true,false)[0]
	for i in range(5):
		picker.select(8+i);picker.item_selected.emit(8+i)
		studio.set_view(0);studio.scrub(0)
		await shot("%s-inspection"%Catalog.ASSET_IDS[i])
		if i==0:
			studio.select_clip(studio.clips.find("tell_slam"))
			for j in range(9):studio.scrub(j/8.0);await shot("buffer-windup-%02d"%j)
	studio.queue_free();await frames()
	var arena=Arena.new();root.add_child(arena);await frames()
	await shot("boss-rehearsal")
	arena.queue_free();await frames()
	print("BOSS_VISUAL: %d failures"%failures)
	quit(1 if failures else 0)
