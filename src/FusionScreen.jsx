import { useState, useCallback, useRef } from 'react';
import { wait, assetUrl } from './utils';
import gsap from 'gsap';
import { dragons, elementColors } from './gameData';
import { getStabilityTier, getFusionElement, getFusionPreview, getAlchemyGrid, executeFusion } from './fusionEngine';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { fuseDragons, setStabilityBoost } from './persistence';
import { playSound } from './soundEngine';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

const STAT_KEYS = ['hp', 'atk', 'def', 'spd'];
const formatDelta = (d) => (d > 0 ? '+' : '') + d;
const deltaClass = (d) => (d > 0 ? 'fusion-delta-pos' : d < 0 ? 'fusion-delta-neg' : 'fusion-delta-zero');
const shortName = (dragon) => dragon.name.split(' ')[0].toUpperCase();

export default function FusionScreen({ onNavigate, save, refreshSave }) {
  const [parentA, setParentA] = useState(null);
  const [parentB, setParentB] = useState(null);
  const [phase, setPhase] = useState('select');
  const [fusionResult, setFusionResult] = useState(null);
  const [tab, setTab] = useState('fuse'); // 'fuse' | 'log'
  // Element key of the owned dragon record the pending fusion would overwrite
  // (null = no overwrite, no confirmation needed).
  const [overwriteTarget, setOverwriteTarget] = useState(null);
  const slotARef = useRef(null);
  const slotBRef = useRef(null);
  const ceremonyRef = useRef(null);

  const ownedDragons = Object.entries(save.dragons)
    .filter(([id, d]) => d.owned && d.level >= 10 && dragons[id]) // drop ids absent from the data table (legacy saves)
    .map(([id, d]) => {
      const dragon = dragons[id];
      const stage = getStageForLevel(d.level);
      const baseStats = d.fusedBaseStats || dragon.baseStats;
      const stats = calculateStatsForLevel(baseStats, d.level, d.shiny);
      return { id, ...dragon, ...d, stage, stats, baseStats };
    });

  const canFuse = parentA && parentB && save.dataScraps >= 100;
  const stabilityBoost = !!save.inventory?.stabilityBoost;
  const boostEffective = stabilityBoost && !!parentA && !!parentB && getStabilityTier(parentA.element, parentB.element) !== 'stable';

  // Forge reading: the fusion pipeline is fully deterministic (no randomness in
  // getFusionElement / getStabilityTier / calculateFusionStats /
  // getFusionOffspringLevel), so the preview is EXACT — the offspring element,
  // level, stats, and per-parent deltas are known before the ceremony. Gameplay
  // plan item #3 deliberately trades the old "OUTCOME UNKNOWN" mystery for an
  // informed forging decision; the alchemy table itself stays discoverable
  // through the Forge Log.
  function getPreview() {
    if (!parentA || !parentB) return null;
    return getFusionPreview(parentA, parentB, { stabilityBoost });
  }

  const preview = getPreview();

  // The dragon record fuseDragons() overwrites is keyed by the offspring
  // element. If that record is already owned by a THIRD dragon (neither parent
  // — same-element fusions overwrite a parent being consumed anyway), the
  // player must explicitly confirm the replacement. No silent overwrites.
  function getOverwriteTargetElement() {
    if (!preview) return null;
    const element = getFusionElement(parentA.element, parentB.element);
    const existing = save.dragons?.[element];
    if (!existing?.owned) return null;
    if (element === parentA.id || element === parentB.id) return null;
    return element;
  }

  // Live overwrite warning for the preview (the dialog itself parks on
  // `overwriteTarget` state once the player presses FUSE).
  const pendingOverwrite = getOverwriteTargetElement();

  const alchemyGrid = getAlchemyGrid(save.fusionLineage);
  const discoveredCount = alchemyGrid.filter((r) => r.discovered).length;

  // Explicit REPLACE/CANCEL dialog for the silent-overwrite case. Shows the
  // dragon record that would be lost (name, element, level, shiny, key stats)
  // alongside the parents being consumed.
  const renderOverwriteDialog = () => {
    if (!overwriteTarget || phase !== 'select' || !preview) return null;
    const targetRecord = save.dragons[overwriteTarget];
    const targetData = dragons[overwriteTarget];
    if (!targetRecord || !targetData) return null;
    const targetStats = calculateStatsForLevel(
      targetRecord.fusedBaseStats || targetData.baseStats,
      targetRecord.level,
      targetRecord.shiny
    );
    const targetColor = elementColors[targetData.element]?.glow || '#fff';
    return (
      <div className="fusion-confirm-overlay">
        <div className="fusion-confirm-card">
          <div className="fusion-confirm-title">⚠ REPLACE EXISTING DRAGON?</div>
          <div className="fusion-confirm-text">
            This fusion forges a <b style={{ color: targetColor }}>{targetData.name.toUpperCase()}</b>,
            but you already own one. Fusing will <b>overwrite</b> it with the new offspring:
          </div>
          <div className="fusion-confirm-target" style={{ borderColor: targetColor }}>
            <div style={{ color: targetColor }}>
              {targetData.name.toUpperCase()}{targetRecord.shiny && <span className="shiny-star">★</span>}
            </div>
            <div>Lv.{targetRecord.level} · {targetData.element.toUpperCase()}</div>
            <div>HP:{targetStats.hp} ATK:{targetStats.atk} DEF:{targetStats.def} SPD:{targetStats.spd}</div>
          </div>
          <div className="fusion-confirm-text">
            Parents consumed: {parentA.name} Lv.{parentA.level} + {parentB.name} Lv.{parentB.level}
          </div>
          <div className="fusion-confirm-btns">
            <button className="fusion-btn fusion-btn-danger" onClick={handleConfirmReplace}>REPLACE</button>
            <button className="fusion-btn" onClick={handleCancelReplace}>CANCEL</button>
          </div>
        </div>
      </div>
    );
  };

  const runFuseCeremony = useCallback(async () => {
    if (!canFuse || phase !== 'select') return;

    setPhase('animating');

    // Convergence ceremony: the parents fly together, dissolve into element
    // motes, and the result hangs as a silhouette before the reveal — the
    // forge fantasy hatching already delivers.
    playSound('fusionMerge');
    const aEl = slotARef.current;
    const bEl = slotBRef.current;
    const ceremonyEl = ceremonyRef.current;
    if (aEl && bEl && ceremonyEl) {
      const ceremonyRect = ceremonyEl.getBoundingClientRect();
      const cx = ceremonyRect.left + ceremonyRect.width / 2;
      const cy = ceremonyRect.top + ceremonyRect.height / 2;
      const moveToCenter = (el) => {
        const r = el.getBoundingClientRect();
        return {
          x: cx - (r.left + r.width / 2),
          y: cy - (r.top + r.height / 2),
        };
      };
      const tl = gsap.timeline();
      tl.to(aEl, { ...moveToCenter(aEl), scale: 0.35, opacity: 0, duration: 0.7, ease: 'power2.in' }, 0)
        .to(bEl, { ...moveToCenter(bEl), scale: 0.35, opacity: 0, duration: 0.7, ease: 'power2.in' }, 0);
      await tl.then();
    } else {
      await wait(700);
    }

    playSound('fusionBurst');
    await wait(400);

    const result = executeFusion(
      { id: parentA.id, element: parentA.element, stats: parentA.stats, level: parentA.level, shiny: parentA.shiny },
      { id: parentB.id, element: parentB.element, stats: parentB.stats, level: parentB.level, shiny: parentB.shiny },
      { stabilityBoost }
    );

    fuseDragons(
      parentA.id, parentB.id,
      result.element, result.level, result.xp,
      result.shiny, result.fusedBaseStats
    );
    if (stabilityBoost && getStabilityTier(parentA.element, parentB.element) !== 'stable') setStabilityBoost(false);
    // NOTE: fusionsCompleted is incremented inside fuseDragons() (persistence.js) — the
    // canonical fusion mutation. Counting it here too double-counted every fusion.

    // Silhouette suspense beat: the result hangs unlit before the reveal.
    setFusionResult(result);
    setPhase('silhouette');
    await wait(700);

    playSound('fusionReveal');
    setPhase('result');
    refreshSave();
  }, [canFuse, phase, parentA, parentB, stabilityBoost]);

  // Entry point for the FUSE button: check for a silent overwrite first. If the
  // offspring element's dragon record is already owned by a third dragon, park
  // in a confirmation dialog instead of starting the ceremony.
  const handleFuse = useCallback(() => {
    if (!canFuse || phase !== 'select') return;
    playSound('buttonClick');
    const target = getOverwriteTargetElement();
    if (target) {
      setOverwriteTarget(target);
      return;
    }
    runFuseCeremony();
  }, [canFuse, phase, preview, parentA, parentB, save, runFuseCeremony]);

  const handleConfirmReplace = useCallback(() => {
    setOverwriteTarget(null);
    runFuseCeremony();
  }, [runFuseCeremony]);

  const handleCancelReplace = useCallback(() => {
    setOverwriteTarget(null);
  }, []);

  const handleDismiss = () => {
    setPhase('select');
    setParentA(null);
    setParentB(null);
    setFusionResult(null);
    setOverwriteTarget(null);
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

      <div className="fusion-content" style={{ '--lab-equipment-url': `url(${assetUrl('/assets/decoration/lab_equipment.png')})` }}>
        <div className="fusion-title">FUSION CHAMBER</div>

        {phase === 'select' && (
          <div className="fusion-tabs">
            <button
              className={`fusion-tab ${tab === 'fuse' ? 'active' : ''}`}
              onClick={() => { playSound('buttonClick'); setTab('fuse'); }}
            >
              FUSE
            </button>
            <button
              className={`fusion-tab ${tab === 'log' ? 'active' : ''}`}
              onClick={() => { playSound('buttonClick'); setTab('log'); }}
            >
              FORGE LOG
            </button>
          </div>
        )}

        {phase === 'select' && tab === 'fuse' && (
          <>
            <div className="fusion-parents">
              <div
                ref={slotARef}
                className={`fusion-slot ${parentA ? 'filled' : ''}`}
                onClick={() => parentA && setParentA(null)}
                tabIndex={0}
                role="button"
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); if (parentA) setParentA(null); } }}
              >
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

              <div
                ref={slotBRef}
                className={`fusion-slot ${parentB ? 'filled' : ''}`}
                onClick={() => parentB && setParentB(null)}
                tabIndex={0}
                role="button"
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); if (parentB) setParentB(null); } }}
              >
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
                <h3>FORGE READING · EXACT</h3>
                <div className="fusion-preview-element" style={{ color: elementColors[preview.element]?.glow || '#fff' }}>
                  {(dragons[preview.element]?.name || preview.element).toUpperCase()} · Lv.{preview.level}
                  {preview.shiny && <span className="shiny-star">★</span>}
                </div>
                <div className={`fusion-preview-stability ${preview.stability}`}>
                  {preview.stability.toUpperCase()} PAIRING
                </div>
                {stabilityBoost && !boostEffective && (
                  <div style={{ fontSize: 8, color: '#888' }}>🔮 STABILITY MATRIX — NO EFFECT (pair already stable)</div>
                )}
                {boostEffective && (
                  <div style={{ fontSize: 8, color: '#cc88ff' }}>🔮 STABILITY MATRIX ACTIVE — +1 TIER</div>
                )}
                <div className="fusion-preview-deltas">
                  {STAT_KEYS.map((key) => (
                    <div key={key} className="fusion-delta-row">
                      <span className="fusion-delta-stat">{key.toUpperCase()}</span>
                      <span className="fusion-delta-value">{preview.offspringStats[key]}</span>
                      <span className={deltaClass(preview.deltas.parentA[key])}>
                        {formatDelta(preview.deltas.parentA[key])} vs {shortName(parentA)}
                      </span>
                      <span className={deltaClass(preview.deltas.parentB[key])}>
                        {formatDelta(preview.deltas.parentB[key])} vs {shortName(parentB)}
                      </span>
                    </div>
                  ))}
                </div>
                <div className="fusion-preview-stats">
                  Stable pairs harden · unstable pairs hit harder but stay fragile
                </div>
                {pendingOverwrite && (
                  <div className="fusion-warning">
                    ⚠ Will REPLACE your existing {(dragons[pendingOverwrite]?.name || pendingOverwrite).toUpperCase()}!
                  </div>
                )}
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
                    tabIndex={0}
                    role="button"
                    onKeyDown={(e) => {
                      if (e.key === 'Enter' || e.key === ' ') {
                        e.preventDefault();
                        if (isSelected) return;
                        if (!parentA) selectDragon(d, 'A');
                        else if (!parentB) selectDragon(d, 'B');
                      }
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

        {phase === 'select' && tab === 'log' && (
          <div className="fusion-log">
            <h3>FORGE LOG · {(save.fusionLineage || []).length} FUSION{(save.fusionLineage || []).length !== 1 ? 'S' : ''}</h3>
            {(save.fusionLineage || []).length === 0 ? (
              <div className="fusion-log-empty">No fusions recorded yet. The forge remembers every pairing.</div>
            ) : (
              <div className="fusion-log-entries">
                {(save.fusionLineage || []).slice().reverse().map((entry, i) => {
                  // Lineage entries store parent dragon ids (element keys) but no
                  // stability-boost flag, so the tier is recomputed from the pair.
                  const aEl = dragons[entry.parentA]?.element || entry.parentA;
                  const bEl = dragons[entry.parentB]?.element || entry.parentB;
                  const aName = (dragons[entry.parentA]?.name || String(entry.parentA)).split(' ')[0].toUpperCase();
                  const bName = (dragons[entry.parentB]?.name || String(entry.parentB)).split(' ')[0].toUpperCase();
                  const oName = (dragons[entry.offspring]?.name || String(entry.offspring)).toUpperCase();
                  const tier = getStabilityTier(aEl, bEl);
                  return (
                    <div key={i} className="fusion-log-entry">
                      <span style={{ color: elementColors[aEl]?.glow }}>{aName}</span>
                      {' + '}
                      <span style={{ color: elementColors[bEl]?.glow }}>{bName}</span>
                      {' → '}
                      <span style={{ color: elementColors[entry.offspring]?.glow }}>{oName}</span>
                      {' '}Lv.{entry.offspringLevel}
                      {' · '}
                      <span className={`fusion-preview-stability ${tier}`}>{tier.toUpperCase()}</span>
                    </div>
                  );
                })}
              </div>
            )}
            <h3>ALCHEMY TABLE · {discoveredCount}/{alchemyGrid.length} DISCOVERED</h3>
            <div className="fusion-alchemy-grid">
              {alchemyGrid.map((recipe) => (
                <div
                  key={recipe.key}
                  className={`fusion-alchemy-cell ${recipe.discovered ? 'discovered' : ''}`}
                  title={recipe.discovered
                    ? `${recipe.parents[0]} + ${recipe.parents[1]} forges ${recipe.offspring}`
                    : 'Undiscovered recipe — fuse this pair to reveal it'}
                >
                  <span className="fusion-alchemy-check">{recipe.discovered ? '✓' : '?'}</span>
                  {' '}{recipe.parents[0].toUpperCase()} + {recipe.parents[1].toUpperCase()}
                  {' → '}
                  <span style={{ color: recipe.discovered ? elementColors[recipe.offspring]?.glow : '#555' }}>
                    {recipe.discovered ? recipe.offspring.toUpperCase() : '? ? ?'}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {renderOverwriteDialog()}

        {phase === 'animating' && (
          <div className="fusion-animation-overlay" ref={ceremonyRef}>
            <div className="fusion-flash" style={{ background: 'radial-gradient(circle, #fff, transparent)' }} />
          </div>
        )}

        {phase === 'silhouette' && fusionResult && (
          <div className="fusion-silhouette-stage">
            <div className="fusion-silhouette" style={{ color: elementColors[fusionResult.element]?.glow || '#ffaa44' }}>
              <DragonSprite
                spriteSheet={dragons[fusionResult.element].spriteSheet}
                stage={getStageForLevel(fusionResult.level)}
                size={{ width: 180, height: 140 }}
                shiny={false}
                element={fusionResult.element}
              />
            </div>
            <div className="fusion-silhouette-label">SIGNAL COALESCING…</div>
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
