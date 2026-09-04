import { describe, expect, it } from 'vitest';
import { npcs } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS } from './singularityBosses';
import { BATTLE_CELL, hasBannedFilter, isBannedArtUrl } from './artBible';
import {
  ARENAS,
  ARENA_STATUS,
  KNOWN_CONTENT_FILTER_ARENAS,
  getArena,
  isGradeOnlyFilter,
  listArenaUrls,
  resolveBattleArena,
} from './arenas';

function collectReferencedArenas() {
  const urls = new Set();
  for (const npc of Object.values(npcs)) urls.add(npc.arena);
  for (const boss of [...SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS]) {
    if (boss?.arena) urls.add(boss.arena);
  }
  return [...urls];
}

function collectBossFilters() {
  const entries = [];
  for (const boss of [...SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS]) {
    entries.push({ id: boss.id, arenaFilter: boss.arenaFilter || null });
  }
  return entries;
}

describe('arena registry', () => {
  it('covers exactly the arenas battle code references', () => {
    const referenced = collectReferencedArenas().sort();
    expect(referenced.length).toBe(11);
    expect(listArenaUrls().sort()).toEqual(referenced);
    for (const [id, entry] of Object.entries(ARENAS)) {
      expect(entry.src, id).toBeTruthy();
      expect(getArena(id)).toBe(entry);
    }
    expect(getArena('magma')).toBe(null);
  });

  it('declares the 320x176 battle cell on every arena', () => {
    for (const [id, entry] of Object.entries(ARENAS)) {
      expect(entry.width, id).toBe(BATTLE_CELL.arenaWidth);
      expect(entry.height, id).toBe(BATTLE_CELL.arenaHeight);
    }
  });

  it('stays honest — all battle arenas are authored after the P1 art pass', () => {
    for (const [id, entry] of Object.entries(ARENAS)) {
      expect(entry.status, id).toBe(ARENA_STATUS.AUTHORED);
    }
  });

  it('never references banned or leftover arena files', () => {
    for (const url of collectReferencedArenas()) {
      expect(isBannedArtUrl(url), url).toBe(false);
    }
    expect(collectReferencedArenas().some((url) => url.includes('arenas/fire.'))).toBe(false);
  });
});

describe('arena filter ratchet', () => {
  it('keeps NPC arenas filter-free', () => {
    for (const npc of Object.values(npcs)) {
      expect(npc.arenaFilter || null, npc.id).toBe(null);
    }
  });

  it('locks the seven known content-filter users — no eighth allowed', () => {
    const contentUsers = collectBossFilters()
      .filter(({ arenaFilter }) => hasBannedFilter(arenaFilter))
      .map(({ id }) => id)
      .sort();
    expect(contentUsers).toEqual([...KNOWN_CONTENT_FILTER_ARENAS].sort());
    expect(KNOWN_CONTENT_FILTER_ARENAS.length).toBe(7);
  });

  it('grades the Singularity without hue-rotate or grayscale', () => {
    expect(isGradeOnlyFilter(FINAL_BOSS.arenaFilter)).toBe(true);
    expect(hasBannedFilter(FINAL_BOSS.arenaFilter)).toBe(false);
  });
});

describe('resolveBattleArena', () => {
  it('passes grade-only filters through and flags debt honestly', () => {
    expect(resolveBattleArena({ arena: '/x/shadow.webp', arenaFilter: null })).toMatchObject({
      src: '/x/shadow.webp',
      filter: 'none',
      placeholder: false,
      contentFilter: false,
    });
    expect(
      resolveBattleArena({ arena: '/x/gravity_chamber.webp', arenaFilter: 'saturate(1.5) contrast(1.2)' }),
    ).toMatchObject({ filter: 'saturate(1.5) contrast(1.2)', placeholder: false, contentFilter: false });
    expect(
      resolveBattleArena({ arena: '/x/shadow.webp', arenaFilter: 'grayscale(0.5) hue-rotate(330deg)' }),
    ).toMatchObject({ contentFilter: true });
  });
});
