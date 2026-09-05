// Four authored zones for the 1.0 cartridge.
// Campaign nodes keep their current DAG. Outer Grid now has an authored
// room route; the other three zones remain P3 skeletons.
// Docs: design/gdd/snes-aaa-roadmap.md

export const WORLD_ZONE_IDS = ['outer_grid', 'frozen_cache', 'storm_spine', 'admin_core'];

export const WORLD_ZONES = {
  outer_grid: {
    id: 'outer_grid',
    name: 'Outer Grid',
    elements: ['stone', 'fire'],
    kicker: 'SECTOR 01 — OUTER GRID',
    setpiece: 'A firewall span collapses into packet-rain. Cross it or drop into Overflow Vent.',
    labRoom: 'Felix field locker — first guardian briefing and a safe return.',
    midBossNodeId: 'signal-breach',
    bossNodeId: 'overflow-vent',
    nodeIds: ['signal-breach', 'overflow-vent'],
    music: 'mapWander',
  },
  frozen_cache: {
    id: 'frozen_cache',
    name: 'Frozen Cache',
    elements: ['ice', 'venom', 'shadow'],
    kicker: 'SECTOR 02 — FROZEN CACHE',
    setpiece: 'Muted screaming channel. Ice holds a corridor of frozen processes in place.',
    labRoom: 'Cold archive — Crypto Lock antechamber with three talking remnants.',
    midBossNodeId: 'siren-loop',
    bossNodeId: 'crypto-lock',
    nodeIds: ['wraith-cache', 'crypto-lock', 'siren-loop'],
    music: 'mapWander',
  },
  storm_spine: {
    id: 'storm_spine',
    name: 'Storm Spine',
    elements: ['storm', 'fire'],
    kicker: 'SECTOR 03 — STORM SPINE',
    setpiece: 'Three-headed fork in the wire. Choose a lane; the other two arc shut.',
    labRoom: 'Overclock gantry — Glitch Hydra watches from the ceiling grid.',
    midBossNodeId: 'logic-core',
    bossNodeId: 'hydra-spine',
    nodeIds: ['hydra-spine', 'logic-core'],
    music: 'singularity',
  },
  admin_core: {
    id: 'admin_core',
    name: 'Admin Core',
    elements: ['stone', 'shadow', 'void', 'light'],
    kicker: 'SECTOR 04 — ADMIN CORE',
    setpiece: 'The Great Reset antechamber. Save lanterns burn cold. The world can still be walked.',
    labRoom: 'Mirror vestibule — Felix\'s last unscripted line before Protocol.',
    midBossNodeId: 'recursive-gate',
    bossNodeId: 'protocol-perch',
    nodeIds: ['recursive-gate', 'protocol-perch'],
    music: 'singularity',
  },
};

export function getZone(zoneId) {
  return WORLD_ZONES[zoneId] || null;
}

export function getZoneForNode(nodeId) {
  return Object.values(WORLD_ZONES).find((zone) => zone.nodeIds.includes(nodeId)) || null;
}

export const OUTER_GRID_ROOMS = {
  'field-locker': {
    id: 'field-locker', name: "Felix's Field Locker", kind: 'Shelter',
    background: '/assets/backgrounds/forge_bg.webp',
    description: 'Beyond the bulkhead, a broken signal is pulling the Outer Grid apart. Felix has left the return lantern lit.',
    inspect: 'Felix: "Stay close to your guardian. Open Signal Breach, follow the failing span, then cool the Overflow Vent. Bring both of you home."',
    exits: [{ to: 'signal-approach', label: 'Leave for Signal Approach', x: 88 }],
  },
  'signal-approach': {
    id: 'signal-approach', name: 'Signal Approach', kind: 'Outer path',
    background: '/assets/arenas/stone.webp',
    description: 'Blue current crawls beneath the stone. Beyond the arch, a shield rises and falls in a steady rhythm.',
    inspect: 'The marks on the wall repeat: shield, pause, opening. A patient guardian can wait out the Sentinel by defending before striking.',
    exits: [{ to: 'field-locker', label: 'Back to Field Locker', x: 12 }, { to: 'signal-breach', label: 'Approach the Sentinel', x: 88 }],
  },
  'signal-breach': {
    id: 'signal-breach', name: 'Signal Breach', kind: 'Gatekeeper',
    background: '/assets/arenas/npc_firewall_sentinel.webp',
    description: 'The Firewall Sentinel blocks the passage. Its packet shield snaps shut as you approach.',
    clearedDescription: 'The shield is quiet. An opening leads deeper into the failing span.',
    nodeId: 'signal-breach',
    exits: [{ to: 'signal-approach', label: 'Back to Signal Approach', x: 12 }, { to: 'firewall-span', label: 'Cross to Firewall Span', x: 88 }],
  },
  'firewall-span': {
    id: 'firewall-span', name: 'Firewall Span', kind: 'Crossing',
    background: '/assets/arenas/stone.webp', requiredNpc: 'firewall_sentinel',
    description: 'The span fractures into falling packets. The upper brace still holds; a maintenance crawlway opens below.',
    inspect: 'Brace the upper span for a direct crossing, or take the lower crawlway to search its supply cache. Both routes reach the Overflow Vent.',
    exits: [
      { to: 'signal-breach', label: 'Back to Signal Breach', x: 12 },
      { to: 'overflow-vent', label: 'Cross the braced span', x: 88, route: 'span' },
      { to: 'maintenance-cache', label: 'Take the lower crawlway', x: 74, route: 'crawlway' },
    ],
  },
  'maintenance-cache': {
    id: 'maintenance-cache', name: 'Maintenance Cache', kind: 'Hidden room',
    background: '/assets/arenas/gravity_chamber.webp', requiredNpc: 'firewall_sentinel',
    description: 'A forgotten supply locker survived beneath the span. Its scraps could help wake another guardian.',
    inspect: 'A dented maintenance tag reads: "Leave the lantern on. Someone always comes back."',
    exits: [{ to: 'firewall-span', label: 'Climb back to the span', x: 12 }, { to: 'overflow-vent', label: 'Follow the heat to Overflow Vent', x: 88 }],
  },
  'overflow-vent': {
    id: 'overflow-vent', name: 'Overflow Vent', kind: 'Zone finale',
    background: '/assets/arenas/npc_buffer_overflow.webp', requiredNpc: 'firewall_sentinel',
    description: 'The overflow coils glow white. A corrupted guardian hoards the heat, one unstable stack at a time.',
    clearedDescription: 'The heat recedes. Through the settling ash, the return gate answers Felix\'s lantern.',
    nodeId: 'overflow-vent',
    exits: [{ to: 'firewall-span', label: 'Back toward the span', x: 12 }, { to: 'return-gate', label: 'Follow the return signal', x: 88 }],
  },
  'return-gate': {
    id: 'return-gate', name: 'Return Gate', kind: 'Homeward path',
    background: '/assets/forge/station_bulkhead.webp', requiredNpc: 'buffer_overflow',
    description: 'The signal holds. Felix has set aside enough scraps for another hatch. The Forge is waiting.',
    inspect: 'Felix: "You brought the signal back. More importantly, you came back together. There is room beside the anvil for both of you."',
    exits: [{ to: 'overflow-vent', label: 'Back to the quiet vent', x: 12 }, { to: 'field-locker', label: 'Return to Field Locker', x: 88 }],
  },
};

// Sector 02 — Frozen Cache. Lab room + path + wraith encounter + the thaw
// setpiece (direct slow thaw, or crack the deep freeze for the vault cache)
// + siren mid-boss + crypto finale + homeward gate. Campaign prerequisites
// hold: entry needs the Outer Grid gatekeeper; the Crypto Lock still waits
// for the Overflow Vent.
export const FROZEN_CACHE_ROOMS = {
  'cold-archive': {
    id: 'cold-archive', name: 'Cold Archive', kind: 'Shelter',
    background: '/assets/arenas/ice.webp',
    description: 'Three frozen processes hang in the ice, mid-scream, mid-thought, mid-lie. The ice keeps them honest. Mostly.',
    inspect: 'The archive hums at a pitch you feel in your teeth. Each remnant is a process the Grid froze before it could finish.',
    exits: [{ to: 'mute-channel', label: 'Enter the Mute Channel', x: 88 }],
  },
  'mute-channel': {
    id: 'mute-channel', name: 'Mute Channel', kind: 'Frozen corridor',
    background: '/assets/arenas/shadow.webp',
    description: 'The screaming channel, muted. Sound moves through the ice like light through dirty glass — slow and wrong.',
    inspect: 'Frozen packets hang in rows like pinned moths. One shadow among them is still warm.',
    exits: [{ to: 'cold-archive', label: 'Back to Cold Archive', x: 12 }, { to: 'wraith-cache', label: 'Approach the warm shadow', x: 88 }],
  },
  'wraith-cache': {
    id: 'wraith-cache', name: 'Wraith Cache', kind: 'Encounter',
    background: '/assets/arenas/npc_bit_wraith.webp',
    description: 'A Bit Wraith coils around a forgotten memory cache, drinking what the ice preserved.',
    clearedDescription: 'The wraith is quiet. The cache it guarded bleeds cold light toward the junction.',
    nodeId: 'wraith-cache',
    exits: [{ to: 'mute-channel', label: 'Back to Mute Channel', x: 12 }, { to: 'thaw-junction', label: 'Follow the cold light', x: 88 }],
  },
  'thaw-junction': {
    id: 'thaw-junction', name: 'Thaw Junction', kind: 'Setpiece',
    background: '/assets/arenas/ice.webp', requiredNpc: 'bit_wraith',
    description: 'The corridor splits around a frozen core. You can coax the thaw upward — or crack the deep freeze below and take your chances in the vault.',
    inspect: 'The slow thaw is safe and direct. The deep freeze hides a sealed vault: more to carry, if you can carry it.',
    exits: [
      { to: 'wraith-cache', label: 'Back to Wraith Cache', x: 12 },
      { to: 'siren-loop', label: 'Take the slow thaw', x: 88, route: 'thaw' },
      { to: 'frozen-vault', label: 'Descend into the vault', x: 74, route: 'crack' },
    ],
  },
  'frozen-vault': {
    id: 'frozen-vault', name: 'Frozen Vault', kind: 'Hidden room',
    background: '/assets/arenas/shadow.webp', requiredNpc: 'bit_wraith',
    description: 'Below the junction, a vault of unclaimed processes. Their hoarded scraps never thawed.',
    inspect: 'A maintenance tag, frozen mid-print: "Cold keeps what fire forgets."',
    exits: [{ to: 'thaw-junction', label: 'Climb back to the junction', x: 12 }, { to: 'siren-loop', label: 'Follow the lure toward Siren Loop', x: 88 }],
  },
  'siren-loop': {
    id: 'siren-loop', name: 'Siren Loop', kind: 'Mid-boss',
    background: '/assets/arenas/npc_phishing_siren.webp', requiredNpc: 'bit_wraith',
    description: 'A venomous lure repeats through the damaged lanes. The Phishing Siren has been singing to the ice for a long time.',
    clearedDescription: 'The loop is broken. The lanes carry only your own footsteps now — toward the lock.',
    nodeId: 'siren-loop',
    exits: [{ to: 'thaw-junction', label: 'Back to Thaw Junction', x: 12 }, { to: 'crypto-lock', label: 'Approach the Crypto Lock', x: 88 }],
  },
  'crypto-lock': {
    id: 'crypto-lock', name: 'Crypto Lock', kind: 'Zone finale',
    background: '/assets/arenas/npc_crypto_crab.webp', requiredNpc: 'phishing_siren', requiresBoss: 'buffer_overflow',
    description: 'Frozen ciphers seal the route inward. The Crypto Crab turns its shell to face you: ENCRYPTED, it says, in every pixel.',
    clearedDescription: 'The lock opens. What the ice held in place is finally, quietly, let go.',
    nodeId: 'crypto-lock',
    exits: [{ to: 'siren-loop', label: 'Back to Siren Loop', x: 12 }, { to: 'thaw-gate', label: 'Follow the thaw out', x: 88 }],
  },
  'thaw-gate': {
    id: 'thaw-gate', name: 'Thaw Gate', kind: 'Homeward path',
    background: '/assets/forge/station_bulkhead.webp', requiresBoss: 'crypto_crab',
    description: 'The channel hums at room temperature. Felix has wired your next hatch to the return lantern.',
    inspect: 'Felix: "You listened to the frozen ones and brought the silence back warm. That is rarer than you know."',
    exits: [{ to: 'crypto-lock', label: 'Back to the quiet lock', x: 12 }, { to: 'cold-archive', label: 'Return to Cold Archive', x: 88 }],
  },
};
