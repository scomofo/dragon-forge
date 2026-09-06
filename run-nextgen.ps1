param([string]$GodotPath = $env:GODOT_BIN, [switch]$Compatibility)
$ErrorActionPreference = 'Stop'
if (-not $GodotPath) {
    $cmd = Get-Command godot, godot4 -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($cmd) { $GodotPath = $cmd.Source }
}
if (-not $GodotPath) { throw 'Install Godot 4.6+ and set GODOT_BIN, or pass -GodotPath with the executable path.' }
$GodotArgs = @('--path', (Join-Path $PSScriptRoot 'dragon-forge-nextgen'))
if ($Compatibility) { $GodotArgs += @('--rendering-method', 'gl_compatibility') }
& $GodotPath @GodotArgs
exit $LASTEXITCODE
