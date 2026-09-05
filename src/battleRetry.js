import { dragons, npcs } from './gameData';

function ownsDragon(save, id) {
  return typeof id === 'string' && Object.hasOwn(dragons, id) && save?.dragons?.[id]?.owned === true;
}

// Retry the encounter that was actually played. In particular, do not roll a
// new daily opponent or replace scaled boss/phases with their base definitions.
// BattleScreen's fresh mount supplies full HP and reads current saved stats.
export function getBattleRetryConfig(config, save) {
  if (!config || !ownsDragon(save, config.dragonId)) return null;
  if (!config.boss && !config.dailyNpc && !Object.hasOwn(npcs, config.npcId)) return null;

  const retry = structuredClone(config);
  retry.benchDragonId = retry.benchDragonId !== retry.dragonId && ownsDragon(save, retry.benchDragonId)
    ? retry.benchDragonId
    : null;
  return retry;
}
