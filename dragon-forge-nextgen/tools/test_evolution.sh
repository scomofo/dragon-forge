#!/usr/bin/env bash
# From the native project root. Engine and optional independent validator are supplied by CI/user.
set -euo pipefail
mkdir -p artifacts/evolution
python3 tools/validate_art.py | tee artifacts/evolution/original-exports.log
python3 tools/validate_evolutions.py | tee artifacts/evolution/exports.log
node tools/validate_evolutions.cjs | tee artifacts/evolution/gltf.log
timeout 100 godot --headless --path . --editor --import 2>&1 | tee artifacts/evolution/import.log
if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' artifacts/evolution/import.log; then exit 1; fi
for script in tests/run.gd tests/art_test.gd validation/review_tests.gd validation/polish_tests.gd campaign/tests/run.gd campaign/tests/party_tests.gd campaign/tests/evolution_tests.gd campaign/tests/play_smoke.gd; do
  log="artifacts/evolution/${script//\//_}.log"
  timeout 150 godot --headless --fixed-fps 60 --path . --script "res://$script" -- --test-mode 2>&1 | tee "$log"
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:|^FAIL ' "$log"; then exit 1; fi
done
grep 'EVOLUTION_TESTS:.*0 failures' artifacts/evolution/campaign_tests_evolution_tests.gd.log
for mode in gl_compatibility forward_plus; do
  timeout 240 xvfb-run -a godot --path . --rendering-method "$mode" --audio-driver Dummy --script res://campaign/tests/evolution_capture.gd -- --test-mode 2>&1 | tee "artifacts/evolution/$mode.log"
  if grep -E 'SCRIPT ERROR|Parse Error|ERROR:' "artifacts/evolution/$mode.log"; then exit 1; fi
  grep 'EVOLUTION_VISUAL: 0 failures' "artifacts/evolution/$mode.log"
  mv artifacts/evolution/captures "artifacts/evolution/$mode"
done
