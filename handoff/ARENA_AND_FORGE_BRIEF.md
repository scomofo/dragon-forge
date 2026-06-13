# Arena & Forge Background — Art Generation Brief

## Status

| Asset | Status | File |
|-------|--------|------|
| magma (fire) arena | ✅ Done | `assets/arenas/magma.png` |
| ice arena | ✅ Done | `assets/arenas/ice.png` |
| shadow arena | ✅ Done | `assets/arenas/shadow.png` |
| stone arena | ✅ Done | `assets/arenas/stone.png` |
| venom arena | ✅ Done | `assets/arenas/venom.png` |
| lightning (storm) arena | ✅ Done | `assets/arenas/lightning.png` |
| gravity chamber (final boss) | ⚠️ Medium quality (696×344) | `assets/arenas/gravity_chamber.png` |
| glitch_hydra NPC arena (storm) | ❌ Needs generation | `assets/arenas/storm.png` → replace current |
| forge background | ❌ Needs generation | `assets/backgrounds/forge_bg.png` (new file) |

---

## Shared Arena Specs

- **Size:** 1024×1024 pixels
- **Style:** 16-bit pixel art, high contrast, moody atmosphere
- **Perspective:** Slight top-down/battlefield angle — flat ground plane visible in the lower third, dramatic sky or environment above
- **Usage:** Displayed as a CSS `background: center/cover` behind battle sprites. The lower half is where sprites stand; the upper half is scenery.
- **No characters or dragons in the scene.** Environment only.

---

## 1. Storm / Lightning Arena

**Filename:** `assets/arenas/storm.png` (replaces current 352×150 placeholder)

> 1024×1024 pixel art battle arena. A stormy sky arena on a shattered floating rock platform above storm clouds. Purple-black storm clouds fill the upper two-thirds, lit from within by branching lightning bolts in electric blue and violet (#7b5fff, #44ccff). The lower third is a cracked dark stone platform with storm debris — broken stone tiles, puddles reflecting lightning, wisps of electricity crackling at the edges. The horizon glows a sickly electric green. 16-bit pixel art style, high contrast, dramatic lighting. No characters. Color palette: #0a0a1f (void black), #1a1040 (deep purple), #7b5fff (electric violet), #44ccff (arc blue), #2a2a4a (storm stone).

---

## 2. Forge Background

**Filename:** `assets/backgrounds/forge_bg.png` (new file — will be used as the forge screen background)
**Display size:** Fills 100% of screen, approximately 1920×1080 aspect ratio content
**Recommended generation size:** 1024×1024 (CSS `cover` will crop to fit)

> 1024×1024 pixel art background for a sci-fi dragon forge interior. A wide underground workshop with a vaulted ceiling of exposed cables and conduit pipes. The rear wall is rough stone with embedded circuit-board patterns glowing faintly orange (#ff5a1f) and cyan (#5edcff). A massive anvil silhouette dominates the left background, lit by ember glow from below. The floor is dark metal plate with a subtle grid pattern. Scattered forge equipment — bellows, cable-wrapped columns, glowing canisters — frame the scene. The overall palette is warm charcoal: #1a1208 (floor), #2a1d14 (walls), #3a2a1f (mid), with ember orange (#ff5a1f) and console green (#5cff8a) accent glows from equipment. Atmosphere: warm underlit, slight haze, industrial-mystical. 16-bit pixel art style. No characters.

---

## 3. Gravity Chamber (upgrade, optional)

**Filename:** `assets/arenas/gravity_chamber.png` (replaces current 696×344)

> 1024×1024 pixel art battle arena. A zero-gravity void chamber — a cubic room made of dark chrome panels with glowing purple seams (#9933ff). The floor and ceiling curve away at the edges suggesting infinite depth. Floating debris — broken circuits, fractured stone chunks — drift in slow suspension. A massive singularity rift tears through the center background, a swirling void of deep blue-black with violet corona. Faint grid lines on the walls pulse with energy. 16-bit pixel art, extremely high contrast. Color palette: #08050f (deep void), #1a0a2e (purple-black), #9933ff (singularity purple), #4400cc (deep violet), #44aaff (energy arc blue), #222233 (chrome panel).

---

## How to integrate once generated

### Storm arena
1. Save as `assets/arenas/storm.png`
2. Already wired — `glitch_hydra` in `src/gameData.js` still uses `npc_glitch_hydra.png` (352×150). After copying storm.png, update that line to:
   ```js
   arena: assetUrl('/assets/arenas/storm.png'),
   ```

### Forge background
1. Create `assets/backgrounds/` directory
2. Save as `assets/backgrounds/forge_bg.png`
3. In `src/styles/forge.css`, update `.forge-screen` background:
   ```css
   .forge-screen {
     background:
       linear-gradient(180deg, rgba(26,18,8,0.82) 0%, rgba(42,29,20,0.72) 60%, rgba(58,42,31,0.68) 100%),
       url('/assets/backgrounds/forge_bg.png') center / cover no-repeat;
   }
   ```
   The gradient overlay preserves readability of the interactive elements while the image shows through.

### Gravity chamber
Replace `assets/arenas/gravity_chamber.png` directly. No code changes needed.
