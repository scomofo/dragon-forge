// === BATTLE FACING ===
// One place that decides which way combatants face in battle, so every
// sprite path (animated battle-set sheets, legacy NPC <img> stills, boss
// stills, dragon portraits) agrees instead of each relying on its own
// per-sprite data flag.
//
// Layout (see .arena-sprites in styles/battle.css, and the lunge wiring in
// BattleScreen): the ENEMY anchors LEFT and the PLAYER anchors RIGHT. The
// lunge directions confirm it — the player lunges left and the enemy lunges
// right, i.e. each strikes toward the other side.
//
// Authored art direction (verified against the shipped assets):
// - Enemy art (NPC stills, NPC battle-set sheets, boss stills) faces LEFT.
// - Player dragon art faces RIGHT, unless a dragon sets facesLeft.
//
// Both sides therefore flip: the enemy mirrors its left-facing art to face
// right toward the player, and the player dragon mirrors its right-facing
// art to face left toward the enemy.

/**
 * Returns true when the sprite must be mirrored horizontally so the
 * combatant faces its opponent.
 * @param {'enemy' | 'player'} side battle side of the combatant
 * @param {boolean} authoredFacesLeft which way the sprite art points unmirrored
 */
export function getBattleFlipX(side, authoredFacesLeft) {
  const opponentOnRight = side === 'enemy';
  return authoredFacesLeft === opponentOnRight;
}

/**
 * Strike direction for lunge animations — always toward the opponent's side.
 * @param {'enemy' | 'player'} side battle side of the attacker
 */
export function getBattleLungeDirection(side) {
  return side === 'enemy' ? 'right' : 'left';
}
