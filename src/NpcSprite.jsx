import { forwardRef } from 'react';

const NpcSprite = forwardRef(function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '', size = 160, flipX = false, style = {} }, ref) {
  const src = isAttacking ? attackSprite : idleSprite;

  return (
    <img
      ref={ref}
      className={`npc-sprite pixelated ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: 'pixelated',
        height: `${size}px`,
        objectFit: 'contain',
        transform: flipX ? 'scaleX(-1)' : 'none',
        ...style,
      }}
    />
  );
});

export default NpcSprite;
