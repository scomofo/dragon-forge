import { describe, it, expect } from 'vitest';
import {
  loadSave,
  applyNewGamePlus,
  applyNgPlusLoreDepth,
  isNgPlusRunActive,
} from './persistence';
import { checkMilestones } from './journalMilestones';
import { CORRUPTION_REMNANTS } from './singularityBosses';

const REMNANT_IDS = CORRUPTION_REMNANTS.map((r) => r.id);

// Minimal NG+-run save: ngPlus >= 1 means an NG+ run is active.
function ngSave(overrides = {}) {
  return {
    ngPlus: 1,
    ngPlusLoreDepth: 0,
    ngPlusRemnantClears: [],
    singularityProgress: { defeated: [], finalBossPhase: 0, replayCounts: {} },
    singularityComplete: false,
    mirrorAdminDefeated: false,
    remnantDefeated: [],
    milestones: [],
    ...overrides,
  };
}

function milestoneSave(overrides = {}) {
  return { dragons: {}, milestones: [], ...overrides };
}

function getMilestone(results, id) {
  return results.find((m) => m.id === id);
}

describe('isNgPlusRunActive', () => {
  it('is true exactly when save.ngPlus >= 1', () => {
    expect(isNgPlusRunActive({ ngPlus: 0 })).toBe(false);
    expect(isNgPlusRunActive({ ngPlus: 1 })).toBe(true);
    expect(isNgPlusRunActive({ ngPlus: 3 })).toBe(true);
    expect(isNgPlusRunActive({})).toBe(false);
    expect(isNgPlusRunActive(undefined)).toBe(false);
  });
});

describe('save schema', () => {
  it('defaults ngPlusLoreDepth to 0 and ngPlusRemnantClears to []', () => {
    const save = loadSave();
    expect(save.ngPlusLoreDepth).toBe(0);
    expect(save.ngPlusRemnantClears).toEqual([]);
  });
});

describe('applyNgPlusLoreDepth increment rules', () => {
  it('never advances when no NG+ run is active (ngPlus = 0)', () => {
    const save = ngSave({ ngPlus: 0 });
    expect(applyNgPlusLoreDepth(save, { kind: 'boss', id: 'data_corruption', isNewClear: true })).toBe(false);
    expect(applyNgPlusLoreDepth(save, { kind: 'singularity', id: 'the_singularity', isNewClear: true })).toBe(false);
    expect(applyNgPlusLoreDepth(save, { kind: 'mirror_admin', id: 'mirror_admin', isNewClear: true })).toBe(false);
    expect(applyNgPlusLoreDepth(save, { kind: 'remnant', id: REMNANT_IDS[0] })).toBe(false);
    expect(save.ngPlusLoreDepth).toBe(0);
    expect(save.ngPlusRemnantClears).toEqual([]);
  });

  it('advances +1 for a new Singularity boss clear in NG+', () => {
    const save = ngSave();
    expect(applyNgPlusLoreDepth(save, { kind: 'boss', id: 'data_corruption', isNewClear: true })).toBe(true);
    expect(save.ngPlusLoreDepth).toBe(1);
  });

  it('does not advance for a repeat boss clear in the same loop (isNewClear=false)', () => {
    const save = ngSave({ ngPlusLoreDepth: 1 });
    expect(applyNgPlusLoreDepth(save, { kind: 'boss', id: 'data_corruption', isNewClear: false })).toBe(false);
    expect(save.ngPlusLoreDepth).toBe(1);
  });

  it('advances for first Singularity / Mirror Admin clears per loop', () => {
    const save = ngSave();
    expect(applyNgPlusLoreDepth(save, { kind: 'singularity', id: 'the_singularity', isNewClear: true })).toBe(true);
    expect(applyNgPlusLoreDepth(save, { kind: 'mirror_admin', id: 'mirror_admin', isNewClear: true })).toBe(true);
    expect(save.ngPlusLoreDepth).toBe(2);
  });

  it('does not advance for repeated Singularity / Mirror Admin clears (isNewClear=false)', () => {
    const save = ngSave({ ngPlusLoreDepth: 2 });
    expect(applyNgPlusLoreDepth(save, { kind: 'singularity', id: 'the_singularity', isNewClear: false })).toBe(false);
    expect(applyNgPlusLoreDepth(save, { kind: 'mirror_admin', id: 'mirror_admin', isNewClear: false })).toBe(false);
    expect(save.ngPlusLoreDepth).toBe(2);
  });

  it('ascendant remnant clears advance depth AND record the remnant id', () => {
    const save = ngSave();
    expect(applyNgPlusLoreDepth(save, { kind: 'remnant', id: REMNANT_IDS[0] })).toBe(true);
    expect(save.ngPlusLoreDepth).toBe(1);
    expect(save.ngPlusRemnantClears).toEqual([REMNANT_IDS[0]]);
    expect(applyNgPlusLoreDepth(save, { kind: 'remnant', id: REMNANT_IDS[1] })).toBe(true);
    expect(save.ngPlusLoreDepth).toBe(2);
    expect(save.ngPlusRemnantClears).toEqual([REMNANT_IDS[0], REMNANT_IDS[1]]);
  });

  it('re-clearing the same remnant in NG+ never double-counts', () => {
    const save = ngSave({ ngPlusLoreDepth: 1, ngPlusRemnantClears: [REMNANT_IDS[0]] });
    expect(applyNgPlusLoreDepth(save, { kind: 'remnant', id: REMNANT_IDS[0] })).toBe(false);
    expect(save.ngPlusLoreDepth).toBe(1);
    expect(save.ngPlusRemnantClears).toEqual([REMNANT_IDS[0]]);
  });

  it('initializes ngPlusRemnantClears when the save predates the field', () => {
    const save = ngSave();
    delete save.ngPlusRemnantClears;
    expect(applyNgPlusLoreDepth(save, { kind: 'remnant', id: REMNANT_IDS[0] })).toBe(true);
    expect(save.ngPlusRemnantClears).toEqual([REMNANT_IDS[0]]);
  });
});

describe('applyNewGamePlus keeps the lore-chase record', () => {
  it('does not reset ngPlusLoreDepth / ngPlusRemnantClears (lifetime record)', () => {
    const save = ngSave({
      ngPlus: 1,
      ngPlusLoreDepth: 5,
      ngPlusRemnantClears: [REMNANT_IDS[0]],
      singularityComplete: true,
      mirrorAdminDefeated: true,
    });
    const next = applyNewGamePlus(save);
    expect(next.ngPlus).toBe(2);
    expect(next.ngPlusLoreDepth).toBe(5);
    expect(next.ngPlusRemnantClears).toEqual([REMNANT_IDS[0]]);
    // The loop itself re-locks: depth resumes advancing on fresh clears.
    expect(next.singularityComplete).toBe(false);
    expect(next.mirrorAdminDefeated).toBe(false);
  });
});

describe('NG+ lore-chase milestones', () => {
  // checkMilestones results expose newlyClaimed (met && !claimed) and progress.
  const claimable = (save, id) => getMilestone(checkMilestones(save), id).newlyClaimed;
  const progressOf = (save, id) => getMilestone(checkMilestones(save), id).progress;

  it('ngplus_depth_1 is claimable only on an active NG+ run with depth >= 1', () => {
    expect(claimable(milestoneSave(), 'ngplus_depth_1')).toBe(false);
    expect(claimable(milestoneSave({ ngPlus: 0, ngPlusLoreDepth: 3 }), 'ngplus_depth_1')).toBe(false);
    expect(claimable(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 0 }), 'ngplus_depth_1')).toBe(false);
    expect(claimable(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 1 }), 'ngplus_depth_1')).toBe(true);
    expect(progressOf(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 1 }), 'ngplus_depth_1')).toBe('1/1');
    // Already claimed: not newly claimable again.
    expect(claimable(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 1, milestones: ['ngplus_depth_1'] }), 'ngplus_depth_1')).toBe(false);
  });

  it('ngplus_depth_3 / ngplus_depth_5 track cumulative depth across loops', () => {
    expect(claimable(milestoneSave({ ngPlus: 2, ngPlusLoreDepth: 3 }), 'ngplus_depth_3')).toBe(true);
    expect(claimable(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 4 }), 'ngplus_depth_5')).toBe(false);
    expect(progressOf(milestoneSave({ ngPlus: 1, ngPlusLoreDepth: 4 }), 'ngplus_depth_5')).toBe('4/5');
    expect(claimable(milestoneSave({ ngPlus: 2, ngPlusLoreDepth: 6 }), 'ngplus_depth_5')).toBe(true);
  });

  it('ngplus_ascendant_remnants requires every remnant cleared in NG+', () => {
    const two = milestoneSave({ ngPlus: 1, ngPlusRemnantClears: REMNANT_IDS.slice(0, 2) });
    expect(claimable(two, 'ngplus_ascendant_remnants')).toBe(false);
    expect(progressOf(two, 'ngplus_ascendant_remnants')).toBe('2/3');
    const all = milestoneSave({ ngPlus: 1, ngPlusRemnantClears: [...REMNANT_IDS] });
    expect(claimable(all, 'ngplus_ascendant_remnants')).toBe(true);
    expect(progressOf(all, 'ngplus_ascendant_remnants')).toBe('3/3');
  });

  it('ngplus_ascendant_remnants never completes in the first loop', () => {
    const firstLoop = milestoneSave({ ngPlus: 0, ngPlusRemnantClears: [...REMNANT_IDS] });
    expect(claimable(firstLoop, 'ngplus_ascendant_remnants')).toBe(false);
  });

  it('all NG+ milestones pay lore, not power: reward 0 with Felix prose', () => {
    for (const id of ['ngplus_depth_1', 'ngplus_depth_3', 'ngplus_depth_5', 'ngplus_ascendant_remnants']) {
      const m = getMilestone(checkMilestones(milestoneSave()), id);
      expect(m.ngPlus).toBe(true);
      expect(m.reward).toBe(0);
      expect(m.loreReward?.title).toBeTruthy();
      expect(m.loreReward?.body).toBeTruthy();
    }
  });
});
