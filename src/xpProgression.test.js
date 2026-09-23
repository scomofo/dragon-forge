import { describe, it, expect } from 'vitest';
import { applyDragonXp, applyDragonXpWithOverflow, xpForLevel } from './persistence';

// Regression guard for the "three conflicting XP curves" bug: a dragon must level
// identically no matter where the XP came from (battle win, duplicate pull, shop).
// applyDragonXp is the single authority; this asserts its key invariants.
describe('XP progression — single source of truth', () => {
  it('xpForLevel is monotonically non-decreasing across the level range', () => {
    for (let l = 1; l < 50; l++) {
      expect(xpForLevel(l + 1)).toBeGreaterThanOrEqual(xpForLevel(l));
    }
  });

  it('same total XP yields the same level/xp regardless of how it is split (source-independent)', () => {
    const lump = applyDragonXp({ level: 1, xp: 0 }, 300);
    const split = { level: 1, xp: 0 };
    applyDragonXp(split, 100); // e.g. a battle win
    applyDragonXp(split, 150); // e.g. a duplicate pull
    applyDragonXp(split, 50);  // e.g. a shop Data Fragment
    expect(split).toEqual(lump);
  });

  it('respects a non-zero starting level/xp the same way in one lump or many chunks', () => {
    const lump = applyDragonXp({ level: 7, xp: 12 }, 500);
    const split = { level: 7, xp: 12 };
    for (let i = 0; i < 10; i++) applyDragonXp(split, 50);
    expect(split).toEqual(lump);
  });

  it('caps at level 50 with 0 leftover XP and never overflows', () => {
    const d = applyDragonXp({ level: 1, xp: 0 }, 999999);
    expect(d.level).toBe(50);
    expect(d.xp).toBe(0);
  });

  it('a single duplicate-pull XP grant matches the canonical curve exactly', () => {
    // L1 + 100 XP -> L2 with 50 leftover (L1 needs 50, L2 needs 55).
    expect(applyDragonXp({ level: 1, xp: 0 }, 100)).toEqual({ level: 2, xp: 50 });
  });
});

describe('applyDragonXpWithOverflow — duplicate overflow accounting', () => {
  it('reports all XP as overflow on a level-50 dragon', () => {
    const { dragon, overflowXp, levelsGained } = applyDragonXpWithOverflow({ level: 50, xp: 0 }, 250);
    expect(overflowXp).toBe(250);
    expect(levelsGained).toBe(0);
    expect(dragon).toEqual({ level: 50, xp: 0 });
  });

  it('reports only the past-cap remainder for a partial overflow', () => {
    // L49 needs 290 XP (50 + 48*5); 280 banked + 50 -> L50, 40 leftover overflows.
    const { dragon, overflowXp, levelsGained } = applyDragonXpWithOverflow({ level: 49, xp: 280 }, 50);
    expect(levelsGained).toBe(1);
    expect(overflowXp).toBe(40);
    expect(dragon).toEqual({ level: 50, xp: 0 });
  });

  it('reports zero overflow when the XP fits under the cap', () => {
    const { dragon, overflowXp, levelsGained } = applyDragonXpWithOverflow({ level: 1, xp: 0 }, 100);
    expect(overflowXp).toBe(0);
    expect(levelsGained).toBe(1);
    expect(dragon).toEqual({ level: 2, xp: 50 });
  });

  it('applyDragonXp delegates unchanged: same dragon state, callers unaffected', () => {
    const viaLegacy = applyDragonXp({ level: 49, xp: 280 }, 50);
    const { dragon } = applyDragonXpWithOverflow({ level: 49, xp: 280 }, 50);
    expect(viaLegacy).toEqual(dragon);
    expect(viaLegacy).toEqual({ level: 50, xp: 0 });
  });
});
