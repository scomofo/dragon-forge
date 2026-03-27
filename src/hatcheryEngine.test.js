import { describe, it, expect } from 'vitest';
import { rollRarity, rollElement, rollShiny, executePull } from './hatcheryEngine';

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

describe('rollShiny', () => {
  it('returns boolean', () => {
    expect(typeof rollShiny(false)).toBe('boolean');
  });

  it('always returns true for exotic (guaranteedShiny)', () => {
    for (let i = 0; i < 20; i++) {
      expect(rollShiny(true)).toBe(true);
    }
  });
});

describe('executePull', () => {
  it('returns a pull result with element, rarity, and shiny', () => {
    const result = executePull(0);
    expect(result).toHaveProperty('element');
    expect(result).toHaveProperty('rarityName');
    expect(result).toHaveProperty('rarityMultiplier');
    expect(result).toHaveProperty('shiny');
    expect(result).toHaveProperty('newPityCounter');
  });

  it('resets pity counter on Rare+ pull', () => {
    const result = executePull(9);
    expect(result.newPityCounter).toBe(0);
  });

  it('increments pity counter on Common/Uncommon pull', () => {
    let foundNonRare = false;
    for (let i = 0; i < 100; i++) {
      const result = executePull(0);
      if (result.rarityName === 'Common' || result.rarityName === 'Uncommon') {
        expect(result.newPityCounter).toBe(1);
        foundNonRare = true;
        break;
      }
    }
    expect(foundNonRare).toBe(true);
  });
});
