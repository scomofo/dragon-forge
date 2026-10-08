import { describe, expect, it } from 'vitest';
import {
  QUESTS,
  ELEMENT_AWAKENING,
  getAwakeningLine,
  getQuestById,
  isQuestComplete,
  getQuestProgress,
  getAvailableQuests,
  getTrackedQuest,
  getTrackedStep,
  applyQuestCompletion,
  rollRecorruption,
  isRecorrupted,
  clearRecorruption,
  countOwnedDragons,
  countCores,
} from './quests';
import { OPENING_BOOT_LINES } from './loreCanon';

function makeSave(overrides = {}) {
  return {
    dragons: {
      fire: { owned: false, level: 1 },
      ice: { owned: false, level: 1 },
      storm: { owned: false, level: 1 },
      stone: { owned: false, level: 1 },
      venom: { owned: false, level: 1 },
      shadow: { owned: false, level: 1 },
    },
    defeatedNpcs: [],
    inventory: { cores: {} },
    stats: { battlesWon: 0 },
    flags: { metFelix: false, journalBriefingSeen: false, fragmentsUnlocked: [] },
    skye: { wrenchTier: 1, relicsOwned: [], bountiesCleared: 0 },
    titles: [],
    equippedTitle: null,
    quests: { completed: [], seen: {}, recorrupted: [], adminNoticed: false },
    ...overrides,
  };
}

describe('quest registry', () => {
  it('covers Act I Beats 2-9 in spine order', () => {
    expect(QUESTS.map((q) => q.beat)).toEqual([2, 3, 4, 5, 6, 7, 8, 9]);
    expect(QUESTS.map((q) => q.id)).toEqual([
      'dead-memory', 'protocol-online', 'weaver-distress', 'captains-log',
      'analog-bypass', 'friction-saddle', 'southern-partition', 'threat-model',
    ]);
  });

  it('every quest has a what-next, briefing, and subtasks with targets', () => {
    for (const q of QUESTS) {
      expect(q.title, q.id).toBeTruthy();
      expect(q.briefing, q.id).toBeTruthy();
      expect(q.whatNext, q.id).toBeTruthy();
      expect(q.completeText, q.id).toBeTruthy();
      expect(q.subtasks.length, q.id).toBeGreaterThan(0);
      for (const st of q.subtasks) {
        expect(st.target, `${q.id}/${st.id}`).toBeTruthy();
        expect(st.action, `${q.id}/${st.id}`).toBeTruthy();
        expect(st.why, `${q.id}/${st.id}`).toBeTruthy();
        expect(typeof st.check).toBe('function');
      }
    }
  });

  it('getQuestById finds quests and returns null for unknown ids', () => {
    expect(getQuestById('dead-memory').beat).toBe(2);
    expect(getQuestById('nope')).toBeNull();
  });
});

describe('quest state machine', () => {
  it('fresh save: dead-memory is the tracked quest at its first step', () => {
    const save = makeSave();
    const tracked = getTrackedQuest(save);
    expect(tracked.quest.id).toBe('dead-memory');
    expect(tracked.status).toBe('active');
    const step = getTrackedStep(save);
    expect(step.quest.id).toBe('dead-memory');
    expect(step.step.id).toBe('hatch');
    expect(step.step.target).toBe('hatchery');
  });

  it('subtask progress derives from live state', () => {
    const save = makeSave({ dragons: { fire: { owned: true, level: 1 } } });
    const p = getQuestProgress(getQuestById('dead-memory'), save);
    expect(p.subtasks.find((s) => s.id === 'hatch').done).toBe(true);
    expect(p.subtasks.find((s) => s.id === 'first-battle').done).toBe(false);
    expect(p.done).toBe(false);
    expect(p.status).toBe('active');
  });

  it('gates later quests behind earlier completion', () => {
    const save = makeSave({ dragons: { fire: { owned: true, level: 7 } } });
    // weaver-distress needs a fire dragon: available and active (Stage 1 so far)
    expect(getQuestProgress(getQuestById('weaver-distress'), save).status).toBe('active');
    // analog-bypass needs weaver-distress completed: locked
    expect(getQuestProgress(getQuestById('analog-bypass'), save).status).toBe('locked');
    // southern-partition needs both analog-bypass and friction-saddle: locked
    expect(getQuestProgress(getQuestById('southern-partition'), save).status).toBe('locked');
  });

  it('a fully-satisfied quest reports complete even before recording', () => {
    const save = makeSave({
      dragons: { fire: { owned: true, level: 1 } },
      stats: { battlesWon: 2 },
      flags: { metFelix: true, journalBriefingSeen: false, fragmentsUnlocked: [] },
    });
    const p = getQuestProgress(getQuestById('dead-memory'), save);
    expect(p.done).toBe(true);
    expect(p.status).toBe('complete');
    expect(isQuestComplete(save, 'dead-memory')).toBe(false);
  });

  it('tracked quest advances through the spine in order', () => {
    const save = makeSave({
      dragons: { fire: { owned: true, level: 1 } },
      stats: { battlesWon: 1 },
      flags: { metFelix: true, journalBriefingSeen: false, fragmentsUnlocked: [] },
      quests: { completed: ['dead-memory'], seen: {}, recorrupted: [], adminNoticed: false },
    });
    // protocol-online is available (owns a dragon) and its witness step is undone
    expect(getTrackedQuest(save).quest.id).toBe('protocol-online');
  });
});

describe('quest rewards', () => {
  it('dead-memory grants the Worldkeeper title', () => {
    const save = makeSave();
    const text = applyQuestCompletion(save, getQuestById('dead-memory'));
    expect(save.quests.completed).toContain('dead-memory');
    expect(save.titles).toContain('worldkeeper');
    expect(save.equippedTitle).toBe('worldkeeper');
    expect(text).toContain('Worldkeeper');
  });

  it('friction-saddle grants the relic without duplicating', () => {
    const save = makeSave();
    applyQuestCompletion(save, getQuestById('friction-saddle'));
    applyQuestCompletion(save, getQuestById('friction-saddle'));
    expect(save.skye.relicsOwned.filter((r) => r === 'friction_saddle')).toHaveLength(1);
  });

  it('threat-model arms the Admin threat model and rolls ambushes', () => {
    const save = makeSave({
      defeatedNpcs: ['firewall_sentinel', 'buffer_overflow', 'bit_wraith'],
      quests: { completed: [], seen: {}, recorrupted: [], adminNoticed: false },
    });
    const text = applyQuestCompletion(save, getQuestById('threat-model'));
    expect(save.quests.adminNoticed).toBe(true);
    expect(save.quests.recorrupted.length).toBeGreaterThan(0);
    expect(save.quests.recorrupted.length).toBeLessThanOrEqual(2);
    expect(text).toContain('threat model');
  });
});

describe('rollback ambushes (Beat 9 bridge)', () => {
  it('rolls at most 2 cleared nodes, deterministically with injected rng', () => {
    const save = makeSave({ defeatedNpcs: ['firewall_sentinel', 'buffer_overflow', 'bit_wraith', 'crypto_crab'] });
    // A fixed rng keeps the Fisher-Yates shuffle deterministic.
    const picked = rollRecorruption(save, () => 0.99);
    expect(picked.length).toBeGreaterThan(0);
    expect(picked.length).toBeLessThanOrEqual(2);
    expect(isRecorrupted(save, picked[0])).toBe(true);
    // A second roll never re-picks or duplicates.
    const again = rollRecorruption(save, () => 0.0);
    const overlap = again.filter((id) => picked.includes(id));
    expect(overlap).toHaveLength(0);
  });

  it('only cleared campaign nodes are eligible', () => {
    const save = makeSave({ defeatedNpcs: ['not_a_campaign_npc'] });
    expect(rollRecorruption(save, () => 0)).toHaveLength(0);
  });

  it('clearRecorruption removes the flag once re-cleared', () => {
    const save = makeSave({ defeatedNpcs: ['firewall_sentinel'] });
    rollRecorruption(save, () => 0);
    const target = save.quests.recorrupted[0];
    expect(isRecorrupted(save, target)).toBe(true);
    expect(clearRecorruption(save, target)).toBe(true);
    expect(isRecorrupted(save, target)).toBe(false);
    expect(clearRecorruption(save, target)).toBe(false);
  });
});

describe('helpers', () => {
  it('counts owned dragons and cores', () => {
    const save = makeSave({
      dragons: { fire: { owned: true, level: 5 }, ice: { owned: false, level: 1 } },
      inventory: { cores: { fire: 2, ice: 1 } },
    });
    expect(countOwnedDragons(save)).toBe(1);
    expect(countCores(save)).toBe(3);
  });

  it('weaver-distress needs a Stage 2+ fire dragon (Magma-Core form)', () => {
    const low = makeSave({ dragons: { fire: { owned: true, level: 7 } } });
    const high = makeSave({ dragons: { fire: { owned: true, level: 8 } } });
    const q = getQuestById('weaver-distress');
    expect(getQuestProgress(q, low).done).toBe(false);
    expect(getQuestProgress(q, high).done).toBe(true);
  });

  it('captains-log needs both fragments read via the briefing tab', () => {
    const q = getQuestById('captains-log');
    const unread = makeSave({ flags: { metFelix: true, journalBriefingSeen: true, fragmentsUnlocked: ['001'] } });
    expect(getQuestProgress(q, unread).done).toBe(false);
    const read = makeSave({ flags: { metFelix: true, journalBriefingSeen: true, fragmentsUnlocked: ['001', '002'] } });
    expect(getQuestProgress(q, read).done).toBe(true);
  });

  it('southern-partition needs the Recursive Golem defeated', () => {
    const q = getQuestById('southern-partition');
    const before = makeSave({ defeatedNpcs: ['glitch_hydra'] });
    expect(getQuestProgress(q, before).subtasks[0].done).toBe(false);
    const after = makeSave({ defeatedNpcs: ['recursive_golem'] });
    expect(getQuestProgress(q, after).subtasks[0].done).toBe(true);
  });
});

describe('Beat 1 boot sequence', () => {
  it('types seven system lines, one of them Skye by name', () => {
    expect(OPENING_BOOT_LINES).toHaveLength(7);
    expect(OPENING_BOOT_LINES.some((l) => l.text.includes('OPERATOR SIGNAL FOUND: SKYE'))).toBe(true);
  });
});

describe('Beat 3 awakening flavor', () => {
  it('names each base element’s Matrix job', () => {
    for (const el of ['fire', 'ice', 'storm', 'stone', 'venom', 'shadow']) {
      expect(ELEMENT_AWAKENING[el], el).toBeTruthy();
    }
    expect(getAwakeningLine('fire')).toContain('renews');
    expect(getAwakeningLine('ice')).toContain('preserves');
  });

  it('falls back for unknown elements', () => {
    expect(getAwakeningLine('bogus')).toBe(ELEMENT_AWAKENING.fire);
  });
});

describe('getAvailableQuests', () => {
  it('excludes locked quests on a fresh save', () => {
    const ids = getAvailableQuests(makeSave()).map((p) => p.quest.id);
    expect(ids).toContain('dead-memory');
    expect(ids).not.toContain('analog-bypass');
    expect(ids).not.toContain('threat-model');
  });
});
