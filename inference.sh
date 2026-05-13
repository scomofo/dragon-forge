#!/usr/bin/env bash
# inference.sh — wrapper around infsh CLI for Dragon Forge asset generation scripts.
# Usage: bash inference.sh --model <id> --prompt <text> [--negative <text>] \
#                          [--width <px>] [--height <px>] --output <file.png>

set -euo pipefail

INFSH="$HOME/.local/bin/infsh"

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

# Map model shorthand to infsh app ID
case "$MODEL" in
  seedream-4.5|seedream)  APP_ID="bytedance/seedream-4-5" ;;
  seedream-4.0)           APP_ID="bytedance/seedream-4-0" ;;
  flux)                   APP_ID="falai/flux-dev-lora" ;;
  flux-klein)             APP_ID="pruna/flux-klein-4b" ;;
  *)                      APP_ID="bytedance/seedream-4-5" ;;  # default
esac

# Build input JSON (negative_prompt only if provided)
if [[ -n "$NEGATIVE" ]]; then
  INPUT_JSON=$(printf '{"prompt":%s,"negative_prompt":%s,"width":%d,"height":%d}' \
    "$(printf '%s' "$PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
    "$(printf '%s' "$NEGATIVE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
    "$WIDTH" "$HEIGHT")
else
  INPUT_JSON=$(printf '{"prompt":%s,"width":%d,"height":%d}' \
    "$(printf '%s' "$PROMPT" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
    "$WIDTH" "$HEIGHT")
fi

# Run inference and capture JSON (strip ANSI banner lines before the first '{')
RESULT=$("$INFSH" app run "$APP_ID" --input "$INPUT_JSON" --json 2>/dev/null \
  | sed -n '/^{/,$ p')

# Extract image URL
IMAGE_URL=$(printf '%s' "$RESULT" | python3 -c '
import json, sys
data = json.load(sys.stdin)
url = data.get("output", {}).get("image", "")
if not url:
    raise SystemExit("No image URL in output: " + json.dumps(data))
print(url)
')

# Download to output path
mkdir -p "$(dirname "$OUTPUT")"
curl -fsSL "$IMAGE_URL" -o "$OUTPUT"
echo "  → saved $OUTPUT"
