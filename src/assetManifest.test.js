import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { dragons, eggSheets, npcs } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS } from './singularityBosses';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

function publicPath(assetUrl) {
  return resolve(root, 'public', assetUrl.replace(/^\/dragon-forge\//, '').replace(/^\//, ''));
}

function collectAssetUrls() {
  const urls = new Set();
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
  for (const boss of [...SINGULARITY_BOSSES, FINAL_BOSS]) {
    if (boss?.sprite) urls.add(boss.sprite);
    for (const phase of boss?.phases || []) {
      if (phase.sprite) urls.add(phase.sprite);
    }
  }
  return [...urls].filter(Boolean);
}

describe('runtime asset manifest', () => {
  it('uses the dedicated shadow stage one sprite', () => {
    expect(dragons.shadow.stageSprites[1]).toContain('/assets/dragons/shadow_stage1.png');
  });

  it('references files that exist under public assets', () => {
    const missing = collectAssetUrls().filter((url) => !existsSync(publicPath(url)));
    expect(missing).toEqual([]);
  });
});
