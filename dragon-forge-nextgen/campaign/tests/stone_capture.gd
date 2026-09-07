extends SceneTree
## Scripted Cairn checkpoints using actual campaign and inspection scenes; not an unassisted playthrough.
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Studio=preload("res://validation/character_inspection.gd")
const Enemy=preload("res://campaign/enemy.gd")
var failures=0
const OUT="res://artifacts/stone/captures"
func _initialize(): root.size=Vector2i(1280,720);call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func shot(label):
	await frames(3);await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1
	print("STONE_CAPTURE "+label)
func eligible()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c)
	c.guardians=["fire","ice","storm"];c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.loadout=["fire","storm"];c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
	c.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate()
	c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"])
	c.room="admin-vault";return c
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	w.title_open=false;w.hud.close_overlay();w.campaign=eligible();w._enter_room("admin-vault",true);await frames()
	w.dragon.position=Vector3(5,.1,-2.5);w.camera_rig.position=w.dragon.position
	await shot("01-stone-imprint")
	Fusion.recover_stone(w.campaign);w.hud.show_stone_recovered();await shot("02-imprint-recovered")
	w.hud.close_overlay();w.campaign.room="forge";w._enter_room("forge",true);await frames();w.hud.show_fusion();await shot("03-resonance-recipes")
	w.hud.close_overlay();Fusion.forge_stone(w.campaign);Fusion.hatch_stone(w.campaign);Fusion.equip_reserve(w.campaign,"stone");w.party.rebuild(w.campaign);w.party.active_id="stone";w.dragon.use_guardian("stone",w.party.states.stone)
	w.hud.show_party();await shot("04-cairn-party")
	w.hud.close_overlay();w.dragon.input_grace=0;w.dragon.aim=Vector3.FORWARD
	var foe=Enemy.new();foe.spec={"id":"capture","name":"Training Sentinel","hp":800.0,"damage":10.0,"shield":false,"boss":false,"patterns":["slam"]};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy()
	w.dragon.state.resolve=3;w.dragon.try_ability("burst");w.dragon.advance_combat(.39);w.dragon.rig.animate(0,0,false,w.dragon.state);paused=true;await shot("05-earthshatter");paused=false
	w.queue_free();await frames()
	var studio=Studio.new();root.add_child(studio);await frames();studio.load_actor(8);studio.set_view(0);studio.select_clip(studio.clips.find("guard"));studio.scrub(.35);await shot("06-cairn-inspection");studio.queue_free();await frames()
	print("STONE_VISUAL: %d failures"%failures);quit(1 if failures else 0)
