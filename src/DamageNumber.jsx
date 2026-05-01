import { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';

export default function DamageNumber({ damage, effectiveness, hit, position, onComplete, isCritical = false, isStatusTick = false, statusElement = null, staggerIndex = 0, variant = null, label = null }) {
  const [visible, setVisible] = useState(true);
  const ref = useRef(null);

  const duration = isCritical ? 1000 : isStatusTick ? 600 : hit ? 800 : 600;

  useEffect(() => {
    const el = ref.current;
    if (!el) return;
    // NES-style pop: snap big, settle, hold, then arc up + fade
    const isMarker = variant === 'status' || variant === 'reflect';
    const popScale = isCritical ? 1.8 : isMarker ? 1.45 : isStatusTick ? 1.0 : effectiveness > 1.0 ? 1.5 : hit ? 1.3 : 1.1;
    const arcY = isCritical ? -54 : isMarker ? -36 : isStatusTick ? -28 : hit ? -42 : -32;
    const tl = gsap.timeline({
      onComplete: () => {
        setVisible(false);
        onComplete?.();
      },
    });
    tl.fromTo(el,
      { scale: 0.3, opacity: 0, y: 6 },
      { scale: popScale, opacity: 1, y: 0, duration: 0.09, ease: 'back.out(3)' }
    );
    tl.to(el, { scale: 1, duration: 0.08, ease: 'power2.out' });
    if (isCritical) {
      tl.to(el, { x: '+=4', duration: 0.04, repeat: 5, yoyo: true, ease: 'none' }, '<');
    }
    tl.to(el, { duration: 0.12 });
    tl.to(el, { y: arcY, opacity: 0, duration: (duration / 1000) - 0.29, ease: 'power1.out' });
    return () => tl.kill();
  }, [onComplete, duration, isCritical, isStatusTick, effectiveness, hit, variant]);

  if (!visible) return null;

  let className = 'damage-number normal';
  let text = String(damage);

  if (variant === 'status') {
    className = 'damage-number status-apply';
    text = label || 'STATUS';
  } else if (variant === 'reflect') {
    className = 'damage-number reflect';
    text = label || `${damage}`;
  } else if (variant === 'ko') {
    className = 'damage-number ko';
    text = `${damage}`;
  } else if (isStatusTick) {
    className = 'damage-number status-tick';
    text = String(damage);
  } else if (!hit) {
    className = 'damage-number miss';
    text = 'MISS';
  } else if (isCritical) {
    className = 'damage-number critical';
    text = `CRIT ${damage}`;
  } else if (effectiveness > 1.0) {
    className = 'damage-number super-effective';
    text = `${damage}`;
  } else if (effectiveness < 1.0) {
    className = 'damage-number resisted';
    text = `${damage}`;
  }

  const xOffset = staggerIndex * 15 * (staggerIndex % 2 === 0 ? 1 : -1);

  const statusColor = isStatusTick && statusElement
    ? { fire: '#ff6622', ice: '#88ccff', storm: '#aa66ff', stone: '#aa8844', venom: '#44cc44', shadow: '#8844aa' }[statusElement]
    : undefined;

  return (
    <div
      ref={ref}
      className={className}
      style={{
        left: `${position.x + xOffset}px`,
        top: `${position.y}px`,
        animation: 'none',
        opacity: 0,
        ...(statusColor ? { color: statusColor } : {}),
      }}
    >
      {text}
    </div>
  );
}
