import { describe, it, expect } from 'vitest';
import { swapActiveAndBench, faintSwap } from './benchLogic';

function makeState() {
  return {
    phase: 'ANIMATING',
    dragon: { id: 'fire', name: 'Magma' }, dragonId: 'fire',
    playerLevel: 10, playerXp: 5, playerStage: 2,
    playerStats: { hp: 100, atk: 30 }, playerHp: 60, playerMaxHp: 100,
    playerStatus: { effect: 'fire', turnsLeft: 2 },
    npcHp: 50, turnCount: 3,
    bench: {
      dragon: { id: 'ice', name: 'Frost' }, dragonId: 'ice',
      playerLevel: 8, playerXp: 0, playerStage: 1,
      playerStats: { hp: 90, atk: 25 }, playerHp: 90, playerMaxHp: 90,
      playerStatus: null,
    },
  };
}

describe('benchLogic.swapActiveAndBench', () => {
  it('trades active and reserve, each keeping its own HP/status', () => {
    const r = swapActiveAndBench(makeState());
    expect(r.dragonId).toBe('ice');
    expect(r.playerHp).toBe(90);
    expect(r.playerStatus).toBeNull();
    expect(r.bench.dragonId).toBe('fire');
    expect(r.bench.playerHp).toBe(60);
    expect(r.bench.playerStatus).toEqual({ effect: 'fire', turnsLeft: 2 });
    expect(r.npcHp).toBe(50); // enemy state untouched
  });

  it('clears defending/sprite transients on swap', () => {
    const r = swapActiveAndBench({ ...makeState(), playerDefending: true });
    expect(r.playerDefending).toBe(false);
    expect(r.playerSpriteClass).toBe('');
  });

  it('is a no-op with no reserve, or a fainted reserve', () => {
    const noBench = { ...makeState(), bench: null };
    expect(swapActiveAndBench(noBench)).toBe(noBench);
    const dead = makeState(); dead.bench.playerHp = 0;
    expect(swapActiveAndBench(dead)).toBe(dead);
  });

  it('does not mutate the input state', () => {
    const s = makeState();
    swapActiveAndBench(s);
    expect(s.dragonId).toBe('fire');
    expect(s.bench.dragonId).toBe('ice');
  });
});

describe('benchLogic.faintSwap', () => {
  it('brings the reserve in, clears the bench, advances the turn, returns control', () => {
    const r = faintSwap(makeState(), 'PLAYER_TURN');
    expect(r.dragonId).toBe('ice');
    expect(r.playerHp).toBe(90);
    expect(r.bench).toBeNull();
    expect(r.phase).toBe('PLAYER_TURN');
    expect(r.turnCount).toBe(4);
  });

  it('is a no-op without a living reserve', () => {
    const noBench = { ...makeState(), bench: null };
    expect(faintSwap(noBench, 'PLAYER_TURN')).toBe(noBench);
  });

  it('does not mutate the input state', () => {
    const s = makeState();
    faintSwap(s, 'PLAYER_TURN');
    expect(s.dragonId).toBe('fire');
    expect(s.bench.dragonId).toBe('ice');
  });
});
