import { describe, it, expect } from 'vitest';
import {
  getTypeEffectiveness, calculateDamage, calculateXpGain,
  calculateStatsForLevel, getStageForLevel, pickNpcMove, resolveTurn
} from './battleEngine';
import { moves } from './gameData';

describe('getTypeEffectiveness', () => {
  it('returns 2.0 for fire attacking ice', () => {
    expect(getTypeEffectiveness('fire', 'ice')).toBe(2.0);
  });

  it('returns 0.5 for fire attacking stone', () => {
    expect(getTypeEffectiveness('fire', 'stone')).toBe(0.5);
  });

  it('returns 1.0 for neutral element', () => {
    expect(getTypeEffectiveness('neutral', 'fire')).toBe(1.0);
  });

  it('returns 1.0 for unknown elements', () => {
    expect(getTypeEffectiveness('fire', 'neutral')).toBe(1.0);
  });
});

describe('calculateDamage', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('calculates super-effective damage correctly', () => {
    // baseDamage = (28 * 1.0 * 2) - (20 * 0.5) = 56 - 10 = 46
    // typedDamage = 46 * 2.0 = 92
    // finalDamage = floor(92 * rand(0.85..1.0)) => 78..92
    const result = calculateDamage(attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(78);
    expect(result.damage).toBeLessThanOrEqual(92);
    expect(result.effectiveness).toBe(2.0);
    expect(result.hit).toBe(true);
  });

  it('halves damage when defender is defending', () => {
    const defendingTarget = { ...defender, defending: true };
    const result = calculateDamage(attacker, defendingTarget, move);
    expect(result.damage).toBeGreaterThanOrEqual(39);
    expect(result.damage).toBeLessThanOrEqual(46);
  });

  it('applies stage multiplier', () => {
    const stage1Attacker = { ...attacker, stage: 1 };
    // baseDamage = (28 * 0.5 * 2) - (20 * 0.5) = 28 - 10 = 18
    // typedDamage = 18 * 2.0 = 36
    const result = calculateDamage(stage1Attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(30);
    expect(result.damage).toBeLessThanOrEqual(36);
  });

  it('returns minimum 1 damage', () => {
    const weakAttacker = { atk: 1, element: 'fire', stage: 1 };
    const tankDefender = { def: 100, element: 'fire', defending: true };
    const result = calculateDamage(weakAttacker, tankDefender, move);
    expect(result.damage).toBe(1);
  });

  it('can miss based on accuracy', () => {
    const lowAccMove = { element: 'fire', power: 65, accuracy: 0 };
    const result = calculateDamage(attacker, defender, lowAccMove);
    expect(result.hit).toBe(false);
    expect(result.damage).toBe(0);
  });
});

describe('getStageForLevel', () => {
  it('returns stage 1 for levels below 10', () => {
    expect(getStageForLevel(1)).toBe(1);
    expect(getStageForLevel(9)).toBe(1);
  });

  it('returns stage 2 for levels 10-24', () => {
    expect(getStageForLevel(10)).toBe(2);
    expect(getStageForLevel(24)).toBe(2);
  });

  it('returns stage 3 for levels 25-49', () => {
    expect(getStageForLevel(25)).toBe(3);
    expect(getStageForLevel(49)).toBe(3);
  });

  it('returns stage 4 for level 50+', () => {
    expect(getStageForLevel(50)).toBe(4);
    expect(getStageForLevel(99)).toBe(4);
  });
});

describe('calculateXpGain', () => {
  it('gives base XP when levels are equal', () => {
    expect(calculateXpGain(50, 10, 10)).toBe(50);
  });

  it('gives more XP for fighting higher level enemies', () => {
    const xp = calculateXpGain(50, 5, 10);
    expect(xp).toBe(100);
  });

  it('gives less XP for fighting lower level enemies', () => {
    const xp = calculateXpGain(50, 10, 5);
    expect(xp).toBe(25);
  });

  it('gives minimum 1 XP', () => {
    const xp = calculateXpGain(50, 99, 1);
    expect(xp).toBeGreaterThanOrEqual(1);
  });
});

describe('calculateStatsForLevel', () => {
  it('returns base stats at level 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 1);
    expect(result).toEqual({ hp: 110, atk: 28, def: 20, spd: 18 });
  });

  it('adds 3 per stat per level above 1', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 5);
    // 4 levels above 1 => +12 to each stat
    expect(result).toEqual({ hp: 122, atk: 40, def: 32, spd: 30 });
  });
});

describe('pickNpcMove', () => {
  it('returns a valid move key from the NPC move list', () => {
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    const result = pickNpcMove(npcMoveKeys, 'stone', 'fire');
    expect(['rock_slide', 'earthquake', 'basic_attack']).toContain(result);
  });

  it('favors super-effective moves', () => {
    // Stone vs Storm => rock_slide and earthquake are both stone (2x vs storm)
    // Run 50 times — super-effective should appear majority
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    let superEffectiveCount = 0;
    for (let i = 0; i < 50; i++) {
      const result = pickNpcMove(npcMoveKeys, 'stone', 'storm');
      const move = moves[result] || moves.basic_attack;
      const eff = getTypeEffectiveness(move.element, 'storm');
      if (eff > 1.0) superEffectiveCount++;
    }
    expect(superEffectiveCount).toBeGreaterThan(25);
  });
});

describe('resolveTurn', () => {
  const playerState = {
    name: 'Magma Dragon', element: 'fire', stage: 3,
    hp: 100, maxHp: 110, atk: 28, def: 20, spd: 18, defending: false,
  };
  const npcState = {
    name: 'Firewall Sentinel', element: 'stone', stage: 3,
    hp: 130, maxHp: 130, atk: 18, def: 32, spd: 8, defending: false,
  };

  it('returns updated player and npc state', () => {
    const result = resolveTurn(playerState, npcState, 'magma_breath', 'rock_slide');
    expect(result.player).toHaveProperty('hp');
    expect(result.npc).toHaveProperty('hp');
    expect(result.events).toBeInstanceOf(Array);
    expect(result.events.length).toBeGreaterThanOrEqual(2);
  });

  it('faster combatant attacks first', () => {
    // Player spd 18 > NPC spd 8, so player goes first
    const result = resolveTurn(playerState, npcState, 'magma_breath', 'rock_slide');
    expect(result.events[0].attacker).toBe('player');
    expect(result.events[1].attacker).toBe('npc');
  });

  it('sets defending flag when defend is chosen', () => {
    const result = resolveTurn(playerState, npcState, 'defend', 'rock_slide');
    // Player chose defend — the defend event should be first (player is faster)
    const defendEvent = result.events.find(e => e.action === 'defend');
    expect(defendEvent).toBeDefined();
  });

  it('stops turn if first attacker KOs the target', () => {
    const weakNpc = { ...npcState, hp: 1 };
    const result = resolveTurn(playerState, weakNpc, 'magma_breath', 'rock_slide');
    // NPC should be KO'd, only player attack event + no npc attack
    expect(result.npc.hp).toBe(0);
    const npcAttackEvents = result.events.filter(e => e.attacker === 'npc' && e.action === 'attack');
    expect(npcAttackEvents.length).toBe(0);
  });
});
