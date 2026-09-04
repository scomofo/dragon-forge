import { describe, it, expect } from 'vitest';
import { computeDaysAway, formatPlaytime, getWelcomeBackGrant } from './persistence';

describe('computeDaysAway', () => {
  const day = (y, m, d) => new Date(y, m - 1, d, 12).getTime();

  it('is 0 for same-day and never-played', () => {
    expect(computeDaysAway(null, day(2026, 9, 3))).toBe(0);
    expect(computeDaysAway(day(2026, 9, 3), day(2026, 9, 3))).toBe(0);
  });

  it('counts whole calendar days, not 24h windows', () => {
    expect(computeDaysAway(day(2026, 8, 30), day(2026, 9, 3))).toBe(4); // Aug 30 → Sep 3
    expect(computeDaysAway(day(2026, 9, 1), day(2026, 9, 3))).toBe(2);
  });

  it('never goes negative (clock skew safe)', () => {
    expect(computeDaysAway(day(2026, 9, 5), day(2026, 9, 3))).toBe(0);
  });
});

describe('formatPlaytime', () => {
  it('formats minutes and hours', () => {
    expect(formatPlaytime(0)).toBe('<1m');
    expect(formatPlaytime(45 * 60000)).toBe('45m');
    expect(formatPlaytime(150 * 60000)).toBe('2h 30m');
  });
});

describe('getWelcomeBackGrant', () => {
  it('pays nothing before 3 days away', () => {
    expect(getWelcomeBackGrant(0)).toBe(0);
    expect(getWelcomeBackGrant(2)).toBe(0);
  });

  it('scales with time away and caps at 200', () => {
    expect(getWelcomeBackGrant(3)).toBe(125);
    expect(getWelcomeBackGrant(6)).toBe(200);
    expect(getWelcomeBackGrant(30)).toBe(200);
  });
});
