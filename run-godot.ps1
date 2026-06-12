$godot = "$env:USERPROFILE\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe"
$project = "C:\dev\dragon-forge\dragon-forge-godot"

if (-not (Test-Path $godot)) {
    Write-Error "Godot binary not found at: $godot`nDownload Godot 4.6.2 win64 and extract to $env:USERPROFILE\Downloads\"
    exit 1
}

if ($args[0] -eq "test") {
    & $godot --headless --path $project --script res://scripts/tests/sim_smoke.gd
} else {
    & $godot --path $project
}
