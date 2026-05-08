import { getStageForLevel } from './battleEngine';
import { getSingularityStage, isSingularityUnlocked } from './singularityProgress';
import { getTickerMessage } from './felixDialogue';
import { getPlayerGuidance } from './playerGuidance';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate, save }) {
  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

  const stage = getSingularityStage(save);
  const ticker = getTickerMessage(stage);
  const guidance = getPlayerGuidance(save);

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
          className={`nav-tab ${activeScreen === 'map' ? 'active' : ''}`}
          onClick={() => onNavigate('map')}
        >
          MAP
        </button>
        <button
          className={`nav-tab ${activeScreen === 'battleSelect' ? 'active' : ''}`}
          onClick={() => onNavigate('battleSelect')}
        >
          BATTLES
        </button>
        <button
          className={`nav-tab ${activeScreen === 'forge' ? 'active' : ''}`}
          onClick={() => onNavigate('forge')}
        >
          FORGE
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
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {guidance && (
          <button
            className={`guidance-chip ${activeScreen === guidance.target ? 'active' : ''}`}
            onClick={() => onNavigate(guidance.target)}
            title={guidance.title}
          >
            <span>NEXT</span>
            <strong>{guidance.action}</strong>
          </button>
        )}
        <div className={`nav-ticker stage-${stage}`}>{ticker}</div>
        <div className="nav-scraps">◆ {save.dataScraps}</div>
        <SoundToggle />
      </div>
    </div>
  );
}
