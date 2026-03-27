import { describe, it, expect } from 'vitest';
import { getFusionElement, calculateFusionStats, getStabilityTier } from './fusionEngine';

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
