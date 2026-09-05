import { useId, useRef, useState, useSyncExternalStore } from 'react';
import {
  getSaveStatus, subscribeSaveStatus, retrySave, restoreSaveBackup,
  importSave, resetSave, getSaveDownload, previewSaveImport, reloadStoredSave,
} from './persistence';

const MAX_SAVE_FILE_BYTES = 1024 * 1024;

export function useSaveStatus() {
  return useSyncExternalStore(subscribeSaveStatus, getSaveStatus, getSaveStatus);
}

export async function readSaveFile(file) {
  if (!file) return { ok: false, error: 'Choose a save file first.' };
  if (file.size > MAX_SAVE_FILE_BYTES) return { ok: false, error: 'Save files must be 1 MiB or smaller.' };
  try {
    const text = await file.text();
    const preview = previewSaveImport(text);
    return preview.ok ? { ...preview, text } : preview;
  } catch {
    return { ok: false, error: 'This file could not be read. Please choose it again.' };
  }
}

export function downloadSave(kind = 'current') {
  let url;
  let link;
  try {
    const download = getSaveDownload(kind);
    if (!download) return { ok: false, error: 'No save is available to download.' };
    url = URL.createObjectURL(new Blob([download.content], { type: 'application/json' }));
    link = document.createElement('a');
    link.href = url;
    link.download = download.name;
    document.body.appendChild(link);
    link.click();
    return { ok: true };
  } catch {
    return { ok: false, error: 'The download could not start. Please try again.' };
  } finally {
    link?.remove();
    // Give the browser time to consume the URL before releasing it.
    if (url) setTimeout(() => URL.revokeObjectURL(url), 1000);
  }
}

export function SaveStatusBanner() {
  const status = useSaveStatus();
  const [error, setError] = useState('');
  if (status.blocked || status.mode === 'ready') return null;

  function retry() {
    const result = retrySave();
    setError(result.ok ? '' : result.error || 'Progress is still not saved. Download a copy before closing.');
  }

  function download() {
    const result = downloadSave();
    setError(result.ok ? '' : result.error);
  }

  return (
    <aside className="save-warning" aria-label="Save warning">
      <div role="status" aria-live="polite">
        <strong>PROGRESS NOT SAVED</strong>
        <p>{status.message || 'Keep this page open. Download your progress before closing.'}</p>
      </div>
      <div className="save-actions">
        <button type="button" className="settings-btn" onClick={retry}>RETRY SAVE</button>
        {status.canExport && <button type="button" className="settings-btn" onClick={download}>DOWNLOAD PROGRESS</button>}
      </div>
      {error && <p className="save-error" role="alert">{error}</p>}
    </aside>
  );
}

export function SaveDataControls({ recovery = false, onChange = () => {} }) {
  const status = useSaveStatus();
  const [pendingImport, setPendingImport] = useState(null);
  const [confirmation, setConfirmation] = useState(null);
  const [busy, setBusy] = useState(false);
  const [feedback, setFeedback] = useState(null);
  const fileRequest = useRef(0);
  const fileInputId = useId();

  function complete(result, successMessage) {
    if (!result.ok) {
      setFeedback({ error: true, text: result.error || 'The save could not be updated. Your progress has not been replaced.' });
      return;
    }
    setPendingImport(null);
    setConfirmation(null);
    setFeedback({ error: false, text: successMessage });
    onChange();
  }

  function download(kind) {
    const result = downloadSave(kind);
    setFeedback({ error: !result.ok, text: result.ok ? 'Download started. Keep a copy somewhere safe.' : result.error });
  }

  async function chooseFile(event) {
    const file = event.target.files?.[0];
    event.target.value = '';
    if (!file) return;
    const request = ++fileRequest.current;
    setBusy(true);
    setFeedback(null);
    setConfirmation(null);
    setPendingImport(null);
    const result = await readSaveFile(file);
    if (request !== fileRequest.current) return;
    setBusy(false);
    if (!result.ok) {
      setFeedback({ error: true, text: result.error });
      return;
    }
    setPendingImport({ text: result.text, summary: result.summary, name: file.name });
  }

  function askConfirmation(action) {
    setFeedback(null);
    setPendingImport(null);
    setConfirmation(action);
  }

  return (
    <div className="save-data-controls">
      {recovery && (
        <div className="save-actions">
          <button type="button" className="settings-btn" onClick={() => complete(retrySave(), 'Your save is ready.')}>TRY AGAIN</button>
          {status.mode === 'conflict' && <button type="button" className="settings-btn" disabled={busy} onClick={() => askConfirmation('reload')}>LOAD SAVED PROGRESS</button>}
        </div>
      )}

      <div className="settings-option">
        <div>
          <div className="settings-option-name">Keep a copy</div>
          <div className="settings-option-desc">Download your progress to restore it here or on another device.</div>
        </div>
        <div className="save-actions">
          {status.canExport && <button type="button" className="settings-btn" onClick={() => download('current')}>DOWNLOAD PROGRESS</button>}
          {status.canExportDamaged && <button type="button" className="settings-btn" onClick={() => download('damaged')}>DOWNLOAD DAMAGED SAVE</button>}
          {status.canRestore && <button type="button" className="settings-btn" onClick={() => download('backup')}>DOWNLOAD BACKUP</button>}
        </div>
      </div>

      {status.canRestore && (
        <div className="settings-option">
          <div>
            <div className="settings-option-name">Previous save</div>
            <div className="settings-option-desc">Restore the last backup. Progress made since that backup will be replaced.</div>
          </div>
          <button type="button" className="settings-btn" disabled={busy} onClick={() => askConfirmation('restore')}>RESTORE BACKUP</button>
        </div>
      )}

      <div className="save-import">
        <label className="settings-option-name" htmlFor={fileInputId}>Import a save file</label>
        <p className="settings-option-desc" id={`${fileInputId}-help`}>Choose a Dragon Forge JSON save, up to 1 MiB. You can review it before replacing your progress.</p>
        <input id={fileInputId} type="file" accept=".json,application/json" disabled={busy}
          aria-describedby={`${fileInputId}-help`} onChange={chooseFile} />
        {busy && <p className="save-feedback" role="status">Reading save…</p>}
      </div>

      {pendingImport && (
        <div className="save-confirmation" role="group" aria-label="Confirm save import">
          <p className="settings-option-name">Ready to import: {pendingImport.name}</p>
          <dl className="save-preview">
            <div><dt>Dragons</dt><dd>{pendingImport.summary.ownedDragons}</dd></div>
            <div><dt>Battles won</dt><dd>{pendingImport.summary.battlesWon}</dd></div>
            <div><dt>Data scraps</dt><dd>{pendingImport.summary.dataScraps}</dd></div>
          </dl>
          <p className="settings-option-desc">Confirming will replace your current progress with this save. Download your progress first if you want to keep it.</p>
          <div className="save-actions">
            <button type="button" className="settings-btn" onClick={() => complete(importSave(pendingImport.text), 'Save imported.')}>CONFIRM IMPORT</button>
            <button type="button" className="settings-btn" onClick={() => setPendingImport(null)}>CANCEL</button>
          </div>
        </div>
      )}

      {confirmation === 'restore' && (
        <div className="save-confirmation" role="group" aria-label="Confirm backup restore">
          <p className="settings-option-name">Replace current progress with the previous backup?</p>
          <div className="save-actions">
            <button type="button" className="settings-btn" onClick={() => complete(restoreSaveBackup(), 'Previous save restored.')}>CONFIRM RESTORE</button>
            <button type="button" className="settings-btn" onClick={() => setConfirmation(null)}>CANCEL</button>
          </div>
        </div>
      )}

      {confirmation === 'reload' && (
        <div className="save-confirmation" role="group" aria-label="Confirm loading saved progress">
          <p className="settings-option-name">Load the progress saved by the other tab?</p>
          <p className="settings-option-desc">Unsaved changes from this session will be discarded. Download your progress first if you want to keep a copy.</p>
          <div className="save-actions">
            <button type="button" className="settings-btn" onClick={() => complete(reloadStoredSave(), 'Saved progress loaded.')}>CONFIRM LOAD</button>
            <button type="button" className="settings-btn" onClick={() => setConfirmation(null)}>CANCEL</button>
          </div>
        </div>
      )}

      <div className="settings-option save-reset">
        <div>
          <div className="settings-option-name">Start a new game</div>
          <div className="settings-option-desc">Replace your saved progress with a fresh start. Download any save you want to keep first.</div>
        </div>
        <button type="button" className="settings-btn" disabled={busy} onClick={() => askConfirmation('reset')}>START NEW GAME</button>
      </div>

      {confirmation === 'reset' && (
        <div className="save-confirmation" role="group" aria-label="Confirm progress reset">
          <p className="settings-option-name">Delete saved progress and start over?</p>
          <p className="settings-option-desc">This deletes your saved progress, backup, and damaged save copies. It cannot be undone. Download anything you want to keep before confirming.</p>
          <div className="save-actions">
            <button type="button" className="settings-btn settings-btn-danger" onClick={() => complete(resetSave(), 'Progress reset. Your new game is ready.')}>DELETE PROGRESS</button>
            <button type="button" className="settings-btn" onClick={() => setConfirmation(null)}>CANCEL</button>
          </div>
        </div>
      )}

      {feedback && <p className={feedback.error ? 'save-error' : 'save-feedback'} role={feedback.error ? 'alert' : 'status'}>{feedback.text}</p>}
    </div>
  );
}

export default function SaveRecovery({ onRecovered }) {
  const status = useSaveStatus();
  return (
    <main className="save-recovery" aria-labelledby="save-recovery-title">
      <h1 id="save-recovery-title">SAVE RECOVERY</h1>
      <div className="save-recovery-message" role="alert">
        <p>{status.message || 'Your save needs attention before you can continue.'}</p>
        <p>Your existing save will stay untouched until you choose a recovery action.</p>
      </div>
      <SaveDataControls recovery onChange={onRecovered} />
    </main>
  );
}
