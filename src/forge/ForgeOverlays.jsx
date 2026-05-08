import { useEffect, useRef, useState } from 'react';
import { getStageForLevel } from '../battleEngine';
import DragonSprite from '../DragonSprite';
import {
  CAPTAINS_LOG_FRAGMENTS,
  FORGE_PALETTE,
  getCaptainLogDisplay,
  getRelic,
  getUsedRelicSlots,
  listRelics,
} from '../forgeData';
import { dragons as DRAGON_DEFS, elementColors } from '../gameData';
import {
  equipRelic as persistEquipRelic,
  setCompanionDragon,
  unequipRelic as persistUnequipRelic,
} from '../persistence';
import { playSound } from '../soundEngine';

export function OverlayShell({ title, accent = '#c9a567', onClose, children }) {
  const closeButtonRef = useRef(null);

  useEffect(() => {
    closeButtonRef.current?.focus();
  }, []);

  return (
    <div className="forge-overlay-backdrop" onClick={onClose}>
      <section
        className="forge-overlay-shell"
        style={{ '--overlay-accent': accent }}
        onClick={(event) => event.stopPropagation()}
        role="dialog"
        aria-modal="true"
        aria-label={title}
      >
        <div className="forge-overlay-header">
          <h2>{title}</h2>
          <button ref={closeButtonRef} type="button" onClick={onClose} aria-label="Close overlay">ESC</button>
        </div>
        {children}
      </section>
    </div>
  );
}

export function AnvilOverlay({ save, onClose, refreshSave }) {
  const tier = save?.skye?.wrenchTier || 1;
  const slots = save?.skye?.relicSlots || 1;
  const owned = save?.skye?.relicsOwned || [];
  const equipped = save?.skye?.relicsEquipped || [];
  const usedSlots = getUsedRelicSlots(equipped);
  const [, force] = useState(0);
  const refresh = () => {
    refreshSave?.();
    force((n) => n + 1);
  };

  function toggle(relicId) {
    const relic = getRelic(relicId);
    if (!relic) return;
    if (equipped.includes(relicId)) {
      persistUnequipRelic(relicId);
      playSound('navSwitch');
    } else {
      if (usedSlots + (relic.slotCost || 1) > slots) {
        playSound('terminalWarning');
        return;
      }
      persistEquipRelic(relicId);
      playSound('terminalOk');
    }
    refresh();
  }

  return (
    <OverlayShell title="THE ANVIL - LOADOUT" accent={FORGE_PALETTE.coalGlow} onClose={onClose}>
      <div className="forge-overlay-summary">
        <div><span>Wrench Tier</span><strong>T{tier}</strong></div>
        <div><span>Relic Slots</span><strong>{usedSlots} / {slots}</strong></div>
      </div>
      {owned.length === 0 ? (
        <p className="forge-muted">No relics yet. Defeat bounty targets to claim Analog Relics.</p>
      ) : (
        <div className="forge-relic-grid">
          <RelicColumn
            title="OWNED"
            accent={FORGE_PALETTE.coalGlow}
            ids={owned.filter((id) => !equipped.includes(id))}
            equipped={equipped}
            actionLabel="EQUIP"
            onAction={toggle}
            slots={slots}
            usedSlots={usedSlots}
          />
          <RelicColumn
            title="EQUIPPED"
            accent={FORGE_PALETTE.emberOrange}
            ids={equipped}
            equipped={equipped}
            actionLabel="REMOVE"
            onAction={toggle}
            slots={slots}
            usedSlots={usedSlots}
          />
        </div>
      )}
    </OverlayShell>
  );
}

function RelicColumn({ title, accent, ids, equipped, actionLabel, onAction, slots, usedSlots }) {
  return (
    <div className="forge-relic-column" style={{ '--column-accent': accent }}>
      <div className="forge-column-title">{title}</div>
      {ids.length === 0 ? (
        <div className="forge-empty">(empty)</div>
      ) : ids.map((id) => {
        const relic = getRelic(id);
        if (!relic) return null;
        const isEquipped = equipped.includes(id);
        const disabled = !isEquipped && usedSlots + (relic.slotCost || 1) > slots;
        return (
          <div key={id} className={`forge-relic-card ${isEquipped ? 'is-equipped' : ''}`}>
            <div className="forge-relic-icon">{relic.icon}</div>
            <div className="forge-relic-copy">
              <div>{relic.name}{relic.mythic ? ' *' : ''}</div>
              <small>{relic.effect}</small>
              <small>Cost {relic.slotCost || 1} | {isEquipped ? 'Equipped' : 'Owned'}</small>
            </div>
            <button type="button" onClick={() => onAction(id)} disabled={disabled}>
              {disabled ? 'FULL' : actionLabel}
            </button>
          </div>
        );
      })}
    </div>
  );
}

export function ConsoleOverlay({ save, onClose, onNavigate }) {
  const unlocked = save?.flags?.fragmentsUnlocked || [];
  return (
    <OverlayShell title="CAPTAIN'S LOG - CRT TERMINAL" accent={FORGE_PALETTE.consoleGreen} onClose={onClose}>
      <div className="forge-console-counts">
        {unlocked.length} / {CAPTAINS_LOG_FRAGMENTS.length} fragments decrypted
      </div>
      <div className="forge-log-list">
        {CAPTAINS_LOG_FRAGMENTS.map((fragment) => {
          const entry = getCaptainLogDisplay(fragment, unlocked);
          return (
            <article key={entry.id} className={`forge-log-entry ${entry.isUnlocked ? 'is-unlocked' : ''}`}>
              <h3>{entry.heading}{!entry.isUnlocked && <span> [{entry.status}]</span>}</h3>
              <p>{entry.body}</p>
            </article>
          );
        })}
      </div>
      <button className="forge-secondary-action" type="button" onClick={() => { onClose(); onNavigate?.('journal'); }}>
        OPEN JOURNAL
      </button>
    </OverlayShell>
  );
}

export function HatcheryRingOverlay({ save, onClose, onNavigate, refreshSave }) {
  const [, force] = useState(0);
  const ownedIds = Object.entries(save?.dragons || {})
    .filter(([, dragon]) => dragon.owned)
    .map(([id]) => id);
  const companionId = save?.skye?.companionDragonId || null;
  const companionLockedUntilAct = 4;
  const companionUnlocked = (save?.flags?.currentAct || 1) >= companionLockedUntilAct;

  function pickCompanion(id) {
    if (!companionUnlocked) {
      playSound('terminalWarning');
      return;
    }
    setCompanionDragon(companionId === id ? null : id);
    playSound('terminalOk');
    refreshSave?.();
    force((n) => n + 1);
  }

  return (
    <OverlayShell title="HATCHERY RING" accent={FORGE_PALETTE.hatcheryCyan} onClose={onClose}>
      {ownedIds.length === 0 ? (
        <div>
          <p className="forge-muted">No dragons yet. Visit the Hatchery to pull your first egg.</p>
          <button className="forge-primary-action" type="button" onClick={() => { onClose(); onNavigate?.('hatchery'); }}>
            OPEN HATCHERY
          </button>
        </div>
      ) : (
        <>
          <p className="forge-muted">
            {companionUnlocked
              ? 'Select a dragon to bond as your Act IV companion.'
              : `Companion bonding unlocks in Act ${companionLockedUntilAct}. Manage dragons or review discoveries below.`}
          </p>
          <div className="forge-hatchery-grid">
            {ownedIds.map((id) => {
              const dragon = save.dragons[id];
              const def = DRAGON_DEFS[id];
              const element = elementColors[def?.element] || elementColors.neutral;
              const stage = getStageForLevel(dragon.level);
              const isCompanion = companionId === id;
              return (
                <button
                  type="button"
                  key={id}
                  className={`forge-dragon-card ${isCompanion ? 'is-companion' : ''}`}
                  style={{ '--dragon-accent': element.primary }}
                  onClick={() => pickCompanion(id)}
                  aria-label={`${def?.name || id}, level ${dragon.level}, stage ${stage}${isCompanion ? ', companion' : ''}`}
                >
                  <span className="forge-dragon-sprite">
                    <DragonSprite
                      spriteSheet={def?.stageSprites?.[stage] || def?.spriteSheet}
                      stage={stage}
                      element={def?.element || ''}
                      shiny={dragon.shiny}
                      size={{ width: 64, height: 64 }}
                    />
                  </span>
                  <strong>{def?.name || id}</strong>
                  <small>Lv {dragon.level} | Stage {stage}</small>
                  {isCompanion && <small>COMPANION</small>}
                </button>
              );
            })}
          </div>
          <div className="forge-overlay-actions">
            <button type="button" onClick={() => { onClose(); onNavigate?.('hatchery'); }}>OPEN FULL HATCHERY</button>
            <button type="button" onClick={() => { onClose(); onNavigate?.('journal'); }}>OPEN JOURNAL</button>
          </div>
        </>
      )}
    </OverlayShell>
  );
}

export function LanternOverlay({ onClose, refreshSave }) {
  function checkpoint() {
    refreshSave?.();
    playSound('terminalOk');
    onClose();
  }

  return (
    <OverlayShell title="SAVE LANTERN" accent={FORGE_PALETTE.lanternWarm} onClose={onClose}>
      <p className="forge-muted">Checkpoint synced. Current systems have no rest-only HP or capacitor state to refill yet.</p>
      <button className="forge-primary-action" type="button" onClick={checkpoint}>SYNC CHECKPOINT</button>
    </OverlayShell>
  );
}

export function FelixOverlay({ line, onClose }) {
  return (
    <OverlayShell title="FELIX" accent="#c9a567" onClose={onClose}>
      <p className="forge-felix-line">"{line}"</p>
      <div className="forge-known-relics">
        <span>{listRelics().length} relic patterns logged in the Anvil.</span>
      </div>
    </OverlayShell>
  );
}
