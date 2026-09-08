#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
export GODOT_SILENCE_ROOT_WARNING=1
mkdir -p artifacts/bosses
for script in tests/run.gd tests/art_test.gd validation/review_tests.gd validation/polish_tests.gd campaign/tests/run.gd campaign/tests/party_tests.gd campaign/tests/evolution_tests.gd campaign/tests/fusion_tests.gd campaign/tests/tempest_tests.gd campaign/tests/audio_tests.gd campaign/tests/stone_tests.gd campaign/tests/venom_tests.gd campaign/tests/venom_runtime_tests.gd campaign/tests/recruitment_tests.gd campaign/tests/shadow_tests.gd campaign/tests/shadow_runtime_tests.gd campaign/tests/void_tests.gd campaign/tests/void_combat_tests.gd campaign/tests/void_runtime_tests.gd campaign/tests/light_tests.gd campaign/tests/light_combat_tests.gd campaign/tests/light_runtime_tests.gd campaign/tests/trial_tests.gd campaign/tests/boss_tests.gd campaign/tests/play_smoke.gd campaign/tests/fusion_play.gd campaign/tests/boss_play.gd; do
  log="artifacts/bosses/$(echo "$script" | tr / _).log"
  clock_args=(--fixed-fps 60)
  if [[ "$script" == campaign/tests/audio_tests.gd ]]; then clock_args=(); fi
  if ! timeout 150 "$GODOT" --headless "${clock_args[@]}" --script "res://$script" -- --test-mode > "$log" 2>&1; then
    echo "NATIVE_SCRIPT_FAILED: $script"
    cat "$log"
    exit 1
  fi
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:|^FAIL ' "$log"; then
    echo "NATIVE_SCRIPT_LOG_ERROR: $script"
    cat "$log"
    exit 1
  fi
  grep -E 'checks, 0 failures|PLAY: 0 failures' "$log"
done
