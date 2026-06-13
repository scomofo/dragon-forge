/**
 * Generates assets/backgrounds/forge_bg.png — Felix's Forge interior.
 * Pure Node.js, no npm dependencies (uses built-in zlib only).
 *
 * Brief: 1024×1024 pixel art, 16-bit style. Stone brick wall, orange circuit
 * traces, anvil with ember glow, render-breach (jungle) on right, dark floor.
 */

'use strict';
const zlib = require('zlib');
const fs   = require('fs');
const path = require('path');

// ── PNG encoder ──────────────────────────────────────────────────────────────

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
    t[n] = c;
  }
  return t;
})();

function crc32(buf) {
  let c = 0xffffffff;
  for (const b of buf) c = CRC_TABLE[(c ^ b) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const t   = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(Buffer.concat([t, data])));
  return Buffer.concat([len, t, data, crc]);
}

function writePNG(file, w, h, pixels) {
  const raw = Buffer.alloc(h * (1 + w * 4));
  for (let y = 0; y < h; y++) {
    raw[y * (1 + w * 4)] = 0;
    for (let x = 0; x < w; x++) {
      const d = y * (1 + w * 4) + 1 + x * 4;
      const s = (y * w + x) * 4;
      raw[d]=pixels[s]; raw[d+1]=pixels[s+1]; raw[d+2]=pixels[s+2]; raw[d+3]=pixels[s+3];
    }
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4);
  ihdr[8]=8; ihdr[9]=6;
  fs.mkdirSync(path.dirname(file), { recursive: true });
  fs.writeFileSync(file, Buffer.concat([
    Buffer.from([137,80,78,71,13,10,26,10]),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]));
}

// ── Pixel buffer ──────────────────────────────────────────────────────────────

const W = 1024, H = 1024;
const pixels = new Uint8ClampedArray(W * H * 4);

function fillRect(x, y, w, h, r, g, b, a=255) {
  const x0=Math.max(0,Math.round(x)), y0=Math.max(0,Math.round(y));
  const x1=Math.min(W,Math.round(x+w)), y1=Math.min(H,Math.round(y+h));
  for (let py=y0; py<y1; py++)
    for (let px=x0; px<x1; px++) {
      const i=(py*W+px)*4;
      if (a===255) { pixels[i]=r; pixels[i+1]=g; pixels[i+2]=b; pixels[i+3]=255; }
      else {
        const oa=a/255, ia=1-oa;
        pixels[i]  = pixels[i]*ia  + r*oa;
        pixels[i+1]= pixels[i+1]*ia+ g*oa;
        pixels[i+2]= pixels[i+2]*ia+ b*oa;
        pixels[i+3]= 255;
      }
    }
}

// Snap to 4px pixel-art grid
const sp = v => Math.round(v/4)*4;
function px(x,y,w,h,r,g,b,a=255) {
  fillRect(sp(x),sp(y),Math.max(4,sp(w)),Math.max(4,sp(h)),r,g,b,a);
}

function radialGlow(cx, cy, ir, ro, r, g, b, maxA) {
  const x0=Math.max(0,cx-ro|0), x1=Math.min(W,(cx+ro+1)|0);
  const y0=Math.max(0,cy-ro|0), y1=Math.min(H,(cy+ro+1)|0);
  for (let py=y0; py<y1; py++)
    for (let qx=x0; qx<x1; qx++) {
      const d = Math.sqrt((qx-cx)**2+(py-cy)**2);
      if (d>ro) continue;
      const t = d<=ir ? 1 : 1-(d-ir)/(ro-ir);
      const a = (t*maxA)|0;
      if (a<2) continue;
      const i=(py*W+qx)*4;
      const oa=a/255, ia=1-oa;
      pixels[i]  =pixels[i]*ia  +r*oa;
      pixels[i+1]=pixels[i+1]*ia+g*oa;
      pixels[i+2]=pixels[i+2]*ia+b*oa;
      pixels[i+3]=255;
    }
}

// ── Layout ────────────────────────────────────────────────────────────────────

const CEIL_H = 80;
const FLOOR_Y = 640;

// ── 1. Base wall (medium dark, visible under bricks) ─────────────────────────

// Wall base — deep brown, NOT near-black
fillRect(0, 0, W, H, 0x18, 0x10, 0x08);

// ── 2. Ceiling ────────────────────────────────────────────────────────────────

fillRect(0, 0, W, CEIL_H, 0x08, 0x06, 0x04);

// Ceiling conduit pipes — every 96px
for (let x=0; x<W; x+=96) {
  px(x,   0, 10, CEIL_H, 0x28, 0x20, 0x10);
  px(x+4, 0,  5, CEIL_H, 0x38, 0x2c, 0x18);
}
// Ember gauge lights
for (let x=18; x<W; x+=96) {
  px(x, 26, 10, 10, 0xff, 0x6a, 0x1f);
  radialGlow(x+5, 31, 0, 28, 0xff, 0x6a, 0x1f, 90);
}
// Cyan diagnostic lights
for (let x=60; x<W; x+=96) {
  px(x, 42, 10, 10, 0x5e, 0xdc, 0xff);
  radialGlow(x+5, 47, 0, 22, 0x5e, 0xdc, 0xff, 70);
}

// ── 3. Stone brick wall (high contrast — warm stone on dark mortar) ───────────

// Wall base behind bricks (mortar color)
fillRect(0, CEIL_H, W, FLOOR_Y-CEIL_H, 0x22, 0x18, 0x0e);

const BW=72, BH=28;
for (let row=0; row*BH+CEIL_H < FLOOR_Y; row++) {
  const off = (row%2)*(BW/2);
  const by  = row*BH + CEIL_H;
  for (let col=-1; col*BW+off < W+BW; col++) {
    const bx = col*BW + off;
    // Brick face — warm medium stone, clearly visible
    const shade = (row+col)%3===0 ? 0x6a : (row+col)%3===1 ? 0x60 : 0x68;
    px(bx+3, by+3, BW-6, BH-6, shade, 0x44, 0x28);
    // Highlight top edge
    px(bx+3, by+3, BW-6, 3, shade+0x12, 0x54, 0x32, 200);
    // Shadow bottom edge
    px(bx+3, by+BH-5, BW-6, 3, 0x30, 0x22, 0x14, 200);
    // Mortar lines already show as the wall base
  }
}

// ── 4. Circuit traces — OPAQUE orange, clearly visible ───────────────────────

const TRACE_ROWS = [
  CEIL_H+52, CEIL_H+120, CEIL_H+208,
  CEIL_H+308, CEIL_H+418, CEIL_H+518,
];

for (const cy of TRACE_ROWS) {
  // Horizontal trace — left half of wall
  px(48,  cy, 260, 4, 0xff, 0x7a, 0x20);
  px(360, cy, 140, 4, 0xff, 0x7a, 0x20, 180);
  px(540, cy, 140, 3, 0xff, 0x7a, 0x20, 160);

  // Junction dots
  for (const nx of [48, 180, 308, 360, 500, 540, 680]) {
    if (nx < W * 0.76) {
      px(nx-4, cy-4, 10, 10, 0xff, 0x9a, 0x40);
      radialGlow(nx, cy, 0, 20, 0xff, 0x7a, 0x20, 70);
    }
  }

  // Vertical branches
  px(120, cy-36, 4, 36, 0xff, 0x7a, 0x20, 200);
  px(420, cy-52, 4, 52, 0xff, 0x7a, 0x20, 180);
  px(580, cy-28, 4, 28, 0xff, 0x7a, 0x20, 160);
}

// ── 5. Render-breach / jungle tear (right side) ───────────────────────────────

// Jagged tear edge defined by (y, edgeX) pairs
const tearPts = [
  [CEIL_H,        W*0.76],
  [CEIL_H+50,     W*0.80],
  [CEIL_H+110,    W*0.77],
  [CEIL_H+200,    W*0.82],
  [CEIL_H+290,    W*0.78],
  [CEIL_H+400,    W*0.83],
  [CEIL_H+510,    W*0.79],
  [FLOOR_Y,       W*0.78],
];

for (let y=CEIL_H; y<FLOOR_Y; y++) {
  let edgeX = W;
  for (let i=0; i<tearPts.length-1; i++) {
    const [y0,x0]=tearPts[i], [y1,x1]=tearPts[i+1];
    if (y>=y0 && y<y1) { edgeX = x0+(x1-x0)*((y-y0)/(y1-y0)); break; }
  }
  if (edgeX >= W) continue;

  // Bright tear edge glow (yellow-green)
  for (let x=Math.round(edgeX-3); x<Math.round(edgeX+6); x++) {
    if (x<0||x>=W) continue;
    const i=(y*W+x)*4;
    pixels[i]=0x88; pixels[i+1]=0xff; pixels[i+2]=0x44; pixels[i+3]=255;
  }
  // Jungle interior — medium green, clearly distinct from brown wall
  for (let x=Math.round(edgeX+6); x<W; x++) {
    const i=(y*W+x)*4;
    const depth = Math.min(1, (x-edgeX)/80);
    const gr = (0x44 + depth*0x20)|0;
    pixels[i]=0x10; pixels[i+1]=gr; pixels[i+2]=0x14; pixels[i+3]=255;
  }
}

// Vegetation blobs inside breach
const vegBlobs = [
  [CEIL_H+15,   W*0.82, 36, 56, 0x3a, 0x8a, 0x28],
  [CEIL_H+100,  W*0.86, 28, 48, 0x28, 0x6a, 0x18],
  [CEIL_H+185,  W*0.83, 40, 64, 0x48, 0xaa, 0x30],
  [CEIL_H+280,  W*0.87, 24, 44, 0x30, 0x78, 0x20],
  [CEIL_H+370,  W*0.84, 36, 56, 0x40, 0x98, 0x28],
  [CEIL_H+465,  W*0.86, 28, 42, 0x28, 0x68, 0x18],
];
for (const [y,x,w,h,r,g,b] of vegBlobs) px(x, y, w, h, r, g, b, 220);

// ── 6. Anvil silhouette with strong ember glow ────────────────────────────────

const AX=52, AY=480, AW=200, AH=150;

// Ember pool beneath anvil — strong warm glow
radialGlow(AX+AW/2, FLOOR_Y+20, 0, 280, 0xff, 0x5a, 0x1f, 120);
radialGlow(AX+AW/2, AY+AH*0.8, 20, 200, 0xff, 0x5a, 0x1f, 90);

// Anvil body (pure black silhouette)
px(AX+8,  AY,            AW-16, AH*0.42, 0x05, 0x03, 0x02);  // top face
px(AX,    AY+AH*0.1,     40,    AH*0.32, 0x05, 0x03, 0x02);  // left horn
px(AX+20, AY+AH*0.42,   AW*0.7, AH*0.1, 0x05, 0x03, 0x02);  // neck
px(AX,    AY+AH*0.52,   AW+8,   AH*0.48, 0x05, 0x03, 0x02); // base

// Glowing top edge
px(AX+8, AY, AW-16, 3, 0xff, 0x9a, 0x3d, 200);

// ── 7. Steel column with ember cable wrap ─────────────────────────────────────

const COL_X=340, COL_W=18;
px(COL_X,   CEIL_H, COL_W,   FLOOR_Y-CEIL_H, 0x28, 0x20, 0x14);
px(COL_X+3, CEIL_H, COL_W-6, FLOOR_Y-CEIL_H, 0x38, 0x2e, 0x1e);

for (let cy=CEIL_H+28; cy<FLOOR_Y; cy+=40) {
  px(COL_X-5, cy, COL_W+10, 4, 0x1a, 0x14, 0x0a);
  px(COL_X-4, cy+1, COL_W+8, 5, 0xff, 0x6a, 0x1f, 220);
  radialGlow(COL_X+COL_W/2, cy+3, 0, 22, 0xff, 0x6a, 0x1f, 55);
}

// ── 8. Console panel (green CRT screen) ───────────────────────────────────────

const CP_X=628, CP_Y=CEIL_H+136, CP_W=96, CP_H=120;
px(CP_X,   CP_Y,    CP_W,    CP_H,    0x08, 0x18, 0x08);
px(CP_X+4, CP_Y+4,  CP_W-8,  CP_H-8,  0x04, 0x10, 0x04);

// CRT text scanlines (bright green pixels)
for (let row=0; row<6; row++) {
  const lineAlpha = row % 2 === 0 ? 230 : 160;
  for (let dot=0; dot<6; dot++) {
    const dv = ((dot*7+row*3)%5 < 3) ? lineAlpha : 80;
    px(CP_X+12+dot*12, CP_Y+18+row*14, 8, 6, 0x5c, 0xff, 0x8a, dv);
  }
}

// Screen glow
radialGlow(CP_X+CP_W/2, CP_Y+CP_H/2, 12, 120, 0x5c, 0xff, 0x8a, 45);

// Frame border
px(CP_X, CP_Y, CP_W, 4, 0x5c, 0xff, 0x8a, 200);
px(CP_X, CP_Y+CP_H-4, CP_W, 4, 0x5c, 0xff, 0x8a, 200);
px(CP_X, CP_Y, 4, CP_H, 0x5c, 0xff, 0x8a, 200);
px(CP_X+CP_W-4, CP_Y, 4, CP_H, 0x5c, 0xff, 0x8a, 200);

// ── 9. Glowing canister ───────────────────────────────────────────────────────

const CAN_X=448, CAN_Y=FLOOR_Y-76;
px(CAN_X,   CAN_Y,    28, 68, 0x28, 0x20, 0x14);
px(CAN_X+3, CAN_Y+3,  22, 62, 0x12, 0x0e, 0x08);
// Glowing core
px(CAN_X+8, CAN_Y+8,  12, 50, 0x5e, 0xdc, 0xff, 220);
px(CAN_X+10,CAN_Y+10, 8,  46, 0xcc, 0xf0, 0xff, 200);
radialGlow(CAN_X+14, CAN_Y+34, 0, 100, 0x5e, 0xdc, 0xff, 65);

// ── 10. Workbench ─────────────────────────────────────────────────────────────

const WB_X=530, WB_Y=FLOOR_Y-68, WB_W=168;
px(WB_X-6, WB_Y, WB_W+12, 6, 0x6a, 0x4c, 0x30);
px(WB_X,   WB_Y+6, WB_W,  58, 0x18, 0x10, 0x08);
// Tools on bench
px(WB_X+14, WB_Y-10, 28, 4,  0x88, 0x78, 0x60);  // wrench shaft
px(WB_X+14, WB_Y-18, 22, 8,  0x9a, 0x8a, 0x72);  // wrench head
px(WB_X+58, WB_Y-16, 8,  14, 0xff, 0x8a, 0x3d, 240); // ember probe
px(WB_X+80, WB_Y-12, 14, 10, 0x5e, 0xdc, 0xff, 230); // cyan device

// ── 11. Floor ────────────────────────────────────────────────────────────────

fillRect(0, FLOOR_Y, W, H-FLOOR_Y, 0x10, 0x0c, 0x08);

// Visible floor grid
for (let gy=FLOOR_Y+40; gy<H; gy+=40)
  px(0, gy, W, 2, 0x28, 0x22, 0x16, 70);
for (let gx=0; gx<W; gx+=72)
  px(gx, FLOOR_Y, 2, H-FLOOR_Y, 0x22, 0x1c, 0x12, 55);

// Warm horizon line at floor join
px(0, FLOOR_Y-4, W*0.76, 4, 0xc9, 0xa5, 0x67, 200);

// Floor reflections (ember + cyan pooling on ground)
radialGlow(AX+AW/2, FLOOR_Y+8,  0, 300, 0xff, 0x5a, 0x1f, 55);
radialGlow(CAN_X+14, FLOOR_Y+8, 0, 110, 0x5e, 0xdc, 0xff, 40);

// ── 12. CRT scanlines (subtle — let underlying image breathe) ─────────────────

for (let sl=0; sl<H; sl+=4)
  px(0, sl, W, 1, 0x00, 0x00, 0x00, 12);

// ── Write ─────────────────────────────────────────────────────────────────────

const outFile = path.join(__dirname, '..', 'public', 'assets', 'backgrounds', 'forge_bg.png');
writePNG(outFile, W, H, pixels);
console.log(`Written: ${outFile} (${(fs.statSync(outFile).size/1024).toFixed(1)} KB)`);
