extends SceneTree
func _initialize() -> void:
	var args = OS.get_cmdline_user_args()
	if args.size() != 1 or not args[0].is_absolute_path(): quit(2); return
	DirAccess.make_dir_recursive_absolute(args[0])
	var file = FileAccess.open(args[0].path_join("GODOT-LICENSE.txt"),FileAccess.WRITE)
	file.store_string(Engine.get_license_text());file.close()
	file = FileAccess.open(args[0].path_join("GODOT-THIRD-PARTY.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"copyright":Engine.get_copyright_info(),"licenses":Engine.get_license_info()},"  "));file.close()
	quit()
