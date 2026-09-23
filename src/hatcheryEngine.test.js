import { describe, it, expect } from 'vitest';
import { rollRarity, rollElement, rollShiny, executePull, executeVoidEggPull, applyPullResult, getRarityCeremony, getPityRitual, getPityProgress, orderGridResults, rankPullExcitement } from './hatcheryEngine';
import { XP_OVERFLOW_SCRAP_RATE } from './gameData';

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
    // Canonical curve: L1 needs 50, L2 needs 55 -> 100 XP lands at L2 with 50 left.
    expect(result.save.dragons.fire.xp).toBe(50);
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
    // Canonical rising curve (L1..L5 need 50/55/60/65/70): 80+250=330 XP lands at L6 with 30 left.
    expect(result.save.dragons.fire.level).toBe(6);
    expect(result.save.dragons.fire.xp).toBe(30);
    expect(result.xpGained).toBe(250);
  });
});

describe('getRarityCeremony', () => {
  it('escalates with rarity: Exotic holds longest and shakes hardest', () => {
    const common = getRarityCeremony('Common');
    const rare = getRarityCeremony('Rare');
    const exotic = getRarityCeremony('Exotic');
    expect(common.holdMs).toBe(0);
    expect(rare.holdMs).toBeGreaterThan(0);
    expect(exotic.holdMs).toBeGreaterThan(rare.holdMs);
    expect(exotic.extraShakes).toBeGreaterThan(rare.extraShakes);
    expect(rare.extraShakes).toBeGreaterThan(common.extraShakes);
  });

  it('only Rare+ escalates the ceremony; Uncommon just tints the glow', () => {
    expect(getRarityCeremony('Common').glow).toBeNull();
    // Uncommon tints the warm-up glow but gets no shakes/hold/stinger.
    expect(getRarityCeremony('Uncommon').glow).toBeTruthy();
    expect(getRarityCeremony('Uncommon').extraShakes).toBe(0);
    expect(getRarityCeremony('Uncommon').holdMs).toBe(0);
    expect(getRarityCeremony('Uncommon').stinger).toBeNull();
    expect(getRarityCeremony('Rare').glow).toBeTruthy();
    expect(getRarityCeremony('Exotic').glow).toBeTruthy();
    expect(getRarityCeremony('Common').stinger).toBeNull();
    expect(getRarityCeremony('Exotic').stinger).toBeTruthy();
  });

  it('falls back to Common for unknown tiers', () => {
    expect(getRarityCeremony('Mythic')).toEqual(getRarityCeremony('Common'));
  });
});

describe('orderGridResults', () => {
  const entry = (rarityMultiplier, { shiny = false, isNew = false } = {}) => ({
    pull: { rarityMultiplier, shiny },
    apply: { isNew },
  });

  it('orders least-to-most exciting so the best pull lands last', () => {
    const common = entry(1);
    const exoticShiny = entry(5, { shiny: true, isNew: true });
    const rare = entry(3);
    const ordered = orderGridResults([exoticShiny, common, rare]);
    expect(ordered[0]).toBe(common);
    expect(ordered[1]).toBe(rare);
    expect(ordered[2]).toBe(exoticShiny);
  });

  it('ranks shiny and NEW above plain duplicates of the same tier', () => {
    const plain = entry(2);
    const shiny = entry(2, { shiny: true });
    const fresh = entry(2, { isNew: true });
    expect(rankPullExcitement(shiny)).toBeGreaterThan(rankPullExcitement(fresh));
    expect(rankPullExcitement(fresh)).toBeGreaterThan(rankPullExcitement(plain));
  });

  it('does not mutate the input array', () => {
    const input = [entry(5), entry(1)];
    orderGridResults(input);
    expect(input[0].pull.rarityMultiplier).toBe(5);
  });
});

describe('executeVoidEggPull', () => {
  it('is fully deterministic: shiny Exotic void, pity reset', () => {
    const pull = executeVoidEggPull();
    expect(pull).toEqual({
      element: 'void',
      rarityName: 'Exotic',
      rarityMultiplier: 5,
      shiny: true,
      newPityCounter: 0,
    });
  });

  it('grants the void dragon through the standard apply path', () => {
    const save = {
      dragons: { void: { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null } },
      pityCounter: 4,
    };
    const result = applyPullResult(save, executeVoidEggPull());
    expect(result.isNew).toBe(true);
    expect(result.save.dragons.void.owned).toBe(true);
    expect(result.save.dragons.void.shiny).toBe(true);
    expect(result.save.pityCounter).toBe(0);
  });
});

describe('getPityProgress', () => {
  it('tracks the fraction toward the guaranteed Rare+ (pityCounter / 10)', () => {
    expect(getPityProgress(0)).toBe(0);
    expect(getPityProgress(5)).toBe(0.5);
    expect(getPityProgress(9)).toBeCloseTo(0.9);
    expect(getPityProgress(10)).toBe(1);
  });

  it('clamps outside the [0, 10] range', () => {
    expect(getPityProgress(-3)).toBe(0);
    expect(getPityProgress(42)).toBe(1);
  });
});

describe('getPityRitual', () => {
  it('is a no-op for non-pity pulls', () => {
    expect(getPityRitual(false)).toEqual({ glow: null, extraHoldMs: 0, css: '' });
  });

  it('gives the pity pull a pink aura and a held beat', () => {
    const ritual = getPityRitual(true);
    expect(ritual.css).toBe('egg-pity-glow');
    expect(ritual.extraHoldMs).toBe(600);
    // Distinct from the Exotic gold so the guaranteed pull reads as pity, not Exotic.
    expect(ritual.glow).not.toBe(getRarityCeremony('Exotic').glow);
  });
});

describe('getRarityCeremony — Exotic reveal hold (plan #5d)', () => {
  it('holds the Exotic reveal a fraction longer (900ms)', () => {
    expect(getRarityCeremony('Exotic').holdMs).toBe(900);
  });
});

describe('applyPullResult — duplicate XP overflow to DataScraps', () => {
  const saveWith = (dragon, dataScraps = 100) => ({
    dragons: { fire: dragon },
    dataScraps,
    pityCounter: 0,
  });

  it('converts level-50 duplicate XP to scraps at the overflow rate', () => {
    // Exotic duplicate: 50 * 5 = 250 XP, all of it overflows on a maxed dragon.
    const save = saveWith({ level: 50, xp: 0, owned: true, shiny: false });
    const pull = { element: 'fire', rarityName: 'Exotic', rarityMultiplier: 5, shiny: false, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    expect(result.xpGained).toBe(250);
    expect(result.scrapsGained).toBe(250 / XP_OVERFLOW_SCRAP_RATE); // 25
    expect(result.save.dataScraps).toBe(100 + 25);
    expect(result.save.dragons.fire.level).toBe(50);
    expect(result.save.dragons.fire.xp).toBe(0);
  });

  it('converts only the past-cap remainder (partial overflow)', () => {
    // L49 needs 290 XP; 280 banked + 50 from a Common duplicate -> L50, 40 overflows.
    const save = saveWith({ level: 49, xp: 280, owned: true, shiny: false });
    const pull = { element: 'fire', rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.save.dragons.fire.level).toBe(50);
    expect(result.scrapsGained).toBe(4); // 40 overflow XP / 10
    expect(result.save.dataScraps).toBe(104);
  });

  it('grants no scraps when the duplicate XP fits under the cap', () => {
    const save = saveWith({ level: 1, xp: 0, owned: true, shiny: false });
    const pull = { element: 'fire', rarityName: 'Uncommon', rarityMultiplier: 2, shiny: false, newPityCounter: 1 };
    const result = applyPullResult(save, pull);
    expect(result.xpGained).toBe(100);
    expect(result.scrapsGained).toBe(0);
    expect(result.save.dataScraps).toBe(100);
  });

  it('grants no scraps for new dragons', () => {
    const save = saveWith({ level: 1, xp: 0, owned: false, shiny: false });
    const pull = { element: 'fire', rarityName: 'Exotic', rarityMultiplier: 5, shiny: false, newPityCounter: 0 };
    const result = applyPullResult(save, pull);
    expect(result.isNew).toBe(true);
    expect(result.scrapsGained).toBe(0);
    expect(result.save.dataScraps).toBe(100);
  });
});
