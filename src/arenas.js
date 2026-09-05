// P1.1 arena registry — battle truth for every arena the cartridge renders.
//
// Eleven arenas are referenced by battle code (9 NPC + shadow + the
// gravity chamber). All eleven are authored 1024x1024 art from the P1
// pass (handoff/ARENA_AND_FORGE_BRIEF.md), generated + converted to webp.
// (The old magma.webp / lightning.webp files were unkeyed dragon sprite
// sheets posing as arenas — removed 2026-09-05; they were never in this
// registry or referenced by battle code.)
//
// Filter ratchet: grade-only filters (saturate/contrast/brightness) pass
// through. Hue-rotate/grayscale are content filters — a new actor or arena
// must ship its own cells, never a filter over another file. The seven
// current content-filter users are locked below; tests reject an eighth.
import { assetUrl } from './utils';
import { BATTLE_CELL, hasBannedFilter, isKnownPlaceholderArena } from './artBible';

export const ARENA_STATUS = {
  AUTHORED: 'authored',
  PLACEHOLDER: 'placeholder',
};

const arena = (file, status) => ({
  src: assetUrl(`/assets/arenas/${file}.png`),
  status,
  width: BATTLE_CELL.arenaWidth,
  height: BATTLE_CELL.arenaHeight,
});

export const ARENAS = {
  npc_firewall_sentinel: arena('npc_firewall_sentinel', ARENA_STATUS.AUTHORED),
  npc_bit_wraith: arena('npc_bit_wraith', ARENA_STATUS.AUTHORED),
  npc_glitch_hydra: arena('npc_glitch_hydra', ARENA_STATUS.AUTHORED),
  npc_recursive_golem: arena('npc_recursive_golem', ARENA_STATUS.AUTHORED),
  npc_buffer_overflow: arena('npc_buffer_overflow', ARENA_STATUS.AUTHORED),
  npc_crypto_crab: arena('npc_crypto_crab', ARENA_STATUS.AUTHORED),
  npc_logic_bomb: arena('npc_logic_bomb', ARENA_STATUS.AUTHORED),
  npc_phishing_siren: arena('npc_phishing_siren', ARENA_STATUS.AUTHORED),
  npc_protocol_vulture: arena('npc_protocol_vulture', ARENA_STATUS.AUTHORED),
  shadow: arena('shadow', ARENA_STATUS.AUTHORED),
  gravity_chamber: arena('gravity_chamber', ARENA_STATUS.AUTHORED),
};

// Boss ids whose arenaFilter relies on a content filter (hue-rotate or
// grayscale). Locked: fix by shipping authored arenas, not by adding users.
// The Singularity's saturate/contrast grade is allowlisted, so it is absent.
export const KNOWN_CONTENT_FILTER_ARENAS = [
  'data_corruption',
  'memory_leak',
  'stack_overflow',
  'mirror_admin',
  'data_corruption_remnant',
  'memory_leak_remnant',
  'stack_overflow_remnant',
];

export function getArena(id) {
  return ARENAS[id] || null;
}

export function listArenaUrls() {
  return Object.values(ARENAS).map((entry) => entry.src);
}

export function isGradeOnlyFilter(filter) {
  if (!filter) return true;
  return !hasBannedFilter(filter);
}

// Central battle-arena resolution. Output matches today's rendering exactly;
// the flags exist so tests and debug attributes can tell placeholder and
// content-filter debt apart from shippable art.
export function resolveBattleArena({ arena: arenaUrl, arenaFilter } = {}) {
  return {
    src: arenaUrl,
    filter: arenaFilter || 'none',
    placeholder: isKnownPlaceholderArena(arenaUrl),
    contentFilter: hasBannedFilter(arenaFilter),
  };
}
