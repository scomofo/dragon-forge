import { describe, expect, test } from 'vitest';
import { moves, npcs } from './gameData';

// Intentionally small kits: early tutorial bosses whose single-move kit is
// load-bearing (firewall_sentinel teaches the defend/strike cycle;
// buffer_overflow's heat cycle requires a deterministic magma_breath cadence).
const TUTORIAL_KIT_EXCEPTIONS = {
  firewall_sentinel: 'tutorial boss: single rock_slide teaches the defend/strike cycle',
  buffer_overflow: 'tutorial boss: single magma_breath keeps the 4-heat cycle deterministic',
};

describe('npc boss kits', () => {
  test('every boss kit has 4 moveKeys (or documents its tutorial exception)', () => {
    for (const [id, npc] of Object.entries(npcs)) {
      if (TUTORIAL_KIT_EXCEPTIONS[id]) {
        expect(npc.moveKeys.length, `${id} stays intentionally small`).toBeLessThan(4);
        continue;
      }
      expect(npc.moveKeys, `${id} kit`).toHaveLength(4);
    }
  });

  test('every kit key names a real move and is not the signature slot', () => {
    for (const [id, npc] of Object.entries(npcs)) {
      for (const key of npc.moveKeys) {
        expect(moves[key], `${id} move ${key}`).toBeDefined();
        expect(key, `${id} keeps its signature out of moveKeys`).not.toBe(npc.signatureMoveKey);
      }
      expect(new Set(npc.moveKeys).size, `${id} has no duplicate keys`).toBe(npc.moveKeys.length);
    }
  });

  test('kit keys survive the NPC move picker (no reflect moves, which are filtered)', () => {
    for (const [id, npc] of Object.entries(npcs)) {
      for (const key of npc.moveKeys) {
        expect(moves[key]?.isReflect, `${id} move ${key} is not reflect-filtered by pickNpcMove`).not.toBe(true);
      }
    }
  });
});
