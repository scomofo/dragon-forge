$godot = "C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"
$project = "C:\Users\Scott Morley\Dev\df\dragon-forge-godot"

if ($args[0] -eq "test") {
    & $godot --headless --path $project --script res://scripts/tests/sim_smoke.gd
} else {
    & $godot --path $project
}
