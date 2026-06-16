# Dragon Forge — To Do

## Recent Browser QA
- [x] Forge hub refactor: scene/overlays/movement split, CSS extracted, truthful station copy
- [x] Browser Playwright smoke: desktop/tablet/mobile screenshots and overflow checks
- [x] Asset manifest test: runtime dragon, NPC, egg, arena, and boss references checked under public/
- [x] Bespoke Void Dragon evolution sprites: generated void_stage1–4.png (near-transparent crystalline form, white-gold fractures)

## Completed
- [x] Intro page text repeats — fixed
- [x] Egg animations janky — fixed
- [x] Fusion tiles off-center — fixed
- [x] VFX impact overlay target — fixed
- [x] Felix portrait metadata/bg — fixed
- [x] Dragon sizing — fixed
- [x] Code review fixes — XP, hatchery skip, counter, scraps guard, dead code, CSS
- [x] New NPCs — 5 integrated with filtered sprites
- [x] Element arenas — copied from handoff
- [x] Special arenas — copied, gravity chamber for final boss
- [x] Egg sheets — 4 updated from handoff
- [x] Per-stage sprite paths — stageSprites data added, getDragonSprite helper
- [x] Theme song — integrated as title music
- [x] SFX generation guide — written to handoff/
- [x] Gene Scrambler — copied to assets/vfx
- [x] CSS split — 10 per-screen modules
- [x] Responsive design — tablet + mobile breakpoints
- [x] Keyboard navigation — focus-visible + onKeyDown
- [x] Shop screen — buy items, forge with cores, core drops from battles

## Needs Art Generation
- [x] 24 dragon evolution sprite sheets — all 8 elements × 4 stages done (fire/ice/storm/stone/venom/shadow/void/light)
- [x] 10 NPC sprite sheets — all 9 campaign NPCs done (idle + attack)
- [x] Mirror Admin unique sprites — `mirror_admin_sprites.png` + `mirror_admin_attack.png`

## Remaining
- [x] Integrate forge/workshop prop art into shop screen background/decoration
- [x] Integrate sci-fi lab equipment art into fusion screen decoration
- [x] Dragon Bounties RPG sheet — used as hatchery background decoration
- [x] Improve hatching animation — 12-step sequence with glow, shake, burst, reveal CSS phases

## Combat & Hatch VFX Overhaul
- [x] Attack VFX now play animated 4-frame projectile sheets that travel across the
      arena (VfxOverlay rAF travel + frame-step + impact pop). Replaced the old
      single mis-cropped concept-art flash. Fixed the stale VFX_FRAMES sheet/crop
      metadata bug (e.g. fire_effects.png is 1024×1024, not 1774×887).
- [x] Procedural placeholder strips for all 15 attacks via tools/asset_gen/make_vfx_strips.py
      → public/assets/vfx/vfx_<move>.png (covered by assetManifest.test.js).
- [x] Defense: flat shield circle → layered energy aegis (dome + dashed rotating
      ring + sweeping arc + deflect ripple), element-tinted.
- [x] Hatching: egg-shell shatter on burst + light flash + radiant rays + sparkle
      motes (eggBurst), plus a rotating light-ray backdrop behind the reveal.
- [x] High-fidelity hand-art VFX sheets — all 15 generated via ChatGPT
      (GPT-image, 4-frame transparent sheets) and keyed/normalized to 1024x256
      with tools/asset_gen/process_vfx_download.py (white-background flood-fill
      key + resize). These replaced the procedural placeholders in
      public/assets/vfx/. Pipeline: prompt ChatGPT for a 4-frame sheet -> in-page
      fetch+download the PNG -> process_vfx_download.py <file> <move>.
      Alternative fal pipeline (gen_vfx_sheets.sh) remains available but unused.
