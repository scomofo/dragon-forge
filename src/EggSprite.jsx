import { useEffect, useRef } from 'react';

const EGG_SHEET = {
  cols: 4,
  rows: 2,
  frameWidth: 256,
  frameHeight: 320,
};

function drawFrame(canvas, img, frame) {
  if (!canvas || !img) return;
  const ctx = canvas.getContext('2d');
  const col = frame % EGG_SHEET.cols;
  const row = Math.floor(frame / EGG_SHEET.cols);
  const sx = col * EGG_SHEET.frameWidth;
  const sy = row * EGG_SHEET.frameHeight;
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  ctx.drawImage(img, sx, sy, EGG_SHEET.frameWidth, EGG_SHEET.frameHeight, 0, 0, canvas.width, canvas.height);
}

export default function EggSprite({ sheet, frame = 0, className = '' }) {
  const canvasRef = useRef(null);
  const imageRef = useRef(null);

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.onload = () => {
      imageRef.current = img;
      drawFrame(canvasRef.current, img, frame);
    };
    img.src = sheet;
  }, [sheet]);

  useEffect(() => {
    if (imageRef.current) {
      drawFrame(canvasRef.current, imageRef.current, frame);
    }
  }, [frame]);

  return (
    <canvas
      ref={canvasRef}
      width={180}
      height={225}
      className={`egg-sprite-canvas ${className}`}
      style={{
        imageRendering: 'pixelated',
        width: '180px',
        height: '225px',
      }}
    />
  );
}
