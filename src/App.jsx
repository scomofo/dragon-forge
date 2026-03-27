import { useState } from 'react';
import TitleScreen from './TitleScreen';
import BattleSelectScreen from './BattleSelectScreen';

const SCREENS = {
  TITLE: 'title',
  BATTLE_SELECT: 'battleSelect',
  BATTLE: 'battle',
};

export default function App() {
  const [screen, setScreen] = useState(SCREENS.TITLE);
  const [battleConfig, setBattleConfig] = useState(null);

  function handleStartGame() {
    setScreen(SCREENS.BATTLE_SELECT);
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
      {screen === SCREENS.BATTLE_SELECT && (
        <BattleSelectScreen onBeginBattle={handleBeginBattle} />
      )}
      {screen === SCREENS.BATTLE && (
        <div className="placeholder-screen">
          <h1>BATTLE (placeholder)</h1>
          <p style={{ fontSize: 9 }}>Dragon: {battleConfig?.dragonId} vs NPC: {battleConfig?.npcId}</p>
          <button onClick={handleBattleEnd}>END BATTLE</button>
        </div>
      )}
    </div>
  );
}
