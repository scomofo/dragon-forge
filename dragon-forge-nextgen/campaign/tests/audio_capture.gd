extends SceneTree
## Capture the actual output mix. Synthetic tour of existing recordings and native cues.
## No microphone, no user device recording, no replacement music composition.
const Director=preload("res://campaign/audio/director.gd")
var pcm=PackedVector2Array()
var tap: AudioEffectCapture
var a
func _initialize() -> void:call_deferred("run")
func section(seconds: float) -> void:
	var left=seconds
	while left>0:
		await create_timer(.04,true).timeout
		pcm.append_array(tap.get_buffer(tap.get_frames_available()))
		left-=.04
func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://artifacts/tempest"))
	a=Director.new();a.test_mode=true;root.add_child(a)
	tap=AudioEffectCapture.new();tap.buffer_length=1.0;AudioServer.add_bus_effect(0,tap)
	a.request_music("forge");await section(2.5)
	a.play_cue("hatch","fire",3);await section(.6)
	a.request_music("battle");await section(1.0)
	a.play_cue("warning","fire",4);await section(.35)
	for guardian in ["fire","ice","storm"]:
		a.play_cue("swap",guardian,2);await section(.3)
		a.play_cue("breath",guardian,2);await section(.5)
	a.play_cue("discharge","storm",3);await section(.6)
	a.request_music("boss");await section(1.3)
	a.play_stinger("victory");await section(1.5)
	a.set_value("muted",true);await section(.3)
	var peak=0.0;var bytes=PackedByteArray();bytes.resize(pcm.size()*4)
	for i in range(pcm.size()):
		peak=maxf(peak,maxf(absf(pcm[i].x),absf(pcm[i].y)))
		bytes.encode_s16(i*4,roundi(clampf(pcm[i].x,-1,1)*32767))
		bytes.encode_s16(i*4+2,roundi(clampf(pcm[i].y,-1,1)*32767))
	var wav=AudioStreamWAV.new();wav.format=AudioStreamWAV.FORMAT_16_BITS;wav.stereo=true
	wav.mix_rate=roundi(AudioServer.get_mix_rate());wav.data=bytes
	var error=wav.save_to_wav("res://artifacts/tempest/native-audio-preview.wav")
	var result={"samples":pcm.size(),"rate":wav.mix_rate,"peak":peak,"dropped":tap.get_discarded_frames(),"scope":"Scripted native output-bus capture, not a user-device or full gameplay recording"}
	var file=FileAccess.open("res://artifacts/tempest/audio-capture.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	# Let the mixer observe unpaused streams before retiring the test director.
	# Music is zero, so draining playback cannot emit an audible frame.
	a.set_value("music",0.0);a.set_value("sfx",0.0);a.set_value("muted",false)
	a.set_focused(true)
	await create_timer(.2,true).timeout
	a.queue_free();a=null;tap=null
	await create_timer(.15,true).timeout
	await process_frame
	var ok=error==OK and pcm.size()>40000 and peak>.001 and peak<1.0 and result.dropped==0
	print("NATIVE_AUDIO_CAPTURE: "+("0 failures" if ok else "FAILED"));quit(0 if ok else 1)
