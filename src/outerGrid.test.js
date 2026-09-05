import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { getCampaignNodeById } from './campaignMap';
import { PULL_COST } from './gameData';
import { actInOuterGrid, applyNewGamePlus, loadSave, recordNpcDefeat, writeSave } from './persistence';
import { OUTER_GRID_ROOMS, WORLD_ZONES } from './worldZones';
import { applyOuterGridAction, getOuterGridBattleConfig, getOuterGridExits, getOuterGridObjective, getOuterGridProgress, OUTER_GRID_CACHE_REWARD, OUTER_GRID_CLEAR_REWARD } from './outerGrid';

function expedition() {
  return {
    dragons: { fire: { owned: true, level: 1 }, ice: { owned: true, level: 1 }, storm: { owned: false, level: 1 } },
    defeatedNpcs: [], dataScraps: 9, stats: { totalScrapsEarned: 20, battlesLost: 0 },
  };
}

function walk(save, ...rooms) {
  return rooms.reduce((current, room) => {
    const next = applyOuterGridAction(current, 'move', room);
    expect(next, `Passage to ${room}`).not.toBe(current);
    expect(next.outerGrid.roomId).toBe(room);
    return next;
  }, save);
}

describe('Outer Grid authored route', () => {
  it('connects every exit and keeps the finale after the gatekeeper in the campaign', () => {
    for (const room of Object.values(OUTER_GRID_ROOMS)) {
      for (const exit of room.exits) expect(OUTER_GRID_ROOMS[exit.to], `${room.id} → ${exit.to}`).toBeDefined();
      if (room.nodeId) expect(getCampaignNodeById(room.nodeId).zoneId).toBe('outer_grid');
    }
    const zone = WORLD_ZONES.outer_grid;
    expect(getCampaignNodeById(zone.bossNodeId).prerequisiteIds).toContain(zone.midBossNodeId);
  });

  it('requires a real, owned guardian to leave the shelter', () => {
    for (const dragons of [{}, { fire: { owned: false } }, { unknown: { owned: true } }]) {
      const save = { ...expedition(), dragons };
      expect(getOuterGridExits(save)[0].open).toBe(false);
      expect(applyOuterGridAction(save, 'move', 'signal-approach')).toBe(save);
      expect(getOuterGridObjective(save)).toContain('Hatch');
    }
  });

  it.each(['span', 'crawlway'])('completes the %s crossing without repeat battles or repeat rewards', route => {
    const original = expedition();
    const snapshot = structuredClone(original);
    let save = walk(original, 'signal-approach', 'signal-breach');
    expect(getOuterGridBattleConfig(save, 'fire', 'ice')).toEqual({
      nodeId: 'signal-breach', npcId: 'firewall_sentinel', dragonId: 'fire', benchDragonId: 'ice', returnScreen: 'outerGrid',
    });
    expect(applyOuterGridAction(save, 'move', 'firewall-span')).toBe(save);
    save = { ...save, defeatedNpcs: ['firewall_sentinel'] };
    expect(getOuterGridBattleConfig(save, 'fire')).toBeNull();
    save = walk(save, 'firewall-span');
    expect(applyOuterGridAction(save, 'move', 'overflow-vent')).toBe(save);
    expect(applyOuterGridAction(save, 'move', 'maintenance-cache')).toBe(save);
    save = applyOuterGridAction(save, 'choose-route', route);
    expect(applyOuterGridAction(save, 'choose-route', route === 'span' ? 'crawlway' : 'span')).toBe(save);
    if (route === 'crawlway') {
      save = walk(save, 'maintenance-cache');
      save = applyOuterGridAction(save, 'claim-cache');
      expect(applyOuterGridAction(save, 'claim-cache')).toBe(save);
      save = walk(save, 'overflow-vent');
    } else {
      expect(applyOuterGridAction(save, 'move', 'maintenance-cache')).toBe(save);
      save = walk(save, 'overflow-vent');
    }
    expect(getOuterGridBattleConfig(save, 'ice')?.npcId).toBe('buffer_overflow');
    expect(applyOuterGridAction(save, 'move', 'return-gate')).toBe(save);
    save = { ...save, defeatedNpcs: ['firewall_sentinel', 'buffer_overflow'] };
    save = walk(save, 'return-gate');
    save = applyOuterGridAction(save, 'claim-clear');
    const reward = PULL_COST + (route === 'crawlway' ? OUTER_GRID_CACHE_REWARD : 0);
    expect(save.dataScraps).toBe(original.dataScraps + reward);
    expect(save.stats.totalScrapsEarned).toBe(original.stats.totalScrapsEarned + reward);
    expect(applyOuterGridAction(save, 'claim-clear')).toBe(save);
    save = walk(save, 'field-locker', 'signal-approach', 'signal-breach', 'firewall-span');
    expect(save.outerGrid.spanRoute).toBe(route);
    expect(save.outerGrid.visited.length).toBe(route === 'span' ? 6 : 7);
    expect(getOuterGridObjective(save)).toContain('stable');
    expect(original).toEqual(snapshot);
  });

  it('keeps a loss at the encounter checkpoint and permits retreat and retry', () => {
    let save = walk(expedition(), 'signal-approach', 'signal-breach');
    const beforeLoss = getOuterGridBattleConfig(save, 'fire');
    save = { ...save, stats: { ...save.stats, battlesLost: 1 } };
    expect(getOuterGridProgress(save).roomId).toBe('signal-breach');
    expect(getOuterGridBattleConfig(save, 'fire')).toEqual(beforeLoss);
    save = walk(save, 'signal-approach', 'field-locker', 'signal-approach', 'signal-breach');
    expect(getOuterGridBattleConfig(save, 'fire')).toEqual(beforeLoss);
    expect(save.outerGrid.visited).toEqual(['field-locker', 'signal-approach', 'signal-breach']);
  });

  it('rejects shortcuts, premature rewards, and actions outside their rooms', () => {
    const save = expedition();
    for (const [action, value] of [['move', 'return-gate'], ['move', 'constructor'], ['claim-cache'], ['claim-clear'], ['choose-route', 'span'], ['unknown']]) {
      expect(applyOuterGridAction(save, action, value)).toBe(save);
    }
    const forgedCheckpoint = { ...save, outerGrid: { roomId: 'return-gate' }, defeatedNpcs: ['buffer_overflow'] };
    expect(applyOuterGridAction(forgedCheckpoint, 'claim-clear')).toBe(forgedCheckpoint);
    const read = applyOuterGridAction(save, 'read-note');
    expect(read.outerGrid.fieldNoteRead).toBe(true);
    expect(applyOuterGridAction(read, 'read-note')).toBe(read);
  });

  it('uses distinct owned party members and refuses unavailable encounters', () => {
    let save = walk(expedition(), 'signal-approach', 'signal-breach');
    expect(getOuterGridBattleConfig(save, 'storm')).toBeNull();
    expect(getOuterGridBattleConfig(save, 'unknown')).toBeNull();
    for (const reserve of ['fire', 'storm', 'unknown', null]) {
      expect(getOuterGridBattleConfig(save, 'fire', reserve).benchDragonId).toBeNull();
    }
    save = applyOuterGridAction(save, 'party', { guardianId: 'fire', reserveId: 'ice' });
    expect(save.outerGrid).toMatchObject({ guardianId: 'fire', reserveId: 'ice' });
    expect(applyOuterGridAction(save, 'party', { guardianId: 'storm' })).toBe(save);
    save.dragons.ice.owned = false; // A later fusion can consume a selected reserve.
    expect(getOuterGridProgress(save).reserveId).toBeNull();
    expect(getOuterGridBattleConfig(expedition(), 'fire')).toBeNull();
  });
});

describe('Outer Grid save lifecycle', () => {
  beforeEach(() => {
    const values = new Map();
    const localStorage = {
      getItem: key => values.get(key) ?? null,
      setItem: (key, value) => values.set(key, value),
      removeItem: key => values.delete(key),
    };
    vi.stubGlobal('window', { localStorage });
    vi.stubGlobal('localStorage', localStorage);
  });
  afterEach(() => vi.unstubAllGlobals());

  it('migrates a legacy save without resetting its wins, currency, or collection', () => {
    const legacy = { ...expedition(), defeatedNpcs: ['firewall_sentinel', 'buffer_overflow'] };
    writeSave(legacy);
    const restored = loadSave();
    expect(restored.outerGrid).toMatchObject({ roomId: 'field-locker', visited: ['field-locker'], rewardClaimed: false });
    expect(restored.defeatedNpcs).toEqual(legacy.defeatedNpcs);
    expect(restored.dataScraps).toBe(legacy.dataScraps);
    expect(restored.dragons.fire.owned).toBe(true);
    const atGate = walk({ ...restored, outerGrid: { roomId: 'overflow-vent' } }, 'return-gate');
    expect(applyOuterGridAction(atGate, 'claim-clear').dataScraps).toBe(legacy.dataScraps + OUTER_GRID_CLEAR_REWARD);
  });

  it('repairs malformed or locked checkpoints instead of discarding the rest of the save', () => {
    for (const roomId of ['missing', 'constructor', 'return-gate', 'maintenance-cache', null, {}]) {
      writeSave({ ...expedition(), outerGrid: {
        roomId, visited: ['signal-approach', 'signal-approach', 'missing', 'constructor', null, {}],
        spanRoute: 'warp', guardianId: 'storm', reserveId: 'storm', cacheClaimed: 'yes',
      } });
      const save = loadSave();
      expect(save.outerGrid).toMatchObject({ roomId: 'field-locker', visited: ['field-locker', 'signal-approach'], spanRoute: null, guardianId: null, reserveId: null, cacheClaimed: false });
      expect(save.dataScraps).toBe(9);
    }
  });

  it('persists checkpoints and reads fresh battle results before opening a passage', () => {
    writeSave(expedition());
    expect(actInOuterGrid('move', 'signal-approach')).toBe(true);
    expect(actInOuterGrid('move', 'signal-breach')).toBe(true);
    expect(actInOuterGrid('party', { guardianId: 'ice', reserveId: 'fire' })).toBe(true);
    expect(loadSave().outerGrid).toMatchObject({ roomId: 'signal-breach', guardianId: 'ice', reserveId: 'fire' });
    expect(actInOuterGrid('move', 'firewall-span')).toBe(false);
    recordNpcDefeat('firewall_sentinel');
    expect(actInOuterGrid('move', 'firewall-span')).toBe(true);
    expect(actInOuterGrid('choose-route', 'crawlway')).toBe(true);
    expect(loadSave().defeatedNpcs).toContain('firewall_sentinel');
    expect(loadSave().outerGrid).toMatchObject({ roomId: 'firewall-span', spanRoute: 'crawlway' });
  });

  it('writes each reward once across repeated calls and reloads', () => {
    writeSave({ ...expedition(), defeatedNpcs: ['firewall_sentinel', 'buffer_overflow'], outerGrid: { roomId: 'maintenance-cache', spanRoute: 'crawlway' } });
    expect(actInOuterGrid('claim-cache')).toBe(true);
    expect(actInOuterGrid('claim-cache')).toBe(false);
    actInOuterGrid('move', 'overflow-vent');
    actInOuterGrid('move', 'return-gate');
    expect(actInOuterGrid('claim-clear')).toBe(true);
    expect(actInOuterGrid('claim-clear')).toBe(false);
    expect(loadSave().dataScraps).toBe(9 + OUTER_GRID_CACHE_REWARD + OUTER_GRID_CLEAR_REWARD);
    expect(loadSave().stats.totalScrapsEarned).toBe(20 + OUTER_GRID_CACHE_REWARD + OUTER_GRID_CLEAR_REWARD);
  });

  it('starts New Game+ in the shelter with fresh crossings and rewards, retaining earned resources', () => {
    const save = { ...expedition(), defeatedNpcs: ['firewall_sentinel', 'buffer_overflow'], outerGrid: {
      roomId: 'return-gate', visited: Object.keys(OUTER_GRID_ROOMS), spanRoute: 'crawlway', cacheClaimed: true, rewardClaimed: true,
    } };
    writeSave(applyNewGamePlus(save));
    const nextRun = loadSave();
    expect(nextRun.outerGrid).toEqual(getOuterGridProgress({}));
    expect(nextRun.dataScraps).toBe(9);
    expect(nextRun.dragons.fire.owned).toBe(true);
    expect(actInOuterGrid('claim-clear')).toBe(false);
    expect(actInOuterGrid('move', 'signal-approach')).toBe(true);
  });
});
