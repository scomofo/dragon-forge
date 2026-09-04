#!/usr/bin/env bash
# inference.sh — generates a Dragon Forge asset via the fal PRODUCTION REST API.
#
# The fal CLI on this machine is pinned to FAL_HOST=api.alpha.fal.ai (an alpha
# backend that does not see the production balance), so we bypass the CLI and
# POST directly to https://fal.run with the FAL_KEY.
#
# Usage: bash inference.sh --model <id> --prompt <text> [--negative <text>] \
#                          [--width <px>] [--height <px>] --output <file.png>
#
# Requires: FAL_KEY env var (https://fal.ai/dashboard/keys). curl + python3+PIL.

set -euo pipefail

MODEL=""
PROMPT=""
NEGATIVE=""
WIDTH=1024
HEIGHT=1024
OUTPUT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --model)    MODEL="$2";    shift 2 ;;
    --prompt)   PROMPT="$2";   shift 2 ;;
    --negative) NEGATIVE="$2"; shift 2 ;;
    --width)    WIDTH="$2";    shift 2 ;;
    --height)   HEIGHT="$2";   shift 2 ;;
    --output)   OUTPUT="$2";   shift 2 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

[[ -z "$PROMPT" ]] && { echo "ERROR: --prompt required" >&2; exit 1; }
[[ -z "$OUTPUT" ]] && { echo "ERROR: --output required" >&2; exit 1; }
[[ -z "${FAL_KEY:-}" ]] && { echo "ERROR: FAL_KEY env var required (https://fal.ai/dashboard/keys)" >&2; exit 3; }

# Map model shorthand to a production endpoint id.
case "$MODEL" in
  seedream-4.5|seedream)  APP_ID="fal-ai/bytedance/seedream/v4.5/text-to-image" ;;
  seedream-4.0)           APP_ID="fal-ai/bytedance/seedream/v4/text-to-image" ;;
  flux)                   APP_ID="fal-ai/flux/dev" ;;
  flux-schnell)           APP_ID="fal-ai/flux/schnell" ;;
  *)                      APP_ID="fal-ai/bytedance/seedream/v4.5/text-to-image" ;;
esac

# seedream v4.5 takes an image_size enum, not raw width/height. Pick the enum
# that best matches the requested aspect ratio; we downscale to the exact
# target below with PIL.
if (( WIDTH == HEIGHT )); then
  SIZE="square_hd"
elif (( WIDTH > HEIGHT )); then
  SIZE="landscape_4_3"
else
  SIZE="portrait_4_3"
fi

# Build the JSON payload safely (prompt may contain quotes).
PAYLOAD=$(python3 -c '
import json, sys
prompt, size = sys.argv[1], sys.argv[2]
print(json.dumps({"prompt": prompt, "image_size": size, "num_images": 1, "enable_safety_checker": False}))
' "$PROMPT" "$SIZE")

# Call the production endpoint.
RESULT=$(curl -fsSL -X POST "https://fal.run/${APP_ID}" \
  -H "Authorization: Key ${FAL_KEY}" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD") || { echo "ERROR: fal request failed for $APP_ID" >&2; exit 4; }

# Extract the first image URL.
IMAGE_URL=$(printf '%s' "$RESULT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
images = data.get("images", [])
if images and images[0].get("url"):
    print(images[0]["url"]); raise SystemExit(0)
raise SystemExit("No image URL in response: " + json.dumps(data)[:400])
')

# Download to a temp file, then downscale/normalize to the exact target size.
mkdir -p "$(dirname "$OUTPUT")"
TMP="$(mktemp --suffix=.img)"
curl -fsSL "$IMAGE_URL" -o "$TMP"

python3 - "$TMP" "$OUTPUT" "$WIDTH" "$HEIGHT" <<'PYEOF'
import sys
from PIL import Image
src, out, w, h = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
img = Image.open(src)
if img.size != (w, h):
    img = img.resize((w, h), Image.LANCZOS)
# Preserve alpha if the source has it; otherwise save as-is.
img.save(out, format="PNG", optimize=True, compress_level=9)
kb = __import__("pathlib").Path(out).stat().st_size // 1024
print(f"  saved {out} ({img.size[0]}x{img.size[1]}, {kb} KB)")
PYEOF

rm -f "$TMP"
