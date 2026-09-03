import { assetUrl } from './utils';

// Historical 3×4 sheet math. Live stage portraits are single painted frames
// (see ACTOR_CONTRACT). Do not slice *_stage[1-4] images with these numbers.
export const DRAGON_SHEET = {
  cols: 3,
  rows: 4,
  frameWidth: 341,
  frameHeight: 256,
  totalFrames: 12,
  lungeFrame: 3,
  frameDuration: 200,
};

export const ACTOR_CONTRACT = {
  stagePortraitsAreSingleFrame: true,
  battleSetWhenShipped: { idle: 4, attack: 6, hurt: 2, faint: 3 },
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

const strip = (move, frames = 4) => ({
  strip: { src: assetUrl(`/assets/vfx/vfx_${move}.png`), frames },
});

// Signature keys that still share another move's strip. P1 clears this map.
export const VFX_PLACEHOLDERS = {
  HEARTFORGE: 'flame_wall',
  ABSOLUTE_ZERO: 'frost_bite',
  OVERCLOCK: 'lightning_strike',
  BASTION: 'rock_slide',
  HEMOTOXIN: 'toxic_cloud',
  PHASE_STRIKE: 'shadow_strike',
  SIPHON_RIFT: 'void_rift',
  RESTORATION: 'solar_flare',
  RECOMPILE: 'void_rift',
};

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
  HEARTFORGE:       strip('flame_wall'),
  ABSOLUTE_ZERO:    strip('frost_bite'),
  OVERCLOCK:        strip('lightning_strike'),
  BASTION:          strip('rock_slide'),
  HEMOTOXIN:        strip('toxic_cloud'),
  PHASE_STRIKE:     strip('shadow_strike'),
  SIPHON_RIFT:      strip('void_rift'),
  RESTORATION:      strip('solar_flare'),
  RECOMPILE:        strip('void_rift'),
  NULL_REFLECT: null,
  BASIC_ATTACK: null,
};
