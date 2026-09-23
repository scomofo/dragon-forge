import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { BUY_ITEMS, canAffordBuy } from './shopItems';

function dateSeed(d) {
  return d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();
}

function seedDaysAgo(n) {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return dateSeed(d);
}

describe('streak shield', () => {
  let api;

  async function reload() {
    vi.resetModules();
    api = await import('./persistence');
  }

  beforeEach(async () => {
    const values = new Map();
    const storage = {
      getItem: key => values.get(key) ?? null,
      setItem: (key, value) => values.set(key, String(value)),
      removeItem: key => values.delete(key),
    };
    vi.stubGlobal('window', { localStorage: storage });
    vi.stubGlobal('localStorage', storage);
    await reload();
  });

  afterEach(() => vi.unstubAllGlobals());

  it('defaults to 0 and migrates onto legacy saves', () => {
    expect(api.loadSave().inventory.streakShield).toBe(0);
    const legacy = api.loadSave();
    delete legacy.inventory.streakShield;
    api.writeSave(legacy);
    expect(api.loadSave().inventory.streakShield).toBe(0);
  });

  it('setStreakShield round-trips', () => {
    api.setStreakShield(1);
    expect(api.loadSave().inventory.streakShield).toBe(1);
    api.setStreakShield(0);
    expect(api.loadSave().inventory.streakShield).toBe(0);
  });

  it('extends the streak normally with no shield involved', () => {
    const save = api.loadSave();
    save.dailyStreak = 4;
    save.lastDailyCompleted = seedDaysAgo(1);
    save.inventory.streakShield = 0;
    api.writeSave(save);
    api.completeDailyChallenge(seedDaysAgo(0));
    const next = api.loadSave();
    expect(next.dailyStreak).toBe(5);
    expect(next.lastDailyCompleted).toBe(seedDaysAgo(0));
    expect(next.inventory.streakShield).toBe(0);
  });

  it('consumes one shield to preserve the streak across a missed day', () => {
    const save = api.loadSave();
    save.dailyStreak = 4;
    save.lastDailyCompleted = seedDaysAgo(3);
    save.inventory.streakShield = 1;
    api.writeSave(save);
    api.completeDailyChallenge(seedDaysAgo(0));
    const next = api.loadSave();
    expect(next.dailyStreak).toBe(5);
    expect(next.inventory.streakShield).toBe(0);
    expect(next.lastDailyCompleted).toBe(seedDaysAgo(0));
  });

  it('resets to 1 on a missed day with no shield', () => {
    const save = api.loadSave();
    save.dailyStreak = 9;
    save.lastDailyCompleted = seedDaysAgo(3);
    save.inventory.streakShield = 0;
    api.writeSave(save);
    api.completeDailyChallenge(seedDaysAgo(0));
    expect(api.loadSave().dailyStreak).toBe(1);
  });

  it('does not consume a shield when the daily was already completed today', () => {
    const save = api.loadSave();
    save.dailyStreak = 4;
    save.lastDailyCompleted = seedDaysAgo(0);
    save.inventory.streakShield = 1;
    api.writeSave(save);
    api.completeDailyChallenge(seedDaysAgo(0));
    const next = api.loadSave();
    expect(next.dailyStreak).toBe(4);
    expect(next.inventory.streakShield).toBe(1);
  });
});

describe('streak shield shop entry', () => {
  const item = BUY_ITEMS.find(i => i.effect === 'streak_shield');

  it('is listed at 500 DataScraps', () => {
    expect(item).toBeDefined();
    // Deliberately steep — flagged for ADR-0006 economy review.
    expect(item.cost).toBe(500);
    expect(item.stackable).toBe(false);
  });

  it('cannot be bought while holding one (cap 1)', () => {
    expect(canAffordBuy(item, { dataScraps: 9999, inventory: { streakShield: 1 } })).toBe(false);
    expect(canAffordBuy(item, { dataScraps: 9999, inventory: { streakShield: 0 } })).toBe(true);
    expect(canAffordBuy(item, { dataScraps: 499, inventory: { streakShield: 0 } })).toBe(false);
  });
});
