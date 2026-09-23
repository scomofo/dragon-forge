import { describe, it, expect } from 'vitest';
import { MILESTONES, TITLES, checkMilestones, countFullyAwakened, getTitleName } from './journalMilestones';
import { JOURNAL_DRAGON_IDS } from './gameData';

const ALL_IDS = JOURNAL_DRAGON_IDS;

function dragonState(over = {}) {
  return { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null, ...over };
}

function fixture(dragonOverrides = {}) {
  const dragons = {};
  for (const id of ALL_IDS) dragons[id] = dragonState(dragonOverrides[id] || {});
  return { dragons, milestones: [] };
}

function milestone(id) {
  return MILESTONES.find((m) => m.id === id);
}

describe('elemental attunement milestones', () => {
  for (const id of ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow']) {
    it(`attune_${id} is met exactly when the ${id} dragon is discovered`, () => {
      const m = milestone(`attune_${id}`);
      expect(m).toBeDefined();
      expect(m.check(fixture()).met).toBe(false);
      expect(m.check(fixture({ [id]: { discovered: true } })).met).toBe(true);
      expect(m.check(fixture({ [id]: { discovered: true } })).progress).toBe('1/1');
    });
  }

  it('skips void, light, and synthesis (covered by void_hunter/light_bearer/synthesis_born)', () => {
    for (const id of ['attune_void', 'attune_light', 'attune_synthesis']) {
      expect(milestone(id)).toBeUndefined();
    }
  });
});

describe('rarity-tier milestones', () => {
  it('tier_common needs fire AND ice discovered', () => {
    const m = milestone('tier_common');
    expect(m.titleReward).toBe('hearth_warden');
    expect(m.check(fixture()).met).toBe(false);
    const one = m.check(fixture({ fire: { discovered: true } }));
    expect(one.met).toBe(false);
    expect(one.progress).toBe('1/2');
    expect(m.check(fixture({ fire: { discovered: true }, ice: { discovered: true } })).met).toBe(true);
  });

  it('tier_uncommon needs storm, venom, and stone', () => {
    const m = milestone('tier_uncommon');
    expect(m.titleReward).toBe('wildcaller');
    const partial = m.check(fixture({ storm: { discovered: true }, venom: { discovered: true } }));
    expect(partial.met).toBe(false);
    expect(partial.progress).toBe('2/3');
    expect(m.check(fixture({
      storm: { discovered: true }, venom: { discovered: true }, stone: { discovered: true },
    })).met).toBe(true);
  });

  it('tier_rare needs shadow; tier_exotic needs void', () => {
    expect(milestone('tier_rare').titleReward).toBe('umbral_scholar');
    expect(milestone('tier_rare').check(fixture()).met).toBe(false);
    expect(milestone('tier_rare').check(fixture({ shadow: { discovered: true } })).met).toBe(true);
    expect(milestone('tier_exotic').titleReward).toBe('rift_walker');
    expect(milestone('tier_exotic').check(fixture({ void: { discovered: true } })).met).toBe(true);
  });
});

describe('shiny_perfection (full shiny set)', () => {
  function allShiny(except = []) {
    const over = {};
    for (const id of ALL_IDS) {
      over[id] = except.includes(id)
        ? { owned: true, shiny: false }
        : { owned: true, shiny: true };
    }
    return fixture(over);
  }

  it('needs all 9 owned shiny — 8/9 is not enough', () => {
    const m = milestone('shiny_perfection');
    expect(m.titleReward).toBe('prismatic_warden');
    const partial = m.check(allShiny(['synthesis']));
    expect(partial.met).toBe(false);
    expect(partial.progress).toBe('8/9');
    const full = m.check(allShiny());
    expect(full.met).toBe(true);
    expect(full.progress).toBe('9/9');
  });

  it('does not count shiny dragons that are not owned', () => {
    const over = {};
    for (const id of ALL_IDS) over[id] = { owned: true, shiny: true };
    over.light = { owned: false, shiny: true }; // lost to fusion, say
    expect(milestone('shiny_perfection').check(fixture(over)).met).toBe(false);
  });
});

describe('countFullyAwakened', () => {
  it('counts only owned dragons at Lv.50 AND shiny', () => {
    const over = {
      fire:   { owned: true, level: 50, shiny: true },   // counts
      ice:    { owned: true, level: 50, shiny: false },  // not shiny
      storm:  { owned: true, level: 49, shiny: true },   // not maxed
      stone:  { owned: false, level: 50, shiny: true },  // not owned
      venom:  { owned: true, level: 50, shiny: true },   // counts
    };
    expect(countFullyAwakened(fixture(over))).toBe(2);
  });

  it('awakened milestones use thresholds 1 / 3 / all 9', () => {
    const awakened = (ids) => {
      const over = {};
      for (const id of ids) over[id] = { owned: true, level: 50, shiny: true };
      return fixture(over);
    };
    const one = milestone('awakened_one');
    const three = milestone('awakened_three');
    const all = milestone('awakened_all');
    expect(one.titleReward).toBe('awakened');
    expect(three.titleReward).toBe('ascendant');
    expect(all.titleReward).toBe('transcendent');

    expect(one.check(awakened([])).met).toBe(false);
    expect(one.check(awakened(['fire'])).met).toBe(true);
    expect(three.check(awakened(['fire', 'ice'])).met).toBe(false);
    expect(three.check(awakened(['fire', 'ice', 'storm'])).met).toBe(true);
    expect(three.check(awakened(['fire', 'ice', 'storm'])).progress).toBe('3/3');
    expect(all.check(awakened(['fire', 'ice', 'storm'])).met).toBe(false);
    expect(all.check(awakened(ALL_IDS)).met).toBe(true);
    expect(all.check(awakened(ALL_IDS)).progress).toBe('9/9');
  });
});

describe('codex titles catalog', () => {
  it('resolves every titleReward on a milestone to a known title', () => {
    const rewardIds = MILESTONES.filter((m) => m.titleReward).map((m) => m.titleReward);
    expect(rewardIds.length).toBeGreaterThan(0);
    for (const id of rewardIds) {
      expect(TITLES[id], `title ${id}`).toBeDefined();
      expect(getTitleName(id)).toBe(TITLES[id].name);
    }
  });

  it('grants 8 distinct cosmetic titles', () => {
    expect(Object.keys(TITLES)).toHaveLength(8);
    expect(getTitleName('nope')).toBeNull();
  });

  it('checkMilestones carries titleReward through to the claim path', () => {
    const results = checkMilestones(fixture({ fire: { discovered: true }, ice: { discovered: true } }));
    const tier = results.find((r) => r.id === 'tier_common');
    expect(tier.titleReward).toBe('hearth_warden');
    expect(tier.newlyClaimed).toBe(true);
  });
});
