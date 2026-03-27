import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';
import BattleScreen from './BattleScreen';
import HatcheryScreen from './HatcheryScreen';

const SCREENS = {
  TITLE: 'title',
  HATCHERY: 'hatchery',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.HATCHERY);
  }

  function handleNavigate(target) {
    if (target === 'hatchery') setScreen(SCREENS.HATCHERY);
    else if (target === 'battleSelect') setScreen(SCREENS.BATTLE_SELECT);
  }

  function handleBeginBattle(config) {
    setBattleConfig(config);
    setScreen(SCREENS.BATTLE);
  }

  function handleBattleEnd() {
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
