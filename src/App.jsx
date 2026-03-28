import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import FusionScreen from './FusionScreen';
import JournalScreen from './JournalScreen';
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
    }
  }

  function handleBeginBattle(config) {
    playSound('buttonClick');
    playMusic('battle', true);
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
    refreshSave();
    playMusic('select');
    setBattleConfig(null);
    setScreen(SCREENS.BATTLE_SELECT);
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
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} save={save} refreshSave={refreshSave} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={handleBattleEnd}
          save={save}
          refreshSave={refreshSave}
        />
      )}
    </div>
  );
}
