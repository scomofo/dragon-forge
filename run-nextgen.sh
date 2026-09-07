#!/usr/bin/env bash
set -euo pipefail
ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
GODOT="${GODOT_BIN:-}"
if [[ -z "$GODOT" ]]; then
  if command -v godot >/dev/null 2>&1; then GODOT="$(command -v godot)"
  elif command -v godot4 >/dev/null 2>&1; then GODOT="$(command -v godot4)"
  elif [[ -x /Applications/Godot.app/Contents/MacOS/Godot ]]; then GODOT=/Applications/Godot.app/Contents/MacOS/Godot
  else printf '%s\n' 'Godot 4.6+ not found. Install Godot, or set GODOT_BIN to its executable.' >&2; exit 1
  fi
fi
ARGS=()
if [[ "${1:-}" == "--compatibility" ]]; then
  ARGS+=(--rendering-method gl_compatibility)
  shift
fi
exec "$GODOT" --path "$ROOT/dragon-forge-nextgen" "${ARGS[@]}" "$@"
