import { useState, useEffect, useRef, useCallback } from 'react';
import {
  FORGE_PALETTE,
  FORGE_STATIONS,
  STATION_IDS,
  CAPTAINS_LOG_FRAGMENTS,
  getBulkheadView,
  pickFelixLine,
  findNearestStation,
} from './forgeData';
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

      {overlay === 'anvil' && <AnvilOverlay save={save} onClose={closeOverlay} />}
      {overlay === 'console' && <ConsoleOverlay save={save} onClose={closeOverlay} />}
      {overlay === 'hatcheryRing' && <HatcheryRingOverlay save={save} onClose={closeOverlay} onNavigate={onNavigate} />}
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

function AnvilOverlay({ save, onClose }) {
  const tier = save?.skye?.wrenchTier || 1;
  const slots = save?.skye?.relicSlots || 1;
  const equipped = save?.skye?.equippedRelics || [];
  return (
    <OverlayShell title="THE ANVIL — LOADOUT" accent={FORGE_PALETTE.coalGlow} onClose={onClose}>
      <p style={{ margin: '4px 0', color: '#ccc' }}>Wrench Tier: <strong style={{ color: FORGE_PALETTE.emberOrange }}>T{tier}</strong></p>
      <p style={{ margin: '4px 0', color: '#ccc' }}>Relic Slots: <strong>{equipped.length} / {slots}</strong></p>
      <hr style={{ border: 0, borderTop: '1px solid #444', margin: '12px 0' }} />
      <p style={{ color: '#888', fontSize: 12, fontStyle: 'italic' }}>
        Relic equip UI coming online. Bring back drops from bounty kills to populate this list.
      </p>
    </OverlayShell>
  );
}

function ConsoleOverlay({ save, onClose }) {
  const unlocked = save?.flags?.fragmentsUnlocked || [];
  return (
    <OverlayShell title="CAPTAIN'S LOG — CRT TERMINAL" accent={FORGE_PALETTE.consoleGreen} onClose={onClose}>
      <div style={{ fontFamily: 'monospace', fontSize: 12 }}>
        {CAPTAINS_LOG_FRAGMENTS.map((f) => {
          const isUnlocked = unlocked.includes(f.id);
          return (
            <div
              key={f.id}
              style={{
                padding: 8,
                margin: '6px 0',
                background: isUnlocked ? 'rgba(92,255,138,0.06)' : 'rgba(80,80,80,0.15)',
                border: `1px solid ${isUnlocked ? FORGE_PALETTE.consoleGreen : '#444'}`,
                color: isUnlocked ? '#d2ffd6' : '#666',
              }}
            >
              <div style={{ color: isUnlocked ? FORGE_PALETTE.consoleGreen : '#777', letterSpacing: 1 }}>
                FRAGMENT {f.id} — {isUnlocked ? f.title.toUpperCase() : '[DEFRAGMENTING...]'}
              </div>
              {isUnlocked && (
                <div style={{ marginTop: 6, color: '#cfe2c9' }}>{f.body}</div>
              )}
            </div>
          );
        })}
      </div>
    </OverlayShell>
  );
}

function HatcheryRingOverlay({ onClose, onNavigate }) {
  return (
    <OverlayShell title="HATCHERY RING" accent={FORGE_PALETTE.hatcheryCyan} onClose={onClose}>
      <p style={{ color: '#ccc' }}>Egg care, bonding, and Act IV companion selection happen here.</p>
      <p style={{ color: '#888', fontSize: 12, fontStyle: 'italic', marginTop: 12 }}>
        Routes through the existing Hatchery system for now.
      </p>
      <button
        onClick={() => { onClose(); onNavigate?.('hatchery'); }}
        style={{
          marginTop: 14, padding: '6px 14px', background: FORGE_PALETTE.hatcheryCyan,
          color: '#001318', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
          letterSpacing: 1, fontWeight: 'bold',
        }}
      >OPEN HATCHERY</button>
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
