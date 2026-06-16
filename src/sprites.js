import { assetUrl } from './utils';
export const DRAGON_SHEET = {
  cols: 3,
  rows: 4,
  frameWidth: 341,
  frameHeight: 256,
  totalFrames: 12,
  lungeFrame: 3,
  frameDuration: 200,
};

export const STAGE_SCALES = {
  1: 0.6,
  2: 0.8,
  3: 1.0,
  4: 1.4,
};

export const DRAGON_DISPLAY = {
  width: 320,
  height: 250,
};

// === VFX PROJECTILE SHEETS ===
// Each vfxKey maps to an animated 4-frame projectile strip (1024x256, four
// 256x256 frames laid out horizontally: launch -> travel -> peak -> impact).
// VfxOverlay plays the strip while translating it from attacker to target,
// stepping frames as it flies and holding the impact frame on contact.
//
// Art lives in public/assets/vfx/vfx_<move>.png. Placeholder strips are baked
// by tools/asset_gen/make_vfx_strips.py; high-fidelity hand-art from
// tools/asset_gen/gen_vfx_sheets.sh (fal pipeline) drops in over the same
// filenames. Strips face right; VfxOverlay mirrors them for right-to-left flight.
const strip = (move, frames = 4) => ({
  strip: { src: assetUrl(`/assets/vfx/vfx_${move}.png`), frames },
});

export const VFX_FRAMES = {
  MAGMA_BREATH:     strip('magma_breath'),
  FLAME_WALL:       strip('flame_wall'),
  FROST_BITE:       strip('frost_bite'),
  BLIZZARD:         strip('blizzard'),
  LIGHTNING_STRIKE: strip('lightning_strike'),
  THUNDER_CLAP:     strip('thunder_clap'),
  ROCK_SLIDE:       strip('rock_slide'),
  EARTHQUAKE:       strip('earthquake'),
  ACID_SPIT:        strip('acid_spit'),
  TOXIC_CLOUD:      strip('toxic_cloud'),
  SHADOW_STRIKE:    strip('shadow_strike'),
  VOID_PULSE:       strip('void_pulse'),
  VOID_RIFT:        strip('void_rift'),
  RADIANT_BEAM:     strip('radiant_beam'),
  SOLAR_FLARE:      strip('solar_flare'),
  NULL_REFLECT: null, // CSS-only reflect shield effect
  BASIC_ATTACK: null, // CSS-only melee slash, no projectile
};
