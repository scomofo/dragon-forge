import { describe, expect, test } from 'vitest';
import {
  CAMPAIGN_NODES,
  getAvailableCampaignNodes,
  getCampaignNodeState,
  getCampaignNodeStates,
  isCampaignNodeCleared,
} from './campaignMap';

function saveWith(defeatedNpcs = []) {
  return {
    defeatedNpcs,
    dragons: {
      shadow: { owned: true, level: 1, xp: 0 },
    },
  };
}

describe('campaign map progression', () => {
  test('starts with the first campaign node available', () => {
    const first = CAMPAIGN_NODES[0];

    expect(getCampaignNodeState(first, saveWith())).toBe('available');
  });

  test('locks nodes when prerequisites are unmet', () => {
    const locked = CAMPAIGN_NODES.find((node) => node.prerequisiteIds.length > 0);

    expect(getCampaignNodeState(locked, saveWith())).toBe('locked');
  });

  test('marks a node cleared when its mapped npc has been defeated', () => {
    const first = CAMPAIGN_NODES[0];

    expect(isCampaignNodeCleared(first, saveWith([first.npcId]))).toBe(true);
    expect(getCampaignNodeState(first, saveWith([first.npcId]))).toBe('cleared');
  });

  test('unlocks downstream nodes when all prerequisites are cleared', () => {
    const downstream = CAMPAIGN_NODES.find((node) => node.prerequisiteIds.length === 1);
    const prerequisite = CAMPAIGN_NODES.find((node) => node.id === downstream.prerequisiteIds[0]);

    expect(getCampaignNodeState(downstream, saveWith([prerequisite.npcId]))).toBe('available');
  });

  test('keeps boss nodes locked until every prerequisite is cleared', () => {
    const boss = CAMPAIGN_NODES.find((node) => node.type === 'boss' && node.prerequisiteIds.length > 1);
    const partialPrereq = boss.prerequisiteIds
      .slice(0, 1)
      .map((id) => CAMPAIGN_NODES.find((node) => node.id === id).npcId);

    expect(getCampaignNodeState(boss, saveWith(partialPrereq))).toBe('locked');
  });

  test('returns available nodes from computed state map', () => {
    const states = getCampaignNodeStates(saveWith());
    const available = getAvailableCampaignNodes(saveWith());

    expect(states[CAMPAIGN_NODES[0].id]).toBe('available');
    expect(available.map((node) => node.id)).toContain(CAMPAIGN_NODES[0].id);
  });
});
