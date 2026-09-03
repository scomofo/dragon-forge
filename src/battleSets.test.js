import { describe, expect, it } from 'vitest';
import { BATTLE_CELL, BATTLE_FRAME_COUNTS, BATTLE_SET_STATUS, DRAGON_BATTLE_SETS, NPC_BATTLE_SETS } from './artBible';
import { JOURNAL_DRAGON_IDS } from './gameData';
import {
  BATTLE_POSES,
  POSE_FRAME_DURATIONS,
  getBattleSetSheetUrl,
  isBattlePose,
  isBattleSetSheetLive,
  listBattleSetSheetUrls,
  normalizeBattlePose,
  resolveBattlePose,
  resolveBattleSprite,
  validateBattleSetSheetUrl,
} from './battleSets';

describe('battle pose resolution', () => {
  it('idles by default', () => {
    expect(resolveBattlePose()).toBe('idle');
    expect(resolveBattlePose({})).toBe('idle');
    expect(resolveBattlePose({ spriteClass: '' })).toBe('idle');
  });

  it('reads telegraph/guard/lunge classes as attack', () => {
    expect(resolveBattlePose({ spriteClass: 'sprite-telegraph' })).toBe('attack');
    expect(resolveBattlePose({ spriteClass: 'sprite-telegraph-heavy' })).toBe('attack');
    expect(resolveBattlePose({ spriteClass: 'sprite-guard' })).toBe('attack');
    expect(resolveBattlePose({ isAttacking: true })).toBe('attack');
  });

  it('reads recoil/critical/status/reflect classes as hurt', () => {
    expect(resolveBattlePose({ spriteClass: 'sprite-recoil' })).toBe('hurt');
    expect(resolveBattlePose({ spriteClass: 'sprite-recoil-heavy' })).toBe('hurt');
    expect(resolveBattlePose({ spriteClass: 'sprite-critical-hit' })).toBe('hurt');
    expect(resolveBattlePose({ spriteClass: 'sprite-status-hit' })).toBe('hurt');
    expect(resolveBattlePose({ spriteClass: 'sprite-reflect-hit' })).toBe('hurt');
  });

  it('reads ko/defeated classes and zero hp as faint', () => {
    expect(resolveBattlePose({ spriteClass: 'sprite-ko' })).toBe('faint');
    expect(resolveBattlePose({ spriteClass: 'sprite-ko-hit' })).toBe('faint');
    expect(resolveBattlePose({ spriteClass: 'sprite-defeated' })).toBe('faint');
    expect(resolveBattlePose({ fainted: true })).toBe('faint');
    expect(resolveBattlePose({ hp: 0, maxHp: 120 })).toBe('faint');
  });

  it('prefers faint over hurt over attack', () => {
    expect(resolveBattlePose({ spriteClass: 'sprite-ko-hit sprite-telegraph', isAttacking: true })).toBe('faint');
    expect(resolveBattlePose({ spriteClass: 'sprite-recoil sprite-telegraph', isAttacking: true })).toBe('hurt');
  });

  it('treats whiff and celebrate as idle', () => {
    expect(resolveBattlePose({ spriteClass: 'sprite-whiff' })).toBe('idle');
    expect(resolveBattlePose({ spriteClass: 'sprite-celebrate' })).toBe('idle');
    expect(resolveBattlePose({ spriteClass: 'unknown-future-class' })).toBe('idle');
  });

  it('normalizes unknown poses to idle', () => {
    expect(normalizeBattlePose('dance')).toBe('idle');
    expect(normalizeBattlePose(null)).toBe('idle');
    for (const pose of BATTLE_POSES) {
      expect(isBattlePose(pose)).toBe(true);
      expect(normalizeBattlePose(pose)).toBe(pose);
    }
  });
});

describe('battle-set sprite resolution', () => {
  it('falls back to portraits for all 18 catalog actors until sheets ship', () => {
    const ids = [...Object.keys(DRAGON_BATTLE_SETS), ...Object.keys(NPC_BATTLE_SETS)];
    expect(ids.length).toBe(18);
    for (const id of ids) {
      expect(isBattleSetSheetLive(id)).toBe(false);
      for (const pose of BATTLE_POSES) {
        const resolved = resolveBattleSprite(id, pose);
        expect(resolved.kind, `${id} ${pose}`).toBe('portrait');
        expect(resolved.src, `${id} ${pose}`).toBe(null);
        expect(resolved.cell, `${id} ${pose}`).toBe(BATTLE_CELL.mid);
        expect(resolved.frames, `${id} ${pose}`).toBe(BATTLE_FRAME_COUNTS[pose]);
      }
    }
  });

  it('falls back to portraits for unknown, null, and boss actors', () => {
    expect(resolveBattleSprite('the_singularity', 'attack').kind).toBe('portrait');
    expect(resolveBattleSprite('mirror_admin', 'hurt').kind).toBe('portrait');
    expect(resolveBattleSprite('not-a-dragon', 'idle').kind).toBe('portrait');
    expect(resolveBattleSprite(null, 'idle').kind).toBe('portrait');
    expect(resolveBattleSprite(undefined, 'faint').pose).toBe('faint');
  });

  it('resolves a shippable sheet the moment a set flips to shipped', () => {
    const spec = DRAGON_BATTLE_SETS[JOURNAL_DRAGON_IDS[0]];
    const prev = spec.status;
    spec.status = BATTLE_SET_STATUS.SHIPPED;
    try {
      expect(isBattleSetSheetLive(JOURNAL_DRAGON_IDS[0])).toBe(true);
      const resolved = resolveBattleSprite(JOURNAL_DRAGON_IDS[0], 'attack');
      expect(resolved.kind).toBe('sheet');
      expect(resolved.src).toContain(`battle-sets/${JOURNAL_DRAGON_IDS[0]}_attack`);
      expect(resolved.cell).toBe(BATTLE_CELL.mid);
      expect(resolved.frames).toBe(BATTLE_FRAME_COUNTS.attack);
    } finally {
      spec.status = prev;
    }
    expect(isBattleSetSheetLive(JOURNAL_DRAGON_IDS[0])).toBe(false);
  });

  it('keeps every future sheet URL inside battle-sets with no banned language', () => {
    const urls = listBattleSetSheetUrls();
    expect(urls.length).toBe(18 * BATTLE_POSES.length);
    expect(new Set(urls).size).toBe(urls.length);
    for (const url of urls) {
      expect(validateBattleSetSheetUrl(url), url).toBe(null);
      expect(url.includes('.webp')).toBe(true);
    }
  });

  it('defines per-pose playback durations', () => {
    for (const pose of BATTLE_POSES) {
      expect(POSE_FRAME_DURATIONS[pose]).toBeGreaterThan(0);
    }
    expect(POSE_FRAME_DURATIONS.attack).toBeLessThan(POSE_FRAME_DURATIONS.idle);
  });
});
