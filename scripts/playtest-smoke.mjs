import { mkdir } from 'node:fs/promises';
import { resolve } from 'node:path';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const ARTIFACT_DIR = resolve('.playtest-artifacts');
const BASE_URL = process.env.PLAYTEST_URL || 'http://127.0.0.1:4173/dragon-forge/';
const viewports = [
  { name: 'desktop', width: 1440, height: 900 },
  { name: 'tablet', width: 900, height: 700 },
  { name: 'mobile', width: 390, height: 844 },
];
let previewProcess = null;

async function isServerReady() {
  try {
    const response = await fetch(BASE_URL, { method: 'HEAD' });
    return response.ok;
  } catch {
    return false;
  }
}

async function ensureServer() {
  if (await isServerReady()) return;
  previewProcess = spawn('npm run preview -- --host 127.0.0.1', {
    stdio: 'pipe',
    shell: true,
  });
  const deadline = Date.now() + 20000;
  while (Date.now() < deadline) {
    if (await isServerReady()) return;
    await new Promise((resolveDelay) => setTimeout(resolveDelay, 400));
  }
  throw new Error(`Preview server did not become ready at ${BASE_URL}`);
}

async function assertNoHorizontalOverflow(page, label) {
  const overflow = await page.evaluate(() => document.documentElement.scrollWidth - document.documentElement.clientWidth);
  if (overflow > 2) throw new Error(`${label}: horizontal overflow ${overflow}px`);
}

async function boot(page) {
  await page.goto(BASE_URL, { waitUntil: 'networkidle' });
  await page.locator('.terminal-screen').click({ timeout: 12000 });
  await page.getByText('INITIALIZE_SIMULATION.EXE').click({ timeout: 30000, force: true });
  const tutorial = page.locator('.tutorial-overlay');
  if (await tutorial.isVisible({ timeout: 3000 }).catch(() => false)) {
    await tutorial.click({ force: true });
  }
}

async function smokeViewport(browser, viewport) {
  const context = await browser.newContext({ viewport });
  const page = await context.newPage();
  const pageErrors = [];
  page.on('pageerror', (error) => pageErrors.push(error.message));
  page.on('console', (message) => {
    if (message.type() === 'error') pageErrors.push(message.text());
  });

  await boot(page);

  for (const screen of ['HATCHERY', 'MAP', 'SHOP', 'BATTLES']) {
    await page.getByRole('button', { name: screen, exact: true }).click({ timeout: 30000 });
    await page.waitForTimeout(250);
    await assertNoHorizontalOverflow(page, `${viewport.name} ${screen}`);
  }

  await page.getByRole('button', { name: /FORGE/i }).click({ timeout: 30000 });
  await page.locator('.forge-screen').waitFor({ timeout: 8000 });
  await assertNoHorizontalOverflow(page, `${viewport.name} forge`);

  await page.locator('.forge-screen').click({ force: true });
  const before = await page.locator('[data-testid="forge-skye"]').evaluate((el) => getComputedStyle(el).left);
  await page.keyboard.press('ArrowRight');
  await page.keyboard.press('ArrowRight');
  await page.waitForTimeout(180);
  const after = await page.locator('[data-testid="forge-skye"]').evaluate((el) => getComputedStyle(el).left);
  if (before === after) {
    throw new Error(`${viewport.name}: Forge movement did not change Skye position`);
  }

  await page.screenshot({ path: resolve(ARTIFACT_DIR, `${viewport.name}.png`), fullPage: true });
  await context.close();

  if (pageErrors.length > 0) {
    throw new Error(`${viewport.name}: page errors\n${pageErrors.join('\n')}`);
  }
}

await mkdir(ARTIFACT_DIR, { recursive: true });
await ensureServer();
const browser = await chromium.launch();
try {
  for (const viewport of viewports) {
    await smokeViewport(browser, viewport);
    console.log(`ok ${viewport.name}`);
  }
} finally {
  await browser.close();
  previewProcess?.kill();
}
