import { useState, useEffect } from 'react';

const INTRO_LINES = [
  '> EMERGENCY BROADCAST FROM DR. FELIX',
  '> The Elemental Matrix is destabilizing...',
  '> We need Dragon Forgers. We need YOU.',
];

export default function TitleScreen({ onStart }) {
  const [visibleLines, setVisibleLines] = useState(0);
  const [showButton, setShowButton] = useState(false);

  useEffect(() => {
    if (visibleLines < INTRO_LINES.length) {
      const timer = setTimeout(() => setVisibleLines((v) => v + 1), 1200);
      return () => clearTimeout(timer);
    } else {
      const timer = setTimeout(() => setShowButton(true), 600);
      return () => clearTimeout(timer);
    }
  }, [visibleLines]);

  return (
    <div className="title-screen">
      <div className="felix-frame" style={{ width: 160, height: 160, overflow: 'hidden', marginBottom: 16, borderRadius: 4 }}>
        <img
          src="/assets/felix_pixel.jpg"
          alt="Professor Felix"
          className="pixelated"
          style={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
        />
      </div>

      <h1>DRAGON FORGE</h1>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 8, minHeight: 80, alignItems: 'center' }}>
        {INTRO_LINES.slice(0, visibleLines).map((line, i) => (
          <p key={i} style={{ color: '#44ff44', fontSize: 9 }}>{line}</p>
        ))}
      </div>

      {showButton && (
        <button className="enter-btn" onClick={onStart}>
          ENTER THE FORGE
        </button>
      )}
    </div>
  );
}
