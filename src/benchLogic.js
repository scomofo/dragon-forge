// Pure state transitions for the 2-dragon bench (reserve dragon). Extracted from
// the battle reducer so they can be unit tested without the React battle screen.
// A "fighter" is the slice of battle state that identifies the active dragon.
export const FIGHTER_FIELDS = [
  'dragon', 'dragonId', 'playerLevel', 'playerXp', 'playerStage',
  'playerStats', 'playerHp', 'playerMaxHp', 'playerStatus',
  'playerAtkBuff', 'playerDefBuff',
];

function snapshotActive(state) {
  const snap = {};
  loadFighter(snap, state);
  return snap;
}

function loadFighter(target, fighter) {
  for (const f of FIGHTER_FIELDS) target[f] = fighter[f];
  // Older reserve snapshots predate buffs. An absent buff must never inherit
  // the outgoing dragon's modifier or introduce undefined battle state.
  target.playerAtkBuff = fighter.playerAtkBuff ?? null;
  target.playerDefBuff = fighter.playerDefBuff ?? null;
}

// Manual swap: the active dragon and the reserve trade places, each keeping its
// own HP/status/buffs. No-op (returns state unchanged) if there is no living reserve.
export function swapActiveAndBench(state) {
  if (!state.bench || state.bench.playerHp <= 0) return state;
  const outgoing = snapshotActive(state);
  const next = { ...state, playerDefending: false, playerSpriteClass: '', playerForcedFrame: null };
  loadFighter(next, state.bench);
  next.bench = outgoing;
  return next;
}

// Faint swap (second life): the active dragon has fallen, so the reserve steps in
// at its remaining HP and the fallen dragon is gone (bench cleared). Advances the
// turn counter and hands control back to the player. A phase shift that already
// counted the turn passes advanceTurn=false. No-op without a living reserve.
export function faintSwap(state, playerTurnPhase, advanceTurn = true) {
  if (!state.bench || state.bench.playerHp <= 0) return state;
  const next = {
    ...state,
    bench: null,
    playerDefending: false,
    playerSpriteClass: '',
    playerForcedFrame: null,
    npcAttacking: false,
    phase: playerTurnPhase,
    turnCount: (state.turnCount || 0) + (advanceTurn ? 1 : 0),
  };
  loadFighter(next, state.bench);
  return next;
}
