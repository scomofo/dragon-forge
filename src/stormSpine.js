// Storm Spine (Sector 03) expedition logic — mirrors frozenCache.js.
// Route: Overclock Gantry -> Live Wire -> Hydra Spine -> Fork in the Wire
//        -> [capacitor] Capacitor Bank -+-> Logic Core -> Discharge Gate
//        -> [archive] Broken Conduit --/
//        -> [direct] ------------------/
// The fork takes ONE lane; the other two arc shut for the expedition.
// Gates: entry needs a guardian + the Frozen Cache finale (crypto_crab);
// the fork and everything past it need the hydra; the gate needs the bomb.
import { getCampaignNodeById, getCampaignNodeState } from './campaignMap';
import { dragons, PULL_COST } from './gameData';
import { STORM_SPINE_ROOMS } from './worldZones';

export const STORM_SPINE_CACHE_REWARD = 25;
export const STORM_SPINE_CLEAR_REWARD = PULL_COST;
const ownsGuardian = (save, id) => typeof id === 'string' && Object.hasOwn(dragons, id) && save?.dragons?.[id]?.owned === true;
const hasGuardian = save => Object.keys(save?.dragons || {}).some(id => ownsGuardian(save, id));
const hasDefeated = (save, id) => (save?.defeatedNpcs || []).includes(id);

export function isStormSpineRoomOpen(id, save) {
  if (typeof id !== 'string' || !Object.hasOwn(STORM_SPINE_ROOMS, id)) return false;
  const room = STORM_SPINE_ROOMS[id];
  if (!room) return false;
  if (!hasGuardian(save)) return false;
  // Sector 03 opens once the Frozen Cache finale is down.
  if (!hasDefeated(save, 'crypto_crab')) return false;
  if (room.requiredNpc && !hasDefeated(save, room.requiredNpc)) return false;
  if (room.requiresBoss && !hasDefeated(save, room.requiresBoss)) return false;
  return true;
}

export function getStormSpineProgress(save) {
  const raw = save?.stormSpine || {};
  const roomId = isStormSpineRoomOpen(raw.roomId, save) ? raw.roomId : 'overclock-gantry';
  return {
    roomId,
    visited: [...new Set(['overclock-gantry', ...(Array.isArray(raw.visited) ? raw.visited.filter(id => typeof id === 'string' && Object.hasOwn(STORM_SPINE_ROOMS, id)) : []), roomId])],
    forkLane: ['capacitor', 'archive', 'direct'].includes(raw.forkLane) ? raw.forkLane : null,
    archiveRead: raw.archiveRead === true,
    cacheClaimed: raw.cacheClaimed === true,
    rewardClaimed: raw.rewardClaimed === true,
    guardianId: ownsGuardian(save, raw.guardianId) ? raw.guardianId : null,
    reserveId: raw.reserveId !== raw.guardianId && ownsGuardian(save, raw.reserveId) ? raw.reserveId : null,
  };
}

export function getStormSpineExits(save) {
  const progress = getStormSpineProgress(save);
  return STORM_SPINE_ROOMS[progress.roomId].exits.map(exit => ({
    ...exit,
    open: isStormSpineRoomOpen(exit.to, save) && (!exit.route || progress.forkLane === exit.route),
    reason: !hasGuardian(save) ? 'Hatch a guardian first.'
      : !hasDefeated(save, 'crypto_crab') ? 'Stabilize the Frozen Cache finale first.'
        : exit.route && !progress.forkLane ? 'Choose a lane — the other two arc shut.'
          : exit.route && progress.forkLane !== exit.route ? 'That lane has arced shut.'
            : 'Stabilize the encounter ahead to open this route.',
  }));
}

export function getStormSpineObjective(save) {
  if (!hasGuardian(save)) return 'Hatch a guardian before stepping onto the wire.';
  if (!hasDefeated(save, 'crypto_crab')) return 'Open the Frozen Cache Crypto Lock first — the spine is fed by it.';
  if (!hasDefeated(save, 'glitch_hydra')) return 'Climb to the ceiling grid. Each hydra head falls to a different element.';
  if (!getStormSpineProgress(save).forkLane) return 'Choose a lane at the fork. The other two arc shut.';
  if (!hasDefeated(save, 'logic_bomb')) return 'Reach the Logic Core and beat the fuse. Six turns — count them.';
  if (!getStormSpineProgress(save).rewardClaimed) return 'Reach the Discharge Gate and collect your next hatch.';
  return 'Storm Spine is stable. Return to the Forge or explore the campaign.';
}

// Returns the same save for invalid/repeated actions. Persistence reloads the
// latest save for every action so clicks cannot replay rewards or erase wins.
export function applyStormSpineAction(save, action, value) {
  const progress = getStormSpineProgress(save);
  let reward = 0;
  if (action === 'move') {
    if (!getStormSpineExits(save).some(exit => exit.to === value && exit.open)) return save;
    progress.roomId = value;
    progress.visited = [...new Set([...progress.visited, value])];
  } else if (action === 'party') {
    if (!ownsGuardian(save, value?.guardianId)) return save;
    progress.guardianId = value.guardianId;
    progress.reserveId = value.reserveId !== value.guardianId && ownsGuardian(save, value.reserveId) ? value.reserveId : null;
  } else if (action === 'choose-lane') {
    if (progress.roomId !== 'fork-in-the-wire' || progress.forkLane || !['capacitor', 'archive', 'direct'].includes(value)) return save;
    progress.forkLane = value;
  } else if (action === 'read-archive') {
    if (progress.roomId !== 'broken-conduit' || progress.archiveRead) return save;
    progress.archiveRead = true;
  } else if (action === 'claim-cache') {
    if (progress.roomId !== 'capacitor-bank' || progress.cacheClaimed) return save;
    progress.cacheClaimed = true;
    reward = STORM_SPINE_CACHE_REWARD;
  } else if (action === 'claim-clear') {
    if (progress.roomId !== 'discharge-gate' || progress.rewardClaimed || !hasDefeated(save, 'logic_bomb')) return save;
    progress.rewardClaimed = true;
    reward = STORM_SPINE_CLEAR_REWARD;
  } else return save;

  return {
    ...save, stormSpine: progress,
    ...(reward > 0 ? {
      dataScraps: (save.dataScraps || 0) + reward,
      stats: { ...save.stats, totalScrapsEarned: (save.stats?.totalScrapsEarned || 0) + reward },
    } : {}),
  };
}

export function getStormSpineBattleConfig(save, dragonId, benchDragonId = null) {
  const room = STORM_SPINE_ROOMS[getStormSpineProgress(save).roomId];
  const node = room.nodeId ? getCampaignNodeById(room.nodeId) : null;
  if (!node || getCampaignNodeState(node, save) !== 'available' || !ownsGuardian(save, dragonId)) return null;
  const bench = benchDragonId !== dragonId && ownsGuardian(save, benchDragonId) ? benchDragonId : null;
  return { nodeId: node.id, npcId: node.npcId, dragonId, benchDragonId: bench, returnScreen: 'stormSpine' };
}
