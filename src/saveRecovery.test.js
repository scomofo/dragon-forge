import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const PRIMARY = 'dragonforge_save';
const BACKUP = 'dragonforge_save_backup';
const DAMAGED = 'dragonforge_save_damaged';

function createStorage() {
  const data = new Map();
  const faults = { read: false, write: null, remove: null };
  const storage = {
    getItem: vi.fn(key => {
      if (faults.read) throw new Error('Storage reads disabled');
      return data.get(key) ?? null;
    }),
    setItem: vi.fn((key, value) => {
      if (faults.write?.(key)) {
        throw Object.assign(new Error('Storage is full'), { name: 'QuotaExceededError' });
      }
      data.set(key, String(value));
    }),
    removeItem: vi.fn(key => {
      if (faults.remove?.(key)) throw new Error('Storage removal disabled');
      data.delete(key);
    }),
    clear: vi.fn(() => data.clear()),
  };
  return { data, faults, storage };
}

describe('save recovery through the persistence API', () => {
  let data;
  let faults;
  let storage;
  let api;
  let validSave;
  let original;

  async function reload() {
    vi.resetModules();
    api = await import('./persistence');
    return api;
  }

  beforeEach(async () => {
    ({ data, faults, storage } = createStorage());
    const fakeWindow = new EventTarget();
    fakeWindow.localStorage = storage;
    vi.stubGlobal('window', fakeWindow);
    vi.stubGlobal('localStorage', storage);
    await reload();
    validSave = api.loadSave();
    validSave.dragons.fire = { ...validSave.dragons.fire, owned: true, discovered: true, level: 7, xp: 80 };
    validSave.dataScraps = 321;
    validSave.stats.battlesWon = 4;
    validSave.flags.metFelix = true;
    validSave.activity = { ...validSave.activity, sessions: 4, playtimeMs: 6000 };
    original = JSON.stringify(validSave);
    data.set(PRIMARY, original);
    await reload();
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it('preserves malformed save bytes through startup, heartbeat, and ordinary writes', () => {
    const damaged = '{"dragons":{"fire":';
    data.set(PRIMARY, damaged);

    expect(() => api.beginSession()).not.toThrow();
    expect(() => api.accumulatePlaytime()).not.toThrow();
    expect(api.writeSave(validSave)).toBe(false);

    expect(data.get(PRIMARY)).toBe(damaged);
    expect(api.getSaveStatus().blocked).toBe(true);
    expect(api.getSaveDownload('damaged')?.content).toBe(damaged);
  });

  it('rejects invalid nested progress without converting it into a new game', async () => {
    for (const invalid of [
      { ...validSave, dragons: { ...validSave.dragons, fire: null } },
      { ...validSave, inventory: null },
      { ...validSave, activity: [] },
    ]) {
      const raw = JSON.stringify(invalid);
      data.set(PRIMARY, raw);
      await reload();
      expect(() => api.beginSession()).not.toThrow();
      expect(api.writeSave(validSave)).toBe(false);
      expect(data.get(PRIMARY)).toBe(raw);
      expect(api.getSaveStatus().blocked).toBe(true);
    }
  });

  it('offers a valid backup without restoring it until explicitly requested', () => {
    const damaged = '{"dataScraps":';
    data.set(PRIMARY, damaged);
    data.set(BACKUP, original);

    api.loadSave();
    api.beginSession();
    expect(data.get(PRIMARY)).toBe(damaged);
    expect(api.getSaveStatus()).toMatchObject({ blocked: true, canRestore: true });

    expect(api.restoreSaveBackup().ok).toBe(true);
    expect(data.get(DAMAGED)).toBe(damaged);
    expect(api.loadSave().dragons.fire.level).toBe(7);
    expect(api.loadSave().dataScraps).toBe(321);
    expect(api.getSaveStatus().blocked).toBe(false);
  });

  it('does not replace damaged progress if archiving the original bytes fails', () => {
    const damaged = 'original damaged progress';
    data.set(PRIMARY, damaged);
    data.set(BACKUP, original);
    faults.write = key => key === DAMAGED;
    api.loadSave();

    expect(api.restoreSaveBackup().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(damaged);
    expect(data.get(BACKUP)).toBe(original);
    expect(api.getSaveStatus().blocked).toBe(true);
  });

  it('rejects malformed or invalid imports without changing any saved bytes', () => {
    data.set(BACKUP, original);
    api.loadSave();
    const before = [...data];

    for (const text of ['{broken', JSON.stringify({ dragons: { fire: null } }), '[]']) {
      expect(api.previewSaveImport(text).ok).toBe(false);
      expect(api.importSave(text).ok).toBe(false);
      expect([...data]).toEqual(before);
    }
    expect(api.loadSave().dataScraps).toBe(321);
  });

  it('backs up the prior valid snapshot when saving new progress', () => {
    const first = api.loadSave();
    first.dataScraps += 25;
    expect(api.writeSave(first)).toBe(true);
    expect(data.get(BACKUP)).toBe(original);

    const priorPrimary = data.get(PRIMARY);
    const second = api.loadSave();
    second.dragons.fire.level += 1;
    expect(api.writeSave(second)).toBe(true);
    expect(data.get(BACKUP)).toBe(priorPrimary);
    expect(JSON.parse(data.get(PRIMARY)).dragons.fire.level).toBe(8);
  });

  it('survives a throwing localStorage getter without erasing existing progress', () => {
    Object.defineProperty(window, 'localStorage', {
      configurable: true,
      get() { throw new Error('Storage access denied'); },
    });

    expect(() => api.loadSave()).not.toThrow();
    expect(() => api.beginSession()).not.toThrow();
    expect(() => api.accumulatePlaytime()).not.toThrow();
    expect(api.writeSave(validSave)).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    expect(api.getSaveStatus().message).toBeTruthy();
  });

  it('never writes defaults over progress that storage temporarily refuses to read', () => {
    faults.read = true;
    expect(() => api.beginSession()).not.toThrow();
    expect(api.writeSave(validSave)).toBe(false);
    expect(api.retrySave().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    expect(storage.setItem).not.toHaveBeenCalled();
  });

  it('retains consecutive failed writes in memory and exports them before retrying', () => {
    const first = api.loadSave();
    faults.write = () => true;
    first.dataScraps += 50;
    expect(api.writeSave(first)).toBe(false);

    const second = api.loadSave();
    expect(second.dataScraps).toBe(371);
    second.dragons.fire.xp += 20;
    expect(api.writeSave(second)).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    const exported = api.getSaveDownload();
    expect(exported.name).toMatch(/\.json$/);
    expect(JSON.parse(exported.content)).toMatchObject({
      dataScraps: 371,
      dragons: { fire: { xp: 100 } },
    });

    faults.write = null;
    expect(api.retrySave().ok).toBe(true);
    expect(JSON.parse(data.get(PRIMARY))).toMatchObject({
      dataScraps: 371,
      dragons: { fire: { xp: 100 } },
    });
    expect(data.get(BACKUP)).toBe(original);
  });

  it('preserves the primary when writing it fails after the backup succeeds', () => {
    const next = api.loadSave();
    next.dataScraps = 900;
    faults.write = key => key === PRIMARY;

    expect(api.writeSave(next)).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    expect(data.get(BACKUP)).toBe(original);
    expect(api.loadSave().dataScraps).toBe(900);

    faults.write = null;
    expect(api.retrySave().ok).toBe(true);
    expect(JSON.parse(data.get(PRIMARY)).dataScraps).toBe(900);
  });

  it('fills omitted legacy fields while preserving owned dragons and earned currency', () => {
    const legacy = {
      dragons: { fire: { level: 9, xp: 17 } },
      dataScraps: 777,
      stats: { battlesWon: 3 },
      flags: { metFelix: true },
    };
    data.set(PRIMARY, JSON.stringify(legacy));

    const loaded = api.loadSave();
    expect(loaded.dataScraps).toBe(777);
    expect(loaded.dragons.fire).toMatchObject({ level: 9, xp: 17, owned: true, discovered: true });
    expect(loaded.dragons.ice).toMatchObject({ level: 1, owned: false });
    expect(loaded.stats).toMatchObject({ battlesWon: 3, battlesLost: 0 });
    expect(loaded.flags.metFelix).toBe(true);
    expect(loaded.activity.playtimeMs).toBe(0);
    expect(api.writeSave(loaded)).toBe(true);
  });

  it('does not offer or restore an invalid backup', () => {
    const damaged = 'primary damaged';
    data.set(PRIMARY, damaged);
    data.set(BACKUP, '{backup damaged');
    api.loadSave();

    expect(api.getSaveStatus().canRestore).toBe(false);
    expect(api.restoreSaveBackup().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(damaged);
    expect(data.get(BACKUP)).toBe('{backup damaged');
  });

  it('keeps the original damaged save when restoring the primary fails', () => {
    const damaged = 'primary damaged';
    data.set(PRIMARY, damaged);
    data.set(BACKUP, original);
    faults.write = key => key === PRIMARY;
    api.loadSave();

    expect(api.restoreSaveBackup().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(damaged);
    expect(data.get(BACKUP)).toBe(original);
    expect(api.getSaveStatus().blocked).toBe(true);
  });

  it('cannot resurrect pre-reset progress from the backup after a successful reset', async () => {
    data.set(BACKUP, original);
    api.loadSave();
    expect(api.resetSave().ok).toBe(true);
    await reload();

    expect(api.loadSave().dragons.fire.owned).toBe(false);
    expect(api.loadSave().dataScraps).toBe(0);
    expect(api.getSaveStatus().canRestore).toBe(false);
    expect(api.restoreSaveBackup().ok).toBe(false);
  });

  it('does not erase the primary when a requested reset cannot be saved', () => {
    api.loadSave();
    faults.write = () => true;
    faults.remove = () => true;
    expect(api.resetSave().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    expect(api.loadSave().dragons.fire.owned).toBe(true);
  });

  it('stops retry from overwriting an external save changed while writes were pending', () => {
    const pending = api.loadSave();
    pending.dataScraps = 500;
    faults.write = () => true;
    expect(api.writeSave(pending)).toBe(false);

    const externalRaw = JSON.stringify({ ...validSave, dataScraps: 800 });
    data.set(PRIMARY, externalRaw);
    faults.write = null;
    expect(api.retrySave().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(externalRaw);
    expect(JSON.parse(api.getSaveDownload().content).dataScraps).toBe(500);
  });

  it('previews an import without writing and preserves the previous save on import', () => {
    api.loadSave();
    const incoming = { ...validSave, dataScraps: 1234 };
    const text = JSON.stringify(incoming);
    const before = [...data];

    expect(api.previewSaveImport(text)).toMatchObject({ ok: true });
    expect([...data]).toEqual(before);
    expect(api.importSave(text).ok).toBe(true);
    expect(api.loadSave().dataScraps).toBe(1234);
    expect(data.get(BACKUP)).toBe(original);
  });

  it('restores already removed recovery copies when reset cleanup fails partway through', () => {
    data.set(BACKUP, original);
    data.set(DAMAGED, 'first damaged save');
    data.set(`${DAMAGED}_1`, 'second damaged save');
    api.loadSave();
    const before = [...data].sort();
    faults.remove = key => key === `${DAMAGED}_1`;

    expect(api.resetSave().ok).toBe(false);
    expect([...data].sort()).toEqual(before);
    expect(api.loadSave().dataScraps).toBe(321);
  });

  it('restores recovery copies if reset reaches the final primary write and fails', () => {
    data.set(BACKUP, original);
    data.set(DAMAGED, 'damaged save to preserve');
    api.loadSave();
    const before = [...data].sort();
    faults.write = key => key === PRIMARY;

    expect(api.resetSave().ok).toBe(false);
    expect([...data].sort()).toEqual(before);
    expect(api.loadSave().dragons.fire.level).toBe(7);
  });

  it('reloads existing progress when unavailable storage recovers before starting a session', () => {
    faults.read = true;
    api.beginSession();
    expect(api.getSaveStatus().blocked).toBe(true);
    expect(data.get(PRIMARY)).toBe(original);

    faults.read = false;
    expect(api.retrySave().ok).toBe(true);
    expect(data.get(PRIMARY)).toBe(original);
    expect(api.loadSave().dataScraps).toBe(321);
    api.beginSession();
    expect(api.loadSave().activity.sessions).toBe(5);
    expect(api.loadSave().dragons.fire.level).toBe(7);
  });

  it('keeps both damaged originals if a recovered save is damaged again later', async () => {
    data.set(PRIMARY, 'first corruption');
    data.set(BACKUP, original);
    api.loadSave();
    expect(api.restoreSaveBackup().ok).toBe(true);

    data.set(PRIMARY, 'second corruption');
    await reload();
    api.loadSave();
    expect(api.restoreSaveBackup().ok).toBe(true);
    expect(data.get(DAMAGED)).toBe('first corruption');
    expect(data.get(`${DAMAGED}_1`)).toBe('second corruption');
    expect(api.getSaveDownload('damaged').content).toBe('second corruption');
  });

  it('preserves the chosen backup if restoring over a valid primary fails', () => {
    const backup = JSON.stringify({ ...validSave, dataScraps: 100 });
    data.set(BACKUP, backup);
    api.loadSave();
    faults.write = key => key === PRIMARY;

    expect(api.restoreSaveBackup().ok).toBe(false);
    expect(data.get(PRIMARY)).toBe(original);
    expect(data.get(BACKUP)).toBe(backup);
    faults.write = null;
    expect(api.restoreSaveBackup().ok).toBe(true);
    expect(api.loadSave().dataScraps).toBe(100);
  });

  it('keeps pending progress downloadable if loading the stored save fails midway', () => {
    const pending = api.loadSave();
    pending.dataScraps = 500;
    faults.write = () => true;
    expect(api.writeSave(pending)).toBe(false);

    let reads = 0;
    storage.getItem.mockImplementation(key => {
      if (key === PRIMARY && ++reads > 1) throw new Error('Storage access revoked');
      return data.get(key) ?? null;
    });
    const result = api.reloadStoredSave();
    const downloaded = JSON.parse(api.getSaveDownload().content);

    // A successful single read may replace the session. A reported failure must
    // retain the unsaved progress that prompted the recovery action.
    expect(downloaded.dataScraps).toBe(result.ok ? 321 : 500);
    expect(data.get(PRIMARY)).toBe(original);
  });

  it('retains the invalid-write warning across reads and exports the last valid progress', () => {
    const current = api.loadSave();
    expect(api.writeSave({ ...current, dragons: { ...current.dragons, fire: null } })).toBe(false);
    const warning = api.getSaveStatus().message;
    expect(warning).toBeTruthy();

    expect(api.loadSave().dragons.fire.level).toBe(7);
    expect(api.getSaveStatus().message).toBe(warning);
    expect(JSON.parse(api.getSaveDownload().content)).toMatchObject({
      dataScraps: 321, dragons: { fire: { owned: true, level: 7 } },
    });
    expect(data.get(PRIMARY)).toBe(original);
  });

  it('keeps a valid session downloadable when the stored main save becomes corrupt', () => {
    api.loadSave();
    const damaged = '{corrupted while playing';
    data.set(PRIMARY, damaged);

    expect(api.loadSave().dataScraps).toBe(321);
    expect(api.getSaveStatus()).toMatchObject({ blocked: true, canExport: true });
    expect(api.writeSave(validSave)).toBe(false);
    expect(JSON.parse(api.getSaveDownload().content).dragons.fire.level).toBe(7);
    expect(api.getSaveDownload('damaged').content).toBe(damaged);
    expect(data.get(PRIMARY)).toBe(damaged);
  });

  it('keeps a valid session downloadable and blocked if the main save is deleted', () => {
    api.loadSave();
    data.delete(PRIMARY);

    expect(api.loadSave().dataScraps).toBe(321);
    expect(api.getSaveStatus()).toMatchObject({ blocked: true, canExport: true });
    expect(api.writeSave(validSave)).toBe(false);
    expect(api.retrySave().ok).toBe(false);
    expect(api.getSaveStatus().blocked).toBe(true);
    expect(JSON.parse(api.getSaveDownload().content).dragons.fire.level).toBe(7);
    expect(data.has(PRIMARY)).toBe(false);
  });
});
