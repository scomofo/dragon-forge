import { describe, it, expect } from 'vitest';
import { getTypeEffectiveness, calculateDamage } from './battleEngine';

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
