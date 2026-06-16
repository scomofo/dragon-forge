#!/usr/bin/env bash
# Attack-VFX projectile sheet generator — high-fidelity hand-art replacements
# for the procedural placeholders from make_vfx_strips.py.
#
# Produces a 1024x256 sprite sheet per attack (4 frames: launch | travel | peak
# | impact, projectile travelling left->right) per handoff/ATTACK_VFX_SPRITE_GUIDE.md.
# Output overwrites: public/assets/vfx/vfx_<move>.png  (the browser build serves these).
#
# Usage:
#   bash tools/asset_gen/gen_vfx_sheets.sh            # generate all 15
#   bash tools/asset_gen/gen_vfx_sheets.sh magma_breath   # a single move
#
# Requires fal auth (FAL_KEY env var or `fal profile key set <KEY>`); inference.sh
# exits non-zero with instructions if unauthenticated.

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="public/assets/vfx"
mkdir -p "$OUT_DIR"

STYLE="16-bit pixel art VFX projectile sprite sheet, 4 frames in a single horizontal row (frame 1 launch / small forming, frame 2 travel / growing with particle trail, frame 3 peak / largest most intense, frame 4 impact / bursting and scattering), each frame 256x256, projectile travels left to right, transparent background, bold saturated colors readable on a dark background, bright glowing core with softer outer glow, 1-2px black outlines, particle trail, dark tech-fantasy aesthetic, no text no borders no frame numbers"
NEG="blurry, watermark, text, border, frame number, photorealistic, 3D, muddy colors, dull, single frame, grid lines"

# move -> effect description (element palettes from handoff/ATTACK_VFX_SPRITE_GUIDE.md)
declare -A DESC=(
  [magma_breath]="a stream of molten fire and lava hurtling forward trailing ember particles and heat distortion, orange-red #ff6622 #ff4400 #cc2200"
  [flame_wall]="a rolling wall of flame sweeping horizontally, wide and engulfing, bright orange-yellow core #ffaa00 with red edges"
  [frost_bite]="a jagged spinning ice shard fang projectile with trailing frost crystals, cyan-blue #44aaff #66ccff #88eeff"
  [blizzard]="a swirling ice storm vortex rushing forward with snowflakes and ice chunks, white-blue #ccddff #44aaff"
  [lightning_strike]="a bolt of lightning arcing forward with branching forks and electric sparks, bright purple-white #aa66ff #cc88ff #ffffff"
  [thunder_clap]="an expanding shockwave ring pulse of crackling energy, purple #aa66ff with a white electric core"
  [rock_slide]="a cluster of boulders and rocks tumbling and flying forward, brown-tan #aa8844 #ccaa66 #665533"
  [earthquake]="a ground-level shockwave of cracking earth and debris erupting upward, dark brown #665533 with tan dust #ccaa66"
  [acid_spit]="a glob of toxic acid projectile dripping and sizzling with trailing droplets, bright green #44cc44 #66ee66 #22aa22"
  [toxic_cloud]="a billowing bubbling poison gas cloud rolling forward, dark green #228822 with bright green highlights #66ee66"
  [shadow_strike]="a dark energy crescent blade slash cutting through the air trailing void wisps, dark purple #8844aa #aa66cc with a black core"
  [void_pulse]="an orb of void energy expanding as it travels distorting space, deep purple-black #330044 #8844aa with faint glowing edges"
  [void_rift]="a jagged vertical tear in reality leaking void energy, violet-white #aa88ff #ffffff with a black core, space distortion"
  [radiant_beam]="a concentrated holy beam of golden light lancing forward, radiant gold-white #ffdd66 #fffae6 with lens-flare glow"
  [solar_flare]="a blooming burst of solar plasma and golden rays expanding outward, brilliant gold #ffcc44 #fff2c0 with white-hot core"
)

ALL=(magma_breath flame_wall frost_bite blizzard lightning_strike thunder_clap \
     rock_slide earthquake acid_spit toxic_cloud shadow_strike void_pulse \
     void_rift radiant_beam solar_flare)

if [[ $# -ge 1 ]]; then
  TARGETS=("$@")
else
  TARGETS=("${ALL[@]}")
fi

for MOVE in "${TARGETS[@]}"; do
  if [[ -z "${DESC[$MOVE]:-}" ]]; then
    echo "[SKIP] unknown move: $MOVE" >&2
    continue
  fi
  OUT="$OUT_DIR/vfx_${MOVE}.png"
  echo "[GEN] $OUT"
  bash inference.sh \
    --model "seedream-4.5" \
    --prompt "${STYLE}, depicting ${DESC[$MOVE]}" \
    --negative "$NEG" \
    --width 1024 \
    --height 256 \
    --output "$OUT"
  echo "[DONE] $OUT"
done

echo ""
echo "VFX sheet generation complete. Verify references resolve:"
echo "  npx vitest run src/assetManifest.test.js"
