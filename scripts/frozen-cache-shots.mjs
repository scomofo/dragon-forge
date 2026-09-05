// Targeted visual check: Frozen Cache zone + thaw-junction FX (both routes).
import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const OUT = resolve(process.env.TEMP || '.', 'frozen-cache-shots');
const BASE_URL = 'http://127.0.0.1:4173/dragon-forge/';
let previewProcess = null;

async function isReady() {
  try { return (await fetch(BASE_URL, { method: 'HEAD' })).ok; } catch { return false; }
}

async function seedAndShoot(browser, route, shots) {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  page.on('pageerror', e => console.error('PAGE ERROR:', e.message));
  await page.addInitScript(() => {
    const dragon = { level: 8, xp: 0, owned: true, discovered: true, shiny: false, fusedBaseStats: null };
    const save = {
      dragons: { ice: dragon },
      defeatedNpcs: ['firewall_sentinel', 'bit_wraith', 'buffer_overflow'],
      outerGrid: { roomId: 'return-gate', visited: ['field-locker'] },
      frozenCache: { roomId: 'thaw-junction', visited: ['cold-archive', 'mute-channel', 'wraith-cache', 'thaw-junction'] },
    };
    localStorage.setItem('dragonforge_save', JSON.stringify(save));
  });
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.locator('.terminal-screen').click({ timeout: 12000 });
  await page.getByText('INITIALIZE_SIMULATION.EXE').click({ timeout: 30000, force: true });
  const tutorial = page.locator('.tutorial-overlay');
  if (await tutorial.isVisible({ timeout: 3000 }).catch(() => false)) await tutorial.click({ force: true });
  await page.getByRole('button', { name: 'MAP', exact: true }).click({ timeout: 15000 });
  await page.waitForTimeout(400);
  // select a frozen_cache node (Wraith Cache) so the EXPLORE button targets it
  await page.getByText('Wraith Cache', { exact: false }).first().click({ force: true });
  await page.waitForTimeout(300);
  await page.getByRole('button', { name: /EXPLORE FROZEN CACHE/i }).click({ timeout: 10000 });
  await page.locator('.frozen-cache-scene').waitFor({ timeout: 8000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, `${shots}-junction.png`) });

  const choice = page.getByRole('button', { name: route === 'thaw' ? /Hold the slow thaw/i : /Crack the deep freeze/i });
  await choice.scrollIntoViewIfNeeded({ timeout: 8000 });
  await choice.click({ timeout: 8000 });
  await page.waitForTimeout(650);
  await page.screenshot({ path: resolve(OUT, `${shots}-fx.png`) });
  await page.waitForTimeout(1100);
  await page.screenshot({ path: resolve(OUT, `${shots}-committed.png`) });
  // take the opened route
  const exitBtn = page.locator('.outer-grid-actions button:not([disabled])').last();
  await exitBtn.click();
  await page.waitForTimeout(300);
  await page.screenshot({ path: resolve(OUT, `${shots}-transit.png`) });
  await page.waitForTimeout(1100);
  await page.screenshot({ path: resolve(OUT, `${shots}-arrived.png`) });
  await page.close();
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
  await seedAndShoot(browser, 'thaw', 'a');
  await seedAndShoot(browser, 'crack', 'b');
  console.log('shots saved to', OUT);
  await browser.close();
  if (previewProcess) previewProcess.kill();
  process.exit(0);
}

main().catch(e => { console.error(e); if (previewProcess) previewProcess.kill(); process.exit(1); });
