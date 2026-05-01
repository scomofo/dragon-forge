import { useState } from 'react';
import Toast from './Toast';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import FusionScreen from './FusionScreen';
import JournalScreen from './JournalScreen';
import CampaignMapScreen from './CampaignMapScreen';
import ShopScreen from './ShopScreen';
import StatsScreen from './StatsScreen';
import SettingsScreen from './SettingsScreen';
import SingularityScreen from './SingularityScreen';
import ForgeScreen from './ForgeScreen';
import { playMusic, stopMusic, playSound } from './soundEngine';
import { loadSave } from './persistence';
import { getSingularityStage } from './singularityProgress';

const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
  FUSION: 'fusion',
  JOURNAL: 'journal',
  MAP: 'map',
  SHOP: 'shop',
  STATS: 'stats',
  SETTINGS: 'settings',
  SINGULARITY: 'singularity',
  FORGE: 'forge',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);
  const [save, setSave] = useState(() => loadSave());
  const refreshSave = () => setSave(loadSave());
  const stage = getSingularityStage(save);
  const [toasts, setToasts] = useState([]);

  function showToast(message) {
    const id = Date.now();
    setToasts(prev => [...prev, { id, message }]);
  }

  function removeToast(id) {
    setToasts(prev => prev.filter(t => t.id !== id));
  }

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
      playMusic('hatchery');
      setScreen(SCREENS.FUSION);
    } else if (target === 'journal') {
      playMusic('hatchery');
      setScreen(SCREENS.JOURNAL);
    } else if (target === 'shop') {
      playMusic('hatchery');
      setScreen(SCREENS.SHOP);
    } else if (target === 'map') {
      playMusic('mapWander');
      setScreen(SCREENS.MAP);
    } else if (target === 'stats') {
      playMusic('hatchery');
      setScreen(SCREENS.STATS);
    } else if (target === 'settings') {
      playMusic('hatchery');
      setScreen(SCREENS.SETTINGS);
    } else if (target === 'singularity') {
      playMusic('battle', true);
      setScreen(SCREENS.SINGULARITY);
    } else if (target === 'forge') {
      playMusic('hatchery');
      setScreen(SCREENS.FORGE);
    }
  }

  function handleBeginBattle(config) {
    playSound('buttonClick');
    playMusic('battleTense', true);
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBeginCampaignBattle(config) {
    playSound('buttonClick');
    playMusic('battleTense', true);
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.npcId,
      campaignNodeId: config.nodeId,
      returnScreen: SCREENS.MAP,
    });
    setScreen(SCREENS.BATTLE);
  }

  function handleEngageBoss(config) {
    playSound('buttonClick');
    playMusic('battleTense', true);
    setBattleConfig({
      dragonId: config.dragonId,
      npcId: config.boss.id,
      boss: config.boss,
      isSingularity: true,
      phases: config.boss.phases || null,
    });
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
    refreshSave();
    const returnScreen = battleConfig?.returnScreen;
    playMusic(returnScreen === SCREENS.MAP ? 'mapWander' : 'select');
    setBattleConfig(null);
    setScreen(returnScreen || SCREENS.BATTLE_SELECT);
  }

  function handleSingularityBattleEnd() {
    refreshSave();
    playMusic('battle', true);
    setBattleConfig(null);
    setScreen(SCREENS.SINGULARITY);
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
            save={save}
          />
        </div>
      )}
      {screen === SCREENS.FORGE && (
        <div className="screen-enter" key="forge">
          <ForgeScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
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
