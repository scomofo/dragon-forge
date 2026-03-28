import { getStageForLevel } from './battleEngine';
import { getSingularityStage, isSingularityUnlocked } from './singularityProgress';
import { getTickerMessage } from './felixDialogue';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate, save }) {
  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

  const stage = getSingularityStage(save);
  const ticker = getTickerMessage(stage);

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
          className={`nav-tab ${activeScreen === 'journal' ? 'active' : ''}`}
          onClick={() => onNavigate('journal')}
        >
          JOURNAL
        </button>
        <button
          className={`nav-tab ${activeScreen === 'shop' ? 'active' : ''}`}
          onClick={() => onNavigate('shop')}
        >
          SHOP
        </button>
        <button
          className={`nav-tab ${activeScreen === 'stats' ? 'active' : ''}`}
          onClick={() => onNavigate('stats')}
        >
          STATS
        </button>
        <button
          className={`nav-tab ${activeScreen === 'settings' ? 'active' : ''}`}
          onClick={() => onNavigate('settings')}
        >
          ⚙
        </button>
        {isSingularityUnlocked(save) && (
          <button
            className={`nav-tab singularity-tab ${activeScreen === 'singularity' ? 'active' : ''}`}
            onClick={() => onNavigate('singularity')}
          >
            SINGULARITY
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
        <div className={`nav-ticker stage-${stage}`}>{ticker}</div>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
