// === ELEMENTS ===
export const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow'];

// === TYPE EFFECTIVENESS ===
// typeChart[attacker][defender] = multiplier
export const typeChart = {
  fire:   { fire: 0.5, ice: 2.0, storm: 1.0, stone: 0.5, venom: 2.0, shadow: 1.0 },
  ice:    { fire: 0.5, ice: 0.5, storm: 2.0, stone: 1.0, venom: 1.0, shadow: 2.0 },
  storm:  { fire: 1.0, ice: 0.5, storm: 0.5, stone: 2.0, venom: 1.0, shadow: 2.0 },
  stone:  { fire: 2.0, ice: 1.0, storm: 0.5, stone: 0.5, venom: 2.0, shadow: 1.0 },
  venom:  { fire: 0.5, ice: 1.0, storm: 1.0, stone: 0.5, venom: 0.5, shadow: 2.0 },
  shadow: { fire: 1.0, ice: 0.5, storm: 0.5, stone: 1.0, venom: 0.5, shadow: 0.5 },
};

// === STAGE MULTIPLIERS ===
export const stageMultipliers = { 1: 0.5, 2: 0.75, 3: 1.0, 4: 1.4 };

// === STAGE THRESHOLDS ===
export const stageThresholds = { 2: 10, 3: 25, 4: 50 };

// === MOVES ===
export const moves = {
  // Fire
  magma_breath:     { name: 'Magma Breath',     element: 'fire',   power: 65, accuracy: 95, vfxKey: 'MAGMA_BREATH' },
  flame_wall:       { name: 'Flame Wall',        element: 'fire',   power: 55, accuracy: 100, vfxKey: 'FLAME_WALL' },
  // Ice
  frost_bite:       { name: 'Frost Bite',        element: 'ice',    power: 60, accuracy: 100, vfxKey: 'FROST_BITE' },
  blizzard:         { name: 'Blizzard',          element: 'ice',    power: 70, accuracy: 85, vfxKey: 'BLIZZARD' },
  // Storm
  lightning_strike: { name: 'Lightning Strike',  element: 'storm',  power: 70, accuracy: 90, vfxKey: 'LIGHTNING_STRIKE' },
  thunder_clap:     { name: 'Thunder Clap',      element: 'storm',  power: 55, accuracy: 100, vfxKey: 'THUNDER_CLAP' },
  // Stone
  rock_slide:       { name: 'Rock Slide',        element: 'stone',  power: 60, accuracy: 95, vfxKey: 'ROCK_SLIDE' },
  earthquake:       { name: 'Earthquake',        element: 'stone',  power: 75, accuracy: 85, vfxKey: 'EARTHQUAKE' },
  // Venom
  acid_spit:        { name: 'Acid Spit',         element: 'venom',  power: 60, accuracy: 100, vfxKey: 'ACID_SPIT' },
  toxic_cloud:      { name: 'Toxic Cloud',       element: 'venom',  power: 70, accuracy: 85, vfxKey: 'TOXIC_CLOUD' },
  // Shadow
  shadow_strike:    { name: 'Shadow Strike',     element: 'shadow', power: 65, accuracy: 95, vfxKey: 'SHADOW_STRIKE' },
  void_pulse:       { name: 'Void Pulse',        element: 'shadow', power: 75, accuracy: 85, vfxKey: 'VOID_PULSE' },
  // Neutral
  basic_attack:     { name: 'Basic Attack',      element: 'neutral', power: 40, accuracy: 100, vfxKey: 'BASIC_ATTACK' },
};

// === PLAYER DRAGONS ===
export const dragons = {
  fire: {
    id: 'fire',
    name: 'Magma Dragon',
    element: 'fire',
    baseStats: { hp: 110, atk: 28, def: 20, spd: 18 },
    moveKeys: ['magma_breath', 'flame_wall'],
    spriteSheet: '/assets/dragons/magma.png',
  },
  ice: {
    id: 'ice',
    name: 'Ice Dragon',
    element: 'ice',
    baseStats: { hp: 100, atk: 24, def: 26, spd: 20 },
    moveKeys: ['frost_bite', 'blizzard'],
    spriteSheet: '/assets/dragons/ice.png',
  },
  storm: {
    id: 'storm',
    name: 'Storm Dragon',
    element: 'storm',
    baseStats: { hp: 90, atk: 30, def: 16, spd: 28 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    spriteSheet: '/assets/dragons/lightning.png',
  },
  stone: {
    id: 'stone',
    name: 'Stone Dragon',
    element: 'stone',
    baseStats: { hp: 120, atk: 22, def: 30, spd: 12 },
    moveKeys: ['rock_slide', 'earthquake'],
    spriteSheet: '/assets/dragons/stone.png',
  },
  venom: {
    id: 'venom',
    name: 'Venom Dragon',
    element: 'venom',
    baseStats: { hp: 95, atk: 26, def: 18, spd: 24 },
    moveKeys: ['acid_spit', 'toxic_cloud'],
    spriteSheet: '/assets/dragons/venom.png',
  },
  shadow: {
    id: 'shadow',
    name: 'Shadow Dragon',
    element: 'shadow',
    baseStats: { hp: 85, atk: 32, def: 14, spd: 26 },
    moveKeys: ['shadow_strike', 'void_pulse'],
    spriteSheet: '/assets/dragons/shadow.png',
  },
};

// === NPC ENEMIES ===
export const npcs = {
  firewall_sentinel: {
    id: 'firewall_sentinel',
    name: 'Firewall Sentinel',
    element: 'stone',
    level: 2,
    stats: { hp: 80, atk: 14, def: 22, spd: 8 },
    moveKeys: ['rock_slide'],
    difficulty: 'Easy',
    baseXP: 25,
    idleSprite: '/assets/npc/firewall_sentinel_sprites.png',
    attackSprite: '/assets/npc/firewall_sentinel_attack.png',
    arena: '/assets/arenas/npc_firewall_sentinel.png',
    flipSprite: false,
  },
  bit_wraith: {
    id: 'bit_wraith',
    name: 'Bit Wraith',
    element: 'shadow',
    level: 4,
    stats: { hp: 55, atk: 22, def: 10, spd: 20 },
    moveKeys: ['shadow_strike', 'void_pulse'],
    difficulty: 'Medium',
    baseXP: 40,
    idleSprite: '/assets/npc/bit_wraith_sprites.png',
    attackSprite: '/assets/npc/bit_wraith_attack.png',
    arena: '/assets/arenas/npc_bit_wraith.png',
    flipSprite: false,
  },
  glitch_hydra: {
    id: 'glitch_hydra',
    name: 'Glitch Hydra',
    element: 'storm',
    level: 7,
    stats: { hp: 75, atk: 24, def: 16, spd: 18 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    difficulty: 'Hard',
    baseXP: 60,
    idleSprite: '/assets/npc/glitch_hydra_sprites.png',
    attackSprite: '/assets/npc/glitch_hydra_attack.png',
    arena: '/assets/arenas/npc_glitch_hydra.png',
    flipSprite: true,
  },
  recursive_golem: {
    id: 'recursive_golem',
    name: 'Recursive Golem',
    element: 'stone',
    level: 10,
    stats: { hp: 120, atk: 20, def: 28, spd: 6 },
    moveKeys: ['rock_slide', 'earthquake'],
    difficulty: 'Boss',
    baseXP: 80,
    idleSprite: '/assets/npc/recursive_golem_sprites.png',
    attackSprite: '/assets/npc/recursive_golem_attack.png',
    arena: '/assets/arenas/npc_recursive_golem.png',
  },
};

// === ELEMENT COLORS (for UI) ===
export const elementColors = {
  fire:    { primary: '#ff6622', glow: '#ff8844' },
  ice:     { primary: '#44aaff', glow: '#66ccff' },
  storm:   { primary: '#aa66ff', glow: '#cc88ff' },
  stone:   { primary: '#aa8844', glow: '#ccaa66' },
  venom:   { primary: '#44cc44', glow: '#66ee66' },
  shadow:  { primary: '#8844aa', glow: '#aa66cc' },
  neutral: { primary: '#888888', glow: '#aaaaaa' },
};
