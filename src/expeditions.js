import { getCampaignNodeById, isCampaignNodeCleared } from './campaignMap';
import { WORLD_ZONES, OUTER_GRID_ROOMS, FROZEN_CACHE_ROOMS, STORM_SPINE_ROOMS, ADMIN_CORE_ROOMS } from './worldZones';
import { getOuterGridProgress, getOuterGridObjective, isOuterGridRoomOpen } from './outerGrid';
import { getFrozenCacheProgress, getFrozenCacheObjective, isFrozenCacheRoomOpen } from './frozenCache';
import { getStormSpineProgress, getStormSpineObjective, isStormSpineRoomOpen } from './stormSpine';
import { getAdminCoreProgress, getAdminCoreObjective, isAdminCoreRoomOpen } from './adminCore';

// Screen IDs connect navigation, save/resume, and guidance. Encounter order
// comes from the authored rooms; battle prerequisites stay in the campaign DAG.
export const EXPEDITIONS = [
  {
    screen: 'outerGrid', zoneId: 'outer_grid', entryRoom: 'signal-approach', rewardRoom: 'return-gate',
    rooms: OUTER_GRID_ROOMS, getProgress: getOuterGridProgress, getObjective: getOuterGridObjective, isRoomOpen: isOuterGridRoomOpen,
  },
  {
    screen: 'frozenCache', zoneId: 'frozen_cache', entryRoom: 'cold-archive', rewardRoom: 'thaw-gate',
    rooms: FROZEN_CACHE_ROOMS, getProgress: getFrozenCacheProgress, getObjective: getFrozenCacheObjective, isRoomOpen: isFrozenCacheRoomOpen,
  },
  {
    screen: 'stormSpine', zoneId: 'storm_spine', entryRoom: 'overclock-gantry', rewardRoom: 'discharge-gate',
    rooms: STORM_SPINE_ROOMS, getProgress: getStormSpineProgress, getObjective: getStormSpineObjective, isRoomOpen: isStormSpineRoomOpen,
  },
  {
    screen: 'adminCore', zoneId: 'admin_core', entryRoom: 'mirror-vestibule', rewardRoom: 'reset-threshold',
    rooms: ADMIN_CORE_ROOMS, getProgress: getAdminCoreProgress, getObjective: getAdminCoreObjective, isRoomOpen: isAdminCoreRoomOpen,
  },
];

export function getExpedition(screen) {
  return EXPEDITIONS.find(expedition => expedition.screen === screen) || null;
}

export function getExpeditionForZone(zoneId) {
  return EXPEDITIONS.find(expedition => expedition.zoneId === zoneId) || null;
}

export function isExpeditionAvailable(screen, save) {
  const expedition = getExpedition(screen);
  return Boolean(expedition?.isRoomOpen(expedition.entryRoom, save));
}

export function getExpeditionGuidance(save) {
  const unfinished = EXPEDITIONS.filter(expedition => {
    if (!isExpeditionAvailable(expedition.screen, save)) return false;
    const progress = expedition.getProgress(save);
    const hasEncounter = Object.values(expedition.rooms).some(room => room.nodeId && !isCampaignNodeCleared(getCampaignNodeById(room.nodeId), save));
    return !progress.rewardClaimed || hasEncounter;
  });
  const expedition = unfinished.find(item => item.screen === save?.flags?.activeExpedition)
    // Older saves have no last-entered marker. Prefer the furthest entered
    // unfinished sector; default shelter records alone do not count as entry.
    || [...unfinished].reverse().find(item => item.getProgress(save).visited.length > 1);
  if (!expedition) return null;

  const nextNode = Object.values(expedition.rooms).filter(room => room.nodeId)
    .map(room => getCampaignNodeById(room.nodeId)).find(node => !isCampaignNodeCleared(node, save));
  const prerequisite = nextNode?.prerequisiteIds.map(getCampaignNodeById)
    .find(node => node.zoneId !== expedition.zoneId && !isCampaignNodeCleared(node, save));
  if (prerequisite) {
    const destination = getExpeditionForZone(prerequisite.zoneId);
    if (destination && isExpeditionAvailable(destination.screen, save)) {
      return {
        target: destination.screen, action: 'OPEN ROUTE',
        title: `Clear ${prerequisite.label} in ${WORLD_ZONES[destination.zoneId].name} to open ${nextNode.label}.`,
      };
    }
  }
  return {
    target: expedition.screen, action: 'CONTINUE ROUTE',
    title: nextNode ? expedition.getObjective(save) : `Collect your reward at the ${expedition.rooms[expedition.rewardRoom].name}.`,
  };
}
