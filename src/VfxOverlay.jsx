import { useState, useCallback } from 'react';
import { elementColors } from './gameData';
import { VFX_FRAMES } from './sprites';

export default function VfxOverlay({ vfxKey, element, direction, onComplete }) {
  const [phase, setPhase] = useState('travel'); // 'travel' | 'impact' | 'done'
  const isLTR = direction === 'left-to-right';
  const colors = elementColors[element] || elementColors.neutral;

  const handleTravelEnd = useCallback(() => {
    const frameConfig = VFX_FRAMES[vfxKey];
    if (frameConfig || vfxKey === 'BASIC_ATTACK') {
      setPhase('impact');
    } else {
      // No impact frame defined, finish immediately
      onComplete();
    }
  }, [vfxKey, onComplete]);

  const handleImpactEnd = useCallback(() => {
    onComplete();
  }, [onComplete]);

  if (phase === 'done') return null;

  return (
    <>
      {/* Travel streak */}
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

      {/* Impact frame — concept art or basic slash */}
      {phase === 'impact' && vfxKey === 'BASIC_ATTACK' && (
        <div
          className="vfx-basic-slash vfx-basic-slash-anim"
          onAnimationEnd={handleImpactEnd}
        />
      )}

      {phase === 'impact' && vfxKey !== 'BASIC_ATTACK' && VFX_FRAMES[vfxKey] && (
        <ImpactFrame config={VFX_FRAMES[vfxKey]} onAnimationEnd={handleImpactEnd} />
      )}
    </>
  );
}

function ImpactFrame({ config, onAnimationEnd }) {
  const { src, crop, filter } = config;

  // Calculate background-size and background-position to show only the crop region.
  // We want the crop region to fill a 200x200 display area.
  const displaySize = 200;
  const scaleX = displaySize / crop.w;
  const scaleY = displaySize / crop.h;
  const scale = Math.min(scaleX, scaleY);

  // Known sheet sizes for background-size calculation
  const sheetSizes = {
    '/assets/vfx/fire_effects.png': { w: 1024, h: 1024 },
    '/assets/vfx/stone_explosion.png': { w: 1536, h: 1024 },
    '/assets/vfx/storm_lightning.png': { w: 1536, h: 1024 },
    '/assets/vfx/ice_crystals.png': { w: 1024, h: 1536 },
    '/assets/vfx/venom_cloud.png': { w: 1536, h: 1024 },
    '/assets/vfx/shadow_flames.png': { w: 1536, h: 1024 },
    '/assets/vfx/stone_meteor.png': { w: 1024, h: 1536 },
    '/assets/vfx/venom_splash.png': { w: 1536, h: 1024 },
  };

  const sheet = sheetSizes[src] || { w: 1024, h: 1024 };
  const bgW = sheet.w * scale;
  const bgH = sheet.h * scale;
  const bgX = -(crop.x * scale);
  const bgY = -(crop.y * scale);

  return (
    <div
      className="vfx-impact vfx-impact-flash"
      style={{
        backgroundImage: `url(${src})`,
        backgroundSize: `${bgW}px ${bgH}px`,
        backgroundPosition: `${bgX}px ${bgY}px`,
        filter: filter || 'none',
      }}
      onAnimationEnd={onAnimationEnd}
    />
  );
}
