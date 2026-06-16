#!/usr/bin/env bash
# inference.sh — calls fal CLI for Dragon Forge asset generation scripts.
# Usage: bash inference.sh --model <id> --prompt <text> [--negative <text>] \
#                          [--width <px>] [--height <px>] --output <file.png>
#
# Requires: fal CLI (uv tool install fal) + FAL_KEY env var or `fal auth login`

set -euo pipefail

FAL="$(command -v fal 2>/dev/null || echo "$HOME/.local/bin/fal")"

# Defaults
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

[[ -z "$PROMPT" ]]  && { echo "ERROR: --prompt required" >&2; exit 1; }
[[ -z "$OUTPUT" ]]  && { echo "ERROR: --output required" >&2; exit 1; }

# Map model shorthand to fal app ID
case "$MODEL" in
  seedream-4.5|seedream)  APP_ID="bytedance/seedream-4-5" ;;
  seedream-4.0)           APP_ID="bytedance/seedream-4-0" ;;
  flux)                   APP_ID="falai/flux-dev-lora" ;;
  flux-klein)             APP_ID="pruna/flux-klein-4b" ;;
  *)                      APP_ID="bytedance/seedream-4-5" ;;
esac

# Build fal api args (key=value pairs)
ARGS=("$APP_ID" "prompt=${PROMPT}" "width=${WIDTH}" "height=${HEIGHT}")
[[ -n "$NEGATIVE" ]] && ARGS+=("negative_prompt=${NEGATIVE}")

# Fail loudly if not authenticated (previously the error was swallowed and the
# batch scripts reported a phantom success).
if ! "$FAL" auth whoami >/dev/null 2>&1 && [[ -z "${FAL_KEY:-}" ]]; then
  echo "ERROR: fal is not authenticated." >&2
  echo "  Run: fal profile key set <KEY>   (or)   export FAL_KEY=<KEY>" >&2
  echo "  Get a key at https://fal.ai/dashboard/keys" >&2
  exit 3
fi

# Run and capture JSON output (surface fal's stderr if the call fails)
if ! RESULT=$("$FAL" api "${ARGS[@]}" 2>/tmp/fal_err); then
  echo "ERROR: fal api call failed for $APP_ID:" >&2
  cat /tmp/fal_err >&2
  exit 4
fi

# Extract image URL — seedream returns {"images":[{"url":"..."}]}
# Fallback handles older {"output":{"image":"..."}} shape
IMAGE_URL=$(printf '%s' "$RESULT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
images = data.get("images", [])
if images:
    print(images[0]["url"]); raise SystemExit(0)
url = data.get("output", {}).get("image", "")
if url:
    print(url); raise SystemExit(0)
raise SystemExit("No image URL in output: " + json.dumps(data))
')

# Download to output path
mkdir -p "$(dirname "$OUTPUT")"
curl -fsSL "$IMAGE_URL" -o "$OUTPUT"
echo "  → saved $OUTPUT"

# Compress in-place if pillow is available (target ≤300 KB)
python3 - "$OUTPUT" <<'PYEOF' 2>/dev/null || true
import sys
from pathlib import Path
try:
    from PIL import Image
    p = Path(sys.argv[1])
    img = Image.open(p)
    img.save(p, format="PNG", optimize=True, compress_level=9)
    kb = p.stat().st_size // 1024
    print(f"  → compressed {p.name} ({kb} KB)")
except Exception:
    pass
PYEOF
