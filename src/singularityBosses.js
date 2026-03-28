export const SINGULARITY_BOSSES = [
  {
    id: 'data_corruption',
    name: 'Data Corruption',
    element: 'fire',
    level: 15,
    stats: { hp: 140, atk: 30, def: 18, spd: 16 },
    moveKeys: ['magma_breath', 'flame_wall'],
    difficulty: 'Singularity',
    baseXP: 100,
    scrapsReward: 200,
    idleSprite: '/assets/npc/firewall_sentinel_sprites.png',
    attackSprite: '/assets/npc/firewall_sentinel_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(15deg) contrast(1.2)',
    felixQuote: "It's eating through our data layers. Fire with fire — you'll need a dragon that can take the heat.",
    unlockRequires: null,
  },
  {
    id: 'memory_leak',
    name: 'Memory Leak',
    element: 'ice',
    level: 20,
    stats: { hp: 120, atk: 26, def: 24, spd: 22 },
    moveKeys: ['frost_bite', 'blizzard'],
    difficulty: 'Singularity',
    baseXP: 150,
    scrapsReward: 300,
    idleSprite: '/assets/npc/bit_wraith_sprites.png',
    attackSprite: '/assets/npc/bit_wraith_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(-30deg) contrast(1.2)',
    felixQuote: "This thing absorbs and never releases. It'll freeze you solid if you let it accumulate.",
    unlockRequires: 'data_corruption',
  },
  {
    id: 'stack_overflow',
    name: 'Stack Overflow',
    element: 'storm',
    level: 25,
    stats: { hp: 100, atk: 34, def: 14, spd: 30 },
    moveKeys: ['lightning_strike', 'thunder_clap'],
    difficulty: 'Singularity',
    baseXP: 200,
    scrapsReward: 400,
    idleSprite: '/assets/npc/glitch_hydra_sprites.png',
    attackSprite: '/assets/npc/glitch_hydra_attack.png',
    arena: '/assets/arenas/shadow.png',
    arenaFilter: 'grayscale(0.5) hue-rotate(330deg) contrast(1.3)',
    spriteFilter: 'saturate(1.5) hue-rotate(30deg) contrast(1.2)',
    felixQuote: "Infinite recursion manifested as pure electricity. It's fast. Faster than anything we've faced.",
    unlockRequires: 'memory_leak',
  },
];

export const FINAL_BOSS = {
  id: 'the_singularity',
  name: 'The Singularity',
  difficulty: 'FINAL',
  baseXP: 500,
  scrapsReward: 1000,
  arena: '/assets/arenas/gravity_chamber.png',
  arenaFilter: 'saturate(1.5) contrast(1.2)',
  felixQuote: "This is it. The source of everything. It will adapt. It will learn. Do not let it win.",
  unlockRequires: 'stack_overflow',
  idleSprite: '/assets/npc/recursive_golem_sprites.png',
  attackSprite: '/assets/npc/recursive_golem_attack.png',
  phases: [
    {
      name: 'The Singularity \u2014 Ignition',
      element: 'fire',
      level: 30,
      stats: { hp: 150, atk: 32, def: 20, spd: 18 },
      moveKeys: ['magma_breath', 'flame_wall'],
      spriteFilter: 'saturate(2) hue-rotate(15deg) contrast(1.3)',
    },
    {
      name: 'The Singularity \u2014 Surge',
      element: 'storm',
      level: 30,
      stats: { hp: 130, atk: 36, def: 16, spd: 26 },
      moveKeys: ['lightning_strike', 'thunder_clap'],
      spriteFilter: 'saturate(2) hue-rotate(60deg) contrast(1.3)',
    },
    {
      name: 'The Singularity \u2014 Void Collapse',
      element: 'void',
      level: 30,
      stats: { hp: 100, atk: 40, def: 12, spd: 32 },
      moveKeys: ['void_rift', 'null_reflect'],
      spriteFilter: 'saturate(2) hue-rotate(180deg) contrast(1.5)',
    },
  ],
};

export function getBossStatus(boss, save) {
  const progress = save.singularityProgress || { defeated: [], finalBossPhase: 0 };
  const defeated = progress.defeated || [];

  if (boss.id === 'the_singularity') {
    const allGatekeepersDefeated = SINGULARITY_BOSSES.every(b => defeated.includes(b.id));
    if (save.singularityComplete) return 'defeated';
    if (allGatekeepersDefeated) return 'available';
    return 'locked';
  }

  if (defeated.includes(boss.id)) return 'defeated';
  if (!boss.unlockRequires) return 'available';
  if (defeated.includes(boss.unlockRequires)) return 'available';
  return 'locked';
}

export const EPILOGUE_LINES = [
  'You did it. The Singularity is contained.',
  'The Matrix is stabilizing. I can feel it.',
  "You've saved every dragon in the Forge.",
  "But between you and me... I don't think it's gone forever.",
  'Stay sharp, Dragon Forger.',
];
