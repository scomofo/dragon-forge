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
