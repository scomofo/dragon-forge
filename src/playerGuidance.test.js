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

function todaySeed() {
  const now = new Date();
  return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
}

// Mark the daily as done so tests below exercise the branch they name (the
// open-daily branch outranks forge/fusion/shop/campaign continuation).
function dailyDone(save) {
  return { ...save, lastDailyCompleted: todaySeed() };
}

describe('getPlayerGuidance', () => {
  it('points new players at the first hatch', () => {
    expect(getPlayerGuidance(freshSave)).toMatchObject({
      target: 'hatchery',
      action: 'FREE PULL',
    });
  });

  it('points players with a first guardian at the Outer Grid opening', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 1 } },
    };

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'outerGrid',
      action: 'EXPLORE',
    });
  });

  it('points players with spendable rewards at the shop', () => {
    const save = dailyDone({
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 3 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 120,
      inventory: { cores: { stone: 1 } },
    });

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'shop',
      action: 'SPEND REWARDS',
    });
  });

  it('does not point at the shop when nothing is affordable', () => {
    const save = dailyDone({
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 3 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 30,
      inventory: { cores: { stone: 1 } },
    });

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'map',
      action: 'CONTINUE',
    });
  });

  it('points players at fusion when they have enough lineage and level', () => {
    const save = dailyDone({
      ...freshSave,
      dragons: {
        ...freshSave.dragons,
        fire: { owned: true, level: 10 },
        ice: { owned: true, level: 3 },
      },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 0,
      inventory: { cores: {} },
    });

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'fusion',
      action: 'FUSE',
    });
  });

  it('points players at singularity when it unlocks', () => {
    const save = dailyDone({
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 7 } },
      defeatedNpcs: ['firewall_sentinel', 'protocol_vulture'],
      dataScraps: 0,
      inventory: { cores: {} },
      singularityProgress: { defeated: [] },
      flags: { currentAct: 3 },
    });

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'singularity',
      action: 'SINGULARITY',
    });
  });

  it('points at the next campaign node when nothing else is actionable', () => {
    const save = dailyDone({
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 4 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 0,
      inventory: { cores: {} },
      flags: { currentAct: 1 },
    });

    expect(getPlayerGuidance(save)).toMatchObject({
      target: 'map',
      action: 'CONTINUE',
    });
  });

  it('shows RETRY after a first loss with no wins', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 1 } },
      stats: { battlesLost: 1, battlesWon: 0 },
    };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'outerGrid', action: 'RETRY' });
  });

  it('keeps an entered Outer Grid route ahead of the daily until its reward is collected', () => {
    const save = {
      ...freshSave,
      dragons: { fire: { owned: true, level: 3 } },
      defeatedNpcs: ['firewall_sentinel'],
      outerGrid: { roomId: 'firewall-span', visited: ['signal-breach'] },
    };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'outerGrid', action: 'CONTINUE ROUTE' });
    save.defeatedNpcs.push('buffer_overflow');
    expect(getPlayerGuidance(save).title).toContain('Return Gate');
    save.outerGrid.rewardClaimed = true;
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'battleSelect', action: 'DAILY OPEN' });
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
    const save = dailyDone({
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 5 } },
      defeatedNpcs: ['a', 'b', 'c'],
      skye: { wrenchTier: 1 },
    });
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'forge', action: 'VISIT FORGE' });
  });

  it('surfaces an open Daily Challenge once the player is battling', () => {
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 5 } },
      defeatedNpcs: ['firewall_sentinel'],
      lastDailyCompleted: 19990101, // some other day — today's is open
    };
    expect(getPlayerGuidance(save)).toMatchObject({ target: 'battleSelect', action: 'DAILY OPEN' });
  });

  it('does not surface the daily after it is completed today', () => {
    const now = new Date();
    const todaySeed = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
    const save = {
      ...freshSave,
      dragons: { ...freshSave.dragons, fire: { owned: true, level: 4 } },
      defeatedNpcs: ['firewall_sentinel'],
      dataScraps: 0,
      inventory: { cores: {} },
      flags: { currentAct: 1 },
      lastDailyCompleted: todaySeed,
    };
    const guidance = getPlayerGuidance(save);
    expect(guidance.action).not.toBe('DAILY OPEN');
  });

  it('keeps the daily out of the way for brand-new players (first hatch/battle first)', () => {
    expect(getPlayerGuidance(freshSave).action).not.toBe('DAILY OPEN');
  });
});
