import { useState, useRef, useEffect } from 'react';
import Toast from './Toast';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import FusionScreen from './FusionScreen';
import JournalScreen from './JournalScreen';
import CampaignMapScreen from './CampaignMapScreen';
import OuterGridScreen from './OuterGridScreen';
import FrozenCacheScreen from './FrozenCacheScreen';
import StormSpineScreen from './StormSpineScreen';
import AdminCoreScreen from './AdminCoreScreen';
import ShopScreen from './ShopScreen';
import StatsScreen from './StatsScreen';
import SettingsScreen from './SettingsScreen';
import SingularityScreen from './SingularityScreen';
import ForgeScreen from './ForgeScreen';
import CreditsScreen from './CreditsScreen';
import { playMusic, stopMusic, playSound } from './soundEngine';
import { loadSave, recordRemnantDefeat, beginSession, accumulatePlaytime, grantWelcomeBack } from './persistence';
import { getSingularityStage, scaleBossForPlayer } from './singularityProgress';
import { checkMilestones } from './journalMilestones';

const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
  FUSION: 'fusion',
  JOURNAL: 'journal',
  MAP: 'map',
  OUTER_GRID: 'outerGrid',
  FROZEN_CACHE: 'frozenCache',
  STORM_SPINE: 'stormSpine',
  ADMIN_CORE: 'adminCore',
  SHOP: 'shop',
  STATS: 'stats',
  SETTINGS: 'settings',
  SINGULARITY: 'singularity',
  FORGE: 'forge',
  CREDITS: 'credits',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);
  const [save, setSave] = useState(() => loadSave());
  function refreshSave() {
    const newSave = loadSave();
    const prevIds = new Set(checkMilestones(save).filter(m => m.newlyClaimed).map(m => m.id));
    const fresh = checkMilestones(newSave).filter(m => m.newlyClaimed && !prevIds.has(m.id));
    if (fresh.length > 0) showToast(`Milestone ready: "${fresh[0].name}" — claim in JOURNAL`);
    setSave(newSave);
  }
  const stage = getSingularityStage(save);
  const [toasts, setToasts] = useState([]);
  const toastIdRef = useRef(0);

  function showToast(message) {
    // Monotonic id — Date.now() collided when two toasts fired in the same ms
    // (e.g. multiple milestones ready at once), producing duplicate React keys.
    const id = ++toastIdRef.current;
    setToasts(prev => [...prev, { id, message }]);
  }

  function removeToast(id) {
    setToasts(prev => prev.filter(t => t.id !== id));
  }

  // Session telemetry + welcome-back beat. beginSession is guarded to one call
  // per page load internally, so StrictMode's double-effect can't double-count.
  useEffect(() => {
    const { daysAway, grant } = beginSession();
    if (grant > 0) {
      grantWelcomeBack(grant);
      setSave(loadSave());
      showToast(`WELCOME BACK, SKYE — ${daysAway} days away. Felix kept the forge warm. +${grant} ◆`);
    }
    const heartbeat = setInterval(accumulatePlaytime, 60000);
    window.addEventListener('beforeunload', accumulatePlaytime);
    return () => {
      clearInterval(heartbeat);
      window.removeEventListener('beforeunload', accumulatePlaytime);
      accumulatePlaytime();
    };
  }, []);

  function handleStartGame() {
    playSound('screenTransition');
    playMusic('hatchery');
    setScreen(SCREENS.HATCHERY);
  }

  function handleNavigate(target) {
    refreshSave();
    playSound('navSwitch');
    if (target === 'hatchery') {
      playMusic('hatchery');
      setScreen(SCREENS.HATCHERY);
    } else if (target === 'battleSelect') {
      playMusic('select');
      setScreen(SCREENS.BATTLE_SELECT);
    } else if (target === 'fusion') {
      playMusic('fusion');
      setScreen(SCREENS.FUSION);
    } else if (target === 'journal') {
      playMusic('journal');
      setScreen(SCREENS.JOURNAL);
    } else if (target === 'shop') {
      playMusic('shop');
      setScreen(SCREENS.SHOP);
    } else if (target === 'map') {
      playMusic('mapWander');
      setScreen(SCREENS.MAP);
    } else if (target === 'outerGrid') {
      playMusic('mapWander');
      setScreen(SCREENS.OUTER_GRID);
    } else if (target === 'frozenCache') {
      playMusic('mapWander');
      setScreen(SCREENS.FROZEN_CACHE);
    } else if (target === 'stormSpine') {
      playMusic('mapWander');
      setScreen(SCREENS.STORM_SPINE);
    } else if (target === 'adminCore') {
      playMusic('mapWander');
      setScreen(SCREENS.ADMIN_CORE);
    } else if (target === 'stats') {
      playMusic('hatchery');
      setScreen(SCREENS.STATS);
    } else if (target === 'settings') {
      playMusic('hatchery');
      setScreen(SCREENS.SETTINGS);
    } else if (target === 'singularity') {
      playMusic('singularity', true);
      setScreen(SCREENS.SINGULARITY);
    } else if (target === 'forge') {
      playMusic('forge');
      setScreen(SCREENS.FORGE);
    }
  }

  function handleBeginBattle(config) {
    playSound('buttonClick');
    playMusic('battle', true); // open calm; BattleScreen escalates to intense at low HP
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBeginCampaignBattle(config) {
    playSound('buttonClick');
    playMusic('battle', true); // open calm; BattleScreen escalates to intense at low HP
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.npcId,
      benchDragonId: config.benchDragonId || null,
      campaignNodeId: config.nodeId,
      returnScreen: [SCREENS.OUTER_GRID, SCREENS.FROZEN_CACHE, SCREENS.STORM_SPINE, SCREENS.ADMIN_CORE].includes(config.returnScreen) ? config.returnScreen : SCREENS.MAP,
    });
    setScreen(SCREENS.BATTLE);
  }

  function handleEngageBoss(config) {
    if (config.isMirrorAdmin) {
      playSound('mirrorAdminSpawn');
      playMusic('mirrorAdmin', true);
    } else if (config.boss?.id === 'singularity') {
      // The Singularity itself keeps the dread commission; gatekeepers are
      // boss fights and get the boss track.
      playSound('buttonClick');
      playMusic('singularity', true);
    } else {
      playSound('buttonClick');
      playMusic('boss', true);
    }
    const scaledBoss = scaleBossForPlayer(config.boss, save);
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.boss.id,
      boss: scaledBoss,
      isSingularity: true,
      isMirrorAdmin: config.isMirrorAdmin || false,
      phases: scaledBoss.phases || null,
    });
    setScreen(SCREENS.BATTLE);
  }

  function handleEngageRemnant(config) {
    playSound('buttonClick');
    playMusic('boss', true); // remnants are boss fights, not the Singularity
    const scaledBoss = scaleBossForPlayer(config.boss, save);
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.boss.id,
      boss: scaledBoss,
      isSingularity: true,
      isRemnant: true,
      remnantId: config.boss.id,
      phases: scaledBoss.phases || null,
      returnScreen: SCREENS.SINGULARITY,
    });
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
    refreshSave();
    const returnScreen = battleConfig?.returnScreen;
    playMusic([SCREENS.MAP, SCREENS.OUTER_GRID, SCREENS.FROZEN_CACHE, SCREENS.STORM_SPINE, SCREENS.ADMIN_CORE].includes(returnScreen) ? 'mapWander' : 'select');
    setBattleConfig(null);
    setScreen(returnScreen || SCREENS.BATTLE_SELECT);
  }

  function handleSingularityBattleEnd(won) {
    // Credits only on a real Mirror Admin victory — the defeat overlay's
    // TRY AGAIN routes here too, and a loser must not see the epilogue.
    // The per-battle outcome is required: the mirrorAdminDefeated save flag
    // is permanent after the first win, so it cannot gate replay losses.
    const wonMirrorAdmin = battleConfig?.isMirrorAdmin && won === true;
    const wonRemnant = battleConfig?.isRemnant && won === true;
    if (wonRemnant && battleConfig.remnantId) {
      recordRemnantDefeat(battleConfig.remnantId);
    }
    refreshSave();
    if (wonMirrorAdmin) {
      playSound('victoryFanfare');
      playMusic('credits', true);
    } else {
      playMusic('singularity', true);
    }
    setBattleConfig(null);
    setScreen(wonMirrorAdmin ? SCREENS.CREDITS : SCREENS.SINGULARITY);
  }

  return (
    <div className={`app${stage >= 2 ? ` corruption-stage-${stage}` : ''}`}>
      {screen === SCREENS.TITLE && (
        <TitleScreen onStart={handleStartGame} save={save} />
      )}
      {screen === SCREENS.HATCHERY && (
        <div className="screen-enter" key="hatchery">
          <HatcheryScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.FUSION && (
        <div className="screen-enter" key="fusion">
          <FusionScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.JOURNAL && (
        <div className="screen-enter" key="journal">
          <JournalScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} showToast={showToast} />
        </div>
      )}
      {screen === SCREENS.OUTER_GRID && (
        <OuterGridScreen save={save} refreshSave={refreshSave} onNavigate={handleNavigate} onBeginCampaignBattle={handleBeginCampaignBattle} />
      )}
      {screen === SCREENS.FROZEN_CACHE && (
        <div className="screen-enter" key="frozenCache">
          <FrozenCacheScreen save={save} refreshSave={refreshSave} onNavigate={handleNavigate} onBeginCampaignBattle={handleBeginCampaignBattle} />
        </div>
      )}
      {screen === SCREENS.STORM_SPINE && (
        <div className="screen-enter" key="stormSpine">
          <StormSpineScreen save={save} refreshSave={refreshSave} onNavigate={handleNavigate} onBeginCampaignBattle={handleBeginCampaignBattle} />
        </div>
      )}
      {screen === SCREENS.ADMIN_CORE && (
        <div className="screen-enter" key="adminCore">
          <AdminCoreScreen save={save} refreshSave={refreshSave} onNavigate={handleNavigate} onBeginCampaignBattle={handleBeginCampaignBattle} />
        </div>
      )}
      {screen === SCREENS.MAP && (
        <div className="screen-enter" key="map">
          <CampaignMapScreen
            onNavigate={handleNavigate}
            onBeginCampaignBattle={handleBeginCampaignBattle}
            save={save}
          />
        </div>
      )}
      {screen === SCREENS.SHOP && (
        <div className="screen-enter" key="shop">
          <ShopScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.STATS && (
        <div className="screen-enter" key="stats">
          <StatsScreen onNavigate={handleNavigate} save={save} />
        </div>
      )}
      {screen === SCREENS.SETTINGS && (
        <div className="screen-enter" key="settings">
          <SettingsScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.SINGULARITY && (
        <div className="screen-enter" key="singularity">
          <SingularityScreen
            onNavigate={handleNavigate}
            onEngageBoss={handleEngageBoss}
            onEngageRemnant={handleEngageRemnant}
            save={save}
          />
        </div>
      )}
      {screen === SCREENS.FORGE && (
        <div className="screen-enter" key="forge">
          <ForgeScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.CREDITS && (
        <div className="screen-enter" key="credits">
          <CreditsScreen onNavigate={handleNavigate} save={save} />
        </div>
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <div className="screen-enter" key="battleSelect">
          <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
        </div>
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <div className="screen-enter" key="battle">
          <BattleScreen
            dragonId={battleConfig.dragonId}
            npcId={battleConfig.npcId}
            onBattleEnd={battleConfig.isSingularity ? handleSingularityBattleEnd : handleBattleEnd}
            save={save}
            refreshSave={refreshSave}
            battleConfig={battleConfig}
          />
        </div>
      )}
      {toasts.length > 0 && (
        <div className="toast-container">
          {toasts.map(t => (
            <Toast key={t.id} message={t.message} onDone={() => removeToast(t.id)} />
          ))}
        </div>
      )}
    </div>
  );
}
