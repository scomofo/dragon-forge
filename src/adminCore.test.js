import { describe, expect, it } from 'vitest';
import { getCampaignNodeById } from './campaignMap';
import { PULL_COST } from './gameData';
import { ADMIN_CORE_ROOMS, WORLD_ZONES } from './worldZones';
import { applyAdminCoreAction, getAdminCoreBattleConfig, getAdminCoreExits, getAdminCoreObjective, getAdminCoreProgress, ADMIN_CORE_CACHE_REWARD, ADMIN_CORE_CLEAR_REWARD } from './adminCore';

function expedition() {
  return {
    dragons: { light: { owned: true, level: 12 }, stone: { owned: true, level: 12 }, fire: { owned: false, level: 1 } },
    defeatedNpcs: ['firewall_sentinel', 'bit_wraith', 'phishing_siren', 'crypto_crab', 'buffer_overflow', 'glitch_hydra', 'logic_bomb'],
    dataScraps: 9, stats: { totalScrapsEarned: 20, battlesLost: 0 },
  };
}

function walk(save, ...rooms) {
  return rooms.reduce((current, room) => {
    const next = applyAdminCoreAction(current, 'move', room);
    expect(next, `Passage to ${room}`).not.toBe(current);
    expect(next.adminCore.roomId).toBe(room);
    return next;
  }, save);
}

describe('Admin Core authored route', () => {
  it('connects every exit and keeps zone nodes inside the zone, DAG order respected', () => {
    for (const room of Object.values(ADMIN_CORE_ROOMS)) {
      for (const exit of room.exits) expect(ADMIN_CORE_ROOMS[exit.to], `${room.id} → ${exit.to}`).toBeDefined();
      if (room.nodeId) expect(getCampaignNodeById(room.nodeId).zoneId).toBe('admin_core');
    }
    const zone = WORLD_ZONES.admin_core;
    expect(getCampaignNodeById(zone.bossNodeId).prerequisiteIds).toContain(zone.midBossNodeId);
    expect(getCampaignNodeById('protocol-perch').prerequisiteIds).toEqual(expect.arrayContaining(['logic-core', 'recursive-gate']));
  });

  it('stays shut until the Storm Spine finale falls, and always needs a guardian', () => {
    for (const dragons of [{}, { light: { owned: false } }, { unknown: { owned: true } }]) {
      const save = { ...expedition(), dragons };
      expect(getAdminCoreExits(save)[0].open).toBe(false);
      expect(applyAdminCoreAction(save, 'move', 'processional')).toBe(save);
    }
    const noFinale = { ...expedition(), defeatedNpcs: ['firewall_sentinel', 'crypto_crab', 'glitch_hydra'] };
    expect(getAdminCoreExits(noFinale)[0].open).toBe(false);
    expect(getAdminCoreObjective(noFinale)).toContain('Logic Core');
  });

  it.each(['hoarding', 'memory', 'passage'])('completes with the %s lantern while the other two burn out', lantern => {
    const original = expedition();
    const snapshot = structuredClone(original);
    let save = walk(original, 'processional', 'recursive-gate');
    expect(getAdminCoreBattleConfig(save, 'light', 'stone')).toEqual({
      nodeId: 'recursive-gate', npcId: 'recursive_golem', dragonId: 'light', benchDragonId: 'stone', returnScreen: 'adminCore',
    });
    // The lanterns stay cold until the golem unwinds.
    expect(applyAdminCoreAction(save, 'move', 'cold-lanterns')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'recursive_golem'] };
    expect(getAdminCoreBattleConfig(save, 'light')).toBeNull(); // already quiet
    save = walk(save, 'cold-lanterns');
    for (const room of ['reliquary-vault', 'echo-archive', 'protocol-perch']) {
      expect(applyAdminCoreAction(save, 'move', room)).toBe(save); // no lantern lit
    }
    save = applyAdminCoreAction(save, 'choose-lantern', lantern);
    for (const other of ['hoarding', 'memory', 'passage'].filter(l => l !== lantern)) {
      expect(applyAdminCoreAction(save, 'choose-lantern', other)).toBe(save); // burned out
    }
    const laneRoom = { hoarding: 'reliquary-vault', memory: 'echo-archive', passage: 'protocol-perch' }[lantern];
    save = walk(save, laneRoom);
    if (lantern === 'hoarding') {
      save = applyAdminCoreAction(save, 'claim-cache');
      expect(applyAdminCoreAction(save, 'claim-cache')).toBe(save); // once only
      save = walk(save, 'protocol-perch');
    } else if (lantern === 'memory') {
      const read = applyAdminCoreAction(save, 'read-archive');
      expect(read.adminCore.archiveRead).toBe(true);
      expect(applyAdminCoreAction(read, 'read-archive')).toBe(read); // once
      save = walk(read, 'protocol-perch');
    }
    expect(getAdminCoreBattleConfig(save, 'stone')?.npcId).toBe('protocol_vulture');
    expect(applyAdminCoreAction(save, 'move', 'reset-threshold')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'protocol_vulture'] };
    save = walk(save, 'reset-threshold');
    save = applyAdminCoreAction(save, 'claim-clear');
    const reward = PULL_COST + (lantern === 'hoarding' ? ADMIN_CORE_CACHE_REWARD : 0);
    expect(save.dataScraps).toBe(original.dataScraps + reward);
    expect(save.stats.totalScrapsEarned).toBe(original.stats.totalScrapsEarned + reward);
    expect(applyAdminCoreAction(save, 'claim-clear')).toBe(save);
    expect(getAdminCoreObjective(save)).toContain('stable');
    expect(original).toEqual(snapshot); // no input mutation
    expect(ADMIN_CORE_CLEAR_REWARD).toBe(PULL_COST);
  });

  it('keeps a loss at the encounter checkpoint and permits retreat and retry', () => {
    let save = walk(expedition(), 'processional', 'recursive-gate');
    const beforeLoss = getAdminCoreBattleConfig(save, 'light');
    save = { ...save, stats: { ...save.stats, battlesLost: 1 } };
    expect(getAdminCoreProgress(save).roomId).toBe('recursive-gate');
    expect(getAdminCoreBattleConfig(save, 'light')).toEqual(beforeLoss);
    save = walk(save, 'processional', 'mirror-vestibule', 'processional', 'recursive-gate');
    expect(getAdminCoreBattleConfig(save, 'light')).toEqual(beforeLoss);
  });

  it('rejects shortcuts, premature rewards, and actions outside their rooms', () => {
    const save = expedition();
    for (const [action, value] of [['move', 'reset-threshold'], ['move', 'constructor'], ['claim-cache'], ['claim-clear'], ['choose-lantern', 'memory'], ['read-archive'], ['unknown']]) {
      expect(applyAdminCoreAction(save, action, value)).toBe(save);
    }
    const forged = { ...save, adminCore: { roomId: 'reset-threshold' }, defeatedNpcs: [...save.defeatedNpcs] };
    expect(applyAdminCoreAction(forged, 'claim-clear')).toBe(forged);
  });

  it('uses distinct owned party members and refuses unavailable encounters', () => {
    let save = walk(expedition(), 'processional', 'recursive-gate');
    expect(getAdminCoreBattleConfig(save, 'fire')).toBeNull(); // not owned
    expect(getAdminCoreBattleConfig(save, 'unknown')).toBeNull();
    expect(getAdminCoreBattleConfig(save, 'light', 'light')).toMatchObject({ benchDragonId: null });
    expect(getAdminCoreBattleConfig(save, 'light', 'stone')).toMatchObject({ benchDragonId: 'stone' });
    save = walk(save, 'processional', 'mirror-vestibule');
    expect(getAdminCoreBattleConfig(save, 'light')).toBeNull(); // shelter has no encounter
  });
});
