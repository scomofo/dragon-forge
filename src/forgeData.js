// Felix's Forge — static layout, dialogue, and station registry.
// All positions are percentages of the screen rect so layout scales cleanly.

import { CAPTAINS_LOG_ARC, FELIX_CONTEXT_LINES } from './loreCanon';

export const FORGE_PALETTE = {
  floor: '#3a2a1f',
  floorAccent: '#2a1d14',
  wallShadow: '#1a1310',
  emberOrange: '#ff8b3d',
  coalGlow: '#ff5a1f',
  hatcheryCyan: '#5edcff',
  consoleGreen: '#5cff8a',
  lanternWarm: '#ffcd6b',
  jungleDay: '#8fcf6c',
  rust: '#7a4a2a',
};

// Station IDs — used as the key for interactions and asset lookup.
export const STATION_IDS = {
  ANVIL: 'anvil',
  CONSOLE: 'console',
  HATCHERY_RING: 'hatcheryRing',
  SAVE_LANTERN: 'saveLantern',
  BULKHEAD: 'bulkhead',
  FELIX: 'felix',
};

// All five interactables + Felix, positioned on a 100×100 grid.
// Skye snaps to within ~12 units of any station to engage proximity highlight.
export const FORGE_STATIONS = [
  {
    id: STATION_IDS.HATCHERY_RING,
    label: 'Hatchery Ring',
    pos: { x: 30, y: 30 },
    size: { w: 16, h: 14 },
    glow: FORGE_PALETTE.hatcheryCyan,
    pulseMs: 1200,
    proximity: 14,
    description: 'A circle of cabling and crystalline matrix cradling 1-3 dragon eggs. The pulse syncs with their dreaming.',
  },
  {
    id: STATION_IDS.SAVE_LANTERN,
    label: 'Save Lantern',
    pos: { x: 70, y: 28 },
    size: { w: 6, h: 10 },
    glow: FORGE_PALETTE.lanternWarm,
    pulseMs: 1500,
    proximity: 10,
    description: 'A salvaged lantern. Resting here refills HP and Capacitors but advances the world by one cycle.',
  },
  {
    id: STATION_IDS.ANVIL,
    label: 'The Anvil',
    pos: { x: 30, y: 60 },
    size: { w: 14, h: 12 },
    glow: FORGE_PALETTE.coalGlow,
    pulseMs: 800,
    proximity: 12,
    description: 'Felix\'s anvil. Coals breathe orange beneath. Equip Analog Relics here.',
  },
  {
    id: STATION_IDS.CONSOLE,
    label: 'The Console',
    pos: { x: 55, y: 60 },
    size: { w: 12, h: 14 },
    glow: FORGE_PALETTE.consoleGreen,
    pulseMs: 1100,
    proximity: 12,
    description: 'A salvaged CRT lashed to a column. Captain\'s Log fragments and narrative saves live here.',
  },
  {
    id: STATION_IDS.FELIX,
    label: 'Felix',
    pos: { x: 22, y: 78 },
    size: { w: 6, h: 10 },
    glow: null,
    pulseMs: 0,
    proximity: 10,
    description: 'The smith. Watches without looking. Speaks without prompting — sometimes.',
  },
  {
    id: STATION_IDS.BULKHEAD,
    label: 'Bulkhead Window',
    pos: { x: 88, y: 50 },
    size: { w: 10, h: 60 },
    glow: FORGE_PALETTE.jungleDay,
    pulseMs: 0,
    proximity: 8,
    description: 'A jagged hole in the hull. Step through to leave the Forge.',
  },
];

// Felix's rotating idle one-liners — chosen at random when no state-specific
// dialogue applies. Twelve total to feel non-repetitive across a play session.
export const FELIX_IDLE_LINES = [
  'A bolt has two states, kid. Tight or stripped. Don\'t be a stripped bolt.',
  'Heat softens iron. Cold makes it brittle. People are the same.',
  'Every dragon I\'ve known started as something fragile. So did every blade.',
  'You came back. That\'s the part most folks forget to do.',
  'The wrench remembers what you forge with it. Keep it honest.',
  'Out there is rust. In here, we make it useful.',
  'I built this anvil from the engine block of the Astraeus. Small comfort.',
  'You smell like the Tundra. Let it go before it sets.',
  'Don\'t bond a dragon you wouldn\'t mourn. That\'s the whole law of it.',
  'The Mirror Admin started as a kindness. Don\'t forget that.',
  'Felix isn\'t my real name. It\'s what the kids could pronounce.',
  'When the lantern flickers blue, the deck has shifted again. Adjust your stance.',
];

// Context-aware dialogue — keyed by save-state predicates evaluated at runtime.
// First match wins; otherwise an idle line is chosen.
export const FELIX_CONTEXTUAL = [
  {
    id: 'firstVisit',
    when: (s) => !s?.flags?.metFelix,
    line: FELIX_CONTEXT_LINES.firstVisit,
  },
  {
    id: 'tundraReturn',
    when: (s) => s?.flags?.lastZone === 'tundra',
    line: 'You came back smelling like coolant. Tundra\'s getting under your suit, kid.',
  },
  {
    id: 'irisFragmentUnlocked',
    when: (s) => s?.flags?.fragmentsUnlocked?.includes('007'),
    line: FELIX_CONTEXT_LINES.irisFragmentUnlocked,
  },
  {
    id: 'wrenchTier3',
    when: (s) => (s?.skye?.wrenchTier || 1) >= 3,
    line: FELIX_CONTEXT_LINES.wrenchTier3,
  },
  {
    id: 'firstBountyKill',
    when: (s) => (s?.skye?.bountiesCleared || 0) === 1,
    line: FELIX_CONTEXT_LINES.firstBountyKill,
  },
];

// Captain's Log fragments — registry. Status comes from save flags at runtime.
export const CAPTAINS_LOG_FRAGMENTS = CAPTAINS_LOG_ARC;

// Analog Relics — Skye's passive equipment, drops from bounty kills.
// `slotCost` matters once mythic slots ship; for now everything is 1.
export const RELICS = {
  iron_knuckle: {
    id: 'iron_knuckle',
    name: 'Iron Knuckle',
    icon: '✊',
    slotCost: 1,
    mythic: false,
    source: 'Recursive Golem (Cooling Intake boss)',
    effect: 'Heavy poise damage +1.',
  },
  hydra_cog: {
    id: 'hydra_cog',
    name: 'Hydra Cog',
    icon: '⚙',
    slotCost: 1,
    mythic: false,
    source: 'Glitch Hydra (Tundra boss)',
    effect: 'Heavy can chain twice on hit.',
  },
  coolant_core: {
    id: 'coolant_core',
    name: 'Coolant Core',
    icon: '❄',
    slotCost: 1,
    mythic: false,
    source: 'Tundra Bit-Wraith swarm bonus',
    effect: 'Capacitor stuns last +50%.',
  },
  phase_lens: {
    id: 'phase_lens',
    name: 'Phase Lens',
    icon: '◉',
    slotCost: 2,
    mythic: false,
    source: 'Sub-routine Stalker (rare drop)',
    effect: 'Roll i-frames extend to 12f.',
  },
  twin_forge: {
    id: 'twin_forge',
    name: 'Twin Forge',
    icon: '⚒',
    slotCost: 2,
    mythic: false,
    source: 'Volcanic miniboss',
    effect: 'Light chain extends to 4 hits.',
  },
  resonant_fork: {
    id: 'resonant_fork',
    name: 'Resonant Tuning Fork',
    icon: '♪',
    slotCost: 1,
    mythic: false,
    source: 'Lattice-Singer (The Last Verse)',
    effect: 'Every 4th Heavy pulses an AOE that strips frostbite.',
  },
  astraeus_engine: {
    id: 'astraeus_engine',
    name: 'Astraeus Engine',
    icon: '★',
    slotCost: 1,
    mythic: true,
    source: 'Mirror Admin\'s Sanctum (Act IV)',
    effect: 'All bounty windows last 50% longer.',
  },
};

export function getRelic(id) { return RELICS[id] || null; }
export function listRelics() { return Object.values(RELICS); }

// Map fragment IDs to a save-flag-derivable trigger condition. Used by the
// auto-unlock pass on relevant game events. Everything is opt-in: the engine
// calls maybeUnlockFragments(save) and the helper only flips fragments whose
// condition is satisfied.
export const FRAGMENT_TRIGGERS = {
  '001': (s) => !!s?.flags?.metFelix,
  '002': (s) => (s?.stats?.battlesWon || 0) >= 1,
  '003': (s) => (s?.stats?.battlesWon || 0) >= 3,
  '004': (s) => (s?.flags?.currentAct || 1) >= 2,
  '005': (s) => (s?.flags?.currentAct || 1) >= 2 && (s?.stats?.battlesWon || 0) >= 5,
  '006': (s) => (s?.flags?.currentAct || 1) >= 2 && (s?.stats?.battlesWon || 0) >= 8,
  '007': (s) => (s?.flags?.currentAct || 1) >= 3,
};

// Bulkhead view by act — palette + parallax variant key.
export const BULKHEAD_VIEWS = {
  1: { variant: 'jungle', palette: [FORGE_PALETTE.jungleDay, '#5a8c3a', '#2c4a1c'] },
  2: { variant: 'tundraEdge', palette: ['#cfe7ff', '#7aa8c4', '#3b5870'] },
  3: { variant: 'volcanic', palette: ['#ff7a3d', '#a83a18', '#3a0c08'] },
  4: { variant: 'aurora', palette: ['#7af0d6', '#9b6cff', '#1a1644'] },
};

export function getBulkheadView(actNumber) {
  return BULKHEAD_VIEWS[actNumber] || BULKHEAD_VIEWS[1];
}

export function pickFelixLine(save) {
  for (const entry of FELIX_CONTEXTUAL) {
    try { if (entry.when(save)) return entry.line; } catch { /* ignore */ }
  }
  return FELIX_IDLE_LINES[Math.floor(Math.random() * FELIX_IDLE_LINES.length)];
}

export function distance(a, b) {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

export function findNearestStation(skyePos, threshold = null) {
  let nearest = null;
  let bestDist = Infinity;
  for (const st of FORGE_STATIONS) {
    const d = distance(skyePos, st.pos);
    const limit = threshold ?? st.proximity;
    if (d <= limit && d < bestDist) {
      bestDist = d;
      nearest = st;
    }
  }
  return nearest;
}
