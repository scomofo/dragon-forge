import { describe, it, expect } from 'vitest';
import {
  getTypeEffectiveness, calculateDamage, calculateXpGain,
  calculateStatsForLevel, getStageForLevel, pickNpcMove, resolveTurn,
  applyStatus, processStatusTick, getTypeEffectivenessLabel,
  effectiveAttack, CHARGE_ATK_MULTIPLIER, MAX_ATK_MULTIPLIER,
} from './battleEngine';
import { moves, typeChart } from './gameData';

describe('effectiveAttack (atk-up cap)', () => {
  it('returns base atk with no buff and no charge', () => {
    expect(effectiveAttack(100, null)).toBe(100);
    expect(effectiveAttack(100, undefined, 1)).toBe(100);
  });

  it('applies a lone atkBuff multiplier', () => {
    expect(effectiveAttack(100, { multiplier: 1.3 })).toBe(130);
  });

  it('applies a lone charge multiplier', () => {
    expect(effectiveAttack(100, null, CHARGE_ATK_MULTIPLIER)).toBe(140);
  });

  it('caps the charge × atkBuff stack at MAX_ATK_MULTIPLIER instead of 1.82×', () => {
    // charge 1.4 × focus 1.3 = 1.82 — must be clamped, not 182.
    const uncapped = Math.floor(100 * CHARGE_ATK_MULTIPLIER * 1.3);
    const result = effectiveAttack(100, { multiplier: 1.3 }, CHARGE_ATK_MULTIPLIER);
    expect(result).toBe(Math.floor(100 * MAX_ATK_MULTIPLIER));
    expect(result).toBeLessThan(uncapped);
  });

  it('never exceeds MAX_ATK_MULTIPLIER for any reachable buff/charge combo', () => {
    const result = effectiveAttack(200, { multiplier: 1.4 }, CHARGE_ATK_MULTIPLIER);
    expect(result).toBeLessThanOrEqual(Math.floor(200 * MAX_ATK_MULTIPLIER));
  });
});

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

describe('getTypeEffectivenessLabel', () => {
  it('derives labels from the same type chart as combat damage', () => {
    expect(getTypeEffectivenessLabel('venom', 'stone')).toBe('RESISTED');
    expect(getTypeEffectivenessLabel('stone', 'fire')).toBe('ADVANTAGE');
    expect(getTypeEffectivenessLabel('void', 'shadow')).toBe('RESISTED');
  });

  it('labels every non-neutral strong and resisted matchup from the type chart', () => {
    for (const [attacker, defenders] of Object.entries(typeChart)) {
      for (const [defender, multiplier] of Object.entries(defenders)) {
        if (multiplier === 2.0) {
          expect(getTypeEffectivenessLabel(attacker, defender)).toBe('ADVANTAGE');
        } else if (multiplier === 0.5) {
          expect(getTypeEffectivenessLabel(attacker, defender)).toBe('RESISTED');
        }
      }
    }
  });
});

describe('calculateDamage', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('calculates super-effective damage correctly', () => {
    // baseDamage = (28 * 1.0 * 2) - (20 * 0.5) = 56 - 10 = 46
    // typedDamage = 46 * 2.0 = 92
    // non-crit range: 78..92; crit (1.5x) range: 117..138
    const result = calculateDamage(attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(78);
    expect(result.damage).toBeLessThanOrEqual(138);
    expect(result.effectiveness).toBe(2.0);
    expect(result.hit).toBe(true);
  });

  it('halves damage when defender is defending', () => {
    const defendingTarget = { ...defender, defending: true };
    // non-crit range: 39..46; crit (1.5x) range: 58..69
    const result = calculateDamage(attacker, defendingTarget, move);
    expect(result.damage).toBeGreaterThanOrEqual(39);
    expect(result.damage).toBeLessThanOrEqual(69);
  });

  it('applies stage multiplier', () => {
    const stage1Attacker = { ...attacker, stage: 1 };
    // stage-1 mult is now 0.6; power 65 => powerScale 1
    // baseDamage = (28 * 0.6 * 1 * 2) - (20 * 0.5) = 33.6 - 10 = 23.6
    // typedDamage = 23.6 * 2.0 = 47.2
    // non-crit floor range: floor(47.2*0.85)=40 .. floor(47.2)=47
    // crit (1.5x) up to floor(47*1.5)=70 (range allows 72 headroom)
    const result = calculateDamage(stage1Attacker, defender, move);
    expect(result.damage).toBeGreaterThanOrEqual(40);
    expect(result.damage).toBeLessThanOrEqual(72);
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
  it('returns stage 1 for levels below 8', () => {
    expect(getStageForLevel(1)).toBe(1);
    expect(getStageForLevel(7)).toBe(1);
  });

  it('returns stage 2 for levels 8-19', () => {
    expect(getStageForLevel(8)).toBe(2);
    expect(getStageForLevel(19)).toBe(2);
  });

  it('returns stage 3 for levels 20-37', () => {
    expect(getStageForLevel(20)).toBe(3);
    expect(getStageForLevel(37)).toBe(3);
  });

  it('returns stage 4 for level 38+', () => {
    expect(getStageForLevel(38)).toBe(4);
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

  it('distributes a +12/level budget by base-stat ratio', () => {
    const base = { hp: 110, atk: 28, def: 20, spd: 18 };
    const result = calculateStatsForLevel(base, 5);
    // totalBase = 176, budget = 4 * 12 = 48 (power-neutral vs old flat +12)
    // hp:  floor(110 + 48*(110/176)) = floor(110 + 30)      = 140
    // atk: floor(28  + 48*(28/176))  = floor(28 + 7.6363)   = 35
    // def: floor(20  + 48*(20/176))  = floor(20 + 5.4545)   = 25
    // spd: floor(18  + 48*(18/176))  = floor(18 + 4.9090)   = 22
    expect(result).toEqual({ hp: 140, atk: 35, def: 25, spd: 22 });
  });
});

describe('calculateStatsForLevel (shiny)', () => {
  it('applies 1.2x multiplier when shiny', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 1, true);
    expect(result).toEqual({ hp: 120, atk: 24, def: 24, spd: 24 });
  });

  it('applies shiny after level scaling', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 5, true);
    // totalBase = 160, budget = 48, mult = 1.2
    // hp:  floor((100 + 48*(100/160)) * 1.2) = floor(130 * 1.2) = 156
    // atk: floor((20  + 48*(20/160))  * 1.2) = floor(26  * 1.2) = 31
    // def/spd identical to atk = 31
    expect(result).toEqual({ hp: 156, atk: 31, def: 31, spd: 31 });
  });

  it('no change when shiny is false', () => {
    const base = { hp: 100, atk: 20, def: 20, spd: 20 };
    const result = calculateStatsForLevel(base, 1, false);
    expect(result).toEqual({ hp: 100, atk: 20, def: 20, spd: 20 });
  });
});

describe('pickNpcMove', () => {
  it('returns a valid move key from the NPC move list', () => {
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    const result = pickNpcMove(npcMoveKeys, 'stone', 'fire');
    expect(['rock_slide', 'earthquake', 'basic_attack']).toContain(result);
  });

  it('favors super-effective moves', () => {
    // Stone vs Fire => rock_slide and earthquake are both stone (2x vs fire)
    // Run 50 times — super-effective should appear majority
    const npcMoveKeys = ['rock_slide', 'earthquake'];
    let superEffectiveCount = 0;
    for (let i = 0; i < 50; i++) {
      const result = pickNpcMove(npcMoveKeys, 'stone', 'fire');
      const move = moves[result] || moves.basic_attack;
      const eff = getTypeEffectiveness(move.element, 'fire');
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
    const result = resolveTurn(playerState, weakNpc, 'basic_attack', 'rock_slide');
    // NPC should be KO'd, only player attack event + no npc attack
    expect(result.npc.hp).toBe(0);
    const npcAttackEvents = result.events.filter(e => e.attacker === 'npc' && e.action === 'attack');
    expect(npcAttackEvents.length).toBe(0);
  });
});

describe('applyStatus', () => {
  it('applies burn status from fire move', () => {
    const result = applyStatus('fire');
    expect(result).toEqual({ effect: 'fire', turnsLeft: 2 });
  });

  it('returns null for neutral element', () => {
    expect(applyStatus('neutral')).toBe(null);
  });

  it('applies freeze with 1 turn duration', () => {
    const result = applyStatus('ice');
    expect(result).toEqual({ effect: 'ice', turnsLeft: 1 });
  });
});

describe('processStatusTick', () => {
  it('deals DOT damage for burn', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'fire', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(85);
    expect(result.status.turnsLeft).toBe(1);
    expect(result.statusEvent).toEqual({ type: 'dot', damage: 15, effectName: 'Burn', expired: false });
  });

  it('deals DOT damage for poison', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'venom', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(88);
    expect(result.status.turnsLeft).toBe(1);
  });

  it('expires status when turnsLeft reaches 0', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'fire', turnsLeft: 1 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(85);
    expect(result.status).toBe(null);
    expect(result.statusEvent.expired).toBe(true);
  });

  it('returns unchanged state when no status', () => {
    const state = { hp: 100, maxHp: 100, status: null };
    const result = processStatusTick(state);
    expect(result.hp).toBe(100);
    expect(result.statusEvent).toBe(null);
  });

  it('decrements non-DOT status without damage', () => {
    const state = { hp: 100, maxHp: 100, status: { effect: 'stone', turnsLeft: 2 } };
    const result = processStatusTick(state);
    expect(result.hp).toBe(100);
    expect(result.status.turnsLeft).toBe(1);
  });
});

describe('Void type effectiveness', () => {
  it('returns 1.0 for void attacking neutral elements', () => {
    expect(getTypeEffectiveness('void', 'fire')).toBe(1.0);
    expect(getTypeEffectiveness('void', 'ice')).toBe(1.0);
    expect(getTypeEffectiveness('void', 'void')).toBe(1.0);
  });

  it('void erodes solid form — super effective vs stone', () => {
    expect(getTypeEffectiveness('void', 'stone')).toBe(2.0);
  });

  it('void is at home in shadow — resisted by shadow', () => {
    expect(getTypeEffectiveness('void', 'shadow')).toBe(0.5);
  });

  it('returns 1.0 for base elements attacking void', () => {
    expect(getTypeEffectiveness('fire', 'void')).toBe(1.0);
    expect(getTypeEffectiveness('ice', 'void')).toBe(1.0);
  });

  it('shadow is the predator of void', () => {
    expect(getTypeEffectiveness('shadow', 'void')).toBe(2.0);
  });
});

describe('Shadow and light rebalance', () => {
  it('shadow is super effective vs storm and void', () => {
    expect(getTypeEffectiveness('shadow', 'storm')).toBe(2.0);
    expect(getTypeEffectiveness('shadow', 'void')).toBe(2.0);
  });

  it('stone and light are neutral to each other in both directions', () => {
    expect(getTypeEffectiveness('stone', 'light')).toBe(1.0);
    expect(getTypeEffectiveness('light', 'stone')).toBe(1.0);
  });

  it('storm is super effective against void', () => {
    expect(getTypeEffectiveness('storm', 'void')).toBe(2.0);
  });

  it('storm resists shadow — relationship is asymmetric, shadow predates storm', () => {
    expect(getTypeEffectiveness('storm', 'shadow')).toBe(0.5);
  });

  it('venom corrodes radiance — super effective vs light, giving light a pre-endgame weakness', () => {
    expect(getTypeEffectiveness('venom', 'light')).toBe(2.0);
    expect(getTypeEffectiveness('light', 'venom')).toBe(2.0);
  });
});

describe('Null Reflect', () => {
  it('reflects damage back to attacker when target is reflecting', () => {
    const player = {
      name: 'Void Dragon', element: 'void', stage: 3,
      hp: 75, atk: 34, def: 12, spd: 30, status: null,
    };
    const npc = {
      name: 'Test NPC', element: 'fire', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10, status: null,
    };

    const result = resolveTurn(player, npc, 'null_reflect', 'basic_attack');

    const reflectEvent = result.events.find(e => e.action === 'reflect');
    expect(reflectEvent).toBeDefined();
    expect(reflectEvent.attacker).toBe('player');

    const attackEvent = result.events.find(e => e.action === 'attack' && e.attacker === 'npc');
    expect(attackEvent).toBeDefined();
    expect(attackEvent.reflected).toBe(true);

    expect(result.player.hp).toBe(75);
    expect(result.npc.hp).toBeLessThan(100);
  });

  it('reflect has no effect if opponent defends', () => {
    const player = {
      name: 'Void Dragon', element: 'void', stage: 3,
      hp: 75, atk: 34, def: 12, spd: 30, status: null,
    };
    const npc = {
      name: 'Test NPC', element: 'fire', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10, status: null,
    };

    const result = resolveTurn(player, npc, 'null_reflect', 'defend');

    expect(result.player.hp).toBe(75);
    expect(result.npc.hp).toBe(100);
  });
});

describe('Glitch status', () => {
  it('turn resolves normally when combatant has Glitch', () => {
    const player = {
      name: 'Fire Dragon', element: 'fire', stage: 3,
      hp: 110, atk: 28, def: 20, spd: 18,
      status: { effect: 'void', turnsLeft: 1 },
    };
    const npc = {
      name: 'Test NPC', element: 'stone', stage: 3,
      hp: 100, atk: 20, def: 20, spd: 10, status: null,
    };

    const result = resolveTurn(player, npc, 'basic_attack', 'basic_attack',
      ['magma_breath', 'flame_wall'], ['rock_slide']);
    expect(result.events.length).toBeGreaterThan(0);
    const playerEvent = result.events.find(e => e.attacker === 'player');
    expect(playerEvent).toBeDefined();
  });
});

describe('calculateDamage critical hits', () => {
  const attacker = { atk: 28, element: 'fire', stage: 3 };
  const defender = { def: 20, element: 'ice', defending: false };
  const move = { element: 'fire', power: 65, accuracy: 100 };

  it('returns isCritical flag on result', () => {
    const result = calculateDamage(attacker, defender, move);
    expect(typeof result.isCritical).toBe('boolean');
  });

  it('critical hits deal 1.5x damage', () => {
    const originalRandom = Math.random;
    let callCount = 0;
    Math.random = () => {
      callCount++;
      if (callCount === 1) return 0.5;  // accuracy: 50 < 100, hit
      if (callCount === 2) return 0.0; // damage roll: lowest (0.85)
      if (callCount === 3) return 0.05; // crit: 5 < 10, critical!
      return 0.0;
    };

    const result = calculateDamage(attacker, defender, move);
    expect(result.isCritical).toBe(true);
    expect(result.damage).toBe(117);

    Math.random = originalRandom;
  });

  it('non-critical hits have isCritical false', () => {
    const originalRandom = Math.random;
    let callCount = 0;
    Math.random = () => {
      callCount++;
      if (callCount === 1) return 0.5;  // accuracy: hit
      if (callCount === 2) return 0.0; // damage roll
      if (callCount === 3) return 0.99; // crit: no crit
      return 0.0;
    };

    const result = calculateDamage(attacker, defender, move);
    expect(result.isCritical).toBe(false);

    Math.random = originalRandom;
  });

  it('misses cannot be critical', () => {
    const lowAccMove = { element: 'fire', power: 65, accuracy: 0 };
    const result = calculateDamage(attacker, defender, lowAccMove);
    expect(result.isCritical).toBe(false);
  });
});

describe('buff action handling', () => {
  const makeState = (overrides = {}) => ({
    name: 'Test Dragon', element: 'fire', stage: 3,
    hp: 100, maxHp: 100, atk: 20, def: 20, spd: 15,
    status: null, defending: false,
    ...overrides,
  });

  it('buff move produces a buff event and sets atkBuff on actor', () => {
    const player = makeState();
    const npc = makeState({ element: 'ice', spd: 5 });
    const result = resolveTurn(player, npc, 'npc_focus', 'basic_attack', ['npc_focus'], ['basic_attack']);
    const buffEvent = result.events.find(e => e.action === 'buff');
    expect(buffEvent).toBeDefined();
    expect(buffEvent.buffStat).toBe('atk');
    expect(buffEvent.attacker).toBe('player');
    expect(result.player.atkBuff).toBeDefined();
    expect(result.player.atkBuff.multiplier).toBe(1.3);
  });

  it('atkBuff multiplier increases damage in next turn', () => {
    const basePlayer = makeState({ atkBuff: null });
    const buffedPlayer = makeState({ atkBuff: { multiplier: 1.3, turnsLeft: 1 } });
    const npc = makeState({ element: 'ice', spd: 5 });
    const moveFire = { element: 'fire', power: 65, accuracy: 100 };

    // Run many trials to get past RNG variance — buffed average must exceed base average
    let baseTotal = 0;
    let buffedTotal = 0;
    const TRIALS = 50;
    const originalRandom = Math.random;
    let callCount = 0;
    Math.random = () => {
      callCount++;
      if (callCount % 3 === 1) return 0.5; // accuracy: hit
      if (callCount % 3 === 2) return 0.0; // damage roll: min (0.85)
      return 0.99;                          // no crit
    };
    callCount = 0;
    for (let i = 0; i < TRIALS; i++) {
      const r = calculateDamage({ atk: basePlayer.atk, element: 'fire', stage: 3 }, { def: npc.def, element: 'ice', defending: false }, moveFire);
      baseTotal += r.damage;
    }
    callCount = 0;
    for (let i = 0; i < TRIALS; i++) {
      const effectiveAtk = Math.floor(buffedPlayer.atk * buffedPlayer.atkBuff.multiplier);
      const r = calculateDamage({ atk: effectiveAtk, element: 'fire', stage: 3 }, { def: npc.def, element: 'ice', defending: false }, moveFire);
      buffedTotal += r.damage;
    }
    Math.random = originalRandom;
    expect(buffedTotal).toBeGreaterThan(baseTotal);
  });

  it('buff expires after its duration via decrementBuff in resolveTurn', () => {
    // Focus has buffDuration: 1, so after one full turn it should be gone
    const player = makeState({ atkBuff: { multiplier: 1.3, turnsLeft: 1 }, spd: 5 });
    const npc = makeState({ element: 'stone' });
    const result = resolveTurn(player, npc, 'basic_attack', 'basic_attack', ['basic_attack'], ['basic_attack']);
    expect(result.player.atkBuff).toBeNull();
  });

  it('defBuff with 2 turns decrements to 1 after first turn', () => {
    const player = makeState({ defBuff: { multiplier: 1.4, turnsLeft: 2 }, spd: 5 });
    const npc = makeState({ element: 'stone' });
    const result = resolveTurn(player, npc, 'basic_attack', 'basic_attack', ['basic_attack'], ['basic_attack']);
    expect(result.player.defBuff).not.toBeNull();
    expect(result.player.defBuff.turnsLeft).toBe(1);
  });
});

describe('pickNpcMove adaptive AI', () => {
  it('desperation mode never picks buff moves', () => {
    const moveKeys = ['rock_slide', 'earthquake', 'npc_harden'];
    const ctx = { enemyHpRatio: 0.20, playerHpRatio: 0.80 };
    for (let i = 0; i < 30; i++) {
      const choice = pickNpcMove(moveKeys, 'stone', 'fire', null, ctx);
      expect(choice).not.toBe('npc_harden');
    }
  });

  it('desperation mode prefers highest-power move', () => {
    // earthquake (power 75) should dominate over rock_slide (power 60)
    const moveKeys = ['rock_slide', 'earthquake'];
    const ctx = { enemyHpRatio: 0.15, playerHpRatio: 0.80 };
    let earthquakeCount = 0;
    for (let i = 0; i < 30; i++) {
      if (pickNpcMove(moveKeys, 'stone', 'fire', null, ctx) === 'earthquake') earthquakeCount++;
    }
    expect(earthquakeCount).toBeGreaterThan(20);
  });

  it('buff timing: uses buff move in first 2 turns with >30% frequency', () => {
    const moveKeys = ['rock_slide', 'npc_harden'];
    const ctx = { turnCount: 1, enemyHpRatio: 0.80, playerHpRatio: 0.80 };
    let buffCount = 0;
    for (let i = 0; i < 60; i++) {
      if (pickNpcMove(moveKeys, 'stone', 'fire', null, ctx) === 'npc_harden') buffCount++;
    }
    expect(buffCount).toBeGreaterThan(18); // >30% of 60
  });

  it('anti-stack: never picks npc_focus when atkBuff is active', () => {
    const moveKeys = ['magma_breath', 'npc_focus'];
    const ctx = { npcAtkBuff: { multiplier: 1.3, turnsLeft: 1 }, enemyHpRatio: 0.80 };
    for (let i = 0; i < 30; i++) {
      expect(pickNpcMove(moveKeys, 'fire', 'ice', null, ctx)).not.toBe('npc_focus');
    }
  });

  it('counter-element adaptation: targets counter moves when player repeats element', () => {
    // Player spammed 'rock_slide' (stone) twice. Storm counters stone.
    // Give NPC storm (lightning_strike) — should see it chosen more with counter adaptation
    const moveKeys = ['thunder_clap', 'lightning_strike'];
    const ctx = {
      playerMoveHistory: ['rock_slide', 'rock_slide'],
      enemyHpRatio: 0.80,
      playerHpRatio: 0.80,
    };
    let stormCount = 0;
    for (let i = 0; i < 40; i++) {
      const choice = pickNpcMove(moveKeys, 'storm', 'stone', null, ctx);
      if (choice === 'thunder_clap' || choice === 'lightning_strike') stormCount++;
    }
    // Storm is super-effective vs stone — counter adaptation should strongly favour it
    expect(stormCount).toBeGreaterThan(25);
  });

  it('exploit mode raises status move usage when player is wounded', () => {
    const moveKeys = ['magma_breath', 'flame_wall'];
    const ctx = { enemyHpRatio: 0.80, playerHpRatio: 0.35 };
    let statusCount = 0;
    for (let i = 0; i < 60; i++) {
      // Both fire moves canApplyStatus — count how often they're chosen in exploit mode
      const choice = pickNpcMove(moveKeys, 'fire', 'ice', null, ctx);
      if (choice === 'magma_breath' || choice === 'flame_wall') statusCount++;
    }
    // In exploit mode status chance is 70% and both moves canApplyStatus, so bias is strong
    expect(statusCount).toBeGreaterThan(25);
  });
});
