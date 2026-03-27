import { useState, useCallback } from 'react';
import { dragons, elementColors, PULL_COST } from './gameData';
import { executePull, applyPullResult } from './hatcheryEngine';
import { loadSave, writeSave } from './persistence';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

const ANIM_PHASES = {
  IDLE: 'idle',
  EGG_APPEAR: 'eggAppear',
  EGG_SHAKE: 'eggShake',
  BURST: 'burst',
  REVEAL: 'reveal',
  GRID: 'grid',
};

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export default function HatcheryScreen({ onNavigate }) {
  const [phase, setPhase] = useState(ANIM_PHASES.IDLE);
  const [currentResult, setCurrentResult] = useState(null);
  const [gridResults, setGridResults] = useState([]);
  const [burstColor, setBurstColor] = useState('#fff');
  const [save, setSave] = useState(() => loadSave());

  const refreshSave = () => setSave(loadSave());

  const isFirstGame = Object.values(save.dragons).every(d => !d.owned);
  const canPull1 = isFirstGame || save.dataScraps >= PULL_COST;
  const canPull10 = save.dataScraps >= PULL_COST * 10;
  const pityRemaining = 10 - save.pityCounter;

  const animateSinglePull = useCallback(async (pullResult, applyResult, skipAnim = false) => {
    const color = elementColors[pullResult.element]?.glow || '#fff';
    setBurstColor(color);

    if (!skipAnim) {
      setPhase(ANIM_PHASES.EGG_APPEAR);
      await wait(300);

      setPhase(ANIM_PHASES.EGG_SHAKE);
      await wait(800);

      setPhase(ANIM_PHASES.BURST);
      await wait(400);
    }

    setCurrentResult({ pull: pullResult, apply: applyResult });
    setPhase(ANIM_PHASES.REVEAL);
  }, []);

  const handleSkip = () => {
    if (phase === ANIM_PHASES.EGG_APPEAR || phase === ANIM_PHASES.EGG_SHAKE || phase === ANIM_PHASES.BURST) {
      // Skip will be handled by setting phase directly to reveal
      // The animateSinglePull await chain will be interrupted visually
    }
  };

  const handlePull1 = async () => {
    if (phase !== ANIM_PHASES.IDLE && phase !== ANIM_PHASES.REVEAL && phase !== ANIM_PHASES.GRID) return;

    let currentSave = loadSave();

    if (!isFirstGame) {
      if (currentSave.dataScraps < PULL_COST) return;
      currentSave.dataScraps -= PULL_COST;
    }

    const pull = executePull(currentSave.pityCounter);
    const result = applyPullResult(currentSave, pull);
    writeSave(result.save);
    refreshSave();
    setGridResults([]);

    await animateSinglePull(pull, result);
  };

  const handlePull10 = async () => {
    if (phase !== ANIM_PHASES.IDLE && phase !== ANIM_PHASES.REVEAL && phase !== ANIM_PHASES.GRID) return;

    let currentSave = loadSave();
    if (currentSave.dataScraps < PULL_COST * 10) return;
    currentSave.dataScraps -= PULL_COST * 10;

    const results = [];
    for (let i = 0; i < 10; i++) {
      const pull = executePull(currentSave.pityCounter);
      const result = applyPullResult(currentSave, pull);
      currentSave = result.save;
      results.push({ pull, apply: result });
    }

    writeSave(currentSave);
    refreshSave();

    // Animate first pull
    const first = results[0];
    setGridResults([]);
    await animateSinglePull(first.pull, first.apply);

    // Show remaining as grid
    await wait(300);
    setGridResults(results);
    setPhase(ANIM_PHASES.GRID);
  };

  const handleDismiss = () => {
    setPhase(ANIM_PHASES.IDLE);
    setCurrentResult(null);
    setGridResults([]);
    refreshSave();
  };

  return (
    <div className="hatchery-screen">
      <NavBar activeScreen="hatchery" onNavigate={onNavigate} />

      <div className="hatchery-content" onClick={phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID ? handleDismiss : handleSkip}>
        <div className="hatchery-title">QUANTUM INCUBATION LAB</div>

        <div className="egg-container">
          {(phase === ANIM_PHASES.IDLE || phase === ANIM_PHASES.EGG_APPEAR) && (
            <div className="egg-sprite egg-pulse" />
          )}
          {phase === ANIM_PHASES.EGG_SHAKE && (
            <div className="egg-sprite egg-shake" />
          )}
          {phase === ANIM_PHASES.BURST && (
            <div style={{ position: 'relative', width: 120, height: 150 }}>
              <div className="egg-burst" style={{ background: `radial-gradient(circle, ${burstColor}, transparent)` }} />
            </div>
          )}
          {phase === ANIM_PHASES.REVEAL && currentResult && (
            <div className="reveal-result">
              <DragonSprite
                spriteSheet={dragons[currentResult.pull.element].spriteSheet}
                stage={1}
                size={{ width: 160, height: 120 }}
                shiny={currentResult.pull.shiny}
              />
              <div style={{ color: elementColors[currentResult.pull.element]?.glow, fontSize: 11, marginTop: 8 }}>
                {dragons[currentResult.pull.element].name}
                {currentResult.pull.shiny && <span className="shiny-star">★</span>}
              </div>
              <div className={`reveal-rarity ${currentResult.pull.rarityName}`}>
                {currentResult.pull.rarityName}
              </div>
              {currentResult.apply.isNew ? (
                <div className="reveal-badge new-badge">NEW!</div>
              ) : (
                <div className="reveal-badge xp-badge">+{currentResult.apply.xpGained} XP</div>
              )}
              {currentResult.pull.shiny && (
                <div className="reveal-badge shiny-badge">+20% STATS</div>
              )}
            </div>
          )}
          {phase === ANIM_PHASES.GRID && (
            <div className="reveal-result">
              <div style={{ fontSize: 9, color: '#888', marginBottom: 8 }}>10x PULL RESULTS</div>
              <div className="pull-grid">
                {gridResults.map((r, i) => {
                  const dragon = dragons[r.pull.element];
                  const color = elementColors[r.pull.element];
                  return (
                    <div key={i} className={`pull-grid-card ${r.pull.shiny ? 'shiny-card' : ''}`}>
                      <DragonSprite
                        spriteSheet={dragon.spriteSheet}
                        stage={1}
                        size={{ width: 60, height: 45 }}
                        shiny={r.pull.shiny}
                      />
                      <div className="card-element" style={{ color: color?.glow }}>{dragon.name.split(' ')[0]}</div>
                      <div className={`card-badge ${r.apply.isNew ? 'new-badge' : 'xp-badge'}`}>
                        {r.apply.isNew ? 'NEW' : `+${r.apply.xpGained}XP`}
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        {pityRemaining < 10 && pityRemaining > 0 && phase === ANIM_PHASES.IDLE && (
          <div className="pity-hint">Rare+ guaranteed in {pityRemaining} pulls</div>
        )}

        {(phase === ANIM_PHASES.IDLE || phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID) && (
          <div className="pull-buttons">
            <button className="pull-btn" disabled={!canPull1} onClick={handlePull1}>
              {isFirstGame ? 'FREE PULL' : `PULL x1 — ${PULL_COST}◆`}
            </button>
            {!isFirstGame && (
              <button className="pull-btn" disabled={!canPull10} onClick={handlePull10}>
                PULL x10 — {PULL_COST * 10}◆
              </button>
            )}
          </div>
        )}

        {(phase === ANIM_PHASES.REVEAL || phase === ANIM_PHASES.GRID) && (
          <div style={{ fontSize: 8, color: '#555', marginTop: 8 }}>Click anywhere to dismiss</div>
        )}
      </div>
    </div>
  );
}
