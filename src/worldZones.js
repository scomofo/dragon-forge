// Four authored zones for the 1.0 cartridge.
// Campaign nodes keep their current DAG; this file is the P3 skeleton
// that later rooms / setpieces / Godot tiles must obey.
// Docs: design/gdd/snes-aaa-roadmap.md

export const WORLD_ZONE_IDS = ['outer_grid', 'frozen_cache', 'storm_spine', 'admin_core'];

export const WORLD_ZONES = {
  outer_grid: {
    id: 'outer_grid',
    name: 'Outer Grid',
    elements: ['stone', 'fire'],
    kicker: 'SECTOR 01 — OUTER GRID',
    setpiece: 'A firewall span collapses into packet-rain. Cross it or drop into Overflow Vent.',
    labRoom: 'Felix field locker — first Captain\'s Log, free pull recap.',
    midBossNodeId: 'overflow-vent',
    bossNodeId: 'signal-breach',
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
