import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resolveTurn } from './battleEngine';

const fighter = {
  name: 'Dragon', element: 'neutral', stage: 3,
  hp: 200, maxHp: 200, atk: 30, def: 0, spd: 10,
};

beforeEach(() => vi.spyOn(Math, 'random').mockReturnValue(0.2));
afterEach(() => vi.restoreAllMocks());

describe('battle entry turn resolution', () => {
  it('guards a slower incoming dragon before the faster enemy attacks', () => {
    const incoming = { ...fighter, spd: 1 };
    const normal = resolveTurn(incoming, fighter, 'defend', 'basic_attack');
    const entry = resolveTurn(incoming, fighter, 'defend', 'basic_attack', [], [], {
      playerGuardOnEntry: true,
    });

    expect(normal.events[0]).toMatchObject({ attacker: 'npc', damage: 32 });
    expect(entry.events[0]).toMatchObject({ attacker: 'npc', damage: 16 });
    expect(entry.player.hp).toBe(184);
  });

  it('resolves one opener and one normal enemy action, with one status and buff tick', () => {
    const incoming = {
      ...fighter, spd: 1,
      atkBuff: { multiplier: 1.2, turnsLeft: 3 },
      defBuff: { multiplier: 1.4, turnsLeft: 3 },
    };
    const enemy = {
      ...fighter, status: { effect: 'venom', turnsLeft: 2 },
      atkBuff: { multiplier: 1.2, turnsLeft: 3 },
    };
    const result = resolveTurn(incoming, enemy, 'defend', 'basic_attack', [], [], {
      playerGuardOnEntry: true, npcOpeningMoveKey: 'toxic_cloud',
    });
    const attacks = result.events.filter(event => event.attacker === 'npc' && event.action === 'attack');

    expect(attacks.map(event => event.moveKey)).toEqual(['toxic_cloud', 'basic_attack']);
    expect(result.events.filter(event => event.attacker === 'status')).toEqual([
      expect.objectContaining({ target: 'player', effectName: 'Poison', damage: 24 }),
      expect.objectContaining({ target: 'npc', effectName: 'Poison', damage: 24 }),
    ]);
    expect(result.player.hp).toBe(200 - attacks[0].damage - attacks[1].damage - 24);
    expect(result.player.status).toEqual({ effect: 'venom', turnsLeft: 1 });
    expect(result.npc.status).toEqual({ effect: 'venom', turnsLeft: 1 });
    expect(result.player.atkBuff.turnsLeft).toBe(2);
    expect(result.player.defBuff.turnsLeft).toBe(2);
    expect(result.npc.atkBuff.turnsLeft).toBe(2);
  });

  it('does not apply the ordinary charged move bonus to the opening attack', () => {
    const options = { playerGuardOnEntry: true, npcOpeningMoveKey: 'basic_attack' };
    const normal = resolveTurn(fighter, fighter, 'defend', 'basic_attack', [], [], options);
    const charged = resolveTurn(fighter, { ...fighter, chargeMultiplier: 1.4 }, 'defend', 'basic_attack', [], [], options);
    const attacks = result => result.events.filter(event => event.action === 'attack');

    expect(attacks(charged)[0].damage).toBe(attacks(normal)[0].damage);
    expect(attacks(charged)[1].damage).toBeGreaterThan(attacks(normal)[1].damage);
  });

  it('ends actions after a lethal opener without letting the incoming dragon defend or heal', () => {
    const result = resolveTurn({ ...fighter, hp: 1, spd: 30 }, fighter, 'restoration', 'basic_attack', [], [], {
      npcOpeningMoveKey: 'basic_attack', playerGuardOnEntry: true,
    });

    expect(result.player.hp).toBe(0);
    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({ attacker: 'npc', moveKey: 'basic_attack' });
  });

  it.each([
    ['absolute_zero', 'Freeze', null],
    ['overclock', 'Paralyze', { effect: 'storm', turnsLeft: 1 }],
  ])('carries an opening %s ailment into the faster player action', (opener, statusName, finalStatus) => {
    const result = resolveTurn({ ...fighter, spd: 30 }, fighter, 'basic_attack', 'defend', [], [], {
      npcOpeningMoveKey: opener,
    });

    expect(result.events[0]).toMatchObject({ attacker: 'npc', moveKey: opener, appliedStatus: statusName });
    expect(result.events[1]).toEqual({ attacker: 'player', action: 'statusSkip', statusName });
    expect(result.events.filter(event => event.action === 'attack')).toHaveLength(1);
    expect(result.player.status).toEqual(finalStatus);
  });

  it('stops ordinary actions when the first attack reflects and KOs its source', () => {
    const result = resolveTurn({ ...fighter, hp: 1, spd: 30 }, { ...fighter, reflecting: true }, 'basic_attack', 'basic_attack');

    expect(result.player.hp).toBe(0);
    expect(result.npc.hp).toBe(200);
    expect(result.events).toHaveLength(1);
    expect(result.events[0]).toMatchObject({ attacker: 'player', reflected: true });
  });

  it('does not allow an already fainted fighter to execute a turn', () => {
    const result = resolveTurn({ ...fighter, hp: 0 }, fighter, 'restoration', 'basic_attack');

    expect(result.player.hp).toBe(0);
    expect(result.events).toEqual([]);
  });

  it.each([199, 200])('reports only actual capped lifesteal restored from %s HP', hp => {
    const result = resolveTurn({ ...fighter, hp, spd: 30 }, fighter, 'siphon_rift', 'defend');
    const attack = result.events.find(event => event.attacker === 'player' && event.action === 'attack');

    expect(result.player.hp).toBe(200);
    expect(attack.lifesteal ?? 0).toBe(200 - hp);
  });

  it.each([1, 30])('discards a move override when Glitch replaces the chosen move at speed %s', spd => {
    const result = resolveTurn(
      { ...fighter, hp: 100, spd, status: { effect: 'void', turnsLeft: 1 } },
      fighter, 'dual_tech', 'defend', ['basic_attack'], [],
      { playerMoveOverride: { name: 'Combo Heal', actionType: 'heal', healPercent: 0.5 } },
    );

    expect(result.events.find(event => event.attacker === 'player')).toMatchObject({
      action: 'attack', moveKey: 'basic_attack', moveName: 'Basic Attack',
    });
    expect(result.player.hp).toBe(100);
  });
});
