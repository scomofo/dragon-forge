// Frozen Cache (Sector 02) expedition logic — mirrors outerGrid.js.
// Route: Cold Archive -> Mute Channel -> Wraith Cache -> Thaw Junction
//        -> [thaw] Siren Loop  |  [crack] Frozen Vault -> Siren Loop
//        -> Crypto Lock -> Thaw Gate
// Gates: entry needs a guardian + the Outer Grid gatekeeper; encounters gate
// the rooms past them; the Crypto Lock also needs the Overflow Vent cleared
// (its campaign node's prerequisite). All actions validate against the latest
// save so clicks cannot replay rewards or erase wins.
import { getCampaignNodeById, getCampaignNodeState } from './campaignMap';
import { dragons, PULL_COST } from './gameData';
import { FROZEN_CACHE_ROOMS } from './worldZones';

export const FROZEN_CACHE_VAULT_REWARD = 20;
export const FROZEN_CACHE_CLEAR_REWARD = PULL_COST;
const ownsGuardian = (save, id) => typeof id === 'string' && Object.hasOwn(dragons, id) && save?.dragons?.[id]?.owned === true;
const hasGuardian = save => Object.keys(save?.dragons || {}).some(id => ownsGuardian(save, id));
const hasDefeated = (save, id) => (save?.defeatedNpcs || []).includes(id);

export function isFrozenCacheRoomOpen(id, save) {
  if (typeof id !== 'string' || !Object.hasOwn(FROZEN_CACHE_ROOMS, id)) return false;
  const room = FROZEN_CACHE_ROOMS[id];
  if (!room) return false;
  if (!hasGuardian(save)) return false;
  // Sector 02 opens once the Outer Grid gatekeeper is down.
  if (!hasDefeated(save, 'firewall_sentinel')) return false;
  if (room.requiredNpc && !hasDefeated(save, room.requiredNpc)) return false;
  if (room.requiresBoss && !hasDefeated(save, room.requiresBoss)) return false;
  return true;
}

export function getFrozenCacheProgress(save) {
  const raw = save?.frozenCache || {};
  const roomId = isFrozenCacheRoomOpen(raw.roomId, save) ? raw.roomId : 'cold-archive';
  return {
    roomId,
    visited: [...new Set(['cold-archive', ...(Array.isArray(raw.visited) ? raw.visited.filter(id => typeof id === 'string' && Object.hasOwn(FROZEN_CACHE_ROOMS, id)) : []), roomId])],
    junctionRoute: ['thaw', 'crack'].includes(raw.junctionRoute) ? raw.junctionRoute : null,
    remnantsHeard: Array.isArray(raw.remnantsHeard) ? raw.remnantsHeard.filter(n => Number.isInteger(n) && n >= 0 && n < 3) : [],
    vaultClaimed: raw.vaultClaimed === true,
    rewardClaimed: raw.rewardClaimed === true,
    guardianId: ownsGuardian(save, raw.guardianId) ? raw.guardianId : null,
    reserveId: raw.reserveId !== raw.guardianId && ownsGuardian(save, raw.reserveId) ? raw.reserveId : null,
  };
}

export function getFrozenCacheExits(save) {
  const progress = getFrozenCacheProgress(save);
  return FROZEN_CACHE_ROOMS[progress.roomId].exits.map(exit => ({
    ...exit,
    open: isFrozenCacheRoomOpen(exit.to, save) && (!exit.route || progress.junctionRoute === exit.route),
    reason: !hasGuardian(save) ? 'Hatch a guardian first.'
      : !hasDefeated(save, 'firewall_sentinel') ? 'Stabilize the Outer Grid gatekeeper first.'
        : exit.route && !progress.junctionRoute ? 'Choose how to cross the thaw junction.'
          : exit.route && progress.junctionRoute !== exit.route ? 'You chose the other crossing.'
            : 'Stabilize the encounter ahead to open this route.',
  }));
}

export function getFrozenCacheObjective(save) {
  if (!hasGuardian(save)) return 'Hatch a guardian before entering the archive.';
  if (!hasDefeated(save, 'firewall_sentinel')) return 'Stabilize the Outer Grid gatekeeper first — the archive opens after Signal Breach.';
  if (!hasDefeated(save, 'bit_wraith')) return 'Follow the Mute Channel and quiet the Bit Wraith.';
  if (!hasDefeated(save, 'phishing_siren')) return 'Cross the Thaw Junction and break the Siren Loop.';
  if (!hasDefeated(save, 'buffer_overflow')) return 'The Crypto Lock is sealed by the Overflow Vent — return to the Outer Grid and cool it first.';
  if (!hasDefeated(save, 'crypto_crab')) return 'Open the Crypto Lock. The crab remembers your last element — repeat it.';
  if (!getFrozenCacheProgress(save).rewardClaimed) return 'Reach the Thaw Gate and collect your next hatch.';
  return 'Frozen Cache is stable. Return to the Forge or explore the campaign.';
}

// Returns the same save for invalid/repeated actions. Persistence reloads the
// latest save for every action so clicks cannot replay rewards or erase wins.
export function applyFrozenCacheAction(save, action, value) {
  const progress = getFrozenCacheProgress(save);
  let reward = 0;
  if (action === 'move') {
    if (!getFrozenCacheExits(save).some(exit => exit.to === value && exit.open)) return save;
    progress.roomId = value;
    progress.visited = [...new Set([...progress.visited, value])];
  } else if (action === 'party') {
    if (!ownsGuardian(save, value?.guardianId)) return save;
    progress.guardianId = value.guardianId;
    progress.reserveId = value.reserveId !== value.guardianId && ownsGuardian(save, value.reserveId) ? value.reserveId : null;
  } else if (action === 'choose-route') {
    if (progress.roomId !== 'thaw-junction' || progress.junctionRoute || !['thaw', 'crack'].includes(value)) return save;
    progress.junctionRoute = value;
  } else if (action === 'hear-remnant') {
    if (progress.roomId !== 'cold-archive') return save;
    const index = Number(value);
    if (!Number.isInteger(index) || index < 0 || index > 2 || progress.remnantsHeard.includes(index)) return save;
    progress.remnantsHeard = [...progress.remnantsHeard, index];
  } else if (action === 'claim-vault') {
    if (progress.roomId !== 'frozen-vault' || progress.vaultClaimed) return save;
    progress.vaultClaimed = true;
    reward = FROZEN_CACHE_VAULT_REWARD;
  } else if (action === 'claim-clear') {
    if (progress.roomId !== 'thaw-gate' || progress.rewardClaimed || !hasDefeated(save, 'crypto_crab')) return save;
    progress.rewardClaimed = true;
    reward = FROZEN_CACHE_CLEAR_REWARD;
  } else return save;

  return {
    ...save, frozenCache: progress,
    ...(reward > 0 ? {
      dataScraps: (save.dataScraps || 0) + reward,
      stats: { ...save.stats, totalScrapsEarned: (save.stats?.totalScrapsEarned || 0) + reward },
    } : {}),
  };
}

export function getFrozenCacheBattleConfig(save, dragonId, benchDragonId = null) {
  const room = FROZEN_CACHE_ROOMS[getFrozenCacheProgress(save).roomId];
  const node = room.nodeId ? getCampaignNodeById(room.nodeId) : null;
  if (!node || getCampaignNodeState(node, save) !== 'available' || !ownsGuardian(save, dragonId)) return null;
  const bench = benchDragonId !== dragonId && ownsGuardian(save, benchDragonId) ? benchDragonId : null;
  return { nodeId: node.id, npcId: node.npcId, dragonId, benchDragonId: bench, returnScreen: 'frozenCache' };
}
