#!/usr/bin/env bash
# Synthesis Dragon sprite sheet generator — 4 stages.
# Usage: bash tools/asset_gen/gen_synthesis.sh [stage]
# Omit stage to generate all 4. Supply 1-4 to generate a single sheet.
# Output: assets/dragons/synthesis_stage<N>.png
#   → copied to public/assets/dragons/ (browser build)
#   → copied to dragon-forge-godot/assets/dragons/ (Godot build)

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

STAGES=(1 2 3 4)
TARGET_STAGES=("${STAGES[@]}")
[[ $# -eq 1 ]] && TARGET_STAGES=("$1")

declare -A STAGE_PROMPT=(
  [1]="pixel art 2D side-view horizontal sprite sheet of a Baby Synthesis Dragon, small crouched hatchling, stumpy wing buds, curious pose, 40-50% frame fill, crystalline silver-white scales with faint void-purple markings, soft golden glow from eyes and belly, cosmic energy motes drifting around body, fusion of void darkness and radiant light, color palette #e8eeff #ffe8aa #220033, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders no frame numbers"
  [2]="pixel art 2D side-view horizontal sprite sheet of a Juvenile Synthesis Dragon, medium upright juvenile, small wings spread, alert stance, 65% frame fill, silver-white crystal scales with void-dark wing membranes, golden radiant light bleeding through cracks in dark wing edges, cosmic gold energy wisps trailing from tail, fusion of void darkness and radiant light, color palette #e8eeff #ffe8aa #220033 #aaddff, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders no frame numbers"
  [3]="pixel art 2D side-view horizontal sprite sheet of an Adult Synthesis Dragon, large powerful adult, wings half-extended, battle-ready stance, 85% frame fill, crystalline white armor plating with void-black fractures leaking golden radiance, glowing gold eyes, cosmic halo particle ring, wing gradient from void-purple at roots to white-gold at tips, fusion of void darkness and radiant light, color palette #e8eeff #ffe8aa #220033 #aa66cc, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders no frame numbers"
  [4]="pixel art 2D side-view horizontal sprite sheet of an Elder Synthesis Dragon, massive towering elder, wings fully spread filling frame, 100% frame fill, crystalline white and void-black body in perfect dual-tone balance, radiant gold-white energy crown above head, wing span merges void purple roots with white-gold tips, reality-warping aura blending light and void, ancient cosmic entity, glowing eyes, fusion of void darkness and radiant light, color palette #e8eeff #ffe8aa #220033 #ffffff, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders no frame numbers"
)

declare -A STAGE_LABEL=([1]="Baby" [2]="Juvenile" [3]="Adult" [4]="Elder")

NEGATIVE="blurry, watermark, text, border, frame number, photorealistic, 3D, extra limbs, multiple heads, split panel"

mkdir -p assets/dragons public/assets/dragons dragon-forge-godot/assets/dragons

for STAGE in "${TARGET_STAGES[@]}"; do
  OUT="assets/dragons/synthesis_stage${STAGE}.png"
  PUB_OUT="public/assets/dragons/synthesis_stage${STAGE}.png"
  GODOT_OUT="dragon-forge-godot/assets/dragons/synthesis_stage${STAGE}.png"

  if [[ -f "$OUT" ]]; then
    echo "[SKIP] $OUT (delete to regenerate)"
    cp -n "$OUT" "$PUB_OUT"   2>/dev/null || true
    cp -n "$OUT" "$GODOT_OUT" 2>/dev/null || true
    continue
  fi

  echo "[GEN] Stage ${STAGE} — ${STAGE_LABEL[$STAGE]}"
  bash inference.sh \
    --model "seedream-4.5" \
    --prompt "${STAGE_PROMPT[$STAGE]}" \
    --negative "$NEGATIVE" \
    --width 1024 \
    --height 256 \
    --output "$OUT"

  # Compress (target ≤300 KB) then copy to both build trees
  if command -v pngquant &>/dev/null; then
    pngquant --force --quality=65-85 --output "$OUT" "$OUT"
  fi

  cp "$OUT" "$PUB_OUT"
  cp "$OUT" "$GODOT_OUT"
  echo "[DONE] $OUT → public/ + godot/"
done

echo ""
echo "Synthesis Dragon generation complete."
echo "Verify with: npx vitest run src/assetManifest.test.js"
