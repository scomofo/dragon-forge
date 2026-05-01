import { useState, useEffect, useRef, useCallback } from 'react';
import {
  FORGE_PALETTE,
  FORGE_STATIONS,
  STATION_IDS,
  CAPTAINS_LOG_FRAGMENTS,
  RELICS,
  FRAGMENT_TRIGGERS,
  listRelics,
  getRelic,
  getBulkheadView,
  getCaptainLogDisplay,
  pickFelixLine,
  findNearestStation,
} from './forgeData';
import {
  setFlag,
  unlockFragment,
  grantRelic,
  equipRelic as persistEquipRelic,
  unequipRelic as persistUnequipRelic,
  setCompanionDragon,
} from './persistence';
import { dragons as DRAGON_DEFS, elementColors } from './gameData';
import DragonSprite from './DragonSprite';
import { playSound } from './soundEngine';

// Movement step (in 0-100 grid units) per keypress.
const STEP = 2;

export default function ForgeScreen({ onNavigate, save, refreshSave }) {
  const [skyePos, setSkyePos] = useState({ x: 30, y: 75 });
  const [activeStation, setActiveStation] = useState(null);
  const [overlay, setOverlay] = useState(null);
  const [felixLine, setFelixLine] = useState(null);
  const screenRef = useRef(null);

  const act = save?.flags?.currentAct || 1;
  const view = getBulkheadView(act);

  const nearest = findNearestStation(skyePos);

  // First-visit + auto-unlock pass: mark Felix met, unlock any fragments whose
  // triggers are already satisfied, and grant a starter relic so the Anvil
  // equip UI has something to show before bounty drops are wired in.
  useEffect(() => {
    let mutated = false;
    if (!save?.flags?.metFelix) {
      setFlag('metFelix', true);
      mutated = true;
    }
    for (const [id, predicate] of Object.entries(FRAGMENT_TRIGGERS)) {
      if (save?.flags?.fragmentsUnlocked?.includes(id)) continue;
      try { if (predicate(save) || ['001', '002'].includes(id)) { unlockFragment(id); mutated = true; } } catch { /* ignore */ }
    }
    if ((save?.skye?.relicsOwned?.length || 0) === 0) {
      grantRelic('iron_knuckle');
      mutated = true;
    }
    if (mutated) refreshSave?.();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const closeOverlay = useCallback(() => {
    setOverlay(null);
    setFelixLine(null);
    playSound('navSwitch');
  }, []);

  const interact = useCallback(() => {
    if (!nearest) return;
    playSound('buttonClick');
    setActiveStation(nearest.id);
    if (nearest.id === STATION_IDS.FELIX) {
      setFelixLine(pickFelixLine(save));
      setOverlay('felix');
    } else if (nearest.id === STATION_IDS.BULKHEAD) {
      playSound('screenTransition');
      onNavigate?.('hatchery');
    } else if (nearest.id === STATION_IDS.SAVE_LANTERN) {
      setOverlay('lantern');
    } else if (nearest.id === STATION_IDS.ANVIL) {
      setOverlay('anvil');
    } else if (nearest.id === STATION_IDS.CONSOLE) {
      setOverlay('console');
    } else if (nearest.id === STATION_IDS.HATCHERY_RING) {
      setOverlay('hatcheryRing');
    }
  }, [nearest, save, onNavigate]);

  // Keyboard nav: WASD/arrows to walk, A/Space/Enter to interact, Esc to close.
  useEffect(() => {
    function onKey(e) {
      if (overlay) {
        if (e.key === 'Escape' || e.key === 'Backspace') {
          e.preventDefault();
          closeOverlay();
        }
        return;
      }
      const k = e.key.toLowerCase();
      let dx = 0, dy = 0;
      if (k === 'arrowup' || k === 'w') dy = -STEP;
      else if (k === 'arrowdown' || k === 's') dy = STEP;
      else if (k === 'arrowleft' || k === 'a') dx = -STEP;
      else if (k === 'arrowright' || k === 'd') dx = STEP;
      else if (k === 'enter' || k === ' ' || k === 'e') { interact(); return; }
      else return;
      e.preventDefault();
      setSkyePos((p) => ({
        x: Math.max(4, Math.min(96, p.x + dx)),
        y: Math.max(20, Math.min(92, p.y + dy)),
      }));
    }
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [overlay, interact, closeOverlay]);

  return (
    <div
      ref={screenRef}
      className="forge-screen"
      style={{
        position: 'relative',
        width: '100%',
        height: '100vh',
        background: `linear-gradient(180deg, ${FORGE_PALETTE.wallShadow} 0%, ${FORGE_PALETTE.floor} 60%, ${FORGE_PALETTE.floorAccent} 100%)`,
        overflow: 'hidden',
        imageRendering: 'pixelated',
        fontFamily: 'monospace',
        color: '#f0e6d2',
      }}
    >
      <BulkheadView view={view} />
      <FloorGrid />

      {FORGE_STATIONS.map((st) => (
        <Station
          key={st.id}
          station={st}
          highlighted={nearest?.id === st.id}
        />
      ))}

      <SkyeSprite pos={skyePos} />

      <ProximityHud nearest={nearest} />

      {overlay === 'anvil' && <AnvilOverlay save={save} onClose={closeOverlay} refreshSave={refreshSave} />}
      {overlay === 'console' && <ConsoleOverlay save={save} onClose={closeOverlay} />}
      {overlay === 'hatcheryRing' && <HatcheryRingOverlay save={save} onClose={closeOverlay} onNavigate={onNavigate} refreshSave={refreshSave} />}
      {overlay === 'lantern' && <LanternOverlay save={save} onClose={closeOverlay} refreshSave={refreshSave} />}
      {overlay === 'felix' && <FelixOverlay line={felixLine} onClose={closeOverlay} />}

      <ControlsHint />
    </div>
  );
}

function BulkheadView({ view }) {
  return (
    <div
      style={{
        position: 'absolute',
        right: 0,
        top: '8%',
        width: '14%',
        height: '60%',
        background: `linear-gradient(180deg, ${view.palette[0]} 0%, ${view.palette[1]} 60%, ${view.palette[2]} 100%)`,
        clipPath: 'polygon(20% 0, 100% 5%, 100% 95%, 10% 100%, 0 60%, 8% 30%)',
        boxShadow: 'inset 6px 0 0 #1a1310, 0 0 24px rgba(0,0,0,0.6)',
      }}
    >
      <div
        style={{
          position: 'absolute',
          inset: 0,
          background: 'repeating-linear-gradient(180deg, transparent 0 6px, rgba(0,0,0,0.08) 6px 7px)',
          pointerEvents: 'none',
        }}
      />
    </div>
  );
}

function FloorGrid() {
  return (
    <div
      aria-hidden
      style={{
        position: 'absolute',
        inset: 0,
        backgroundImage: `repeating-linear-gradient(0deg, transparent 0 31px, rgba(0,0,0,0.12) 31px 32px), repeating-linear-gradient(90deg, transparent 0 31px, rgba(0,0,0,0.12) 31px 32px)`,
        pointerEvents: 'none',
        opacity: 0.6,
      }}
    />
  );
}

function Station({ station, highlighted }) {
  const { pos, size, glow, label, pulseMs } = station;
  return (
    <div
      style={{
        position: 'absolute',
        left: `${pos.x - size.w / 2}%`,
        top: `${pos.y - size.h / 2}%`,
        width: `${size.w}%`,
        height: `${size.h}%`,
        border: `2px solid ${glow || '#888'}`,
        borderRadius: 4,
        background: glow ? `${glow}22` : 'rgba(0,0,0,0.25)',
        boxShadow: highlighted
          ? `0 0 12px ${glow || '#fff'}, inset 0 0 8px ${glow || '#fff'}`
          : (glow ? `0 0 6px ${glow}66` : 'none'),
        animation: pulseMs ? `forgePulse ${pulseMs}ms ease-in-out infinite` : 'none',
        display: 'flex',
        alignItems: 'flex-end',
        justifyContent: 'center',
        padding: 4,
        boxSizing: 'border-box',
        transition: 'box-shadow 120ms',
      }}
    >
      <span
        style={{
          fontSize: 11,
          letterSpacing: 1,
          color: highlighted ? '#fff' : '#bbb',
          textShadow: '1px 1px 0 #000',
          background: 'rgba(0,0,0,0.55)',
          padding: '1px 4px',
          textTransform: 'uppercase',
        }}
      >
        {label}
      </span>
      <style>{`
        @keyframes forgePulse {
          0%, 100% { filter: brightness(1); }
          50% { filter: brightness(1.35); }
        }
      `}</style>
    </div>
  );
}

function SkyeSprite({ pos }) {
  return (
    <div
      style={{
        position: 'absolute',
        left: `${pos.x - 1.5}%`,
        top: `${pos.y - 3}%`,
        width: '3%',
        height: '6%',
        background: '#e8c787',
        border: '2px solid #2a1d14',
        borderRadius: 2,
        boxShadow: '0 2px 0 #1a1310',
        transition: 'left 80ms linear, top 80ms linear',
        zIndex: 5,
      }}
      aria-label="Skye"
    />
  );
}

function ProximityHud({ nearest }) {
  if (!nearest) return null;
  return (
    <div
      style={{
        position: 'absolute',
        bottom: 60,
        left: '50%',
        transform: 'translateX(-50%)',
        background: 'rgba(0,0,0,0.78)',
        border: '2px solid #c9a567',
        padding: '6px 14px',
        fontSize: 13,
        letterSpacing: 1,
      }}
    >
      <span style={{ color: '#c9a567' }}>[E]</span>{' '}
      <strong>{nearest.label}</strong>{' '}
      <span style={{ color: '#bbb' }}>— {nearest.description}</span>
    </div>
  );
}

function ControlsHint() {
  return (
    <div
      style={{
        position: 'absolute',
        top: 12,
        left: 12,
        fontSize: 11,
        color: '#a59678',
        letterSpacing: 1,
        textShadow: '1px 1px 0 #000',
      }}
    >
      WASD / arrows to walk · E to interact · Esc to close
    </div>
  );
}

// === OVERLAYS ===
// Each is a placeholder pixel-bordered panel. Real implementations will be
// composited from existing screens (Hatchery, Stats, etc) in follow-up work.

function OverlayShell({ title, accent = '#c9a567', onClose, children }) {
  return (
    <div
      onClick={onClose}
      style={{
        position: 'absolute',
        inset: 0,
        background: 'rgba(0,0,0,0.55)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        zIndex: 100,
      }}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        style={{
          background: '#1a1310',
          border: `3px solid ${accent}`,
          boxShadow: `0 0 24px ${accent}66, 4px 4px 0 #000`,
          padding: 20,
          minWidth: 420,
          maxWidth: '70%',
          maxHeight: '75%',
          overflow: 'auto',
          imageRendering: 'pixelated',
        }}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
          <h2 style={{ margin: 0, color: accent, letterSpacing: 2, fontSize: 16 }}>{title}</h2>
          <button
            onClick={onClose}
            style={{
              background: 'transparent', color: accent, border: `1px solid ${accent}`,
              padding: '2px 8px', cursor: 'pointer', fontFamily: 'inherit',
            }}
          >ESC</button>
        </div>
        {children}
      </div>
    </div>
  );
}

function AnvilOverlay({ save, onClose, refreshSave }) {
  const tier = save?.skye?.wrenchTier || 1;
  const slots = save?.skye?.relicSlots || 1;
  const owned = save?.skye?.relicsOwned || [];
  const equipped = save?.skye?.relicsEquipped || [];
  const [, force] = useState(0);
  const refresh = () => { refreshSave?.(); force(n => n + 1); };

  function toggle(relicId) {
    if (equipped.includes(relicId)) {
      persistUnequipRelic(relicId);
      playSound('navSwitch');
    } else {
      if (equipped.length >= slots) {
        playSound('terminalWarning');
        return;
      }
      persistEquipRelic(relicId);
      playSound('terminalOk');
    }
    refresh();
  }

  return (
    <OverlayShell title="THE ANVIL — LOADOUT" accent={FORGE_PALETTE.coalGlow} onClose={onClose}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
        <div>
          <span style={{ color: '#ccc' }}>Wrench Tier: </span>
          <strong style={{ color: FORGE_PALETTE.emberOrange }}>T{tier}</strong>
        </div>
        <div>
          <span style={{ color: '#ccc' }}>Relic Slots: </span>
          <strong style={{ color: FORGE_PALETTE.emberOrange }}>{equipped.length} / {slots}</strong>
        </div>
      </div>

      {owned.length === 0 ? (
        <p style={{ color: '#888', fontSize: 12, fontStyle: 'italic' }}>
          No relics yet. Defeat bounty targets to claim Analog Relics.
        </p>
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <RelicColumn
            title="OWNED"
            accent={FORGE_PALETTE.coalGlow}
            ids={owned.filter(id => !equipped.includes(id))}
            actionLabel="EQUIP"
            onAction={toggle}
            disabled={equipped.length >= slots}
          />
          <RelicColumn
            title="EQUIPPED"
            accent={FORGE_PALETTE.emberOrange}
            ids={equipped}
            actionLabel="REMOVE"
            onAction={toggle}
          />
        </div>
      )}
    </OverlayShell>
  );
}

function RelicColumn({ title, accent, ids, actionLabel, onAction, disabled = false }) {
  return (
    <div style={{ border: `1px solid ${accent}55`, padding: 8, minHeight: 160 }}>
      <div style={{ color: accent, letterSpacing: 2, fontSize: 11, marginBottom: 6 }}>{title}</div>
      {ids.length === 0 ? (
        <div style={{ color: '#666', fontSize: 11, fontStyle: 'italic' }}>(empty)</div>
      ) : ids.map(id => {
        const r = getRelic(id);
        if (!r) return null;
        return (
          <div
            key={id}
            style={{
              padding: 6,
              margin: '4px 0',
              background: 'rgba(0,0,0,0.4)',
              border: '1px solid #2a1d14',
              display: 'flex',
              alignItems: 'center',
              gap: 8,
            }}
          >
            <div style={{ fontSize: 18, width: 24, textAlign: 'center', color: r.mythic ? '#ffcc55' : accent }}>{r.icon}</div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 12, color: '#fff' }}>{r.name}{r.mythic ? ' ★' : ''}</div>
              <div style={{ fontSize: 10, color: '#aaa' }}>{r.effect}</div>
            </div>
            <button
              onClick={() => onAction(id)}
              disabled={disabled}
              style={{
                background: disabled ? '#222' : 'transparent',
                color: disabled ? '#555' : accent,
                border: `1px solid ${disabled ? '#333' : accent}`,
                padding: '2px 6px',
                cursor: disabled ? 'not-allowed' : 'pointer',
                fontFamily: 'inherit',
                fontSize: 10,
                letterSpacing: 1,
              }}
            >{actionLabel}</button>
          </div>
        );
      })}
    </div>
  );
}

function ConsoleOverlay({ save, onClose }) {
  const unlocked = save?.flags?.fragmentsUnlocked || [];
  return (
    <OverlayShell title="CAPTAIN'S LOG — CRT TERMINAL" accent={FORGE_PALETTE.consoleGreen} onClose={onClose}>
      <div style={{ fontFamily: 'monospace', fontSize: 12 }}>
        {CAPTAINS_LOG_FRAGMENTS.map((f) => {
          const entry = getCaptainLogDisplay(f, unlocked);
          const isUnlocked = entry.isUnlocked;
          return (
            <div
              key={entry.id}
              style={{
                padding: 8,
                margin: '6px 0',
                background: isUnlocked ? 'rgba(92,255,138,0.06)' : 'rgba(80,80,80,0.15)',
                border: `1px solid ${isUnlocked ? FORGE_PALETTE.consoleGreen : '#444'}`,
                color: isUnlocked ? '#d2ffd6' : '#666',
              }}
            >
              <div style={{ color: isUnlocked ? FORGE_PALETTE.consoleGreen : '#777', letterSpacing: 1 }}>
                {entry.heading}
                {!isUnlocked && <span style={{ color: '#555' }}> [{entry.status}]</span>}
              </div>
              <div style={{ marginTop: 6, color: isUnlocked ? '#cfe2c9' : '#777' }}>{entry.body}</div>
            </div>
          );
        })}
      </div>
    </OverlayShell>
  );
}

function HatcheryRingOverlay({ save, onClose, onNavigate, refreshSave }) {
  const [, force] = useState(0);
  const ownedIds = Object.entries(save?.dragons || {})
    .filter(([, d]) => d.owned)
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
    force(n => n + 1);
  }

  return (
    <OverlayShell title="HATCHERY RING" accent={FORGE_PALETTE.hatcheryCyan} onClose={onClose}>
      {ownedIds.length === 0 ? (
        <div>
          <p style={{ color: '#ccc' }}>No dragons yet. Visit the Hatchery to pull your first egg.</p>
          <button
            onClick={() => { onClose(); onNavigate?.('hatchery'); }}
            style={{
              marginTop: 14, padding: '6px 14px', background: FORGE_PALETTE.hatcheryCyan,
              color: '#001318', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
              letterSpacing: 1, fontWeight: 'bold',
            }}
          >OPEN HATCHERY</button>
        </div>
      ) : (
        <div>
          <div style={{ fontSize: 11, color: '#aaa', letterSpacing: 1, marginBottom: 10 }}>
            {companionUnlocked
              ? 'Select a dragon to bond as your Act IV companion.'
              : `Companion bonding unlocks in Act ${companionLockedUntilAct}. View and manage dragons below.`}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(140px, 1fr))', gap: 10 }}>
            {ownedIds.map(id => {
              const d = save.dragons[id];
              const def = DRAGON_DEFS[id];
              const elem = elementColors[def?.element] || elementColors.neutral;
              const stage = Math.min(4, Math.max(1, Math.ceil(d.level / 4)));
              const isCompanion = companionId === id;
              return (
                <div
                  key={id}
                  onClick={() => pickCompanion(id)}
                  style={{
                    border: `2px solid ${isCompanion ? FORGE_PALETTE.hatcheryCyan : elem.primary + '88'}`,
                    background: isCompanion ? `${FORGE_PALETTE.hatcheryCyan}11` : 'rgba(0,0,0,0.4)',
                    padding: 8,
                    cursor: companionUnlocked ? 'pointer' : 'default',
                    textAlign: 'center',
                    boxShadow: isCompanion ? `0 0 12px ${FORGE_PALETTE.hatcheryCyan}` : 'none',
                    opacity: companionUnlocked ? 1 : 0.85,
                  }}
                >
                  <div style={{ height: 70, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                    <DragonSprite
                      spriteSheet={def?.stageSprites?.[stage] || def?.spriteSheet}
                      stage={stage}
                      element={def?.element || ''}
                      shiny={d.shiny}
                      size={{ width: 64, height: 64 }}
                    />
                  </div>
                  <div style={{ fontSize: 11, color: elem.primary, marginTop: 4 }}>{def?.name || id}</div>
                  <div style={{ fontSize: 10, color: '#aaa' }}>Lv {d.level} · Stage {stage}</div>
                  {isCompanion && (
                    <div style={{ fontSize: 9, color: FORGE_PALETTE.hatcheryCyan, marginTop: 2, letterSpacing: 1 }}>★ COMPANION</div>
                  )}
                </div>
              );
            })}
          </div>
          <button
            onClick={() => { onClose(); onNavigate?.('hatchery'); }}
            style={{
              marginTop: 16, padding: '6px 14px', background: 'transparent',
              color: FORGE_PALETTE.hatcheryCyan, border: `1px solid ${FORGE_PALETTE.hatcheryCyan}`,
              cursor: 'pointer', fontFamily: 'inherit', letterSpacing: 1,
            }}
          >OPEN FULL HATCHERY</button>
        </div>
      )}
    </OverlayShell>
  );
}

function LanternOverlay({ onClose, refreshSave }) {
  function rest() {
    // Placeholder — real implementation refills HP/Capacitors and advances world-time
    refreshSave?.();
    playSound('terminalOk');
    onClose();
  }
  return (
    <OverlayShell title="SAVE LANTERN" accent={FORGE_PALETTE.lanternWarm} onClose={onClose}>
      <p style={{ color: '#ccc' }}>Rest here to refill HP and Capacitors. The world advances by one cycle.</p>
      <button
        onClick={rest}
        style={{
          marginTop: 14, padding: '6px 14px', background: FORGE_PALETTE.lanternWarm,
          color: '#1a1004', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
          letterSpacing: 1, fontWeight: 'bold',
        }}
      >REST</button>
    </OverlayShell>
  );
}

function FelixOverlay({ line, onClose }) {
  return (
    <OverlayShell title="FELIX" accent="#c9a567" onClose={onClose}>
      <p style={{ color: '#e8d2a0', fontSize: 14, lineHeight: 1.5 }}>"{line}"</p>
    </OverlayShell>
  );
}
