export default function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '' }) {
  const src = isAttacking ? attackSprite : idleSprite;

  return (
    <img
      className={`npc-sprite pixelated ${className}`}
      src={src}
      alt="NPC"
      style={{
        imageRendering: 'pixelated',
        height: '160px',
        objectFit: 'contain',
      }}
    />
  );
}
