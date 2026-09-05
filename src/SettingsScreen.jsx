import NavBar from './NavBar';
import { SaveDataControls } from './SaveRecovery';

export default function SettingsScreen({ onNavigate, save, refreshSave }) {
  return (
    <div>
      <NavBar activeScreen="settings" onNavigate={onNavigate} save={save} />

      <div className="settings-layout">
        <div className="settings-title">SETTINGS</div>

        <div className="settings-section">
          <h3 className="settings-section-title">Save Data</h3>
          <SaveDataControls onChange={refreshSave} />
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
