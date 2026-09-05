import { forwardRef } from 'react';
import BattleSetSprite from './BattleSetSprite';
import { normalizeBattlePose, resolveBattleSprite } from './battleSets';

const NpcSprite = forwardRef(function NpcSprite({ idleSprite, attackSprite, isAttacking = false, className = '', size = 160, flipX = false, smooth = false, style = {}, actorId = null, pose = null, battlePlayback = false }, ref) {
  // P1 battle-set pipeline: explicit pose wins; otherwise the legacy
  // idle/attack swap decides. Shipped sheets take over the <img> stills.
  const effectivePose = pose || (isAttacking ? 'attack' : 'idle');
  const battleSprite = actorId ? resolveBattleSprite(actorId, effectivePose) : { kind: 'portrait' };

  if (battleSprite.kind === 'sheet') {
    return (
      <BattleSetSprite
        ref={ref}
        src={battleSprite.src}
        cell={battleSprite.cell}
        frames={battleSprite.frames}
        pose={battleSprite.pose}
        flipX={flipX}
        battlePlayback={battlePlayback}
        width={size}
        height={size}
        className={`npc-sprite ${className}`}
        style={style}
      />
    );
  }

  const src = isAttacking ? attackSprite : idleSprite;

  // Pixel-art NPCs render crisp (pixelated); bespoke illustration bosses render
  // smoothly so they don't look jagged when scaled.
  return (
    <img
      ref={ref}
      className={`npc-sprite ${smooth ? '' : 'pixelated'} ${className}`}
      src={src}
      alt="NPC"
      data-battle-pose={normalizeBattlePose(effectivePose)}
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
