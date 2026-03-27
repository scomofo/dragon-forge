import { useState } from 'react';
import TitleScreen from './TitleScreen';

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
        <div className="placeholder-screen">
          <h1>SELECT YOUR DRAGON</h1>
          <button onClick={() => handleBeginBattle({ dragonId: 'fire', npcId: 'firewall_sentinel' })}>
            BEGIN BATTLE (placeholder)
          </button>
        </div>
      )}
      {screen === SCREENS.BATTLE && (
        <div className="placeholder-screen">
          <h1>BATTLE (placeholder)</h1>
          <p>Config: {JSON.stringify(battleConfig)}</p>
          <button onClick={handleBattleEnd}>END BATTLE</button>
        </div>
      )}
    </div>
  );
}
