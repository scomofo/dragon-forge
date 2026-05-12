$Godot = 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe'
$Project = Split-Path -Parent $MyInvocation.MyCommand.Path

& $Godot --path $Project
