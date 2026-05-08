# Dragon Forge Godot Rebuild — Plan 6: Asset Generation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Generate all missing dragon evolution sprite sheets and NPC sprite sheets using the inference CLI, place them in `assets/` and `dragon-forge-godot/assets/`, and update `data/sprite_manifest.json` so both builds can resolve every sprite path.

**Architecture:** Generation is driven by three shell scripts under `tools/asset_gen/`. Each script calls `inference.sh` with parameterized prompts per element/stage/NPC. Approved output PNGs are committed into `assets/` at the repo root; the Godot project references them via `res://assets/` (Godot copies from the root `assets/` folder into `dragon-forge-godot/assets/` as needed — both paths are updated). After generation, `data/sprite_manifest.json` is updated with the real paths, replacing the `placeholder.png` entries written by Plan 5.

**Tech Stack:** `inference.sh` CLI (FLUX Dev LoRA / Seedream 4.5 / Reve), Bash, ImageMagick (`magick` for sprite sheet assembly if frames are generated individually), Godot 4.6 import pipeline.

**Prerequisite:** Plan 4 complete — `data/sprite_manifest.json` exists with placeholder entries. You have access to the `inference.sh` CLI and can run it from the repo root.

---

## Task 1: Style Reference Document

Establish the exact visual spec before writing any generation prompt.

**Files:**
- Create: `tools/asset_gen/style_reference.md`

- [ ] **Step 1.1 — Measure existing dragon sprites**

Open the following files in an image viewer and record their pixel dimensions and frame counts:

```
assets/dragons/magma.png
assets/dragons/ice.png
assets/dragons/lightning.png
assets/dragons/stone.png
assets/dragons/venom.png
assets/dragons/shadow.png
```

Also open:

```
assets/npc/firewall_sentinel_sprites.png
assets/npc/firewall_sentinel_attack.png
assets/npc/bit_wraith_sprites.png
assets/npc/glitch_hydra_sprites.png
```

Record: total image width × height, number of frames per row, frame size in px.

- [ ] **Step 1.2 — Record color palette per element**

From `src/gameData.js`, the element primary + glow hex values are:

| Element | Primary   | Glow      |
|---------|-----------|-----------|
| fire    | `#ff6622` | `#ff8844` |
| ice     | `#44aaff` | `#66ccff` |
| storm   | `#aa66ff` | `#cc88ff` |
| stone   | `#aa8844` | `#ccaa66` |
| venom   | `#44cc44` | `#66ee66` |
| shadow  | `#8844aa` | `#aa66cc` |

Use these as the dominant color target in every generation prompt.

- [ ] **Step 1.3 — Write the style reference**

Create `tools/asset_gen/style_reference.md` with content exactly as follows (fill in the measured pixel dimensions from Step 1.1):

```markdown
# Dragon Forge — Asset Generation Style Reference

## Measured sprite dimensions (fill in from Step 1.1)
- Dragon sheet: <WIDTH>×<HEIGHT> total, <N> frames horizontal, each frame <FW>×<FH>px
- NPC idle sheet: <WIDTH>×<HEIGHT> total, <N> frames horizontal, each frame <FW>×<FH>px
- NPC attack sheet: <WIDTH>×<HEIGHT> total (may be single frame)

## Style keywords (use in every prompt)
pixel art, 2D side-view, horizontal sprite sheet, dark tech-fantasy aesthetic,
transparent background, clean outlines, no anti-aliasing artifacts, sprites on black
or transparent canvas, each frame identical size

## Stage size progression
- Stage 1 (Baby): small, 40–50% of the frame filled
- Stage 2 (Juvenile): medium, 60–70% of the frame filled
- Stage 3 (Adult): large, 80–90% of the frame filled
- Stage 4 (Elder): massive, 95–100% of the frame, crown or extra appendages

## Stage posture descriptors
- Stage 1: crouched, curious, stumpy wings or no wings
- Stage 2: upright, small wings spread, alert
- Stage 3: powerful stance, wings half-extended, battle-ready
- Stage 4: towering, wings fully spread, glowing eyes, radiates element energy

## Element visual guides
- fire:   lava-cracked scales, magma glow core, orange/red dorsal spines
- ice:    translucent blue crystal scales, frozen breath trail, icicle horns
- storm:  purple-black scales, arcing lightning across body, glowing yellow eyes
- stone:  grey-brown rock-plated hide, moss in crevices, amber eyes
- venom:  sickly green scales, dripping fangs, toxic cloud fringe
- shadow: near-black form, purple void-fire eyes, partially transparent at edges

## Output spec
- Format: PNG
- Background: transparent (RGBA) or pure black (#000000)
- Frames: laid out horizontally, left to right
- No text, no borders, no margins between frames
```

- [ ] **Step 1.4 — Commit style reference**

```bash
git add tools/asset_gen/style_reference.md
git commit -m "Add asset generation style reference"
```

---

## Task 2: Dragon Evolution Sheet Generator

Generate 24 sprite sheets: 6 elements × 4 stages.

**Files:**
- Create: `tools/asset_gen/gen_dragons.sh`

- [ ] **Step 2.1 — Create the generation script**

Create `tools/asset_gen/gen_dragons.sh`:

```bash
#!/usr/bin/env bash
# Dragon evolution sprite sheet generator.
# Usage: bash tools/asset_gen/gen_dragons.sh [element] [stage]
# Omit args to generate all 24 sheets.
# Output: assets/dragons/<element>_stage<N>.png

set -euo pipefail

ELEMENTS=(fire ice storm stone venom shadow)
STAGES=(1 2 3 4)

STAGE_LABELS=(
  [1]="Baby"
  [2]="Juvenile"
  [3]="Adult"
  [4]="Elder"
)

STAGE_DESCRIPTORS=(
  [1]="small crouched hatchling, stumpy wings, curious pose, 40% frame fill"
  [2]="medium upright juvenile, small wings spread, alert stance, 65% frame fill"
  [3]="large powerful adult, wings half-extended, battle-ready, 85% frame fill"
  [4]="massive towering elder, wings fully spread, glowing eyes, radiates element energy, 100% frame fill"
)

ELEMENT_DESCS=(
  [fire]="lava-cracked scales, magma core glow, orange and red dorsal spines, color palette #ff6622 #ff8844"
  [ice]="translucent blue crystal scales, frozen breath trail, icicle horns, color palette #44aaff #66ccff"
  [storm]="purple-black scales, arcing lightning across body, glowing yellow eyes, color palette #aa66ff #cc88ff"
  [stone]="grey-brown rock-plated hide, moss in crevices, amber eyes, color palette #aa8844 #ccaa66"
  [venom]="sickly green scales, dripping fangs, toxic cloud fringe, color palette #44cc44 #66ee66"
  [shadow]="near-black form, purple void-fire eyes, partially transparent edges, color palette #8844aa #aa66cc"
)

TARGET_ELEMENTS=("${@:-${ELEMENTS[@]}}")
# If first arg is an element name and second is a stage number, run just that one.
if [[ $# -eq 2 && " ${ELEMENTS[*]} " == *" $1 "* ]]; then
  TARGET_ELEMENTS=("$1")
  TARGET_STAGES=("$2")
else
  TARGET_STAGES=("${STAGES[@]}")
fi

mkdir -p assets/dragons

for ELEM in "${TARGET_ELEMENTS[@]}"; do
  for STAGE in "${TARGET_STAGES[@]}"; do
    OUT="assets/dragons/${ELEM}_stage${STAGE}.png"
    if [[ -f "$OUT" ]]; then
      echo "[SKIP] $OUT already exists. Delete to regenerate."
      continue
    fi
    PROMPT="pixel art 2D side-view horizontal sprite sheet of a ${STAGE_LABELS[$STAGE]} ${ELEM} dragon, ${STAGE_DESCRIPTORS[$STAGE]}, ${ELEMENT_DESCS[$ELEM]}, 4 frames horizontal idle animation, transparent background, dark tech-fantasy aesthetic, clean pixel outlines, no text no borders"
    echo "[GEN] $OUT"
    echo "  PROMPT: $PROMPT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "blurry, watermark, text, border, frame number, photorealistic, 3D, extra limbs" \
      --width 1024 \
      --height 256 \
      --output "$OUT"
    echo "[DONE] $OUT"
  done
done

echo "All dragon sheets complete."
```

```bash
chmod +x tools/asset_gen/gen_dragons.sh
```

- [ ] **Step 2.2 — Run for fire stage 1 as a pilot**

```bash
bash tools/asset_gen/gen_dragons.sh fire 1
```

Open `assets/dragons/fire_stage1.png`. Verify: correct dimensions, transparent or black background, 4 horizontal frames, appropriate colors. If the output is wrong, adjust the `--prompt` or `--width`/`--height` in the script and re-run (delete the file first to unblock the skip guard).

- [ ] **Step 2.3 — Run for all remaining fire stages**

```bash
bash tools/asset_gen/gen_dragons.sh fire 2
bash tools/asset_gen/gen_dragons.sh fire 3
bash tools/asset_gen/gen_dragons.sh fire 4
```

Review each output before continuing.

- [ ] **Step 2.4 — Run full generation for remaining 5 elements**

```bash
for ELEM in ice storm stone venom shadow; do
  for STAGE in 1 2 3 4; do
    bash tools/asset_gen/gen_dragons.sh "$ELEM" "$STAGE"
  done
done
```

Review samples at each element. If a stage prompt is off, adjust `STAGE_DESCRIPTORS` or `ELEMENT_DESCS` in the script and re-run that combination.

- [ ] **Step 2.5 — Verify all 24 files exist**

```bash
for ELEM in fire ice storm stone venom shadow; do
  for STAGE in 1 2 3 4; do
    [[ -f "assets/dragons/${ELEM}_stage${STAGE}.png" ]] || echo "MISSING: ${ELEM}_stage${STAGE}.png"
  done
done
echo "Verification complete."
```

Expected: no MISSING lines.

- [ ] **Step 2.6 — Commit generation script and generated art**

```bash
git add tools/asset_gen/gen_dragons.sh assets/dragons/
git commit -m "Generate dragon evolution sprite sheets (all 24, 6 elements × 4 stages)"
```

---

## Task 3: NPC Sprite Sheet Generator

Generate 10 sprite sheets for the 5 NPCs that currently use filtered placeholders: `buffer_overflow`, `crypto_crab`, `logic_bomb`, `phishing_siren`, `protocol_vulture`. Each needs an idle sheet and an attack sheet.

**Files:**
- Create: `tools/asset_gen/gen_npcs.sh`

- [ ] **Step 3.1 — Create the generation script**

Create `tools/asset_gen/gen_npcs.sh`:

```bash
#!/usr/bin/env bash
# NPC sprite sheet generator for the 5 missing NPCs.
# Usage: bash tools/asset_gen/gen_npcs.sh [npc_id]
# Omit npc_id to generate all 10 sheets (idle + attack for each).

set -euo pipefail

declare -A NPC_ELEMENT=(
  [buffer_overflow]="fire"
  [crypto_crab]="ice"
  [logic_bomb]="fire"
  [phishing_siren]="venom"
  [protocol_vulture]="shadow"
)

declare -A NPC_DESC=(
  [buffer_overflow]="a glitching humanoid data construct bleeding fire overflow, corrupted fire elemental, red/orange color palette"
  [crypto_crab]="a mechanical ice crab with crystalline shell and freezing breath, blue color palette"
  [logic_bomb]="a volatile floating sphere of compressed fire logic, ticking countdown display on its surface, orange flames"
  [phishing_siren]="a bioluminescent venom serpent with digital lure tendrils, toxic green glow, sleek and predatory"
  [protocol_vulture]="a massive shadow avian daemon with corrupted data-feathers, purple void energy eyes, shadow element"
)

NPCS=(buffer_overflow crypto_crab logic_bomb phishing_siren protocol_vulture)
TARGET_NPCS=("${@:-${NPCS[@]}}")

mkdir -p assets/npc

for NPC in "${TARGET_NPCS[@]}"; do
  DESC="${NPC_DESC[$NPC]}"

  # Idle sprite sheet
  IDLE_OUT="assets/npc/${NPC}_sprites.png"
  if [[ ! -f "$IDLE_OUT" ]]; then
    PROMPT="pixel art 2D side-view enemy sprite sheet, idle animation, ${DESC}, 4 frames horizontal, dark tech-fantasy, transparent background, clean pixel outlines, no text no borders"
    echo "[GEN IDLE] $IDLE_OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "blurry, watermark, text, border, photorealistic, 3D, extra limbs" \
      --width 1024 \
      --height 256 \
      --output "$IDLE_OUT"
    echo "[DONE] $IDLE_OUT"
  else
    echo "[SKIP] $IDLE_OUT"
  fi

  # Attack sprite sheet
  ATTACK_OUT="assets/npc/${NPC}_attack.png"
  if [[ ! -f "$ATTACK_OUT" ]]; then
    PROMPT="pixel art 2D side-view enemy attack pose, single frame, ${DESC}, attack lunging forward, elemental energy burst, dark tech-fantasy, transparent background, clean pixel outlines, no text no borders"
    echo "[GEN ATTACK] $ATTACK_OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "$PROMPT" \
      --negative "blurry, watermark, text, border, photorealistic, 3D" \
      --width 256 \
      --height 256 \
      --output "$ATTACK_OUT"
    echo "[DONE] $ATTACK_OUT"
  else
    echo "[SKIP] $ATTACK_OUT"
  fi
done

echo "All NPC sheets complete."
```

```bash
chmod +x tools/asset_gen/gen_npcs.sh
```

- [ ] **Step 3.2 — Run pilot: buffer_overflow**

```bash
bash tools/asset_gen/gen_npcs.sh buffer_overflow
```

Open `assets/npc/buffer_overflow_sprites.png` and `assets/npc/buffer_overflow_attack.png`. Verify visual consistency with existing NPCs (`firewall_sentinel_sprites.png`). Adjust `NPC_DESC[buffer_overflow]` in the script if needed.

- [ ] **Step 3.3 — Run remaining 4 NPCs**

```bash
for NPC in crypto_crab logic_bomb phishing_siren protocol_vulture; do
  bash tools/asset_gen/gen_npcs.sh "$NPC"
done
```

Review each pair of files.

- [ ] **Step 3.4 — Verify all 10 files exist**

```bash
for NPC in buffer_overflow crypto_crab logic_bomb phishing_siren protocol_vulture; do
  [[ -f "assets/npc/${NPC}_sprites.png" ]] || echo "MISSING IDLE: $NPC"
  [[ -f "assets/npc/${NPC}_attack.png" ]]   || echo "MISSING ATTACK: $NPC"
done
echo "Verification complete."
```

Expected: no MISSING lines.

- [ ] **Step 3.5 — Commit**

```bash
git add tools/asset_gen/gen_npcs.sh assets/npc/
git commit -m "Generate missing NPC sprite sheets (5 NPCs × idle + attack)"
```

---

## Task 4: VFX Particle Texture Generator

Generate 6 element particle textures and 3 singularity corruption overlays.

**Files:**
- Create: `tools/asset_gen/gen_vfx.sh`

- [ ] **Step 4.1 — Create the generation script**

Create `tools/asset_gen/gen_vfx.sh`:

```bash
#!/usr/bin/env bash
# VFX asset generator: element particle textures + singularity corruption overlays.
# Usage: bash tools/asset_gen/gen_vfx.sh

set -euo pipefail

mkdir -p assets/vfx

# Element particle textures (64×64 used as GPUParticles2D texture)
declare -A PARTICLE_PROMPTS=(
  [fire]="pixel art glowing ember particle, single flame fragment, orange and red, transparent background, 64x64"
  [ice]="pixel art ice crystal shard particle, sharp blue edges, cold glow, transparent background, 64x64"
  [storm]="pixel art electric spark particle, jagged lightning bolt shape, purple and yellow, transparent background, 64x64"
  [stone]="pixel art rock fragment particle, angular brown stone chip, earthy tones, transparent background, 64x64"
  [venom]="pixel art toxic droplet particle, green bioluminescent drip, transparent background, 64x64"
  [shadow]="pixel art void smoke particle, wispy dark purple smoke puff, transparent background, 64x64"
)

for ELEM in fire ice storm stone venom shadow; do
  OUT="assets/vfx/particle_${ELEM}.png"
  if [[ ! -f "$OUT" ]]; then
    echo "[GEN PARTICLE] $OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "${PARTICLE_PROMPTS[$ELEM]}" \
      --negative "text, border, watermark, photorealistic, 3D" \
      --width 64 \
      --height 64 \
      --output "$OUT"
    echo "[DONE] $OUT"
  else
    echo "[SKIP] $OUT"
  fi
done

# Singularity corruption overlays (full-screen tint textures 256×256)
declare -A CORRUPTION_PROMPTS=(
  [2]="pixel art digital corruption noise overlay, subtle red static, horizontal scan lines, light distortion, transparent center, dark edges, 256x256"
  [3]="pixel art heavy digital corruption overlay, red and black glitch artifacts, broken data pattern, semi-transparent, 256x256"
  [4]="pixel art extreme void corruption overlay, deep purple and black, total data breakdown, fractured pixel grid, near opaque edges, 256x256"
)

for STAGE in 2 3 4; do
  OUT="assets/vfx/corruption_stage_${STAGE}.png"
  if [[ ! -f "$OUT" ]]; then
    echo "[GEN CORRUPTION] $OUT"
    bash inference.sh \
      --model "seedream-4.5" \
      --prompt "${CORRUPTION_PROMPTS[$STAGE]}" \
      --negative "text, watermark, photorealistic, 3D, characters, dragons" \
      --width 256 \
      --height 256 \
      --output "$OUT"
    echo "[DONE] $OUT"
  else
    echo "[SKIP] $OUT"
  fi
done

echo "All VFX textures complete."
```

```bash
chmod +x tools/asset_gen/gen_vfx.sh
```

- [ ] **Step 4.2 — Run VFX generation**

```bash
bash tools/asset_gen/gen_vfx.sh
```

Review each of the 9 output files. For particle textures, verify they look like distinct element-colored particles with transparent backgrounds. For corruption overlays, verify they are dark and atmospheric without obscuring too much of the screen.

- [ ] **Step 4.3 — Commit**

```bash
git add tools/asset_gen/gen_vfx.sh assets/vfx/particle_*.png assets/vfx/corruption_stage_*.png
git commit -m "Generate element particle textures and singularity corruption overlays"
```

---

## Task 5: Sync Assets to Godot Project

Copy new assets into the Godot assets folder so `res://assets/` resolves them.

- [ ] **Step 5.1 — Copy dragon sheets to Godot assets**

```bash
cp assets/dragons/*_stage*.png dragon-forge-godot/assets/dragons/
```

Verify:

```bash
ls dragon-forge-godot/assets/dragons/ | grep "stage"
```

Expected: 24 files matching `<element>_stage<N>.png`.

- [ ] **Step 5.2 — Copy NPC sheets**

```bash
cp assets/npc/buffer_overflow_sprites.png  dragon-forge-godot/assets/npc/
cp assets/npc/buffer_overflow_attack.png   dragon-forge-godot/assets/npc/
cp assets/npc/crypto_crab_sprites.png      dragon-forge-godot/assets/npc/
cp assets/npc/crypto_crab_attack.png       dragon-forge-godot/assets/npc/
cp assets/npc/logic_bomb_sprites.png       dragon-forge-godot/assets/npc/
cp assets/npc/logic_bomb_attack.png        dragon-forge-godot/assets/npc/
cp assets/npc/phishing_siren_sprites.png   dragon-forge-godot/assets/npc/
cp assets/npc/phishing_siren_attack.png    dragon-forge-godot/assets/npc/
cp assets/npc/protocol_vulture_sprites.png dragon-forge-godot/assets/npc/
cp assets/npc/protocol_vulture_attack.png  dragon-forge-godot/assets/npc/
```

- [ ] **Step 5.3 — Copy VFX textures**

```bash
cp assets/vfx/particle_*.png            dragon-forge-godot/assets/vfx/
cp assets/vfx/corruption_stage_*.png    dragon-forge-godot/assets/vfx/
```

- [ ] **Step 5.4 — Run headless Godot import**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --import
```

Expected: exit code `0`. Godot will generate `.import` metadata for each new PNG.

- [ ] **Step 5.5 — Commit Godot assets + import files**

```bash
git add dragon-forge-godot/assets/
git commit -m "Sync generated art to Godot assets folder and run import"
```

---

## Task 6: Update Sprite Manifest

Replace placeholder entries in `data/sprite_manifest.json` with real paths.

- [ ] **Step 6.1 — Update `dragon-forge-godot/data/sprite_manifest.json`**

Replace the `placeholder.png` paths with the generated stage sprite paths. For each element in the `dragons` section:

```json
"fire": {
  "sheet":  "res://assets/dragons/magma.png",
  "stage1": "res://assets/dragons/fire_stage1.png",
  "stage2": "res://assets/dragons/fire_stage2.png",
  "stage3": "res://assets/dragons/fire_stage3.png",
  "stage4": "res://assets/dragons/fire_stage4.png"
}
```

Repeat for `ice`, `storm`, `stone`, `venom`, `shadow`.

Add the 5 new NPCs to the `npcs` section:

```json
"buffer_overflow":   { "idle": "res://assets/npc/buffer_overflow_sprites.png",   "attack": "res://assets/npc/buffer_overflow_attack.png" },
"crypto_crab":       { "idle": "res://assets/npc/crypto_crab_sprites.png",        "attack": "res://assets/npc/crypto_crab_attack.png" },
"logic_bomb":        { "idle": "res://assets/npc/logic_bomb_sprites.png",         "attack": "res://assets/npc/logic_bomb_attack.png" },
"phishing_siren":    { "idle": "res://assets/npc/phishing_siren_sprites.png",     "attack": "res://assets/npc/phishing_siren_attack.png" },
"protocol_vulture":  { "idle": "res://assets/npc/protocol_vulture_sprites.png",   "attack": "res://assets/npc/protocol_vulture_attack.png" }
```

Add a `vfx` section:

```json
"vfx": {
  "particle_fire":        "res://assets/vfx/particle_fire.png",
  "particle_ice":         "res://assets/vfx/particle_ice.png",
  "particle_storm":       "res://assets/vfx/particle_storm.png",
  "particle_stone":       "res://assets/vfx/particle_stone.png",
  "particle_venom":       "res://assets/vfx/particle_venom.png",
  "particle_shadow":      "res://assets/vfx/particle_shadow.png",
  "corruption_stage_2":   "res://assets/vfx/corruption_stage_2.png",
  "corruption_stage_3":   "res://assets/vfx/corruption_stage_3.png",
  "corruption_stage_4":   "res://assets/vfx/corruption_stage_4.png"
}
```

- [ ] **Step 6.2 — Also update `src/gameData.js` stage sprites**

In `src/gameData.js`, the `stageSprites` paths for each dragon currently reference files like `fire_stage1.png` etc. These should now resolve correctly since `assets/dragons/fire_stage1.png` exists. Verify by running the browser build:

```bash
npm run dev
```

Open `http://localhost:5173` (or whatever port Vite reports), hatch a dragon and confirm stage evolution shows the new sprites.

- [ ] **Step 6.3 — Final smoke test**

```powershell
& 'C:\Users\Scott Morley\Downloads\Godot_v4.6.2-stable_win64.exe\Godot_v4.6.2-stable_win64.exe' --headless --path 'C:\Users\Scott Morley\Dev\df\dragon-forge-godot' --script res://scripts/tests/sim_smoke.gd
```

Expected: exit code `0`.

- [ ] **Step 6.4 — Final commit**

```bash
git add dragon-forge-godot/data/sprite_manifest.json src/gameData.js
git commit -m "Update sprite manifest with real asset paths — Plan 6 complete"
```
