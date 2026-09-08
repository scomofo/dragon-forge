extends SceneTree
## Scripted actual-engine review of Forge Trials and multi-enemy role presentation.
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
var failures=0
const OUT="res://artifacts/trials/captures"
func _initialize():root.size=Vector2i(1280,720);call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func shot(label:String):
	await frames(3);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1
	print("TRIAL_CAPTURE "+label)
func ready_campaign()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm","stone"];c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.loadout=["fire","stone"];c.active_guardian="fire";c.evolutions={"fire":"flashfire","ice":"aegis","storm":"overcharge"}
	c.cleared=["outer-boss","frozen-boss","storm-boss","admin-boss"];c.cores=["outer","frozen","storm","admin"];c.installed=c.cores.duplicate();c.room="forge";return c
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w=World.new();w.test_mode=true;root.add_child(w);await frames(5)
	w.title_open=false;w.hud.close_overlay();w.campaign=ready_campaign();w._enter_room("forge",true);await frames(5)
	w.dragon.position=Vector3(-6.5,.1,-4.5);w.camera_rig.global_position=w.dragon.global_position
	await shot("01-forge-trials-station")
	w.hud.show_trials();await shot("02-trials-menu");w.hud.close_overlay()
	w.start_forge_trial("storm-overclock");await frames(8);await shot("03-skirmisher-wave")
	for foe in w.enemies.duplicate():foe.take_hit(9999,true)
	await frames(8);await shot("04-two-skirmishers")
	w.leave_trial();await frames(8);w.start_forge_trial("admin-control");await frames(8)
	for foe in w.enemies.duplicate():foe.take_hit(9999,true)
	await frames(8);await shot("05-controller-crossfire")
	w.leave_trial();await frames(5);w.queue_free();await frames()
	print("TRIAL_VISUAL: %d failures"%failures);quit(1 if failures else 0)
