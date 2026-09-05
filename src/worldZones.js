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
    // DAG order (hydra-spine unlocks logic-core) makes the hydra the mid-boss
    // and the Logic Core the finale.
    midBossNodeId: 'hydra-spine',
    bossNodeId: 'logic-core',
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

// Sector 03 — Storm Spine. Gantry shelter (the hydra watches from the ceiling
// grid the whole time) -> live wire -> hydra mid-boss -> the three-lane fork
// (choose one: capacitor cache, conduit archive, or the direct lane — the
// other two arc shut for the expedition) -> Logic Core finale -> homeward.
// Entry needs the Frozen Cache finale (crypto_crab), matching the DAG.
export const STORM_SPINE_ROOMS = {
  'overclock-gantry': {
    id: 'overclock-gantry', name: 'Overclock Gantry', kind: 'Shelter',
    background: '/assets/arenas/storm.webp',
    description: 'A maintenance gantry over the storm spine. Somewhere above the grid, three pairs of eyes open in sequence, then close.',
    inspect: 'Felix, by wire: "The hydra watches from the ceiling grid. Three heads, three tempers — each one falls only to a different element. Count your lanes before you commit."',
    exits: [{ to: 'live-wire', label: 'Step onto the live wire', x: 88 }],
  },
  'live-wire': {
    id: 'live-wire', name: 'Live Wire', kind: 'Charged path',
    background: '/assets/arenas/storm.webp',
    description: 'Current runs along the gantry floor in standing waves. Step between pulses and the wire only hums.',
    inspect: 'Scorch marks alternate with frost blooms — storm and fire share this spine, and neither shares well.',
    exits: [{ to: 'overclock-gantry', label: 'Back to the gantry', x: 12 }, { to: 'hydra-spine', label: 'Approach the ceiling grid', x: 88 }],
  },
  'hydra-spine': {
    id: 'hydra-spine', name: 'Hydra Spine', kind: 'Mid-boss',
    background: '/assets/arenas/npc_glitch_hydra.webp',
    description: 'The Glitch Hydra uncoils from the ceiling grid, three heads arguing in packet loss.',
    clearedDescription: 'The heads hang quiet, still arguing in static. The fork ahead is live.',
    nodeId: 'hydra-spine',
    exits: [{ to: 'live-wire', label: 'Back to the live wire', x: 12 }, { to: 'fork-in-the-wire', label: 'Enter the fork', x: 88 }],
  },
  'fork-in-the-wire': {
    id: 'fork-in-the-wire', name: 'Fork in the Wire', kind: 'Setpiece',
    background: '/assets/arenas/storm.webp', requiredNpc: 'glitch_hydra',
    description: 'The spine splits into three lanes: a charged capacitor bank, a broken conduit whispering old logs, and a bare direct bus. Pick one — the other two arc shut.',
    inspect: 'Charge pools in the capacitor lane. The conduit lane carries the hydra\'s origin logs. The direct bus is fastest and holds nothing.',
    exits: [
      { to: 'hydra-spine', label: 'Back to the hydra', x: 12 },
      { to: 'capacitor-bank', label: 'Ride the capacitor lane', x: 64, route: 'capacitor' },
      { to: 'broken-conduit', label: 'Enter the conduit lane', x: 76, route: 'archive' },
      { to: 'logic-core', label: 'Take the direct bus', x: 88, route: 'direct' },
    ],
  },
  'capacitor-bank': {
    id: 'capacitor-bank', name: 'Capacitor Bank', kind: 'Hidden room',
    background: '/assets/arenas/storm.webp', requiredNpc: 'glitch_hydra',
    description: 'Charged cells hum in rows, overfull. Their stored scraps never made it to the front line.',
    inspect: 'A charge tag reads: "Store it where the storm can\'t reach." The storm reached anyway.',
    exits: [{ to: 'fork-in-the-wire', label: 'Back to the fork', x: 12 }, { to: 'logic-core', label: 'Discharge toward the Logic Core', x: 88 }],
  },
  'broken-conduit': {
    id: 'broken-conduit', name: 'Broken Conduit', kind: 'Lore room',
    background: '/assets/arenas/shadow.webp', requiredNpc: 'glitch_hydra',
    description: 'The conduit is cracked open, spooling the hydra\'s origin logs into the dark.',
    inspect: 'Log fragment: "Three heads were cheaper than three watchdogs. We regret the savings." Another: "It still thinks it is guarding the fork."',
    exits: [{ to: 'fork-in-the-wire', label: 'Back to the fork', x: 12 }, { to: 'logic-core', label: 'Follow the logs to the Logic Core', x: 88 }],
  },
  'logic-core': {
    id: 'logic-core', name: 'Logic Core', kind: 'Zone finale',
    background: '/assets/arenas/npc_logic_bomb.webp', requiredNpc: 'glitch_hydra',
    description: 'A Logic Bomb ticks in the core cradle, fuse burning down in orderly turns. It has been patient. It is done being patient.',
    clearedDescription: 'The fuse is out. The core spins down to a clean, honest hum.',
    nodeId: 'logic-core',
    exits: [{ to: 'fork-in-the-wire', label: 'Back to the fork', x: 12 }, { to: 'discharge-gate', label: 'Follow the discharge out', x: 88 }],
  },
  'discharge-gate': {
    id: 'discharge-gate', name: 'Discharge Gate', kind: 'Homeward path',
    background: '/assets/forge/station_bulkhead.webp', requiresBoss: 'logic_bomb',
    description: 'The spine grounds itself into the return rail. Felix has your next hatch wired and waiting.',
    inspect: 'Felix, by wire: "You picked a lane and lived with it. That is the whole trick. Come home."',
    exits: [{ to: 'logic-core', label: 'Back to the quiet core', x: 12 }, { to: 'overclock-gantry', label: 'Return to the gantry', x: 88 }],
  },
};

// Sector 04 — Admin Core. The Great Reset antechamber: the mirror vestibule
// (Felix's last unscripted line), the processional, the Recursive Gate, then
// the cold-lantern setpiece — three save lanterns burn cold; you light ONE
// (hoarding = reliquary cache, memory = the Reset's origin logs, passage =
// the direct walk) and the other two burn out for the expedition. The
// Protocol Perch waits past it; the Reset Threshold leads home. Entry needs
// the Storm Spine finale (logic_bomb); the perch also needs the gate golem,
// matching the DAG.
export const ADMIN_CORE_ROOMS = {
  'mirror-vestibule': {
    id: 'mirror-vestibule', name: 'Mirror Vestibule', kind: 'Shelter',
    background: '/assets/arenas/shadow.webp',
    description: 'The antechamber of the Great Reset. Your reflection keeps perfect time; you do not. Somewhere past the glass, Protocol rehearses.',
    inspect: 'Felix\'s last unscripted line is scrawled under the mirror: "They will offer you a clean world. Check the price tag. The old one is still yours to walk."',
    exits: [{ to: 'processional', label: 'Walk the processional', x: 88 }],
  },
  'processional': {
    id: 'processional', name: 'Processional', kind: 'Cold path',
    background: '/assets/arenas/stone.webp',
    description: 'Save lanterns line the walk, burning cold — every flame a world someone chose to keep.',
    inspect: 'Each lantern is a checkpoint someone never returned to. The brackets on the gate ahead nest deeper the longer you look.',
    exits: [{ to: 'mirror-vestibule', label: 'Back to the vestibule', x: 12 }, { to: 'recursive-gate', label: 'Approach the Recursive Gate', x: 88 }],
  },
  'recursive-gate': {
    id: 'recursive-gate', name: 'Recursive Gate', kind: 'Mid-boss',
    background: '/assets/arenas/npc_recursive_golem.webp',
    description: 'The Recursive Golem hardens in loops, brackets within brackets, a gate that locks itself locking itself.',
    clearedDescription: 'The loops unwind to a single open bracket. The lanterns ahead wait to be chosen.',
    nodeId: 'recursive-gate',
    exits: [{ to: 'processional', label: 'Back to the processional', x: 12 }, { to: 'cold-lanterns', label: 'Approach the cold lanterns', x: 88 }],
  },
  'cold-lanterns': {
    id: 'cold-lanterns', name: 'Cold Lanterns', kind: 'Setpiece',
    background: '/assets/arenas/gravity_chamber.webp', requiredNpc: 'recursive_golem',
    description: 'Three save lanterns burn cold over the antechamber: one over a hoard, one over a memory, one over the open walk. You can light exactly one. The other two burn out.',
    inspect: 'Hoarding warms the reliquary vault. Memory warms the echo archive. Passage warms nothing but the road.',
    exits: [
      { to: 'recursive-gate', label: 'Back to the gate', x: 12 },
      { to: 'reliquary-vault', label: 'Follow the hoarding light', x: 64, route: 'hoarding' },
      { to: 'echo-archive', label: 'Follow the memory light', x: 76, route: 'memory' },
      { to: 'protocol-perch', label: 'Follow the passage light', x: 88, route: 'passage' },
    ],
  },
  'reliquary-vault': {
    id: 'reliquary-vault', name: 'Reliquary Vault', kind: 'Hidden room',
    background: '/assets/arenas/lightning.webp', requiredNpc: 'recursive_golem',
    description: 'A vault of unspent saves — hoarded scraps from runs that never happened, still warm with potential.',
    inspect: 'A reliquary plaque: "Saved for later." Later never came. It can come for you.',
    exits: [{ to: 'cold-lanterns', label: 'Back to the lanterns', x: 12 }, { to: 'protocol-perch', label: 'Carry the light to the perch', x: 88 }],
  },
  'echo-archive': {
    id: 'echo-archive', name: 'Echo Archive', kind: 'Lore room',
    background: '/assets/arenas/lightning.webp', requiredNpc: 'recursive_golem',
    description: 'The archive holds the first draft of the Great Reset — and the signature at the bottom is not the Admin\'s.',
    inspect: 'Draft zero of the Reset: "Wipe the Grid clean; begin again blameless." The margin note, in Felix\'s hand: "Blameless is not the same as kind."',
    exits: [{ to: 'cold-lanterns', label: 'Back to the lanterns', x: 12 }, { to: 'protocol-perch', label: 'Carry the memory to the perch', x: 88 }],
  },
  'protocol-perch': {
    id: 'protocol-perch', name: 'Protocol Perch', kind: 'Zone finale',
    background: '/assets/arenas/npc_protocol_vulture.webp', requiredNpc: 'recursive_golem', requiresBoss: 'logic_bomb',
    description: 'The Protocol Vulture roosts over the last door, patient as policy. At half strength it will perch — and drain what it is owed.',
    clearedDescription: 'The perch stands empty. Policy, it turns out, can be outlasted.',
    nodeId: 'protocol-perch',
    exits: [{ to: 'cold-lanterns', label: 'Back to the lanterns', x: 12 }, { to: 'reset-threshold', label: 'Approach the Reset Threshold', x: 88 }],
  },
  'reset-threshold': {
    id: 'reset-threshold', name: 'Reset Threshold', kind: 'Homeward path',
    background: '/assets/forge/station_bulkhead.webp', requiresBoss: 'protocol_vulture',
    description: 'The last door before the Singularity opens inward — toward home. Felix kept your lantern lit the whole time.',
    inspect: 'Felix: "You walked the old world when they offered you a new one. That is why there is still a world to walk."',
    exits: [{ to: 'protocol-perch', label: 'Back to the empty perch', x: 12 }, { to: 'mirror-vestibule', label: 'Return to the vestibule', x: 88 }],
  },
};
