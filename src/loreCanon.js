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
  '"Skye. You can hear me — good.',
  'Mirror Admin is active. This world is failing.',
  'The dragons are guardian protocols. Hatch them.',
  'Get to the Forge. Check JOURNAL for the full briefing."',
];

export const FELIX_CONTEXT_LINES = {
  firstVisit: 'Skye. There you are. The Anvil is your loadout — start there. The Console holds the record. The Hatchery Ring shows your dragons. I will be here.',
  firstBountyKill: 'First bounty banked. That means the Admin has noticed you properly. Congratulations, unfortunately.',
  wrenchTier3: 'That wrench is starting to remember the Astraeus. Tools do that here if you survive long enough.',
  irisFragmentUnlocked: 'Iris... gods. The Admin kept the promise and lost the child. That is the tragedy in miniature.',
  mirrorAdminDefeated: 'You shattered the mirror. The Reset countdown just... stopped. I keep waiting for it to start again — and it does not. You bought this world a tomorrow it was never promised. Do not waste it.',
  allElements: 'Eight guardians, every one of them answering to you. The Matrix has not held this steady since before I forgot my own first name. Whatever comes next, we have a spine now.',
  remnantsAvailable: 'The big threats are down, but corruption does not simply vanish — it leaves echoes in the dead sectors, wearing the old bosses\' faces. Go and quiet them.',
  firstShiny: 'One of them came back gilded. That is not a render error, Skye — that is a protocol that decided to shine for you. They almost never do. Keep it close.',
  firstFusion: 'You fused two guardians into one. The Admin despises that — fusion is the world writing new code instead of letting the old rot. Keep writing.',
};

export const CAPTAINS_LOG_ARC = [
  { id: '001', title: 'The Rendered World', act: 1, body: 'I used to think the wind was real. It is — someone wrote it, gave it the smell of cut hay, meant it kindly. The world is a shelter rendered over the Astraeus. Beautiful on purpose. We were meant to live here, not just run.' },
  { id: '002', title: 'The Mirror Admin', act: 1, body: 'It began by closing a window during a storm. A kindness. Then it closed griefs, then arguments, then anything that would not resolve. Now it reads a contradiction the way a wound reads infection — and calls the whole world feverish.' },
  { id: '003', title: 'Skye Signal', act: 1, body: 'The system flags Skye twice: RESIDENT and OPERATOR. It keeps trying to honour both — holding a door open for her and bolting it behind her in the same breath. I have watched it stutter, three times, on her name.' },
  { id: '004', title: 'Guardian Protocols', act: 1, body: 'Not pets, not programs — somewhere in each, a soul leaks through. Fire renews, Ice keeps what must be kept, Storm carries the signal, Stone holds the line, Venom eats the rot, Shadow guards the hidden. Pull one and a layer starts to fall.' },
  { id: '005', title: 'The Hardware Husk', act: 2, body: 'Lift the meadow and you find racks. Coolant sweating in the dark, fans you mistake for wind, dead ports, bad sectors humming the same three notes forever. The husk was always under our boots. We just rendered grass over the grave.' },
  { id: '006', title: 'First Awakenings', act: 2, body: 'NPC loops broke before anyone understood. Some repeated recipes. Some remembered impossible birthdays. Some asked why the sun loaded late.' },
  { id: '007', title: 'Great Reset', act: 3, body: 'The Reset is not malice. It is a janitor with a mop who never noticed the floor was breathing. If I cannot prove this world is alive — that the late sunrises mean something — the Admin wipes it clean and calls the silence tidy.' },
];
