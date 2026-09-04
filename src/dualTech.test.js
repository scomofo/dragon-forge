import { describe, it, expect, vi, afterEach } from 'vitest';
import { DUAL_TECHS, resolveDualTech, listDualTechPairings } from './gameData';
import { resolveTurn } from './battleEngine';

describe('dual tech resolution', () => {
  it('resolves the same pairing regardless of active/bench order', () => {
    expect(resolveDualTech('fire', 'ice')).toBe(DUAL_TECHS.fire_ice);
    expect(resolveDualTech('ice', 'fire')).toBe(DUAL_TECHS.fire_ice);
  });

  it('returns null for same-element and unpaired elements', () => {
    expect(resolveDualTech('fire', 'fire')).toBeNull();
    expect(resolveDualTech('fire', 'venom')).toBeNull();
    expect(resolveDualTech('fire', null)).toBeNull();
    expect(resolveDualTech(null, null)).toBeNull();
  });

  it('lists all six authored pairings', () => {
    expect(listDualTechPairings().length).toBe(6);
  });

  it('every pairing resolves to a real move with power and vfx', () => {
    for (const tech of Object.values(DUAL_TECHS)) {
      expect(tech.power).toBeGreaterThan(0);
      expect(tech.vfxKey).toBeTruthy();
      expect(tech.move1).toBeTruthy();
      expect(tech.move2).toBeTruthy();
    }
  });
});

describe('dual tech override in the engine', () => {
  const player = {
    name: 'Test', element: 'fire', stage: 1, hp: 100, maxHp: 100,
    atk: 200, def: 20, spd: 50, defending: false, status: null,
  };
  const dummy = {
    name: 'Dummy', element: 'venom', stage: 3, hp: 100, maxHp: 100,
    atk: 10, def: 20, spd: 10, defending: false, status: null,
  };

  it('playerMoveOverride drives the resolved event (power scales)', () => {
    // Steam Burst has accuracy 90, so stub the RNG to force a hit — otherwise
    // ~10% of runs miss (damage 0) and this flakes on CI.
    vi.spyOn(Math, 'random').mockReturnValue(0.5);
    try {
      const tech = DUAL_TECHS.fire_ice;
      const { events } = resolveTurn(player, dummy, 'dual_steam_burst', 'defend', ['dual_steam_burst'], ['defend'], {
        playerMoveOverride: tech,
      });
      const hit = events.find(e => e.attacker === 'player' && e.action === 'attack');
      expect(hit.moveName).toBe('Steam Burst');
      expect(hit.damage).toBeGreaterThan(0);
    } finally {
      vi.restoreAllMocks();
    }
  });
});
