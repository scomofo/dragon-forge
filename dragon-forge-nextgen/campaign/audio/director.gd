extends Node
## Bounded native audio: two crossfading music decks, one stinger, ten SFX voices.
## Private per-instance buses never change the global Master or another test/game world.
const Catalog = preload("res://campaign/audio/catalog.gd")
const Settings = preload("res://campaign/audio/preferences.gd")
const Synth = preload("res://campaign/audio/synth.gd")
const FADE_SECONDS = .65
const VOICES = 10
var source
var test_mode = false
var settings = Settings.new()
var values = Catalog.DEFAULTS.duplicate()
var decks: Array[AudioStreamPlayer] = []
var stinger: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var buses: Array[String] = []
var deck_roles = ["", ""]
var gains = [0.0, 0.0]
var starts = [0.0, 0.0]
var targets = [0.0, 0.0]
var fade = 1.0
var active = 0
var current_role = ""
var focused = true
var was_paused = false
var music_cache: Dictionary = {}
var cooldowns: Dictionary = {}
var event_counts: Dictionary = {}
var serial = 0
var muted_output = false
var _initialized = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not test_mode: values = settings.read_values()
	var prefix = "Reconnection_" + str(get_instance_id())
	for suffix in ["Mix","Music","SFX"]:
		var bus = prefix + "_" + suffix
		AudioServer.add_bus()
		var index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index,bus)
		AudioServer.set_bus_send(index,"Master" if suffix == "Mix" else buses[0])
		buses.append(bus)
	# Conservative limiter in the private mix. Never modifies user's global audio setup.
	var limiter = AudioEffectLimiter.new()
	limiter.ceiling_db = -1.0
	limiter.threshold_db = -3.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index(buses[0]),limiter)
	for i in range(2): decks.append(_player(buses[1]))
	stinger = _player(buses[1])
	stinger.volume_db = -5
	for i in range(VOICES): voices.append(_player(buses[2]))
	_initialized = true
	apply_mix()

func _player(bus: String) -> AudioStreamPlayer:
	var node = AudioStreamPlayer.new()
	node.bus = bus
	add_child(node)
	return node

func track(role: String, looping: bool = true) -> AudioStream:
	if not Catalog.TRACKS.has(role): return null
	var key = role + ("/loop" if looping else "/once")
	if music_cache.has(key): return music_cache[key]
	var loaded = load(Catalog.ROOT + Catalog.TRACKS[role]) as AudioStream
	if loaded == null: return null
	var stream = loaded.duplicate() as AudioStream
	if stream is AudioStreamMP3:
		stream.loop = looping
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if looping else AudioStreamWAV.LOOP_DISABLED
		stream.loop_begin = 0
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	music_cache[key] = stream
	return stream

func request_music(role: String) -> bool:
	if not Catalog.TRACKS.has(role) or not _initialized: return false
	if role == current_role: return true
	# Reuse the existing deck on a reversal; otherwise replace the quieter deck.
	var next = deck_roles.find(role)
	if next < 0: next = 0 if gains[0] <= gains[1] else 1
	if deck_roles[next] != role or not decks[next].has_stream_playback():
		decks[next].stop()
		decks[next].stream = track(role,not role in ["victory","defeat"])
		if decks[next].stream == null: return false
		decks[next].volume_db = -80
		decks[next].play()
		deck_roles[next] = role
	active = next
	current_role = role
	starts = gains.duplicate()
	targets = [0.0,0.0]
	targets[next] = 1.0
	fade = 0.0
	apply_mix()
	return true

func advance(delta: float) -> void:
	var dt = clampf(delta,0.0,.25) if is_finite(delta) else 0.0
	for key in cooldowns.keys(): cooldowns[key] = maxf(0.0,cooldowns[key]-dt)
	if not focused and values.mute_unfocused:
		apply_mix()
		return
	fade = minf(1.0,fade+dt/FADE_SECONDS)
	for i in range(2):
		gains[i] = lerpf(starts[i],targets[i],fade)
		if fade >= 1.0 and targets[i] == 0.0:
			decks[i].stop()
			deck_roles[i] = ""
	apply_mix()

func _process(delta: float) -> void:
	if is_instance_valid(source):
		request_music(Catalog.role(source))
	var paused = get_tree().paused
	if paused and not was_paused: clear_effects(true)
	was_paused = paused
	advance(delta)

func apply_mix() -> void:
	if not _initialized: return
	muted_output = values.muted or values.master <= 0.0 or (values.mute_unfocused and not focused)
	_set_bus(buses[0],values.master,muted_output)
	_set_bus(buses[1],values.music,values.music <= 0.0)
	_set_bus(buses[2],values.sfx,values.sfx <= 0.0)
	var duck = 1.0
	if is_instance_valid(source) and get_tree().paused and not source.title_open: duck = .38
	if stinger.playing: duck *= .35
	for i in range(2):
		decks[i].volume_db = linear_to_db(maxf(.0001,gains[i]*duck*.7))
		decks[i].stream_paused = not focused and values.mute_unfocused
	stinger.stream_paused = not focused and values.mute_unfocused

func _set_bus(bus: String, volume: float, mute: bool) -> void:
	var index = AudioServer.get_bus_index(bus)
	if index < 0: return
	AudioServer.set_bus_volume_db(index,linear_to_db(maxf(.0001,volume)))
	AudioServer.set_bus_mute(index,mute)

func set_value(key: String, value: Variant) -> bool:
	if not key in ["master","music","sfx","muted","mute_unfocused"]: return false
	var candidate = values.duplicate()
	candidate[key] = value
	candidate = Catalog.normalize(candidate)
	if candidate.is_empty(): return false
	values = candidate
	if values.muted or values.sfx <= 0.0 or values.master <= 0.0: clear_effects()
	apply_mix()
	return true

func save_settings() -> bool:
	return true if test_mode else settings.write_values(values)

func set_focused(value: bool) -> void:
	focused = value
	if not value and values.mute_unfocused: clear_effects(); stinger.stop()
	apply_mix()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT: set_focused(false)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN: set_focused(true)

func clear_effects(only_gameplay: bool = false) -> void:
	for voice in voices:
		if not only_gameplay or not voice.get_meta("ui",false): voice.stop()

func play_cue(cue: String, guardian: String = "fire", priority: int = 1, ui: bool = false) -> bool:
	if not _initialized or muted_output or values.sfx <= 0.0: return false
	if get_tree().paused and not ui: return false
	var key = cue + "/" + guardian
	if cooldowns.get(key,0.0) > 0: return false
	var sound = Synth.sound(cue,guardian)
	if sound == null: return false
	var candidate: AudioStreamPlayer = null
	for voice in voices:
		if not voice.playing: candidate = voice; break
	if candidate == null:
		for voice in voices:
			if int(voice.get_meta("priority",0)) <= priority:
				if candidate == null or int(voice.get_meta("serial",0)) < int(candidate.get_meta("serial",0)): candidate = voice
	if candidate == null: return false
	candidate.stop()
	candidate.stream = sound
	candidate.volume_db = -4 if cue in ["breath","burst","impact"] else -7
	candidate.set_meta("priority",priority)
	candidate.set_meta("ui",ui)
	serial += 1
	candidate.set_meta("serial",serial)
	candidate.play()
	cooldowns[key] = .18 if cue in ["hit","blocked","warning","impact"] else .05
	event_counts[cue] = event_counts.get(cue,0)+1
	return true

func play_stinger(role: String) -> void:
	if not role in ["victory"] or muted_output or values.music <= 0.0: return
	stinger.stop()
	stinger.stream = track(role,false)
	stinger.play()

func _exit_tree() -> void:
	# Remove only this director's buses, after stopping its own voices.
	clear_effects()
	for deck in decks: deck.stop()
	if is_instance_valid(stinger): stinger.stop()
	for i in range(buses.size()-1,-1,-1):
		var index = AudioServer.get_bus_index(buses[i])
		if index > 0: AudioServer.remove_bus(index)
