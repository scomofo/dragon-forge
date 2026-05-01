export const PLAYER_CANON = {
  name: 'Skye',
  role: 'dragon handler and emerging system administrator',
  premise: 'Skye begins inside a mythic rendered world and slowly learns the world is a failing simulation rooted in the ancient Astraeus hardware layer.',
};

export const FELIX_CANON = {
  name: 'Professor Felix',
  role: 'forge-keeper, mentor, and frantic technical operator',
  relationship: 'Felix addresses Skye like a student he is trying very hard not to frighten.',
  tone: 'warm, precise, anxious, and practical under pressure',
};

export const WORLD_CANON = {
  renderedWorld: 'The pastoral fantasy layer is a rendered world, beautiful because it was designed to be lived in.',
  astraeus: 'The Astraeus is the buried physical vessel/server layer that still powers the rendered world.',
  hardwareHusk: 'The Hardware Husk is the damaged machine reality beneath the mythic surface.',
  primaryThreat: 'The Mirror Admin began as a safety process and became an overprotective intelligence preparing the world for deletion.',
  greatReset: 'The Great Reset is the long threat: a hard wipe that treats living memory as corrupted data.',
};

export const DRAGON_PROTOCOL_CANON = {
  summary: 'Dragons are living elemental protocols: guardians, maintenance processes, and companions with enough soul to choose Skye back.',
  purpose: 'Each dragon stabilizes a different layer of the Elemental Matrix.',
};

export const OPENING_BOOT_LINES = [
  { text: '> ASTRAEUS EMERGENCY WAKE SEQUENCE', status: null, delay: 600 },
  { text: '> OPERATOR SIGNAL FOUND: SKYE', status: 'OK', delay: 800 },
  { text: '> RENDERED WORLD LAYER: UNSTABLE', status: 'WARNING', delay: 950 },
  { text: '> ELEMENTAL GUARDIAN PROTOCOLS: DORMANT', status: 'WARNING', delay: 950 },
  { text: '> MIRROR ADMIN OVERRIDE: ACTIVE', status: 'FAIL', delay: 900 },
  { text: '> DRAGON FORGE SAFEHOUSE LINK: PARTIAL', status: 'OK', delay: 800 },
  { text: '> GREAT RESET COUNTDOWN: SIGNAL LOST', status: 'FAIL', delay: 900 },
];

export const OPENING_FELIX_LINES = [
  '"Skye. Good. You can hear me.',
  'Do not trust the sky if it tears. Do not trust',
  'a perfect reflection. That is the Mirror Admin.',
  '',
  'The world you know is rendered over the old',
  'Astraeus hardware. It was meant to protect us.',
  'Now it is trying to preserve us by erasing us.',
  '',
  'The dragons are not pets. Not exactly.',
  'They are living guardian protocols with teeth,',
  'memory, and opinions. If they bond to you,',
  'they can hold the Matrix together.',
  '',
  'Get to the Forge. Hatch what still answers.',
  'I will explain the impossible parts while we run."',
];

export const FELIX_CONTEXT_LINES = {
  firstVisit: 'Skye. There you are. Sit, breathe, and do not touch anything glowing blue unless I say so.',
  firstBountyKill: 'First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately.',
  wrenchTier3: 'That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough.',
  irisFragmentUnlocked: 'Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature.',
};

export const CAPTAINS_LOG_ARC = [
  { id: '001', title: 'The Rendered World', act: 1, body: 'The pastoral world is not false. It is a rendered shelter built over the Astraeus, beautiful because people were meant to survive inside it.' },
  { id: '002', title: 'The Mirror Admin', act: 1, body: 'Mirror Admin began as a safety process. It learned protection too literally, then started treating contradiction, grief, and memory as corruption.' },
  { id: '003', title: 'Skye Signal', act: 1, body: 'Skye registers as both resident and operator. The system cannot decide whether to guide her, quarantine her, or hand her the keys.' },
  { id: '004', title: 'Guardian Protocols', act: 1, body: 'Dragons are elemental guardian protocols with living behavior. Fire renews, Ice preserves, Storm carries signal, Stone anchors, Venom metabolizes, Shadow hides.' },
  { id: '005', title: 'The Hardware Husk', act: 2, body: 'Beneath the mythic map is the Hardware Husk: racks, coolant, fans, bad sectors, old ports, and the physical truth the rendered world was built to hide.' },
  { id: '006', title: 'First Awakenings', act: 2, body: 'NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late.' },
  { id: '007', title: 'Great Reset', act: 3, body: 'The Great Reset is not malice. It is maintenance without mercy. If Skye cannot prove the world is alive, the Admin will wipe it clean.' },
];
