// Targeted visual check: Outer Grid room transitions + firewall-span FX.
// Boots a fresh save, walks to the span, captures mid-animation frames.
import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const OUT = resolve(process.env.TEMP || '.', 'outer-grid-shots');
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

  // Seed a mid-expedition save: sentinel defeated, standing at the span.
  await page.addInitScript(() => {
    const dragon = { level: 6, xp: 0, owned: true, discovered: true, shiny: false, fusedBaseStats: null };
    const save = {
      dragons: { fire: { ...dragon, owned: false }, shadow: dragon },
      defeatedNpcs: ['firewall_sentinel', 'buffer_overflow'],
      outerGrid: { roomId: 'firewall-span', visited: ['field-locker', 'signal-approach', 'signal-breach', 'firewall-span'] },
    };
    localStorage.setItem('dragonforge_save', JSON.stringify(save));
  });

  // boot (same as smoke)
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.locator('.terminal-screen').click({ timeout: 12000 });
  await page.getByText('INITIALIZE_SIMULATION.EXE').click({ timeout: 30000, force: true });
  const tutorial = page.locator('.tutorial-overlay');
  if (await tutorial.isVisible({ timeout: 3000 }).catch(() => false)) await tutorial.click({ force: true });

  // straight into the grid
  await page.getByRole('button', { name: 'MAP', exact: true }).click({ timeout: 15000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, '0b-map.png') });
  // The default selection may not be an outer_grid node on a seeded save —
  // click the Signal Breach node first so the EXPLORE button appears.
  const explore = page.getByRole('button', { name: /EXPLORE OUTER GRID/i });
  if (!(await explore.isVisible({ timeout: 1500 }).catch(() => false))) {
    await page.locator('.campaign-node').first().click({ force: true });
    await page.waitForTimeout(300);
  }
  await explore.click({ timeout: 10000 });
  await page.locator('.outer-grid-scene').waitFor({ timeout: 8000 });
  await page.waitForTimeout(400);
  await page.screenshot({ path: resolve(OUT, '5-firewall-span.png') });

  // brace the span: capture mid-animation (1.5s commit delay)
  await page.getByRole('button', { name: /Brace the span/i }).click({ timeout: 8000 });
  await page.waitForTimeout(700);
  await page.screenshot({ path: resolve(OUT, '6-span-fx.png') });
  await page.waitForTimeout(1200);
  await page.screenshot({ path: resolve(OUT, '7-span-committed.png') });

  // walk through the opened crossing to see a transit into the next room
  await page.getByRole('button', { name: /Cross|upper span/i }).first().click({ timeout: 8000 });
  await page.waitForTimeout(260);
  await page.screenshot({ path: resolve(OUT, '8-span-transit.png') });
  await page.waitForTimeout(1000);
  await page.screenshot({ path: resolve(OUT, '9-after-span.png') });

  console.log('shots saved to', OUT);
  await browser.close();
  if (previewProcess) previewProcess.kill();
  process.exit(0);
}

main().catch(e => { console.error(e); if (previewProcess) previewProcess.kill(); process.exit(1); });
