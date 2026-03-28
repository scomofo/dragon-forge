import { describe, it, expect } from 'vitest';
import { rollRarity, rollElement, rollShiny, executePull, applyPullResult } from './hatcheryEngine';

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

describe('applyPullResult', () => {
  it('unlocks a new dragon', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: false, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.fire.owned).toBe(true);
    expect(result.isNew).toBe(true);
    expect(result.xpGained).toBe(0);
  });

  it('merges duplicate with XP bonus', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Uncommon', rarityMultiplier: 2, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.isNew).toBe(false);
    expect(result.xpGained).toBe(100);
    expect(result.save.dragons.fire.xp).toBe(0);
    expect(result.save.dragons.fire.level).toBe(2);
  });

  it('upgrades to shiny on duplicate shiny pull', () => {
    const save = {
      dragons: { shadow: { level: 5, xp: 20, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'shadow', rarityName: 'Rare', rarityMultiplier: 3, shiny: true, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.shadow.shiny).toBe(true);
  });

  it('updates pity counter', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 0, owned: false, shiny: false } },
      dataScraps: 100,
      pityCounter: 3,
    };
    const pull = { element: 'fire', rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 4 };
    const result = applyPullResult(save, pull);
    expect(result.save.pityCounter).toBe(4);
  });

  it('levels up dragon when XP exceeds threshold', () => {
    const save = {
      dragons: { fire: { level: 1, xp: 80, owned: true, shiny: false } },
      dataScraps: 100,
      pityCounter: 0,
    };
    const pull = { element: 'fire', rarityName: 'Exotic', rarityMultiplier: 5, shiny: false, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.fire.level).toBe(4);
    expect(result.save.dragons.fire.xp).toBe(30);
    expect(result.xpGained).toBe(250);
  });
});
