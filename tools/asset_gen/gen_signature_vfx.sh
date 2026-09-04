#!/usr/bin/env bash
# Signature-move VFX strip generator (P1) — clears the procedural placeholder
# debt on the 9 signature moves. Each strip is a 1024x256 horizontal sheet of 4
# frames (launch -> travel -> peak -> impact), 256x256 per frame, in the move's
# authored palette + motif from src/sprites.js.
#
# Output: public/assets/vfx/vfx_sig_<key>.png  (lowercase signature key)
#
# Usage: FAL_KEY=<key> bash tools/asset_gen/gen_signature_vfx.sh [key ...]
# Omit keys to generate all 9. Existing files are skipped (delete to regen).

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

OUT_DIR="public/assets/vfx"
mkdir -p "$OUT_DIR"

STYLE="16-bit pixel art VFX sprite sheet, exactly 4 frames in a single horizontal row, each frame 256x256, on a uniform solid pure black background across ALL four frames. A single contained elemental projectile travels left to right and grows: frame 1 small compact orb at the left, frame 2 larger with a particle trail, frame 3 largest and most intense filling the frame, frame 4 a radial impact burst exploding outward. The projectile is centered within each 256x256 cell and never crosses cell boundaries. Bold saturated colours with a bright glowing core and softer outer glow, 1-2px black outlines, no objects, no scenery, no text no letters no numbers no borders no frame numbers"
NEG="blurry, watermark, text, letters, numbers, binary, glyphs, runes, border, frame number, photorealistic, 3D, muddy colours, single frame, grid lines, checkerboard, character, dragon, creature, white background, grey background"

# key -> contained elemental projectile in the move's authored palette (from
# src/sprites.js). Keep each a single contained projectile/energy mass like the
# proven attack strips — no literal objects, no scenery, no glyphs.
declare -A DESC=(
  [heartforge]="a blazing forge-fire projectile: a compact orb of molten ember-orange flame with a hot white core, trailing forge sparks and embers, growing larger and bursting into an anvil-shaped shockwave of fire on impact, palette #ff5a1f #ffaa00 #7a1e00"
  [absolute_zero]="a freezing projectile: a compact orb of jagged ice and frost swirling inward, trailing ice crystals, growing larger and bursting into a snowflake of shattered frost on impact, palette #ccf4ff #44aaff #0a2a4a"
  [overclock]="an overcharged projectile: a compact crackling orb of violet-white electricity with a spinning gear-shaped corona, trailing zigzag sparks, growing larger and bursting into an electric gear-flash on impact, palette #e8dcff #7b5fff #1a1040"
  [bastion]="a fortifying projectile: a compact spinning mass of golden stone-and-energy bricks, trailing dust, growing larger and bursting outward into a radiant wall of interlocking bricks on impact, palette #e8d5a8 #aa8844 #3a2a18"
  [hemotoxin]="a toxic projectile: a compact glob of bright venom-green acid, trailing corrosive dripping droplets, growing larger and bursting into a dripping fang-shaped splash of toxin on impact, palette #baff5c #33cc44 #0a2a10"
  [phase_strike]="a phasing projectile: a compact violet rift-blade of slashing energy, trailing after-image echoes, growing larger and bursting into a cross-slash rift tear on impact, palette #d5a8ff #6633aa #08000f"
  [siphon_rift]="a draining projectile: a compact cyan vortex orb pulling spirals of energy inward, trailing suction streams, growing larger and bursting into an inward-collapsing spiral on impact, palette #66ffff #0099aa #001a20"
  [restoration]="a healing projectile: a compact orb of golden stained-glass light, trailing soft light petals, growing larger and blooming outward into a radiant pane of gold on impact, palette #fff6cc #ffd966 #7a5c00"
  [recompile]="a reweaving projectile: a compact orb of violet diamond-lattice energy, trailing assembling crystal shards, growing larger and bursting into a woven diamond flash on impact, palette #f0e0ff #c8a8e0 #2a1a40"
)

ALL=(heartforge absolute_zero overclock bastion hemotoxin phase_strike siphon_rift restoration recompile)

if [[ $# -ge 1 ]]; then
  TARGETS=("$@")
else
  TARGETS=("${ALL[@]}")
fi

for KEY in "${TARGETS[@]}"; do
  if [[ -z "${DESC[$KEY]:-}" ]]; then
    echo "[ERR] unknown signature key: $KEY" >&2
    continue
  fi
  OUT="$OUT_DIR/vfx_sig_${KEY}.png"
  if [[ -f "$OUT" ]]; then
    echo "[SKIP] $OUT (delete to regenerate)"
    continue
  fi
  echo "[GEN] $OUT"
  bash inference.sh \
    --model "seedream-4.5" \
    --prompt "${DESC[$KEY]}, ${STYLE}" \
    --negative "$NEG" \
    --width 1024 \
    --height 256 \
    --output "$OUT"
  echo "[DONE] $OUT"
  # Force a uniform transparent background across all 4 frames. The model
  # returns a black (or mixed) backdrop; key dark->transparent per frame so the
  # strip never flickers when sliced. Keeps the glowing projectile opaque.
  python3 tools/asset_gen/_vfx_strip_alpha.py "$OUT"
done

echo ""
echo "Signature VFX generation complete."
