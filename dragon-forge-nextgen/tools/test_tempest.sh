#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export GODOT_SILENCE_ROOT_WARNING=1
mkdir -p artifacts/tempest
"$GODOT" --headless --editor --import > artifacts/tempest/import.log 2>&1
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/tempest/import.log; then exit 1; fi
for script in tests/run.gd tests/art_test.gd validation/review_tests.gd validation/polish_tests.gd campaign/tests/run.gd campaign/tests/party_tests.gd campaign/tests/evolution_tests.gd campaign/tests/fusion_tests.gd campaign/tests/tempest_tests.gd campaign/tests/audio_tests.gd campaign/tests/play_smoke.gd campaign/tests/fusion_play.gd; do
  log="artifacts/tempest/$(echo "$script" | tr / _).log"
  clock_args=(--fixed-fps 60)
  if [[ "$script" == campaign/tests/audio_tests.gd ]]; then clock_args=(); fi
  timeout 120 "$GODOT" --headless "${clock_args[@]}" --script "res://$script" -- --test-mode > "$log" 2>&1
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:|^FAIL ' "$log"; then exit 1; fi
  grep -E 'checks, 0 failures|PLAY: 0 failures' "$log"
done
