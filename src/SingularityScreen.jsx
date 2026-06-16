import { useState } from 'react';
import { playSound } from './soundEngine';
import { dragons, elementColors, ELEMENTS } from './gameData';
import { SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN, CORRUPTION_REMNANTS, getBossStatus } from './singularityBosses';
import { getRemnantProgress } from './singularityProgress';
import { startNewGamePlus } from './persistence';
import NavBar from './NavBar';
import NpcSprite from './NpcSprite';

const ALL_BOSSES = [...SINGULARITY_BOSSES, FINAL_BOSS, MIRROR_ADMIN];

export default function SingularityScreen({ onNavigate, onEngageBoss, onEngageRemnant, save }) {
  const [selectedBossId, setSelectedBossId] = useState(ALL_BOSSES[0].id);
  const [selectedDragonId, setSelectedDragonId] = useState(() => {
    const firstOwned = ELEMENTS.find(el => save.dragons[el]?.owned);
    return firstOwned || 'fire';
  });
  const [confirmingNg, setConfirmingNg] = useState(false);

  const handleNewGamePlus = () => {
    playSound('screenTransition');
    startNewGamePlus();
    onNavigate('hatchery'); // re-locks the Singularity; onNavigate refreshes the save
  };

  // Fall back to the first boss if the selected id ever fails to resolve, so the
  // screen can never crash on selectedBoss.phases/stats (ALL_BOSSES is non-empty).
  const selectedBoss = ALL_BOSSES.find(b => b.id === selectedBossId) || ALL_BOSSES[0];
  const bossStatus = getBossStatus(selectedBoss, save);
  const canEngage = bossStatus === 'available' || bossStatus === 'defeated';
  const ownedDragons = ELEMENTS.filter(el => save.dragons[el]?.owned);
  const remnantProgress = getRemnantProgress(save);

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
      isMirrorAdmin: selectedBoss.id === 'mirror_admin',
    });
  };

  const handleEngageRemnant = (remnant) => {
    playSound('buttonClick');
    onEngageRemnant({
      dragonId: selectedDragonId,
      boss: remnant,
    });
  };

  const getRemnantStatus = (remnant) => {
    if (!remnantProgress.available) return 'locked';
    if (remnantProgress.defeated.includes(remnant.id)) return 'defeated';
    if (!remnant.unlockRequires) return 'available';
    if (remnantProgress.defeated.includes(remnant.unlockRequires)) return 'available';
    return 'locked';
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
          {/* New Game+ — offered once the Mirror Admin (true final) has fallen */}
          {save.mirrorAdminDefeated && (
            <div className="singularity-boss-card" style={{ marginBottom: 8, borderColor: '#ffaa44', cursor: 'default', flexDirection: 'column', alignItems: 'stretch', background: 'rgba(40,24,8,0.4)' }}>
              <div style={{ fontSize: 8, color: '#ffcc66', letterSpacing: 1, textTransform: 'uppercase' }}>
                New Game+{save.ngPlus > 0 ? ` · Tier ${save.ngPlus}` : ''}
              </div>
              <div style={{ fontSize: 6, color: '#aa8844', margin: '3px 0 5px', lineHeight: 1.5 }}>
                Replay the campaign &amp; Singularity. Enemies +25% / rewards +25% per tier. Keeps your dragons, scraps &amp; cores.
              </div>
              {confirmingNg ? (
                <div style={{ display: 'flex', gap: 4 }}>
                  <button className="singularity-engage-btn" style={{ fontSize: 6, padding: '3px 6px', flex: 1 }} onClick={handleNewGamePlus}>CONFIRM RESET</button>
                  <button className="singularity-engage-btn" style={{ fontSize: 6, padding: '3px 6px', flex: 1, background: '#333', borderColor: '#555' }} onClick={() => { playSound('buttonClick'); setConfirmingNg(false); }}>CANCEL</button>
                </div>
              ) : (
                <button className="singularity-engage-btn" style={{ fontSize: 6, padding: '3px 6px' }} onClick={() => { playSound('buttonClick'); setConfirmingNg(true); }}>
                  START NEW GAME+
                </button>
              )}
            </div>
          )}
          {ALL_BOSSES.map((boss) => {
            const status = getBossStatus(boss, save);
            const isSelected = boss.id === selectedBossId;

            return (
              <div
                key={boss.id}
                className={`singularity-boss-card ${status} ${isSelected ? 'selected' : ''}`}
                onClick={() => handleSelectBoss(boss.id)}
                tabIndex={0}
                role="button"
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); handleSelectBoss(boss.id); } }}
              >
                <div>
                  <div className="singularity-boss-name">
                    {status === 'locked' ? '???' : boss.name.toUpperCase()}
                  </div>
                  <div className="singularity-boss-sub">
                    {status === 'locked'
                      ? (boss.id === 'mirror_admin' && save.singularityComplete ? 'UNLOCK ALL LOG FRAGMENTS' : 'LOCKED')
                      : `${boss.difficulty} · ${(boss.phases ? boss.phases[0].element : boss.element).toUpperCase()}`}
                    {boss.phases && status !== 'locked' && ' · 3 PHASES'}
                    {status === 'defeated' && (save.singularityProgress?.replayCounts?.[boss.id] || 0) > 1 && (
                      <span style={{ marginLeft: 4, color: '#ff6600' }}>×{save.singularityProgress.replayCounts[boss.id]}</span>
                    )}
                  </div>
                </div>
                <div className={`singularity-boss-status ${status}`}>
                  {status === 'locked' ? '🔒' : status === 'defeated' ? '✓' : '⚔'}
                </div>
              </div>
            );
          })}

          {/* Corruption Remnants — post-game only */}
          {remnantProgress.available && (
            <>
              <div
                className="singularity-boss-card"
                style={{
                  marginTop: 12,
                  borderTop: '1px solid #330033',
                  paddingTop: 8,
                  cursor: 'default',
                  background: 'transparent',
                }}
              >
                <div style={{ fontSize: 7, color: '#aa00aa', letterSpacing: 2, textTransform: 'uppercase' }}>
                  Corruption Remnants
                </div>
                <div style={{ fontSize: 6, color: '#660066' }}>
                  {remnantProgress.defeated.length}/3 CLEARED
                </div>
              </div>
              {CORRUPTION_REMNANTS.map((remnant) => {
                const rstatus = getRemnantStatus(remnant);
                return (
                  <div
                    key={remnant.id}
                    className={`singularity-boss-card ${rstatus}`}
                    style={{ opacity: rstatus === 'locked' ? 0.45 : 1 }}
                  >
                    <div>
                      <div className="singularity-boss-name" style={{ color: rstatus === 'locked' ? '#555' : '#cc44cc' }}>
                        {rstatus === 'locked' ? '???' : remnant.name.toUpperCase()}
                      </div>
                      <div className="singularity-boss-sub">
                        {rstatus === 'locked' ? 'LOCKED' : `REMNANT · ${remnant.phases[0].element.toUpperCase()} · 3 PHASES`}
                      </div>
                    </div>
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
                      <div className={`singularity-boss-status ${rstatus}`}>
                        {rstatus === 'locked' ? '🔒' : rstatus === 'defeated' ? '✓' : '⚔'}
                      </div>
                      {rstatus !== 'locked' && (
                        <button
                          className="singularity-engage-btn"
                          style={{ fontSize: 6, padding: '2px 6px', marginTop: 2 }}
                          onClick={() => handleEngageRemnant(remnant)}
                        >
                          CHALLENGE
                        </button>
                      )}
                    </div>
                  </div>
                );
              })}
            </>
          )}
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
                      tabIndex={0}
                      role="button"
                      onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); playSound('buttonClick'); setSelectedDragonId(el); } }}
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
