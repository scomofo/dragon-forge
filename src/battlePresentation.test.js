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
  buildDefeatRecap,
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

describe('buildDefeatRecap', () => {
  const npcHit = (overrides = {}) => ({
    turn: 7,
    attacker: 'npc',
    moveName: 'Tectonic Rupture',
    moveKey: 'golem_rupture',
    damage: 84,
    effectiveness: 1,
    isCritical: false,
    wasCharged: false,
    playerDefended: false,
    ...overrides,
  });
  const playerHit = (overrides = {}) => ({
    turn: 6,
    attacker: 'player',
    moveName: 'Ember Fang',
    moveKey: 'ember_fang',
    damage: 52,
    effectiveness: 1,
    isCritical: false,
    wasCharged: false,
    playerDefended: false,
    ...overrides,
  });

  test('returns an empty recap for empty or missing records', () => {
    for (const records of [[], null, undefined, 'nope']) {
      const recap = buildDefeatRecap(records, 7);
      expect(recap.lostTurn).toBe(7);
      expect(recap.biggestHitTaken).toBeNull();
      expect(recap.biggestHitDealt).toBeNull();
      expect(recap.causes).toEqual([]);
      expect(recap.summary).toBeNull();
      expect(recap.dealtSummary).toBeNull();
    }
  });

  test('picks the biggest single hit taken across all turns', () => {
    const records = [
      npcHit({ turn: 5, moveName: 'Rock Throw', damage: 30 }),
      npcHit({ turn: 7, damage: 84 }),
      npcHit({ turn: 6, moveName: 'Heavy Slam', damage: 60 }),
    ];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.biggestHitTaken.damage).toBe(84);
    expect(recap.biggestHitTaken.turn).toBe(7);
    expect(recap.summary).toBe('Turn 7 — Tectonic Rupture hit for 84.');
  });

  test('picks the biggest hit dealt for symmetry', () => {
    const records = [npcHit(), playerHit({ damage: 52 }), playerHit({ turn: 4, moveName: 'Claw', damage: 40 })];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.biggestHitDealt.damage).toBe(52);
    expect(recap.biggestHitDealt.moveName).toBe('Ember Fang');
    expect(recap.dealtSummary).toBe('Your biggest hit: Ember Fang for 52.');
  });

  test('reports dealt damage even when the player took no damage', () => {
    const recap = buildDefeatRecap([playerHit()], 7);
    expect(recap.biggestHitTaken).toBeNull();
    expect(recap.summary).toBeNull();
    expect(recap.dealtSummary).toBe('Your biggest hit: Ember Fang for 52.');
  });

  test('ignores zero-damage records when finding biggest hits', () => {
    const recap = buildDefeatRecap([npcHit({ damage: 0 }), playerHit({ damage: 0 })], 7);
    expect(recap.biggestHitTaken).toBeNull();
    expect(recap.biggestHitDealt).toBeNull();
    expect(recap.summary).toBeNull();
  });

  test('flags super-effective and resisted hits', () => {
    const se = buildDefeatRecap([npcHit({ effectiveness: 2 })], 7);
    expect(se.causes).toEqual(['super-effective ×2']);
    expect(se.summary).toBe('Turn 7 — Tectonic Rupture hit for 84: super-effective ×2.');

    const resisted = buildDefeatRecap([npcHit({ effectiveness: 0.5 })], 7);
    expect(resisted.causes).toEqual(['resisted ×0.5']);
    expect(resisted.summary).toBe('Turn 7 — Tectonic Rupture hit for 84: resisted ×0.5.');
  });

  test('omits the effectiveness fragment for neutral hits', () => {
    const recap = buildDefeatRecap([npcHit({ effectiveness: 1 })], 7);
    expect(recap.causes).toEqual([]);
    expect(recap.summary).toBe('Turn 7 — Tectonic Rupture hit for 84.');
  });

  test('flags charged, critical, and expired-defend causes together', () => {
    const records = [
      npcHit({ turn: 6, damage: 20, playerDefended: true }),
      npcHit({ turn: 7, damage: 84, effectiveness: 2, wasCharged: true, isCritical: true }),
    ];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.causes).toEqual([
      'super-effective ×2',
      'opponent charged',
      'critical hit',
      'your defend expired',
    ]);
    expect(recap.summary).toBe(
      'Turn 7 — charged Tectonic Rupture hit for 84: super-effective ×2 × opponent charged × critical hit × your defend expired.'
    );
  });

  test('does not claim defend expired when the player never defended', () => {
    const recap = buildDefeatRecap([npcHit({ turn: 7, damage: 84 })], 7);
    expect(recap.causes).not.toContain('your defend expired');
  });

  test('does not claim defend expired when the player defended the hit turn too', () => {
    const records = [
      npcHit({ turn: 6, damage: 20, playerDefended: true }),
      npcHit({ turn: 7, damage: 84, playerDefended: true }),
    ];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.causes).not.toContain('your defend expired');
  });

  test('does not claim defend expired from a stale defend two turns back', () => {
    const records = [
      npcHit({ turn: 5, damage: 20, playerDefended: true }),
      npcHit({ turn: 6, damage: 30 }),
      npcHit({ turn: 7, damage: 84 }),
    ];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.causes).not.toContain('your defend expired');
  });

  test('detects defend on the previous turn from any record of that turn', () => {
    // The player defended turn 6 (their own defend produces no damaging
    // record); the NPC's turn-6 hit carries the turn's defended flag.
    const records = [
      npcHit({ turn: 6, damage: 12, playerDefended: true }),
      npcHit({ turn: 7, damage: 84 }),
    ];
    const recap = buildDefeatRecap(records, 7);
    expect(recap.causes).toContain('your defend expired');
  });

  test('rounds fractional effectiveness multipliers cleanly', () => {
    const recap = buildDefeatRecap([npcHit({ effectiveness: 1.5 })], 7);
    expect(recap.causes).toEqual(['super-effective ×1.5']);
  });
});
