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
  const actualColsRef = useRef(DRAGON_SHEET.cols);
  const frameOffsetsRef = useRef([]);
  const frameStartRef = useRef(0);
  const unstableSheetRef = useRef(false);

  // Every dragon is now authored as a single detailed pose (per-stage), not a
  // 3×4 animation sheet — the frame tiler would slice the one dragon into
  // fragments (renders as a blank/garbled box). Draw the whole image instead.
  const singleFrame = /\/dragons\/[a-z]+_stage[1-4]\.png/.test(String(spriteSheet));

  // Load sprite sheet image
  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      imageRef.current = img;
      if (singleFrame) {
        actualColsRef.current = 1;
        frameStartRef.current = 0;
        actualFramesRef.current = 1;
        frameOffsetsRef.current = [0];
        unstableSheetRef.current = false;
        setImageLoaded(true);
        return;
      }
      // Detect actual frame count from image dimensions
      const cols = Math.floor(img.width / DRAGON_SHEET.frameWidth);
      const rows = Math.floor(img.height / DRAGON_SHEET.frameHeight);
      actualColsRef.current = Math.max(1, cols);
      const maxFrames = Math.min(DRAGON_SHEET.totalFrames, cols * rows);
      const frameMetrics = getFrameMetrics(img, maxFrames, actualColsRef.current);
      const stableRange = getStableIdleFrameRange(frameMetrics);
      frameStartRef.current = stableRange.start;
      actualFramesRef.current = stableRange.count;
      frameOffsetsRef.current = getFrameBaselineOffsets(frameMetrics, stableRange);
      unstableSheetRef.current = stableRange.count < maxFrames || frameOffsetsRef.current.some((offset) => offset > 0);
      setImageLoaded(true);
    };
    img.src = spriteSheet;
  }, [spriteSheet]);

  // Animate frames
  useEffect(() => {
    if (singleFrame) {
      setFrame(0);
      return;
    }
    if (forcedFrame !== null) {
      const clamped = Math.min(forcedFrame, actualFramesRef.current - 1);
      setFrame(clamped);
      return;
    }

    const interval = setInterval(() => {
      setFrame((prev) => (prev + 1) % actualFramesRef.current);
    }, DRAGON_SHEET.frameDuration);

    return () => clearInterval(interval);
  }, [forcedFrame, singleFrame]);

  // Draw frame to canvas with chroma key
  const drawFrame = useCallback(() => {
    const canvas = canvasRef.current;
    const img = imageRef.current;
    if (!canvas || !img) return;

    const ctx = canvas.getContext('2d');

    if (singleFrame) {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      ctx.save();
      if (flipX) {
        ctx.translate(canvas.width, 0);
        ctx.scale(-1, 1);
      }
      ctx.drawImage(img, 0, 0, img.width, img.height, 0, 0, canvas.width, canvas.height);
      ctx.restore();
      // Green chroma-key (no-op when the sprite already has baked transparency).
      const single = ctx.getImageData(0, 0, canvas.width, canvas.height);
      const sd = single.data;
      for (let i = 0; i < sd.length; i += 4) {
        if (sd[i + 1] > 150 && sd[i] < 150 && sd[i + 2] < 150 && sd[i + 1] > sd[i] * 1.3 && sd[i + 1] > sd[i + 2] * 1.3) {
          sd[i + 3] = 0;
        }
      }
      ctx.putImageData(single, 0, 0);
      return;
    }

    const sourceFrame = frameStartRef.current + frame;
    const col = sourceFrame % actualColsRef.current;
    const row = Math.floor(sourceFrame / actualColsRef.current);
    const sx = col * DRAGON_SHEET.frameWidth;
    const sy = row * DRAGON_SHEET.frameHeight;
    const baselineOffset = frameOffsetsRef.current[frame] || 0;
    const horizontalInset = unstableSheetRef.current ? Math.round(canvas.width * 0.04) : 0;
    const verticalInset = unstableSheetRef.current ? Math.round(canvas.height * 0.04) : 0;
    const drawWidth = canvas.width - horizontalInset * 2;
    const drawHeight = canvas.height - verticalInset * 2;
    const drawOffsetY = verticalInset + Math.round(baselineOffset * (drawHeight / DRAGON_SHEET.frameHeight));

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
      horizontalInset, drawOffsetY, drawWidth, drawHeight
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
  }, [frame, flipX, singleFrame]);

  useEffect(() => {
    if (imageLoaded) {
      drawFrame();
    }
  }, [imageLoaded, drawFrame]);

  const scale = STAGE_SCALES[stage] ?? 1.0;
  const baseW = size ? size.width : DRAGON_DISPLAY.width;
  const baseH = size ? size.height : DRAGON_DISPLAY.height;
  let width = Math.round(baseW * scale);
  let height = Math.round(baseH * scale * (unstableSheetRef.current ? 1.16 : 1));
  // An explicit `size` is a fixed UI slot (the roster/fusion/hatchery cards wrap
  // the sprite in an overflow:hidden box). The stage-4 scale (1.4×) pushes the
  // canvas past that slot, so the box center-crops the dragon — wings, head and
  // tail get clipped. Endgame dragons (void/light/synthesis) sit at stage 4, so
  // they're the ones that crop while lower-stage base dragons fit. Cap the canvas
  // to the slot so high stages fit; lower stages already render smaller than it.
  if (size) {
    const fit = Math.min(1, size.width / width, size.height / height);
    if (fit < 1) {
      width = Math.round(width * fit);
      height = Math.round(height * fit);
    }
  }

  const shinyFilter = shiny
    ? 'drop-shadow(0 0 6px gold) drop-shadow(0 0 12px rgba(255,215,0,0.4))'
    : (stage === 4 ? 'drop-shadow(0 0 8px gold)' : 'none');

  // The void & synthesis sprites are now authored with their final colours
  // (violet crystal / silver-gold), so the legacy .void-sprite hue-rotate(180deg)
  // filter — which was a tint hack — would wreck them. It's retired.
  const useVoidFilter = false;

  return (
    <canvas
      ref={canvasRef}
      width={width}
      height={height}
      className={`dragon-sprite stage-${stage} ${className} ${shiny ? 'shiny-sprite' : ''} ${useVoidFilter ? 'void-sprite' : ''}`}
      style={{
        imageRendering: 'auto',
        filter: shinyFilter,
        width: `${width}px`,
        height: `${height}px`,
      }}
    />
  );
});

function getFrameMetrics(img, frameCount, cols) {
  const tempCanvas = document.createElement('canvas');
  tempCanvas.width = DRAGON_SHEET.frameWidth;
  tempCanvas.height = DRAGON_SHEET.frameHeight;
  const ctx = tempCanvas.getContext('2d', { willReadFrequently: true });
  if (!ctx) return [];

  const metrics = [];
  for (let index = 0; index < frameCount; index += 1) {
    const col = index % cols;
    const row = Math.floor(index / cols);
    ctx.clearRect(0, 0, tempCanvas.width, tempCanvas.height);
    ctx.drawImage(
      img,
      col * DRAGON_SHEET.frameWidth,
      row * DRAGON_SHEET.frameHeight,
      DRAGON_SHEET.frameWidth,
      DRAGON_SHEET.frameHeight,
      0,
      0,
      DRAGON_SHEET.frameWidth,
      DRAGON_SHEET.frameHeight
    );
    const data = ctx.getImageData(0, 0, tempCanvas.width, tempCanvas.height).data;
    let top = DRAGON_SHEET.frameHeight;
    let bottom = -1;
    for (let y = 0; y < DRAGON_SHEET.frameHeight; y += 1) {
      for (let x = 0; x < DRAGON_SHEET.frameWidth; x += 1) {
        const offset = (y * DRAGON_SHEET.frameWidth + x) * 4;
        const r = data[offset];
        const g = data[offset + 1];
        const b = data[offset + 2];
        const a = data[offset + 3];
        const isGreenScreen = g > 150 && r < 150 && b < 150 && g > r * 1.3 && g > b * 1.3;
        if (a > 0 && !isGreenScreen) {
          top = Math.min(top, y);
          bottom = Math.max(bottom, y);
          break;
        }
      }
    }
    metrics.push({ top: bottom >= 0 ? top : 0, bottom });
  }

  return metrics;
}

function getStableIdleFrameRange(metrics) {
  if (metrics.length <= 3) return { start: 0, count: metrics.length };
  const bottoms = metrics.map(({ bottom }) => bottom).filter((bottom) => bottom >= 0);
  const hasSevereBaselineJump = Math.max(...bottoms) - Math.min(...bottoms) > DRAGON_SHEET.frameHeight * 0.18;
  if (!hasSevereBaselineJump) return { start: 0, count: metrics.length };

  const first = metrics[0];
  for (let index = 3; index < metrics.length; index += 1) {
    const current = metrics[index];
    if (
      Math.abs(current.top - first.top) > 20 ||
      Math.abs(current.bottom - first.bottom) > 20
    ) {
      return { start: 0, count: index };
    }
  }
  return { start: 0, count: metrics.length };
}

function getFrameBaselineOffsets(metrics, range) {
  const frameMetrics = metrics.slice(range.start, range.start + range.count);
  const baseline = Math.max(...frameMetrics.map(({ bottom }) => bottom).filter((bottom) => bottom >= 0), 0);
  return frameMetrics.map(({ bottom }) => (bottom >= 0 ? baseline - bottom : 0));
}

export default DragonSprite;
