extends SceneTree
## Authored review setups, not an unassisted campaign playthrough.
const World = preload("res://campaign/world.gd")
const Fixtures = preload("res://campaign/tests/evolution_tests.gd")
const Studio = preload("res://validation/character_inspection.gd")
var failures = 0
var w
const OUT = "res://artifacts/evolution/captures"
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("run")
func frames(n: int=4) -> void:
	for i in range(n): await process_frame
func shot(label: String) -> void:
	await frames(3)
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+label+".png") != OK:failures+=1
	print("EVOLUTION_CAPTURE "+label)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.hud.show_title();await shot("01-title")
	w.hud.close_overlay();w.title_open=false
	w.campaign=Fixtures.eligible();w._enter_room("forge",true);await frames()
	w.dragon.position=Vector3(6,.1,8);w.camera_rig.position=w.dragon.position;w.dragon.input_grace=0
	w.hud.show_growth("fire");await shot("02-evolution-choice")
	w.choose_evolution("fire","flashfire");await shot("03-crowned-result")
	w.hud.close_overlay();w.dragon.input_grace=0
	await shot("04-crowned-gameplay")
	w.choose_evolution("ice","aegis");w.hud.close_overlay();w.dragon.input_grace=0;w.party.swap_remaining=0;w.swap_guardian("ice")
	await shot("05-aurora-gameplay")
	w.hud.show_growth("ice");await shot("06-rime-specializations")
	w.hud.show_party();await shot("07-party")
	w.hud.close_overlay();w.campaign.room="live-wire";w.campaign.visited.append("live-wire");w._enter_room("live-wire",true);await frames()
	w.dragon.position=Vector3(0,.1,-2);w.camera_rig.position=w.dragon.position
	w.dragon.input_grace=0;w.dragon.mouse_aim=false;w.dragon.aim=Vector3.FORWARD
	w.enemy.position=Vector3(0,.1,-5);w.enemy.set_physics_process(false)
	w.dragon.try_ability("breath");w.dragon.advance_combat(.29);w.dragon.rig.animate(0,0,false,w.dragon.state)
	paused=true;await shot("08-aurora-combat")
	paused=false;w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames()
	var picker: OptionButton=studio.find_children("*","OptionButton",true,false)[0]
	for index in [0,4,3,5]:
		picker.select(index);picker.item_selected.emit(index)
		studio.set_view(0);studio.scrub(0)
		await shot({0:"09-magma-young",4:"10-magma-evolved",3:"11-rime-young",5:"12-rime-evolved"}[index])
		if index==4:
			studio.set_view(1);studio.select_clip(studio.clips.find("guard"));studio.scrub(.5);studio.set_material(2)
			await shot("13-crowned-guard-clay")
			studio.set_material(0)
		if index==5:
			studio.set_view(3);studio.select_clip(studio.clips.find("breath"));studio.scrub(.28)
			await shot("14-aurora-jaw")
	studio.queue_free();await frames()
	print("EVOLUTION_VISUAL: %d failures" % failures)
	quit(1 if failures else 0)
