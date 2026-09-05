import { getCampaignNodeById, getCampaignNodeState } from './campaignMap';
import { dragons, PULL_COST } from './gameData';
import { OUTER_GRID_ROOMS } from './worldZones';

export const OUTER_GRID_CACHE_REWARD = 15;
export const OUTER_GRID_CLEAR_REWARD = PULL_COST;
const ownsGuardian = (save, id) => typeof id === 'string' && Object.hasOwn(dragons, id) && save?.dragons?.[id]?.owned === true;
const hasGuardian = save => Object.keys(save?.dragons || {}).some(id => ownsGuardian(save, id));
const hasDefeated = (save, id) => (save?.defeatedNpcs || []).includes(id);

export function isOuterGridRoomOpen(id, save) {
  if (typeof id !== 'string' || !Object.hasOwn(OUTER_GRID_ROOMS, id)) return false;
  const room = OUTER_GRID_ROOMS[id];
  if (!room) return false;
  if (id !== 'field-locker' && !hasGuardian(save)) return false;
  if (room.requiredNpc && !hasDefeated(save, room.requiredNpc)) return false;
  if (id === 'return-gate' && !hasDefeated(save, 'firewall_sentinel')) return false;
  return true;
}

export function getOuterGridProgress(save) {
  const raw = save?.outerGrid || {};
  const roomId = isOuterGridRoomOpen(raw.roomId, save) ? raw.roomId : 'field-locker';
  return {
    roomId,
    visited: [...new Set(['field-locker', ...(Array.isArray(raw.visited) ? raw.visited.filter(id => typeof id === 'string' && Object.hasOwn(OUTER_GRID_ROOMS, id)) : []), roomId])],
    spanRoute: ['span', 'crawlway'].includes(raw.spanRoute) ? raw.spanRoute : null,
    fieldNoteRead: raw.fieldNoteRead === true,
    cacheClaimed: raw.cacheClaimed === true,
    rewardClaimed: raw.rewardClaimed === true,
    guardianId: ownsGuardian(save, raw.guardianId) ? raw.guardianId : null,
    reserveId: raw.reserveId !== raw.guardianId && ownsGuardian(save, raw.reserveId) ? raw.reserveId : null,
  };
}

export function getOuterGridExits(save) {
  const progress = getOuterGridProgress(save);
  return OUTER_GRID_ROOMS[progress.roomId].exits.map(exit => ({
    ...exit,
    open: isOuterGridRoomOpen(exit.to, save) && (!exit.route || progress.spanRoute === exit.route),
    reason: !hasGuardian(save) ? 'Hatch a guardian first.'
      : exit.route && !progress.spanRoute ? 'Choose how to cross the span.'
        : exit.route && progress.spanRoute !== exit.route ? 'You chose the other crossing.'
          : 'Stabilize the encounter ahead to open this route.',
  }));
}

export function getOuterGridObjective(save) {
  if (!hasGuardian(save)) return 'Hatch your first guardian before leaving the locker.';
  if (!hasDefeated(save, 'firewall_sentinel')) return 'Open Signal Breach. Defend against the packet shield, then strike.';
  if (!hasDefeated(save, 'buffer_overflow')) return 'Cross Firewall Span and stabilize the Overflow Vent.';
  if (!getOuterGridProgress(save).rewardClaimed) return 'Reach the Return Gate and collect your next hatch.';
  return 'Outer Grid is stable. Return to the Forge or explore the campaign.';
}

// Returns the same save for invalid/repeated actions. Persistence reloads the
// latest save for every action so clicks cannot replay rewards or erase wins.
export function applyOuterGridAction(save, action, value) {
  const progress = getOuterGridProgress(save);
  let reward = 0;
  if (action === 'move') {
    if (!getOuterGridExits(save).some(exit => exit.to === value && exit.open)) return save;
    progress.roomId = value;
    progress.visited = [...new Set([...progress.visited, value])];
  } else if (action === 'party') {
    if (!ownsGuardian(save, value?.guardianId)) return save;
    progress.guardianId = value.guardianId;
    progress.reserveId = value.reserveId !== value.guardianId && ownsGuardian(save, value.reserveId) ? value.reserveId : null;
  } else if (action === 'choose-route') {
    if (progress.roomId !== 'firewall-span' || progress.spanRoute || !['span', 'crawlway'].includes(value)) return save;
    progress.spanRoute = value;
  } else if (action === 'read-note') {
    if (progress.roomId !== 'field-locker' || progress.fieldNoteRead) return save;
    progress.fieldNoteRead = true;
  } else if (action === 'claim-cache') {
    if (progress.roomId !== 'maintenance-cache' || progress.cacheClaimed) return save;
    progress.cacheClaimed = true;
    reward = OUTER_GRID_CACHE_REWARD;
  } else if (action === 'claim-clear') {
    if (progress.roomId !== 'return-gate' || progress.rewardClaimed || !hasDefeated(save, 'firewall_sentinel') || !hasDefeated(save, 'buffer_overflow')) return save;
    progress.rewardClaimed = true;
    reward = OUTER_GRID_CLEAR_REWARD;
  } else return save;

  return {
    ...save, outerGrid: progress,
    ...(reward > 0 ? {
      dataScraps: (save.dataScraps || 0) + reward,
      stats: { ...save.stats, totalScrapsEarned: (save.stats?.totalScrapsEarned || 0) + reward },
    } : {}),
  };
}

export function getOuterGridBattleConfig(save, dragonId, benchDragonId = null) {
  const room = OUTER_GRID_ROOMS[getOuterGridProgress(save).roomId];
  const node = getCampaignNodeById(room.nodeId);
  if (!node || getCampaignNodeState(node, save) !== 'available' || !ownsGuardian(save, dragonId)) return null;
  const bench = benchDragonId !== dragonId && ownsGuardian(save, benchDragonId) ? benchDragonId : null;
  return { nodeId: node.id, npcId: node.npcId, dragonId, benchDragonId: bench, returnScreen: 'outerGrid' };
}
