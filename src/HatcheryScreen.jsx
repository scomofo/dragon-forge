import { useState, useCallback, useRef } from 'react';
import { wait } from './utils';
import { playSound } from './soundEngine';
import { dragons, elementColors, eggSheets, PULL_COST } from './gameData';
import { executePull, applyPullResult, getRarityCeremony, orderGridResults } from './hatcheryEngine';
import { loadSave, writeSave, trackStat } from './persistence';
import { assetUrl } from './utils';
import { eggBurst } from './animationEngine';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';
import EggSprite from './EggSprite';

const PHASES = {
  IDLE: 'idle',
  HATCHING: 'hatching',
  REVEAL: 'reveal',
  GRID: 'grid',
};

// Hatch animation sequence: frame index, duration, CSS class applied to egg container
const HATCH_SEQUENCE = [
  { frame: 0, duration: 400, css: 'egg-idle-pulse' },      // Idle pulse — anticipation
  { frame: 1, duration: 500, css: 'egg-glow' },            // Glow — warm up
  { frame: 2, duration: 300, css: 'egg-crack' },           // Crack 1
  { frame: 3, duration: 300, css: 'egg-crack' },           // Crack 2
  { frame: 4, duration: 150, css: 'egg-shake-anim' },      // Shake L
  { frame: 5, duration: 150, css: 'egg-shake-anim' },      // Shake R
  { frame: 4, duration: 120, css: 'egg-shake-anim' },      // Shake L faster
  { frame: 5, duration: 120, css: 'egg-shake-anim' },      // Shake R faster
  { frame: 4, duration: 80, css: 'egg-shake-intense' },    // Shake L intense
  { frame: 5, duration: 80, css: 'egg-shake-intense' },    // Shake R intense
  { frame: 6, duration: 400, css: '' },                    // Burst! (eggBurst handles the VFX; skip frame 7 shell)
];

export default function HatcheryScreen({ onNavigate, save, refreshSave }) {
  const [phase, setPhase] = useState(PHASES.IDLE);
  const [eggFrame, setEggFrame] = useState(0);
  const [eggSheet, setEggSheet] = useState(eggSheets.generic);
  const [eggCss, setEggCss] = useState('');
  const [eggGlowColor, setEggGlowColor] = useState(null);
  const [showTutorial, setShowTutorial] = useState(() => Object.values(save.dragons).every(d => !d.owned));
  const [currentResult, setCurrentResult] = useState(null);
  const [gridResults, setGridResults] = useState([]);
  const skippedRef = useRef(false);
  const eggContainerRef = useRef(null);
  const currentElementRef = useRef('fire');
  const burstFiredRef = useRef(false);

  // Fire the shell-shatter / light burst exactly once per hatch.
  const fireBurst = useCallback((element) => {
    if (burstFiredRef.current) return;
    burstFiredRef.current = true;
    eggBurst(eggContainerRef.current, element);
  }, []);

  const isFirstGame = Object.values(save.dragons).every(d => !d.owned);
  const canPull1 = isFirstGame || save.dataScraps >= PULL_COST;
  const canPull10 = save.dataScraps >= PULL_COST * 10;
  const pityRemaining = 10 - save.pityCounter;

  const animateHatch = useCallback(async (element, rarityName = 'Common') => {
    const ceremony = getRarityCeremony(rarityName);
    skippedRef.current = false;
    burstFiredRef.current = false;
    currentElementRef.current = element;
    setEggSheet(eggSheets.generic);
    setEggFrame(0);
    setEggCss('');
    setEggGlowColor(ceremony.glow);
    setPhase(PHASES.HATCHING);

    await wait(400);
    if (skippedRef.current) return;

    setEggSheet(eggSheets[element] || eggSheets.generic);

    // Rare+ gets extra shake escalation before the burst — the egg visibly
    // struggles harder when something valuable is inside.
    const sequence = [...HATCH_SEQUENCE];
    if (ceremony.extraShakes > 0) {
      const extra = [];
      for (let i = 0; i < ceremony.extraShakes; i++) {
        extra.push({ frame: i % 2 === 0 ? 4 : 5, duration: 70, css: 'egg-shake-intense' });
      }
      sequence.splice(sequence.length - 1, 0, ...extra);
    }

    for (const step of sequence) {
      if (skippedRef.current) return;
      setEggFrame(step.frame);
      setEggCss(step.css || '');

      if (step.frame === 1) playSound('eggGlow');
      else if (step.frame === 2 || step.frame === 3) playSound('eggCrack');
      else if (step.frame === 4 || step.frame === 5) playSound('eggShake');
      else if (step.frame === 6) { playSound('hatchBurst'); setTimeout(() => playSound('dragonReveal'), 200); }

      if (step.frame === 6) {
        // Hold-your-breath beat: Rare+ hangs on the cracked egg for a moment
        // before it bursts — anticipation is the reward.
        if (ceremony.holdMs > 0) {
          await wait(ceremony.holdMs);
          if (skippedRef.current) return;
        }
        await wait(60); // let the burst frame paint before slicing the canvas
        if (skippedRef.current) return;
        fireBurst(element);
        await wait(Math.max(0, step.duration - 60));
      } else {
        await wait(step.duration);
      }
    }
    setEggCss('');
  }, [fireBurst]);

  const handlePull1 = async () => {
    playSound('buttonClick');
    if (phase !== PHASES.IDLE && phase !== PHASES.REVEAL && phase !== PHASES.GRID) return;

    let currentSave = loadSave();

    if (!isFirstGame) {
      if (currentSave.dataScraps < PULL_COST) return;
      currentSave.dataScraps -= PULL_COST;
    }

    const pull = executePull(currentSave.pityCounter);
    const result = applyPullResult(currentSave, pull);
    writeSave(result.save);
    trackStat('totalPulls');
    refreshSave();
    setGridResults([]);

    await animateHatch(pull.element, pull.rarityName);

    setCurrentResult({ pull, apply: result });
    setPhase(PHASES.REVEAL);
    const stinger = getRarityCeremony(pull.rarityName).stinger;
    if (stinger) setTimeout(() => playSound(stinger), 600);
  };

  const handlePull10 = async () => {
    playSound('buttonClick');
    if (phase !== PHASES.IDLE && phase !== PHASES.REVEAL && phase !== PHASES.GRID) return;

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
    trackStat('totalPulls', 10);
    refreshSave();

    // Animate first pull
    const first = results[0];
    setGridResults([]);
    await animateHatch(first.pull.element, first.pull.rarityName);

    setCurrentResult({ pull: first.pull, apply: first.apply });
    setPhase(PHASES.REVEAL);
    const stinger = getRarityCeremony(first.pull.rarityName).stinger;
    if (stinger) setTimeout(() => playSound(stinger), 600);

    // After brief pause, show grid — ordered so the best pull lands last
    await wait(500);
    setGridResults(orderGridResults(results));
    setPhase(PHASES.GRID);
  };

  const handleSkip = () => {
    if (phase === PHASES.HATCHING) {
      skippedRef.current = true;
      setEggFrame(6);
      setEggCss('');
      // Let the jump-to-burst frame paint, then fire the shatter once.
      setTimeout(() => fireBurst(currentElementRef.current), 60);
    }
  };

  const handleDismiss = () => {
    setPhase(PHASES.IDLE);
    setCurrentResult(null);
    setGridResults([]);
    setEggFrame(0);
    setEggSheet(eggSheets.generic);
    setEggGlowColor(null);
    refreshSave();
  };

  const handleContentClick = () => {
    if (phase === PHASES.HATCHING) {
      handleSkip();
    } else if (phase === PHASES.REVEAL || phase === PHASES.GRID) {
      handleDismiss();
    }
  };

  return (
    <div
      className="hatchery-screen"
      style={{ '--hatchery-decoration': `url(${assetUrl('/assets/decoration/dragon_bounties.png')})` }}
    >
      <NavBar activeScreen="hatchery" onNavigate={onNavigate} save={save} />

      <div className="hatchery-content" onClick={handleContentClick}>
        <div className="hatchery-title">QUANTUM INCUBATION LAB</div>

        <div
          className={`egg-container ${eggCss}`}
          ref={eggContainerRef}
          style={eggGlowColor ? { '--rarity-glow': eggGlowColor } : undefined}
        >
          {(phase === PHASES.IDLE || phase === PHASES.HATCHING) && (
            <EggSprite sheet={eggSheet} frame={eggFrame} />
          )}

          {phase === PHASES.REVEAL && currentResult && (
            <div className="reveal-result">
              <span
                className="reveal-rays"
                style={{ '--ray-color': elementColors[currentResult.pull.element]?.glow || '#ffaa44' }}
                aria-hidden="true"
              />
              <DragonSprite
                spriteSheet={dragons[currentResult.pull.element].spriteSheet}
                stage={1}
                size={{ width: 180, height: 140 }}
                shiny={currentResult.pull.shiny}
                element={currentResult.pull.element}
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

          {phase === PHASES.GRID && (
            <div className="reveal-result">
              <div style={{ fontSize: 9, color: '#888', marginBottom: 8 }}>10x PULL RESULTS</div>
              <div className="pull-grid">
                {gridResults.map((r, i) => {
                  const dragon = dragons[r.pull.element];
                  const color = elementColors[r.pull.element];
                  return (
                    <div
                      key={i}
                      className={`pull-grid-card grid-flip ${r.pull.shiny ? 'shiny-card' : ''}`}
                      style={{ animationDelay: `${i * 70}ms` }}
                    >
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

        {pityRemaining < 10 && pityRemaining > 0 && phase === PHASES.IDLE && (
          <div className="pity-hint">Rare+ guaranteed in {pityRemaining} pulls</div>
        )}

        {(phase === PHASES.IDLE || phase === PHASES.REVEAL || phase === PHASES.GRID) && (
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

        {(phase === PHASES.REVEAL || phase === PHASES.GRID) && (
          <div style={{ fontSize: 8, color: '#555', marginTop: 8 }}>Click anywhere to dismiss</div>
        )}
        {phase === PHASES.HATCHING && (
          <div style={{ fontSize: 8, color: '#555', marginTop: 8 }}>Click to skip</div>
        )}
      </div>

      {showTutorial && (
        <div className="tutorial-overlay" onClick={() => setShowTutorial(false)}>
          <div className="tutorial-card">
            <div style={{ fontSize: 12, color: '#ff6622', marginBottom: 12 }}>WELCOME, SKYE</div>
            <div className="tutorial-steps">
              <div className="tutorial-step">Your first hatch is free. Pull a guardian, then take it into battle.</div>
            </div>
            <div style={{ fontSize: 8, color: '#555', marginTop: 12 }}>Tap anywhere to begin</div>
          </div>
        </div>
      )}
    </div>
  );
}
