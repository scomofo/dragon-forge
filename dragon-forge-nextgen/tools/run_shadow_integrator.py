#!/usr/bin/env python3
"""One-shot, exact-anchor source integration for Umbra/Shadow.
The temporary workflow removes this file after the generated assets and runtime are verified.
"""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def rep(rel,old,new):
    p=ROOT/rel;text=p.read_text();count=text.count(old)
    assert count==1,f'{rel}: expected one anchor, got {count}: {old[:100]!r}'
    p.write_text(text.replace(old,new,1))

def write(rel,text):
    p=ROOT/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text)

write('campaign/shadow_rig.gd','''extends Node3D
## Umbra is a distinct imported negative-space wolf. Animation sampling is presentation-only.
const Scene = preload("res://campaign/shadow/shadow_guardian.glb")
const Art = preload("res://presentation/art_library.gd")
var model:Node3D
var skeleton:Skeleton3D
var player:AnimationPlayer
var clock=0.0
var hurt_time=0.0
var death_time=0.0
var sampled_clip="idle"
var sampled_time=0.0
func _ready()->void:
\tmodel=Scene.instantiate();add_child(model)
\tskeleton=model.find_child("Skeleton3D",true,false);player=model.find_child("AnimationPlayer",true,false)
\tplayer.process_mode=Node.PROCESS_MODE_DISABLED;reset_pose()
func reset_pose()->void:
\tclock=0.0;hurt_time=0.0;death_time=0.0
\tif is_instance_valid(player):Art.sample(player,"idle",0.0)
func hurt(guarded:bool)->void:hurt_time=.05 if guarded else .22
func animate(delta:float,speed:float,reduced:bool,state:Dictionary)->void:
\tvar dt=maxf(0.0,delta) if is_finite(delta) else 0.0
\tclock+=dt;hurt_time=maxf(0.0,hurt_time-dt);sampled_clip="idle";sampled_time=0.0 if reduced else fposmod(clock,1.6)
\tif state.hp<=0.0:death_time=minf(.78,death_time+dt);sampled_clip="defeat";sampled_time=death_time
\telif state.action!="":sampled_clip=state.action;sampled_time=state.action_time
\telif state.guard:sampled_clip="guard";sampled_time=.40
\telif hurt_time>0.0:sampled_clip="hurt";sampled_time=.22-hurt_time
\telif speed>.15:sampled_clip="walk";sampled_time=0.0 if reduced else fposmod(clock,.76)
\tArt.sample(player,sampled_clip,sampled_time)
func muzzle_position()->Vector3:
\treturn skeleton.global_transform*(skeleton.get_bone_global_pose(skeleton.find_bone("Head"))*Vector3(0,-.03,-.60))
''')
rep('campaign/dragon.gd','const VenomRig = preload("res://campaign/venom_rig.gd")\n','const VenomRig = preload("res://campaign/venom_rig.gd")\nconst ShadowRig = preload("res://campaign/shadow_rig.gd")\n')
rep('campaign/dragon.gd','if not id in ["fire","ice","storm","stone","venom"]:','if not id in ["fire","ice","storm","stone","venom","shadow"]:')
rep('campaign/dragon.gd','\t\tif id == "venom":\n\t\t\tnext = VenomRig.new()\n\t\telif id == "stone":','\t\tif id == "shadow":\n\t\t\tnext = ShadowRig.new()\n\t\telif id == "venom":\n\t\t\tnext = VenomRig.new()\n\t\telif id == "stone":')
rep('campaign/dragon.gd','\tguard_ring.visible = false\n\nfunc advance_combat','\tguard_ring.visible = false\n\nfunc receive_damage(amount: float) -> float:\n\tvar phase_before=int(state.get("phase",0))\n\tvar applied=super.receive_damage(amount)\n\tif guardian=="shadow" and int(state.get("phase",0))>phase_before:\n\t\thint.emit("PHASE %d / %d  •  Phase Strike stores the opening" % [int(state.phase),GuardianCombat.MAX_PHASE])\n\treturn applied\n\nfunc advance_combat')
rep('campaign/growth.gd','static func form_name(guardian: String, evolved: bool) -> String:\n\tif guardian == "venom": return "Nox"','static func form_name(guardian: String, evolved: bool) -> String:\n\tif guardian == "shadow": return "Umbra"\n\tif guardian == "venom": return "Nox"')
rep('campaign/audio/synth.gd','{"fire":.78,"ice":1.55,"storm":1.08,"stone":.58,"venom":.90}.get(guardian,1.0)','{"fire":.78,"ice":1.55,"storm":1.08,"stone":.58,"venom":.90,"shadow":.70}.get(guardian,1.0)')
rep('campaign/world.gd','\t\telif owner_id=="stone": _place_bulwark(origin,direction)\n\t\telse: _place_venom(origin,direction)','\t\telif owner_id=="stone": _place_bulwark(origin,direction)\n\t\telif owner_id=="shadow": _place_shadow(origin,direction)\n\t\telse: _place_venom(origin,direction)')
rep('campaign/world.gd','\tif owner_id=="stone" and id=="burst" and landed:\n\t\tvar spent=GuardianCombat.consume_resolve(dragon.state)\n\t\tif spent>0:hud.feedback("EARTHSHATTER / RESOLVE %d" % spent,"Guard landed hits to rebuild Resolve.")\n','\tif owner_id=="stone" and id=="burst" and landed:\n\t\tvar spent=GuardianCombat.consume_resolve(dragon.state)\n\t\tif spent>0:hud.feedback("EARTHSHATTER / RESOLVE %d" % spent,"Guard landed hits to rebuild Resolve.")\n\tif owner_id=="shadow" and id=="burst" and landed:\n\t\tvar spent_phase=GuardianCombat.consume_phase(dragon.state)\n\t\tif spent_phase>0:hud.feedback("PHASE STRIKE / PHASE %d" % spent_phase,"Dodge through real incoming hits to rebuild Phase.")\n')
rep('campaign/world.gd','\tif owner_id=="venom":\n\t\t_venom_contact(id,origin,direction,rule.range)\n\tif owner_id=="ice":','\tif owner_id=="venom":\n\t\t_venom_contact(id,origin,direction,rule.range)\n\tif owner_id=="shadow":\n\t\t_shadow_contact(id,origin,direction,rule.range)\n\t\tif id=="breath" and not conduits.is_empty():\n\t\t\thud.toast("Thermal relays need Magma. Void Pulse cannot power the conductor.")\n\t\t\treturn\n\tif owner_id=="ice":')
rep('campaign/world.gd','hud.feedback(GuardianCombat.guardian_name(target)+" TAKES POINT", {"ice":"Chill, then swap to Magma to shatter.", "fire":"Fire shatters chilled enemies on a direct hit.", "storm":"Charge with Arc Lance or Static Well. Discharge with technique 4.", "stone":"Guard landed hits to build Resolve, then Earthshatter [4]."}.get(target, ""))','hud.feedback(GuardianCombat.guardian_name(target)+" TAKES POINT", {"ice":"Chill, then swap to Magma to shatter.", "fire":"Fire shatters chilled enemies on a direct hit.", "storm":"Charge with Arc Lance or Static Well. Discharge with technique 4.", "stone":"Guard landed hits to build Resolve, then Earthshatter [4].", "venom":"Build Toxin, then cash it out with Septic Bloom [4].", "shadow":"Dodge through real hits to build Phase, then land Phase Strike [4]."}.get(target, ""))')
rep('campaign/world.gd','func hatch_venom() -> bool:\n\tif not can_fuse() or not Fusion.hatch_venom(campaign):return false\n\tsound("hatch","venom",3,true);_save();hud.show_fusion();return true\n\nfunc equip_reserve','func hatch_venom() -> bool:\n\tif not can_fuse() or not Fusion.hatch_venom(campaign):return false\n\tsound("hatch","venom",3,true);_save();hud.show_fusion();return true\n\nfunc forge_shadow() -> bool:\n\tif not can_fuse() or not Fusion.forge_shadow(campaign):return false\n\tsound("fusion","shadow",3,true);_save();hud.show_fusion();return true\n\nfunc hatch_shadow() -> bool:\n\tif not can_fuse() or not Fusion.hatch_shadow(campaign):return false\n\tsound("hatch","shadow",3,true);_save();hud.show_fusion();return true\n\nfunc equip_reserve')
rep('campaign/world.gd','func _stone_contact(id:String,origin:Vector3,direction:Vector3,reach:float)->void:','''func _place_shadow(origin:Vector3,direction:Vector3)->void:
\tvar at=origin+direction*4.0
\tvar hit=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin+Vector3.UP,at+Vector3.UP,1))
\tif not hit.is_empty():at=hit.position-direction*.6
\tat.y=0.0
\tvar marker=effects.decal(at,2.4,Color("2a2138"))
\tvar violet=Geo.material(Color("9b72d3"),.55,true)
\tfor i in [0,1,3,4,6,7]:
\t\tvar a=TAU*float(i)/8.0;Geo.orb(marker,Vector3(sin(a)*1.85,.09,cos(a)*1.85),.11,violet)
\twalls.append({"at":at,"ttl":3.6,"tick":0.0,"damage":campaign_damage("wall"),"guardian":"shadow","node":marker})

func _shadow_contact(id:String,origin:Vector3,direction:Vector3,reach:float)->void:
\tif id=="burst":effects.pulse(origin,reach,Color("9d70dc"));return
\tvar node=Node3D.new();add_child(node);effects._reserve(node);var mat=Geo.material(Color("9c72db"),.70,true)
\tvar count=4 if id=="claw" else 12
\tfor i in range(count):
\t\tvar d=.9+i*.50
\t\tif d>reach or not line_clear(origin,origin+direction*d):break
\t\tif i%3==1:continue
\t\tvar side=direction.cross(Vector3.UP)*(.16 if i%2 else -.16)
\t\tGeo.orb(node,origin+direction*d+side+Vector3.UP*(.62+.03*(i%3)),.09,mat)
\tnode.create_tween().tween_interval(.25).finished.connect(node.queue_free)

func _stone_contact(id:String,origin:Vector3,direction:Vector3,reach:float)->void:''')
rep('campaign/hud.gd','\tif actor.state.get("ward",0.0)>0.0:\n\t\tdefensive_text.text="CRYSTAL AEGIS  /  %.1fs" % actor.state.ward\n','\tif active_id=="shadow":\n\t\tdefensive_text.text="PHASE %d / %d  /  DODGE THROUGH HITS" % [int(actor.state.get("phase",0)),GuardianCombat.MAX_PHASE]\n\telif actor.state.get("ward",0.0)>0.0:\n\t\tdefensive_text.text="CRYSTAL AEGIS  /  %.1fs" % actor.state.ward\n')
rep('campaign/hud.gd','\t\tif active_id=="venom":\n\t\t\tif id in ["claw","breath"]:card.cost.text="%d + TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n\t\t\telif id=="wall":card.cost.text="%d/tick + TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n\t\t\telif id=="burst":card.cost.text="%d / +25%% per TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n','\t\tif active_id=="venom":\n\t\t\tif id in ["claw","breath"]:card.cost.text="%d + TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n\t\t\telif id=="wall":card.cost.text="%d/tick + TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n\t\t\telif id=="burst":card.cost.text="%d / +25%% per TOXIN / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n\t\tif active_id=="shadow" and id=="burst":\n\t\t\tcard.cost.text="%d / +30%% per PHASE / %d heat" % [roundi(world.campaign_damage(id)),roundi(GuardianCombat.heat_cost(actor.state,id))]\n')
rep('campaign/hud.gd','"VENOM RESONANCE   /   22 ROOMS   /   FIVE GUARDIANS, TWO FIELD SLOTS"','"SHADOW RESONANCE   /   22 ROOMS   /   SIX GUARDIANS, TWO FIELD SLOTS"')
rep('campaign/hud.gd','for id in ["fire","ice","storm","stone","venom"]:','for id in ["fire","ice","storm","stone","venom","shadow"]:')
rep('campaign/hud.gd','{"fire":GOLD,"ice":TEAL,"storm":Color("c4b1fa"),"stone":Color("c8ad7c"),"venom":Color("a8db61")}[id]','{"fire":GOLD,"ice":TEAL,"storm":Color("c4b1fa"),"stone":Color("c8ad7c"),"venom":Color("a8db61"),"shadow":Color("b78be0")}[id]')
rep('campaign/hud.gd','"venom":"Fang, Spit and Cloud build Toxin. Septic Bloom gains +25% per stack and consumes stacks only when it lands."}','"venom":"Fang, Spit and Cloud build Toxin. Septic Bloom gains +25% per stack and consumes stacks only when it lands.","shadow":"A real incoming hit during dodge i-frames builds Phase (max 2). Phase Strike gains +30% per Phase and spends it only when damage lands."}')
rep('campaign/hud.gd','\t\t\telif id=="stone":\n\t\t\t\t_label(col,"Resolve %d / 3" % int((world.party.states[id].get("resolve",0) if selected else 0)),15,GOLD)\n','\t\t\telif id=="stone":\n\t\t\t\t_label(col,"Resolve %d / 3" % int((world.party.states[id].get("resolve",0) if selected else 0)),15,GOLD)\n\t\t\telif id=="shadow":\n\t\t\t\t_label(col,"Phase %d / 2" % int((world.party.states[id].get("phase",0) if selected else 0)),15,Color("b78be0"))\n')
rep('campaign/hud.gd','\t\telse:\n\t\t\t_wrapped(col,"Rescue Rime, then recover the preserved Venom culture from Frozen Vault. Canonical Ice + Venom remains Venom; Rime is retained.",17,PAPER,272)\n\t\t\t_button(col,"View fusion recipes").pressed.connect(show_fusion)\n','\t\telif id=="venom":\n\t\t\t_wrapped(col,"Rescue Rime, then recover the preserved Venom culture from Frozen Vault. Canonical Ice + Venom remains Venom; Rime is retained.",17,PAPER,272)\n\t\t\t_button(col,"View fusion recipes").pressed.connect(show_fusion)\n\t\telse:\n\t\t\t_wrapped(col,"Awaken Nox, then combine Magma + Nox at Resonance Fusion. Canonical Fire + Venom creates Shadow; both parents are retained.",17,PAPER,272)\n\t\t\t_button(col,"View fusion recipes").pressed.connect(show_fusion)\n')
rep('campaign/hud.gd','The Forge now holds three explicit, non-destructive resonance recipes.','The Forge now holds four explicit, non-destructive resonance recipes.')
rep('campaign/hud.gd','\t_wrapped(overlay_column,"NOX / Toxin Fang • Acid Spit • Toxic Cloud • Septic Bloom\\nBuild up to 3 Toxin stacks. Existing Toxin ticks after shields re-close; Bloom gains +25% per stack and consumes them only when the Bloom lands.",17,MUTED)\n\tif world.store.message!="":','\t_wrapped(overlay_column,"NOX / Toxin Fang • Acid Spit • Toxic Cloud • Septic Bloom\\nBuild up to 3 Toxin stacks. Existing Toxin ticks after shields re-close; Bloom gains +25% per stack and consumes them only when the Bloom lands.",17,MUTED)\n\t_label(overlay_column,"FIRE + VENOM = SHADOW / UMBRA",22,Color("b78be0"))\n\tif c.guardians.has("shadow"):\n\t\t_label(overlay_column,"UMBRA / RECRUITED",18,TEAL)\n\telif c.shadow_forged:\n\t\tvar hatch4=_button(overlay_column,"Awaken Umbra / free");hatch4.disabled=not world.can_fuse();hatch4.pressed.connect(func():world.hatch_shadow())\n\telse:\n\t\t_wrapped(overlay_column,Fusion.shadow_reason(c) if Fusion.shadow_reason(c)!="" else "READY / Magma + Nox. Canonical Fire + Venom creates Shadow; both parents remain.",16,GOLD)\n\t\tvar forge4=_button(overlay_column,"Create Shadow resonance / keep Magma + Nox");forge4.disabled=Fusion.shadow_reason(c)!="" or not world.can_fuse();forge4.pressed.connect(func():world.forge_shadow())\n\t_wrapped(overlay_column,"UMBRA / Shadow Strike • Void Pulse • Umbral Wake • Phase Strike\\nDodge through real incoming hits to build Phase (max 2). Phase Strike gains +30% per Phase and spends it only when damage lands; a closed shield preserves Phase.",17,MUTED)\n\tif world.store.message!="":')
rep('validation/character_inspection.gd','"stone_guardian", "venom_guardian", "buffer_overflow"','"stone_guardian", "venom_guardian", "shadow_guardian", "buffer_overflow"')
rep('validation/character_inspection.gd','UI.picker(box, ["Magma guardian", "Firewall Sentinel", "Packet Warden", "Rime / Ice guardian", "Crowned Magma / Evolved", "Aurora Rime / Evolved", "Arc / Storm fusion", "Tempest Arc / Evolved", "Cairn / Stone guardian", "Buffer Overflow / Boss", "Memory Leak / Boss", "Stack Overflow / Boss", "Mirror Admin / Boss", "Singularity / Final"], load_actor)','UI.picker(box, ["Magma guardian", "Firewall Sentinel", "Packet Warden", "Rime / Ice guardian", "Crowned Magma / Evolved", "Aurora Rime / Evolved", "Arc / Storm fusion", "Tempest Arc / Evolved", "Cairn / Stone guardian", "Nox / Venom guardian", "Umbra / Shadow guardian", "Buffer Overflow / Boss", "Memory Leak / Boss", "Stack Overflow / Boss", "Mirror Admin / Boss", "Singularity / Final"], load_actor)')
rep('validation/character_inspection.gd','\telif actor_id == "venom_guardian":\n\t\tmodel = load("res://campaign/venom/venom_guardian.glb").instantiate();add_child(model)\n\telse:','\telif actor_id == "venom_guardian":\n\t\tmodel = load("res://campaign/venom/venom_guardian.glb").instantiate();add_child(model)\n\telif actor_id == "shadow_guardian":\n\t\tmodel = load("res://campaign/shadow/shadow_guardian.glb").instantiate();add_child(model)\n\telse:')
rep('validation/character_inspection.gd','\tif actor_id=="venom_guardian":\n\t\tfocus=[Vector3(0,.9,.25),Vector3(0,1.18,-.55),Vector3(0,.35,.3),Vector3(0,1.35,-1.05),Vector3(0,.8,1.0)][index]\n','\tif actor_id=="venom_guardian":\n\t\tfocus=[Vector3(0,.9,.25),Vector3(0,1.18,-.55),Vector3(0,.35,.3),Vector3(0,1.35,-1.05),Vector3(0,.8,1.0)][index]\n\tif actor_id=="shadow_guardian":\n\t\tfocus=[Vector3(0,1.0,.22),Vector3(0,1.45,-.80),Vector3(0,.35,.20),Vector3(0,1.55,-1.18),Vector3(0,.82,1.05)][index]\n')
rep('validation/foot_review.gd','\tif id in ["storm_guardian","tempest_arc"]:\n\t\terror = "Arc hovers above the deck.\\nNo planted-foot contract applies."\n\t\treturn false\n','\tif id in ["storm_guardian","tempest_arc"]:\n\t\terror = "Arc hovers above the deck.\\nNo planted-foot contract applies."\n\t\treturn false\n\tif id=="shadow_guardian":\n\t\terror = "Umbra uses grounded collision but no planted-foot solver.\\nNo planted-foot contract applies to this first-pass rig."\n\t\treturn false\n')
rep('release/export_smoke.gd','\ts.venom_culture_recovered = true\n\ts.venom_forged = true\n\ts.guardians = ["fire","ice","storm","stone","venom"]','\ts.venom_culture_recovered = true\n\ts.venom_forged = true\n\ts.shadow_forged = true\n\ts.guardians = ["fire","ice","storm","stone","venom","shadow"]')
rep('release/export_smoke.gd','info.get("assets",[]).size() == 63, "pack build identity and 63 art/audio resources present"','info.get("assets",[]).size() == 68, "pack build identity and 68 art/audio resources present"')
rep('release/export_smoke.gd','for pair in [["fire","ice"],["fire","storm"],["fire","stone"],["fire","venom"]]:','for pair in [["fire","ice"],["fire","storm"],["fire","stone"],["fire","venom"],["fire","shadow"]]:')
rep('release/export_smoke.gd','\told.erase("venom_forged")\n','\told.erase("venom_forged")\n\told.erase("shadow_forged")\n')
rep('release/export_smoke.gd','loaded.version == 8 and not loaded.stone_imprint_recovered and not loaded.stone_forged and not loaded.venom_culture_recovered and not loaded.venom_forged, "schema-5 campaign migrates through Shadow to schema 8 in export"','loaded.version == 8 and not loaded.stone_imprint_recovered and not loaded.stone_forged and not loaded.venom_culture_recovered and not loaded.venom_forged and not loaded.shadow_forged, "schema-5 campaign migrates through Shadow to schema 8 with no unearned roster progress"')
rep('tools/test_bosses.sh','campaign/tests/shadow_tests.gd campaign/tests/trial_tests.gd','campaign/tests/shadow_tests.gd campaign/tests/shadow_runtime_tests.gd campaign/tests/trial_tests.gd')
rep('campaign/tests/fusion_tests.gd','check(actor_picker.item_count==14,"all fourteen actual actors appear in the inspection picker")','check(actor_picker.item_count==16,"all sixteen actual actors appear in the inspection picker")')
rep('campaign/tests/boss_tests.gd','\t\t# Nox occupies inspector slot 9; bosses now begin at slot 10.\n\t\tstudio.load_actor(10+i)','\t\t# Nox and Umbra occupy inspector slots 9 and 10; bosses begin at slot 11.\n\t\tstudio.load_actor(11+i)')
rep('tools/release/build.py',"if len(assets)!=63: raise SystemExit('Expected 29 models, 24 maps and 10 recordings; review inventory before changing this gate.')","if len(assets)!=68: raise SystemExit('Expected 30 models, 28 maps and 10 recordings; review inventory before changing this gate.')")
rep('tools/release/build.py',"'DRAGON FORGE - RECONNECTION / VENOM RESONANCE\\n'","'DRAGON FORGE - RECONNECTION / SHADOW RESONANCE\\n'")
rep('release/README.md','These exports contain the complete Reconnection campaign with Nox / Venom Resonance,\nCairn / Stone Resonance, Forge Trials, Boss Identities, Tempest, the existing soundtrack,','These exports contain the complete Reconnection campaign with Umbra / Shadow Resonance,\nNox / Venom Resonance, Cairn / Stone Resonance, Forge Trials, Boss Identities, Tempest, the existing soundtrack,')
rep('release/README.md','progress uses save schema 7 and retains the existing custom userdata directory.','progress uses save schema 8 and retains the existing custom userdata directory.')
rep('release/README.md','The title reads **VENOM RESONANCE**. Nox is the fifth owned guardian; expeditions','The title reads **SHADOW RESONANCE**. Umbra is the sixth owned guardian; expeditions')
rep('release/README.md','dynamically loaded boss models, guardian variants, Cairn, Nox and the soundtrack;','dynamically loaded boss models, guardian variants, Cairn, Nox, Umbra and the soundtrack;')
rep('release/README.md','Package integrity, executable format, default campaign startup, all **63** models/maps/\nrecordings loadable from the exported pack, all 22 rooms, five imported bosses,\nFire/Ice/Storm/Stone/Venom guardian swaps, runtime audio decoding, schema-5-to-7','Package integrity, executable format, default campaign startup, all **68** models/maps/\nrecordings loadable from the exported pack, all 22 rooms, five imported bosses,\nFire/Ice/Storm/Stone/Venom/Shadow guardian swaps, runtime audio decoding, schema-5-to-8')
rep('release/README.md','Nox is packed and swappable and exercises schema-5-to-7 migration without writing','Umbra is packed and swappable and exercises schema-5-to-8 migration without writing')
write('campaign/tests/shadow_runtime_tests.gd','''extends SceneTree
const Rules=preload("res://campaign/progress.gd")
const Fusion=preload("res://campaign/fusion.gd")
const Combat=preload("res://campaign/guardian_combat.gd")
const World=preload("res://campaign/world.gd")
const Enemy=preload("res://campaign/enemy.gd")
var checks=0
var failures=0
func _initialize():call_deferred("run")
func check(ok:bool,label:String):checks+=1;if not ok:failures+=1;print(("PASS " if ok else "FAIL ")+label)
func frames(n=3):
\tfor i in range(n):await physics_frame
func ready_nox()->Dictionary:
\tvar c=Rules.fresh();Rules.hatch(c);c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.venom_culture_recovered=true;c.venom_forged=true
\tc.guardians=["fire","ice","storm","stone","venom"];c.loadout=["fire","venom"];c.active_guardian="fire";c.evolutions={"fire":"flashfire","ice":"aegis","storm":""}
\tc.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate();c.room="forge";return c
func run():
\tvar scene=load("res://campaign/shadow/shadow_guardian.glb").instantiate();root.add_child(scene)
\tvar sk=scene.find_child("Skeleton3D",true,false);var ap=scene.find_child("AnimationPlayer",true,false)
\tcheck(sk!=null and sk.get_bone_count()==26,"Umbra imported negative-space skeleton has 26 bones")
\tfor clip in ["idle","walk","claw","breath","wall","burst","guard","hurt","defeat"]:check(ap.has_animation(clip),"Umbra imported clip "+clip)
\tscene.queue_free();await frames()
\tvar w=World.new();w.test_mode=true;root.add_child(w);await frames(5);w.title_open=false;w.hud.close_overlay();w.campaign=ready_nox();w._enter_room("forge",true);await frames(5);w.dragon.position=Fusion.STATION+Vector3(0,.1,0);w.dragon.input_grace=0
\tcheck(w.forge_shadow(),"real Forge creates Shadow resonance");check(w.hatch_shadow(),"real Forge awakens Umbra");check(w.campaign.guardians==["fire","ice","storm","stone","venom","shadow"],"world owns six ordered guardians")
\tw.hud.close_overlay();w.dragon.position=Vector3(6,.1,8);w.dragon.input_grace=0;check(w.equip_reserve("shadow"),"Nursery equips Umbra as reserve");w.hud.close_overlay();w.party.swap_remaining=0;w.dragon.input_grace=0;check(w.swap_guardian("shadow"),"world swaps to Umbra")
\tcheck(w.dragon.guardian=="shadow" and w.dragon.rig.skeleton.get_bone_count()==26 and w.dragon.rig.player.has_animation("burst"),"Umbra controller uses actual imported rig")
\tvar hp=w.dragon.state.hp;check(Combat.dodge(w.dragon.state),"Umbra begins authoritative dodge");check(w.dragon.receive_damage(22)==0 and w.dragon.state.hp==hp and w.dragon.state.phase==1,"real world incoming hit during i-frames earns Phase")
\tcheck(w.dragon.receive_damage(22)==0 and w.dragon.state.phase==2,"second real world hit reaches Phase cap")
\tw.dragon.advance_combat(.30);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0
\tvar foe=Enemy.new();foe.spec={"id":"shadow-runtime","name":"Phase Target","hp":900.0,"damage":10.0,"shield":true,"boss":false,"patterns":["slam"],"archetype":"bulwark"};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy();w.dragon.aim=Vector3.FORWARD
\tvar blocked_hp=foe.hp;check(w.dragon.try_ability("burst"),"Umbra begins shielded Phase Strike");w.dragon.advance_combat(.21);check(foe.hp==blocked_hp and w.dragon.state.phase==2,"closed shield blocks Phase Strike and preserves Phase")
\tw.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;foe.spec.shield=false;var open_hp=foe.hp
\tcheck(w.dragon.try_ability("burst"),"Umbra begins open Phase Strike");w.dragon.advance_combat(.21);check(w.dragon.state.phase==0 and open_hp-foe.hp>Combat.SHADOW.burst.damage,"landed Phase Strike spends Phase through real world routing")
\tw.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;check(w.dragon.try_ability("wall"),"Umbra casts Umbral Wake");w.dragon.advance_combat(.19);check(not w.walls.is_empty() and w.walls[-1].guardian=="shadow","Umbral Wake snapshots Shadow ownership")
\tvar field=w.walls[-1];w.dragon.advance_combat(.5);w.party.swap_remaining=0;w.dragon.input_grace=0;check(w.swap_guardian("fire"),"swap away from Umbra");check(field.guardian=="shadow" and w.walls[-1].guardian=="shadow","swap cannot relabel persistent Shadow field")
\tw.campaign.room="thaw-junction";if not w.campaign.visited.has("thaw-junction"):w.campaign.visited.append("thaw-junction");w._enter_room("thaw-junction",true);await frames(4);w._clear_encounter();if not w.campaign.cleared.has("frozen-guardian"):w.campaign.cleared.append("frozen-guardian");w._enter_room("thaw-junction",true);await frames(4)
\tw.campaign.loadout=["fire","shadow"];w.party.rebuild(w.campaign);w.party.active_id="shadow";w.dragon.use_guardian("shadow",w.party.states.shadow);w.dragon.input_grace=0;var relay=w.conduits[0];w.dragon.position=relay.node.position+Vector3.BACK*2;w.dragon.aim=Vector3.FORWARD;w.resolve_ability("breath",w.dragon.position,Vector3.FORWARD);check(relay.sim.heat==0,"Void Pulse cannot power thermal relay")
\tw.queue_free();await frames(4);print("SHADOW_RUNTIME_TESTS: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
''')
write('campaign/tests/shadow_capture.gd','''extends SceneTree
## Prepared-state visual review using the actual campaign; not an unassisted playthrough.
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Enemy=preload("res://campaign/enemy.gd")
var failures=0
const OUT="res://artifacts/shadow/captures"
func _initialize():root.size=Vector2i(1280,720);call_deferred("run")
func frames(n=4):
\tfor i in range(n):await process_frame
func shot(label):await frames(3);await RenderingServer.frame_post_draw;if root.get_texture().get_image().save_png(OUT+"/"+label+".png")!=OK:failures+=1;print("SHADOW_CAPTURE "+label)
func ready()->Dictionary:
\tvar c=Rules.fresh();Rules.hatch(c);c.ice_rescued=true;c.lattice_recovered=true;c.storm_forged=true;c.stone_imprint_recovered=true;c.stone_forged=true;c.venom_culture_recovered=true;c.venom_forged=true;c.shadow_forged=true;c.guardians=["fire","ice","storm","stone","venom","shadow"];c.loadout=["fire","shadow"];c.active_guardian="shadow";c.evolutions={"fire":"flashfire","ice":"aegis","storm":""};c.cleared=["outer-boss","frozen-boss","storm-boss"];c.cores=["outer","frozen","storm"];c.installed=c.cores.duplicate();c.room="forge";return c
func run():
\tDirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT));var w=World.new();w.test_mode=true;root.add_child(w);await frames(5);w.title_open=false;w.hud.close_overlay();w.campaign=ready();w._enter_room("forge",true);await frames(5);w.party.rebuild(w.campaign);w.party.active_id="shadow";w.dragon.use_guardian("shadow",w.party.states.shadow);w.dragon.position=Vector3(0,.1,2);w.dragon.aim=Vector3.FORWARD
\tw.hud.show_fusion();await shot("01-shadow-recipe");w.hud.close_overlay();w.hud.show_party();await shot("02-six-guardian-roster");w.hud.close_overlay();await shot("03-umbra-negative-space")
\tvar foe=Enemy.new();foe.spec={"id":"shadow-capture","name":"Training Sentinel","hp":900.0,"damage":10.0,"shield":false,"boss":false,"patterns":["slam"],"archetype":"bruiser"};foe.target=w.dragon;foe.navigation=w;w.level.add_child(foe);foe.position=w.dragon.position+Vector3.FORWARD*3;foe.set_physics_process(false);w.enemies=[foe];w._select_enemy();w.dragon.input_grace=0;w.dragon.state.phase=2
\tw.dragon.try_ability("wall");w.dragon.advance_combat(.19);await shot("04-umbral-wake");w.dragon.advance_combat(.5);w.dragon.state.heat=0;w.dragon.state.cooldowns.clear();w.dragon.input_grace=0;w.dragon.try_ability("burst");w.dragon.advance_combat(.21);paused=true;await shot("05-phase-strike");paused=false
\tw.queue_free();await frames(4);print("SHADOW_VISUAL: %d failures"%failures);quit(1 if failures else 0)
''')
print('SHADOW_RUNTIME_INTEGRATION: exact anchors applied')
