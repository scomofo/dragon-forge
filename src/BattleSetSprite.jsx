// P1 sheet-strip player. Renders one horizontal battle-set strip
// (`<actorId>_<pose>.webp`, `frames` cells of `cell`×`cell`) onto a canvas at
// integer scale. Faint plays once and holds the last cell; every other pose
// loops. Mounted only for actors whose set status is `shipped` — everyone
// else keeps their painted portrait until their sheets land.
import { forwardRef, useEffect, useRef, useState } from 'react';
import { POSE_FRAME_DURATIONS, normalizeBattlePose } from './battleSets';

const INTEGER_SCALE = 2;

const BattleSetSprite = forwardRef(function BattleSetSprite({
  src,
  cell = 96,
  frames = 4,
  pose = 'idle',
  flipX = false,
  width = null,
  height = null,
  className = '',
  style = {},
}, ref) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);
  const [frame, setFrame] = useState(0);
  const [loaded, setLoaded] = useState(false);
  const [missing, setMissing] = useState(false);
  const normalized = normalizeBattlePose(pose);
  const count = Math.max(1, frames);

  useEffect(() => {
    setFrame(0);
    setLoaded(false);
    setMissing(false);
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      imageRef.current = img;
      setLoaded(true);
    };
    img.onerror = () => {
      setMissing(true);
    };
    img.src = src;
    return () => {
      imageRef.current = null;
    };
  }, [src]);

  useEffect(() => {
    if (!loaded || missing) return undefined;
    if (normalized === 'faint' && frame >= count - 1) return undefined;
    const duration = POSE_FRAME_DURATIONS[normalized] || 140;
    const timer = setTimeout(() => {
      setFrame((prev) => {
        if (normalized === 'faint') return Math.min(prev + 1, count - 1);
        return (prev + 1) % count;
      });
    }, duration);
    return () => clearTimeout(timer);
  }, [loaded, missing, frame, count, normalized]);

  useEffect(() => {
    const canvas = canvasRef.current;
    const img = imageRef.current;
    if (!canvas || !img || !loaded || missing) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.imageSmoothingEnabled = false;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
    ctx.save();
    if (flipX) {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(img, frame * cell, 0, cell, cell, 0, 0, canvas.width, canvas.height);
    ctx.restore();
  }, [loaded, missing, frame, cell, flipX]);

  // Internal ref drives frame drawing; a parent ref (animation targets) is
  // merged onto the same canvas node.
  const setCanvasRefs = (node) => {
    canvasRef.current = node;
    if (!ref) return;
    if (typeof ref === 'function') ref(node);
    else ref.current = node;
  };

  if (missing) return null;

  const px = cell * INTEGER_SCALE;
  return (
    <canvas
      ref={setCanvasRefs}
      width={px}
      height={px}
      className={`battle-set-sprite battle-set-${normalized} ${className}`}
      data-actor-pose={normalized}
      style={{
        imageRendering: 'pixelated',
        width: width ? `${width}px` : `${px}px`,
        height: height ? `${height}px` : `${px}px`,
        ...style,
      }}
    />
  );
});

export default BattleSetSprite;
