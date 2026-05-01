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
      <ForgeAtmosphere />
      <BulkheadView view={view} />
      <ForgeFloorZones />
      <CablePaths />
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

function ForgeAtmosphere() {
  return (
    <>
      <div
        aria-hidden
        style={{
          position: 'absolute',
          inset: 0,
          background: [
            'radial-gradient(ellipse at 30% 62%, rgba(255, 90, 31, 0.24) 0 12%, transparent 36%)',
            'radial-gradient(ellipse at 30% 30%, rgba(94, 220, 255, 0.18) 0 11%, transparent 30%)',
            'radial-gradient(ellipse at 56% 58%, rgba(92, 255, 138, 0.16) 0 10%, transparent 28%)',
            'linear-gradient(180deg, rgba(8, 5, 3, 0.48) 0%, transparent 28%, rgba(4, 3, 2, 0.38) 100%)',
          ].join(', '),
          pointerEvents: 'none',
        }}
      />
      <div
        aria-hidden
        style={{
          position: 'absolute',
          left: '8%',
          right: '18%',
          top: '19%',
          height: '6%',
          background: 'linear-gradient(90deg, transparent, rgba(255, 205, 107, 0.18), transparent)',
          clipPath: 'polygon(4% 45%, 100% 0, 96% 35%, 0 100%)',
          filter: 'blur(1px)',
          pointerEvents: 'none',
        }}
      />
    </>
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

function ForgeFloorZones() {
  const zones = [
    { left: '16%', top: '19%', width: '28%', height: '23%', color: FORGE_PALETTE.hatcheryCyan, label: 'HATCHERY' },
    { left: '19%', top: '50%', width: '25%', height: '26%', color: FORGE_PALETTE.coalGlow, label: 'ANVIL' },
    { left: '45%', top: '49%', width: '22%', height: '28%', color: FORGE_PALETTE.consoleGreen, label: 'CONSOLE' },
    { left: '63%', top: '19%', width: '16%', height: '20%', color: FORGE_PALETTE.lanternWarm, label: 'SAVE' },
  ];
  return (
    <>
      {zones.map((zone) => (
        <div
          key={zone.label}
          aria-hidden
          style={{
            position: 'absolute',
            ...zone,
            border: `1px solid ${zone.color}55`,
            background: `radial-gradient(ellipse at 50% 65%, ${zone.color}22, rgba(0,0,0,0.18) 62%, transparent 72%)`,
            boxShadow: `0 0 24px ${zone.color}18, inset 0 0 18px rgba(0,0,0,0.38)`,
            transform: 'skewX(-6deg)',
            pointerEvents: 'none',
          }}
        />
      ))}
      <div
        aria-hidden
        style={{
          position: 'absolute',
          left: '12%',
          top: '76%',
          width: '23%',
          height: '12%',
          borderTop: '2px solid rgba(201,165,103,0.45)',
          background: 'linear-gradient(180deg, rgba(201,165,103,0.12), transparent)',
          pointerEvents: 'none',
        }}
      />
    </>
  );
}

function CablePaths() {
  const cable = (points, color, width = 3) => (
    <polyline
      points={points}
      fill="none"
      stroke={color}
      strokeWidth={width}
      strokeLinecap="square"
      strokeLinejoin="miter"
      opacity="0.72"
    />
  );
  return (
    <svg
      aria-hidden
      viewBox="0 0 100 100"
      preserveAspectRatio="none"
      style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', pointerEvents: 'none' }}
    >
      {cable('30,75 30,60 42,60 55,60', '#5cff8a', 0.45)}
      {cable('30,75 30,60 30,30', '#5edcff', 0.5)}
      {cable('55,60 70,60 70,28', '#ffcd6b', 0.42)}
      {cable('55,60 76,56 88,50', '#8fcf6c', 0.5)}
      {cable('22,78 30,75', '#c9a567', 0.38)}
      {cable('30,75 30,60 42,60 55,60', 'rgba(0,0,0,0.55)', 1.25)}
      {cable('30,75 30,60 30,30', 'rgba(0,0,0,0.55)', 1.25)}
      {cable('55,60 70,60 70,28', 'rgba(0,0,0,0.55)', 1.1)}
      {cable('55,60 76,56 88,50', 'rgba(0,0,0,0.55)', 1.1)}
    </svg>
  );
}

function FloorGrid() {
  return (
    <div
      aria-hidden
      style={{
        position: 'absolute',
        inset: 0,
        backgroundImage: `repeating-linear-gradient(0deg, transparent 0 47px, rgba(0,0,0,0.18) 47px 49px), repeating-linear-gradient(90deg, transparent 0 47px, rgba(255,255,255,0.035) 47px 49px)`,
        pointerEvents: 'none',
        opacity: 0.45,
      }}
    />
  );
}

function Station({ station, highlighted }) {
  const { pos, size, glow, label, pulseMs } = station;
  const stationType = station.id;
  return (
    <div
      style={{
        position: 'absolute',
        left: `${pos.x - size.w / 2}%`,
        top: `${pos.y - size.h / 2}%`,
        width: `${size.w}%`,
        height: `${size.h}%`,
        border: highlighted ? `2px solid ${glow || '#d7ad4b'}` : '1px solid rgba(240,230,210,0.22)',
        borderRadius: stationType === STATION_IDS.HATCHERY_RING ? '50%' : 4,
        background: 'rgba(8, 5, 3, 0.28)',
        boxShadow: highlighted
          ? `0 0 22px ${glow || '#d7ad4b'}, inset 0 0 18px ${glow || '#d7ad4b'}55`
          : `0 10px 16px rgba(0,0,0,0.34), ${glow ? `0 0 14px ${glow}44` : 'none'}`,
        animation: pulseMs ? `forgePulse ${pulseMs}ms ease-in-out infinite` : 'none',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'flex-end',
        justifyContent: 'flex-end',
        padding: 3,
        boxSizing: 'border-box',
        transition: 'box-shadow 120ms, transform 120ms',
        transform: highlighted ? 'translateY(-2px)' : 'none',
      }}
    >
      <StationSilhouette type={stationType} glow={glow} highlighted={highlighted} />
      <span
        style={{
          position: 'absolute',
          left: '50%',
          bottom: -18,
          transform: 'translateX(-50%)',
          whiteSpace: 'nowrap',
          fontSize: 10,
          letterSpacing: 1,
          color: highlighted ? '#fff' : '#bbb',
          textShadow: '1px 1px 0 #000',
          background: highlighted ? 'rgba(0,0,0,0.82)' : 'rgba(0,0,0,0.62)',
          border: `1px solid ${highlighted ? glow || '#d7ad4b' : 'rgba(255,255,255,0.18)'}`,
          padding: '2px 5px',
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

function StationSilhouette({ type, glow, highlighted }) {
  const color = glow || '#c9a567';
  const common = {
    position: 'absolute',
    inset: '10%',
    filter: highlighted ? `drop-shadow(0 0 6px ${color})` : 'none',
  };
  if (type === STATION_IDS.HATCHERY_RING) {
    return (
      <div style={common}>
        <div style={{ position: 'absolute', inset: '6%', border: `4px solid ${color}`, borderRadius: '50%', boxShadow: `inset 0 0 18px ${color}55` }} />
        <div style={{ position: 'absolute', left: '38%', top: '32%', width: '24%', height: '36%', borderRadius: '50%', background: '#f0e6d2', boxShadow: `0 0 14px ${color}` }} />
        <div style={{ position: 'absolute', left: '8%', right: '8%', top: '48%', height: 2, background: color }} />
        <div style={{ position: 'absolute', left: '48%', top: '8%', bottom: '8%', width: 2, background: color }} />
      </div>
    );
  }
  if (type === STATION_IDS.ANVIL) {
    return (
      <div style={common}>
        <div style={{ position: 'absolute', left: '12%', top: '26%', width: '64%', height: '24%', background: color, clipPath: 'polygon(0 35%, 62% 35%, 78% 0, 100% 0, 100% 70%, 72% 70%, 58% 100%, 0 100%)' }} />
        <div style={{ position: 'absolute', left: '34%', top: '50%', width: '24%', height: '28%', background: '#1a1310', border: `2px solid ${color}` }} />
        <div style={{ position: 'absolute', left: '20%', right: '20%', bottom: '8%', height: '12%', background: '#0f0a07', borderTop: `2px solid ${color}` }} />
      </div>
    );
  }
  if (type === STATION_IDS.CONSOLE) {
    return (
      <div style={common}>
        <div style={{ position: 'absolute', left: '12%', top: '10%', width: '66%', height: '46%', background: '#0b1711', border: `3px solid ${color}`, boxShadow: `inset 0 0 14px ${color}66` }} />
        <div style={{ position: 'absolute', left: '22%', top: '22%', width: '44%', height: '12%', background: color }} />
        <div style={{ position: 'absolute', left: '18%', top: '66%', width: '58%', height: '18%', background: '#1a1310', border: `2px solid ${color}` }} />
      </div>
    );
  }
  if (type === STATION_IDS.SAVE_LANTERN) {
    return (
      <div style={common}>
        <div style={{ position: 'absolute', left: '42%', top: '4%', width: '16%', height: '88%', background: '#120c08', borderLeft: `2px solid ${color}`, borderRight: `2px solid ${color}` }} />
        <div style={{ position: 'absolute', left: '18%', top: '18%', width: '64%', height: '38%', background: color, clipPath: 'polygon(20% 0, 80% 0, 100% 100%, 0 100%)', boxShadow: `0 0 18px ${color}` }} />
      </div>
    );
  }
  if (type === STATION_IDS.BULKHEAD) {
    return (
      <div style={common}>
        <div style={{ position: 'absolute', inset: '4%', background: `linear-gradient(90deg, #102514, ${color}44)`, border: `3px solid ${color}`, clipPath: 'polygon(22% 0, 100% 6%, 100% 94%, 12% 100%, 0 62%, 10% 28%)' }} />
        <div style={{ position: 'absolute', left: '30%', top: '14%', bottom: '14%', width: 3, background: color }} />
        <div style={{ position: 'absolute', left: '54%', top: '12%', bottom: '12%', width: 3, background: color }} />
      </div>
    );
  }
  return (
    <div style={common}>
      <div style={{ position: 'absolute', left: '36%', top: '18%', width: '28%', height: '28%', borderRadius: '50%', background: '#c9a567' }} />
      <div style={{ position: 'absolute', left: '28%', top: '46%', width: '44%', height: '38%', background: '#5b3c24', border: '2px solid #c9a567' }} />
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
