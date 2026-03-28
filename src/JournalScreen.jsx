import { useState, useEffect, useRef } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, dragonLore, ELEMENTS } from './gameData';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { loadSave, claimMilestone } from './persistence';
import { checkMilestones } from './journalMilestones';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

export default function JournalScreen({ onNavigate }) {
  const [save, setSave] = useState(() => loadSave());
  const [selectedId, setSelectedId] = useState(() => {
    const s = loadSave();
    const firstOwned = ELEMENTS.find(el => s.dragons[el]?.owned);
    return firstOwned || 'fire';
  });
  const [milestoneResults, setMilestoneResults] = useState([]);
  const [newlyClaimed, setNewlyClaimed] = useState([]);
  const hasCheckedRef = useRef(false);

  // Check and claim milestones on first render
  useEffect(() => {
    if (hasCheckedRef.current) return;
    hasCheckedRef.current = true;

    const currentSave = loadSave();
    const results = checkMilestones(currentSave);
    const toClaim = results.filter(m => m.newlyClaimed);

    if (toClaim.length > 0) {
      for (const m of toClaim) {
        claimMilestone(m.id, m.reward);
      }
      playSound('superEffective');
      const updatedSave = loadSave();
      setSave(updatedSave);
      setMilestoneResults(checkMilestones(updatedSave));
      setNewlyClaimed(toClaim.map(m => m.id));
    } else {
      setMilestoneResults(results);
    }
  }, []);

  const handleSelectDragon = (elementId) => {
    playSound('buttonClick');
    setSelectedId(elementId);
  };

  const dragon = dragons[selectedId];
  const progress = save.dragons[selectedId];
  const owned = progress?.owned;
  const stage = owned ? getStageForLevel(progress.level) : 1;
  const stats = owned
    ? calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny)
    : null;
  const discoveredCount = Object.values(save.dragons).filter(d => d.owned).length;

  return (
    <div>
      <NavBar activeScreen="journal" onNavigate={onNavigate} />

      <div className="journal-layout">
        {/* Left panel — dragon grid */}
        <div className="journal-grid-panel">
          <div className="journal-grid">
            {ELEMENTS.map((el) => {
              const d = dragons[el];
              const p = save.dragons[el];
              const isOwned = p?.owned;
              const color = elementColors[el];
              const isSelected = el === selectedId;

              return (
                <div
                  key={el}
                  className={`journal-card ${isOwned ? 'owned' : ''} ${isSelected ? 'selected' : ''}`}
                  style={{
                    borderLeftColor: isOwned ? color.primary : '#333',
                    borderColor: isSelected ? color.primary : undefined,
                  }}
                  onClick={() => handleSelectDragon(el)}
                >
                  <DragonSprite
                    spriteSheet={d.spriteSheet}
                    stage={isOwned ? getStageForLevel(p.level) : 1}
                    size={{ width: 80, height: 60 }}
                    shiny={p?.shiny}
                    className={isOwned ? '' : 'undiscovered-silhouette'}
                    element={el}
                  />
                  <div
                    className="journal-card-name"
                    style={{ color: isOwned ? color.glow : '#444' }}
                  >
                    {isOwned ? d.name.toUpperCase() : '???'}
                    {p?.shiny && isOwned && <span className="shiny-star"> ★</span>}
                  </div>
                  <div className="journal-card-sub">
                    {isOwned ? `Lv.${p.level} Stage ${getStageForLevel(p.level) === 4 ? 'IV' : getStageForLevel(p.level) === 3 ? 'III' : getStageForLevel(p.level) === 2 ? 'II' : 'I'}` : 'UNDISCOVERED'}
                  </div>
                </div>
              );
            })}
          </div>
          <div className="journal-discovery-count">
            {discoveredCount}/6 DISCOVERED
          </div>
        </div>

        {/* Right panel — detail */}
        <div className="journal-detail">
          <DragonSprite
            spriteSheet={dragon.spriteSheet}
            stage={stage}
            shiny={progress?.shiny && owned}
            className={owned ? '' : 'undiscovered-silhouette'}
            element={dragon.element}
          />

          <div
            className="journal-detail-name"
            style={{ color: owned ? elementColors[dragon.element].glow : '#444' }}
          >
            {owned ? dragon.name.toUpperCase() : '???'}
            {owned && progress?.shiny && <span className="shiny-star"> ★</span>}
          </div>

          <div className="journal-detail-meta">
            {owned ? (
              <>
                {dragon.element.toUpperCase()} · Lv.{progress.level} · Stage {stage === 4 ? 'IV' : stage === 3 ? 'III' : stage === 2 ? 'II' : 'I'}
                {progress.fusedBaseStats && <span className="journal-detail-fused" style={{ marginLeft: 8 }}>FUSED</span>}
              </>
            ) : (
              'ELEMENT UNKNOWN'
            )}
          </div>

          {owned && stats && (
            <div className="journal-detail-stats">
              <div>HP <span>{stats.hp}</span></div>
              <div>ATK <span>{stats.atk}</span></div>
              <div>DEF <span>{stats.def}</span></div>
              <div>SPD <span>{stats.spd}</span></div>
            </div>
          )}

          <div className="journal-detail-lore">
            "{owned ? dragonLore[dragon.element] : 'No data available. Discover this dragon in the Hatchery.'}"
            <br />
            <span style={{ color: '#555' }}>— Professor Felix</span>
          </div>

          {/* Milestones */}
          <div className="journal-milestones">
            {milestoneResults.map((m) => {
              const isClaimed = m.claimed || newlyClaimed.includes(m.id);
              const isNew = newlyClaimed.includes(m.id);

              return (
                <div
                  key={m.id}
                  className={`milestone-badge ${isClaimed ? 'claimed' : ''} ${isNew ? 'newly-claimed' : ''}`}
                  title={`${m.description} — ${m.reward} DataScraps`}
                >
                  {isClaimed ? '✓ ' : ''}{m.name}
                  {!isClaimed && <span style={{ display: 'block', fontSize: 6, color: '#444' }}>{m.progress}</span>}
                  {isNew && <span style={{ display: 'block', fontSize: 6, color: '#ffcc00' }}>+{m.reward} ◆</span>}
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
