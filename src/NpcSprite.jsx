export default function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '', size = 160 }) {
  const src = isAttacking ? attackSprite : idleSprite;

  return (
    <img
      className={`npc-sprite pixelated ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: 'pixelated',
        height: `${size}px`,
        objectFit: 'contain',
      }}
    />
  );
}
