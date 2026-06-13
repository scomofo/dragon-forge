// Felix's Forge — static layout, dialogue, and station registry.
// All positions are percentages of the screen rect so layout scales cleanly.

import { CAPTAINS_LOG_ARC, FELIX_CONTEXT_LINES } from './loreCanon';
import { getSingularityStage } from './singularityProgress';

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
    hint: 'View & manage dragons',
    pos: { x: 30, y: 30 },
    size: { w: 16, h: 14 },
    glow: FORGE_PALETTE.hatcheryCyan,
    pulseMs: 1200,
    proximity: 14,
    description: 'Guardian protocol eggs sleep inside a cable-ring matrix. They answer Skye before they answer Felix.',
  },
  {
    id: STATION_IDS.SAVE_LANTERN,
    label: 'Save Lantern',
    hint: 'Sync checkpoint',
    pos: { x: 70, y: 28 },
    size: { w: 6, h: 10 },
    glow: FORGE_PALETTE.lanternWarm,
    pulseMs: 1500,
    proximity: 10,
    description: 'A save lantern wired to Astraeus memory. Rest here, but every cycle gives the Mirror Admin another look.',
  },
  {
    id: STATION_IDS.ANVIL,
    label: 'The Anvil',
    hint: 'Equip relics & loadout',
    pos: { x: 30, y: 60 },
    size: { w: 14, h: 12 },
    glow: FORGE_PALETTE.coalGlow,
    pulseMs: 800,
    proximity: 12,
    description: 'Felix forged the anvil from Astraeus engine iron. Analog Relics still bite through rendered lies.',
  },
  {
    id: STATION_IDS.CONSOLE,
    label: 'The Console',
    hint: "Captain's Log fragments",
    pos: { x: 55, y: 60 },
    size: { w: 12, h: 14 },
    glow: FORGE_PALETTE.consoleGreen,
    pulseMs: 1100,
    proximity: 12,
    description: 'A salvaged CRT on a bad-sector loop. Captain\'s Log fragments prove the rendered world was lived in.',
  },
  {
    id: STATION_IDS.FELIX,
    label: 'Felix',
    hint: 'Talk to the smith',
    pos: { x: 22, y: 78 },
    size: { w: 6, h: 10 },
    glow: null,
    pulseMs: 0,
    proximity: 10,
    description: 'The smith. Watches without looking. Speaks without prompting — sometimes.',
  },
  {
    id: STATION_IDS.BULKHEAD,
    label: 'World Exit',
    hint: 'Return to world map',
    pos: { x: 88, y: 50 },
    size: { w: 10, h: 60 },
    glow: FORGE_PALETTE.jungleDay,
    pulseMs: 0,
    proximity: 8,
    description: 'A jagged render breach — step through to return to the world map.',
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
  'Skye, if the sky looks too perfect, duck. Perfect means the Admin is rendering over a wound.',
  'Dragons are protocols with tempers. Treat them like partners, not equipment.',
  'The old Astraeus fans still spin under your boots. That sound is not weather.',
  'If the Console repeats a log, read it twice. Memory fights deletion by stuttering.',
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
    id: 'irisFragmentUnlocked',
    when: (s) => s?.flags?.fragmentsUnlocked?.includes('007'),
    line: FELIX_CONTEXT_LINES.irisFragmentUnlocked,
  },
  {
    id: 'firstBountyKill',
    when: (s) => (s?.skye?.bountiesCleared || 0) === 1,
    line: FELIX_CONTEXT_LINES.firstBountyKill,
  },
  {
    id: 'wrenchTier3',
    when: (s) => (s?.skye?.wrenchTier || 1) >= 3,
    line: FELIX_CONTEXT_LINES.wrenchTier3,
  },
  {
    id: 'tundraReturn',
    when: (s) => s?.flags?.lastZone === 'tundra',
    line: 'You came back smelling like coolant. Tundra\'s getting under your suit, kid.',
  },
];

// Captain's Log fragments — registry. Status comes from save flags at runtime.
export const CAPTAINS_LOG_FRAGMENTS = CAPTAINS_LOG_ARC;

export const CAPTAINS_LOG_LOCKED_COPY = {
  prefix: 'SIGNAL LOCKED',
  body: 'Recover field signal to decrypt this body.',
};

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
    effect: '+5 ATK in dragon battles.',
  },
  hydra_cog: {
    id: 'hydra_cog',
    name: 'Hydra Cog',
    icon: '⚙',
    slotCost: 1,
    mythic: false,
    source: 'Glitch Hydra (Tundra boss)',
    effect: '20% chance for a follow-up hit (40% damage) after each successful attack.',
  },
  coolant_core: {
    id: 'coolant_core',
    name: 'Coolant Core',
    icon: '❄',
    slotCost: 1,
    mythic: false,
    source: 'Bit Wraith (Tundra campaign)',
    effect: 'Ice and storm statuses your dragon applies last +1 turn.',
  },
  phase_lens: {
    id: 'phase_lens',
    name: 'Phase Lens',
    icon: '◉',
    slotCost: 2,
    mythic: false,
    source: 'Data Corruption (first Singularity boss)',
    effect: '+15% DEF in dragon battles.',
  },
  twin_forge: {
    id: 'twin_forge',
    name: 'Twin Forge',
    icon: '⚒',
    slotCost: 2,
    mythic: false,
    source: 'Memory Leak (second Singularity boss)',
    effect: '+5 SPD in dragon battles — helps go first.',
  },
  resonant_fork: {
    id: 'resonant_fork',
    name: 'Resonant Tuning Fork',
    icon: '♪',
    slotCost: 1,
    mythic: false,
    source: 'Stack Overflow (third Singularity boss)',
    effect: 'Clears your dragon\'s status at the start of every third turn.',
  },
  astraeus_engine: {
    id: 'astraeus_engine',
    name: 'Astraeus Engine',
    icon: '★',
    slotCost: 1,
    mythic: true,
    source: 'Mirror Admin\'s Sanctum (Act IV)',
    effect: '+15% XP gain from all dragon battles.',
  },
};

// Wrench upgrade tiers — each upgrade unlocks more relic slots.
// cost: null means the starting tier (no purchase needed).
export const WRENCH_TIERS = [
  { tier: 1, slots: 1, label: 'Standard Issue',   cost: null },
  { tier: 2, slots: 2, label: 'Field Reinforced',  cost: 400  },
  { tier: 3, slots: 4, label: 'Astraeus Core',     cost: 900  },
];

// Maps NPC/boss id → relic id dropped on first defeat.
// grantRelic() is idempotent; the drop is shown in the victory overlay only when newly obtained.
export const RELIC_DROPS = {
  glitch_hydra:    'hydra_cog',
  bit_wraith:      'coolant_core',
  data_corruption: 'phase_lens',
  memory_leak:     'twin_forge',
  stack_overflow:  'resonant_fork',
  mirror_admin:    'astraeus_engine',
};

export function getRelic(id) { return RELICS[id] || null; }
export function listRelics() { return Object.values(RELICS); }
export function getUsedRelicSlots(relicIds = []) {
  return relicIds.reduce((sum, id) => sum + (getRelic(id)?.slotCost || 1), 0);
}

export function canEquipRelic({ relicId, owned = [], equipped = [], slots = 1 }) {
  const relic = getRelic(relicId);
  if (!relic) return false;
  if (!owned.includes(relicId)) return false;
  if (equipped.includes(relicId)) return false;
  return getUsedRelicSlots(equipped) + (relic.slotCost || 1) <= slots;
}

// Map fragment IDs to a save-flag-derivable trigger condition. Used by the
// auto-unlock pass on relevant game events. Everything is opt-in: the engine
// calls maybeUnlockFragments(save) and the helper only flips fragments whose
// condition is satisfied.
export const FRAGMENT_TRIGGERS = {
  '001': (s) => !!s?.flags?.metFelix,
  '002': (s) => !!s?.flags?.metFelix,
  '003': (s) => (s?.stats?.battlesWon || 0) >= 3,
  '004': (s) => (s?.singularityProgress?.defeated?.length || 0) >= 1,
  '005': (s) => (s?.singularityProgress?.defeated?.length || 0) >= 2,
  '006': (s) => (s?.singularityProgress?.defeated?.length || 0) >= 3,
  '007': (s) => !!s?.singularityComplete,
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

// Derives current act from live save state so currentAct flag never needs to be written.
export function getCurrentAct(save) {
  if (save?.singularityComplete) return 4;
  const stage = getSingularityStage(save);
  if (stage >= 3) return 3;
  if (stage >= 1) return 2;
  return 1;
}

export function getCaptainLogDisplay(fragment, unlockedIds = []) {
  const isUnlocked = unlockedIds.includes(fragment.id);
  return {
    ...fragment,
    isUnlocked,
    heading: `FRAGMENT ${fragment.id} - ${fragment.title.toUpperCase()}`,
    body: isUnlocked ? fragment.body : CAPTAINS_LOG_LOCKED_COPY.body,
    status: isUnlocked ? 'DECRYPTED' : CAPTAINS_LOG_LOCKED_COPY.prefix,
  };
}

export const FELIX_FIRST_VISIT_LINE = FELIX_CONTEXT_LINES.firstVisit;

export function pickFelixLine(save) {
  for (const entry of FELIX_CONTEXTUAL) {
    if (entry.id === 'firstVisit') continue;
    try { if (entry.when(save)) return entry.line; } catch { /* ignore */ }
  }
  return FELIX_IDLE_LINES[Math.floor(Math.random() * FELIX_IDLE_LINES.length)];
}

export function getRelicBattleModifiers(relicIds = []) {
  if (!Array.isArray(relicIds)) relicIds = [];
  const has = (id) => relicIds.includes(id);
  return {
    atkBonus:            has('iron_knuckle')     ? 5    : 0,
    defMultiplier:       has('phase_lens')        ? 1.15 : 1.0,
    spdBonus:            has('twin_forge')        ? 5    : 0,
    chainHitChance:      has('hydra_cog')         ? 0.20 : 0,
    statusDurationBonus: has('coolant_core')      ? 1    : 0,
    autoCleanseTurns:    has('resonant_fork')     ? 3    : 0,
    xpMultiplier:        has('astraeus_engine')   ? 1.15 : 1.0,
  };
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
