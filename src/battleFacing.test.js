import { describe, expect, test } from 'vitest';
import { getBattleFlipX, getBattleLungeDirection } from './battleFacing';

// Battle layout: the enemy anchors LEFT, the player anchors RIGHT
// (see .arena-sprites in styles/battle.css; the player lunges left and the
// enemy lunges right). Shipped art: enemy sprites (NPC stills, NPC
// battle-set sheets, boss stills) face LEFT; player dragon art faces RIGHT.

describe('getBattleFlipX', () => {
  test('enemy (left side) flips its left-facing art to face right toward the player', () => {
    expect(getBattleFlipX('enemy', true)).toBe(true);
  });

  test('enemy art already facing right needs no flip', () => {
    expect(getBattleFlipX('enemy', false)).toBe(false);
  });

  test('player dragon (right side) flips its right-facing art to face left toward the enemy', () => {
    expect(getBattleFlipX('player', false)).toBe(true);
  });

  test('a left-facing player dragon needs no flip to face the enemy', () => {
    expect(getBattleFlipX('player', true)).toBe(false);
  });

  test('every combatant ends up facing its opponent, never away', () => {
    // authored facing × side: the rendered facing must always be toward the foe
    const renderedFacing = (side, authoredFacesLeft) =>
      authoredFacesLeft !== getBattleFlipX(side, authoredFacesLeft) ? 'left' : 'right';
    expect(renderedFacing('enemy', true)).toBe('right');
    expect(renderedFacing('enemy', false)).toBe('right');
    expect(renderedFacing('player', true)).toBe('left');
    expect(renderedFacing('player', false)).toBe('left');
  });
});

describe('getBattleLungeDirection', () => {
  test('the enemy lunges right, toward the player', () => {
    expect(getBattleLungeDirection('enemy')).toBe('right');
  });

  test('the player lunges left, toward the enemy', () => {
    expect(getBattleLungeDirection('player')).toBe('left');
  });
});
