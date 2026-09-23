// @ts-nocheck
import { describe, it, expect } from 'vitest';
import {
  getFusionElement,
  calculateFusionStats,
  getStabilityTier,
  getFusionOffspringLevel,
  executeFusion,
  getFusionPreview,
  getDiscoveredRecipeKeys,
  getAlchemyGrid,
} from './fusionEngine';
import { calculateStatsForLevel } from './battleEngine';

describe('getFusionElement', () => {
  it('returns same element for same-element fusion', () => {
    expect(getFusionElement('fire', 'fire')).toBe('fire');
    expect(getFusionElement('shadow', 'shadow')).toBe('shadow');
  });

  it('returns storm for fire+ice', () => {
    expect(getFusionElement('fire', 'ice')).toBe('storm');
    expect(getFusionElement('ice', 'fire')).toBe('storm');
  });

  it('returns shadow for fire+venom', () => {
    expect(getFusionElement('fire', 'venom')).toBe('shadow');
    expect(getFusionElement('venom', 'fire')).toBe('shadow');
  });

  it('is commutative', () => {
    expect(getFusionElement('ice', 'storm')).toBe(getFusionElement('storm', 'ice'));
    expect(getFusionElement('stone', 'shadow')).toBe(getFusionElement('shadow', 'stone'));
  });

  it('forges Synthesis from Void and Light', () => {
    expect(getFusionElement('void', 'light')).toBe('synthesis');
    expect(getFusionElement('light', 'void')).toBe('synthesis');
  });
});

describe('getStabilityTier', () => {
  it('returns stable for same element', () => {
    expect(getStabilityTier('fire', 'fire')).toBe('stable');
  });

  it('returns unstable for opposing elements', () => {
    expect(getStabilityTier('fire', 'ice')).toBe('unstable');
    expect(getStabilityTier('storm', 'stone')).toBe('unstable');
    expect(getStabilityTier('venom', 'shadow')).toBe('unstable');
  });

  it('returns normal for neutral combos', () => {
    expect(getStabilityTier('fire', 'storm')).toBe('normal');
    expect(getStabilityTier('ice', 'venom')).toBe('normal');
  });

  it('stability boost promotes one tier', () => {
    expect(getStabilityTier('fire', 'storm', true)).toBe('stable');
    expect(getStabilityTier('fire', 'ice', true)).toBe('normal');
    expect(getStabilityTier('fire', 'fire', true)).toBe('stable');
  });
});

describe('calculateFusionStats', () => {
  const parentA = { hp: 100, atk: 30, def: 20, spd: 20 };
  const parentB = { hp: 80, atk: 20, def: 30, spd: 10 };

  it('averages stats with 10% fusion bonus', () => {
    const result = calculateFusionStats(parentA, parentB, 'normal');
    expect(result).toEqual({ hp: 99, atk: 27, def: 27, spd: 16 });
  });

  it('applies 25% bonus for stable fusion', () => {
    const result = calculateFusionStats(parentA, parentB, 'stable');
    expect(result).toEqual({ hp: 123, atk: 33, def: 33, spd: 20 });
  });

  it('applies unstable modifiers — HP*0.8, ATK*1.1', () => {
    const result = calculateFusionStats(parentA, parentB, 'unstable');
    expect(result).toEqual({ hp: 79, atk: 29, def: 27, spd: 16 });
  });
});

describe('executeFusion', () => {
  it('produces offspring with correct element and stats', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 110, atk: 28, def: 20, spd: 18 }, level: 12, shiny: false };
    const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 24, def: 26, spd: 20 }, level: 10, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.element).toBe('storm');
    expect(result.stabilityTier).toBe('unstable');
    expect(result.fusedBaseStats).toHaveProperty('hp');
    // offspring level = max(10, min(50, round((12 + 10) / 2 * 0.85))) = max(10, round(9.35)) = 10
    expect(result.level).toBe(10);
    expect(result.shiny).toBe(false);
  });

  it('inherits shiny from either parent', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: true };
    const parentB = { id: 'storm', element: 'storm', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.shiny).toBe(true);
  });

  it('offspring keeps 85% of the parents average level', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 30, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 200, atk: 50, def: 40, spd: 40 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    // max(10, min(50, round(27.5 * 0.85))) = round(23.375) = 23
    expect(result.level).toBe(23);
  });

  it('scales offspring level smoothly with parent levels (no L50 cliff)', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 24, shiny: false };
    const parentB = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 25, shiny: false };
    const result = executeFusion(parentA, parentB);
    // max(10, min(50, round(24.5 * 0.85))) = round(20.825) = 21
    expect(result.level).toBe(21);
  });

  it('never regresses high-investment parents to a low-level child', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 50, shiny: false };
    const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 50, shiny: false };
    const result = executeFusion(parentA, parentB);
    // round(50 * 0.85) = 43 — not the old cap-30 cliff
    expect(result.level).toBe(43);
  });
});

describe('getFusionOffspringLevel', () => {
  it('floors at 10 so the child is always re-fusable', () => {
    expect(getFusionOffspringLevel(10, 10)).toBe(10);
    expect(getFusionOffspringLevel(1, 1)).toBe(10);
  });

  it('keeps 85% of the average, rounded', () => {
    expect(getFusionOffspringLevel(30, 25)).toBe(23);
    expect(getFusionOffspringLevel(50, 50)).toBe(43);
  });

  it('caps at the level cap', () => {
    expect(getFusionOffspringLevel(50, 50)).toBeLessThanOrEqual(50);
  });

  it('applies the stability boost to the fusion result', () => {
    const parentA = { id: 'fire', element: 'fire', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    const parentB = { id: 'storm', element: 'storm', stats: { hp: 100, atk: 20, def: 20, spd: 20 }, level: 12, shiny: false };
    expect(executeFusion(parentA, parentB).stabilityTier).toBe('normal');
    expect(executeFusion(parentA, parentB, { stabilityBoost: true }).stabilityTier).toBe('stable');
  });

  it('forges Synthesis from Void and Light parents', () => {
    const parentA = { id: 'void', element: 'void', stats: { hp: 88, atk: 34, def: 16, spd: 30 }, level: 20, shiny: false };
    const parentB = { id: 'light', element: 'light', stats: { hp: 100, atk: 26, def: 22, spd: 22 }, level: 20, shiny: false };
    const result = executeFusion(parentA, parentB);
    expect(result.element).toBe('synthesis');
    expect(result.parentAId).toBe('void');
    expect(result.parentBId).toBe('light');
  });
});

describe('getFusionPreview', () => {
  const parentA = { id: 'fire', element: 'fire', stats: { hp: 110, atk: 28, def: 20, spd: 18 }, level: 12, shiny: false };
  const parentB = { id: 'ice', element: 'ice', stats: { hp: 100, atk: 24, def: 26, spd: 20 }, level: 10, shiny: false };

  it('resolves the exact offspring element, stability, and level', () => {
    const preview = getFusionPreview(parentA, parentB);
    expect(preview.element).toBe('storm');
    expect(preview.stability).toBe('unstable');
    // max(10, min(50, round(11 * 0.85))) = max(10, 9) = 10
    expect(preview.level).toBe(10);
    expect(preview.shiny).toBe(false);
    expect(preview.deterministic).toBe(true);
  });

  it('computes offspring current stats from fused base stats at the offspring level', () => {
    const preview = getFusionPreview(parentA, parentB);
    expect(preview.fusedBaseStats).toEqual({ hp: 92, atk: 30, def: 25, spd: 20 });
    expect(preview.offspringStats).toEqual(calculateStatsForLevel(preview.fusedBaseStats, preview.level, false));
    expect(preview.offspringStats).toEqual({ hp: 151, atk: 49, def: 41, spd: 32 });
  });

  it('reports stat deltas vs EACH parent', () => {
    const preview = getFusionPreview(parentA, parentB);
    expect(preview.deltas.parentA).toEqual({ hp: 41, atk: 21, def: 21, spd: 14 });
    expect(preview.deltas.parentB).toEqual({ hp: 51, atk: 25, def: 15, spd: 12 });
  });

  it('can report negative deltas (losses vs a strong parent)', () => {
    // A Lv.50 parent fused with a Lv.10 parent: the Lv.26 offspring trails the
    // maxed parent's HP, so deltas must be able to go negative.
    const maxA = { id: 'fire', element: 'fire', stats: calculateStatsForLevel({ hp: 110, atk: 28, def: 20, spd: 18 }, 50, false), level: 50, shiny: false };
    const lowB = { id: 'ice', element: 'ice', stats: calculateStatsForLevel({ hp: 100, atk: 24, def: 26, spd: 20 }, 10, false), level: 10, shiny: false };
    const preview = getFusionPreview(maxA, lowB);
    expect(preview.level).toBe(26);
    expect(preview.offspringStats).toEqual({ hp: 447, atk: 152, def: 111, spd: 95 });
    expect(preview.deltas.parentA).toEqual({ hp: -30, atk: 31, def: 25, spd: 17 });
    expect(preview.deltas.parentB).toEqual({ hp: 284, atk: 113, def: 69, spd: 63 });
  });

  it('inherits shiny from either parent and applies it to offspring stats', () => {
    const shinyA = { ...parentA, shiny: true };
    const preview = getFusionPreview(shinyA, parentB);
    expect(preview.shiny).toBe(true);
    expect(preview.offspringStats).toEqual(calculateStatsForLevel(preview.fusedBaseStats, preview.level, true));
  });

  it('is order-independent (deltas swap, everything else identical)', () => {
    const ab = getFusionPreview(parentA, parentB);
    const ba = getFusionPreview(parentB, parentA);
    expect(ba.element).toBe(ab.element);
    expect(ba.stability).toBe(ab.stability);
    expect(ba.level).toBe(ab.level);
    expect(ba.offspringStats).toEqual(ab.offspringStats);
    expect(ba.deltas.parentA).toEqual(ab.deltas.parentB);
    expect(ba.deltas.parentB).toEqual(ab.deltas.parentA);
  });

  it('applies the stability boost to the preview tier', () => {
    expect(getFusionPreview(parentA, parentB).stability).toBe('unstable');
    expect(getFusionPreview(parentA, parentB, { stabilityBoost: true }).stability).toBe('normal');
  });
});

describe('getDiscoveredRecipeKeys', () => {
  it('keys recipes by the sorted parent pair, order-independent', () => {
    const lineage = [
      { parentA: 'fire', parentB: 'ice', offspring: 'storm', offspringLevel: 10 },
      { parentA: 'ice', parentB: 'fire', offspring: 'storm', offspringLevel: 10 },
    ];
    const keys = getDiscoveredRecipeKeys(lineage);
    expect(keys.size).toBe(1);
    expect(keys.has('fire_ice')).toBe(true);
  });

  it('ignores malformed lineage entries', () => {
    expect(getDiscoveredRecipeKeys([null, {}, { parentA: 'fire' }]).size).toBe(0);
    expect(getDiscoveredRecipeKeys(undefined).size).toBe(0);
  });
});

describe('getAlchemyGrid', () => {
  it('covers every ALCHEMY recipe exactly once (dedupes light_void/void_light)', () => {
    const grid = getAlchemyGrid([]);
    expect(grid.length).toBe(22);
    expect(new Set(grid.map((r) => r.key)).size).toBe(22);
    expect(grid.every((r) => r.discovered === false)).toBe(true);
  });

  it('marks recipes discovered by lineage entries, order-independent', () => {
    const lineage = [{ parentA: 'ice', parentB: 'fire', offspring: 'storm', offspringLevel: 10 }];
    const grid = getAlchemyGrid(lineage);
    const fireIce = grid.find((r) => r.key === 'fire_ice');
    expect(fireIce.discovered).toBe(true);
    expect(fireIce.offspring).toBe('storm');
    expect(fireIce.parents).toEqual(['fire', 'ice']);
    const fireStorm = grid.find((r) => r.key === 'fire_storm');
    expect(fireStorm.discovered).toBe(false);
  });

  it('counts the synthesis recipe from a void+light fusion', () => {
    const lineage = [{ parentA: 'void', parentB: 'light', offspring: 'synthesis', offspringLevel: 17 }];
    const grid = getAlchemyGrid(lineage);
    const synthesis = grid.find((r) => r.offspring === 'synthesis');
    expect(synthesis.discovered).toBe(true);
    expect(synthesis.key).toBe('light_void');
  });
});
