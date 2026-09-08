extends SceneTree
## Scripted art/menu checkpoints; not an unassisted campaign playthrough.
const World=preload("res://campaign/world.gd")
const Fixture=preload("res://campaign/tests/tempest_tests.gd")
const Director=preload("res://campaign/audio/director.gd")
const Studio=preload("res://validation/character_inspection.gd")
var failures=0
const OUT="res://artifacts/tempest/captures"
func _initialize() -> void:
	root.size=Vector2i(1280,720);call_deferred("run")
func frames(n: int=4) -> void:
	for i in range(n):await process_frame
func shot(label: String) -> void:
	await frames(3);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1
	print("TEMPEST_CAPTURE "+label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	var a=Director.new();a.test_mode=true;a.source=w;w.audio=a;w.add_child(a)
	w.hud.show_title();await shot("01-title")
	w.hud.show_audio();await shot("02-audio-settings")
	w.hud._leave_audio();w.hud.close_overlay();w.title_open=false
	w.campaign=Fixture.eligible();w.campaign.loadout=["fire","storm"]
	w._enter_room("forge",true);await frames()
	w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0
	w.hud.show_growth("storm");await shot("03-tempest-choices")
	w.choose_evolution("storm","thunderhead");await shot("04-evolved")
	w.hud.show_party();await shot("05-party")
	w.hud.close_overlay();w.dragon.input_grace=0;w.swap_guardian("storm")
	w.campaign.room="live-wire";w.campaign.visited.append("live-wire")
	w._enter_room("live-wire",true);await frames()
	w.dragon.position=Vector3(0,.1,-2);w.camera_rig.position=w.dragon.position
	w.dragon.input_grace=0;w.dragon.mouse_aim=false;w.dragon.aim=Vector3.FORWARD
	w.enemy.position=Vector3(0,.1,-6);w.enemy.set_physics_process(false);w.enemy.brain.open_window(5)
	w.dragon.try_ability("breath");w.dragon.advance_combat(.27);w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true;await shot("06-thunderhead-lance")
	paused=false;w.dragon.advance_combat(.6);w.dragon.state.heat=0;w.dragon.try_ability("burst");w.dragon.advance_combat(.35)
	w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true;await shot("07-discharge")
	paused=false;w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	var picker: OptionButton=studio.find_children("*","OptionButton",true,false)[0]
	picker.select(7);picker.item_selected.emit(7)
	studio.set_view(0);studio.scrub(0);await shot("08-tempest-inspection")
	studio.set_view(3);studio.select_clip(studio.clips.find("breath"));studio.scrub(.26);await shot("09-tempest-jaw")
	studio.set_view(0);studio.select_clip(studio.clips.find("guard"));studio.scrub(.4);await shot("10-tempest-guard")
	studio.queue_free();await frames()
	print("TEMPEST_VISUAL: %d failures"%failures);quit(1 if failures else 0)
