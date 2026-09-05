// Targeted visual check: Admin Core zone + cold-lantern FX.
import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const OUT = resolve(process.env.TEMP || '.', 'admin-core-shots');
const BASE_URL = 'http://127.0.0.1:4173/dragon-forge/';
let previewProcess = null;

async function isReady() {
  try { return (await fetch(BASE_URL, { method: 'HEAD' })).ok; } catch { return false; }
}

async function main() {
  await mkdir(OUT, { recursive: true });
  if (!(await isReady())) {
    previewProcess = spawn('npm run preview -- --host 127.0.0.1', { stdio: 'pipe', shell: true });
    const deadline = Date.now() + 20000;
    while (Date.now() < deadline && !(await isReady())) await new Promise(r => setTimeout(r, 400));
  }
  const executablePath = process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || undefined;
  const browser = await chromium.launch({
    executablePath,
    channel: executablePath ? undefined : (process.env.PLAYTEST_CHANNEL || undefined),
  });
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on('pageerror', e => console.error('PAGE ERROR:', e.message));

  // Seed: standing at the fork, hydra quiet, Frozen Cache cleared.
  await page.addInitScript(() => {
    const dragon = { level: 10, xp: 0, owned: true, discovered: true, shiny: false, fusedBaseStats: null };
    const save = {
      introSeen: true,
      // Defeating every base NPC pushes the app to corruption stage 5 (a
      // permanent screen-shake that makes Playwright's stability check hang).
      // singularityComplete returns the world to stage 0 for QA.
      singularityComplete: true,
      dragons: { light: dragon },
      defeatedNpcs: ['firewall_sentinel', 'bit_wraith', 'phishing_siren', 'crypto_crab', 'buffer_overflow', 'glitch_hydra', 'logic_bomb', 'recursive_golem'],
      frozenCache: { roomId: 'thaw-gate', visited: ['cold-archive'] },
      stormSpine: { roomId: 'discharge-gate', visited: ['overclock-gantry'] },
      adminCore: { roomId: 'cold-lanterns', visited: ['mirror-vestibule', 'processional', 'recursive-gate', 'cold-lanterns'] },
    };
    localStorage.setItem('dragonforge_save', JSON.stringify(save));
  });

  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  // The index.html splash clears on window.load + 2s, which can hang when
  // external fonts stall — remove it in-harness. The terminal's blinking
  // cursor also never goes 'stable' for Playwright, so dispatch the click
  // via DOM (the typewriter skip doesn't need a trusted event).
  await page.evaluate(() => document.getElementById('splash')?.remove());
  await page.waitForSelector('.terminal-screen', { timeout: 12000 });
  await page.evaluate(() => document.querySelector('.terminal-screen')?.click());
  await page.waitForSelector('.terminal-init-btn', { timeout: 30000 });
  await page.evaluate(() => document.querySelector('.terminal-init-btn')?.click());
  const tutorial = page.locator('.tutorial-overlay');
  if (await tutorial.isVisible({ timeout: 3000 }).catch(() => false)) await tutorial.click({ force: true });
  await page.waitForTimeout(1200);
  await page.screenshot({ path: resolve(OUT, '0-after-boot.png') });
  console.log('buttons:', JSON.stringify(await page.locator('button').allTextContents()));
  await page.getByRole('button', { name: 'MAP', exact: true }).click({ timeout: 15000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, '0-map.png') });
  const explore = page.getByRole('button', { name: /EXPLORE ADMIN CORE/i });
  if (!(await explore.isVisible({ timeout: 1500 }).catch(() => false))) {
    await page.getByText('Protocol Perch', { exact: false }).first().click({ force: true });
    await page.waitForTimeout(300);
  }
  await explore.click({ timeout: 10000 });
  await page.locator('.admin-core-scene').waitFor({ timeout: 8000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, '1-lanterns.png') });

  // choose the capacitor lane: capture the arc-shut mid-animation
  const choice = page.getByRole('button', { name: /^Light the memory lantern/i });
  await choice.scrollIntoViewIfNeeded({ timeout: 8000 });
  await choice.click({ timeout: 8000 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: resolve(OUT, '2-lantern-fx.png') });
  await page.waitForTimeout(1300);
  await page.screenshot({ path: resolve(OUT, '3-lantern-committed.png') });

  // ride the opened lane to the capacitor bank
  const exit = page.getByRole('button', { name: /Follow the memory light/i });
  await exit.scrollIntoViewIfNeeded({ timeout: 8000 });
  await exit.click();
  await page.waitForTimeout(300);
  await page.screenshot({ path: resolve(OUT, '4-transit.png') });
  await page.waitForTimeout(1100);
  await page.screenshot({ path: resolve(OUT, '5-echo-archive.png') });

  console.log('shots saved to', OUT);
  await browser.close();
  if (previewProcess) previewProcess.kill();
  process.exit(0);
}

main().catch(e => { console.error(e); if (previewProcess) previewProcess.kill(); process.exit(1); });
