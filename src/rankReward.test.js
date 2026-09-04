import { describe, it, expect } from 'vitest';
import { getRankBonusScraps } from './persistence';

describe('getRankBonusScraps', () => {
  it('pays S > A > B and nothing for C or unknown ranks', () => {
    expect(getRankBonusScraps('S')).toBe(15);
    expect(getRankBonusScraps('A')).toBe(8);
    expect(getRankBonusScraps('B')).toBe(4);
    expect(getRankBonusScraps('C')).toBe(0);
    expect(getRankBonusScraps(undefined)).toBe(0);
  });

  it('keeps the ordering monotone with rank quality', () => {
    expect(getRankBonusScraps('S')).toBeGreaterThan(getRankBonusScraps('A'));
    expect(getRankBonusScraps('A')).toBeGreaterThan(getRankBonusScraps('B'));
    expect(getRankBonusScraps('B')).toBeGreaterThan(getRankBonusScraps('C'));
  });
});
