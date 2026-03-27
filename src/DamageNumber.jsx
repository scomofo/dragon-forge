import { useEffect, useState } from 'react';

export default function DamageNumber({ damage, effectiveness, hit, position, onComplete }) {
  const [visible, setVisible] = useState(true);

  useEffect(() => {
    const timer = setTimeout(() => {
      setVisible(false);
      onComplete?.();
    }, 800);
    return () => clearTimeout(timer);
  }, [onComplete]);

  if (!visible) return null;

  let className = 'damage-number normal';
  let text = String(damage);

  if (!hit) {
    className = 'damage-number miss';
    text = 'MISS';
  } else if (effectiveness > 1.0) {
    className = 'damage-number super-effective';
    text = `${damage}`;
  } else if (effectiveness < 1.0) {
    className = 'damage-number resisted';
    text = `${damage}`;
  }

  return (
    <div
      className={className}
      style={{
        left: `${position.x}px`,
        top: `${position.y}px`,
      }}
    >
      {text}
    </div>
  );
}
