// @ts-nocheck
import { useState, useEffect, useRef } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, getDragonLore, JOURNAL_DRAGON_IDS } from './gameData';
import { calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { claimMilestone, setDragonNickname, setFlag } from './persistence';
import { checkMilestones } from './journalMilestones';
import { stageToRoman } from './utils';
import { JOURNAL_BRIEFING } from './loreCanon';
import { CAPTAINS_LOG_FRAGMENTS, getCaptainLogDisplay } from './forgeData';
import NavBar from './NavBar';
import DragonSprite from './DragonSprite';

export default function JournalScreen({ onNavigate, save, refreshSave, showToast }) {
  const [tab, setTab] = useState(() => (save.flags?.journalBriefingSeen ? 'dragons' : 'briefing'));
  const [editingName, setEditingName] = useState(false);
  const [nameInput, setNameInput] = useState('');
  const [selectedId, setSelectedId] = useState(() => {
    const firstOwned = JOURNAL_DRAGON_IDS.find(el => save.dragons[el]?.owned);
    return firstOwned || 'fire';
  });
  const [milestoneResults, setMilestoneResults] = useState([]);
  const hasCheckedRef = useRef(false);
  const briefingMarkedRef = useRef(false);

  function handleClaim(m) {
    playSound('journalUnlock');
    claimMilestone(m.id, m.reward);
    showToast(`🏆 ${m.name} — +${m.reward} ◆`);
    refreshSave();
    setMilestoneResults(prev => prev.map(r => r.id === m.id ? { ...r, claimed: true, newlyClaimed: false } : r));
  }

  useEffect(() => {
    if (hasCheckedRef.current) return;
    hasCheckedRef.current = true;

    const results = checkMilestones(save);
    setMilestoneResults(results);
  }, []);

  useEffect(() => {
    if (tab !== 'briefing' || briefingMarkedRef.current || save.flags?.journalBriefingSeen) return;
    briefingMarkedRef.current = true;
    setFlag('journalBriefingSeen', true);
    refreshSave?.();
  }, [tab, save.flags?.journalBriefingSeen, refreshSave]);

  const handleSelectDragon = (elementId) => {
    playSound('buttonClick');
    setSelectedId(elementId);
    setTab('dragons');
  };

  const switchTab = (next) => {
    playSound('navSwitch');
    setTab(next);
  };

  const dragon = dragons[selectedId];
  const progress = save.dragons[selectedId];
  const owned = progress?.owned;
  const stage = owned ? getStageForLevel(progress.level) : 1;
  const stats = owned
    ? calculateStatsForLevel(progress.fusedBaseStats || dragon.baseStats, progress.level, progress.shiny)
    : null;
  const discoveredCount = JOURNAL_DRAGON_IDS.filter(id => save.dragons[id]?.discovered || save.dragons[id]?.owned).length;
  const unlockedFragments = save.flags?.fragmentsUnlocked || [];
  const accent = elementColors[selectedId] || elementColors[dragon?.element] || elementColors.neutral;

  return (
    <div>
      <NavBar activeScreen="journal" onNavigate={onNavigate} save={save} />

      <div className="journal-tabs" role="tablist" aria-label="Journal sections">
        <button
          type="button"
          role="tab"
          aria-selected={tab === 'briefing'}
          className={`journal-tab ${tab === 'briefing' ? 'active' : ''}`}
          onClick={() => switchTab('briefing')}
        >
          BRIEFING
        </button>
        <button
          type="button"
          role="tab"
          aria-selected={tab === 'dragons'}
          className={`journal-tab ${tab === 'dragons' ? 'active' : ''}`}
          onClick={() => switchTab('dragons')}
        >
          DRAGONS
        </button>
      </div>

      {tab === 'briefing' ? (
        <div className="journal-briefing">
          <p className="journal-briefing-kicker">FIELD BRIEFING — PROF. FELIX</p>
          <div className="journal-briefing-grid">
            {JOURNAL_BRIEFING.map((entry) => (
              <article key={entry.heading} className="journal-briefing-card">
                <h3>{entry.heading}</h3>
                <p>{entry.body}</p>
              </article>
            ))}
          </div>

          <div className="journal-log-head">
            <h3>CAPTAIN'S LOG</h3>
            <span>{unlockedFragments.length} / {CAPTAINS_LOG_FRAGMENTS.length} decrypted</span>
          </div>
          <div className="journal-log-list">
            {CAPTAINS_LOG_FRAGMENTS.map((fragment) => {
              const entry = getCaptainLogDisplay(fragment, unlockedFragments);
              return (
                <article key={entry.id} className={`journal-log-entry ${entry.isUnlocked ? 'is-unlocked' : ''}`}>
                  <h4>{entry.heading}{!entry.isUnlocked && <span> [{entry.status}]</span>}</h4>
                  <p>{entry.body}</p>
                </article>
              );
            })}
          </div>
        </div>
      ) : (
        <div className="journal-layout">
          <div className="journal-grid-panel">
            <div className="journal-grid">
              {JOURNAL_DRAGON_IDS.map((el) => {
                const d = dragons[el];
                const p = save.dragons[el];
                const isOwned = p?.owned;
                const color = elementColors[el] || elementColors[d.element];
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
                    tabIndex={0}
                    role="button"
                    onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleSelectDragon(el); } }}
                  >
                    <DragonSprite
                      spriteSheet={isOwned ? (d.stageSprites?.[getStageForLevel(p.level)] || d.spriteSheet) : d.spriteSheet}
                      stage={isOwned ? getStageForLevel(p.level) : 1}
                      size={{ width: 80, height: 60 }}
                      shiny={p?.shiny}
                      className={isOwned ? '' : 'undiscovered-silhouette'}
                      element={d.element}
                    />
                    <div
                      className="journal-card-name"
                      style={{ color: isOwned ? color.glow : '#444' }}
                    >
                      {isOwned ? d.name.toUpperCase() : '???'}
                      {p?.shiny && isOwned && <span className="shiny-star"> ★</span>}
                    </div>
                    <div className="journal-card-sub">
                      {isOwned ? `Lv.${p.level} Stage ${stageToRoman(getStageForLevel(p.level))}` : 'UNDISCOVERED'}
                    </div>
                  </div>
                );
              })}
            </div>
            <div className="journal-discovery-count">
              {discoveredCount}/{JOURNAL_DRAGON_IDS.length} DISCOVERED
            </div>
          </div>

          <div className="journal-detail">
            <DragonSprite
              spriteSheet={owned ? (dragon.stageSprites?.[stage] || dragon.spriteSheet) : dragon.spriteSheet}
              stage={stage}
              shiny={progress?.shiny && owned}
              className={owned ? '' : 'undiscovered-silhouette'}
              element={dragon.element}
            />

            {owned && editingName ? (
              <input
                className="journal-nickname-input"
                style={{ color: accent.glow }}
                value={nameInput}
                maxLength={20}
                autoFocus
                onChange={(e) => setNameInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    setDragonNickname(selectedId, nameInput.trim() || null);
                    refreshSave();
                    setEditingName(false);
                  } else if (e.key === 'Escape') {
                    setEditingName(false);
                  }
                }}
                onBlur={() => {
                  setDragonNickname(selectedId, nameInput.trim() || null);
                  refreshSave();
                  setEditingName(false);
                }}
              />
            ) : (
              <div
                className="journal-detail-name"
                style={{ color: owned ? accent.glow : '#444', cursor: owned ? 'pointer' : 'default' }}
                onClick={() => {
                  if (owned) {
                    setNameInput(progress?.nickname || dragon.name);
                    setEditingName(true);
                  }
                }}
                title={owned ? 'Click to rename' : ''}
              >
                {owned ? (progress?.nickname || dragon.name).toUpperCase() : '???'}
                {owned && progress?.shiny && <span className="shiny-star"> ★</span>}
                {owned && <span style={{ fontSize: 7, color: '#555', marginLeft: 6 }}>✏</span>}
              </div>
            )}

            <div className="journal-detail-meta">
              {owned ? (
                <>
                  {dragon.element.toUpperCase()} · Lv.{progress.level} · Stage {stageToRoman(stage)}
                  {progress.fusedBaseStats && <span className="journal-detail-fused" style={{ marginLeft: 8 }}>FUSED</span>}
                </>
              ) : (
                'PROTOCOL UNKNOWN'
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
              "{getDragonLore(selectedId, { owned })}"
              <br />
              <span style={{ color: '#555' }}>— Professor Felix</span>
            </div>

            {(save.fusionLineage?.length > 0 || (save.stats?.fusionsCompleted || 0) > 0) && (
              <div style={{ marginTop: 12, fontSize: 8, color: '#666' }}>
                <div style={{ color: '#888', letterSpacing: '0.1em', marginBottom: 4 }}>
                  FORGE LINEAGE · {save.stats?.fusionsCompleted || 0} FUSION{(save.stats?.fusionsCompleted || 0) !== 1 ? 'S' : ''}
                </div>
                {(save.fusionLineage || []).slice(-5).reverse().map((entry, i) => (
                  <div key={i} style={{ color: '#555', marginBottom: 2 }}>
                    {entry.parentA.toUpperCase()} + {entry.parentB.toUpperCase()} → {entry.offspring.toUpperCase()} Lv.{entry.offspringLevel}
                  </div>
                ))}
              </div>
            )}

            <div className="journal-milestones">
              {milestoneResults.map((m) => {
                const isClaimed = m.claimed;
                const claimable = m.newlyClaimed;

                return (
                  <div
                    key={m.id}
                    className={`milestone-badge ${isClaimed ? 'claimed' : ''} ${claimable ? 'claimable' : ''}`}
                    title={`${m.description} — ${m.reward} DataScraps`}
                  >
                    {isClaimed ? '✓ ' : ''}{m.name}
                    {claimable ? (
                      <button
                        className="milestone-claim-btn"
                        onClick={() => handleClaim(m)}
                      >
                        CLAIM +{m.reward} ◆
                      </button>
                    ) : (
                      !isClaimed && <span style={{ display: 'block', fontSize: 6, color: '#444' }}>{m.progress}</span>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
