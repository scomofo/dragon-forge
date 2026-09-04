import { describe, it, expect } from 'vitest';
import { FORGE_RECIPES, canForge } from './shopItems';

const voidEgg = FORGE_RECIPES.find(r => r.id === 'void_egg');

function saveWith(cores, scraps = 1000) {
  return { dataScraps: scraps, inventory: { cores } };
}

describe('void egg recipe (deterministic Void chase)', () => {
  it('exists and promises a guaranteed hatch', () => {
    expect(voidEgg).toBeTruthy();
    expect(voidEgg.effect).toBe('voidEgg');
    expect(voidEgg.description).toMatch(/GUARANTEED/i);
  });

  it('requires 5 of every element core', () => {
    const fiveEach = { fire: 5, ice: 5, storm: 5, stone: 5, venom: 5, shadow: 5 };
    expect(canForge(voidEgg, saveWith(fiveEach))).toBe(true);
    expect(canForge(voidEgg, saveWith({ ...fiveEach, shadow: 4 }))).toBe(false);
    expect(canForge(voidEgg, saveWith({ fire: 99 }))).toBe(false);
  });

  it('requires the scrap cost on top of cores', () => {
    const fiveEach = { fire: 5, ice: 5, storm: 5, stone: 5, venom: 5, shadow: 5 };
    expect(canForge(voidEgg, saveWith(fiveEach, 799))).toBe(false);
    expect(canForge(voidEgg, saveWith(fiveEach, 800))).toBe(true);
  });
});
