import { describe, expect, it } from 'vitest';
import { getPlayerGuidance } from './playerGuidance';

const freshSave = {
  dragons: {
    fire: { owned: false, level: 1 },
    ice: { owned: false, level: 1 },
  },
  defeatedNpcs: [],
  dataScraps: 0,
  inventory: { cores: {} },
};

describe('getPlayerGuidance', () => {
  it('points new players at the first hatch', () => {
    expect(getPlayerGuidance(freshSave)).toMatchObject({
      target: 'hatchery',
      action: 'FREE PULL',
    });
  });

  it('points players with a dragon at the campaign map', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 1 } },
    };

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'map',
      action: 'FIRST BATTLE',
    });
  });

  it('points players with early rewards at upgrades', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 3 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 30,
      inventory: { cores: { stone: 1 } },
    };

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'shop',
      action: 'SPEND REWARDS',
    });
  });

  it('points players at fusion when they have enough lineage and level', () => {
    const save = {
      ...freshSave,
      dragons: {
        ...freshSave.dragons,
        fire: { owned: true, level: 10 },
        ice: { owned: true, level: 3 },
      },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 0,
      inventory: { cores: {} },
    };

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'fusion',
      action: 'FUSE',
    });
  });

  it('points players at singularity when it unlocks', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 7 } },
      defeatedNpcs: ['firewall_sentinel', 'protocol_vulture'],
      dataScraps: 0,
      inventory: { cores: {} },
      singularityProgress: { defeated: [] },
      flags: { currentAct: 3 },
    };

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'singularity',
      action: 'SINGULARITY',
    });
  });

  it('returns no guidance when there is no immediate objective', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 4 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 0,
      inventory: { cores: {} },
      flags: { currentAct: 1 },
    };

    expect(getPlayerGuidance(save)).toBeNull();
  });

  it('shows RETRY after a first loss with no wins', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 1 } },
      stats: { battlesLost: 1, battlesWon: 0 },
    };
    expect(getPlayerGuidance(save)).toMatchObject({ action: 'RETRY' });
  });

  it('shows archive-complete guidance after Mirror Admin defeat', () => {
    const save = { ...freshSave, mirrorAdminDefeated: true };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'journal', action: 'ARCHIVE COMPLETE' });
  });

  it('shows fragment progress after Singularity complete with no fragments collected', () => {
    const save = {
      ...freshSave,
      singularityComplete: true,
      flags: { fragmentsUnlocked: [] },
    };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'singularity', action: 'FRAGMENTS 0/7' });
  });

  it('points at forge when player has enough progression to upgrade', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 5 } },
      defeatedNpcs: ['a', 'b', 'c'],
      skye: { wrenchTier: 1 },
    };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'forge', action: 'VISIT FORGE' });
  });
});
