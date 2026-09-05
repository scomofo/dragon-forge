// Targeted visual check: Storm Spine zone + fork-in-the-wire arc-shut FX.
import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const OUT = resolve(process.env.TEMP || '.', 'storm-spine-shots');
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
      dragons: { storm: dragon },
      defeatedNpcs: ['firewall_sentinel', 'bit_wraith', 'phishing_siren', 'crypto_crab', 'buffer_overflow', 'glitch_hydra'],
      frozenCache: { roomId: 'thaw-gate', visited: ['cold-archive'] },
      stormSpine: { roomId: 'fork-in-the-wire', visited: ['overclock-gantry', 'live-wire', 'hydra-spine', 'fork-in-the-wire'] },
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
  await page.getByText('Hydra Spine', { exact: false }).first().click({ force: true });
  await page.waitForTimeout(300);
  await page.getByRole('button', { name: /EXPLORE STORM SPINE/i }).click({ timeout: 10000 });
  await page.locator('.storm-spine-scene').waitFor({ timeout: 8000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, '1-fork.png') });

  // choose the capacitor lane: capture the arc-shut mid-animation
  const choice = page.getByRole('button', { name: /^Capacitor lane/i });
  await choice.scrollIntoViewIfNeeded({ timeout: 8000 });
  await choice.click({ timeout: 8000 });
  await page.waitForTimeout(500);
  await page.screenshot({ path: resolve(OUT, '2-fork-fx.png') });
  await page.waitForTimeout(1300);
  await page.screenshot({ path: resolve(OUT, '3-fork-committed.png') });

  // ride the opened lane to the capacitor bank
  const exit = page.getByRole('button', { name: /Ride the capacitor lane/i });
  await exit.scrollIntoViewIfNeeded({ timeout: 8000 });
  await exit.click();
  await page.waitForTimeout(300);
  await page.screenshot({ path: resolve(OUT, '4-transit.png') });
  await page.waitForTimeout(1100);
  await page.screenshot({ path: resolve(OUT, '5-capacitor-bank.png') });

  console.log('shots saved to', OUT);
  await browser.close();
  if (previewProcess) previewProcess.kill();
  process.exit(0);
}

main().catch(e => { console.error(e); if (previewProcess) previewProcess.kill(); process.exit(1); });
