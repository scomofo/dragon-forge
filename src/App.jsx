import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import FusionScreen from './FusionScreen';
import JournalScreen from './JournalScreen';
import ShopScreen from './ShopScreen';
import SingularityScreen from './SingularityScreen';
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
  SHOP: 'shop',
  SINGULARITY: 'singularity',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);
  const [save, setSave] = useState(() => loadSave());
  const refreshSave = () => setSave(loadSave());
  const stage = getSingularityStage(save);

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
    } else if (target === 'singularity') {
      playMusic('battle', true);
      setScreen(SCREENS.SINGULARITY);
    }
  }

  function handleBeginBattle(config) {
    playSound('buttonClick');
    playMusic('battle', true);
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleEngageBoss(config) {
    playSound('buttonClick');
    playMusic('battle', true);
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
    playMusic('select');
    setBattleConfig(null);
    setScreen(SCREENS.BATTLE_SELECT);
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
        <HatcheryScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.FUSION && (
        <FusionScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.JOURNAL && (
        <JournalScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.SHOP && (
        <ShopScreen onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.SINGULARITY && (
        <SingularityScreen
          onNavigate={handleNavigate}
          onEngageBoss={handleEngageBoss}
          save={save}
        />
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={battleConfig.isSingularity ? handleSingularityBattleEnd : handleBattleEnd}
          save={save}
          refreshSave={refreshSave}
          battleConfig={battleConfig}
        />
      )}
    </div>
  );
}
