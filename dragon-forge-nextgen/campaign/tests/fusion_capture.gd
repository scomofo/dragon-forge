extends SceneTree
## Scripted visual checkpoints, not an unassisted playthrough or performance benchmark.
const World=preload("res://campaign/world.gd")
const Fixtures=preload("res://campaign/tests/fusion_tests.gd")
const Studio=preload("res://validation/character_inspection.gd")
const Fusion=preload("res://campaign/fusion.gd")
var failures=0
var w
const OUT="res://artifacts/fusion/captures"
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("run")
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func shot(label: String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1
	print("FUSION_CAPTURE "+label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.hud.show_title();await shot("01-title")
	w.hud.close_overlay();w.title_open=false
	w.campaign=Fixtures.eligible();w.campaign.room="capacitor-cache";w._enter_room(w.campaign.room,true);await frames()
	w.dragon.position=Vector3(3,.1,0);w.camera_rig.position=w.dragon.position
	await shot("02-lattice")
	w.dragon.position=Fusion.LATTICE+Vector3.UP*.1;w.dragon.input_grace=0;w.interact()
	await shot("03-recovered")
	w.hud.close_overlay();w.return_to_forge();await frames()
	w.dragon.position=Fusion.STATION+Vector3.UP*.1;w.camera_rig.position=w.dragon.position;w.dragon.input_grace=0
	w.interact();await shot("04-fusion-preview")
	w.forge_storm();await shot("05-storm-egg")
	w.hatch_storm();await shot("06-hatched")
	w.hud.close_overlay();w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	w.equip_reserve("storm");await shot("07-expedition-pair")
	w.hud.close_overlay();w.dragon.input_grace=0;w.swap_guardian("storm")
	w.campaign.room="live-wire";w.campaign.visited.append("live-wire");w._enter_room(w.campaign.room,true);await frames()
	w.dragon.position=Vector3(0,.1,-2);w.camera_rig.position=w.dragon.position
	w.dragon.input_grace=0;w.dragon.mouse_aim=false;w.dragon.aim=Vector3.FORWARD
	w.enemy.position=Vector3(0,.1,-6);w.enemy.set_physics_process(false)
	w.dragon.try_ability("breath");w.dragon.advance_combat(.27);w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true;await shot("08-arc-lance")
	paused=false;w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.try_ability("burst");w.dragon.advance_combat(.35)
	w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true;await shot("09-tempest")
	paused=false;w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	var picker: OptionButton=studio.find_children("*","OptionButton",true,false)[0]
	picker.select(6);picker.item_selected.emit(6)
	studio.set_view(0);studio.scrub(0)
	await shot("10-arc-inspection")
	studio.set_view(3);studio.select_clip(studio.clips.find("breath"));studio.scrub(.26)
	await shot("11-arc-jaw")
	studio.set_view(0);studio.select_clip(studio.clips.find("idle"))
	for i in range(12):
		studio.scrub(i*1.8/12.0)
		await shot("hover-%02d"%i)
	studio.queue_free();await frames()
	print("FUSION_VISUAL: %d failures"%failures)
	quit(1 if failures else 0)
