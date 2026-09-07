extends Node3D
const Art = preload("res://presentation/art_library.gd")
var boss = false
var model: Node3D
var skeleton: Skeleton3D
var player: AnimationPlayer
var clock = 0.0
var sampled_clip = "idle"

func _ready() -> void:
	model = Art.place(self, "packet_warden" if boss else "firewall_sentinel")
	skeleton = model.find_child("Skeleton3D", true, false)
	player = model.find_child("AnimationPlayer", true, false)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	Art.sample(player, "idle", 0.0)

func animate(delta: float, brain, speed: float, reduced: bool) -> void:
	clock += maxf(0.0, delta)
	sampled_clip = "idle"
	var time = 0.0
	if brain.mode == "tell":
		sampled_clip = "tell"
		time = 1.0 - clampf(brain.timer / maxf(brain.locked_duration, 0.001), 0.0, 1.0)
	elif brain.vulnerable():
		sampled_clip = "open"
		time = 0.5
	elif speed > 0.15:
		sampled_clip = "walk"
		time = fposmod(clock, 0.9)
	elif not reduced:
		time = fposmod(clock, 1.8)
	Art.sample(player, sampled_clip, time)
