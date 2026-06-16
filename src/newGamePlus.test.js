import { describe, it, expect } from 'vitest';
import { applyNewGamePlus } from './persistence';

function beatenSave() {
  return {
    dragons: {
      fire: { level: 50, xp: 0, owned: true, shiny: true },
      ice: { level: 40, xp: 10, owned: true, shiny: false },
    },
    dataScraps: 9999,
    inventory: { cores: { fire: 20 }, xpBoostBattles: 0, stabilityBoost: false },
    milestones: ['first_discovery', 'singularity_contained'],
    records: { longestStreak: 7 },
    stats: { battlesWon: 50 },
    skye: { wrenchTier: 3, relicsOwned: ['iron_knuckle'] },
    ngPlus: 0,
    defeatedNpcs: ['firewall_sentinel', 'protocol_vulture'],
    singularityProgress: { defeated: ['the_singularity'], finalBossPhase: 2, replayCounts: { mirror_admin: 1 } },
    singularityComplete: true,
    mirrorAdminDefeated: true,
    remnantDefeated: ['data_corruption_remnant'],
    flags: { currentAct: 3, metFelix: true, fragmentsUnlocked: ['001', '002', '007'] },
  };
}

describe('New Game+ reset (applyNewGamePlus)', () => {
  it('increments ngPlus and re-locks the campaign + Singularity', () => {
    const s = applyNewGamePlus(beatenSave());
    expect(s.ngPlus).toBe(1);
    expect(s.defeatedNpcs).toEqual([]);
    expect(s.singularityComplete).toBe(false);
    expect(s.mirrorAdminDefeated).toBe(false);
    expect(s.remnantDefeated).toEqual([]);
    expect(s.singularityProgress).toEqual({ defeated: [], finalBossPhase: 0, replayCounts: {} });
    expect(s.flags.currentAct).toBe(1);
    expect(s.flags.fragmentsUnlocked).toEqual([]);
  });

  it('KEEPS the collection — dragons, scraps, cores, milestones, records, stats, skye', () => {
    const s = applyNewGamePlus(beatenSave());
    expect(s.dragons.fire).toEqual({ level: 50, xp: 0, owned: true, shiny: true });
    expect(s.dragons.ice.owned).toBe(true);
    expect(s.dataScraps).toBe(9999);
    expect(s.inventory.cores.fire).toBe(20);
    expect(s.milestones).toContain('singularity_contained');
    expect(s.records.longestStreak).toBe(7);
    expect(s.stats.battlesWon).toBe(50);
    expect(s.skye.wrenchTier).toBe(3);
  });

  it('preserves non-campaign flags (metFelix) while resetting act/fragments', () => {
    const s = applyNewGamePlus(beatenSave());
    expect(s.flags.metFelix).toBe(true);
  });

  it('stacks across multiple New Game+ runs', () => {
    let s = applyNewGamePlus(beatenSave());
    s.mirrorAdminDefeated = true; // they beat it again
    s = applyNewGamePlus(s);
    expect(s.ngPlus).toBe(2);
  });
});
