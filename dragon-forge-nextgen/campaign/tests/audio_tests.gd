extends SceneTree
const Director=preload("res://campaign/audio/director.gd")
const Catalog=preload("res://campaign/audio/catalog.gd")
const Settings=preload("res://campaign/audio/preferences.gd")
const Synth=preload("res://campaign/audio/synth.gd")
const World=preload("res://campaign/world.gd")
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:failures+=1
	print(("PASS " if ok else "FAIL ")+label)
func frames(n: int=3) -> void:
	for i in range(n):await process_frame
func wait(seconds: float) -> void: await create_timer(seconds,true).timeout
func run() -> void:
	var count=AudioServer.bus_count
	var a=Director.new();a.test_mode=true;root.add_child(a);await frames()
	check(a.decks.size()==2 and a.voices.size()==10,"bounded two decks and ten SFX voices")
	check(AudioServer.bus_count==count+3,"three private buses created")
	for role in Catalog.TRACKS:
		var stream=a.track(role)
		check(stream!=null and stream.get_length()>1,"real recording decodes / "+role)
		check(a.track(role)==stream,"stream reused / "+role)
	check(a.track("battle") is AudioStreamWAV,"mislabeled original battle recording uses WAV decoder")
	check(a.track("battle").loop_mode==AudioStreamWAV.LOOP_FORWARD,"WAV music loops")
	check(a.track("title").loop and not a.track("victory",false).loop,"bed loops, reward does not")
	for cue in Synth.CUES:
		var s=Synth.sound(cue,"storm")
		check(s!=null and s.data.size()>100,"generated cue is PCM / "+cue)
	check(not a.request_music("invalid"),"unknown track rejected")
	a.request_music("forge");a.advance(.25);a.advance(.25);a.advance(.2)
	check(a.gains[a.active]==1.0,"crossfade reaches full target")
	var active=a.active
	a.request_music("forge")
	check(a.active==active and a.fade==1.0,"same track never restarts fade")
	a.request_music("battle");a.advance(.2);a.request_music("forge")
	for i in range(5):a.advance(.2)
	check(a.current_role=="forge" and a.gains[a.active]==1,"mid-fade reversal resolves safely")
	var live=0
	for d in a.decks:
		if d.playing:live+=1
	check(live==1,"outgoing deck stops after fade")
	a.set_value("music",0.0);a.request_music("boss");a.advance(.25)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(a.buses[1])),"zero music remains muted through fades")
	a.set_value("muted",true);a.request_music("final");a.advance(.25)
	check(a.muted_output and not a.play_cue("burst"),"mute blocks cues and survives music changes")
	a.set_value("muted",false);a.set_value("music",.45)
	a.set_focused(false)
	check(a.muted_output and a.decks[a.active].stream_paused,"focus loss silences and pauses bed")
	a.set_value("muted",true);a.set_focused(true)
	check(a.muted_output,"focus return does not override user mute")
	a.set_value("muted",false)
	check(a.play_cue("warning"),"warning cue available")
	check(not a.play_cue("warning"),"duplicate warning rate limited")
	paused=true;await frames()
	check(not a.play_cue("claw"),"gameplay effects rejected while paused")
	check(a.play_cue("ui","fire",0,true),"UI can sound while paused")
	paused=false;a.clear_effects()
	check(not a.set_value("music",NAN) and not a.set_value("music",-1) and not a.set_value("unknown",0),"invalid preferences rejected")
	var pref=Settings.new();pref.path="user://tempest-audio-test.json"
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(pref.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(pref.path+suffix))
	check(pref.read_values()==Catalog.DEFAULTS,"new audio preferences are independent defaults")
	var v=Catalog.DEFAULTS.duplicate();v.music=.13;v.muted=true
	check(pref.write_values(v) and pref.read_values()==v,"audio preferences round-trip")
	var f=FileAccess.open(pref.path,FileAccess.WRITE);f.store_string('{"version":99}');f.close()
	pref.read_values()
	check(pref.blocked and not pref.write_values(v) and FileAccess.get_file_as_string(pref.path)=='{"version":99}',"future preferences not overwritten")
	for suffix in ["",".bak",".tmp"]:
		if FileAccess.file_exists(pref.path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(pref.path+suffix))
	# Capture actual mixed output, not just a playing flag. No microphone is opened.
	var capture=AudioEffectCapture.new();capture.buffer_length=2.0
	AudioServer.add_bus_effect(0,capture)
	a.set_value("master",.8);a.set_value("music",.45);a.request_music("forge")
	await wait(.85);capture.clear_buffer();await wait(.25)
	var pcm=capture.get_buffer(capture.get_frames_available())
	var peak=0.0
	for frame in pcm:peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
	check(pcm.size()>100 and peak>.001 and peak<1,"actual music mixed non-silent below clipping")
	a.set_value("muted",true);await wait(.20);capture.clear_buffer();await wait(.20)
	pcm=capture.get_buffer(capture.get_frames_available());peak=0.0
	for frame in pcm:peak=maxf(peak,maxf(absf(frame.x),absf(frame.y)))
	check(pcm.size()>100 and peak<.00001,"mute gives silent sampled output after mixer latency")
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	# Drain unpaused (but silent) playback before removing the test-only buses.
	a.set_value("music",0.0);a.set_value("sfx",0.0);a.set_value("muted",false);a.set_focused(true)
	await wait(.2)
	a.queue_free();await wait(.2);await frames()
	check(AudioServer.bus_count==count,"director cleanup leaves no private buses")
	var w=World.new();w.test_mode=true;root.add_child(w);await frames()
	a=Director.new();a.test_mode=true;a.source=w;w.audio=a;w.add_child(a)
	w.title_open=true;w.hud.show_title();await frames()
	check(a.current_role=="title","normal title routed to existing theme")
	w.hud.show_audio();await frames()
	check(w.hud.overlay_kind=="audio" and paused,"dedicated paused audio menu")
	w.hud._leave_audio()
	check(w.hud.overlay_kind=="title" and w.title_open,"audio menu returns to title safely")
	w.begin_campaign(false);await frames()
	check(a.current_role=="forge","begin routes to Forge soundtrack")
	w.campaign.hatched=true;w.campaign.room="signal-approach";w.campaign.visited.append("signal-approach")
	w._enter_room("signal-approach",true);await frames()
	check(a.current_role=="battle","encounter routes to battle recording")
	w.enemy._begin_attack()
	check(a.event_counts.get("warning",0)==1,"real enemy tell emits warning once")
	w.dragon.input_grace=0;w.dragon.try_ability("breath")
	check(a.event_counts.get("launch",0)==1,"real accepted ability starts launch cue")
	w.dragon.advance_combat(.23)
	check(a.event_counts.get("breath",0)==1,"real ability contact emits elemental effect")
	w.hud.close_overlay()
	a.set_value("music",0.0);a.set_value("sfx",0.0);a.set_value("muted",false);a.set_focused(true)
	await wait(.2)
	w.queue_free();a=null;w=null;capture=null
	await wait(.2);await frames()
	print("AUDIO_TESTS: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)
