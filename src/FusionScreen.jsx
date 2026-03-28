import { useState, useCallback } from 'react';
import { wait } from './utils';
import { dragons, elementColors } from './gameData';
import { getFusionElement, getStabilityTier, calculateFusionStats, executeFusion } from './fusionEngine';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { fuseDragons } from './persistence';
import { playSound } from './soundEngine';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

export default function FusionScreen({ onNavigate, save, refreshSave }) {
  const [parentA, setParentA] = useState(null);
  const [parentB, setParentB] = useState(null);
  const [phase, setPhase] = useState('select');
  const [fusionResult, setFusionResult] = useState(null);

  const ownedDragons = Object.entries(save.dragons)
    .filter(([, d]) => d.owned && d.level >= 10)
    .map(([id, d]) => {
      const dragon = dragons[id];
      const stage = getStageForLevel(d.level);
      const baseStats = d.fusedBaseStats || dragon.baseStats;
      const stats = calculateStatsForLevel(baseStats, d.level, d.shiny);
      return { id, ...dragon, ...d, stage, stats, baseStats };
    });

  const canFuse = parentA && parentB && save.dataScraps >= 100;

  function getPreview() {
    if (!parentA || !parentB) return null;
    const element = getFusionElement(parentA.element, parentB.element);
    const stability = getStabilityTier(parentA.element, parentB.element);
    const fusedStats = calculateFusionStats(parentA.stats, parentB.stats, stability);
    const color = elementColors[element];
    return { element, stability, fusedStats, color, dragonName: dragons[element].name };
  }

  const preview = getPreview();

  const handleFuse = useCallback(async () => {
    if (!canFuse || phase !== 'select') return;

    playSound('buttonClick');
    setPhase('animating');

    playSound('fusionMerge');
    await wait(600);
    playSound('fusionBurst');
    await wait(400);

    const result = executeFusion(
      { id: parentA.id, element: parentA.element, stats: parentA.stats, level: parentA.level, shiny: parentA.shiny },
      { id: parentB.id, element: parentB.element, stats: parentB.stats, level: parentB.level, shiny: parentB.shiny }
    );

    fuseDragons(
      parentA.id, parentB.id,
      result.element, result.level, result.xp,
      result.shiny, result.fusedBaseStats
    );

    playSound('fusionReveal');
    setFusionResult(result);
    setPhase('result');
    refreshSave();
  }, [canFuse, phase, parentA, parentB]);

  const handleDismiss = () => {
    setPhase('select');
    setParentA(null);
    setParentB(null);
    setFusionResult(null);
    refreshSave();
  };

  const selectDragon = (dragon, slot) => {
    playSound('buttonClick');
    if (slot === 'A') {
      setParentA(dragon);
      if (parentB?.id === dragon.id) setParentB(null);
    } else {
      setParentB(dragon);
      if (parentA?.id === dragon.id) setParentA(null);
    }
  };

  return (
    <div className="fusion-screen">
      <NavBar activeScreen="fusion" onNavigate={onNavigate} save={save} />

      <div className="fusion-content">
        <div className="fusion-title">FUSION CHAMBER</div>

        {phase === 'select' && (
          <>
            <div className="fusion-parents">
              <div className={`fusion-slot ${parentA ? 'filled' : ''}`} onClick={() => parentA && setParentA(null)}>
                <div className="fusion-slot-label">PARENT A</div>
                {parentA ? (
                  <>
                    <DragonSprite spriteSheet={parentA.spriteSheet} stage={parentA.stage} size={{ width: 100, height: 75 }} shiny={parentA.shiny} element={parentA.element} />
                    <div style={{ fontSize: 9, color: elementColors[parentA.element]?.glow }}>{parentA.name}</div>
                    <div style={{ fontSize: 8, color: '#888' }}>Lv.{parentA.level}</div>
                  </>
                ) : (
                  <div style={{ fontSize: 20, color: '#333' }}>+</div>
                )}
              </div>

              <div className="fusion-arrow">+</div>

              <div className={`fusion-slot ${parentB ? 'filled' : ''}`} onClick={() => parentB && setParentB(null)}>
                <div className="fusion-slot-label">PARENT B</div>
                {parentB ? (
                  <>
                    <DragonSprite spriteSheet={parentB.spriteSheet} stage={parentB.stage} size={{ width: 100, height: 75 }} shiny={parentB.shiny} element={parentB.element} />
                    <div style={{ fontSize: 9, color: elementColors[parentB.element]?.glow }}>{parentB.name}</div>
                    <div style={{ fontSize: 8, color: '#888' }}>Lv.{parentB.level}</div>
                  </>
                ) : (
                  <div style={{ fontSize: 20, color: '#333' }}>+</div>
                )}
              </div>
            </div>

            {preview && (
              <div className="fusion-preview">
                <h3>RESULT PREVIEW</h3>
                <div className="fusion-preview-element" style={{ color: preview.color?.glow }}>
                  {preview.dragonName}
                </div>
                <div className={`fusion-preview-stability ${preview.stability}`}>
                  {preview.stability.toUpperCase()}
                </div>
                <div className="fusion-preview-stats">
                  HP:{preview.fusedStats.hp} ATK:{preview.fusedStats.atk} DEF:{preview.fusedStats.def} SPD:{preview.fusedStats.spd}
                </div>
                <div className="fusion-warning">⚠ Both parents will be consumed</div>
              </div>
            )}

            <div className="fusion-dragon-picker">
              {ownedDragons.map((d) => {
                const isSelectedA = parentA?.id === d.id;
                const isSelectedB = parentB?.id === d.id;
                const isSelected = isSelectedA || isSelectedB;
                return (
                  <div
                    key={d.id}
                    className={`fusion-picker-card ${isSelected ? 'selected' : ''}`}
                    onClick={() => {
                      if (isSelected) return;
                      if (!parentA) selectDragon(d, 'A');
                      else if (!parentB) selectDragon(d, 'B');
                    }}
                  >
                    <DragonSprite spriteSheet={d.spriteSheet} stage={d.stage} size={{ width: 60, height: 45 }} shiny={d.shiny} />
                    <div style={{ color: elementColors[d.element]?.glow, marginTop: 4 }}>{d.name.split(' ')[0]}</div>
                    <div style={{ color: '#888' }}>Lv.{d.level}</div>
                  </div>
                );
              })}
            </div>

            <button className="fusion-btn" disabled={!canFuse} onClick={handleFuse}>
              FUSE — 100◆
            </button>

            {ownedDragons.length < 2 && (
              <div style={{ fontSize: 8, color: '#666' }}>Need 2+ Stage II dragons to fuse</div>
            )}
          </>
        )}

        {phase === 'animating' && (
          <div className="fusion-animation-overlay">
            <div className="fusion-flash" style={{ background: 'radial-gradient(circle, #fff, transparent)' }} />
          </div>
        )}

        {phase === 'result' && fusionResult && (
          <div className="fusion-result-card" onClick={handleDismiss}>
            <DragonSprite
              spriteSheet={dragons[fusionResult.element].spriteSheet}
              stage={getStageForLevel(fusionResult.level)}
              size={{ width: 180, height: 140 }}
              shiny={fusionResult.shiny}
              element={fusionResult.element}
            />
            <div style={{ color: elementColors[fusionResult.element]?.glow, fontSize: 12, marginTop: 8 }}>
              {dragons[fusionResult.element].name}
              {fusionResult.shiny && <span className="shiny-star">★</span>}
            </div>
            <div className={`fusion-preview-stability ${fusionResult.stabilityTier}`} style={{ marginTop: 4 }}>
              {fusionResult.stabilityTier.toUpperCase()} FUSION
            </div>
            <div style={{ fontSize: 9, color: '#888', marginTop: 4 }}>
              HP:{fusionResult.fusedBaseStats.hp} ATK:{fusionResult.fusedBaseStats.atk} DEF:{fusionResult.fusedBaseStats.def} SPD:{fusionResult.fusedBaseStats.spd}
            </div>
            {fusionResult.level === 50 && (
              <div style={{ fontSize: 10, color: '#ffcc00', marginTop: 8 }}>STAGE IV ELDER!</div>
            )}
            <div style={{ fontSize: 8, color: '#555', marginTop: 12 }}>Click to continue</div>
          </div>
        )}
      </div>
    </div>
  );
}
