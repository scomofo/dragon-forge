extends RefCounted
## Repository recordings only. music_battle is PCM WAV despite the browser's .mp3 name.
const ROOT = "res://campaign/audio/music/"
const TRACKS = {
	"title": "theme.mp3", "forge": "music_hub.mp3", "explore": "music_map_wander.mp3",
	"battle": "music_battle.wav", "boss": "music_boss.mp3", "mirror": "music_mirror_admin.mp3",
	"final": "music_singularity.mp3", "victory": "music_victory.mp3", "defeat": "music_defeat.mp3",
	"ending": "music_credits.mp3",
}
const DEFAULTS = {"version":1, "master":0.8, "music":0.45, "sfx":0.7, "muted":false, "mute_unfocused":true}

static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("version") != 1:
		return {}
	var result = DEFAULTS.duplicate()
	for key in ["master", "music", "sfx"]:
		var v: Variant = value.get(key)
		if not (v is int or v is float) or not is_finite(float(v)) or v < 0 or v > 1:
			return {}
		result[key] = float(v)
	for key in ["muted", "mute_unfocused"]:
		if not value.get(key) is bool: return {}
		result[key] = value[key]
	return result

static func role(world) -> String:
	if world.title_open: return "title"
	if is_instance_valid(world.hud):
		if world.hud.overlay_kind == "ending": return "ending"
		if world.hud.overlay_kind == "defeat": return "defeat"
	for foe in world.enemies:
		if not is_instance_valid(foe) or foe.is_queued_for_deletion() or foe.hp <= 0: continue
		if foe.spec.id == "singularity-final": return "final"
		if foe.spec.id == "admin-boss": return "mirror"
		return "boss" if foe.boss else "battle"
	return "forge" if world.campaign.room == "forge" else "explore"
