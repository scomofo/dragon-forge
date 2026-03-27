import { describe, it, expect } from 'vitest';
import { rollRarity, rollElement } from './hatcheryEngine';

describe('rollRarity', () => {
  it('returns a rarity tier object', () => {
    const result = rollRarity(0);
    expect(result).toHaveProperty('name');
    expect(result).toHaveProperty('elements');
    expect(result).toHaveProperty('multiplier');
  });

  it('forces Rare+ when pity counter reaches threshold', () => {
    let rareOrExoticCount = 0;
    for (let i = 0; i < 50; i++) {
      const result = rollRarity(9);
      if (result.name === 'Rare' || result.name === 'Exotic') rareOrExoticCount++;
    }
    expect(rareOrExoticCount).toBe(50);
  });

  it('returns valid rarity at normal pity', () => {
    const validNames = ['Common', 'Uncommon', 'Rare', 'Exotic'];
    for (let i = 0; i < 20; i++) {
      const result = rollRarity(0);
      expect(validNames).toContain(result.name);
    }
  });
});

describe('rollElement', () => {
  it('returns an element from the rarity tier', () => {
    const tier = { name: 'Uncommon', elements: ['storm', 'venom', 'stone'], multiplier: 2 };
    for (let i = 0; i < 20; i++) {
      const el = rollElement(tier);
      expect(['storm', 'venom', 'stone']).toContain(el);
    }
  });

  it('returns the only element for single-element tiers', () => {
    const tier = { name: 'Rare', elements: ['shadow'], multiplier: 3 };
    expect(rollElement(tier)).toBe('shadow');
  });
});
