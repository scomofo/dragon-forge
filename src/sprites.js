// Dragon sprite sheets are 2x4 grids on 1024x1024 images
// Each frame is 512x256 (but we'll render them scaled)
export const DRAGON_SHEET = {
  cols: 2,
  rows: 4,
  frameWidth: 512,
  frameHeight: 256,
  totalFrames: 8,
  idleFrames: [0, 1, 2, 3, 4, 5, 6, 7],
  lungeFrame: 3,
  frameDuration: 150, // ms per frame
};

// Scale factors for each evolution stage
export const STAGE_SCALES = {
  1: 0.6,
  2: 0.8,
  3: 1.0,
  4: 1.4,
};

// Display size for a dragon at scale 1.0
export const DRAGON_DISPLAY = {
  width: 200,
  height: 100,
};
