import { useEffect, useState } from 'react';

export default function DamageNumber({ damage, effectiveness, hit, position, onComplete, isCritical = false, isStatusTick = false, statusElement = null, staggerIndex = 0 }) {
  const [visible, setVisible] = useState(true);

  const duration = isCritical ? 1000 : isStatusTick ? 600 : hit ? 800 : 600;

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      onComplete?.();
    }, duration);
    return () => clearTimeout(timer);
  }, [onComplete, duration]);

  if (!visible) return null;

  let className = 'damage-number normal';
  let text = String(damage);

  if (isStatusTick) {
    className = 'damage-number status-tick';
    text = String(damage);
  } else if (!hit) {
    className = 'damage-number miss';
    text = 'MISS';
  } else if (isCritical) {
    className = 'damage-number critical';
    text = `${damage}`;
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
      className={className}
      style={{
        left: `${position.x + xOffset}px`,
        top: `${position.y}px`,
        ...(statusColor ? { color: statusColor } : {}),
      }}
    >
      {text}
    </div>
  );
}
