import { describe, expect, test } from 'vitest';
import {
  classifyBattleEvent,
  getBattlePresentationProfile,
  getBattleResultCallout,
  getStatusMoveSummary,
  shouldAnimateBattleEvent,
} from './battlePresentation';

describe('battle presentation profiles', () => {
  test('classifies a missed attack as a miss profile', () => {
    const event = { action: 'attack', hit: false, damage: 0, effectiveness: 1, targetHp: 40 };

    expect(classifyBattleEvent(event)).toBe('miss');
    expect(getBattlePresentationProfile(event).damageVariant).toBe('miss');
  });

  test('classifies a critical hit before effectiveness styling', () => {
    const event = { action: 'attack', hit: true, isCritical: true, damage: 30, effectiveness: 2, targetHp: 20 };

    expect(classifyBattleEvent(event)).toBe('criticalHit');
    expect(getBattlePresentationProfile(event).impactPauseMs).toBeGreaterThan(90);
  });

  test('classifies super-effective and resisted hits distinctly', () => {
    const effective = { action: 'attack', hit: true, damage: 20, effectiveness: 2, targetHp: 10 };
    const resisted = { action: 'attack', hit: true, damage: 4, effectiveness: 0.5, targetHp: 10 };

    expect(classifyBattleEvent(effective)).toBe('effectiveHit');
    expect(classifyBattleEvent(resisted)).toBe('resistedHit');
  });

  test('classifies reflected attacks as reflect even when they hit', () => {
    const event = { action: 'attack', hit: true, reflected: true, damage: 12, effectiveness: 1, targetHp: 15 };

    expect(classifyBattleEvent(event)).toBe('reflect');
    expect(getBattlePresentationProfile(event).damageVariant).toBe('reflect');
  });

  test('classifies KO as the strongest hit punctuation', () => {
    const event = { action: 'attack', hit: true, damage: 50, effectiveness: 1, targetHp: 0 };

    expect(classifyBattleEvent(event)).toBe('ko');
    expect(getBattlePresentationProfile(event).defenderClass).toContain('sprite-ko-hit');
  });

  test('classifies status application separately from the damage hit', () => {
    const event = { action: 'attack', hit: true, damage: 8, effectiveness: 1, appliedStatus: 'Burn', targetHp: 20 };

    expect(getBattlePresentationProfile(event).statusVariant).toBe('status');
  });

  test('returns concise arcade callouts for special outcomes', () => {
    expect(getBattleResultCallout({ action: 'attack', hit: false })).toEqual({ text: 'MISS', variant: 'miss' });
    expect(getBattleResultCallout({ action: 'attack', hit: true, effectiveness: 0.5, targetHp: 10 })).toEqual({ text: 'RESIST', variant: 'resistedHit' });
    expect(getBattleResultCallout({ action: 'attack', hit: true, effectiveness: 2, targetHp: 10 })).toEqual({ text: 'SUPER HIT', variant: 'effectiveHit' });
    expect(getBattleResultCallout({ action: 'attack', hit: true, isCritical: true, targetHp: 10 })).toEqual({ text: 'CRITICAL', variant: 'criticalHit' });
    expect(getBattleResultCallout({ action: 'attack', hit: true, reflected: true, targetHp: 10 })).toEqual({ text: 'REFLECT', variant: 'reflect' });
    expect(getBattleResultCallout({ action: 'attack', hit: true, targetHp: 0 })).toEqual({ text: 'KO', variant: 'ko' });
  });

  test('does not send end-of-turn status bookkeeping through attack animation', () => {
    expect(shouldAnimateBattleEvent({ attacker: 'status', damage: 2, target: 'npc' })).toBe(false);
    expect(shouldAnimateBattleEvent({ attacker: 'npc', action: 'statusSkip', statusName: 'Freeze' })).toBe(false);
    expect(shouldAnimateBattleEvent({ attacker: 'player', action: 'attack', hit: true })).toBe(true);
  });
});

describe('getStatusMoveSummary', () => {
  test('summarizes status moves with chance, name, duration, and effect', () => {
    expect(getStatusMoveSummary({ element: 'fire', canApplyStatus: true })).toEqual({
      label: 'BURN 30%',
      title: 'Burn',
      duration: '2 turns',
      summary: 'Damage over time',
    });
  });

  test('returns null for moves without a status rider', () => {
    expect(getStatusMoveSummary({ element: 'neutral', canApplyStatus: false })).toBeNull();
  });
});
