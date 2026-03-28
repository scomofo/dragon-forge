import { useState } from 'react';
import { playSound } from './soundEngine';
import { dragons, npcs, elementColors } from './gameData';
import { getTypeEffectiveness, calculateStatsForLevel, getStageForLevel } from './battleEngine';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';
import NavBar from './NavBar';

const dragonList = Object.values(dragons);
const npcList = Object.values(npcs);

export default function BattleSelectScreen({ onBeginBattle, onNavigate, save, refreshSave }) {
  const [selectedDragon, setSelectedDragon] = useState(null);
  const [selectedNpc, setSelectedNpc] = useState(null);

  function getMatchup() {
    if (!selectedDragon || !selectedNpc) return null;
    const eff = getTypeEffectiveness(selectedDragon.element, selectedNpc.element);
    if (eff > 1.0) return { label: 'SUPER EFFECTIVE!', className: 'super-effective' };
    if (eff < 1.0) return { label: 'RESISTED...', className: 'resisted' };
    return { label: 'NEUTRAL', className: 'neutral' };
  }

  const matchup = getMatchup();

  function handleBegin() {
    if (!selectedDragon || !selectedNpc) return;
    playSound('buttonClick');
    onBeginBattle({ dragonId: selectedDragon.id, npcId: selectedNpc.id });
  }

  return (
    <div className="battle-select">
      <NavBar activeScreen="battleSelect" onNavigate={onNavigate} save={save} />
      <div className="battle-select-header">SELECT YOUR BATTLE</div>

      <div className="battle-select-panels">
        <div className="select-panel">
          <h2>YOUR DRAGONS</h2>
          {dragonList.map((dragon) => {
            const progress = save.dragons[dragon.id] || { level: 1, xp: 0, owned: false, shiny: false };
            const isOwned = progress.owned;
            const stage = getStageForLevel(progress.level);
            const baseStats = progress.fusedBaseStats || dragon.baseStats;
            const stats = calculateStatsForLevel(baseStats, progress.level, progress.shiny);
            const color = elementColors[dragon.element];

            if (!isOwned) {
              return (
                <div key={dragon.id} className="select-card" style={{ opacity: 0.4, cursor: 'default' }}>
                  <div style={{ width: 130, height: 90, flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <div style={{ fontSize: 24, color: '#333' }}>?</div>
                  </div>
                  <div className="select-card-info">
                    <div className="select-card-name" style={{ color: '#444' }}>???</div>
                    <div className="select-card-stats">LOCKED — Pull from Hatchery</div>
                  </div>
                </div>
              );
            }

            return (
              <div
                key={dragon.id}
                className={`select-card ${selectedDragon?.id === dragon.id ? 'selected' : ''} ${progress.shiny ? 'shiny-card' : ''}`}
                style={{ borderColor: selectedDragon?.id === dragon.id ? color.primary : undefined }}
                onClick={() => { playSound('buttonClick'); setSelectedDragon(dragon); }}
                tabIndex={0}
                role="button"
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); playSound('buttonClick'); setSelectedDragon(dragon); } }}
              >
                <div style={{ width: 130, height: 90, overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <DragonSprite spriteSheet={dragon.spriteSheet} stage={stage} size={{ width: 130, height: 90 }} shiny={progress.shiny} element={dragon.element} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>
                    {progress.nickname || dragon.name}{progress.shiny && <span className="shiny-star">★</span>}
                  </div>
                  <div className="select-card-stats">
                    Lv.{progress.level} | HP:{stats.hp} ATK:{stats.atk} DEF:{stats.def} SPD:{stats.spd}
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        <div className="select-panel">
          <h2>OPPONENTS</h2>
          {npcList.map((npc) => {
            const color = elementColors[npc.element];
            return (
              <div
                key={npc.id}
                className={`select-card ${selectedNpc?.id === npc.id ? 'selected' : ''}`}
                style={{ borderColor: selectedNpc?.id === npc.id ? color.primary : undefined }}
                onClick={() => { playSound('buttonClick'); setSelectedNpc(npc); }}
                tabIndex={0}
                role="button"
                onKeyDown={(e) => { if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); playSound('buttonClick'); setSelectedNpc(npc); } }}
              >
                <div style={{ width: 60, height: 60, overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <NpcSprite idleSprite={npc.idleSprite} attackSprite={npc.attackSprite} size={55} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>{npc.name}</div>
                  <div className="select-card-stats">
                    Lv.{npc.level} | {npc.difficulty} | {npc.element.toUpperCase()}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {matchup && (
        <div className={`matchup-indicator ${matchup.className}`}>
          {selectedDragon.element.toUpperCase()} vs {selectedNpc.element.toUpperCase()} — {matchup.label}
        </div>
      )}

      <div className="battle-select-footer">
        <button
          className="begin-battle-btn"
          disabled={!selectedDragon || !selectedNpc}
          onClick={handleBegin}
        >
          BEGIN BATTLE
        </button>
      </div>
    </div>
  );
}
