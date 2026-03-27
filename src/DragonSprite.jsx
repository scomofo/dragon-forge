import { useState, useEffect, useRef } from 'react';
import { DRAGON_SHEET, STAGE_SCALES, DRAGON_DISPLAY } from './sprites';

export default function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '' }) {
  const [frame, setFrame] = useState(0);
  const intervalRef = useRef(null);

  useEffect(() => {
    if (forcedFrame !== null) {
      setFrame(forcedFrame);
      return;
    }

    intervalRef.current = setInterval(() => {
      setFrame((prev) => (prev + 1) % DRAGON_SHEET.totalFrames);
    }, DRAGON_SHEET.frameDuration);

    return () => clearInterval(intervalRef.current);
  }, [forcedFrame]);

  const col = frame % DRAGON_SHEET.cols;
  const row = Math.floor(frame / DRAGON_SHEET.cols);
  const bgX = -(col * DRAGON_SHEET.frameWidth);
  const bgY = -(row * DRAGON_SHEET.frameHeight);

  const scale = STAGE_SCALES[stage] ?? 1.0;
  const width = DRAGON_DISPLAY.width * scale;
  const height = DRAGON_DISPLAY.height * scale;

  const style = {
    width: `${width}px`,
    height: `${height}px`,
    backgroundImage: `url(${spriteSheet})`,
    backgroundPosition: `${bgX * (width / DRAGON_SHEET.frameWidth)}px ${bgY * (height / DRAGON_SHEET.frameHeight)}px`,
    backgroundSize: `${DRAGON_SHEET.cols * width}px ${DRAGON_SHEET.rows * height}px`,
    imageRendering: 'pixelated',
    transform: flipX ? 'scaleX(-1)' : 'none',
    filter: stage === 4 ? 'drop-shadow(0 0 8px gold)' : 'none',
  };

  return <div className={`dragon-sprite ${className}`} style={style} />;
}
