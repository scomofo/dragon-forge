import { forwardRef } from 'react';

const NpcSprite = forwardRef(function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '', size = 160, flipX = false, smooth = false, style = {} }, ref) {
  const src = isAttacking ? attackSprite : idleSprite;

  // Pixel-art NPCs render crisp (pixelated); bespoke illustration bosses render
  // smoothly so they don't look jagged when scaled.
  return (
    <img
      ref={ref}
      className={`npc-sprite ${smooth ? '' : 'pixelated'} ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: smooth ? 'auto' : 'pixelated',
        height: `${size}px`,
        objectFit: 'contain',
        transform: flipX ? 'scaleX(-1)' : 'none',
        ...style,
      }}
    />
  );
});

export default NpcSprite;
