// Admin Core (Sector 04) expedition logic — mirrors stormSpine.js.
// Route: Mirror Vestibule -> Processional -> Recursive Gate -> Cold Lanterns
//        -> [hoarding] Reliquary Vault --+-> Protocol Perch -> Reset Threshold
//        -> [memory] Echo Archive ------/
//        -> [passage] ------------------/
// The lanterns take ONE choice; the other two burn out for the expedition.
// Gates: entry needs a guardian + the Storm Spine finale (logic_bomb);
// lanterns and beyond need the gate golem; the perch's DAG also requires the
// Logic Core (enforced by the campaign node + room requiresBoss).
import { getCampaignNodeById, getCampaignNodeState } from './campaignMap';
import { dragons, PULL_COST } from './gameData';
import { ADMIN_CORE_ROOMS } from './worldZones';

export const ADMIN_CORE_CACHE_REWARD = 35;
export const ADMIN_CORE_CLEAR_REWARD = PULL_COST;
const ownsGuardian = (save, id) => typeof id === 'string' && Object.hasOwn(dragons, id) && save?.dragons?.[id]?.owned === true;
const hasGuardian = save => Object.keys(save?.dragons || {}).some(id => ownsGuardian(save, id));
const hasDefeated = (save, id) => (save?.defeatedNpcs || []).includes(id);

export function isAdminCoreRoomOpen(id, save) {
  if (typeof id !== 'string' || !Object.hasOwn(ADMIN_CORE_ROOMS, id)) return false;
  const room = ADMIN_CORE_ROOMS[id];
  if (!room) return false;
  if (!hasGuardian(save)) return false;
  // Sector 04 opens once the Storm Spine finale is down.
  if (!hasDefeated(save, 'logic_bomb')) return false;
  if (room.requiredNpc && !hasDefeated(save, room.requiredNpc)) return false;
  if (room.requiresBoss && !hasDefeated(save, room.requiresBoss)) return false;
  return true;
}

export function getAdminCoreProgress(save) {
  const raw = save?.adminCore || {};
  const roomId = isAdminCoreRoomOpen(raw.roomId, save) ? raw.roomId : 'mirror-vestibule';
  return {
    roomId,
    visited: [...new Set(['mirror-vestibule', ...(Array.isArray(raw.visited) ? raw.visited.filter(id => typeof id === 'string' && Object.hasOwn(ADMIN_CORE_ROOMS, id)) : []), roomId])],
    lantern: ['hoarding', 'memory', 'passage'].includes(raw.lantern) ? raw.lantern : null,
    archiveRead: raw.archiveRead === true,
    cacheClaimed: raw.cacheClaimed === true,
    rewardClaimed: raw.rewardClaimed === true,
    guardianId: ownsGuardian(save, raw.guardianId) ? raw.guardianId : null,
    reserveId: raw.reserveId !== raw.guardianId && ownsGuardian(save, raw.reserveId) ? raw.reserveId : null,
  };
}

export function getAdminCoreExits(save) {
  const progress = getAdminCoreProgress(save);
  return ADMIN_CORE_ROOMS[progress.roomId].exits.map(exit => ({
    ...exit,
    open: isAdminCoreRoomOpen(exit.to, save) && (!exit.route || progress.lantern === exit.route),
    reason: !hasGuardian(save) ? 'Hatch a guardian first.'
      : !hasDefeated(save, 'logic_bomb') ? 'Stabilize the Storm Spine finale first.'
        : exit.route && !progress.lantern ? 'Light one lantern. The other two burn out.'
          : exit.route && progress.lantern !== exit.route ? 'That lantern has burned out.'
            : 'Stabilize the encounter ahead to open this route.',
  }));
}

export function getAdminCoreObjective(save) {
  if (!hasGuardian(save)) return 'Hatch a guardian before the vestibule.';
  if (!hasDefeated(save, 'logic_bomb')) return 'Beat the Storm Spine Logic Core first — the Core answers to it.';
  if (!hasDefeated(save, 'recursive_golem')) return 'Unwind the Recursive Gate. When the brackets stack, pierce the loop.';
  if (!getAdminCoreProgress(save).lantern) return 'Light one cold lantern. The other two burn out.';
  if (!hasDefeated(save, 'protocol_vulture')) return 'Face the Protocol Vulture. When it perches at half strength, brace for Soul Drain.';
  if (!getAdminCoreProgress(save).rewardClaimed) return 'Cross the Reset Threshold and collect your next hatch.';
  return 'Admin Core is stable. The Singularity waits past the threshold.';
}

// Returns the same save for invalid/repeated actions. Persistence reloads the
// latest save for every action so clicks cannot replay rewards or erase wins.
export function applyAdminCoreAction(save, action, value) {
  const progress = getAdminCoreProgress(save);
  let reward = 0;
  if (action === 'move') {
    if (!getAdminCoreExits(save).some(exit => exit.to === value && exit.open)) return save;
    progress.roomId = value;
    progress.visited = [...new Set([...progress.visited, value])];
  } else if (action === 'party') {
    if (!ownsGuardian(save, value?.guardianId)) return save;
    progress.guardianId = value.guardianId;
    progress.reserveId = value.reserveId !== value.guardianId && ownsGuardian(save, value.reserveId) ? value.reserveId : null;
  } else if (action === 'choose-lantern') {
    if (progress.roomId !== 'cold-lanterns' || progress.lantern || !['hoarding', 'memory', 'passage'].includes(value)) return save;
    progress.lantern = value;
  } else if (action === 'read-archive') {
    if (progress.roomId !== 'echo-archive' || progress.archiveRead) return save;
    progress.archiveRead = true;
  } else if (action === 'claim-cache') {
    if (progress.roomId !== 'reliquary-vault' || progress.cacheClaimed) return save;
    progress.cacheClaimed = true;
    reward = ADMIN_CORE_CACHE_REWARD;
  } else if (action === 'claim-clear') {
    if (progress.roomId !== 'reset-threshold' || progress.rewardClaimed || !hasDefeated(save, 'protocol_vulture')) return save;
    progress.rewardClaimed = true;
    reward = ADMIN_CORE_CLEAR_REWARD;
  } else return save;

  return {
    ...save, adminCore: progress,
    ...(reward > 0 ? {
      dataScraps: (save.dataScraps || 0) + reward,
      stats: { ...save.stats, totalScrapsEarned: (save.stats?.totalScrapsEarned || 0) + reward },
    } : {}),
  };
}

export function getAdminCoreBattleConfig(save, dragonId, benchDragonId = null) {
  const room = ADMIN_CORE_ROOMS[getAdminCoreProgress(save).roomId];
  const node = room.nodeId ? getCampaignNodeById(room.nodeId) : null;
  if (!node || getCampaignNodeState(node, save) !== 'available' || !ownsGuardian(save, dragonId)) return null;
  const bench = benchDragonId !== dragonId && ownsGuardian(save, benchDragonId) ? benchDragonId : null;
  return { nodeId: node.id, npcId: node.npcId, dragonId, benchDragonId: bench, returnScreen: 'adminCore' };
}
