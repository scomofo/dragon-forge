import { moves } from './gameData';

export const HYDRA_HEAD_COUNT = 3;
export const HYDRA_HP_FLOOR = 0.3;

export function isLogicBombDetonationDue(state) {
  return state.bossPatternId === 'logic_bomb'
    && (state.bossState?.fuseTurns ?? 6) <= 0
    && !state.bossState?.fuseDetonated;
}

// Garble belongs to the affected dragon, not the arena slot. The existing
// counter name is retained, but its unit is completed uses, not elapsed turns.
export function createCorruptionState(dragonId, moveKeys) {
  const candidates = moveKeys.filter(key => key !== 'basic_attack'
    && moves[key] && !moves[key].isSignature && !key.startsWith('dual_'));
  const key = candidates.length ? candidates[Math.floor(Math.random() * candidates.length)] : null;
  return { garbledDragonId: key ? dragonId : null, garbledMoveKey: key, garbledTurnsLeft: key ? 2 : 0 };
}

export function getCorruptedMoveKey(state) {
  const bs = state.bossState || {};
  return state.bossPatternId === 'data_corruption' && bs.garbledTurnsLeft > 0
    && bs.garbledDragonId === state.dragonId
    && state.dragon?.moveKeys?.includes(bs.garbledMoveKey)
    ? bs.garbledMoveKey : null;
}

function isPlayerHit(event) {
  return event?.attacker === 'player' && event.action === 'attack'
    && event.hit && !event.reflected && !event.blocked;
}

// Storm has only two weaknesses. Count successful strikes, so one matching
// dragon can break all three heads without an impossible third element.
export function advanceHydraHeads(headsBroken, event) {
  return Math.min(HYDRA_HEAD_COUNT, headsBroken + (isPlayerHit(event) && event.effectiveness > 1 ? 1 : 0));
}

// Ice is resisted by Memory Leak's ice typing. The reset rewards the element,
// independently of damage effectiveness; use the resolved element for combos.
export function resetsMemoryLeak(event) {
  return isPlayerHit(event) && event.element === 'ice';
}
