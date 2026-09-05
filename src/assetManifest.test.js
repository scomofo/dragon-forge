import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { dragons, eggSheets, moves, npcs } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS } from './singularityBosses';
import { SIGNATURE_VFX, VFX_FRAMES } from './sprites';
import { DRAGON_BATTLE_SETS, NPC_BATTLE_SETS } from './artBible';
import { BATTLE_POSES, getBattleSetSheetUrl, isBattleSetSheetLive } from './battleSets';
import { OUTER_GRID_ROOMS } from './worldZones';
import { assetUrl } from './utils';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function publicPath(url) {
  const stripped = url.replace(/^\/dragon-forge\//, '').replace(/^\//, '');
  const webp = resolve(root, 'public', stripped);
  if (existsSync(webp)) return webp;
  return resolve(root, 'public', stripped.replace(/\.webp$/i, '.png'));
}

function collectAssetUrls() {
  const urls = new Set();
  Object.values(OUTER_GRID_ROOMS).forEach(room => urls.add(assetUrl(room.background)));
  urls.add(assetUrl('/assets/characters/skye.png'));
  for (const dragon of Object.values(dragons)) {
    urls.add(dragon.spriteSheet);
    Object.values(dragon.stageSprites || {}).forEach((url) => urls.add(url));
  }
  Object.values(eggSheets).forEach((url) => urls.add(url));
  for (const npc of Object.values(npcs)) {
    urls.add(npc.idleSprite);
    urls.add(npc.attackSprite);
    urls.add(npc.arena);
  }
  for (const boss of [...SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS]) {
    if (!boss) continue;
    if (boss.sprite) urls.add(boss.sprite);
    if (boss.idleSprite) urls.add(boss.idleSprite);
    if (boss.attackSprite) urls.add(boss.attackSprite);
    if (boss.arena) urls.add(boss.arena);
    for (const phase of boss.phases || []) {
      if (phase.sprite) urls.add(phase.sprite);
      if (phase.idleSprite) urls.add(phase.idleSprite);
      if (phase.attackSprite) urls.add(phase.attackSprite);
    }
  }
  for (const frame of Object.values(VFX_FRAMES)) {
    if (frame?.strip?.src) urls.add(frame.strip.src);
  }
  // Shipped battle-set sheets must resolve on disk. Nothing is shipped yet,
  // so this is a no-op today and a gate the moment the first sheets land.
  for (const id of [...Object.keys(DRAGON_BATTLE_SETS), ...Object.keys(NPC_BATTLE_SETS)]) {
    if (!isBattleSetSheetLive(id)) continue;
    for (const pose of BATTLE_POSES) urls.add(getBattleSetSheetUrl(id, pose));
  }
  return [...urls].filter(Boolean);
}

describe('runtime asset manifest', () => {
  it('uses the dedicated shadow stage one sprite', () => {
    expect(dragons.shadow.stageSprites[1]).toContain('/assets/dragons/shadow_stage1.webp');
  });

  it('rewrites painted sprites to webp', () => {
    const urls = collectAssetUrls();
    expect(urls.length).toBeGreaterThan(20);
    expect(urls.every((url) => url.includes('.webp'))).toBe(true);
  });

  it('gives remnants and Mirror Admin phases their own portraits', () => {
    const remnantIds = CORRUPTION_REMNANTS.map((r) => r.idleSprite);
    expect(remnantIds.some((u) => u.includes('remnant_data_corruption'))).toBe(true);
    expect(remnantIds.some((u) => u.includes('remnant_memory_leak'))).toBe(true);
    expect(remnantIds.some((u) => u.includes('remnant_stack_overflow'))).toBe(true);
    const phases = MIRROR_ADMIN.phases.map((p) => p.idleSprite);
    expect(phases[0]).toContain('mirror_admin_protocol');
    expect(phases[1]).toContain('mirror_admin_warden');
    expect(phases[2]).toContain('mirror_admin_reset');
  });

  it('references files that exist under public assets', () => {
    const missing = collectAssetUrls().filter((url) => !existsSync(publicPath(url)));
    expect(missing).toEqual([]);
  });

  it('gives every signature move a dedicated non-shared VFX identity', () => {
    const signatures = Object.values(moves).filter((move) => move.isSignature);
    expect(signatures.length).toBeGreaterThanOrEqual(9);
    const seenStrips = new Set();
    for (const move of signatures) {
      const entry = VFX_FRAMES[move.vfxKey];
      expect(entry, move.name).toBeTruthy();
      if (entry?.strip?.src) {
        expect(seenStrips.has(entry.strip.src), move.name).toBe(false);
        seenStrips.add(entry.strip.src);
      } else {
        expect(entry?.signature, move.name).toBeTruthy();
        expect(SIGNATURE_VFX[move.vfxKey], move.name).toBeTruthy();
      }
    }
  });

  it('gives every boss phase resolvable sprite files', () => {
    const missing = [];
    for (const boss of [FINAL_BOSS, MIRROR_ADMIN, ...CORRUPTION_REMNANTS]) {
      for (const phase of boss.phases || []) {
        for (const url of [phase.idleSprite, phase.attackSprite]) {
          if (url && !existsSync(publicPath(url))) missing.push(`${boss.id} ${phase.name} ${url}`);
        }
      }
    }
    expect(missing).toEqual([]);
  });
});
