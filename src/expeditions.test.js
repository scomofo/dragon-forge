import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { CAMPAIGN_NODES, getCampaignNodeById } from './campaignMap';
import { EXPEDITIONS, getExpeditionGuidance } from './expeditions';
import { getPlayerGuidance } from './playerGuidance';
import { actInOuterGrid, actInFrozenCache, actInStormSpine, actInAdminCore, applyNewGamePlus, loadSave, recordNpcDefeat, rememberExpedition, writeSave } from './persistence';

const allWins = CAMPAIGN_NODES.map(node => node.npcId);
const frozenWins = ['firewall_sentinel', 'buffer_overflow', 'bit_wraith', 'phishing_siren', 'crypto_crab'];

function explorer(defeatedNpcs = ['firewall_sentinel']) {
  return {
    dragons: { fire: { owned: true, level: 8 }, ice: { owned: true, level: 8 } },
    dataScraps: 17, defeatedNpcs, inventory: { cores: { ice: 2 } },
    stats: { battlesWon: 4, totalScrapsEarned: 70 }, flags: { metFelix: true },
  };
}

describe('guidance across the four expeditions', () => {
  it('uses all nine campaign encounters in the order of their authored rooms', () => {
    const encounters = EXPEDITIONS.flatMap(expedition => Object.values(expedition.rooms).filter(room => room.nodeId).map(room => {
      expect(getCampaignNodeById(room.nodeId).zoneId).toBe(expedition.zoneId);
      return room.nodeId;
    }));
    expect(new Set(encounters)).toEqual(new Set(CAMPAIGN_NODES.map(node => node.id)));
    expect(encounters.indexOf('siren-loop')).toBeLessThan(encounters.indexOf('crypto-lock'));
  });

  it('does not treat the default shelter records as expeditions the player entered', () => {
    const save = explorer(allWins);
    for (const expedition of EXPEDITIONS) save[expedition.screen] = expedition.getProgress(save);
    expect(getExpeditionGuidance(save)).toBeNull();
    expect(getPlayerGuidance(save).action).toBe('DAILY OPEN');
  });

  it('follows the last entered route even when an earlier route has an unclaimed reward', () => {
    const save = explorer(frozenWins);
    save.outerGrid = { roomId: 'return-gate' };
    save.stormSpine = { roomId: 'live-wire' };
    save.flags.activeExpedition = 'stormSpine';
    expect(getExpeditionGuidance(save).target).toBe('stormSpine');
    save.flags.activeExpedition = 'outerGrid';
    expect(getExpeditionGuidance(save)).toMatchObject({ target: 'outerGrid', title: expect.stringContaining('Return Gate') });
  });

  it('uses the furthest entered unfinished sector for saves without a last-entered marker', () => {
    const save = explorer(frozenWins);
    save.outerGrid = { roomId: 'return-gate' };
    save.frozenCache = { roomId: 'thaw-gate' };
    save.stormSpine = { roomId: 'live-wire' };
    expect(getExpeditionGuidance(save).target).toBe('stormSpine');
  });

  it('points from Crypto Lock back to Overflow Vent when the map path skipped it', () => {
    const save = explorer(['firewall_sentinel', 'bit_wraith', 'phishing_siren']);
    save.flags.activeExpedition = 'frozenCache';
    const guidance = getExpeditionGuidance(save);
    expect(guidance).toMatchObject({ target: 'outerGrid', action: 'OPEN ROUTE' });
    expect(guidance.title).toContain('Overflow Vent');
    expect(guidance.title).toContain('Crypto Lock');
    save.defeatedNpcs.push('buffer_overflow');
    expect(getExpeditionGuidance(save)).toMatchObject({ target: 'frozenCache', action: 'CONTINUE ROUTE' });
  });

  it('points from Hydra Spine back to Siren Loop after a direct map clear of Crypto Lock', () => {
    const save = explorer(['firewall_sentinel', 'buffer_overflow', 'crypto_crab']);
    save.flags.activeExpedition = 'stormSpine';
    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'frozenCache', action: 'OPEN ROUTE', title: 'Clear Siren Loop in Frozen Cache to open Hydra Spine.',
    });
    save.defeatedNpcs.push('bit_wraith', 'phishing_siren');
    expect(getExpeditionGuidance(save)).toMatchObject({ target: 'stormSpine', action: 'CONTINUE ROUTE' });
  });

  it.each(EXPEDITIONS.map(expedition => [expedition.screen, expedition.rooms[expedition.rewardRoom].name]))('keeps %s return rewards visible until claimed', (screen, gateName) => {
    const save = explorer(allWins);
    save.flags.activeExpedition = screen;
    expect(getPlayerGuidance(save)).toMatchObject({ target: screen, title: expect.stringContaining(gateName) });
    save[screen] = { rewardClaimed: true };
    expect(getExpeditionGuidance(save)).toBeNull();
    expect(getPlayerGuidance(save).action).toBe('DAILY OPEN');
  });

  it('does not hide a skipped encounter just because a legacy player claimed the zone reward', () => {
    const save = explorer(['firewall_sentinel', 'buffer_overflow', 'crypto_crab']);
    save.flags.activeExpedition = 'frozenCache';
    save.frozenCache = { rewardClaimed: true };
    expect(getExpeditionGuidance(save)).toMatchObject({ target: 'frozenCache', title: expect.stringContaining('Bit Wraith') });
  });

  it('ignores malformed and locked route records and preserves endgame priorities', () => {
    const save = explorer();
    save.flags.activeExpedition = 'constructor';
    save.adminCore = { roomId: 'processional', visited: ['processional'] };
    expect(getExpeditionGuidance(save)).toBeNull();
    save.flags.activeExpedition = 'frozenCache';
    save.singularityComplete = true;
    expect(getPlayerGuidance(save).target).toBe('singularity');
    save.mirrorAdminDefeated = true;
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'journal', action: 'ARCHIVE COMPLETE' });
  });
});

describe('remembering the active expedition', () => {
  let storage;
  beforeEach(() => {
    const values = new Map();
    storage = {
      getItem: key => values.get(key) ?? null,
      setItem: vi.fn((key, value) => values.set(key, value)),
      removeItem: key => values.delete(key),
    };
    vi.stubGlobal('window', { localStorage: storage });
    vi.stubGlobal('localStorage', storage);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('records entry before the first room action and preserves that choice through reload', () => {
    writeSave(explorer(frozenWins));
    expect(rememberExpedition('stormSpine')).toBe(true);
    const resumed = loadSave();
    expect(resumed.stormSpine.visited).toEqual(['overclock-gantry']);
    expect(resumed.flags.activeExpedition).toBe('stormSpine');
    expect(getPlayerGuidance(resumed).target).toBe('stormSpine');
    expect(resumed.dataScraps).toBe(17);
    expect(resumed.inventory.cores.ice).toBe(2);
    expect(resumed.flags.metFelix).toBe(true);
    storage.setItem.mockClear();
    expect(rememberExpedition('stormSpine')).toBe(false);
    expect(storage.setItem).not.toHaveBeenCalled();
  });

  it('does not replace the active route on ordinary navigation or a locked zone entry', () => {
    writeSave(explorer());
    rememberExpedition('outerGrid');
    for (const screen of ['forge', 'map', 'settings', 'stormSpine', 'adminCore', 'constructor', null]) {
      expect(rememberExpedition(screen)).toBe(false);
      expect(loadSave().flags.activeExpedition).toBe('outerGrid');
    }
  });

  it.each([
    ['outerGrid', actInOuterGrid, 'signal-approach'],
    ['frozenCache', actInFrozenCache, 'mute-channel'],
    ['stormSpine', actInStormSpine, 'live-wire'],
    ['adminCore', actInAdminCore, 'processional'],
  ])('updates the active route after a valid %s action using the latest save', (screen, act, roomId) => {
    const save = explorer(allWins);
    save.flags.activeExpedition = screen === 'outerGrid' ? 'frozenCache' : 'outerGrid';
    writeSave(save);
    expect(act('move', 'missing-room')).toBe(false);
    expect(loadSave().flags.activeExpedition).toBe(save.flags.activeExpedition);
    expect(act('move', roomId)).toBe(true);
    const resumed = loadSave();
    expect(resumed.flags.activeExpedition).toBe(screen);
    expect(resumed[screen].roomId).toBe(roomId);
    expect(resumed.defeatedNpcs).toEqual(allWins);
    expect(resumed.stats.totalScrapsEarned).toBe(70);
  });

  it('migrates absent, unknown, and locked markers without discarding progression', () => {
    for (const activeExpedition of [undefined, null, 'unknown', 'constructor', {}, 'adminCore']) {
      writeSave({ ...explorer(), flags: { metFelix: true, activeExpedition } });
      const save = loadSave();
      expect(save.flags.activeExpedition).toBeNull();
      expect(save.defeatedNpcs).toEqual(['firewall_sentinel']);
      expect(save.dataScraps).toBe(17);
      expect(save.flags.metFelix).toBe(true);
    }
  });

  it('resumes after a win and resets the marker for New Game+ without losing resources', () => {
    writeSave(explorer());
    rememberExpedition('frozenCache');
    actInFrozenCache('move', 'mute-channel');
    recordNpcDefeat('bit_wraith');
    expect(getPlayerGuidance(loadSave())).toMatchObject({ target: 'frozenCache', title: expect.stringContaining('Siren Loop') });
    writeSave(applyNewGamePlus(loadSave()));
    const next = loadSave();
    expect(next.flags.activeExpedition).toBeNull();
    expect(next.frozenCache.visited).toEqual(['cold-archive']);
    expect(next.dataScraps).toBe(17);
    expect(getPlayerGuidance(next).target).toBe('outerGrid');
  });
});
