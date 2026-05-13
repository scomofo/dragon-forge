#!/usr/bin/env bash
# NPC battle sprite sheet generator — 5 missing NPCs × (idle sheet + attack frame).
# Usage: bash tools/asset_gen/gen_npcs.sh [npc_id]
# Omit npc_id to generate all 10 files.
# Output: assets/npc/<npc_id>_sprites.png  and  assets/npc/<npc_id>_attack.png
# Also copies to dragon-forge-godot/assets/npc/

set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$REPO_ROOT"

NPCS=(buffer_overflow crypto_crab logic_bomb phishing_siren protocol_vulture)
TARGET_NPCS=("${@:-${NPCS[@]}}")

declare -A NPC_DESC=(
  [buffer_overflow]="a glitching humanoid data construct bleeding fire overflow, corrupted fire elemental enemy, red and orange color palette, aggressive posture"
  [crypto_crab]="a mechanical ice crab with crystalline shell and freezing breath, armored crustacean enemy, blue and white color palette, defensive sideways stance"
  [logic_bomb]="a volatile floating sphere of compressed fire logic with a ticking countdown display on its surface, orange and red flames, hovering enemy, pulsing energy"
  [phishing_siren]="a bioluminescent venom serpent with digital lure tendrils, toxic green glow, sleek and predatory, venomous enemy, coiled ready to strike"
  [protocol_vulture]="a massive shadow avian daemon with corrupted data-feathers, purple void energy eyes, shadow element, wings spread, sinister scavenger enemy"
)

mkdir -p assets/npc dragon-forge-godot/assets/npc

COMMON_NEG="blurry, watermark, text, border, photorealistic, 3D, extra limbs, human face"

for NPC in "${TARGET_NPCS[@]}"; do
  DESC="${NPC_DESC[$NPC]}"

  # --- Idle sprite sheet (4 frames horizontal, 1024×256) ---
  IDLE_OUT="assets/npc/${NPC}_sprites.png"
  if [[ ! -f "$IDLE_OUT" ]]; then
    PROMPT="pixel art 2D side-view enemy idle animation sprite sheet, 4 frames horizontal, ${DESC}, dark tech-fantasy aesthetic, transparent background, clean pixel outlines, no text no borders"
    echo "[GEN IDLE] $IDLE_OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "$COMMON_NEG" \
      --width 1024 \
      --height 256 \
      --output "$IDLE_OUT"
    echo "[DONE] $IDLE_OUT"
  else
    echo "[SKIP IDLE] $IDLE_OUT"
  fi
  cp -n "$IDLE_OUT" "dragon-forge-godot/assets/npc/${NPC}_sprites.png" 2>/dev/null || \
    cp "$IDLE_OUT" "dragon-forge-godot/assets/npc/${NPC}_sprites.png"

  # --- Attack frame (single 256×256) ---
  ATK_OUT="assets/npc/${NPC}_attack.png"
  if [[ ! -f "$ATK_OUT" ]]; then
    PROMPT="pixel art 2D side-view enemy attack pose, single frame, ${DESC}, lunging forward with elemental energy burst, dark tech-fantasy aesthetic, transparent background, clean pixel outlines, no text no borders"
    echo "[GEN ATTACK] $ATK_OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "$COMMON_NEG" \
      --width 256 \
      --height 256 \
      --output "$ATK_OUT"
    echo "[DONE] $ATK_OUT"
  else
    echo "[SKIP ATTACK] $ATK_OUT"
  fi
  cp -n "$ATK_OUT" "dragon-forge-godot/assets/npc/${NPC}_attack.png" 2>/dev/null || \
    cp "$ATK_OUT" "dragon-forge-godot/assets/npc/${NPC}_attack.png"

done

echo ""
echo "NPC generation complete."

# Verify
MISSING=0
for NPC in "${NPCS[@]}"; do
  [[ -f "assets/npc/${NPC}_sprites.png" ]] || { echo "MISSING IDLE: $NPC"; MISSING=1; }
  [[ -f "assets/npc/${NPC}_attack.png"  ]] || { echo "MISSING ATTACK: $NPC"; MISSING=1; }
done
[[ $MISSING -eq 0 ]] && echo "All 10 NPC files verified." || echo "Some files missing — re-run the script."
