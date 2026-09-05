// Storage is deliberately separate from migrations. A failed write keeps the
// current session in memory; a failed read never authorizes a fresh-game write.
const PRIMARY = 'dragonforge_save';
const BACKUP = 'dragonforge_save_backup';
const DAMAGED = 'dragonforge_save_damaged';
const clone = value => structuredClone(value);
const failure = error => ({ ok: false, error });

export const READY_SAVE_STATUS = Object.freeze({
  mode: 'ready', blocked: false, canRestore: false, canExport: true,
  canExportDamaged: false, message: '',
});

export function createSaveStorage({ getStorage, makeDefault, decode }) {
  let initialized = false;
  let current = makeDefault();
  let validCurrent = false;
  let expectedRaw = null;
  let backupRaw = null;
  let damagedRaw = null;
  let pending = null;
  let rejectedWrite = false;
  let status = READY_SAVE_STATUS;
  const listeners = new Set();

  function valid(raw) {
    if (raw === null) return false;
    try { decode(raw); return true; } catch { return false; }
  }

  function report(mode, message = '') {
    const next = {
      mode, blocked: ['recovery', 'unavailable', 'conflict'].includes(mode),
      canRestore: valid(backupRaw), canExport: validCurrent,
      canExportDamaged: damagedRaw !== null, message,
    };
    if (JSON.stringify(next) !== JSON.stringify(status)) {
      status = Object.freeze(next);
      listeners.forEach(listener => listener());
    }
  }

  // Keep each damaged original, including a second corruption after a recovery.
  function archives(storage) {
    const entries = [];
    for (let i = 0; ; i++) {
      const key = i ? `${DAMAGED}_${i}` : DAMAGED;
      const raw = storage.getItem(key);
      if (raw === null) return entries;
      entries.push([key, raw]);
    }
  }

  function read() {
    initialized = true;
    rejectedWrite = false;
    try {
      const storage = getStorage();
      const raw = storage.getItem(PRIMARY);
      backupRaw = storage.getItem(BACKUP);
      const savedArchives = archives(storage);
      damagedRaw = savedArchives.at(-1)?.[1] ?? null;
      const hadPrimary = expectedRaw !== null || (status.mode === 'recovery' && validCurrent);
      expectedRaw = raw;
      if (raw !== null) {
        try {
          current = decode(raw);
          validCurrent = true;
          report('ready');
        } catch {
          // A good snapshot from this session is still worth downloading even
          // if another tab or an external tool damages the stored copy.
          if (!validCurrent) current = makeDefault();
          damagedRaw = raw;
          report('recovery', 'Your saved progress could not be read. Restore a backup or import a save to continue.');
        }
      } else if (backupRaw !== null || hadPrimary) {
        if (!validCurrent) current = makeDefault();
        report('recovery', 'The main save is missing. Check the backup or import a save before starting again.');
      } else {
        current = makeDefault();
        validCurrent = true;
        report('ready');
      }
    } catch {
      report(validCurrent ? 'unsaved' : 'unavailable',
        'Browser storage is unavailable. Allow storage and retry, or download any progress from this session.');
    }
  }

  function load() {
    if (!initialized || (!pending && !rejectedWrite && !status.blocked)) read();
    return clone(pending ?? current);
  }

  function flush() {
    try {
      const storage = getStorage();
      if (storage.getItem(PRIMARY) !== expectedRaw) {
        report('conflict', 'Saved progress changed in another tab. Download this session before loading the saved progress.');
        return false;
      }
      const raw = JSON.stringify(pending);
      if (raw !== expectedRaw) {
        // Never sacrifice the main save if its safety copy cannot be written.
        const backup = expectedRaw ?? raw;
        storage.setItem(BACKUP, backup);
        backupRaw = backup;
        storage.setItem(PRIMARY, raw);
      }
      expectedRaw = raw;
      current = pending;
      pending = null;
      validCurrent = true;
      report('ready');
      return true;
    } catch {
      report('unsaved', 'Progress is only in this tab because saving failed. Keep this tab open, retry, or download your progress.');
      return false;
    }
  }

  function write(save) {
    if (!initialized) read();
    if (status.blocked) return false;
    try { pending = decode(JSON.stringify(save)); } catch {
      rejectedWrite = true;
      report('unsaved', 'An invalid progress update could not be saved. Your last valid progress is available to download.');
      return false;
    }
    rejectedWrite = false;
    validCurrent = true;
    return flush();
  }

  function retry() {
    if (pending) return flush() ? { ok: true } : failure(status.message);
    read();
    return status.blocked || status.mode === 'unsaved' ? failure(status.message) : { ok: true };
  }

  // Imports/restores are explicit replacements. Failed replacements must not
  // become pending game writes or silently replace the session being played.
  function replace(save) {
    let next;
    try {
      next = decode(JSON.stringify(save));
      delete next.activity.sessionStart;
    } catch (error) { return failure(error.message); }
    let storage;
    let previousBackup;
    let rotatedBackup = false;
    try {
      storage = getStorage();
      previousBackup = storage.getItem(BACKUP);
      const previous = storage.getItem(PRIMARY);
      if (previous !== null && !valid(previous)) {
        const entries = archives(storage);
        if (!entries.some(([, raw]) => raw === previous)) {
          storage.setItem(entries.length ? `${DAMAGED}_${entries.length}` : DAMAGED, previous);
        }
        damagedRaw = previous;
      } else if (previous !== null) {
        storage.setItem(BACKUP, previous);
        backupRaw = previous;
        rotatedBackup = true;
      } else if (!valid(previousBackup)) {
        storage.setItem(BACKUP, JSON.stringify(next));
        backupRaw = JSON.stringify(next);
        rotatedBackup = true;
      }
      const raw = JSON.stringify(next);
      storage.setItem(PRIMARY, raw);
      expectedRaw = raw;
      current = next;
      pending = null;
      rejectedWrite = false;
      initialized = true;
      validCurrent = true;
      report('ready');
      return { ok: true };
    } catch {
      // In particular, a failed restore must leave its target backup available
      // for another attempt, even when the current main save is also valid.
      if (rotatedBackup) {
        try {
          if (previousBackup === null) storage.removeItem(BACKUP);
          else storage.setItem(BACKUP, previousBackup);
          backupRaw = previousBackup;
        } catch { /* The untouched main save still preserves current progress. */ }
      }
      return failure('The save could not be replaced. Free browser storage or allow storage access, then retry.');
    }
  }

  function restore() {
    try {
      const raw = getStorage().getItem(BACKUP);
      if (!valid(raw)) return failure('No readable backup is available.');
      return replace(decode(raw));
    } catch { return failure('The backup could not be read. Allow browser storage and retry.'); }
  }

  function reset() {
    // Remove recovery copies before committing the new game. If any operation
    // fails, retain the main save and attempt to restore already removed copies.
    let storage;
    const removed = [];
    try {
      storage = getStorage();
      const copies = [[BACKUP, storage.getItem(BACKUP)], ...archives(storage)];
      for (const [key, raw] of copies) {
        if (raw !== null) {
          storage.removeItem(key);
          removed.push([key, raw]);
        }
      }
      const next = makeDefault();
      const raw = JSON.stringify(next);
      storage.setItem(PRIMARY, raw);
      current = next;
      expectedRaw = raw;
      pending = null;
      rejectedWrite = false;
      backupRaw = null;
      damagedRaw = null;
      initialized = true;
      validCurrent = true;
      report('ready');
      return { ok: true };
    } catch {
      for (const [key, raw] of removed) {
        try { storage.setItem(key, raw); } catch { /* Main save remains untouched. */ }
      }
      return failure('Progress could not be reset. Allow browser storage and retry.');
    }
  }

  function reloadStored() {
    // Gather and validate everything before discarding the pending session.
    try {
      const storage = getStorage();
      const raw = storage.getItem(PRIMARY);
      const backup = storage.getItem(BACKUP);
      const damaged = archives(storage).at(-1)?.[1] ?? null;
      if (raw === null && backup !== null) throw new Error('Missing main save');
      const next = raw === null ? makeDefault() : decode(raw);
      delete next.activity.sessionStart;
      pending = null;
      rejectedWrite = false;
      current = next;
      expectedRaw = raw;
      backupRaw = backup;
      damagedRaw = damaged;
      validCurrent = true;
      initialized = true;
      report('ready');
      return { ok: true };
    } catch {
      return failure('Saved progress is not readable. Download this session or import a save.');
    }
  }

  function download(kind = 'current') {
    if (!initialized) read();
    let content = null;
    if (kind === 'current' && validCurrent) content = JSON.stringify(pending ?? current, null, 2);
    if (kind === 'backup' && valid(backupRaw)) content = backupRaw;
    if (kind === 'damaged') content = damagedRaw;
    return content === null ? null : { name: `dragon-forge-${kind}.json`, content };
  }

  return {
    load, write, retry, replace, restore, reset, reloadStored, download,
    getStatus: () => status,
    subscribe: listener => { listeners.add(listener); return () => listeners.delete(listener); },
  };
}
