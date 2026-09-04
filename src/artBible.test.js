import { describe, expect, it } from 'vitest';
import { dragons, moves, npcs, JOURNAL_DRAGON_IDS } from './gameData';
import {
  BANNED_ART_SUBSTRINGS,
  BANNED_ARENA_SUBSTRINGS,
  BATTLE_CELL,
  BATTLE_FRAME_COUNTS,
  BATTLE_SET_STATUS,
  BODY_PLANS,
  DRAGON_BATTLE_SETS,
  NPC_BATTLE_SETS,
  NPC_BATTLE_SET_IDS,
  getBodyPlan,
  getBattleSet,
  hasBannedFilter,
  isBannedArtUrl,
  isKnownPlaceholderArena,
  KNOWN_PLACEHOLDER_ARENAS,
  uniqueSilhouettes,
  validateBattleSetSpec,
} from './artBible';
import { ACTOR_CONTRACT, SIGNATURE_VFX, VFX_FRAMES, VFX_PLACEHOLDERS, getVfxKind } from './sprites';
import { WORLD_ZONE_IDS, WORLD_ZONES, getZoneForNode } from './worldZones';
import { BOSS_PATTERNS } from './bossPatterns';
import { CAMPAIGN_NODES } from './campaignMap';
import { SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS } from './singularityBosses';

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
      const entry = VFX_FRAMES[key];
      const hasStrip = Boolean(entry?.strip?.src);
      const hasSignature = Boolean(entry?.signature?.palette && entry?.signature?.motif && entry?.signature?.motion);
      const isPlaceholder = Object.prototype.hasOwnProperty.call(VFX_PLACEHOLDERS, key);
      expect(Boolean(hasStrip || hasSignature || entry === null || isPlaceholder), `${move.name} ${key}`).toBe(true);
    }
  });

  it('clears signature VFX placeholders — every signature owns its strip or signature contract', () => {
    expect(Object.keys(VFX_PLACEHOLDERS)).toEqual([]);
    const signatures = Object.values(moves).filter((move) => move.isSignature);
    for (const move of signatures) {
      expect(getVfxKind(move.vfxKey), move.name).toBe('signature');
    }
    const ids = Object.keys(SIGNATURE_VFX);
    expect(ids.length).toBeGreaterThanOrEqual(9);
    const palettes = ids.map((id) => SIGNATURE_VFX[id].signature.palette.join('|'));
    const motifs = ids.map((id) => SIGNATURE_VFX[id].signature.motif);
    const motions = ids.map((id) => SIGNATURE_VFX[id].signature.motion);
    expect(new Set(palettes).size).toBe(palettes.length);
    expect(new Set(motifs).size).toBe(motifs.length);
    expect(new Set(motions).size).toBe(motions.length);
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
    }
  });

  it('tracks execution per pattern; all 13 are live', () => {
    const entries = Object.entries(BOSS_PATTERNS);
    const executed = entries.filter(([, p]) => p.executedByBattleEngine);
    expect(executed.length).toBe(13);
    // The original pilot must stay wired.
    expect(BOSS_PATTERNS.firewall_sentinel.executedByBattleEngine).toBe(true);
  });
});

describe('P1 battle frame-set catalog', () => {
  it('tracks stage-3 sets for all 9 dragons at the mid cell', () => {
    expect(Object.keys(DRAGON_BATTLE_SETS).sort()).toEqual([...JOURNAL_DRAGON_IDS].sort());
    for (const [id, spec] of Object.entries(DRAGON_BATTLE_SETS)) {
      expect(spec.cell, id).toBe(BATTLE_CELL.mid);
      expect(validateBattleSetSpec(spec), id).toBe(null);
      expect(getBattleSet(id)?.actorId, id).toBe(id);
    }
  });

  it('tracks 9 NPC sets at the same cell size', () => {
    expect(NPC_BATTLE_SET_IDS.length).toBe(9);
    for (const id of NPC_BATTLE_SET_IDS) {
      expect(npcs[id], id).toBeTruthy();
    }
    for (const [id, spec] of Object.entries(NPC_BATTLE_SETS)) {
      expect(spec.cell, id).toBe(BATTLE_CELL.mid);
      expect(validateBattleSetSpec(spec), id).toBe(null);
    }
  });

  it('stays honest — nothing claims shipped until real sheets exist', () => {
    expect(ACTOR_CONTRACT.stagePortraitsAreSingleFrame).toBe(true);
    for (const id of [...JOURNAL_DRAGON_IDS, ...NPC_BATTLE_SET_IDS]) {
      expect(getBattleSet(id)?.status, id).toBe(BATTLE_SET_STATUS.PORTRAIT_ONLY);
    }
  });
});

describe('P1 arena contract', () => {
  it('bans printed-error language and leftover fire-arena references', () => {
    const urls = [];
    for (const npc of Object.values(npcs)) urls.push(npc.arena);
    for (const boss of [...SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS]) {
      if (boss?.arena) urls.push(boss.arena);
    }
    expect(urls.length).toBeGreaterThan(10);
    for (const url of urls) {
      expect(isBannedArtUrl(url), url).toBe(false);
    }
    for (const banned of BANNED_ARENA_SUBSTRINGS) {
      expect(urls.some((url) => String(url).toLowerCase().includes(banned))).toBe(false);
    }
  });

  it('tracks no known placeholder arenas after the P1 art pass', () => {
    expect(KNOWN_PLACEHOLDER_ARENAS).toEqual([]);
    expect(isKnownPlaceholderArena('/assets/arenas/gravity_chamber.webp')).toBe(false);
    expect(isKnownPlaceholderArena('/assets/arenas/shadow.webp')).toBe(false);
  });
});

describe('P1 boss phase cells', () => {
  it('gives every boss phase its own cells — never a hue-rotate recolor', () => {
    const bosses = [FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS];
    expect(bosses.length).toBeGreaterThanOrEqual(5);
    for (const boss of bosses) {
      expect(boss.phases?.length, boss.id).toBeGreaterThanOrEqual(3);
      for (const phase of boss.phases) {
        expect(phase.idleSprite, `${boss.id} ${phase.name}`).toBeTruthy();
        expect(phase.attackSprite, `${boss.id} ${phase.name}`).toBeTruthy();
        expect(hasBannedFilter(phase.spriteFilter), `${boss.id} ${phase.name}`).toBe(false);
      }
    }
  });
});
