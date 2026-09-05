import { describe, expect, it } from 'vitest';
import { getCampaignNodeById } from './campaignMap';
import { PULL_COST } from './gameData';
import { STORM_SPINE_ROOMS, WORLD_ZONES } from './worldZones';
import { applyStormSpineAction, getStormSpineBattleConfig, getStormSpineExits, getStormSpineObjective, getStormSpineProgress, STORM_SPINE_CACHE_REWARD, STORM_SPINE_CLEAR_REWARD } from './stormSpine';

function expedition() {
  return {
    dragons: { storm: { owned: true, level: 6 }, ice: { owned: true, level: 6 }, fire: { owned: false, level: 1 } },
    defeatedNpcs: ['firewall_sentinel', 'bit_wraith', 'phishing_siren', 'crypto_crab', 'buffer_overflow'],
    dataScraps: 9, stats: { totalScrapsEarned: 20, battlesLost: 0 },
  };
}

function walk(save, ...rooms) {
  return rooms.reduce((current, room) => {
    const next = applyStormSpineAction(current, 'move', room);
    expect(next, `Passage to ${room}`).not.toBe(current);
    expect(next.stormSpine.roomId).toBe(room);
    return next;
  }, save);
}

describe('Storm Spine authored route', () => {
  it('connects every exit and keeps zone nodes inside the zone, DAG order respected', () => {
    for (const room of Object.values(STORM_SPINE_ROOMS)) {
      for (const exit of room.exits) expect(STORM_SPINE_ROOMS[exit.to], `${room.id} → ${exit.to}`).toBeDefined();
      if (room.nodeId) expect(getCampaignNodeById(room.nodeId).zoneId).toBe('storm_spine');
    }
    const zone = WORLD_ZONES.storm_spine;
    // The DAG forces hydra-spine before logic-core; the zone def must agree.
    expect(getCampaignNodeById(zone.bossNodeId).prerequisiteIds).toContain(zone.midBossNodeId);
    expect(getCampaignNodeById('hydra-spine').prerequisiteIds).toEqual(expect.arrayContaining(['crypto-lock', 'siren-loop']));
  });

  it('stays shut until the Frozen Cache finale falls, and always needs a guardian', () => {
    for (const dragons of [{}, { storm: { owned: false } }, { unknown: { owned: true } }]) {
      const save = { ...expedition(), dragons };
      expect(getStormSpineExits(save)[0].open).toBe(false);
      expect(applyStormSpineAction(save, 'move', 'live-wire')).toBe(save);
    }
    const noFinale = { ...expedition(), defeatedNpcs: ['firewall_sentinel', 'bit_wraith'] };
    expect(getStormSpineExits(noFinale)[0].open).toBe(false);
    expect(getStormSpineObjective(noFinale)).toContain('Frozen Cache');
  });

  it.each(['capacitor', 'archive', 'direct'])('completes the %s lane while the other two arc shut', lane => {
    const original = expedition();
    const snapshot = structuredClone(original);
    let save = walk(original, 'live-wire', 'hydra-spine');
    expect(getStormSpineBattleConfig(save, 'storm', 'ice')).toEqual({
      nodeId: 'hydra-spine', npcId: 'glitch_hydra', dragonId: 'storm', benchDragonId: 'ice', returnScreen: 'stormSpine',
    });
    // The fork is shut until the hydra is quiet.
    expect(applyStormSpineAction(save, 'move', 'fork-in-the-wire')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'glitch_hydra'] };
    expect(getStormSpineBattleConfig(save, 'storm')).toBeNull(); // already quiet
    save = walk(save, 'fork-in-the-wire');
    // No lane chosen: every routed exit is closed.
    for (const room of ['capacitor-bank', 'broken-conduit', 'logic-core']) {
      expect(applyStormSpineAction(save, 'move', room)).toBe(save);
    }
    save = applyStormSpineAction(save, 'choose-lane', lane);
    // The other two lanes are permanently shut.
    for (const other of ['capacitor', 'archive', 'direct'].filter(l => l !== lane)) {
      expect(applyStormSpineAction(save, 'choose-lane', other)).toBe(save);
    }
    const laneRoom = { capacitor: 'capacitor-bank', archive: 'broken-conduit', direct: 'logic-core' }[lane];
    save = walk(save, laneRoom);
    if (lane === 'capacitor') {
      save = applyStormSpineAction(save, 'claim-cache');
      expect(applyStormSpineAction(save, 'claim-cache')).toBe(save); // once only
      save = walk(save, 'logic-core');
    } else if (lane === 'archive') {
      const read = applyStormSpineAction(save, 'read-archive');
      expect(read.stormSpine.archiveRead).toBe(true);
      expect(applyStormSpineAction(read, 'read-archive')).toBe(read); // once
      save = walk(read, 'logic-core');
    }
    expect(getStormSpineBattleConfig(save, 'ice')?.npcId).toBe('logic_bomb');
    expect(applyStormSpineAction(save, 'move', 'discharge-gate')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'logic_bomb'] };
    save = walk(save, 'discharge-gate');
    save = applyStormSpineAction(save, 'claim-clear');
    const reward = PULL_COST + (lane === 'capacitor' ? STORM_SPINE_CACHE_REWARD : 0);
    expect(save.dataScraps).toBe(original.dataScraps + reward);
    expect(save.stats.totalScrapsEarned).toBe(original.stats.totalScrapsEarned + reward);
    expect(applyStormSpineAction(save, 'claim-clear')).toBe(save);
    expect(getStormSpineObjective(save)).toContain('stable');
    expect(original).toEqual(snapshot); // no input mutation
    expect(STORM_SPINE_CLEAR_REWARD).toBe(PULL_COST);
  });

  it('keeps a loss at the encounter checkpoint and permits retreat and retry', () => {
    let save = walk(expedition(), 'live-wire', 'hydra-spine');
    const beforeLoss = getStormSpineBattleConfig(save, 'storm');
    save = { ...save, stats: { ...save.stats, battlesLost: 1 } };
    expect(getStormSpineProgress(save).roomId).toBe('hydra-spine');
    expect(getStormSpineBattleConfig(save, 'storm')).toEqual(beforeLoss);
    save = walk(save, 'live-wire', 'overclock-gantry', 'live-wire', 'hydra-spine');
    expect(getStormSpineBattleConfig(save, 'storm')).toEqual(beforeLoss);
  });

  it('rejects shortcuts, premature rewards, and actions outside their rooms', () => {
    const save = expedition();
    for (const [action, value] of [['move', 'discharge-gate'], ['move', 'constructor'], ['claim-cache'], ['claim-clear'], ['choose-lane', 'direct'], ['read-archive'], ['unknown']]) {
      expect(applyStormSpineAction(save, action, value)).toBe(save);
    }
    const forged = { ...save, stormSpine: { roomId: 'discharge-gate' }, defeatedNpcs: [...save.defeatedNpcs] };
    expect(applyStormSpineAction(forged, 'claim-clear')).toBe(forged);
  });

  it('uses distinct owned party members and refuses unavailable encounters', () => {
    let save = walk(expedition(), 'live-wire', 'hydra-spine');
    expect(getStormSpineBattleConfig(save, 'fire')).toBeNull(); // not owned
    expect(getStormSpineBattleConfig(save, 'unknown')).toBeNull();
    expect(getStormSpineBattleConfig(save, 'storm', 'storm')).toMatchObject({ benchDragonId: null });
    expect(getStormSpineBattleConfig(save, 'storm', 'ice')).toMatchObject({ benchDragonId: 'ice' });
    save = walk(save, 'live-wire', 'overclock-gantry');
    expect(getStormSpineBattleConfig(save, 'storm')).toBeNull(); // shelter has no encounter
  });
});
