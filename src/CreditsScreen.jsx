import { useEffect, useState } from 'react';
import { MIRROR_ADMIN_EPILOGUE_LINES } from './singularityBosses';
import { playSound } from './soundEngine';

export default function CreditsScreen({ onNavigate }) {
  const [visibleLines, setVisibleLines] = useState(0);

  useEffect(() => {
    if (visibleLines < MIRROR_ADMIN_EPILOGUE_LINES.length) {
      const t = setTimeout(() => setVisibleLines(n => n + 1), 1400);
      return () => clearTimeout(t);
    }
  }, [visibleLines]);

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(180deg, #020008 0%, #0a0015 50%, #020008 100%)',
      display: 'flex',
      flexDirection: 'column',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '40px 24px',
      color: '#e8d5ff',
      fontFamily: 'inherit',
    }}>
      <div style={{ maxWidth: 520, textAlign: 'center' }}>
        <div style={{ fontSize: 10, letterSpacing: 5, color: '#9966cc', marginBottom: 40, textTransform: 'uppercase' }}>
          Simulation Status: Restored
        </div>
        {MIRROR_ADMIN_EPILOGUE_LINES.map((line, i) => (
          <p key={i} style={{
            opacity: i < visibleLines ? 1 : 0,
            transform: i < visibleLines ? 'translateY(0)' : 'translateY(10px)',
            transition: 'opacity 0.9s ease, transform 0.9s ease',
            fontSize: i === MIRROR_ADMIN_EPILOGUE_LINES.length - 1 ? 16 : 13,
            fontStyle: i < MIRROR_ADMIN_EPILOGUE_LINES.length - 1 ? 'italic' : 'normal',
            fontWeight: i === MIRROR_ADMIN_EPILOGUE_LINES.length - 1 ? 'bold' : 'normal',
            color: i === MIRROR_ADMIN_EPILOGUE_LINES.length - 1 ? '#ffffff' : '#c8a8e0',
            lineHeight: 1.8,
            marginBottom: 14,
          }}>
            {line}
          </p>
        ))}
        {visibleLines >= MIRROR_ADMIN_EPILOGUE_LINES.length && (
          <button
            onClick={() => { playSound('buttonClick'); onNavigate('hatchery'); }}
            style={{
              marginTop: 48,
              padding: '12px 36px',
              background: 'transparent',
              border: '1px solid #9966cc',
              color: '#e8d5ff',
              fontSize: 11,
              letterSpacing: 4,
              cursor: 'pointer',
              textTransform: 'uppercase',
              transition: 'background 0.2s, border-color 0.2s',
              animation: 'fadeIn 0.8s ease',
            }}
            onMouseEnter={e => { e.currentTarget.style.background = 'rgba(153,102,204,0.15)'; e.currentTarget.style.borderColor = '#cc88ff'; }}
            onMouseLeave={e => { e.currentTarget.style.background = 'transparent'; e.currentTarget.style.borderColor = '#9966cc'; }}
          >
            Return to the Forge
          </button>
        )}
      </div>
    </div>
  );
}
