import { describe, expect, it } from 'vitest';
import { getEffectiveStreak, getDailyStreakMultiplier, getMsUntilDailyReset } from './dailyChallenge';

function seedFor(date) {
  return date.getFullYear() * 10000 + (date.getMonth() + 1) * 100 + date.getDate();
}

function yesterdaySeed() {
  const d = new Date();
  d.setDate(d.getDate() - 1);
  return seedFor(d);
}

function staleSeed() {
  const d = new Date();
  d.setDate(d.getDate() - 3);
  return seedFor(d);
}

describe('getEffectiveStreak', () => {
  it('returns the stored streak when yesterday was completed', () => {
    const save = { lastDailyCompleted: yesterdaySeed(), dailyStreak: 4 };
    expect(getEffectiveStreak(save)).toBe(4);
  });

  it('returns 0 when the streak has lapsed', () => {
    const save = { lastDailyCompleted: staleSeed(), dailyStreak: 5 };
    expect(getEffectiveStreak(save)).toBe(0);
  });

  it('returns 0 for a save with no daily history', () => {
    expect(getEffectiveStreak({})).toBe(0);
  });
});

describe('getDailyStreakMultiplier', () => {
  it('applies 1.0 on a first or broken streak', () => {
    expect(getDailyStreakMultiplier({})).toBe(1.0);
    expect(getDailyStreakMultiplier({ lastDailyCompleted: staleSeed(), dailyStreak: 5 })).toBe(1.0);
  });

  it('grows by 0.1 per consecutive day from a live streak', () => {
    const save = { lastDailyCompleted: yesterdaySeed(), dailyStreak: 2 };
    expect(getDailyStreakMultiplier(save)).toBeCloseTo(1.2);
  });

  it('caps at 1.5', () => {
    const save = { lastDailyCompleted: yesterdaySeed(), dailyStreak: 20 };
    expect(getDailyStreakMultiplier(save)).toBe(1.5);
  });
});

describe('getMsUntilDailyReset', () => {
  it('is positive and never more than 24 hours out', () => {
    const ms = getMsUntilDailyReset();
    expect(ms).toBeGreaterThan(0);
    expect(ms).toBeLessThanOrEqual(24 * 60 * 60 * 1000);
  });
});

describe('seed codes (shareable daily)', () => {
  it('round-trips a date seed', async () => {
    const { encodeSeedCode, decodeSeedCode, getDailyChallenge } = await import('./dailyChallenge');
    expect(decodeSeedCode(encodeSeedCode(20260903))).toBe(20260903);
  });

  it('accepts lowercase and surrounding whitespace', async () => {
    const { decodeSeedCode } = await import('./dailyChallenge');
    expect(decodeSeedCode('  df-20260903 ')).toBe(20260903);
  });

  it('rejects garbage and impossible dates', async () => {
    const { decodeSeedCode } = await import('./dailyChallenge');
    expect(decodeSeedCode('hello')).toBeNull();
    expect(decodeSeedCode('DF-20261301')).toBeNull(); // month 13
    expect(decodeSeedCode('DF-123')).toBeNull();
  });

  it('shared seed reproduces the same fighter with base rewards', async () => {
    const { getDailyChallenge } = await import('./dailyChallenge');
    const a = getDailyChallenge(20260903, { boostRewards: false });
    const b = getDailyChallenge(20260903, { boostRewards: false });
    expect(a.name).toBe(b.name);
    expect(a.stats).toEqual(b.stats);
    expect(a.level).toBe(b.level);
    expect(a.shared).toBe(true);
    // Base rewards: the official daily pays 3x scraps / 2x XP; shared pays 1x
    const official = getDailyChallenge(20260903);
    expect(a.scrapsReward).toBeLessThan(official.scrapsReward);
    expect(a.baseXP).toBeLessThan(official.baseXP);
  });

  it('marks official (no-override) dailies as not shared', async () => {
    const { getDailyChallenge } = await import('./dailyChallenge');
    expect(getDailyChallenge().shared).toBe(false);
    expect(getDailyChallenge(null).shared).toBe(false);
    expect(getDailyChallenge(20260903).shared).toBe(true);
  });
});
