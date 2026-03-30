import { useState, useEffect, useRef, useCallback, forwardRef, useImperativeHandle } from 'react';
import { DRAGON_SHEET, STAGE_SCALES, DRAGON_DISPLAY } from './sprites';

const DragonSprite = forwardRef(function DragonSprite({ spriteSheet, stage = 3, flipX = false, forcedFrame = null, className = '', size = null, shiny = false, element = '' }, ref) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);
  const [frame, setFrame] = useState(0);
  const [imageLoaded, setImageLoaded] = useState(false);

  useImperativeHandle(ref, () => ({
    getCanvas: () => canvasRef.current,
  }));

  const actualFramesRef = useRef(DRAGON_SHEET.totalFrames);

  // Load sprite sheet image
  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      imageRef.current = img;
      // Detect actual frame count from image dimensions
      const cols = Math.floor(img.width / DRAGON_SHEET.frameWidth);
      const rows = Math.floor(img.height / DRAGON_SHEET.frameHeight);
      actualFramesRef.current = Math.min(DRAGON_SHEET.totalFrames, cols * rows);
      setImageLoaded(true);
    };
    img.src = spriteSheet;
  }, [spriteSheet]);

  // Animate frames
  useEffect(() => {
    if (forcedFrame !== null) {
      const clamped = Math.min(forcedFrame, actualFramesRef.current - 1);
      setFrame(clamped);
      return;
    }

    const interval = setInterval(() => {
      setFrame((prev) => (prev + 1) % actualFramesRef.current);
    }, DRAGON_SHEET.frameDuration);

    return () => clearInterval(interval);
  }, [forcedFrame]);

  // Draw frame to canvas with chroma key
  const drawFrame = useCallback(() => {
    const canvas = canvasRef.current;
    const img = imageRef.current;
    if (!canvas || !img) return;

    const ctx = canvas.getContext('2d');
    const col = frame % DRAGON_SHEET.cols;
    const row = Math.floor(frame / DRAGON_SHEET.cols);
    const sx = col * DRAGON_SHEET.frameWidth;
    const sy = row * DRAGON_SHEET.frameHeight;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Draw the frame
    ctx.save();
    if (flipX) {
      ctx.translate(canvas.width, 0);
      ctx.scale(-1, 1);
    }
    ctx.drawImage(
      img,
      sx, sy, DRAGON_SHEET.frameWidth, DRAGON_SHEET.frameHeight,
      0, 0, canvas.width, canvas.height
    );
    ctx.restore();

    // Remove green background (chroma key)
    const imageData = ctx.getImageData(0, 0, canvas.width, canvas.height);
    const data = imageData.data;
    for (let i = 0; i < data.length; i += 4) {
      const r = data[i];
      const g = data[i + 1];
      const b = data[i + 2];
      // Detect green screen pixels: high green, low red and blue
      if (g > 150 && r < 150 && b < 150 && g > r * 1.3 && g > b * 1.3) {
        data[i + 3] = 0; // Set alpha to 0
      }
    }
    ctx.putImageData(imageData, 0, 0);
  }, [frame, flipX]);

  useEffect(() => {
    if (imageLoaded) {
      drawFrame();
    }
  }, [imageLoaded, drawFrame]);

  const scale = STAGE_SCALES[stage] ?? 1.0;
  const baseW = size ? size.width : DRAGON_DISPLAY.width;
  const baseH = size ? size.height : DRAGON_DISPLAY.height;
  const width = Math.round(baseW * scale);
  const height = Math.round(baseH * scale);

  const shinyFilter = shiny
    ? 'drop-shadow(0 0 6px gold) drop-shadow(0 0 12px rgba(255,215,0,0.4))'
    : (stage === 4 ? 'drop-shadow(0 0 8px gold)' : 'none');

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      className={`dragon-sprite ${className} ${shiny ? 'shiny-sprite' : ''} ${element === 'void' ? 'void-sprite' : ''}`}
      style={{
        imageRendering: 'pixelated',
        filter: shinyFilter,
        width: `${width}px`,
        height: `${height}px`,
      }}
    />
  );
});

export default DragonSprite;
