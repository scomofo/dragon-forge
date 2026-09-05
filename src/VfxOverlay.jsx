import { useState, useEffect, useRef, useCallback } from 'react';
import { elementColors } from './gameData';
import { VFX_FRAMES } from './sprites';

// Strip playback timing. Travel = projectile flying across the arena (frames
// 0..n-2), impact = the burst frame held on the target (frame n-1). The
// profile (battlePresentation) passes per-move timing — heavy attacks fly
// slower, light attacks snap, and 2x battle speed halves both.
const DEFAULT_TRAVEL_MS = 330;
const DEFAULT_IMPACT_MS = 220;
const STRIP_DISPLAY = 200; // px the projectile renders at on screen

// Arena anchor positions (% of the .arena-sprites width). targetSide is the
// side that takes the hit, so the projectile starts on the opposite side.
const NEAR_EDGE = 18;
const FAR_EDGE = 78;

export default function VfxOverlay({ vfxKey, element, direction, onImpact, onComplete, targetSide, travelMs, impactMs }) {
  const config = VFX_FRAMES[vfxKey];
  const travel = travelMs || DEFAULT_TRAVEL_MS;
  const impact = impactMs || DEFAULT_IMPACT_MS;

  if (config?.strip) {
    return <StripVfx config={config} targetSide={targetSide} onImpact={onImpact} onComplete={onComplete} travelMs={travel} impactMs={impact} />;
  }
  if (config?.signature) {
    return <SignatureVfx config={config} targetSide={targetSide} onImpact={onImpact} onComplete={onComplete} travelMs={travel} impactMs={impact} />;
  }
  return (
    <LegacyVfx
      vfxKey={vfxKey}
      element={element}
      direction={direction}
      targetSide={targetSide}
      onImpact={onImpact}
      onComplete={onComplete}
      travelMs={travel}
      impactMs={impact}
    />
  );
}

// === Animated projectile strip ===
function StripVfx({ config, targetSide, onImpact, onComplete, travelMs, impactMs }) {
  const ref = useRef(null);
  const doneRef = useRef(false);
  const impactRef = useRef(false);

  useEffect(() => {
    doneRef.current = false;
    impactRef.current = false;
    const el = ref.current;
    if (!el) {
      onComplete();
      return undefined;
    }
    const { frames } = config.strip;
    // targetSide 'left' => target is on the left, projectile flies right->left
    const toLeft = targetSide === 'left';
    const startX = toLeft ? FAR_EDGE : NEAR_EDGE;
    const endX = toLeft ? NEAR_EDGE : FAR_EDGE;
    const flip = toLeft ? -1 : 1; // strips face right; mirror for leftward flight
    const total = travelMs + impactMs;
    const travelEnd = travelMs / total;

    let raf = 0;
    let startTs = null;
    let active = true;

    const tick = (ts) => {
      if (!active) return;
      if (startTs == null) startTs = ts;
      const t = Math.min(1, (ts - startTs) / total);

      let x;
      let frameIdx;
      let scale;
      let opacity;
      if (t < travelEnd) {
        const tt = t / travelEnd;
        x = startX + (endX - startX) * tt;
        frameIdx = Math.min(frames - 2, Math.floor(tt * (frames - 1)));
        scale = 0.7 + 0.35 * tt;
        opacity = Math.min(1, tt * 5);
      } else {
        const tt = (t - travelEnd) / (1 - travelEnd);
        x = endX;
        frameIdx = frames - 1; // impact burst
        scale = 1.1 + 0.4 * Math.sin(Math.min(1, tt) * Math.PI);
        opacity = 1 - Math.max(0, (tt - 0.45) / 0.55);
      }

      el.style.left = `${x}%`;
      el.style.opacity = String(opacity);
      el.style.backgroundPosition = `${-frameIdx * STRIP_DISPLAY}px 0px`;
      el.style.transform = `translate(-50%, -50%) scale(${flip * scale}, ${scale})`;

      if (t >= travelEnd && !impactRef.current) {
        impactRef.current = true;
        onImpact?.();
      }
      if (!active) return;
      if (t >= 1) {
        if (!doneRef.current) {
          doneRef.current = true;
          onComplete();
        }
        return;
      }
      raf = requestAnimationFrame(tick);
    };

    raf = requestAnimationFrame(tick);
    return () => { active = false; cancelAnimationFrame(raf); };
  }, [config, targetSide, onImpact, onComplete, travelMs, impactMs]);

  return (
    <div
      ref={ref}
      className="vfx-strip"
      style={{
        backgroundImage: `url(${config.strip.src})`,
        backgroundSize: `${STRIP_DISPLAY * config.strip.frames}px ${STRIP_DISPLAY}px`,
        width: `${STRIP_DISPLAY}px`,
        height: `${STRIP_DISPLAY}px`,
      }}
    />
  );
}

// === Dedicated signature VFX (P1.2) ===
// Procedural contract: each signature owns a palette + motif + motion so no
// two signatures read the same. When 1024×256 signature strips ship, they
// attach as `strip` on the same entry and take over automatically.
const SIGNATURE_GLYPHS = {
  'anvil-ring': '◉',
  'snowflake-collapse': '❄',
  'gear-spark': '⚙',
  'wall-brick': '▣',
  'fang-drip': '☠',
  'rift-slash': '✕',
  'vortex-drain': '🌀',
  'pane-bloom': '☀',
  'diamond-weave': '✦',
};

function SignatureVfx({ config, targetSide, onImpact, onComplete, travelMs, impactMs }) {
  const ref = useRef(null);
  const doneRef = useRef(false);
  const impactRef = useRef(false);
  const sig = config.signature;

  useEffect(() => {
    doneRef.current = false;
    impactRef.current = false;
    const el = ref.current;
    if (!el) {
      onComplete();
      return undefined;
    }
    const toLeft = targetSide === 'left';
    const startX = toLeft ? FAR_EDGE : NEAR_EDGE;
    const endX = toLeft ? NEAR_EDGE : FAR_EDGE;
    const total = travelMs + impactMs;
    const travelEnd = travelMs / total;
    let raf = 0;
    let startTs = null;
    let active = true;

    const tick = (ts) => {
      if (!active) return;
      if (startTs == null) startTs = ts;
      const t = Math.min(1, (ts - startTs) / total);
      let x;
      let scale;
      let opacity;
      if (t < travelEnd) {
        const tt = t / travelEnd;
        x = startX + (endX - startX) * tt;
        scale = 0.7 + 0.35 * tt;
        opacity = Math.min(1, tt * 5);
      } else {
        const tt = (t - travelEnd) / (1 - travelEnd);
        x = endX;
        scale = 1.1 + 0.4 * Math.sin(Math.min(1, tt) * Math.PI);
        opacity = 1 - Math.max(0, (tt - 0.45) / 0.55);
      }
      el.style.left = `${x}%`;
      el.style.opacity = String(opacity);
      el.style.transform = `translate(-50%, -50%) scale(${scale}, ${scale})`;
      if (t >= travelEnd && !impactRef.current) {
        impactRef.current = true;
        onImpact?.();
      }
      if (!active) return;
      if (t >= 1) {
        if (!doneRef.current) {
          doneRef.current = true;
          onComplete();
        }
        return;
      }
      raf = requestAnimationFrame(tick);
    };

    raf = requestAnimationFrame(tick);
    return () => { active = false; cancelAnimationFrame(raf); };
  }, [config, targetSide, onImpact, onComplete, travelMs, impactMs]);

  const [hi, mid, deep] = sig.palette;
  return (
    <div
      ref={ref}
      className={`vfx-strip vfx-signature vfx-signature-${sig.motion}`}
      role="presentation"
      aria-label={sig.label}
      title={sig.label}
      style={{
        background: `radial-gradient(circle, ${hi} 0%, ${mid} 55%, transparent 78%)`,
        boxShadow: `0 0 28px ${mid}, 0 0 64px ${deep}`,
        width: `${STRIP_DISPLAY}px`,
        height: `${STRIP_DISPLAY}px`,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        fontSize: '72px',
        color: hi,
        textShadow: `0 0 12px ${mid}, 0 2px 0 ${deep}`,
      }}
    >
      {SIGNATURE_GLYPHS[sig.motif] || '✦'}
    </div>
  );
}

// === CSS-only fallback (basic attack slash / undefined projectiles) ===
function LegacyVfx({ vfxKey, element, direction, onImpact, onComplete, targetSide, travelMs, impactMs }) {
  const [phase, setPhase] = useState('travel');
  const impactRef = useRef(false);
  const doneRef = useRef(false);
  const activeRef = useRef(true);
  const isLTR = direction === 'left-to-right';
  const colors = elementColors[element] || elementColors.neutral;

  useEffect(() => {
    impactRef.current = false;
    doneRef.current = false;
    activeRef.current = true;
    setPhase('travel');
    return () => { activeRef.current = false; };
  }, [vfxKey, element, direction, targetSide, onImpact, onComplete, travelMs, impactMs]);

  const handleImpactEnd = useCallback(function handleImpactEnd() {
    if (!activeRef.current || doneRef.current) return;
    doneRef.current = true;
    onComplete();
  }, [onComplete]);

  const handleTravelEnd = useCallback(function handleTravelEnd() {
    if (!activeRef.current || impactRef.current) return;
    impactRef.current = true;
    onImpact?.();
    if (vfxKey === 'BASIC_ATTACK') {
      setPhase('impact');
    } else {
      handleImpactEnd();
    }
  }, [vfxKey, onImpact, handleImpactEnd]);

  return (
    <>
      {phase === 'travel' && (
        <div
          className={`vfx-travel ${isLTR ? 'vfx-travel-ltr' : 'vfx-travel-rtl'}`}
          style={{
            background: `radial-gradient(ellipse, ${colors.glow}, ${colors.primary} 60%, transparent 80%)`,
            boxShadow: `${isLTR ? '-20px' : '20px'} 0 20px ${colors.primary}`,
            animationDuration: `${travelMs}ms`,
          }}
          onAnimationEnd={handleTravelEnd}
        />
      )}

      {phase === 'impact' && vfxKey === 'BASIC_ATTACK' && (
        <div
          className="vfx-basic-slash vfx-basic-slash-anim"
          style={{ left: targetSide === 'left' ? '15%' : '85%', animationDuration: `${impactMs}ms` }}
          onAnimationEnd={handleImpactEnd}
        />
      )}
    </>
  );
}
