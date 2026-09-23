import { describe, expect, it } from 'vitest';
import { WORLD_ZONE_IDS } from './worldZones';
import { getDailySeed } from './dailyChallenge';
import {
  FEATURED_ZONE_SCRAP_MULTIPLIER,
  applyFeaturedMultiplier,
  getFeaturedZone,
  getFeaturedZoneSeed,
  isFeaturedZone,
} from './featuredZone';
import { applyOuterGridAction, OUTER_GRID_CACHE_REWARD, OUTER_GRID_CLEAR_REWARD } from './outerGrid';
import { applyFrozenCacheAction, FROZEN_CACHE_VAULT_REWARD, FROZEN_CACHE_CLEAR_REWARD } from './frozenCache';
import { applyStormSpineAction, STORM_SPINE_CACHE_REWARD, STORM_SPINE_CLEAR_REWARD } from './stormSpine';
import { applyAdminCoreAction, ADMIN_CORE_CACHE_REWARD, ADMIN_CORE_CLEAR_REWARD } from './adminCore';

// Seeds verified against the module's mixed PRNG — each zone's featured day
// and a day it is NOT featured.
const SEEDS = {
  outer_grid: { featured: 20240107, unfeatured: 20240101 },
  frozen_cache: { featured: 20240101, unfeatured: 20240102 },
  storm_spine: { featured: 20240102, unfeatured: 20240101 },
  admin_core: { featured: 20240103, unfeatured: 20240101 },
};

function dateSeedFor(year, month, day) {
  return year * 10000 + month * 100 + day;
}

describe('featured zone rotation', () => {
  it('reuses the daily seed', () => {
    expect(getFeaturedZoneSeed()).toBe(getDailySeed());
  });

  it('is deterministic per seed', () => {
    for (const seed of [20240101, 20240102, 20260923, 20300101]) {
      expect(getFeaturedZone(seed)).toBe(getFeaturedZone(seed));
      expect(WORLD_ZONE_IDS).toContain(getFeaturedZone(seed));
    }
  });

  it('rotates day to day instead of pinning', () => {
    // Without seed mixing the raw LCG pins one zone for months at a time
    // (2 day-boundary changes in all of 2026). The rotation must turn over.
    const zones = [];
    for (let day = 1; day <= 365; day += 1) {
      const d = new Date(2026, 0, day);
      zones.push(getFeaturedZone(dateSeedFor(d.getFullYear(), d.getMonth() + 1, d.getDate())));
    }
    const changes = zones.slice(1).filter((z, i) => z !== zones[i]).length;
    expect(changes).toBeGreaterThan(100);
  });

  it('reaches all four zones', () => {
    const seen = new Set();
    for (let y = 2024; y <= 2032; y += 1) {
      for (let m = 1; m <= 12; m += 1) {
        for (let day = 1; day <= 28; day += 1) {
          seen.add(getFeaturedZone(dateSeedFor(y, m, day)));
        }
      }
    }
    expect([...seen].sort()).toEqual([...WORLD_ZONE_IDS].sort());
  });

  it('isFeaturedZone agrees with getFeaturedZone', () => {
    for (const seed of [20240101, 20260521, 20260923]) {
      const zone = getFeaturedZone(seed);
      for (const id of WORLD_ZONE_IDS) {
        expect(isFeaturedZone(id, seed)).toBe(id === zone);
      }
    }
  });

  it('doubles scraps only on the featured zone', () => {
    expect(FEATURED_ZONE_SCRAP_MULTIPLIER).toBe(2);
    expect(applyFeaturedMultiplier('outer_grid', 15, SEEDS.outer_grid.featured)).toBe(30);
    expect(applyFeaturedMultiplier('outer_grid', 15, SEEDS.outer_grid.unfeatured)).toBe(15);
    expect(applyFeaturedMultiplier('frozen_cache', 20, SEEDS.frozen_cache.featured)).toBe(40);
    expect(applyFeaturedMultiplier('frozen_cache', 20, SEEDS.frozen_cache.unfeatured)).toBe(20);
    expect(applyFeaturedMultiplier('storm_spine', 25, SEEDS.storm_spine.featured)).toBe(50);
    expect(applyFeaturedMultiplier('storm_spine', 25, SEEDS.storm_spine.unfeatured)).toBe(25);
    expect(applyFeaturedMultiplier('admin_core', 35, SEEDS.admin_core.featured)).toBe(70);
    expect(applyFeaturedMultiplier('admin_core', 35, SEEDS.admin_core.unfeatured)).toBe(35);
    // Zero rewards stay zero — the multiplier never pays for nothing.
    expect(applyFeaturedMultiplier('outer_grid', 0, SEEDS.outer_grid.featured)).toBe(0);
  });
});

function baseSave() {
  return {
    dragons: { fire: { owned: true, level: 5 } },
    defeatedNpcs: [
      'firewall_sentinel', 'buffer_overflow', 'bit_wraith', 'phishing_siren',
      'crypto_crab', 'glitch_hydra', 'logic_bomb', 'recursive_golem', 'protocol_vulture',
    ],
    dataScraps: 100,
    stats: { totalScrapsEarned: 0 },
  };
}

describe('featured zone reward doubling in the engines', () => {
  it('doubles Outer Grid cache + clear when featured', () => {
    const { featured, unfeatured } = SEEDS.outer_grid;
    const cache = { ...baseSave(), outerGrid: { roomId: 'maintenance-cache', spanRoute: 'crawlway' } };
    expect(applyOuterGridAction(cache, 'claim-cache', null, { seed: featured }).dataScraps)
      .toBe(100 + OUTER_GRID_CACHE_REWARD * 2);
    expect(applyOuterGridAction(cache, 'claim-cache', null, { seed: featured }).stats.totalScrapsEarned)
      .toBe(OUTER_GRID_CACHE_REWARD * 2);
    expect(applyOuterGridAction(cache, 'claim-cache', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + OUTER_GRID_CACHE_REWARD);

    const clear = { ...baseSave(), outerGrid: { roomId: 'return-gate', spanRoute: 'crawlway' } };
    expect(applyOuterGridAction(clear, 'claim-clear', null, { seed: featured }).dataScraps)
      .toBe(100 + OUTER_GRID_CLEAR_REWARD * 2);
    expect(applyOuterGridAction(clear, 'claim-clear', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + OUTER_GRID_CLEAR_REWARD);
  });

  it('doubles Frozen Cache vault + clear when featured', () => {
    const { featured, unfeatured } = SEEDS.frozen_cache;
    const vault = { ...baseSave(), frozenCache: { roomId: 'frozen-vault', junctionRoute: 'crack' } };
    expect(applyFrozenCacheAction(vault, 'claim-vault', null, { seed: featured }).dataScraps)
      .toBe(100 + FROZEN_CACHE_VAULT_REWARD * 2);
    expect(applyFrozenCacheAction(vault, 'claim-vault', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + FROZEN_CACHE_VAULT_REWARD);

    const clear = { ...baseSave(), frozenCache: { roomId: 'thaw-gate', junctionRoute: 'crack' } };
    expect(applyFrozenCacheAction(clear, 'claim-clear', null, { seed: featured }).dataScraps)
      .toBe(100 + FROZEN_CACHE_CLEAR_REWARD * 2);
    expect(applyFrozenCacheAction(clear, 'claim-clear', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + FROZEN_CACHE_CLEAR_REWARD);
  });

  it('doubles Storm Spine cache + clear when featured', () => {
    const { featured, unfeatured } = SEEDS.storm_spine;
    const cache = { ...baseSave(), stormSpine: { roomId: 'capacitor-bank', forkLane: 'capacitor' } };
    expect(applyStormSpineAction(cache, 'claim-cache', null, { seed: featured }).dataScraps)
      .toBe(100 + STORM_SPINE_CACHE_REWARD * 2);
    expect(applyStormSpineAction(cache, 'claim-cache', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + STORM_SPINE_CACHE_REWARD);

    const clear = { ...baseSave(), stormSpine: { roomId: 'discharge-gate', forkLane: 'capacitor' } };
    expect(applyStormSpineAction(clear, 'claim-clear', null, { seed: featured }).dataScraps)
      .toBe(100 + STORM_SPINE_CLEAR_REWARD * 2);
    expect(applyStormSpineAction(clear, 'claim-clear', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + STORM_SPINE_CLEAR_REWARD);
  });

  it('doubles Admin Core cache + clear when featured', () => {
    const { featured, unfeatured } = SEEDS.admin_core;
    const cache = { ...baseSave(), adminCore: { roomId: 'reliquary-vault', lantern: 'hoarding' } };
    expect(applyAdminCoreAction(cache, 'claim-cache', null, { seed: featured }).dataScraps)
      .toBe(100 + ADMIN_CORE_CACHE_REWARD * 2);
    expect(applyAdminCoreAction(cache, 'claim-cache', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + ADMIN_CORE_CACHE_REWARD);

    const clear = { ...baseSave(), adminCore: { roomId: 'reset-threshold', lantern: 'hoarding' } };
    expect(applyAdminCoreAction(clear, 'claim-clear', null, { seed: featured }).dataScraps)
      .toBe(100 + ADMIN_CORE_CLEAR_REWARD * 2);
    expect(applyAdminCoreAction(clear, 'claim-clear', null, { seed: unfeatured }).dataScraps)
      .toBe(100 + ADMIN_CORE_CLEAR_REWARD);
  });

  it('defaults to today\'s seed when no seed is passed', () => {
    const save = { ...baseSave(), outerGrid: { roomId: 'maintenance-cache', spanRoute: 'crawlway' } };
    const next = applyOuterGridAction(save, 'claim-cache', null);
    const expected = OUTER_GRID_CACHE_REWARD * (isFeaturedZone('outer_grid') ? 2 : 1);
    expect(next.dataScraps).toBe(100 + expected);
  });
});
