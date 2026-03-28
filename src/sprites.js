export const DRAGON_SHEET = {
  cols: 3,
  rows: 4,
  frameWidth: 341,
  frameHeight: 256,
  totalFrames: 12,
  idleFrames: [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
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
  width: 280,
  height: 220,
};

// === VFX IMPACT FRAMES ===
// Each vfxKey maps to a source image and crop region for the impact overlay.
// Crop coordinates (x, y, w, h) define the rectangle in the source sheet.
// The crop is displayed at 200x200px on screen with mix-blend-mode: screen.
export const VFX_FRAMES = {
  MAGMA_BREATH: {
    src: '/assets/vfx/fire_effects.png',
    sheet: { w: 1024, h: 1024 },
    crop: { x: 0, y: 512, w: 512, h: 256 },
    filter: 'brightness(0.8) contrast(1.3)',
  },
  FLAME_WALL: {
    src: '/assets/vfx/fire_effects.png',
    sheet: { w: 1024, h: 1024 },
    crop: { x: 0, y: 768, w: 1024, h: 256 },
    filter: 'brightness(0.8) contrast(1.3)',
  },
  FROST_BITE: {
    src: '/assets/vfx/ice_crystals.png',
    sheet: { w: 1024, h: 1536 },
    crop: { x: 0, y: 768, w: 512, h: 384 },
    filter: null,
  },
  BLIZZARD: {
    src: '/assets/vfx/ice_crystals.png',
    sheet: { w: 1024, h: 1536 },
    crop: { x: 0, y: 1152, w: 1024, h: 384 },
    filter: null,
  },
  LIGHTNING_STRIKE: {
    src: '/assets/vfx/storm_lightning.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 512, y: 512, w: 512, h: 256 },
    filter: null,
  },
  THUNDER_CLAP: {
    src: '/assets/vfx/storm_lightning.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 1024, y: 0, w: 512, h: 256 },
    filter: null,
  },
  ROCK_SLIDE: {
    src: '/assets/vfx/stone_meteor.png',
    sheet: { w: 1024, h: 1536 },
    crop: { x: 0, y: 384, w: 512, h: 384 },
    filter: 'brightness(0.7) contrast(1.4)',
  },
  EARTHQUAKE: {
    src: '/assets/vfx/stone_explosion.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 0, y: 640, w: 512, h: 256 },
    filter: 'brightness(0.7) contrast(1.4)',
  },
  ACID_SPIT: {
    src: '/assets/vfx/venom_splash.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 256, y: 256, w: 512, h: 256 },
    filter: null,
  },
  TOXIC_CLOUD: {
    src: '/assets/vfx/venom_cloud.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 384, y: 256, w: 512, h: 384 },
    filter: null,
  },
  SHADOW_STRIKE: {
    src: '/assets/vfx/shadow_flames.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 0, y: 384, w: 512, h: 256 },
    filter: null,
  },
  VOID_PULSE: {
    src: '/assets/vfx/shadow_flames.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 512, y: 384, w: 512, h: 256 },
    filter: null,
  },
  VOID_RIFT: {
    src: '/assets/vfx/shadow_flames.png',
    sheet: { w: 1536, h: 1024 },
    crop: { x: 512, y: 384, w: 512, h: 256 },
    filter: 'hue-rotate(180deg) saturate(1.5)',
  },
  NULL_REFLECT: null, // CSS-only reflect shield effect
  BASIC_ATTACK: null, // CSS-only, no sprite
};
