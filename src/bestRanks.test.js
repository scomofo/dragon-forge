import { describe, it, expect } from 'vitest';
import { getUpgradedRank, getBestRanks, countSRanks } from './persistence';
import { checkMilestones } from './journalMilestones';
import { CAMPAIGN_NODES } from './campaignMap';

function dragon(props = {}) {
  return { level: 1, xp: 0, owned: false, discovered: false, shiny: false, fusedBaseStats: null, ...props };
}
const ELEMENTS = ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow', 'void', 'light', 'synthesis'];
function roster() {
  return Object.fromEntries(ELEMENTS.map(e => [e, dragon()]));
}
function saveWith(bestRanks) {
  return { dragons: roster(), milestones: [], bestRanks };
}

describe('getUpgradedRank', () => {
  it('upgrades to a better rank, keeps the better of two', () => {
    expect(getUpgradedRank(undefined, 'B')).toBe('B');
    expect(getUpgradedRank('B', 'A')).toBe('A');
    expect(getUpgradedRank('A', 'C')).toBe('A');
    expect(getUpgradedRank('S', 'A')).toBe('S');
    expect(getUpgradedRank('C', 'S')).toBe('S');
  });

  it('countSRanks counts only S entries', () => {
    expect(countSRanks({ bestRanks: { a: 'S', b: 'S', c: 'A' } })).toBe(2);
    expect(getBestRanks({ bestRanks: { a: 'S' } }).a).toBe('S');
  });
});

describe('rank_perfect milestone', () => {
  it('is unmet until every campaign NPC has an S rank', () => {
    const partial = CAMPAIGN_NODES.slice(0, -1).reduce((acc, node) => ({ ...acc, [node.npcId]: 'S' }), {});
    const result = checkMilestones(saveWith(partial)).find(m => m.id === 'rank_perfect');
    expect(result.newlyClaimed).toBe(false);
    expect(result.progress).toBe(`${CAMPAIGN_NODES.length - 1}/${CAMPAIGN_NODES.length}`);
  });

  it('claims when all campaign NPCs hold an S', () => {
    const full = CAMPAIGN_NODES.reduce((acc, node) => ({ ...acc, [node.npcId]: 'S' }), {});
    const result = checkMilestones(saveWith(full)).find(m => m.id === 'rank_perfect');
    expect(result.newlyClaimed).toBe(true);
  });
});
