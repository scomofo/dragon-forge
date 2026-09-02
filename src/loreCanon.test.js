// @ts-nocheck
import { describe, expect, test } from 'vitest';
import {
  CAPTAINS_LOG_ARC,
  DRAGON_PROTOCOL_CANON,
  FELIX_CANON,
  FELIX_STAGE_PROSE,
  JOURNAL_BRIEFING,
  OPENING_BOOT_LINES,
  OPENING_FELIX_LINES,
  PLAYER_CANON,
  REQUIRED_FRAGMENT_IDS,
  WORLD_CANON,
} from './loreCanon';
import { getDragonLore } from './gameData';
import { getTerminalDialogue } from './felixDialogue';
import {
  CAPTAINS_LOG_FRAGMENTS,
  FELIX_CONTEXTUAL,
  FELIX_IDLE_LINES,
  FORGE_STATIONS,
  FRAGMENT_TRIGGERS,
  getCaptainLogDisplay,
  pickFelixDelivery,
} from './forgeData';

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
    expect(felixText).toContain('JOURNAL');
  });

  test('journal briefing surfaces the canon the boot promises', () => {
    const text = JOURNAL_BRIEFING.map((entry) => `${entry.heading} ${entry.body}`).join(' ');
    expect(text).toContain('Skye');
    expect(text).toContain('Astraeus');
    expect(text).toContain('protocol');
    expect(text).toContain('Mirror Admin');
    expect(text).toContain('Great Reset');
    expect(JOURNAL_BRIEFING).toHaveLength(4);
  });

  test('captain log arc has unique short fragments including Iris', () => {
    const ids = CAPTAINS_LOG_ARC.map((fragment) => fragment.id);
    expect(new Set(ids).size).toBe(ids.length);
    expect(CAPTAINS_LOG_ARC.length).toBeGreaterThanOrEqual(8);
    expect(REQUIRED_FRAGMENT_IDS).toEqual(['001', '002', '003', '004', '005', '006', '007']);
    const iris = CAPTAINS_LOG_ARC.find((fragment) => fragment.id === '008');
    expect(iris.title).toBe('Iris');
    expect(iris.body).toMatch(/child|Admin/);
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

test('later title CRT lines stay in sync with Forge stage prose', () => {
  const stageFive = getTerminalDialogue(5).join(' ');
  expect(stageFive).toContain('Singularity');
  expect(FELIX_STAGE_PROSE[5]).toContain('Singularity');
});

test('Forge lore hub exposes Skye canon fragments and contextual lines', () => {
  const fragmentText = CAPTAINS_LOG_FRAGMENTS.map((fragment) => `${fragment.title} ${fragment.body}`).join(' ');
  expect(fragmentText).toContain('Skye');
  expect(fragmentText).toContain('Astraeus');
  expect(fragmentText).toContain('Mirror Admin');
  expect(fragmentText).toContain('Great Reset');
  expect(fragmentText).toContain('Iris');

  const firstVisit = FELIX_CONTEXTUAL.find((entry) => entry.id === 'firstVisit');
  expect(firstVisit.line).toContain('Skye');
});

test('Forge station prompts carry the runtime mythology into ordinary play', () => {
  const stationText = FORGE_STATIONS.map((station) => station.description).join(' ');
  const felixText = FELIX_IDLE_LINES.join(' ');

  expect(stationText).toContain('Skye');
  expect(stationText).toContain('Astraeus');
  expect(stationText).toContain('Mirror Admin');
  expect(stationText).toContain('rendered world');
  expect(felixText).toContain('Skye');
  expect(felixText).toContain('protocols');
});

test('Captain log reveals early lore and teases locked entries by title', () => {
  const freshSave = { flags: { metFelix: true }, stats: { battlesWon: 0 } };
  expect(FRAGMENT_TRIGGERS['001'](freshSave)).toBe(true);
  expect(FRAGMENT_TRIGGERS['002'](freshSave)).toBe(true);
  expect(FRAGMENT_TRIGGERS['008'](freshSave)).toBe(false);
  expect(FRAGMENT_TRIGGERS['008']({ singularityComplete: true })).toBe(true);

  const unlockedEntry = getCaptainLogDisplay(CAPTAINS_LOG_FRAGMENTS[0], ['001']);
  expect(unlockedEntry.heading).toContain('THE RENDERED WORLD');
  expect(unlockedEntry.body).toContain('Astraeus');
  expect(unlockedEntry.status).toBe('DECRYPTED');

  const lockedEntry = getCaptainLogDisplay(CAPTAINS_LOG_FRAGMENTS[2], ['001', '002']);
  expect(lockedEntry.heading).toContain('SKYE SIGNAL');
  expect(lockedEntry.body).toContain('Recover field signal');
  expect(lockedEntry.body).not.toContain('operator');
  expect(lockedEntry.status).toBe('SIGNAL LOCKED');
});

test('Felix speaks the Matrix stage line once, then Iris when her log decrypts', () => {
  const stageSave = {
    dragons: { fire: { owned: true }, ice: { owned: true } },
    defeatedNpcs: [],
    flags: { felixStageHeard: 0 },
  };
  const first = pickFelixDelivery(stageSave);
  expect(first.line).toMatch(/anomalous/i);
  expect(first.flags.felixStageHeard).toBe(1);

  const heard = pickFelixDelivery({ ...stageSave, flags: { felixStageHeard: 1 } });
  expect(heard.line).not.toMatch(/anomalous/i);

  const iris = pickFelixDelivery({
    flags: { fragmentsUnlocked: ['008'], felixIrisHeard: false, felixStageHeard: 5 },
    singularityComplete: true,
  });
  expect(iris.line).toContain('Iris');
  expect(iris.flags.felixIrisHeard).toBe(true);
});

test('owned Synthesis uses its own lore instead of Void', () => {
  expect(getDragonLore('synthesis', { owned: true })).toMatch(/living memory/i);
  expect(getDragonLore('synthesis', { owned: false })).toMatch(/No data available/);
  expect(getDragonLore('fire', { owned: true })).toMatch(/protocol/i);
});
