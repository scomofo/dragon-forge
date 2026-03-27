import { describe, it, expect } from 'vitest';
import { getTypeEffectiveness, calculateDamage, calculateXpGain, calculateStatsForLevel, getStageForLevel } from './battleEngine';

describe('getTypeEffectiveness', () => {
  it('returns 2.0 for fire attacking ice', () => {
    expect(getTypeEffectiveness('fire', 'ice')).toBe(2.0);
  });

  it('returns 0.5 for fire attacking stone', () => {
    expect(getTypeEffectiveness('fire', 'stone')).toBe(0.5);
  });

  it('returns 1.0 for neutral element', () => {
    expect(getTypeEffectiveness('neutral', 'fire')).toBe(1.0);
  });

  it('returns 1.0 for unknown elements', () => {
    expect(getTypeEffectiveness('fire', 'neutral')).toBe(1.0);
  });
});

describe('calculateDamage', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('calculates super-effective damage correctly', () => {
    // baseDamage = (28 * 1.0 * 2) - (20 * 0.5) = 56 - 10 = 46
    // typedDamage = 46 * 2.0 = 92
    // finalDamage = floor(92 * rand(0.85..1.0)) => 78..92
    const result = calculateDamage(attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(78);
    expect(result.damage).toBeLessThanOrEqual(92);
    expect(result.effectiveness).toBe(2.0);
    expect(result.hit).toBe(true);
  });

  it('halves damage when defender is defending', () => {
    const defendingTarget = { ...defender, defending: true };
    const result = calculateDamage(attacker, defendingTarget, move);
    expect(result.damage).toBeGreaterThanOrEqual(39);
    expect(result.damage).toBeLessThanOrEqual(46);
  });

  it('applies stage multiplier', () => {
    const stage1Attacker = { ...attacker, stage: 1 };
    // baseDamage = (28 * 0.5 * 2) - (20 * 0.5) = 28 - 10 = 18
    // typedDamage = 18 * 2.0 = 36
    const result = calculateDamage(stage1Attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(30);
    expect(result.damage).toBeLessThanOrEqual(36);
  });

  it('returns minimum 1 damage', () => {
    const weakAttacker = { atk: 1, element: 'fire', stage: 1 };
    const tankDefender = { def: 100, element: 'fire', defending: true };
    const result = calculateDamage(weakAttacker, tankDefender, move);
    expect(result.damage).toBe(1);
  });

  it('can miss based on accuracy', () => {
    const lowAccMove = { element: 'fire', power: 65, accuracy: 0 };
    const result = calculateDamage(attacker, defender, lowAccMove);
    expect(result.hit).toBe(false);
    expect(result.damage).toBe(0);
  });
});

describe('getStageForLevel', () => {
  it('returns stage 1 for levels below 10', () => {
    expect(getStageForLevel(1)).toBe(1);
    expect(getStageForLevel(9)).toBe(1);
  });

  it('returns stage 2 for levels 10-24', () => {
    expect(getStageForLevel(10)).toBe(2);
    expect(getStageForLevel(24)).toBe(2);
  });

  it('returns stage 3 for levels 25-49', () => {
    expect(getStageForLevel(25)).toBe(3);
    expect(getStageForLevel(49)).toBe(3);
  });

  it('returns stage 4 for level 50+', () => {
    expect(getStageForLevel(50)).toBe(4);
    expect(getStageForLevel(99)).toBe(4);
  });
});

describe('calculateXpGain', () => {
  it('gives base XP when levels are equal', () => {
    expect(calculateXpGain(50, 10, 10)).toBe(50);
  });

  it('gives more XP for fighting higher level enemies', () => {
    const xp = calculateXpGain(50, 5, 10);
    expect(xp).toBe(100);
  });

  it('gives less XP for fighting lower level enemies', () => {
    const xp = calculateXpGain(50, 10, 5);
    expect(xp).toBe(25);
  });

  it('gives minimum 1 XP', () => {
    const xp = calculateXpGain(50, 99, 1);
    expect(xp).toBeGreaterThanOrEqual(1);
  });
});

describe('calculateStatsForLevel', () => {
  it('returns base stats at level 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 1);
    expect(result).toEqual({ hp: 110, atk: 28, def: 20, spd: 18 });
  });

  it('adds 3 per stat per level above 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 5);
    // 4 levels above 1 => +12 to each stat
    expect(result).toEqual({ hp: 122, atk: 40, def: 32, spd: 30 });
  });
});
