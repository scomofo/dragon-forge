import { describe, expect, it } from 'vitest';
import { dragons, moves, JOURNAL_DRAGON_IDS } from './gameData';
import {
  BANNED_ART_SUBSTRINGS,
  BATTLE_FRAME_COUNTS,
  BODY_PLANS,
  getBodyPlan,
  uniqueSilhouettes,
} from './artBible';
import { ACTOR_CONTRACT, VFX_FRAMES, VFX_PLACEHOLDERS } from './sprites';
import { WORLD_ZONE_IDS, WORLD_ZONES, getZoneForNode } from './worldZones';
import { BOSS_PATTERNS } from './bossPatterns';
import { CAMPAIGN_NODES } from './campaignMap';

describe('art bible', () => {
  it('gives every journal dragon a unique body-plan silhouette', () => {
    for (const id of JOURNAL_DRAGON_IDS) {
      expect(getBodyPlan(id), id).toBeTruthy();
      expect(dragons[id], id).toBeTruthy();
    }
    const silhouettes = uniqueSilhouettes();
    expect(new Set(silhouettes).size).toBe(silhouettes.length);
    expect(Object.keys(BODY_PLANS)).toEqual(JOURNAL_DRAGON_IDS);
  });

  it('declares stage portraits as single-frame until real sheets exist', () => {
    expect(ACTOR_CONTRACT.stagePortraitsAreSingleFrame).toBe(true);
    expect(BATTLE_FRAME_COUNTS.idle).toBe(4);
    expect(BATTLE_FRAME_COUNTS.attack).toBe(6);
  });

  it('reserves a distinct VFX key for every signature and tracks placeholders', () => {
    const signatures = Object.values(moves).filter((move) => move.isSignature);
    expect(signatures.length).toBeGreaterThanOrEqual(8);
    for (const move of signatures) {
      expect(move.vfxKey, move.name).toBeTruthy();
      const key = move.vfxKey;
      const hasStrip = VFX_FRAMES[key]?.strip?.src || VFX_FRAMES[key] === null;
      const isPlaceholder = Object.prototype.hasOwnProperty.call(VFX_PLACEHOLDERS, key);
      expect(hasStrip || isPlaceholder, `${move.name} ${key}`).toBe(true);
    }
  });

  it('bans printed-error and watermark language in actor paths', () => {
    const urls = [];
    for (const dragon of Object.values(dragons)) {
      urls.push(dragon.spriteSheet, ...Object.values(dragon.stageSprites || {}));
    }
    const haystack = urls.join(' ').toLowerCase();
    for (const banned of BANNED_ART_SUBSTRINGS) {
      expect(haystack.includes(banned)).toBe(false);
    }
  });
});

describe('four-zone cartridge skeleton', () => {
  it('maps every campaign node onto one of the four authored zones', () => {
    expect(WORLD_ZONE_IDS).toEqual(['outer_grid', 'frozen_cache', 'storm_spine', 'admin_core']);
    for (const node of CAMPAIGN_NODES) {
      expect(node.zoneId, node.id).toBeTruthy();
      expect(WORLD_ZONE_IDS).toContain(node.zoneId);
      expect(getZoneForNode(node.id)?.id).toBe(node.zoneId);
    }
    const used = new Set(CAMPAIGN_NODES.map((node) => node.zoneId));
    expect(used.size).toBe(WORLD_ZONE_IDS.length);
    for (const zone of Object.values(WORLD_ZONES)) {
      expect(zone.setpiece).toBeTruthy();
      expect(zone.bossNodeId).toBeTruthy();
    }
  });
});

describe('boss pattern authorship', () => {
  it('defines twelve named patterns with a readable tell', () => {
    const ids = Object.keys(BOSS_PATTERNS);
    expect(ids.length).toBeGreaterThanOrEqual(12);
    for (const pattern of Object.values(BOSS_PATTERNS)) {
      expect(pattern.tell).toBeTruthy();
      expect(pattern.rule).toBeTruthy();
      expect(pattern.executedByBattleEngine).toBe(false);
    }
  });
});
