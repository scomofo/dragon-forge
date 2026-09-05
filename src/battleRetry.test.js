import { describe, expect, it } from 'vitest';
import { getBattleRetryConfig } from './battleRetry';
import { getDailyChallenge } from './dailyChallenge';
import { FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS } from './singularityBosses';

const save = {
  dragons: {
    fire: { owned: true, level: 5 },
    ice: { owned: true, level: 3 },
    shadow: { owned: false, level: 1 },
  },
};

describe('battle retry configuration', () => {
  it.each(['outerGrid', 'frozenCache', 'stormSpine', 'adminCore', 'map'])('keeps the encounter, party and %s checkpoint', returnScreen => {
    const config = {
      dragonId: 'fire', npcId: 'firewall_sentinel', benchDragonId: 'ice',
      campaignNodeId: 'signal-breach', returnScreen,
    };
    const retry = getBattleRetryConfig(config, save);

    expect(retry).toEqual(config);
    expect(retry).not.toBe(config);
  });

  it('keeps the exact shared daily opponent and reward policy instead of rerolling it', () => {
    const dailyNpc = getDailyChallenge(20260905, { boostRewards: false });
    const config = { dragonId: 'fire', npcId: 'daily_challenge', dailyNpc, benchDragonId: 'ice' };
    const retry = getBattleRetryConfig(config, save);

    expect(retry).toEqual(config);
    expect(retry.dailyNpc).not.toBe(dailyNpc);
    retry.dailyNpc.stats.hp = 1;
    expect(dailyNpc.stats.hp).not.toBe(1);
  });

  it.each([
    [FINAL_BOSS, { isSingularity: true }],
    [MIRROR_ADMIN, { isSingularity: true, isMirrorAdmin: true }],
    [CORRUPTION_REMNANTS[0], { isSingularity: true, isRemnant: true, remnantId: CORRUPTION_REMNANTS[0].id }],
  ])('retains the scaled phases and completion flags for $id', (boss, flags) => {
    const scaledBoss = structuredClone(boss);
    scaledBoss.phases[0].stats.hp = 321;
    const config = {
      dragonId: 'fire', npcId: boss.id, boss: scaledBoss, phases: scaledBoss.phases,
      returnScreen: 'singularity', ...flags,
    };
    const retry = getBattleRetryConfig(config, save);

    expect(retry).toEqual({ ...config, benchDragonId: null });
    expect(retry.boss.phases[0].stats.hp).toBe(321);
    retry.boss.phases[0].stats.hp = 1;
    expect(scaledBoss.phases[0].stats.hp).toBe(321);
  });

  it.each([null, { dragonId: 'shadow', npcId: 'firewall_sentinel' }, { dragonId: 'unknown', npcId: 'firewall_sentinel' }, { dragonId: 'fire', npcId: 'unknown' }])('returns to preparation when the primary or encounter is unavailable', config => {
    expect(getBattleRetryConfig(config, save)).toBeNull();
  });

  it.each(['shadow', 'unknown', 'fire', null])('drops unavailable or duplicate reserve %s without changing the primary', benchDragonId => {
    const config = { dragonId: 'fire', npcId: 'firewall_sentinel', benchDragonId };
    expect(getBattleRetryConfig(config, save)).toEqual({ ...config, benchDragonId: null });
    expect(config.benchDragonId).toBe(benchDragonId);
  });
});
