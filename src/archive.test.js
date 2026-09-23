import { describe, it, expect } from 'vitest';
import { getArchiveEntries, getArchiveCompletion, ARCHIVE_GROUPS } from './ArchiveScreen';
import {
  SINGULARITY_BOSSES,
  FINAL_BOSS,
  MIRROR_ADMIN,
  CORRUPTION_REMNANTS,
} from './singularityBosses';
import { CAPTAINS_LOG_FRAGMENTS } from './forgeData';

function emptySave(overrides = {}) {
  return {
    singularityProgress: { defeated: [], finalBossPhase: 0, replayCounts: {} },
    singularityComplete: false,
    mirrorAdminDefeated: false,
    remnantDefeated: [],
    ngPlusRemnantClears: [],
    flags: { fragmentsUnlocked: [] },
    ...overrides,
  };
}

describe('archive unlock mapping', () => {
  it('starts fully locked: 0/16 with every entry a silhouette', () => {
    const entries = getArchiveEntries(emptySave());
    const all = [...entries.bosses, ...entries.remnants, ...entries.fragments, ...entries.beats];
    expect(all.length).toBe(16);
    expect(all.every((e) => e.unlocked === false)).toBe(true);
    const { unlocked, total, pct } = getArchiveCompletion(entries);
    expect(unlocked).toBe(0);
    expect(total).toBe(16);
    expect(pct).toBe(0);
  });

  it('boss entries unlock from singularityProgress.defeated and carry boss lore', () => {
    const entries = getArchiveEntries(emptySave({
      singularityProgress: { defeated: ['data_corruption'], finalBossPhase: 0, replayCounts: {} },
    }));
    expect(entries.bosses).toHaveLength(SINGULARITY_BOSSES.length);
    const boss = entries.bosses.find((e) => e.id === 'data_corruption');
    expect(boss.unlocked).toBe(true);
    expect(boss.body).toBe(SINGULARITY_BOSSES.find((b) => b.id === 'data_corruption').felixQuote);
    const other = entries.bosses.find((e) => e.id === 'memory_leak');
    expect(other.unlocked).toBe(false);
  });

  it('remnant entries unlock from remnantDefeated and flag ascendant NG+ clears', () => {
    const remnantId = CORRUPTION_REMNANTS[0].id;
    const entries = getArchiveEntries(emptySave({
      remnantDefeated: [remnantId],
      ngPlusRemnantClears: [remnantId],
    }));
    expect(entries.remnants).toHaveLength(CORRUPTION_REMNANTS.length);
    const remnant = entries.remnants.find((e) => e.id === remnantId);
    expect(remnant.unlocked).toBe(true);
    expect(remnant.ascendant).toBe(true);
    expect(remnant.body).toBe(CORRUPTION_REMNANTS[0].felixQuote);
    // Cleared in the first loop only: no ascendant tag.
    const plain = getArchiveEntries(emptySave({ remnantDefeated: [remnantId] }));
    expect(plain.remnants.find((e) => e.id === remnantId).ascendant).toBe(false);
  });

  it('fragment entries unlock from flags.fragmentsUnlocked with decrypted bodies', () => {
    const entries = getArchiveEntries(emptySave({ flags: { fragmentsUnlocked: ['001'] } }));
    expect(entries.fragments).toHaveLength(CAPTAINS_LOG_FRAGMENTS.length);
    const frag = entries.fragments.find((e) => e.id === 'fragment_001');
    expect(frag.unlocked).toBe(true);
    expect(frag.body).toBe(CAPTAINS_LOG_FRAGMENTS.find((f) => f.id === '001').body);
    const locked = entries.fragments.find((e) => e.id === 'fragment_002');
    expect(locked.unlocked).toBe(false);
  });

  it('Mirror Admin beats unlock from singularityComplete / mirrorAdminDefeated', () => {
    const none = getArchiveEntries(emptySave());
    expect(none.beats.find((e) => e.id === 'the_singularity').unlocked).toBe(false);
    expect(none.beats.find((e) => e.id === 'mirror_admin').unlocked).toBe(false);

    const sing = getArchiveEntries(emptySave({ singularityComplete: true }));
    const theSingularity = sing.beats.find((e) => e.id === 'the_singularity');
    expect(theSingularity.unlocked).toBe(true);
    expect(theSingularity.body).toBe(FINAL_BOSS.felixQuote);
    expect(sing.beats.find((e) => e.id === 'mirror_admin').unlocked).toBe(false);

    const mirror = getArchiveEntries(emptySave({ singularityComplete: true, mirrorAdminDefeated: true }));
    const admin = mirror.beats.find((e) => e.id === 'mirror_admin');
    expect(admin.unlocked).toBe(true);
    expect(admin.body).toContain(MIRROR_ADMIN.felixQuote);
    for (const line of MIRROR_ADMIN.phaseLines) expect(admin.body).toContain(line);
  });

  it('completion % tracks unlocked/total across all four groups', () => {
    const entries = getArchiveEntries(emptySave({
      singularityProgress: { defeated: ['data_corruption', 'memory_leak'], finalBossPhase: 0, replayCounts: {} },
      flags: { fragmentsUnlocked: ['001', '002', '003'] },
      singularityComplete: true,
      mirrorAdminDefeated: true,
      remnantDefeated: [CORRUPTION_REMNANTS[0].id],
    }));
    // 2 bosses + 1 remnant + 3 fragments + 2 beats = 8 of 16
    const { unlocked, total, pct } = getArchiveCompletion(entries);
    expect(unlocked).toBe(8);
    expect(total).toBe(16);
    expect(pct).toBe(50);
  });

  it('defines the four required groups: Bosses, Remnants, Fragments, Mirror Admin beats', () => {
    expect(ARCHIVE_GROUPS.map((g) => g.id)).toEqual(['bosses', 'remnants', 'fragments', 'beats']);
  });
});
