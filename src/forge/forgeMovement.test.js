import { describe, expect, it } from 'vitest';
import { clampSkyePos, getMovementDirection, moveSkye } from './forgeMovement';

describe('forgeMovement', () => {
  it('clamps Skye inside the walkable Forge bounds', () => {
    expect(clampSkyePos({ x: -10, y: 200 })).toEqual({ x: 4, y: 92 });
  });

  it('moves Skye by one Forge step in a named direction', () => {
    expect(moveSkye({ x: 30, y: 75 }, 'up')).toEqual({ x: 30, y: 73 });
  });

  it('maps keyboard keys to Forge movement and action directions', () => {
    expect(getMovementDirection('ArrowLeft')).toBe('left');
    expect(getMovementDirection('d')).toBe('right');
    expect(getMovementDirection('Enter')).toBeNull();
  });
});
