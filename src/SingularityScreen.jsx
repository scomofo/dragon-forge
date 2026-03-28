import { useState } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, ELEMENTS } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS, getBossStatus } from './singularityBosses';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';

const ALL_BOSSES = [...SINGULARITY_BOSSES, FINAL_BOSS];

export default function SingularityScreen({ onNavigate, onEngageBoss, save }) {
  const [selectedBossId, setSelectedBossId] = useState(ALL_BOSSES[0].id);
  const [selectedDragonId, setSelectedDragonId] = useState(() => {
    const firstOwned = ELEMENTS.find(el => save.dragons[el]?.owned);
    return firstOwned || 'fire';
  });

  const selectedBoss = ALL_BOSSES.find(b => b.id === selectedBossId);
  const bossStatus = getBossStatus(selectedBoss, save);
  const canEngage = bossStatus === 'available' || bossStatus === 'defeated';
  const ownedDragons = ELEMENTS.filter(el => save.dragons[el]?.owned);

  const handleSelectBoss = (bossId) => {
    const boss = ALL_BOSSES.find(b => b.id === bossId);
    const status = getBossStatus(boss, save);
    if (status === 'locked') return;
    playSound('buttonClick');
    setSelectedBossId(bossId);
  };

  const handleEngage = () => {
    if (!canEngage) return;
    playSound('buttonClick');
    onEngageBoss({
      dragonId: selectedDragonId,
      boss: selectedBoss,
      isSingularity: true,
    });
  };

  const displayStats = selectedBoss.phases ? selectedBoss.phases[0].stats : selectedBoss.stats;
  const displayElement = selectedBoss.phases ? selectedBoss.phases[0].element : selectedBoss.element;
  const displayLevel = selectedBoss.phases ? selectedBoss.phases[0].level : selectedBoss.level;

  return (
    <div>
      <NavBar activeScreen="singularity" onNavigate={onNavigate} save={save} />

      <div className="singularity-layout">
        {/* Left panel — boss list */}
        <div className="singularity-boss-list">
          {ALL_BOSSES.map((boss) => {
            const status = getBossStatus(boss, save);
            const isSelected = boss.id === selectedBossId;

            return (
              <div
                key={boss.id}
                className={`singularity-boss-card ${status} ${isSelected ? 'selected' : ''}`}
                onClick={() => handleSelectBoss(boss.id)}
              >
                <div>
                  <div className="singularity-boss-name">
                    {status === 'locked' ? '???' : boss.name.toUpperCase()}
                  </div>
                  <div className="singularity-boss-sub">
                    {status === 'locked' ? 'LOCKED' : `${boss.difficulty} · ${(boss.phases ? boss.phases[0].element : boss.element).toUpperCase()}`}
                    {boss.phases && status !== 'locked' && ' · 3 PHASES'}
                  </div>
                </div>
                <div className={`singularity-boss-status ${status}`}>
                  {status === 'locked' ? '🔒' : status === 'defeated' ? '✓' : '⚔'}
                </div>
              </div>
            );
          })}
        </div>

        {/* Right panel — detail */}
        <div className="singularity-detail">
          {bossStatus !== 'locked' ? (
            <>
              <NpcSprite
                idleSprite={selectedBoss.idleSprite}
                attackSprite={selectedBoss.attackSprite || selectedBoss.idleSprite}
                isAttacking={false}
                style={{ filter: selectedBoss.spriteFilter || (selectedBoss.phases ? selectedBoss.phases[0].spriteFilter : '') }}
              />

              <div className="singularity-detail-name">
                {selectedBoss.name.toUpperCase()}
              </div>

              <div className="singularity-detail-meta">
                {displayElement.toUpperCase()} · Lv.{displayLevel} · {selectedBoss.difficulty}
                {selectedBoss.phases && (
                  <span className="singularity-phases-indicator" style={{ marginLeft: 8 }}>3 PHASES</span>
                )}
              </div>

              <div className="singularity-detail-stats">
                <div>HP <span>{displayStats.hp}</span></div>
                <div>ATK <span>{displayStats.atk}</span></div>
                <div>DEF <span>{displayStats.def}</span></div>
                <div>SPD <span>{displayStats.spd}</span></div>
              </div>

              <div className="singularity-detail-quote">
                "{selectedBoss.felixQuote}"
                <br />
                <span style={{ color: '#555' }}>— Professor Felix</span>
              </div>

              {/* Dragon picker */}
              <div className="singularity-dragon-picker">
                {ownedDragons.map((el) => {
                  const d = dragons[el];
                  const color = elementColors[el];
                  return (
                    <div
                      key={el}
                      className={`singularity-dragon-option ${el === selectedDragonId ? 'selected' : ''}`}
                      style={{ borderColor: el === selectedDragonId ? color.primary : undefined }}
                      onClick={() => { playSound('buttonClick'); setSelectedDragonId(el); }}
                    >
                      {d.name}
                    </div>
                  );
                })}
              </div>

              <button
                className="singularity-engage-btn"
                disabled={!canEngage}
                onClick={handleEngage}
              >
                ENGAGE
              </button>
            </>
          ) : (
            <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', flex: 1 }}>
              <div style={{ fontSize: 10, color: '#444', textAlign: 'center', lineHeight: 2 }}>
                LOCKED<br />
                <span style={{ fontSize: 7, color: '#333' }}>Defeat the previous boss to unlock</span>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
