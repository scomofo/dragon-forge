# Synthesis Dragon — incoming art drop

Drop the 4 ChatGPT-generated PNGs **here** with these exact names:

```
synthesis_stage1.png   (Baby)
synthesis_stage2.png   (Juvenile)
synthesis_stage3.png   (Adult)
synthesis_stage4.png   (Elder)
```

Then run:

```bash
python tools/asset_gen/place_synthesis.py
```

That converts/compresses each and copies it into both build trees:
- `public/assets/dragons/synthesis_stageN.png`  (browser)
- `dragon-forge-godot/assets/dragons/synthesis_stageN.png`  (Godot)

Tell Claude when done — it will flip `gameData.js` off the void placeholders
and run the asset-manifest test.

## Style target (match the void dragons)
- Side view, facing **left**, single dragon centred
- Plain flat near-white background (~#f3f3f3)
- Crystalline body + **radiant golden inner light** (void+light fusion)
- Gold hexagonal vein network, gold sparkle motes, gold ground-ripple rings
- Amber/gold glowing eyes
- Baby = chibi sitting upright; Elder = full wingspan, radiant halo
