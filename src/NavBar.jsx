import { loadSave } from './persistence';
import { getStageForLevel } from './battleEngine';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate }) {
  const save = loadSave();

  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

  return (
    <div className="nav-bar">
      <div className="nav-tabs">
        <button
          className={`nav-tab ${activeScreen === 'hatchery' ? 'active' : ''}`}
          onClick={() => onNavigate('hatchery')}
        >
          HATCHERY
        </button>
        {showFusion && (
          <button
            className={`nav-tab ${activeScreen === 'fusion' ? 'active' : ''}`}
            onClick={() => onNavigate('fusion')}
          >
            FUSION
          </button>
        )}
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
