import { describe, expect, it } from 'vitest';
import { getCampaignNodeById } from './campaignMap';
import { PULL_COST } from './gameData';
import { FROZEN_CACHE_ROOMS, WORLD_ZONES } from './worldZones';
import { applyFrozenCacheAction, getFrozenCacheBattleConfig, getFrozenCacheExits, getFrozenCacheObjective, getFrozenCacheProgress, FROZEN_CACHE_VAULT_REWARD, FROZEN_CACHE_CLEAR_REWARD } from './frozenCache';

function expedition() {
  return {
    dragons: { fire: { owned: true, level: 3 }, ice: { owned: true, level: 3 }, storm: { owned: false, level: 1 } },
    defeatedNpcs: ['firewall_sentinel'], dataScraps: 9, stats: { totalScrapsEarned: 20, battlesLost: 0 },
  };
}

function walk(save, ...rooms) {
  return rooms.reduce((current, room) => {
    const next = applyFrozenCacheAction(current, 'move', room);
    expect(next, `Passage to ${room}`).not.toBe(current);
    expect(next.frozenCache.roomId).toBe(room);
    return next;
  }, save);
}

describe('Frozen Cache authored route', () => {
  it('connects every exit and keeps zone nodes inside the zone', () => {
    for (const room of Object.values(FROZEN_CACHE_ROOMS)) {
      for (const exit of room.exits) expect(FROZEN_CACHE_ROOMS[exit.to], `${room.id} → ${exit.to}`).toBeDefined();
      if (room.nodeId) expect(getCampaignNodeById(room.nodeId).zoneId).toBe('frozen_cache');
    }
    expect(WORLD_ZONES.frozen_cache.nodeIds).toEqual(['wraith-cache', 'crypto-lock', 'siren-loop']);
  });

  it('stays shut until the Outer Grid gatekeeper falls, and always needs a guardian', () => {
    for (const dragons of [{}, { fire: { owned: false } }, { unknown: { owned: true } }]) {
      const save = { ...expedition(), dragons };
      expect(getFrozenCacheExits(save)[0].open).toBe(false);
      expect(applyFrozenCacheAction(save, 'move', 'mute-channel')).toBe(save);
    }
    const noGatekeeper = { ...expedition(), defeatedNpcs: [] };
    expect(getFrozenCacheExits(noGatekeeper)[0].open).toBe(false);
    expect(getFrozenCacheObjective(noGatekeeper)).toContain('gatekeeper');
  });

  it.each(['thaw', 'crack'])('completes the %s crossing without repeat battles or repeat rewards', route => {
    const original = expedition();
    const snapshot = structuredClone(original);
    let save = walk(original, 'mute-channel', 'wraith-cache');
    expect(getFrozenCacheBattleConfig(save, 'fire', 'ice')).toEqual({
      nodeId: 'wraith-cache', npcId: 'bit_wraith', dragonId: 'fire', benchDragonId: 'ice', returnScreen: 'frozenCache',
    });
    // The junction is shut until the wraith is quiet.
    expect(applyFrozenCacheAction(save, 'move', 'thaw-junction')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'bit_wraith'] };
    expect(getFrozenCacheBattleConfig(save, 'fire')).toBeNull(); // already quiet
    save = walk(save, 'thaw-junction');
    expect(applyFrozenCacheAction(save, 'move', 'siren-loop')).toBe(save); // route not chosen
    expect(applyFrozenCacheAction(save, 'move', 'frozen-vault')).toBe(save);
    save = applyFrozenCacheAction(save, 'choose-route', route);
    expect(applyFrozenCacheAction(save, 'choose-route', route === 'thaw' ? 'crack' : 'thaw')).toBe(save);
    if (route === 'crack') {
      save = walk(save, 'frozen-vault');
      save = applyFrozenCacheAction(save, 'claim-vault');
      expect(applyFrozenCacheAction(save, 'claim-vault')).toBe(save); // once only
      save = walk(save, 'siren-loop');
    } else {
      expect(applyFrozenCacheAction(save, 'move', 'frozen-vault')).toBe(save);
      save = walk(save, 'siren-loop');
    }
    expect(getFrozenCacheBattleConfig(save, 'ice')?.npcId).toBe('phishing_siren');

    // The lock needs both the siren and the Outer Grid finale.
    expect(applyFrozenCacheAction(save, 'move', 'crypto-lock')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'phishing_siren'] };
    expect(applyFrozenCacheAction(save, 'move', 'crypto-lock')).toBe(save); // still needs buffer_overflow
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'buffer_overflow'] };
    save = walk(save, 'crypto-lock');
    expect(getFrozenCacheBattleConfig(save, 'ice')?.npcId).toBe('crypto_crab');
    expect(applyFrozenCacheAction(save, 'move', 'thaw-gate')).toBe(save);
    save = { ...save, defeatedNpcs: [...save.defeatedNpcs, 'crypto_crab'] };
    save = walk(save, 'thaw-gate');
    save = applyFrozenCacheAction(save, 'claim-clear');
    const reward = PULL_COST + (route === 'crack' ? FROZEN_CACHE_VAULT_REWARD : 0);
    expect(save.dataScraps).toBe(original.dataScraps + reward);
    expect(save.stats.totalScrapsEarned).toBe(original.stats.totalScrapsEarned + reward);
    expect(applyFrozenCacheAction(save, 'claim-clear')).toBe(save);
    expect(getFrozenCacheObjective(save)).toContain('stable');
    expect(original).toEqual(snapshot); // no input mutation
    expect(FROZEN_CACHE_CLEAR_REWARD).toBe(PULL_COST);
  });

  it('hears each talking remnant once, only inside the Cold Archive', () => {
    let save = expedition();
    for (let i = 0; i < 3; i += 1) {
      const heard = applyFrozenCacheAction(save, 'hear-remnant', i);
      expect(heard.frozenCache.remnantsHeard).toContain(i);
      expect(applyFrozenCacheAction(heard, 'hear-remnant', i)).toBe(heard); // no replay
      save = heard;
    }
    expect(applyFrozenCacheAction(save, 'hear-remnant', 3)).toBe(save); // out of range
    const elsewhere = walk(save, 'mute-channel');
    expect(applyFrozenCacheAction(elsewhere, 'hear-remnant', 0)).toBe(elsewhere); // wrong room
  });

  it('keeps a loss at the encounter checkpoint and permits retreat and retry', () => {
    let save = walk(expedition(), 'mute-channel', 'wraith-cache');
    const beforeLoss = getFrozenCacheBattleConfig(save, 'fire');
    save = { ...save, stats: { ...save.stats, battlesLost: 1 } };
    expect(getFrozenCacheProgress(save).roomId).toBe('wraith-cache');
    expect(getFrozenCacheBattleConfig(save, 'fire')).toEqual(beforeLoss);
    save = walk(save, 'mute-channel', 'cold-archive', 'mute-channel', 'wraith-cache');
    expect(getFrozenCacheBattleConfig(save, 'fire')).toEqual(beforeLoss);
  });

  it('rejects shortcuts, premature rewards, and actions outside their rooms', () => {
    const save = expedition();
    for (const [action, value] of [['move', 'thaw-gate'], ['move', 'constructor'], ['claim-vault'], ['claim-clear'], ['choose-route', 'thaw'], ['unknown']]) {
      expect(applyFrozenCacheAction(save, action, value)).toBe(save);
    }
    // A forged checkpoint without the boss defeat still cannot claim.
    const forged = { ...save, frozenCache: { roomId: 'thaw-gate' }, defeatedNpcs: ['firewall_sentinel'] };
    expect(applyFrozenCacheAction(forged, 'claim-clear')).toBe(forged);
  });

  it('uses distinct owned party members and refuses unavailable encounters', () => {
    let save = walk(expedition(), 'mute-channel', 'wraith-cache');
    expect(getFrozenCacheBattleConfig(save, 'storm')).toBeNull(); // not owned
    expect(getFrozenCacheBattleConfig(save, 'unknown')).toBeNull();
    expect(getFrozenCacheBattleConfig(save, 'fire', 'fire')).toMatchObject({ benchDragonId: null }); // no self-reserve
    expect(getFrozenCacheBattleConfig(save, 'fire', 'ice')).toMatchObject({ benchDragonId: 'ice' });
    // No encounter in the shelter.
    save = walk(save, 'mute-channel', 'cold-archive');
    expect(getFrozenCacheBattleConfig(save, 'fire')).toBeNull();
  });
});
