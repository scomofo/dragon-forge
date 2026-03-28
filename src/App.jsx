import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';
import FusionScreen from './FusionScreen';
import JournalScreen from './JournalScreen';
import { playMusic, stopMusic, playSound } from './soundEngine';

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

  function handleStartGame() {
    playSound('screenTransition');
    playMusic('hatchery');
    setScreen(SCREENS.HATCHERY);
  }

  function handleNavigate(target) {
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
    playMusic('select');
    setBattleConfig(null);
    setScreen(SCREENS.BATTLE_SELECT);
  }

  return (
    <div className="app">
      {screen === SCREENS.TITLE && (
        <TitleScreen onStart={handleStartGame} />
      )}
      {screen === SCREENS.HATCHERY && (
        <HatcheryScreen onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.FUSION && (
        <FusionScreen onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.JOURNAL && (
        <JournalScreen onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} onNavigate={handleNavigate} />
      )}
      {screen === SCREENS.BATTLE && battleConfig && (
        <BattleScreen
          dragonId={battleConfig.dragonId}
          npcId={battleConfig.npcId}
          onBattleEnd={handleBattleEnd}
        />
      )}
    </div>
  );
}
