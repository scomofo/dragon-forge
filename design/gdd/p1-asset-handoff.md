# P1 Asset Handoff

> **Status**: Binding production brief — 2026-09-02
> **Owner**: SNES-AAA P1
> **Code twins**: `src/artBible.js`, `src/p1BattleSheets.js`, `src/sprites.js`
> **Reject filter**: `design/gdd/art-bible.md`
> **Progress**: `design/gdd/p1-battle-frames.md`

This file is the image-spec sheet for anyone generating battle art (Retro Diffusion, an artist, or a later pass). Journal portraits stay painted. Everything that stands in an arena must match this contract.

---

## Tool routing

| Job | Tool | Do not use |
|-----|------|------------|
| Identity still + motion cells | [Retro Diffusion](https://retrodiffusion.ai/) — **RD Plus** for stills, **Advanced Animation** (`idle` / `attack` / `custom_action` / `destroy`) for motion | Flux, Ideogram, GPT-Image, Nano Banana, Kling, any “make it pixel art” photo model |
| Background / leftover type cleanup | 1min.ai **Background Remover** / **Text Remover** | 1min.ai Image Generator |
| Upscale | Nearest-neighbor 2× or 3× only | 1min.ai Image Upscaler (blurs the grid) |

`app.1min.ai/image-generator` does **not** expose Retro Diffusion (verified 2026-09-02). That dropdown is Flux-class models. Do not spend those credits on P1 cells.

RD **battle-sprites** style is locked to 64×64. Skip it. Advanced Animation accepts 32–256, so **96×96 works**.

Send the **native** 96 px frame into animation. A 4× display export is 384 px and gets rejected.

---

## Shared register (every battle file)

| Rule | Value |
|------|-------|
| Grammar | 16-bit SNES pixel, 2-px dark outer outline, hard edge |
| Forbidden | Painterly blur, photo texture, chroma-green, checkerboard, watermark, baked UI type, substrings `404` / `error` / `gemini` / `watermark` |
| Camera | 3/4 battle stance, facing **right**, feet planted, readable at 48×48 |
| Background | Transparent |
| Padding | Opaque pixels ≥6 px off every edge (RD animation fails on edge-touch) |
| Scale | Integer only (2× or 3×). Never 1.5× |
| Export | PNG. Convert to WebP at ingest (`assetUrl` rewrites `.png` → `.webp`) |

### Cell sizes (`BATTLE_CELL`)

| Kind | Size | Who |
|------|------|-----|
| Mid actor | **96×96** | Stage-3 dragons, humanoid NPCs |
| Small foe | **64×64** | Tiny critters only |
| Stage-4 / true-final | **128×128** | Not this pass |
| Arena / battleback | **320×176** | One per fight room |
| Signature VFX cell | **256×256** | Four cells in a row |
| Signature VFX strip | **1024×256** | launch → travel → peak → impact, facing right |

Match landed `vfx_heartforge.webp` / `vfx_absolute_zero.webp` if those dimensions differ on disk.

### Actor frame counts (`BATTLE_FRAME_COUNTS`)

| Pose | Frames | Index on a 15-cell strip |
|------|--------|--------------------------|
| Idle | 4 | 0–3 |
| Attack | 6 | 4–9 |
| Hurt | 2 | 10–11 |
| Faint | 3 | 12–14 |

Strip layout: one horizontal row, **1440×96** (15 × 96). Left → right in the table order.

Hue-rotate of another actor is not a new actor. Two dragons that silhouette the same = one is rejected.

---

## Production order

1. **Fire identity still** — stop. Reject or accept on silhouette.
2. Fire motion (idle 4 / attack 6 / hurt 2 / faint 3) from that still as `input_image`.
3. Ice identity + motion (quadruped redraw).
4. Venom → shadow → void → light → synthesis (synthesis last; it is void + light).
5. Seven leftover signature VFX strips.
6. Nine NPC sets at 96².
7. Crop leftover 352×150 arenas.

**Do not generate:** storm or stone battle sheets (bible match already), journal portraits, music, video, Kling clips.

Storm and stone journal portraits may stay winged western dragons. That is a portrait-register mismatch, not a battle-register failure.

---

## Workflow per dragon

1. RD Plus @ 96×96 — one identity still, neutral idle.
2. QC against the body-plan thumbnail read below.
3. Animate from **that file**:
   - Idle — `rd_advanced_animation__idle`, `frames_duration: 8`, keep 4
   - Attack — `rd_advanced_animation__attack`, `frames_duration: 6`, keep 6
   - Hurt — `custom_action`, `frames_duration: 6`, keep 2
   - Faint — `destroy` or `custom_action`, `frames_duration: 6–8`, keep 3
4. Name files. Drop into `artifacts/snes-aaa-p1/dragons/` (or chat). Ingest copies into `public/assets/dragons/` and adds `{id}` to `P1_BATTLE_SHEETS`.

### Filenames

```
{id}_identity.png
{id}_idle_01.png … {id}_idle_04.png
{id}_attack_01.png … {id}_attack_06.png
{id}_hurt_01.png {id}_hurt_02.png
{id}_faint_01.png … {id}_faint_03.png
{id}_stage3_battle.png          # optional 1440×96 strip
```

Shipped runtime name: `public/assets/dragons/{id}_stage3_battle.webp`.

### Shared pose list

**Idle 4** — weight shift, chest/ridge breathe, tail tick, blink. Same silhouette. Feet do not slide.

**Attack 6**

1. Wind-up (mass gathers)
2. Load (limb / jaw / ridge coils)
3. Commit (strike leaves the body)
4. Contact peak (signature tell visible)
5. Follow-through
6. Recover toward idle

**Hurt 2** — recoil + white flash on the outline, then stagger. Same body plan.

**Faint 3** — buckle, hit the ground, dust/crumble hold. Last cell is a readable corpse silhouette, not a fade-to-black.

### Negative prompt (every generation)

```
western dragon, four legs plus wings, painterly, airbrushed, photograph,
3D render, anime, chibi, cute mascot, watermark, text, UI, checkerboard,
green screen, bloom glow, motion blur, extra limbs, second head, human rider
```

### Shared positive prefix

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right, feet planted. Hard pixels, limited palette.
One character, no arena, no text. Readable at 48x48.
```

---

## Dragons

Status key: **redraw** = sheet exists but fails the body plan. **new** = no battle sheet. **landed** = do not regenerate.

### fire — Magma Dragon — REDRAW FIRST

| | |
|---|---|
| Body plan | Hex-scale biped |
| Thumbnail | Wide diamond + horn nubs |
| Notes | Barrel chest, lava-plate shoulders. Two legs. No long neck. No wyvern wings. |
| Palette | Ember orange, slag charcoal, cooling-crust black. Magma only in plate seams. |
| Signature | Heartforge — attack-4 chest plates split, heart of magma shows |
| Current gap | Sheet is a magma kaiju, not the biped |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right, feet planted.
Adult magma dragon as a hex-scale biped: barrel chest, hexagonal lava-plate
armor on shoulders and thighs, short horn nubs, thick plantigrade legs,
stubby tail, no wings, no long neck.
Wide diamond silhouette. Readable at 48x48.
Hard pixels, limited palette: ember orange, slag charcoal, cooling-crust black.
Neutral idle. One character, no arena, no text.
```

**Reject if:** four-legged kaiju, long western neck, bat wings, standing in a lava field, painterly shading.

**Hurt:** `recoil as if punched in the chest plates, brief white outline flash, same hex-scale biped, feet still planted`

**Faint:** `hex-scale biped buckles at the knees, plates crack, collapses into a slag heap, last frame is a readable diamond corpse`

### ice — Ice Dragon — REDRAW

| | |
|---|---|
| Body plan | Faceted quadruped |
| Thumbnail | Long low rectangle + spike row |
| Notes | Crystal ridge spine, low center. Four legs. Not a biped. |
| Palette | Glacier teal, facet white, deep ice-blue. No pastel princess ice. |
| Signature | Absolute Zero — attack-4 breath / ridge flash freezes the air |
| Current gap | Sheet reads upright; want long and low |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right, four feet planted.
Adult ice dragon as a faceted quadruped: low long body, crystal ridge spike-row
along the spine, geometric ice-facet armor, short head, no wings, not standing
on two legs.
Silhouette is a long low rectangle with a spike row. Readable at 48x48.
Hard pixels, limited palette: glacier teal, facet white, deep ice-blue.
Neutral idle. One character, no arena, no text.
```

**Reject if:** upright biped, western ice wyvern, snowy landscape, sparkles instead of facets.

**Hurt:** `low quadruped flinches, ridge crystals flash white, body stays long and low`

**Faint:** `quadruped folds onto the ice, ridge cracks, last frame is a long low frozen carcass`

### storm — Storm Dragon — LANDED

Ribbon / serpentine. Thin S, no legs. Do not regenerate the battle sheet.

### stone — Stone Dragon — LANDED

Block golem. Square stack, tiny head, right angles. Do not regenerate the battle sheet.

### venom — Venom Dragon — NEW

| | |
|---|---|
| Body plan | Frilled wyrm |
| Thumbnail | Hood triangle + whip tail |
| Notes | Cobra hood. Trailing whip tail. No walking legs (vestigial nubs only). |
| Palette | Acid lime, bruise purple, wet-scale olive, fang ivory |
| Signature | Hemotoxin — attack-4 hood flares, spit-line leaves the mouth |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right.
Adult venom dragon as a frilled wyrm: cobra hood triangle, long whip tail,
no walking legs, body coiled so the hood reads at thumbnail.
Silhouette is a hood triangle plus a whip tail. Readable at 48x48.
Hard pixels, limited palette: acid lime, bruise purple, wet olive.
Neutral idle, hood half-open. One character, no arena, no text.
```

**Reject if:** four-legged lizard, biped cobra-man, cute snake, second head.

**Attack motion:** hood flare → coil load → spit commit → venom arc peak → neck recoil → hood settles.

**Hurt:** `hood snaps shut, body whips sideways, white flash on the frill`

**Faint:** `wyrm uncoils and goes slack, hood collapses, last frame is a limp triangle-plus-tail`

### shadow — Shadow Dragon — NEW

| | |
|---|---|
| Body plan | Negative-space gap |
| Thumbnail | Hole in a wolf shape |
| Notes | Broken contour. Missing chunks are true transparency. One pale eye. |
| Palette | Void black, edge-violet, one pale eye |
| Signature | Phase Strike — attack-4 body splits along a hole, claw comes out of the gap |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel dark-violet outline, transparent background,
3/4 battle stance facing right, feet planted.
Adult shadow dragon as a wolf-shaped body with broken contour: missing chunks
in the torso and neck so the background shows through, one pale eye, ragged
mane, not a solid animal.
Silhouette is a hole in a wolf shape. Readable at 48x48.
Hard pixels, limited palette: void black, edge violet, one pale eye.
Neutral idle. One character, no arena, no text.
```

**Reject if:** solid black wolf, bat, smoke cloud with no wolf read, purple western dragon.

**Hurt:** `the holes tear wider, body staggers, eye flashes white`

**Faint:** `the wolf contour breaks into separate shards, last frame is a collapsed hole-shape on the ground`

### void — Void Dragon — NEW

| | |
|---|---|
| Body plan | Hollow crystal tetra |
| Thumbnail | Diamond frame, empty middle |
| Notes | Frame only. Inner glow. No animal head, no wings, no legs. Empty center = transparency. |
| Palette | Cold amethyst frame, inner-glow magenta |
| Signature | Siphon Rift — attack-4 frame opens, a rift pulls inward |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right.
Adult void dragon as a hollow crystal tetrahedron: geometric diamond frame,
empty transparent middle, inner glow only on the inner edges, no animal head,
no wings, no legs.
Silhouette is a diamond frame with an empty middle. Readable at 48x48.
Hard pixels, limited palette: cold amethyst, inner-glow magenta.
Neutral idle, frame hovering just above the ground line. One character, no text.
```

**Reject if:** western dragon made of crystal, solid gem, humanoid, filled-in center (that is Synthesis).

**Attack motion:** frame tilts → edges sharpen → center rift opens → pull peak → edges slam → hover recover.

**Hurt:** `the tetra frame cracks on one edge, inner glow flickers white`

**Faint:** `frame splits into three shards that fall, last frame is a broken diamond on the ground`

### light — Light Dragon — NEW

| | |
|---|---|
| Body plan | Stained-glass winged biped |
| Thumbnail | Wing chevron + pane grid |
| Notes | Hard panes. Lead-came black between panes. Gold/white only — no storm-violet. |
| Palette | Gold, warm white, lead-came black. No soft god-ray blur. |
| Signature | Restoration — attack-4 panes ignite gold-white |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right, feet planted.
Adult light dragon as a stained-glass winged biped: two legs, hard geometric
glass panes on chest and wings, lead-came black lines between panes, wing
chevron silhouette, no feathers, no soft glow bloom.
Silhouette is a wing chevron plus a pane grid. Readable at 48x48.
Hard pixels, limited palette: gold, warm white, lead-came black.
Neutral idle. One character, no arena, no text.
```

**Reject if:** angel, holy western dragon with painted glow, no pane grid, empty diamond (that is Void).

**Hurt:** `panes crack, gold flash on the wing chevron, biped staggers`

**Faint:** `wings fold, panes go dark, last frame is a collapsed chevron of dark glass`

### synthesis — Synthesis — NEW, LAST

| | |
|---|---|
| Body plan | Void frame filled with light panes |
| Thumbnail | Diamond frame + pane fill |
| Notes | Must read as void + light combined, not a tenth animal. |
| Palette | Amethyst frame + gold pane fill |
| Signature | Recompile — attack-4 panes rewrite inside the frame |

**Identity prompt**

```
SNES 16-bit pixel art, 96x96, 2-pixel black outline, transparent background,
3/4 battle stance facing right.
Adult synthesis dragon: hollow diamond crystal frame like the void tetra,
but the empty middle is filled with stained-glass gold-white panes and
lead-came lines. No animal head, no wings, no legs.
Silhouette is a diamond frame with pane fill. Readable at 48x48.
Hard pixels, limited palette: amethyst frame, gold pane fill.
Neutral idle, hovering just above the ground line. One character, no text.
```

**Reject if:** empty middle (Void), winged biped (Light), western fusion dragon.

**Hurt:** `panes inside the frame scramble, frame cracks, gold-then-violet flash`

**Faint:** `panes go dark inside a falling frame, last frame is a dead diamond with black panes`

---

## Signature VFX strips

Four 256×256 cells in a **1024×256** strip, facing right: launch → travel → peak → impact.

Each *signature* needs its own strip. Sharing `FLAME_WALL` or `VOID_RIFT` is a tracked placeholder, not a finish state.

| Id | Move | Element | Status | Tell |
|----|------|---------|--------|------|
| `vfx_heartforge` | Heartforge | fire | authored | Chest-heart magma burst |
| `vfx_absolute_zero` | Absolute Zero | ice | authored | Freezing cone / crystal lock |
| `vfx_overclock` | Overclock | storm | placeholder | Violet-white spark rail |
| `vfx_bastion` | Bastion | stone | placeholder | Stone plate slam / dust ring |
| `vfx_hemotoxin` | Hemotoxin | venom | placeholder | Acid spit-line + drip |
| `vfx_phase_strike` | Phase Strike | shadow | placeholder | Hole-tear claw |
| `vfx_siphon_rift` | Siphon Rift | void | placeholder | Inward rift pull |
| `vfx_restoration` | Restoration | light | placeholder | Gold/white pane flare — not hue-rotated lightning |
| `vfx_recompile` | Recompile | synthesis | placeholder | Frame rewrite / pane scramble |

Light VFX must read gold/white. Storm VFX must read violet-white. No hue-rotate of lightning to fake radiance.

Filename: `public/assets/vfx/vfx_{id}.webp`.

---

## NPCs (second pass, after one dragon set is accepted)

Same cell (96×96), same outline, same 15-frame contract. No printed words on shields, banners, or hulls.

RD is stronger on humanoids than on dragons. Do these after fire identity passes.

| Id | Name | Element | Silhouette note |
|----|------|---------|-----------------|
| `firewall_sentinel` | Firewall Sentinel | stone | Blank-shield knight. Attack cell is still idle — needs attack/hurt/faint. No printed 404. |
| `bit_wraith` | Bit Wraith | shadow | Ragged data-wraith, not a hue-rotated shadow dragon |
| `glitch_hydra` | Glitch Hydra | storm | Multi-head signal hydra |
| `recursive_golem` | Recursive Golem | stone | Distinct from stone dragon (block golem). Nested cubes / recursion motif |
| `buffer_overflow` | Buffer Overflow | fire | Volatile barrel / overflow construct |
| `crypto_crab` | Crypto Crab | ice | Low crab, not an ice dragon |
| `logic_bomb` | Logic Bomb | fire | Fuse/timer body, not a magma biped |
| `phishing_siren` | Phishing Siren | venom | Lure silhouette, not a frilled wyrm |
| `protocol_vulture` | Protocol Vulture | shadow | Bird of prey, not the holed wolf |

NPC filenames:

```
npc/{id}_idle_01.png …
npc/{id}_stage3_battle.png
```

Runtime today is split `idleSprite` + `attackSprite`. New work ships as one 15×96 strip per id, same as dragons.

Boss extras (later): second attack cell + phase-change cell for Singularity / Mirror Admin. Hue-rotate is not a phase.

---

## Arenas

| Rule | Value |
|------|-------|
| Native | **320×176** (SNES-ish 16:9 battleback). 256×144 acceptable |
| Forbidden | Leftover labels (`FIRE-MAGMA`, `MAGMA DRAGON`), grid paper, generator sparkle, Gemini watermark, 352×150 concept crops |
| Count | One arena per zone plus one unique room per zone-boss and true-final |
| Forbidden shortcut | Hue-rotate of `shadow.webp` is not a Singularity room |

Landed (no leftover type): `fire`, `magma`, `ice`, `stone`, `gravity_chamber`, `npc_firewall_sentinel`.

Remaining: crop any leftover 352×150 concept arenas; unique rooms for unset NPCs / bosses.

---

## Eggs (not this pass)

Six authored frames: idle, glow, hairline, crack, shatter, empty. Construction leftovers (grey circle over a frame, scratch lines, duplicate poses) fail QA.

---

## Ingest checklist

A drop is accepted only if:

- [ ] Native 96×96 (or 320×176 / 1024×256 for arena / VFX)
- [ ] Transparent background, no checkerboard, no watermark, no type
- [ ] Body-plan silhouette matches the table at 48×48
- [ ] Feet planted, 3/4 camera, facing right
- [ ] 15 cells in bible order (or 4 VFX cells in bible order)
- [ ] File named per the patterns above
- [ ] Copied to `public/assets/…` and listed in `P1_BATTLE_SHEETS` / VFX map

Binaries do not travel through the GitHub text API. Art drop lives in the project folder `snes-aaa-p1/` and must be copied into `public/assets/`.
