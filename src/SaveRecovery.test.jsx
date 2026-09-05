import { beforeEach, describe, expect, it, vi } from 'vitest';
import { renderToStaticMarkup } from 'react-dom/server';
import App from './App';
import SettingsScreen from './SettingsScreen';
import SaveRecovery, { SaveDataControls, SaveStatusBanner, readSaveFile, downloadSave } from './SaveRecovery';
import { importSave, previewSaveImport, resetSave, restoreSaveBackup, retrySave, getSaveDownload, reloadStoredSave, beginSession, accumulatePlaytime } from './persistence';

const controls = vi.hoisted(() => ({
  status: {}, hooks: [], cursor: 0, directRender: false, captureEffects: false, effects: [], effectDependencies: [],
}));

vi.mock('./persistence', async importOriginal => {
  const original = await importOriginal();
  return {
    ...original,
    getSaveStatus: () => controls.status,
    subscribeSaveStatus: () => () => {},
    retrySave: vi.fn(), restoreSaveBackup: vi.fn(), importSave: vi.fn(), resetSave: vi.fn(), reloadStoredSave: vi.fn(),
    getSaveDownload: vi.fn(), previewSaveImport: vi.fn(),
    beginSession: vi.fn(), accumulatePlaytime: vi.fn(),
  };
});

vi.mock('./TitleScreen', () => ({ default: () => <div>GAME TITLE SCREEN</div> }));

// Exercise the component's real button/file handlers with persistent hook state.
// The project uses Vitest's node environment; SSR separately verifies its markup.
vi.mock('react', async importOriginal => {
  const original = await importOriginal();
  return {
    ...original,
    useState(initial) {
      if (!controls.directRender) return original.useState(initial);
      const index = controls.cursor++;
      if (!(index in controls.hooks)) controls.hooks[index] = typeof initial === 'function' ? initial() : initial;
      return [controls.hooks[index], value => { controls.hooks[index] = typeof value === 'function' ? value(controls.hooks[index]) : value; }];
    },
    useRef(initial) {
      if (!controls.directRender) return original.useRef(initial);
      const index = controls.cursor++;
      return controls.hooks[index] ??= { current: initial };
    },
    useId: () => controls.directRender ? 'save-file' : original.useId(),
    useSyncExternalStore(...args) {
      return controls.directRender ? args[1]() : original.useSyncExternalStore(...args);
    },
    useEffect(effect, dependencies) {
      if (controls.captureEffects) controls.effects.push(effect);
      if (controls.directRender) {
        controls.effects.push(effect);
        controls.effectDependencies.push(dependencies);
        return;
      }
      return original.useEffect(effect, dependencies);
    },
  };
});

function renderControls(props = {}) {
  controls.directRender = true;
  controls.cursor = 0;
  try { return SaveDataControls(props); }
  finally { controls.directRender = false; }
}

function renderAppDirect() {
  controls.directRender = true;
  controls.cursor = 0;
  controls.effects = [];
  controls.effectDependencies = [];
  try { return App(); }
  finally { controls.directRender = false; }
}

function findAll(node, predicate) {
  if (!node || typeof node !== 'object') return [];
  if (Array.isArray(node)) return node.flatMap(child => findAll(child, predicate));
  return [...(predicate(node) ? [node] : []), ...findAll(node.props?.children, predicate)];
}

function button(tree, text) {
  return findAll(tree, node => node.type === 'button' && node.props.children === text)[0];
}

beforeEach(() => {
  vi.clearAllMocks();
  controls.status = { mode: 'ready', blocked: false, canRestore: true, canExport: true, canExportDamaged: false, message: '' };
  controls.hooks = [];
  controls.cursor = 0;
  controls.directRender = false;
  controls.captureEffects = false;
  controls.effects = [];
  controls.effectDependencies = [];
  beginSession.mockReturnValue({ daysAway: 0, grant: 0 });
  previewSaveImport.mockReturnValue({ ok: true, summary: { ownedDragons: 3, battlesWon: 12, dataScraps: 48 } });
  for (const action of [retrySave, restoreSaveBackup, importSave, resetSave, reloadStoredSave]) action.mockReturnValue({ ok: true });
});

describe('save file preparation', () => {
  it('previews a file without importing it', async () => {
    const result = await readSaveFile({ size: 12, text: async () => '{"version":1}' });
    expect(result).toMatchObject({ ok: true, text: '{"version":1}', summary: { ownedDragons: 3 } });
    expect(importSave).not.toHaveBeenCalled();
  });

  it('rejects oversized files before reading or parsing', async () => {
    const file = { size: 1024 * 1024 + 1, text: vi.fn() };
    expect(await readSaveFile(file)).toMatchObject({ ok: false });
    expect(file.text).not.toHaveBeenCalled();
    expect(previewSaveImport).not.toHaveBeenCalled();
  });

  it('reports read and validation failures without importing', async () => {
    expect(await readSaveFile({ size: 5, text: async () => { throw new Error('read failed'); } })).toMatchObject({ ok: false });
    previewSaveImport.mockReturnValueOnce({ ok: false, error: 'Unsupported save version.' });
    expect(await readSaveFile({ size: 5, text: async () => 'null' })).toEqual({ ok: false, error: 'Unsupported save version.' });
    expect(importSave).not.toHaveBeenCalled();
  });
});

describe('save control confirmations', () => {
  it('requires explicit confirmation before importing the reviewed file', async () => {
    const onChange = vi.fn();
    let tree = renderControls({ onChange });
    const input = findAll(tree, node => node.type === 'input')[0];
    await input.props.onChange({ target: { files: [{ name: 'my-save.json', size: 12, text: async () => '{"version":1}' }], value: 'chosen' } });
    tree = renderControls({ onChange });
    expect(importSave).not.toHaveBeenCalled();
    expect(button(tree, 'CONFIRM IMPORT')).toBeDefined();
    button(tree, 'CONFIRM IMPORT').props.onClick();
    expect(importSave).toHaveBeenCalledExactlyOnceWith('{"version":1}');
    expect(onChange).toHaveBeenCalledOnce();
  });

  it('cancels import without writing any progress', async () => {
    let tree = renderControls();
    await findAll(tree, node => node.type === 'input')[0].props.onChange({ target: { files: [{ name: 'save.json', size: 5, text: async () => '{}' }], value: '' } });
    tree = renderControls();
    button(tree, 'CANCEL').props.onClick();
    expect(button(renderControls(), 'CONFIRM IMPORT')).toBeUndefined();
    expect(importSave).not.toHaveBeenCalled();
  });

  it.each([
    ['RESTORE BACKUP', 'CONFIRM RESTORE', restoreSaveBackup],
    ['START NEW GAME', 'DELETE PROGRESS', resetSave],
  ])('requires confirmation for %s and reports a failure without claiming success', (start, confirm, action) => {
    const onChange = vi.fn();
    action.mockReturnValue({ ok: false, error: 'Storage is full.' });
    button(renderControls({ onChange }), start).props.onClick();
    expect(action).not.toHaveBeenCalled();
    button(renderControls({ onChange }), confirm).props.onClick();
    expect(action).toHaveBeenCalledOnce();
    expect(onChange).not.toHaveBeenCalled();
    const alerts = findAll(renderControls({ onChange }), node => node.props?.role === 'alert');
    expect(alerts[0].props.children).toBe('Storage is full.');
    expect(button(renderControls({ onChange }), confirm)).toBeDefined();
  });

  it('reports reset complete only after a successful reset', () => {
    const onChange = vi.fn();
    button(renderControls({ onChange }), 'START NEW GAME').props.onClick();
    button(renderControls({ onChange }), 'DELETE PROGRESS').props.onClick();
    expect(onChange).toHaveBeenCalledOnce();
    const tree = renderControls({ onChange });
    expect(button(tree, 'DELETE PROGRESS')).toBeUndefined();
    expect(findAll(tree, node => node.props?.role === 'status')[0].props.children).toContain('Progress reset.');
  });

  it('requires confirmation before discarding session changes to load another tab’s save', () => {
    controls.status = { ...controls.status, mode: 'conflict', blocked: true };
    const onChange = vi.fn();
    button(renderControls({ recovery: true, onChange }), 'LOAD SAVED PROGRESS').props.onClick();
    expect(reloadStoredSave).not.toHaveBeenCalled();
    const tree = renderControls({ recovery: true, onChange });
    const copy = findAll(tree, node => node.type === 'p').map(node => node.props.children).join(' ');
    expect(copy).toContain('Unsaved changes from this session will be discarded');
    button(tree, 'CONFIRM LOAD').props.onClick();
    expect(reloadStoredSave).toHaveBeenCalledOnce();
    expect(onChange).toHaveBeenCalledOnce();
  });
});

describe('recovery and warning rendering', () => {
  it('restarts telemetry after a healthy save replacement while keeping Settings mounted', () => {
    vi.useFakeTimers();
    vi.stubGlobal('window', { addEventListener: vi.fn(), removeEventListener: vi.fn() });
    try {
      renderAppDirect();
      controls.hooks[0] = 'settings';
      const tree = renderAppDirect();
      const oldCleanup = controls.effects[0]();
      const oldDependencies = controls.effectDependencies[0];
      const settings = findAll(tree, node => node.type === SettingsScreen)[0];
      // This callback is invoked by SaveDataControls only after import, reset,
      // or restore succeeds. It must start the replacement save's session.
      settings.props.refreshSave();
      oldCleanup();
      expect(accumulatePlaytime).not.toHaveBeenCalled();
      const nextTree = renderAppDirect();
      expect(findAll(nextTree, node => node.type === SettingsScreen)).toHaveLength(1);
      expect(controls.effectDependencies[0]).not.toEqual(oldDependencies);
      const nextCleanup = controls.effects[0]();
      expect(beginSession).toHaveBeenCalledTimes(2);
      vi.advanceTimersByTime(60000);
      expect(accumulatePlaytime).toHaveBeenCalledOnce();
      nextCleanup();
    } finally {
      vi.unstubAllGlobals();
      vi.useRealTimers();
    }
  });

  it('does not start session writes while recovery blocks the game', () => {
    controls.status = { ...controls.status, mode: 'recovery', blocked: true };
    controls.captureEffects = true;
    renderToStaticMarkup(<App />);
    controls.effects.forEach(effect => effect());
    expect(beginSession).not.toHaveBeenCalled();
    expect(accumulatePlaytime).not.toHaveBeenCalled();
  });

  it('stops telemetry writes immediately when storage becomes blocked', () => {
    vi.useFakeTimers();
    vi.stubGlobal('window', { addEventListener: vi.fn(), removeEventListener: vi.fn() });
    try {
      controls.captureEffects = true;
      renderToStaticMarkup(<App />);
      const cleanups = controls.effects.map(effect => effect());
      expect(beginSession).toHaveBeenCalledOnce();
      controls.status = { ...controls.status, blocked: true };
      vi.advanceTimersByTime(60000);
      cleanups.forEach(cleanup => cleanup?.());
      expect(accumulatePlaytime).not.toHaveBeenCalled();
    } finally {
      vi.unstubAllGlobals();
      vi.useRealTimers();
    }
  });

  it.each(['recovery', 'unavailable', 'conflict'])('blocks game screen mounting during %s', mode => {
    controls.status = { ...controls.status, mode, blocked: true, canExportDamaged: true, message: 'Your save needs attention.' };
    const html = renderToStaticMarkup(<App />);
    expect(html).toContain('SAVE RECOVERY');
    expect(html).toContain('DOWNLOAD DAMAGED SAVE');
    expect(html).not.toContain('GAME TITLE SCREEN');
    expect(html).not.toContain('toast-container');
  });

  it('renders accessible recovery controls and a labelled file input', () => {
    controls.status = { ...controls.status, mode: 'recovery', blocked: true, canExport: false, canExportDamaged: true };
    const html = renderToStaticMarkup(<SaveRecovery onRecovered={() => {}} />);
    expect(html).toContain('aria-labelledby="save-recovery-title"');
    expect(html).toContain('type="file"');
    expect(html).toContain('DOWNLOAD DAMAGED SAVE');
    expect(html).toContain('RESTORE BACKUP');
    expect(html).not.toContain('CONFIRM IMPORT');
    expect(html).not.toContain('DELETE PROGRESS');
  });

  it('keeps the game and a nonmodal warning together after a failed write', () => {
    controls.status = { ...controls.status, mode: 'unsaved', message: 'Download before closing this page.' };
    const html = renderToStaticMarkup(<App />);
    expect(html).toContain('GAME TITLE SCREEN');
    expect(html).toContain('PROGRESS NOT SAVED');
    expect(html).toContain('RETRY SAVE');
    expect(html).toContain('DOWNLOAD PROGRESS');
    expect(html).not.toContain('role="dialog"');
  });

  it('has no save warning while storage is healthy', () => {
    expect(renderToStaticMarkup(<SaveStatusBanner />)).toBe('');
  });

  it('reports download failure when there is no progress available', () => {
    getSaveDownload.mockReturnValue(null);
    expect(downloadSave('damaged')).toMatchObject({ ok: false });
    expect(getSaveDownload).toHaveBeenCalledExactlyOnceWith('damaged');
  });

  it('downloads the untouched damaged content and releases the temporary URL', async () => {
    vi.useFakeTimers();
    const link = { click: vi.fn(), remove: vi.fn() };
    const createUrl = vi.spyOn(URL, 'createObjectURL').mockReturnValue('blob:save-copy');
    const revokeUrl = vi.spyOn(URL, 'revokeObjectURL').mockImplementation(() => {});
    vi.stubGlobal('document', { createElement: () => link, body: { appendChild: vi.fn() } });
    try {
      getSaveDownload.mockReturnValue({ name: 'dragonforge-damaged.json', content: '{"broken":' });
      expect(downloadSave('damaged')).toEqual({ ok: true });
      expect(await createUrl.mock.calls[0][0].text()).toBe('{"broken":');
      expect(link.download).toBe('dragonforge-damaged.json');
      expect(link.click).toHaveBeenCalledOnce();
      expect(link.remove).toHaveBeenCalledOnce();
      vi.advanceTimersByTime(1000);
      expect(revokeUrl).toHaveBeenCalledExactlyOnceWith('blob:save-copy');
    } finally {
      createUrl.mockRestore();
      revokeUrl.mockRestore();
      vi.unstubAllGlobals();
      vi.useRealTimers();
    }
  });
});
