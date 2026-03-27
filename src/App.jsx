import { useState } from 'react';

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
        <div className="placeholder-screen">
          <h1>DRAGON FORGE</h1>
          <button onClick={handleStartGame}>ENTER THE FORGE</button>
        </div>
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
