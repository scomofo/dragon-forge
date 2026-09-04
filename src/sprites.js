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

// Authored 1024x256 signature strips (P1) — generated into public/assets/vfx/
// as vfx_sig_<key>.png. Attached alongside `signature:` so the overlay prefers
// the authored strip and keeps the procedural contract as documented fallback.
const sigStrip = (key, frames = 4) => ({
  strip: { src: assetUrl(`/assets/vfx/vfx_sig_${key}.png`), frames },
});

// P1.2 — every signature ships its own authored VFX identity. These are
// procedural contracts (palette + motif + motion) so no two signatures share
// another move's strip. When 1024×256 signature strips land in
// public/assets/vfx/, add `strip:` alongside `signature:` — the overlay
// prefers the strip and keeps the procedural look as fallback.
const signature = (label, palette, motif, motion) => ({
  signature: { label, palette, motif, motion },
});

export const SIGNATURE_VFX = {
  HEARTFORGE:   signature('Heartforge',   ['#ff5a1f', '#ffaa00', '#7a1e00'], 'anvil-ring',         'rise'),
  ABSOLUTE_ZERO: signature('Absolute Zero', ['#ccf4ff', '#44aaff', '#0a2a4a'], 'snowflake-collapse', 'implode'),
  OVERCLOCK:    signature('Overclock',    ['#e8dcff', '#7b5fff', '#1a1040'], 'gear-spark',          'zigzag'),
  BASTION:      signature('Bastion',      ['#e8d5a8', '#aa8844', '#3a2a18'], 'wall-brick',          'fortify'),
  HEMOTOXIN:    signature('Hemotoxin',    ['#baff5c', '#33cc44', '#0a2a10'], 'fang-drip',           'drip'),
  PHASE_STRIKE: signature('Phase Strike', ['#d5a8ff', '#6633aa', '#08000f'], 'rift-slash',          'blink'),
  SIPHON_RIFT:  signature('Siphon Rift',  ['#66ffff', '#0099aa', '#001a20'], 'vortex-drain',        'spiral'),
  RESTORATION:  signature('Restoration',  ['#fff6cc', '#FFD966', '#7a5c00'], 'pane-bloom',          'bloom'),
  RECOMPILE:    signature('Recompile',    ['#f0e0ff', '#c8a8e0', '#2a1a40'], 'diamond-weave',       'weave'),
};

// P1.2 clears this map: no signature shares another move's strip.
export const VFX_PLACEHOLDERS = {};

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
  HEARTFORGE:       { ...SIGNATURE_VFX.HEARTFORGE, ...sigStrip('heartforge') },
  ABSOLUTE_ZERO:    { ...SIGNATURE_VFX.ABSOLUTE_ZERO, ...sigStrip('absolute_zero') },
  OVERCLOCK:        { ...SIGNATURE_VFX.OVERCLOCK, ...sigStrip('overclock') },
  BASTION:          { ...SIGNATURE_VFX.BASTION, ...sigStrip('bastion') },
  HEMOTOXIN:        { ...SIGNATURE_VFX.HEMOTOXIN, ...sigStrip('hemotoxin') },
  PHASE_STRIKE:     { ...SIGNATURE_VFX.PHASE_STRIKE, ...sigStrip('phase_strike') },
  SIPHON_RIFT:      { ...SIGNATURE_VFX.SIPHON_RIFT, ...sigStrip('siphon_rift') },
  RESTORATION:      { ...SIGNATURE_VFX.RESTORATION, ...sigStrip('restoration') },
  RECOMPILE:        { ...SIGNATURE_VFX.RECOMPILE, ...sigStrip('recompile') },
  NULL_REFLECT: null,
  BASIC_ATTACK: null,
};

export function isSignatureVfxKey(key) {
  return Object.prototype.hasOwnProperty.call(SIGNATURE_VFX, key);
}

export function getVfxKind(key) {
  const entry = VFX_FRAMES[key];
  if (!entry) return 'legacy';
  if (entry.strip) return 'strip';
  if (entry.signature) return 'signature';
  return 'legacy';
}

export function listSignatureVfxKeys() {
  return Object.keys(SIGNATURE_VFX);
}
