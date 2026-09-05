import { useState } from 'react';
import { playSound } from './soundEngine';
import { resetSave } from './persistence';
import NavBar from './NavBar';

export default function SettingsScreen({ onNavigate, save, refreshSave }) {
  const [confirmReset, setConfirmReset] = useState(false);
  const [resetDone, setResetDone] = useState(false);

  const handleReset = () => {
    if (!confirmReset) {
      setConfirmReset(true);
      return;
    }
    playSound('terminalFail');
    resetSave();
    refreshSave();
    setResetDone(true);
    setConfirmReset(false);
  };

  return (
    <div>
      <NavBar activeScreen="settings" onNavigate={onNavigate} save={save} />

      <div className="settings-layout">
        <div className="settings-title">SETTINGS</div>

        <div className="settings-section">
          <h3 className="settings-section-title">Save Data</h3>
          <div className="settings-option">
            <div>
              <div className="settings-option-name">Reset All Progress</div>
              <div className="settings-option-desc">Delete all save data and start fresh. This cannot be undone.</div>
            </div>
            <button
              className={`settings-btn ${confirmReset ? 'settings-btn-danger' : ''}`}
              onClick={handleReset}
            >
              {resetDone ? 'RESET COMPLETE' : confirmReset ? 'CONFIRM RESET' : 'RESET SAVE'}
            </button>
          </div>
        </div>

        <div className="settings-section">
          <h3 className="settings-section-title">About</h3>
          <div className="settings-credits">
            <div className="settings-credit-line">DRAGON FORGE v1.0</div>
            <div className="settings-credit-line dim">A 16-bit cyber-retro dragon breeding and combat simulator</div>
            <div className="settings-credit-line dim" style={{ marginTop: 8 }}>Created by Scott Morley</div>
            <div className="settings-credit-line dim">Powered by React + Vite</div>
            <div className="settings-credit-line dim">Art generated with AI assistance</div>
            <div className="settings-credit-line dim" style={{ marginTop: 8 }}>Built with Claude Code</div>
          </div>
        </div>
      </div>
    </div>
  );
}
