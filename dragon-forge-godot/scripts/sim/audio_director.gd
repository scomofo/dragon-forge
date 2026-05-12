extends Node

var _music_player: AudioStreamPlayer
var _sfx_player: AudioStreamPlayer
var _music_enabled: bool = true
var _sfx_enabled: bool = true
var _current_track: String = ""

func _ready() -> void:
	_setup_buses()
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	_music_player.volume_db = 0.0
	add_child(_music_player)
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.bus = "SFX"
	add_child(_sfx_player)

func _setup_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "Music")
		AudioServer.set_bus_volume_db(idx, -3.0)
		AudioServer.set_bus_send(idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus()
		var idx := AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(idx, "SFX")
		AudioServer.set_bus_volume_db(idx, 0.0)
		AudioServer.set_bus_send(idx, "Master")

func play_music_context(track_key: String) -> void:
	if not _music_enabled or track_key == _current_track:
		return
	_current_track = track_key
	var path := "res://assets/audio/music/%s.ogg" % track_key
	if not ResourceLoader.exists(path):
		return
	_music_player.stream = load(path)
	_music_player.play()

func play_sfx_profile(profile: Dictionary) -> void:
	if not _sfx_enabled:
		return
	var path: String = str(profile.get("path", ""))
	if path == "" or not ResourceLoader.exists(path):
		return
	_sfx_player.stream = load(path)
	_sfx_player.play()

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if not enabled:
		_music_player.stop()
		_current_track = ""

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled

func stop_music() -> void:
	_music_player.stop()
	_current_track = ""

func play_music(track: String) -> void:
	play_music_context(track)

func play_sfx(_sfx_key: String) -> void:
	pass
