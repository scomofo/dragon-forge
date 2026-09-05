import { describe, expect, it } from 'vitest';
import { fillSaveDefaults, validateSaveShape } from './saveValidation';

describe('save shape validation', () => {
  it('accepts incomplete legacy progress without mutating ownership backfills', () => {
    const legacy = {
      dragons: { fire: { level: 8, xp: 120 }, ice: { owned: true, level: 1 } },
      dataScraps: 17, defeatedNpcs: ['firewall_sentinel'],
      inventory: { cores: { ice: 2 } }, stats: { battlesWon: 4 }, records: { longestStreak: 7 },
      flags: { metFelix: true }, futureFeature: { progress: ['kept'] },
    };
    const before = structuredClone(legacy);
    expect(validateSaveShape(legacy)).toBe(legacy);
    expect(legacy).toEqual(before);
    expect(legacy.dragons.fire.owned).toBeUndefined();
    expect(legacy.introSeen).toBeUndefined();
    expect(validateSaveShape({ dragons: {} })).toEqual({ dragons: {} });
  });

  it('accepts known null sentinels and preserves progression beyond current balance caps', () => {
    const save = {
      dragons: { fire: { level: 99, xp: 30000, owned: true, nickname: null, fusedBaseStats: null } },
      dataScraps: 1000000, inventory: { cores: { fire: 200 } },
      records: { fastestWin: null }, activity: { firstPlayed: null, lastPlayed: null },
      flags: { lastZone: null }, skye: { companionDragonId: null },
    };
    expect(() => validateSaveShape(save)).not.toThrow();
  });

  it('leaves recoverable expedition leaf values to the existing checkpoint sanitizers', () => {
    const save = { dragons: {}, outerGrid: {
      roomId: {}, visited: ['signal-approach', null, {}], spanRoute: 'warp', cacheClaimed: 'yes',
    }, flags: { activeExpedition: {} } };
    expect(() => validateSaveShape(save)).not.toThrow();
  });

  it.each([null, [], 3, true, 'save', {}, { dragons: null }, { dragons: [] }, { dragons: { fire: null } }])(
    'rejects a missing or malformed save/dragon container: %j', value => {
      expect(() => validateSaveShape(value)).toThrow(/Invalid save field save/);
    });

  it.each([
    ['dataScraps', '40'], ['dataScraps', -1], ['dataScraps', Infinity], ['pityCounter', NaN],
    ['milestones', {}], ['defeatedNpcs', [12]], ['remnantDefeated', 'boss'],
    ['fusionLineage', [null]], ['fusionLineage', [{ offspringLevel: '4' }]],
    ['inventory', null], ['inventory', { cores: [] }], ['inventory', { cores: { ice: -2 } }],
    ['inventory', { stabilityBoost: 1 }], ['stats', { battlesWon: null }],
    ['records', null], ['records', { fastestWin: Infinity }],
    ['activity', []], ['activity', { lastPlayed: 'yesterday' }],
    ['flags', null], ['flags', { metFelix: 'yes' }], ['flags', { fragmentsUnlocked: [false] }],
    ['skye', null], ['skye', { relicsEquipped: {} }], ['skye', { companionDragonId: 3 }],
    ['singularityProgress', { defeated: null }], ['singularityProgress', { replayCounts: { boss: -1 } }],
    ['outerGrid', null], ['frozenCache', []], ['stormSpine', 'room'], ['adminCore', false],
  ])('rejects malformed supplied %s before migration', (key, value) => {
    expect(() => validateSaveShape({ dragons: {}, [key]: value })).toThrow(`save.${key}`);
  });

  it.each([
    { level: 0 }, { level: '2' }, { xp: NaN }, { owned: 1 }, { discovered: 'true' },
    { nickname: {} }, { fusedBaseStats: [] }, { fusedBaseStats: { hp: -1 } },
    { fusedBaseStats: {} }, { fusedBaseStats: { hp: 100, atk: 30, def: 20 } },
    { fusedBaseStats: { hp: 0, atk: 30, def: 20, spd: 20 } },
  ])('rejects malformed fighter values: %j', dragon => {
    expect(() => validateSaveShape({ dragons: { fire: dragon } })).toThrow('save.dragons.fire');
  });

  it('accepts a complete fusion stat record with positive HP and nonnegative other stats', () => {
    const save = { dragons: { fire: { fusedBaseStats: { hp: 120, atk: 0, def: 0, spd: 0 } } } };
    expect(() => validateSaveShape(save)).not.toThrow();
  });

  it.each(['__proto__', 'constructor', 'toString', 'valueOf', 'hasOwnProperty'])('rejects the reserved dragon ID %s', id => {
    const save = { dragons: Object.fromEntries([[id, { owned: true, level: 10 }]]) };
    expect(() => validateSaveShape(save)).toThrow(`save.dragons.${id}`);
  });

  it('preserves ordinary unrecognized dragon IDs for legacy and future saves', () => {
    const save = { dragons: { future_dragon: { owned: true, level: 10 } } };
    expect(validateSaveShape(save)).toBe(save);
  });
});

describe('filling legacy save defaults', () => {
  const defaults = {
    dragons: { fire: { level: 1, xp: 0, owned: false }, ice: { level: 1, xp: 0, owned: false } },
    inventory: { cores: {}, xpBoostBattles: 0, stabilityBoost: false },
    records: { fastestWin: null, highestDamage: 0, longestStreak: 0, currentStreak: 0 },
    introSeen: false, milestones: [], flags: { metFelix: false },
  };

  it('fills missing nested fields while preserving migrated ownership, currency, and unknown data', () => {
    const migrated = { dragons: { fire: { level: 8, owned: true, discovered: true } },
      inventory: { cores: { ice: 2 } }, records: { longestStreak: 7 },
      introSeen: true, dataScraps: 17, milestones: ['first_hatch'], flags: { futureFlag: 'keep' },
    };
    const result = fillSaveDefaults(migrated, defaults);
    expect(result).toMatchObject({
      dragons: { fire: { level: 8, xp: 0, owned: true, discovered: true }, ice: { level: 1, xp: 0, owned: false } },
      inventory: { cores: { ice: 2 }, xpBoostBattles: 0, stabilityBoost: false },
      records: { longestStreak: 7, currentStreak: 0, fastestWin: null, highestDamage: 0 },
      introSeen: true, dataScraps: 17, milestones: ['first_hatch'], flags: { metFelix: false, futureFlag: 'keep' },
    });
  });

  it('does not share mutable values with either the saved progress or default template', () => {
    const source = { dragons: {}, milestones: ['first_hatch'], future: { visits: [1] } };
    const result = fillSaveDefaults(source, defaults);
    result.dragons.fire.level = 9;
    result.milestones.push('boss');
    result.future.visits.push(2);
    expect(defaults.dragons.fire.level).toBe(1);
    expect(source.milestones).toEqual(['first_hatch']);
    expect(source.future.visits).toEqual([1]);
  });

  it('preserves unknown JSON keys as data without changing object prototypes', () => {
    const source = JSON.parse('{"dragons":{},"__proto__":{"owned":true},"constructor":{"progress":3}}');
    const result = fillSaveDefaults(source, defaults);
    expect(Object.hasOwn(result, '__proto__')).toBe(true);
    expect(result.__proto__).toEqual({ owned: true });
    expect(result.constructor).toEqual({ progress: 3 });
    expect(Object.getPrototypeOf(result)).toBe(Object.prototype);
    expect({}.owned).toBeUndefined();
  });
});
