import { useState } from 'react';
import { dragons, npcs, elementColors } from './gameData';
import { getTypeEffectiveness, calculateStatsForLevel, getStageForLevel } from './battleEngine';
import { loadSave } from './persistence';
import DragonSprite from './DragonSprite';
import NpcSprite from './NpcSprite';

const dragonList = Object.values(dragons);
const npcList = Object.values(npcs);

export default function BattleSelectScreen({ onBeginBattle }) {
  const [selectedDragon, setSelectedDragon] = useState(null);
  const [selectedNpc, setSelectedNpc] = useState(null);
  const save = loadSave();

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
    onBeginBattle({ dragonId: selectedDragon.id, npcId: selectedNpc.id });
  }

  return (
    <div className="battle-select">
      <div className="battle-select-header">SELECT YOUR BATTLE</div>

      <div className="battle-select-panels">
        <div className="select-panel">
          <h2>YOUR DRAGONS</h2>
          {dragonList.map((dragon) => {
            const progress = save.dragons[dragon.id] || { level: 1, xp: 0 };
            const stage = getStageForLevel(progress.level);
            const stats = calculateStatsForLevel(dragon.baseStats, progress.level);
            const color = elementColors[dragon.element];
            return (
              <div
                key={dragon.id}
                className={`select-card ${selectedDragon?.id === dragon.id ? 'selected' : ''}`}
                style={{ borderColor: selectedDragon?.id === dragon.id ? color.primary : undefined }}
                onClick={() => setSelectedDragon(dragon)}
              >
                <div style={{ width: 100, height: 70, overflow: 'hidden', flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                  <DragonSprite spriteSheet={dragon.spriteSheet} stage={stage} size={{ width: 100, height: 70 }} />
                </div>
                <div className="select-card-info">
                  <div className="select-card-name" style={{ color: color.primary }}>{dragon.name}</div>
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
                onClick={() => setSelectedNpc(npc)}
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
