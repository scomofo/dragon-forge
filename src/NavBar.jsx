import { getStageForLevel } from './battleEngine';
import { getSingularityStage, isSingularityUnlocked } from './singularityProgress';
import { getTickerMessage } from './felixDialogue';
import { getPlayerGuidance } from './playerGuidance';
import { checkMilestones } from './journalMilestones';
import { isDailyChallengeCompleted, getEffectiveStreak } from './dailyChallenge';
import SoundToggle from './SoundToggle';

export default function NavBar({ activeScreen, onNavigate, save }) {
  const ownedDragons = Object.values(save.dragons).filter(d => d.owned);
  const hasEligible = ownedDragons.some(d => d.level >= 10);
  const showFusion = ownedDragons.length >= 2 && hasEligible;

  const stage = getSingularityStage(save);
  const ticker = getTickerMessage(stage);
  const guidance = getPlayerGuidance(save);

  const defeatedNpcs = save.defeatedNpcs || [];
  const hasAnyCores = Object.values(save.inventory?.cores || {}).some(c => c > 0);
  const showShop = save.dataScraps > 0 || hasAnyCores;
  const showForge = defeatedNpcs.length >= 1;
  const showStats = (save.stats?.battlesWon || 0) >= 1;
  const hasClaimableMilestone = checkMilestones(save).some(m => m.newlyClaimed);
  // Daily visibility: dot on BATTLES while today's challenge is still open;
  // show the live streak next to it so there's something to lose.
  const dailyOpen = !isDailyChallengeCompleted(save);
  const liveStreak = getEffectiveStreak(save);

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
          JOURNAL{hasClaimableMilestone && <span style={{ display: 'inline-block', width: 6, height: 6, borderRadius: '50%', background: '#ffcc00', marginLeft: 4, verticalAlign: 'middle' }} />}
        </button>
        {showShop && (
          <button
            className={`nav-tab ${activeScreen === 'shop' ? 'active' : ''}`}
            onClick={() => onNavigate('shop')}
          >
            SHOP
          </button>
        )}
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
          BATTLES{dailyOpen && (
            <span
              title={liveStreak > 0 ? `Daily Challenge open — ${liveStreak}-day streak on the line` : 'Daily Challenge open'}
              style={{ display: 'inline-block', width: 6, height: 6, borderRadius: '50%', background: '#ff6600', marginLeft: 4, verticalAlign: 'middle' }}
            />
          )}
          {liveStreak > 0 && (
            <span style={{ marginLeft: 3, fontSize: 8, color: '#ff6600' }}>🔥{liveStreak}</span>
          )}
        </button>
        {showForge && (
          <button
            className={`nav-tab ${activeScreen === 'forge' ? 'active' : ''}`}
            onClick={() => onNavigate('forge')}
          >
            FORGE
          </button>
        )}
        {isSingularityUnlocked(save) && (
          <button
            className={`nav-tab singularity-tab ${activeScreen === 'singularity' ? 'active' : ''}`}
            onClick={() => onNavigate('singularity')}
          >
            SINGULARITY
          </button>
        )}
        {showStats && (
          <button
            className={`nav-tab ${activeScreen === 'stats' ? 'active' : ''}`}
            onClick={() => onNavigate('stats')}
          >
            STATS
          </button>
        )}
        <button
          className={`nav-tab ${activeScreen === 'settings' ? 'active' : ''}`}
          onClick={() => onNavigate('settings')}
          aria-label="Settings"
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
