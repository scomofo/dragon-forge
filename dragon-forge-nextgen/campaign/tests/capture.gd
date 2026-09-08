extends SceneTree
const World=preload("res://campaign/world.gd")
const Rules=preload("res://campaign/progress.gd")
const Data=preload("res://campaign/data.gd")
var failures=0
var w
var output="res://artifacts/campaign"
func _initialize() -> void:
	root.size=Vector2i(1280,720)
	call_deferred("_run")
func wait_frames(n: int=6) -> void:
	for i in range(n):
		await process_frame
func capture(name_text: String) -> void:
	await wait_frames(2)
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	var result=image.save_png(output+"/"+name_text+".png")
	if result!=OK or image.is_empty():failures+=1
	print("CAMPAIGN_CAPTURE "+name_text+" "+str(image.get_size()))
func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	w=World.new();w.test_mode=true;root.add_child(w)
	await wait_frames(4)
	w.hud.show_title()
	await capture("01-title")
	w.begin_campaign()
	w.interact()
	await wait_frames(3)
	await capture("02-forge-opening")
	w.hud.show_map()
	await capture("03-world-map")
	w.hud.close_overlay()
	# Explicit seeded prerequisites for independent visual review; not a manual playthrough.
	for z in Data.ZONES:
		w.campaign.cleared.append(z.id+"-boss")
		w.campaign.cores.append(z.id)
		w.campaign.installed.append(z.id)
		w.campaign.visited.append(z.entry)
	w.campaign.module="bastion"
	for pair in [["signal-approach","04-outer-grid"],["mute-channel","05-frozen-cache"],["live-wire","06-storm-spine"],["cold-lanterns","07-admin-core"],["singularity","08-singularity"]]:
		w.campaign.room=pair[0]
		w._enter_room(pair[0],true)
		await wait_frames(3)
		w.dragon.position=Vector3(0,0.1,-5)
		w.dragon.input_grace=0.0
		w.camera_rig.position=w.dragon.position
		await wait_frames(4)
		if is_instance_valid(w.enemy):
			w.enemy._begin_attack()
		await wait_frames(3)
		paused=true
		await capture(pair[1])
		paused=false
	w.campaign.room="forge";w._enter_room("forge",true)
	await wait_frames(3)
	w.campaign.salvage=180
	w.dragon.position=Vector3(-7,0.1,2)
	w.hud.show_upgrades()
	await capture("09-upgrades")
	w.hud.close_overlay()
	w.dragon.position=Vector3(5,0.1,5)
	w.hud.show_modules()
	await capture("10-modules")
	w.hud.close_overlay()
	w.campaign.finished=true
	w.campaign.guardians.append("light")
	w.hud.show_ending()
	await capture("11-ending")
	w.hud.close_overlay()
	w.queue_free()
	await wait_frames(3)
	print("CAMPAIGN_VISUAL: %d failures" % failures)
	quit(1 if failures else 0)
