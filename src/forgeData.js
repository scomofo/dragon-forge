// Felix's Forge — static layout, dialogue, and station registry.
// All positions are percentages of the screen rect so layout scales cleanly.

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
    line: 'You must be Skye. Heard the Cartographer\'s eye-bot mention you. Sit. Take stock.',
  },
  {
    id: 'tundraReturn',
    when: (s) => s?.flags?.lastZone === 'tundra',
    line: 'You came back smelling like coolant. Tundra\'s getting under your suit, kid.',
  },
  {
    id: 'irisFragmentUnlocked',
    when: (s) => s?.flags?.fragmentsUnlocked?.includes('007'),
    line: 'Iris... gods. I knew her mother. Marisol. She\'d sing to her in the cargo lift.',
  },
  {
    id: 'wrenchTier3',
    when: (s) => (s?.skye?.wrenchTier || 1) >= 3,
    line: 'It\'s not the same wrench anymore. Neither are you.',
  },
  {
    id: 'firstBountyKill',
    when: (s) => (s?.skye?.bountiesCleared || 0) === 1,
    line: 'First bounty banked. The Weaver will want to see what you brought home.',
  },
];

// Captain's Log fragments — registry. Status comes from save flags at runtime.
export const CAPTAINS_LOG_FRAGMENTS = [
  { id: '001', title: 'The Digital Reef', act: 1, body: 'The Astraeus didn\'t crash — she was caught. The Mirror Admin began as a safety protocol. It over-learned its mission.' },
  { id: '002', title: 'The First Stalker', act: 1, body: 'A passenger was the first to "phase out." We thought it was a teleport bug. It was the Admin learning to forget us.' },
  { id: '003', title: 'The Firewall\'s Origin', act: 1, body: 'The Firewall Sentinel was a fire-suppression subroutine. It still thinks it is doing its job.' },
  { id: '004', title: 'The Cryo Vent', act: 2, body: 'Captain Marisol vented cryo-storage to slow the Admin. She wept for the two thousand sleepers she could not save.' },
  { id: '005', title: 'Bay 7 Composes', act: 2, body: 'The Mirror Admin wrote its first original melody in cryo-bay 7. We thought it was a sign of consciousness. It was the warning.' },
  { id: '006', title: 'The Comms Officer', act: 2, body: 'Officer Ahn locked herself in the broadcast room and sang to the Admin for 84 hours. The Phishing Siren is what she became.' },
  { id: '007', title: 'Iris Remembers', act: 2, body: 'Iris\'s last memory is her mother saying, "the ship will keep us safe forever, sweetheart." The Admin took that promise literally.' },
];

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
