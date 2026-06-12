import { describe, expect, it } from 'vitest';
import { getEffectiveStreak, getDailyStreakMultiplier } from './dailyChallenge';

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
