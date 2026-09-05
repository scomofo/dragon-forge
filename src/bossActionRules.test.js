import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resolveTurn } from './battleEngine';
import { createCorruptionState, getCorruptedMoveKey } from './bossMechanics';
import { dragons, moves } from './gameData';

const player = { name: 'Guardian', element: 'stone', stage: 3, hp: 200, maxHp: 200, atk: 15, def: 50, spd: 100, status: null };
const bomb = { name: 'Logic Bomb', element: 'fire', stage: 3, hp: 200, maxHp: 200, atk: 30, def: 20, spd: 24, status: null };
const attack = (result, side = 'npc') => result.events.find(event => event.attacker === side && event.action === 'attack');
function detonate(playerMove = 'basic_attack', playerPatch = {}, npcPatch = {}, options = { logicBombDetonation: true }) {
  return resolveTurn({ ...player, ...playerPatch }, { ...bomb, ...npcPatch }, playerMove, 'bomb_detonation',
    ['basic_attack'], ['magma_breath', 'flame_wall'], options);
}

beforeEach(() => vi.spyOn(Math, 'random').mockReturnValue(0.99));
afterEach(() => vi.restoreAllMocks());

describe('fuse detonation preserves tactical counters', () => {
  it('keeps Defend mitigation, including the guard of a slower incoming reserve', () => {
    const open = detonate();
    const guarded = detonate('defend');
    const reserve = detonate('defend', { spd: 1 }, {}, { logicBombDetonation: true, playerGuardOnEntry: true });
    expect(attack(open).hit).toBe(true);
    expect(attack(guarded).damage).toBeLessThan(attack(open).damage);
    expect(attack(reserve).damage).toBe(attack(guarded).damage);
    expect(moves.bomb_detonation.accuracy).toBe(85);
  });

  it('allows a faster finishing hit to prevent the bomb acting at all', () => {
    const result = detonate('basic_attack', { atk: 10000 }, { hp: 1 });
    expect(result.npc.hp).toBe(0);
    expect(attack(result)).toBeUndefined();
    expect(result.player.hp).toBe(player.hp);
  });

  it('allows reflection to send the guaranteed hit back and KO the bomb', () => {
    const result = detonate('null_reflect', {}, { hp: 1, status: { effect: 'shadow', turnsLeft: 2 } });
    expect(attack(result)).toMatchObject({ moveKey: 'bomb_detonation', hit: true, reflected: true });
    expect(result.npc.hp).toBe(0);
    expect(result.player.hp).toBe(player.hp);
  });

  it('does not make an early threshold signature accurate or immune to Freeze', () => {
    expect(attack(detonate('defend', {}, {}, {})).hit).toBe(false);
    const frozen = detonate('defend', {}, { status: { effect: 'ice', turnsLeft: 2 } }, {});
    expect(attack(frozen)).toBeUndefined();
    expect(frozen.events.some(event => event.attacker === 'npc' && event.action === 'statusSkip')).toBe(true);
  });

  it('does not give an ordinary NPC move immunity when the fuse option is present', () => {
    const result = resolveTurn(player, { ...bomb, status: { effect: 'ice', turnsLeft: 2 } }, 'defend', 'magma_breath',
      [], [], { logicBombDetonation: true });
    expect(attack(result)).toBeUndefined();
  });
});

describe('corrupted regular slots', () => {
  it('never selects Basic Attack, a missing move, a signature or a combo', () => {
    const corruption = createCorruptionState('light', ['restoration', 'basic_attack', 'missing', 'dual_test', 'radiant_beam']);
    expect(corruption).toEqual({ garbledDragonId: 'light', garbledMoveKey: 'radiant_beam', garbledTurnsLeft: 2 });
    expect(createCorruptionState('light', ['restoration', 'basic_attack'])).toEqual({ garbledDragonId: null, garbledMoveKey: null, garbledTurnsLeft: 0 });
  });

  it('cannot affect another dragon, even when the two kits share the same move', () => {
    const state = { bossPatternId: 'data_corruption', dragonId: 'fire', dragon: dragons.fire,
      bossState: { garbledDragonId: 'other', garbledMoveKey: 'magma_breath', garbledTurnsLeft: 2 } };
    expect(getCorruptedMoveKey(state)).toBeNull();
    expect(getCorruptedMoveKey({ ...state, bossState: { ...state.bossState, garbledDragonId: 'fire' } })).toBe('magma_breath');
  });

  it('does not report a use when a faster enemy KOs the selected dragon', () => {
    const result = resolveTurn({ ...player, hp: 1, spd: 1 }, { ...bomb, atk: 1000 }, 'rock_slide', 'flame_wall',
      ['rock_slide'], ['flame_wall'], { playerCorruptedMoveKey: 'rock_slide' });
    expect(result.player.hp).toBe(0);
    expect(attack(result, 'player')).toBeUndefined();
    expect(result.events.some(event => event.corruptedMoveKey)).toBe(false);
  });

  it('reports the consumed slot even when its Basic Attack is reflected', () => {
    const result = resolveTurn({ ...player, spd: 1 }, bomb, 'rock_slide', 'null_reflect',
      ['rock_slide'], ['null_reflect'], { playerCorruptedMoveKey: 'rock_slide' });
    expect(attack(result, 'player')).toMatchObject({ moveKey: 'basic_attack', corruptedMoveKey: 'rock_slide', reflected: true });
  });
});
