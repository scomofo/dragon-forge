import { describe, expect, test, afterEach } from 'vitest';
import {
  classifyBattleEvent,
  getBattlePresentationProfile,
  getBattleResultCallout,
  getStatusMoveSummary,
  getTellCallout,
  shouldAnimateBattleEvent,
  getEffectivenessBadge,
  EFFECTIVENESS_BADGES,
  TELL_VARIANT,
} from './battlePresentation';
import { BOSS_PATTERNS } from './bossPatterns';
import { setBattleSpeed } from './battleSpeed';

afterEach(() => setBattleSpeed(1));

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

  test('heavy moves telegraph longer and fly slower than light moves', () => {
    const event = { action: 'attack', hit: true, damage: 20, effectiveness: 1, targetHp: 40 };
    const heavy = getBattlePresentationProfile(event, { power: 80 });
    const light = getBattlePresentationProfile(event, { power: 40 });
    expect(heavy.anticipationMs).toBeGreaterThan(light.anticipationMs);
    expect(heavy.vfxTravelMs).toBeGreaterThan(light.vfxTravelMs);
  });

  test('keeps authored durations at 1x so playback boundaries scale only once', () => {
    const event = { action: 'attack', hit: true, damage: 20, effectiveness: 1, targetHp: 40 };
    const normal = getBattlePresentationProfile(event, { power: 40 });
    setBattleSpeed(2);
    const fast = getBattlePresentationProfile(event, { power: 40 });
    expect(fast).toEqual(normal);
  });
});

describe('getTellCallout', () => {
  test('charge wind-up returns icon + one-line warning under the tell variant', () => {
    expect(getTellCallout({ kind: 'charge', npcName: 'Buffer Overflow', moveName: 'Magma Breath' })).toEqual({
      icon: '⚡',
      text: 'BUFFER OVERFLOW IS WINDING UP MAGMA BREATH!',
      variant: 'tell',
    });
  });

  test('signature pre-warning returns icon + one-line warning under the tell variant', () => {
    expect(getTellCallout({ kind: 'signature', npcName: 'Logic Bomb', moveName: 'Final Detonation' })).toEqual({
      icon: '💥',
      text: 'SIGNATURE — LOGIC BOMB UNLEASHES FINAL DETONATION!',
      variant: 'tell',
    });
  });

  test('every authored boss pattern has an intro tell under the same contract', () => {
    const patternIds = Object.keys(BOSS_PATTERNS);
    expect(patternIds).toHaveLength(13);
    for (const patternId of patternIds) {
      const callout = getTellCallout({ kind: 'pattern', patternId });
      expect(callout, `intro for ${patternId}`).toMatchObject({ variant: TELL_VARIANT });
      expect(typeof callout.icon, `icon for ${patternId}`).toBe('string');
      expect(callout.icon.length, `icon for ${patternId}`).toBeGreaterThan(0);
      expect(typeof callout.text, `text for ${patternId}`).toBe('string');
      expect(callout.text.length, `text for ${patternId}`).toBeGreaterThan(0);
    }
  });

  test('pattern beats fire through the same helper with the same contract', () => {
    const beats = [
      ['buffer_overflow', 'overheat'],
      ['bit_wraith', 'phase'],
      ['crypto_crab', 'decrypted'],
      ['phishing_siren', 'lure'],
      ['glitch_hydra', 'headBroken'],
      ['glitch_hydra', 'lockBroken'],
      ['logic_bomb', 'detonation'],
      ['recursive_golem', 'rupture'],
      ['protocol_vulture', 'perch'],
      ['data_corruption', 'corrupted'],
      ['memory_leak', 'maxed'],
      ['stack_overflow', 'surge'],
      ['stack_overflow', 'crash'],
      ['mirror_admin_reset', 'reset'],
    ];
    for (const [patternId, beat] of beats) {
      expect(getTellCallout({ kind: 'pattern', patternId, beat }), `${patternId}/${beat}`)
        .toMatchObject({ variant: 'tell' });
    }
  });

  test('returns null for unknown patterns, unknown beats, and missing details', () => {
    expect(getTellCallout({ kind: 'pattern', patternId: 'not_a_boss' })).toBeNull();
    expect(getTellCallout({ kind: 'pattern', patternId: 'bit_wraith', beat: 'nope' })).toBeNull();
    expect(getTellCallout({ kind: 'charge' })).toBeNull();
    expect(getTellCallout({ kind: 'signature' })).toBeNull();
    expect(getTellCallout()).toBeNull();
  });

  test('tell variant does not collide with result callout variants', () => {
    const resultVariants = new Set(
      [
        { action: 'attack', hit: false },
        { action: 'attack', hit: true, effectiveness: 0.5, targetHp: 10 },
        { action: 'attack', hit: true, effectiveness: 2, targetHp: 10 },
        { action: 'attack', hit: true, isCritical: true, targetHp: 10 },
        { action: 'attack', hit: true, reflected: true, targetHp: 10 },
        { action: 'attack', hit: true, targetHp: 0 },
        { action: 'buff' },
        { action: 'charge' },
        { action: 'heal' },
      ]
        .map(getBattleResultCallout)
        .filter(Boolean)
        .map(callout => callout.variant),
    );
    expect(resultVariants.has(TELL_VARIANT)).toBe(false);
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

describe('getEffectivenessBadge', () => {
  test('maps ADVANTAGE matchups to the super-effective chip', () => {
    expect(getEffectivenessBadge('fire', 'ice')).toEqual({ symbol: '▲', text: 'SE', matchClass: 'advantage' });
    expect(getEffectivenessBadge('shadow', 'light')).toEqual({ symbol: '▲', text: 'SE', matchClass: 'advantage' });
  });

  test('maps RESISTED matchups to the resisted chip', () => {
    expect(getEffectivenessBadge('fire', 'stone')).toEqual({ symbol: '▼', text: 'RES', matchClass: 'resisted' });
    expect(getEffectivenessBadge('light', 'void')).toEqual({ symbol: '▼', text: 'RES', matchClass: 'resisted' });
  });

  test('maps NORMAL matchups to the neutral chip', () => {
    expect(getEffectivenessBadge('fire', 'storm')).toEqual({ symbol: '●', text: 'NEUT', matchClass: 'normal' });
    expect(getEffectivenessBadge('ice', 'venom')).toEqual({ symbol: '●', text: 'NEUT', matchClass: 'normal' });
  });

  test('badge matchClass matches the lowercase matchup class used on .move-btn', () => {
    expect(EFFECTIVENESS_BADGES.ADVANTAGE.matchClass).toBe('advantage');
    expect(EFFECTIVENESS_BADGES.RESISTED.matchClass).toBe('resisted');
    expect(EFFECTIVENESS_BADGES.NORMAL.matchClass).toBe('normal');
  });

  test('falls back to neutral for unknown elements', () => {
    expect(getEffectivenessBadge('nope', 'ice')).toEqual({ symbol: '●', text: 'NEUT', matchClass: 'normal' });
    expect(getEffectivenessBadge('fire', 'nope')).toEqual({ symbol: '●', text: 'NEUT', matchClass: 'normal' });
  });
});
