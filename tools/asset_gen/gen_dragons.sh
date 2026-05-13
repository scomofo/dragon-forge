#!/usr/bin/env bash
# Dragon evolution sprite sheet generator — 6 elements × 4 stages = 24 sheets.
# Usage: bash tools/asset_gen/gen_dragons.sh [element] [stage]
# Omit args to generate all 24. Supply both to generate a single sheet.
# Output: assets/dragons/<element>_stage<N>.png  (also copied to dragon-forge-godot/assets/dragons/)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

ELEMENTS=(fire ice storm stone venom shadow)
STAGES=(1 2 3 4)

declare -A STAGE_LABEL=(
  [1]="Baby" [2]="Juvenile" [3]="Adult" [4]="Elder"
)
declare -A STAGE_DESC=(
  [1]="small crouched hatchling, stumpy wings or no wings, curious pose, 40-50% frame fill"
  [2]="medium upright juvenile, small wings spread, alert stance, 65% frame fill"
  [3]="large powerful adult, wings half-extended, battle-ready, 85% frame fill"
  [4]="massive towering elder, wings fully spread, glowing eyes, radiates element energy, 100% frame fill"
)
declare -A ELEM_DESC=(
  [fire]="lava-cracked scales, magma core glow, orange and red dorsal spines, color palette #ff6622 #ff8844"
  [ice]="translucent blue crystal scales, frozen breath trail, icicle horns, color palette #44aaff #66ccff"
  [storm]="purple-black scales, arcing lightning across body, glowing yellow eyes, color palette #aa66ff #cc88ff"
  [stone]="grey-brown rock-plated hide, moss in crevices, amber eyes, color palette #aa8844 #ccaa66"
  [venom]="sickly green scales, dripping fangs, toxic cloud fringe, color palette #44cc44 #66ee66"
  [shadow]="near-black form, purple void-fire eyes, partially transparent at edges, color palette #8844aa #aa66cc"
)

# Determine targets
if [[ $# -eq 2 ]]; then
  TARGET_ELEMENTS=("$1")
  TARGET_STAGES=("$2")
elif [[ $# -eq 1 ]]; then
  TARGET_ELEMENTS=("$1")
  TARGET_STAGES=("${STAGES[@]}")
else
  TARGET_ELEMENTS=("${ELEMENTS[@]}")
  TARGET_STAGES=("${STAGES[@]}")
fi

mkdir -p assets/dragons dragon-forge-godot/assets/dragons

for ELEM in "${TARGET_ELEMENTS[@]}"; do
  for STAGE in "${TARGET_STAGES[@]}"; do
    OUT="assets/dragons/${ELEM}_stage${STAGE}.png"
    GODOT_OUT="dragon-forge-godot/assets/dragons/${ELEM}_stage${STAGE}.png"

    if [[ -f "$OUT" ]]; then
      echo "[SKIP] $OUT (delete to regenerate)"
      cp -n "$OUT" "$GODOT_OUT" 2>/dev/null || true
      continue
    fi

    PROMPT="pixel art 2D side-view horizontal sprite sheet of a ${STAGE_LABEL[$STAGE]} ${ELEM} dragon, ${STAGE_DESC[$STAGE]}, ${ELEM_DESC[$ELEM]}, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders no frame numbers"

    echo "[GEN] $OUT"
    echo "  Stage ${STAGE} (${STAGE_LABEL[$STAGE]}) — ${ELEM}"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "blurry, watermark, text, border, frame number, photorealistic, 3D, extra limbs, multiple heads" \
      --width 1024 \
      --height 256 \
      --output "$OUT"

    cp "$OUT" "$GODOT_OUT"
    echo "[DONE] $OUT → $GODOT_OUT"
  done
done

echo ""
echo "Dragon generation complete."
echo "Verify with: bash tools/asset_gen/gen_dragons.sh --verify"
