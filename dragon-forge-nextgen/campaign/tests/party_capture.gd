extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Studio=preload("res://validation/character_inspection.gd")
var failures=0
var w
const OUT="res://artifacts/guardians"
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("run")
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func shot(name_text: String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	if image.save_png(OUT+"/"+name_text+".png")!=OK:failures+=1
	print("GUARDIAN_CAPTURE "+name_text)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.hud.show_title();await shot("01-title")
	w.hud.close_overlay();w.title_open=false;Rules.hatch(w.campaign)
	# Seed prerequisites only to inspect the recruitment feature, not a claimed playthrough.
	w.campaign.cleared=["outer-boss","frozen-guardian"]
	w.campaign.cores=["outer"];w.campaign.installed=["outer"]
	w.campaign.visited.append("frozen-vault");w.campaign.room="frozen-vault"
	w._enter_room("frozen-vault",true);await frames()
	w.dragon.position=Vector3(4,.1,0);w.camera_rig.position=w.dragon.position
	await shot("02-frozen-egg")
	w.dragon.position=Vector3(6,.1,-4);w.dragon.input_grace=0;w.interact()
	await shot("03-rescue")
	w.hud.close_overlay();w.return_to_forge();await frames()
	w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0;w.interact()
	await shot("04-collection")
	w.hud.close_overlay();w.dragon.input_grace=0;w.swap_guardian("ice")
	await shot("05-rime-forge")
	w.campaign.room="mute-channel";w.campaign.visited.append("mute-channel");w._enter_room("mute-channel",true)
	await frames();w.dragon.position=Vector3(0,.1,-2);w.camera_rig.position=w.dragon.position
	w.dragon.input_grace=0;w.dragon.mouse_aim=false;w.dragon.aim=Vector3.FORWARD
	w.enemy.position=Vector3(0,.1,-6);w.enemy.set_physics_process(false)
	w.dragon.try_ability("breath");w.dragon.advance_combat(.29);w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true
	await shot("06-rime-lance")
	paused=false;w.dragon.advance_combat(.6);w.dragon.state.heat=0;w.dragon.try_ability("burst");w.dragon.advance_combat(.21)
	paused=true;await shot("07-crystal-aegis")
	paused=false;w.dragon.advance_combat(.6);w.dragon.input_grace=0;w.party.swap_remaining=0;w.swap_guardian("fire")
	w.dragon.position=Vector3(0,.1,-4);w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD
	w.enemy.chilled=3;w.dragon.try_ability("claw");w.dragon.advance_combat(.11)
	paused=true;await shot("08-fire-shatter")
	paused=false;w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	studio.load_actor(3);studio.set_view(0);studio.scrub(0.0)
	await shot("09-rime-inspection")
	studio.set_view(3);studio.select_clip(studio.clips.find("breath"));studio.scrub(.28)
	await shot("10-rime-jaw")
	studio.set_view(0);studio.select_clip(studio.clips.find("walk"))
	for i in range(12):
		studio.scrub(float(i)/12.0*.8)
		await shot("rime-walk-%02d"%i)
	studio.queue_free();await frames()
	print("GUARDIAN_VISUAL: %d failures" % failures)
	quit(1 if failures else 0)
