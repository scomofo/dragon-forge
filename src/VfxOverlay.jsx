import { useState, useEffect, useRef, useCallback } from 'react';
import { elementColors } from './gameData';
import { VFX_FRAMES } from './sprites';

// Strip playback timing. Travel = projectile flying across the arena (frames
// 0..n-2), impact = the burst frame held on the target (frame n-1).
const TRAVEL_MS = 330;
const IMPACT_MS = 220;
const STRIP_DISPLAY = 200; // px the projectile renders at on screen

// Arena anchor positions (% of the .arena-sprites width). targetSide is the
// side that takes the hit, so the projectile starts on the opposite side.
const NEAR_EDGE = 18;
const FAR_EDGE = 78;

export default function VfxOverlay({ vfxKey, element, direction, onComplete, targetSide }) {
  const config = VFX_FRAMES[vfxKey];

  if (config?.strip) {
    return <StripVfx config={config} targetSide={targetSide} onComplete={onComplete} />;
  }
  return (
    <LegacyVfx
      vfxKey={vfxKey}
      element={element}
      direction={direction}
      targetSide={targetSide}
      onComplete={onComplete}
    />
  );
}

// === Animated projectile strip ===
function StripVfx({ config, targetSide, onComplete }) {
  const ref = useRef(null);
  const doneRef = useRef(false);

  useEffect(() => {
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
    const total = TRAVEL_MS + IMPACT_MS;
    const travelEnd = TRAVEL_MS / total;

    let raf = 0;
    let startTs = null;

    const tick = (ts) => {
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
    return () => cancelAnimationFrame(raf);
  }, [config, targetSide, onComplete]);

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

// === CSS-only fallback (basic attack slash / undefined projectiles) ===
function LegacyVfx({ vfxKey, element, direction, onComplete, targetSide }) {
  const [phase, setPhase] = useState('travel');
  const isLTR = direction === 'left-to-right';
  const colors = elementColors[element] || elementColors.neutral;

  const handleTravelEnd = useCallback(() => {
    if (vfxKey === 'BASIC_ATTACK') {
      setPhase('impact');
    } else {
      onComplete();
    }
  }, [vfxKey, onComplete]);

  return (
    <>
      {phase === 'travel' && (
        <div
          className={`vfx-travel ${isLTR ? 'vfx-travel-ltr' : 'vfx-travel-rtl'}`}
          style={{
            background: `radial-gradient(ellipse, ${colors.glow}, ${colors.primary} 60%, transparent 80%)`,
            boxShadow: `${isLTR ? '-20px' : '20px'} 0 20px ${colors.primary}`,
          }}
          onAnimationEnd={handleTravelEnd}
        />
      )}

      {phase === 'impact' && vfxKey === 'BASIC_ATTACK' && (
        <div
          className="vfx-basic-slash vfx-basic-slash-anim"
          style={{ left: targetSide === 'left' ? '15%' : '85%' }}
          onAnimationEnd={onComplete}
        />
      )}
    </>
  );
}
