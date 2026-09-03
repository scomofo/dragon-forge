import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { dragons, eggSheets, npcs } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS } from './singularityBosses';
import { VFX_FRAMES } from './sprites';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function publicPath(url) {
  const stripped = url.replace(/^\/dragon-forge\//, '').replace(/^\//, '');
  const webp = resolve(root, 'public', stripped);
  if (existsSync(webp)) return webp;
  return resolve(root, 'public', stripped.replace(/\.webp$/i, '.png'));
}

function collectAssetUrls() {
  const urls = new Set();
  for (const dragon of Object.values(dragons)) {
    urls.add(dragon.spriteSheet);
    Object.values(dragon.stageSprites || {}).forEach((url) => urls.add(url));
    if (dragon.battleSheet && existsSync(publicPath(dragon.battleSheet))) {
      urls.add(dragon.battleSheet);
    }
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
  return [...urls].filter(Boolean);
}

describe('runtime asset manifest', () => {
  it('uses the dedicated shadow stage one sprite', () => {
    expect(dragons.shadow.stageSprites[1]).toContain('/assets/dragons/shadow_stage1.webp');
  });

  it('declares P1 battle sheets for fire and ice', () => {
    expect(dragons.fire.battleSheet).toMatch(/fire_stage3_battle\.webp$/);
    expect(dragons.ice.battleSheet).toMatch(/ice_stage3_battle\.webp$/);
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
});
