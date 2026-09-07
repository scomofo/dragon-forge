extends Node
## Export-only bootstrap. Ordinary launches immediately enter the unchanged campaign.
## The explicit verification mode never creates a normal save-loading game world.
func _ready() -> void:
	set_meta("standalone_entry",true)
	if OS.get_cmdline_user_args().has("--ci-release-check"):
		var check = load("res://release/export_smoke.gd").new()
		add_child(check)
	else:
		get_tree().change_scene_to_file.call_deferred("res://campaign/main.tscn")
