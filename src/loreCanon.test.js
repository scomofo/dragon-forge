import { describe, expect, test } from 'vitest';
import {
  CAPTAINS_LOG_ARC,
  DRAGON_PROTOCOL_CANON,
  FELIX_CANON,
  OPENING_BOOT_LINES,
  OPENING_FELIX_LINES,
  PLAYER_CANON,
  WORLD_CANON,
} from './loreCanon';
import { getTerminalDialogue } from './felixDialogue';
import { CAPTAINS_LOG_FRAGMENTS, FELIX_CONTEXTUAL } from './forgeData';

describe('runtime lore canon', () => {
  test('defines the core Skye/Felix/world premise', () => {
    expect(PLAYER_CANON.name).toBe('Skye');
    expect(PLAYER_CANON.role).toContain('dragon handler');
    expect(FELIX_CANON.name).toBe('Professor Felix');
    expect(FELIX_CANON.relationship).toContain('Skye');
    expect(WORLD_CANON.astraeus).toContain('Astraeus');
    expect(WORLD_CANON.primaryThreat).toContain('Mirror Admin');
    expect(DRAGON_PROTOCOL_CANON.summary).toContain('protocol');
  });

  test('opening text names Skye and introduces the long threat', () => {
    const bootText = OPENING_BOOT_LINES.map((line) => line.text).join(' ');
    const felixText = OPENING_FELIX_LINES.join(' ');

    expect(bootText).toContain('SKYE');
    expect(`${bootText} ${felixText}`).toMatch(/Astraeus|Mirror Admin/);
    expect(felixText).toContain('Skye');
    expect(felixText).toContain('dragons');
  });

  test('captain log arc has unique short fragments', () => {
    const ids = CAPTAINS_LOG_ARC.map((fragment) => fragment.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(CAPTAINS_LOG_ARC.length).toBeGreaterThanOrEqual(7);
    for (const fragment of CAPTAINS_LOG_ARC) {
      expect(fragment.title.length).toBeGreaterThan(3);
      expect(fragment.body.length).toBeGreaterThan(40);
      expect(fragment.body.length).toBeLessThan(260);
    }
  });
});

test('stage zero Felix dialogue uses the Skye canon opening', () => {
  const stageZero = getTerminalDialogue(0).join(' ');
  expect(stageZero).toContain('Skye');
  expect(stageZero).toContain('Mirror Admin');
  expect(stageZero).toContain('Forge');
});

test('Forge lore hub exposes Skye canon fragments and contextual lines', () => {
  const fragmentText = CAPTAINS_LOG_FRAGMENTS.map((fragment) => `${fragment.title} ${fragment.body}`).join(' ');
  expect(fragmentText).toContain('Skye');
  expect(fragmentText).toContain('Astraeus');
  expect(fragmentText).toContain('Mirror Admin');
  expect(fragmentText).toContain('Great Reset');

  const firstVisit = FELIX_CONTEXTUAL.find((entry) => entry.id === 'firstVisit');
  expect(firstVisit.line).toContain('Skye');
});
