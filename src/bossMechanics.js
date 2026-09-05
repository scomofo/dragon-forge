export const HYDRA_HEAD_COUNT = 3;
export const HYDRA_HP_FLOOR = 0.3;

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
