# Dragon Forge — Asset Generation Style Reference

## Measured sprite dimensions (from existing assets)
- Dragon portrait: 1024×1024 single image (existing magma/ice/lightning/stone/venom/shadow)
- Dragon stage sheet (new): 1024×256 total, 4 frames horizontal, each frame 256×256px
- NPC idle: ~250×280 single frame (existing firewall_sentinel, bit_wraith, glitch_hydra)
- NPC attack: ~285×406 single frame
- NPC battle sheet (new): 1024×256 total, 4 frames horizontal, each frame 256×256px

## Style keywords (use in every prompt)
pixel art, 2D side-view, dark tech-fantasy aesthetic, transparent background,
clean pixel outlines, no anti-aliasing artifacts, no text, no borders, no frame numbers

## Stage size progression
- Stage 1 (Baby):    small, 40–50% of frame filled, crouched/curious, stumpy wings
- Stage 2 (Juvenile): medium, 65% frame fill, upright, small wings spread, alert
- Stage 3 (Adult):   large, 85% frame fill, powerful stance, wings half-extended
- Stage 4 (Elder):   massive, 100% frame fill, wings fully spread, glowing eyes, radiates element energy

## Element visual guides
- fire:   lava-cracked scales, magma glow core, orange/red dorsal spines         #ff6622 #ff8844
- ice:    translucent blue crystal scales, frozen breath trail, icicle horns      #44aaff #66ccff
- storm:  purple-black scales, arcing lightning across body, glowing yellow eyes  #aa66ff #cc88ff
- stone:  grey-brown rock-plated hide, moss in crevices, amber eyes               #aa8844 #ccaa66
- venom:  sickly green scales, dripping fangs, toxic cloud fringe                 #44cc44 #66ee66
- shadow: near-black form, purple void-fire eyes, partially transparent at edges  #8844aa #aa66cc

## Inference settings
- Model:    seedream-4.5
- Negative: blurry, watermark, text, border, frame number, photorealistic, 3D, extra limbs
- Dragon stage sheet:  --width 1024 --height 256
- NPC single frame:    --width 256  --height 256
- NPC idle sheet:      --width 1024 --height 256
- Particle texture:    --width 64   --height 64
- Corruption overlay:  --width 256  --height 256

## Output spec
- Format: PNG, RGBA transparent background (or pure black #000000)
- Frames: horizontal, left to right, no margins between frames
- Consistent character size across all stages of the same element
