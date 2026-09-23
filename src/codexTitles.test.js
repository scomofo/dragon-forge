import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import {
  loadSave, writeSave, recordDiscovery, claimMilestone, setEquippedTitle,
  unlockDragon, markSingularityComplete, fuseDragons,
} from './persistence';
import { applyPullResult } from './hatcheryEngine';
import { JOURNAL_DRAGON_IDS } from './gameData';

// In-memory localStorage stand-in (same pattern as expeditions.test.js).
function stubStorage() {
  const values = new Map();
  const storage = {
    getItem: (key) => values.get(key) ?? null,
    setItem: (key, value) => values.set(key, value),
    removeItem: (key) => values.delete(key),
  };
  vi.stubGlobal('window', { localStorage: storage });
  vi.stubGlobal('localStorage', storage);
  return storage;
}

describe('recordDiscovery', () => {
  it('appends the id the first time and guards duplicates', () => {
    const save = {};
    recordDiscovery(save, 'fire');
    recordDiscovery(save, 'fire');
    recordDiscovery(save, 'ice');
    expect(save.discoveryOrder).toEqual(['fire', 'ice']);
  });

  it('repairs a missing discoveryOrder array', () => {
    const save = { discoveryOrder: 'corrupt' };
    recordDiscovery(save, 'fire');
    expect(save.discoveryOrder).toEqual(['fire']);
  });

  it('ignores falsy ids', () => {
    const save = {};
    recordDiscovery(save, null);
    expect(save.discoveryOrder).toEqual([]);
  });
});

describe('applyPullResult discovery order', () => {
  function pullSave() {
    const dragons = {};
    for (const id of JOURNAL_DRAGON_IDS) {
      dragons[id] = { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null };
    }
    return { dragons, pityCounter: 0, discoveryOrder: [] };
  }
  const pull = (element) => ({
    element, rarityName: 'Common', rarityMultiplier: 1, shiny: false, newPityCounter: 1,
  });

  it('appends on the isNew path and never duplicates', () => {
    const first = applyPullResult(pullSave(), pull('fire'));
    expect(first.isNew).toBe(true);
    expect(first.save.discoveryOrder).toEqual(['fire']);

    // Duplicate pull of an owned dragon: no reorder, no duplicate.
    const dup = applyPullResult(first.save, pull('fire'));
    expect(dup.isNew).toBe(false);
    expect(dup.save.discoveryOrder).toEqual(['fire']);

    const second = applyPullResult(dup.save, pull('ice'));
    expect(second.save.discoveryOrder).toEqual(['fire', 'ice']);
  });
});

describe('claimMilestone title grants', () => {
  beforeEach(() => stubStorage());
  afterEach(() => vi.unstubAllGlobals());

  it('grants the title and auto-equips it when none is equipped', () => {
    writeSave(loadSave());
    expect(claimMilestone('tier_common', 250, 'hearth_warden')).toBe(true);
    const save = loadSave();
    expect(save.titles).toEqual(['hearth_warden']);
    expect(save.equippedTitle).toBe('hearth_warden');
    expect(save.dataScraps).toBe(250);
  });

  it('does not duplicate titles or pay twice', () => {
    writeSave(loadSave());
    claimMilestone('tier_common', 250, 'hearth_warden');
    expect(claimMilestone('tier_common', 250, 'hearth_warden')).toBe(false);
    const save = loadSave();
    expect(save.titles).toEqual(['hearth_warden']);
    expect(save.dataScraps).toBe(250);
  });

  it('keeps the currently equipped title when a later title is claimed', () => {
    writeSave(loadSave());
    claimMilestone('tier_common', 250, 'hearth_warden');
    claimMilestone('tier_uncommon', 400, 'wildcaller');
    const save = loadSave();
    expect(save.titles).toEqual(['hearth_warden', 'wildcaller']);
    expect(save.equippedTitle).toBe('hearth_warden');
  });

  it('claims without a titleReward still work (legacy milestones)', () => {
    writeSave(loadSave());
    expect(claimMilestone('first_discovery', 100)).toBe(true);
    expect(loadSave().titles).toEqual([]);
    expect(loadSave().equippedTitle).toBeNull();
  });
});

describe('setEquippedTitle', () => {
  beforeEach(() => stubStorage());
  afterEach(() => vi.unstubAllGlobals());

  it('equips unlocked titles, rejects unknown ones, and clears with null', () => {
    writeSave(loadSave());
    expect(setEquippedTitle('hearth_warden')).toBe(false); // not unlocked yet
    claimMilestone('tier_common', 250, 'hearth_warden');
    expect(setEquippedTitle('wildcaller')).toBe(false); // still locked
    expect(setEquippedTitle('hearth_warden')).toBe(true);
    expect(loadSave().equippedTitle).toBe('hearth_warden');
    expect(setEquippedTitle(null)).toBe(true);
    expect(loadSave().equippedTitle).toBeNull();
  });
});

describe('discovery-order persistence across grant paths', () => {
  beforeEach(() => stubStorage());
  afterEach(() => vi.unstubAllGlobals());

  it('unlockDragon (roster grant) appends', () => {
    writeSave(loadSave());
    unlockDragon('void', true);
    expect(loadSave().discoveryOrder).toEqual(['void']);
    unlockDragon('void', false); // re-grant: no duplicate
    expect(loadSave().discoveryOrder).toEqual(['void']);
  });

  it('markSingularityComplete (Light grant) appends', () => {
    writeSave(loadSave());
    markSingularityComplete();
    const save = loadSave();
    expect(save.dragons.light.owned).toBe(true);
    expect(save.discoveryOrder).toContain('light');
    markSingularityComplete(); // already owned: no duplicate
    expect(loadSave().discoveryOrder.filter((id) => id === 'light')).toHaveLength(1);
  });

  it('fuseDragons offspring appends exactly once', () => {
    const setup = loadSave();
    setup.dataScraps = 1000;
    setup.dragons.fire.owned = true;
    setup.dragons.fire.discovered = true;
    setup.dragons.ice.owned = true;
    setup.dragons.ice.discovered = true;
    writeSave(setup);
    fuseDragons('fire', 'ice', 'synthesis', 1, 0, false, null);
    expect(loadSave().discoveryOrder).toContain('synthesis');
    fuseDragons('fire', 'ice', 'synthesis', 1, 0, false, null);
    expect(loadSave().discoveryOrder.filter((id) => id === 'synthesis')).toHaveLength(1);
  });
});

describe('codex field migrations', () => {
  beforeEach(() => stubStorage());
  afterEach(() => vi.unstubAllGlobals());

  it('initializes titles, equippedTitle, and discoveryOrder on legacy saves', () => {
    const legacy = loadSave();
    delete legacy.titles;
    delete legacy.equippedTitle;
    delete legacy.discoveryOrder;
    writeSave(legacy);
    const save = loadSave();
    expect(save.titles).toEqual([]);
    expect(save.equippedTitle).toBeNull();
    expect(save.discoveryOrder).toEqual([]);
  });

  it('resets equippedTitle when it names a title the player never unlocked', () => {
    const save = loadSave();
    save.titles = ['hearth_warden'];
    save.equippedTitle = 'transcendent'; // tampered / stale
    writeSave(save);
    expect(loadSave().equippedTitle).toBeNull();
  });

  it('keeps a legitimately equipped title through migration', () => {
    const save = loadSave();
    save.titles = ['hearth_warden'];
    save.equippedTitle = 'hearth_warden';
    writeSave(save);
    expect(loadSave().equippedTitle).toBe('hearth_warden');
  });
});
