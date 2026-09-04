// @ts-nocheck
import { describe, it, expect } from 'vitest';
import { getFusionElement, calculateFusionStats, getStabilityTier, getFusionOffspringLevel, executeFusion } from './fusionEngine';

describe('getFusionElement', () => {
  it('returns same element for same-element fusion', () => {
    expect(getFusionElement('fire', 'fire')).toBe('fire');
    expect(getFusionElement('shadow', 'shadow')).toBe('shadow');
  });

  it('returns storm for fire+ice', () => {
    expect(getFusionElement('fire', 'ice')).toBe('storm');
    expect(getFusionElement('ice', 'fire')).toBe('storm');
  });

  it('returns shadow for fire+venom', () => {
    expect(getFusionElement('fire', 'venom')).toBe('shadow');
    expect(getFusionElement('venom', 'fire')).toBe('shadow');
  });

  it('is commutative', () => {
    expect(getFusionElement('ice', 'storm')).toBe(getFusionElement('storm', 'ice'));
    expect(getFusionElement('stone', 'shadow')).toBe(getFusionElement('shadow', 'stone'));
  });

  it('forges Synthesis from Void and Light', () => {
    expect(getFusionElement('void', 'light')).toBe('synthesis');
    expect(getFusionElement('light', 'void')).toBe('synthesis');
  });
});

describe('getStabilityTier', () => {
  it('returns stable for same element', () => {
    expect(getStabilityTier('fire', 'fire')).toBe('stable');
  });

  it('returns unstable for opposing elements', () => {
    expect(getStabilityTier('fire', 'ice')).toBe('unstable');
    expect(getStabilityTier('storm', 'stone')).toBe('unstable');
    expect(getStabilityTier('venom', 'shadow')).toBe('unstable');
  });

  it('returns normal for neutral combos', () => {
    expect(getStabilityTier('fire', 'storm')).toBe('normal');
    expect(getStabilityTier('ice', 'venom')).toBe('normal');
  });

  it('stability boost promotes one tier', () => {
    expect(getStabilityTier('fire', 'storm', true)).toBe('stable');
    expect(getStabilityTier('fire', 'ice', true)).toBe('normal');
    expect(getStabilityTier('fire', 'fire', true)).toBe('stable');
  });
});

describe('calculateFusionStats', () => {
  const parentA = { hp: 100, atk: 30, def: 20, spd: 20 };
  const parentB = { hp: 80, atk: 20, def: 30, spd: 10 };

  it('averages stats with 10% fusion bonus', () => {
    const result = calculateFusionStats(parentA, parentB, 'normal');
    expect(result).toEqual({ hp: 99, atk: 27, def: 27, spd: 16 });
  });

  it('applies 25% bonus for stable fusion', () => {
    const result = calculateFusionStats(parentA, parentB, 'stable');
    expect(result).toEqual({ hp: 123, atk: 33, def: 33, spd: 20 });
  });

  it('applies unstable modifiers — HP*0.8, ATK*1.1', () => {
    const result = calculateFusionStats(parentA, parentB, 'unstable');
    expect(result).toEqual({ hp: 79, atk: 29, def: 27, spd: 16 });
  });
});

describe('executeFusion', () => {
  it('produces offspring with correct element and stats', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 110, atk: 28, def: 20, spd: 18 }, level: 12, shiny: false };
    const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 24, def: 26, spd: 20 }, level: 10, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.element).toBe('storm');
    expect(result.stabilityTier).toBe('unstable');
    expect(result.fusedBaseStats).toHaveProperty('hp');
    // offspring level = max(10, min(50, round((12 + 10) / 2 * 0.85))) = max(10, round(9.35)) = 10
    expect(result.level).toBe(10);
    expect(result.shiny).toBe(false);
  });

  it('inherits shiny from either parent', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: true };
    const parentB = { id: 'storm', element: 'storm', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.shiny).toBe(true);
  });

  it('offspring keeps 85% of the parents average level', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 30, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    // max(10, min(50, round(27.5 * 0.85))) = round(23.375) = 23
    expect(result.level).toBe(23);
  });

  it('scales offspring level smoothly with parent levels (no L50 cliff)', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 24, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    // max(10, min(50, round(24.5 * 0.85))) = round(20.825) = 21
    expect(result.level).toBe(21);
  });

  it('never regresses high-investment parents to a low-level child', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 50, shiny: false };
    const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 50, shiny: false };
    const result = executeFusion(parentA, parentB);
    // round(50 * 0.85) = 43 — not the old cap-30 cliff
    expect(result.level).toBe(43);
  });
});

describe('getFusionOffspringLevel', () => {
  it('floors at 10 so the child is always re-fusable', () => {
    expect(getFusionOffspringLevel(10, 10)).toBe(10);
    expect(getFusionOffspringLevel(1, 1)).toBe(10);
  });

  it('keeps 85% of the average, rounded', () => {
    expect(getFusionOffspringLevel(30, 25)).toBe(23);
    expect(getFusionOffspringLevel(50, 50)).toBe(43);
  });

  it('caps at the level cap', () => {
    expect(getFusionOffspringLevel(50, 50)).toBeLessThanOrEqual(50);
  });

  it('applies the stability boost to the fusion result', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    const parentB = { id: 'storm', element: 'storm', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    expect(executeFusion(parentA, parentB).stabilityTier).toBe('normal');
    expect(executeFusion(parentA, parentB, { stabilityBoost: true }).stabilityTier).toBe('stable');
  });

  it('forges Synthesis from Void and Light parents', () => {
    const parentA = { id: 'void', element: 'void', stats: { hp: 88, atk: 34, def: 16, spd: 30 }, level: 20, shiny: false };
    const parentB = { id: 'light', element: 'light', stats: { hp: 100, atk: 26, def: 22, spd: 22 }, level: 20, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.element).toBe('synthesis');
    expect(result.parentAId).toBe('void');
    expect(result.parentBId).toBe('light');
  });
});
