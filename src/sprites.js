import { assetUrl } from './utils';

// Historical 3×4 sheet math. Live stage portraits are single painted frames.
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

// P1 battle actors: 15 frames × 96px in one row.
// 0-3 idle, 4-9 attack, 10-11 hurt, 12-14 faint.
export const BATTLE_SHEET = {
  frameWidth: 96,
  frameHeight: 96,
  cols: 15,
  rows: 1,
  totalFrames: 15,
  frameDuration: 140,
  poses: {
    idle: { start: 0, count: 4 },
    attack: { start: 4, count: 6 },
    hurt: { start: 10, count: 2 },
    faint: { start: 12, count: 3 },
  },
};

export function isBattleSheet(src) {
  return /_battle\.(png|webp)/i.test(String(src || ''));
}

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

// HEARTFORGE and ABSOLUTE_ZERO have authored strips. The rest still copy pixels.
export const VFX_PLACEHOLDERS = {
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
  HEARTFORGE:       strip('heartforge'),
  ABSOLUTE_ZERO:    strip('absolute_zero'),
  OVERCLOCK:        strip('overclock'),
  BASTION:          strip('bastion'),
  HEMOTOXIN:        strip('hemotoxin'),
  PHASE_STRIKE:     strip('phase_strike'),
  SIPHON_RIFT:      strip('siphon_rift'),
  RESTORATION:      strip('restoration'),
  RECOMPILE:        strip('recompile'),
  NULL_REFLECT: null,
  BASIC_ATTACK: null,
};
