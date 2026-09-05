import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { resolveTurn } from './battleEngine';
import { moves, npcs } from './gameData';
import { SINGULARITY_BOSSES } from './singularityBosses';
import { advanceHydraHeads, resetsMemoryLeak, HYDRA_HEAD_COUNT, HYDRA_HP_FLOOR } from './bossMechanics';

const player = { name: 'Ice Dragon', element: 'ice', stage: 3, hp: 100, maxHp: 100, atk: 500, def: 50, spd: 200, status: null };
const fighter = npc => ({ ...npc.stats, name: npc.name, element: npc.element, stage: 3, maxHp: npc.stats.hp, status: null });
const playerHit = result => result.events.find(event => event.attacker === 'player' && event.action === 'attack');

beforeEach(() => vi.spyOn(Math, 'random').mockReturnValue(0.5));
afterEach(() => vi.restoreAllMocks());

describe('Hydra head lock', () => {
  it('lets one Ice dragon break all heads and defeat the real Storm Hydra', () => {
    let hydra = fighter(npcs.glitch_hydra);
    let heads = 0;
    for (let turn = 0; turn < HYDRA_HEAD_COUNT; turn++) {
      const result = resolveTurn(player, hydra, 'frost_bite', 'defend', ['frost_bite'], ['defend'], { hydraFloor: HYDRA_HP_FLOOR });
      heads = advanceHydraHeads(heads, playerHit(result));
      hydra = result.npc;
      expect(heads).toBe(turn + 1);
      expect(hydra.hp).toBe(Math.ceil(hydra.maxHp * HYDRA_HP_FLOOR));
    }
    const finisher = resolveTurn(player, hydra, 'frost_bite', 'defend', ['frost_bite'], ['defend'], { hydraFloor: heads < HYDRA_HEAD_COUNT ? HYDRA_HP_FLOOR : 0 });
    expect(finisher.npc.hp).toBe(0);
    expect(advanceHydraHeads(heads, playerHit(finisher))).toBe(HYDRA_HEAD_COUNT);
  });

  it('counts super-effective combo hits whose keys are outside the moves table', () => {
    const result = resolveTurn(player, fighter(npcs.glitch_hydra), 'dual_test', 'defend', [], ['defend'], {
      playerMoveOverride: { ...moves.frost_bite, name: 'Ice Combo' }, hydraFloor: HYDRA_HP_FLOOR,
    });
    expect(advanceHydraHeads(0, playerHit(result))).toBe(1);
  });

  it.each([
    { hit: false }, { effectiveness: 1 }, { effectiveness: 0.5 },
    { reflected: true }, { blocked: true }, { attacker: 'npc' }, { action: 'statusTick' },
  ])('does not break a head for an ineligible event: %j', change => {
    expect(advanceHydraHeads(1, { attacker: 'player', action: 'attack', hit: true, effectiveness: 2, ...change })).toBe(1);
  });
});

describe('Memory Leak reset', () => {
  it('clears on an actual resisted Ice hit against the shipped Ice boss', () => {
    const leak = SINGULARITY_BOSSES.find(boss => boss.id === 'memory_leak');
    const result = resolveTurn({ ...player, atk: 30 }, fighter(leak), 'frost_bite', 'defend', ['frost_bite'], ['defend']);
    expect(playerHit(result).effectiveness).toBe(0.5);
    expect(resetsMemoryLeak(playerHit(result))).toBe(true);
  });

  it('uses the resolved element for combo moves', () => {
    const leak = SINGULARITY_BOSSES.find(boss => boss.id === 'memory_leak');
    const result = resolveTurn(player, fighter(leak), 'dual_test', 'defend', [], ['defend'], {
      playerMoveOverride: { ...moves.frost_bite, name: 'Ice Combo' },
    });
    expect(resetsMemoryLeak(playerHit(result))).toBe(true);
  });

  it('does not treat a copied Fire advantage as Ice', () => {
    const leak = SINGULARITY_BOSSES.find(boss => boss.id === 'memory_leak');
    const result = resolveTurn(player, fighter(leak), 'recompile', 'defend', ['recompile'], ['defend']);
    expect(playerHit(result).element).toBe('fire');
    expect(resetsMemoryLeak(playerHit(result))).toBe(false);
  });

  it.each([
    { hit: false }, { element: 'fire' }, { reflected: true }, { blocked: true }, { attacker: 'npc' },
  ])('does not clear the leak for an ineligible event: %j', change => {
    expect(resetsMemoryLeak({ attacker: 'player', action: 'attack', element: 'ice', hit: true, ...change })).toBe(false);
  });
});
