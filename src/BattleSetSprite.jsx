// P1 sheet-strip player. Renders one horizontal battle-set strip
// (`<actorId>_<pose>.webp`, `frames` cells of `cell`×`cell`) onto a canvas with
// a 2x backing raster, fitted proportionally to its slot. Faint plays once
// and holds the last cell; every other pose
// loops. Mounted only for actors whose set status is `shipped` — everyone
// else keeps their painted portrait until their sheets land.
import { forwardRef, useEffect, useRef } from 'react';
import { normalizeBattlePose } from './battleSets';
import { getBattleSpriteSize, startBattleSpritePlayback } from './battleSpritePlayback';

const INTEGER_SCALE = 2;

const BattleSetSprite = forwardRef(function BattleSetSprite({
  src,
  cell = 96,
  frames = 4,
  pose = 'idle',
  flipX = false,
  battlePlayback = false,
  width = null,
  height = null,
  className = '',
  style = {},
}, ref) {
  const canvasRef = useRef(null);
  const normalized = normalizeBattlePose(pose);

  useEffect(() => startBattleSpritePlayback({
    canvas: canvasRef.current, src, cell, frames, pose: normalized, flipX, battlePlayback,
  }), [src, cell, frames, normalized, flipX, battlePlayback]);

  // Internal ref drives frame drawing; a parent ref (animation targets) is
  // merged onto the same canvas node.
  const setCanvasRefs = (node) => {
    canvasRef.current = node;
    if (!ref) return;
    if (typeof ref === 'function') ref(node);
    else ref.current = node;
  };

  const px = cell * INTEGER_SCALE;
  const displaySize = getBattleSpriteSize(cell, width, height);
  return (
    <canvas
      ref={setCanvasRefs}
      width={px}
      height={px}
      className={`battle-set-sprite battle-set-${normalized} ${className}`}
      data-actor-pose={normalized}
      style={{
        ...style,
        imageRendering: 'pixelated',
        width: `${displaySize}px`,
        height: `${displaySize}px`,
      }}
    />
  );
});

export default BattleSetSprite;
