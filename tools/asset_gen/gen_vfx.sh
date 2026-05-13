#!/usr/bin/env bash
# VFX asset prep — alias existing element VFX to particle_<element>.png format
# and generate corruption overlay PNGs (stages 2/3/4) via inference.
# Usage: bash tools/asset_gen/gen_vfx.sh
# Output: dragon-forge-godot/assets/vfx/particle_<element>.png
#         dragon-forge-godot/assets/vfx/corruption_stage_{2,3,4}.png
#         assets/vfx/ copies of the above

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

mkdir -p assets/vfx

# --- Alias existing element VFX to particle_<element>.png ---
# Source files live in dragon-forge-godot/assets/vfx/ (already imported by Godot)
declare -A ELEM_SOURCE=(
  [fire]="dragon-forge-godot/assets/vfx/fire_effects.png"
  [ice]="dragon-forge-godot/assets/vfx/ice_crystals.png"
  [storm]="dragon-forge-godot/assets/vfx/storm_lightning.png"
  [stone]="dragon-forge-godot/assets/vfx/stone_explosion.png"
  [venom]="dragon-forge-godot/assets/vfx/venom_cloud.png"
  [shadow]="dragon-forge-godot/assets/vfx/shadow_flames.png"
)

for ELEM in fire ice storm stone venom shadow; do
  SRC="${ELEM_SOURCE[$ELEM]}"
  DEST="dragon-forge-godot/assets/vfx/particle_${ELEM}.png"
  ASSETS_DEST="assets/vfx/particle_${ELEM}.png"
  if [[ -f "$SRC" ]]; then
    cp -f "$SRC" "$DEST"
    cp -f "$SRC" "$ASSETS_DEST"
    echo "[ALIAS] $SRC → $DEST"
  else
    echo "[MISSING SOURCE] $SRC — skipping particle_${ELEM}.png"
  fi
done

# --- Generate corruption overlays via inference ---
COMMON_NEG="blurry, watermark, text, border, photorealistic, 3D, color, bright"

declare -A CORRUPTION_DESC=(
  [2]="subtle digital corruption overlay, sparse glitching scanlines and static noise on a black background, 20% coverage, dark purple tint, transparent alpha regions, pixel art style"
  [3]="moderate digital corruption overlay, dense glitching scanlines with data-fragment artifacts on black, 50% coverage, deep purple and red tint, pixel art style"
  [4]="severe total corruption overlay, heavy all-over glitch static and reality-tear fragments on black, 80% coverage, intense crimson and void-purple, pixel art style"
)

for STAGE in 2 3 4; do
  OUT="dragon-forge-godot/assets/vfx/corruption_stage_${STAGE}.png"
  ASSETS_OUT="assets/vfx/corruption_stage_${STAGE}.png"
  if [[ ! -f "$OUT" ]]; then
    PROMPT="${CORRUPTION_DESC[$STAGE]}, no text no borders no frame numbers"
    echo "[GEN] $OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "$COMMON_NEG" \
      --width 256 \
      --height 256 \
      --output "$OUT"
    echo "[DONE] $OUT"
  else
    echo "[SKIP] $OUT"
  fi
  cp -f "$OUT" "$ASSETS_OUT"
done

echo ""
echo "VFX prep complete."

# Verify
MISSING=0
for ELEM in fire ice storm stone venom shadow; do
  [[ -f "dragon-forge-godot/assets/vfx/particle_${ELEM}.png" ]] || \
    { echo "MISSING: particle_${ELEM}.png"; MISSING=1; }
done
for STAGE in 2 3 4; do
  [[ -f "dragon-forge-godot/assets/vfx/corruption_stage_${STAGE}.png" ]] || \
    { echo "MISSING: corruption_stage_${STAGE}.png"; MISSING=1; }
done
[[ $MISSING -eq 0 ]] && echo "All 9 VFX files verified." || echo "Some files missing — re-run the script."
