import { describe, expect, it } from 'vitest';
import { JOURNAL_DRAGON_IDS, dragons } from './gameData';
import {
  getWantedCoreElement,
  getWantedDragon,
  getWeekSeed,
  WANTED_DRAGON_CORE_BONUS,
} from './wantedDragon';

describe('weekly wanted dragon', () => {
  it('uses ISO week seeds (year*100 + week)', () => {
    // 2026-09-21 is a Monday, 2026-09-27 the Sunday of the same ISO week.
    expect(getWeekSeed(new Date(2026, 8, 21))).toBe(getWeekSeed(new Date(2026, 8, 27)));
    expect(getWeekSeed(new Date(2026, 8, 27))).not.toBe(getWeekSeed(new Date(2026, 8, 28)));
    // Year boundary: 2025-12-29 (Mon) belongs to ISO week 1 of 2026.
    expect(getWeekSeed(new Date(2025, 11, 29))).toBe(202601);
    expect(getWeekSeed(new Date(2026, 0, 1))).toBe(202601);
    expect(getWeekSeed(new Date(2026, 0, 4))).toBe(202601);
    expect(getWeekSeed(new Date(2026, 0, 5))).toBe(202602);
  });

  it('is deterministic per week', () => {
    expect(getWantedDragon(new Date(2026, 8, 21))).toBe(getWantedDragon(new Date(2026, 8, 25)));
    expect(getWantedDragon()).toBe(getWantedDragon(new Date()));
  });

  it('always picks a journal dragon', () => {
    for (let w = 0; w < 53; w += 1) {
      const dragon = getWantedDragon(new Date(2026, 0, 4 + w * 7));
      expect(JOURNAL_DRAGON_IDS).toContain(dragon);
      expect(dragons[dragon]?.name).toBeTruthy();
    }
  });

  it('rotates week to week instead of pinning', () => {
    // Without seed mixing the raw LCG pins a single dragon for the whole
    // year (0 week-boundary changes in 2026). The weekly pick must turn over.
    const picks = [];
    for (let w = 0; w < 52; w += 1) picks.push(getWantedDragon(new Date(2026, 0, 4 + w * 7)));
    const changes = picks.slice(1).filter((d, i) => d !== picks[i]).length;
    expect(changes).toBeGreaterThan(30);
    expect(new Set(picks).size).toBeGreaterThanOrEqual(6);
  });

  it('reaches every journal dragon over time', () => {
    const seen = new Set();
    for (let y = 2024; y <= 2032; y += 1) {
      for (let w = 0; w < 53; w += 1) {
        seen.add(getWantedDragon(new Date(y, 0, 1 + w * 7)));
      }
    }
    expect([...seen].sort()).toEqual([...JOURNAL_DRAGON_IDS].sort());
  });

  it('documents the bonus rate and core mapping', () => {
    // +2 cores per win — flagged for ADR-0006 economy review.
    expect(WANTED_DRAGON_CORE_BONUS).toBe(2);
    expect(getWantedCoreElement('fire')).toBe('fire');
    expect(getWantedCoreElement('void')).toBe('void');
    expect(getWantedCoreElement('light')).toBe('light');
    // Synthesis has no core bucket of its own; it maps to Void.
    expect(getWantedCoreElement('synthesis')).toBe('void');
    expect(getWantedCoreElement('nope')).toBeNull();
  });
});
