extends SceneTree
## Prepared-state visual review using the actual campaign, not an unassisted playthrough.
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Enemy=preload("res://campaign/enemy.gd")
var failures=0
const OUT="res://artifacts/venom/captures"
func _initialize():root.size=Vector2i(1280,720);call_deferred("run")
func frames(n=4):
	for i in range(n):await process_frame
func shot(label):await frames(3);await RenderingServer.frame_post_draw;if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1;print("VENOM_CAPTURE "+label)
func ready()->Dictionary:
	var c=Rules.fresh();Rules.hatch(c);c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.venom_culture_recovered=true;c.venom_forged=true;c.guardians=["fire","ice","storm","stone","venom"];c.loadout=["fire","venom"];c.evolutions={"fire":"flashfire","ice":"aegis","storm":""};c.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate();c.visited.append_array(["field-locker","signal-approach","firewall-span","overflow-vent","cold-archive","mute-channel","thaw-junction","memory-vault","frozen-vault","overclock-gantry","live-wire","wire-fork","logic-core","capacitor-cache","mirror-vestibule","recursive-gate","cold-lanterns","admin-vault"]);c.room="forge";return c
func run():
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));var w=World.new();w.test_mode=true;root.add_child(w);await frames(5);w.title_open=false;w.hud.close_overlay();w.campaign=ready();w._enter_room("forge",true);await frames(5)
	w.hud.show_fusion();await shot("01-venom-recipe");w.hud.close_overlay();w.hud.show_party();await shot("02-five-guardian-roster");w.hud.close_overlay();w.party.rebuild(w.campaign);w.party.active_id="venom";w.dragon.use_guardian("venom",w.party.states.venom);w.dragon.position=Vector3(0,.1,2);w.dragon.aim=Vector3.FORWARD;await shot("03-nox-frilled-wyrm")
	var foe=Enemy.new();foe.spec={"id":"venom-capture","name":"Training Sentinel","hp":900.0,"damage":10.0,"shield":false,"boss":false,"patterns":["slam"],"archetype":"bruiser"};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy();w.dragon.input_grace=0
	w.dragon.try_ability("wall");w.dragon.advance_combat(.23);foe.position=w.walls[-1].at;w._tick_walls(.1);await shot("04-toxic-cloud");w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;foe.toxin=3;foe.toxin_time=5;w.dragon.try_ability("burst");w.dragon.advance_combat(.31);paused=true;await shot("05-septic-bloom");paused=false
	w.queue_free();await frames(4);print("VENOM_VISUAL: %d failures"%failures);quit(1 if failures else 0)
