const fs = require('fs');
const zlib = require('zlib');

function crc32(b) {
  const t = new Int32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1); t[n] = c; }
  let c = 0xffffffff;
  for (let i = 0; i < b.length; i++) c = t[(c ^ b[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
function chunk(type, data) {
  const td = Buffer.concat([Buffer.from(type), data]);
  const l = Buffer.alloc(4); l.writeUInt32BE(data.length);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([l, td, crc]);
}
function encodePNG(W, H, pixels) {
  const rows = [];
  for (let y = 0; y < H; y++) {
    const row = Buffer.alloc(1 + W * 4); row[0] = 0;
    pixels.copy(row, 1, y * W * 4, (y + 1) * W * 4); rows.push(row);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(W, 0); ihdr.writeUInt32BE(H, 4); ihdr[8] = 8; ihdr[9] = 6;
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  return Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', zlib.deflateSync(Buffer.concat(rows))), chunk('IEND', Buffer.alloc(0))]);
}

const YELLOW = [0xFF, 0xD9, 0x3D];
const PINK   = [0xFF, 0x8A, 0x9E];
const BLUE   = [0x5B, 0x9B, 0xD5];
const DARK   = [0x2C, 0x2C, 0x2C];
const BG     = [250, 248, 245];
const BLUSH_Y = [0xFF, 0xAD, 0xB9];
const BLUSH_P = [0xFF, 0x6B, 0x81];
const BLUSH_B = [0x4A, 0x8A, 0xC7];

function dist(x, y, cx, cy) { return Math.hypot(x - cx, y - cy); }

function drawBall(arr, W, H, cx, cy, r, color) {
  for (let y = Math.floor(cy - r - 1); y <= Math.ceil(cy + r + 1); y++) {
    if (y < 0 || y >= H) continue;
    for (let x = Math.floor(cx - r - 1); x <= Math.ceil(cx + r + 1); x++) {
      if (x < 0 || x >= W) continue;
      const d = dist(x, y, cx, cy);
      if (d > r) continue;
      const shade = 1.0 - 0.12 * Math.max(0, (d / r) * (1 + (y - cy) / r) * 0.7);
      const hl = 0.15 * Math.max(0, 1 - dist(x, y, cx - r * 0.3, cy - r * 0.3) / (r * 0.7));
      const r2 = Math.min(255, Math.round(color[0] * shade + hl * 255));
      const g2 = Math.min(255, Math.round(color[1] * shade + hl * 255));
      const b2 = Math.min(255, Math.round(color[2] * shade + hl * 255));
      const edgeAlpha = Math.min(1, (r - d));
      const off = (y * W + x) * 4;
      arr[off] = Math.round(arr[off] * (1 - edgeAlpha) + r2 * edgeAlpha);
      arr[off + 1] = Math.round(arr[off + 1] * (1 - edgeAlpha) + g2 * edgeAlpha);
      arr[off + 2] = Math.round(arr[off + 2] * (1 - edgeAlpha) + b2 * edgeAlpha);
      arr[off + 3] = 255;
    }
  }
}

function drawDot(arr, W, H, cx, cy, r) {
  for (let y = Math.floor(cy - r - 1); y <= Math.ceil(cy + r + 1); y++) {
    if (y < 0 || y >= H) continue;
    for (let x = Math.floor(cx - r - 1); x <= Math.ceil(cx + r + 1); x++) {
      if (x < 0 || x >= W) continue;
      if (dist(x, y, cx, cy) < r) {
        const off = (y * W + x) * 4;
        arr[off] = DARK[0]; arr[off + 1] = DARK[1]; arr[off + 2] = DARK[2];
      }
    }
  }
}

function drawSmile(arr, W, H, cx, cy, w, h) {
  for (let dy = 0; dy < h; dy++) {
    const t = dy / h;
    const halfW = w / 2 * Math.sin(t * Math.PI);
    for (let dx = -halfW; dx < halfW; dx += 0.35) {
      const x = Math.round(cx + dx), y = Math.round(cy + dy);
      if (x >= 0 && x < W && y >= 0 && y < H) {
        const off = (y * W + x) * 4;
        arr[off] = DARK[0]; arr[off + 1] = DARK[1]; arr[off + 2] = DARK[2];
      }
    }
  }
}

function drawBlush(arr, W, H, cx, cy, rx, ry, color) {
  for (let y = Math.floor(cy - ry - 1); y <= Math.ceil(cy + ry + 1); y++) {
    if (y < 0 || y >= H) continue;
    for (let x = Math.floor(cx - rx - 1); x <= Math.ceil(cx + rx + 1); x++) {
      if (x < 0 || x >= W) continue;
      const d = ((x - cx) / rx) ** 2 + ((y - cy) / ry) ** 2;
      if (d < 1) {
        const off = (y * W + x) * 4;
        const alpha = (1 - d) * 0.45;
        arr[off] = Math.round(arr[off] * (1 - alpha) + color[0] * alpha);
        arr[off + 1] = Math.round(arr[off + 1] * (1 - alpha) + color[1] * alpha);
        arr[off + 2] = Math.round(arr[off + 2] * (1 - alpha) + color[2] * alpha);
      }
    }
  }
}

const sizes = { 'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192 };

for (const [density, sz] of Object.entries(sizes)) {
  const arr = Buffer.alloc(sz * sz * 4);
  for (let i = 0; i < arr.length; i += 4) { arr[i] = BG[0]; arr[i + 1] = BG[1]; arr[i + 2] = BG[2]; arr[i + 3] = 255; }

  const k = sz / 240.0;

  // CSS positions: 240x240 container
  // Yellow: 160x160, top:15, left:20 → center(100,95) r=80
  drawBall(arr, sz, sz, 100 * k, 95 * k, 80 * k, YELLOW);
  // Pink: 135x135, bottom:35, right:-10 → center(172,137) r=67
  drawBall(arr, sz, sz, 172 * k, 137 * k, 67 * k, PINK);
  // Blue: 145x145, bottom:-15, left:10 → center(82,172) r=72
  drawBall(arr, sz, sz, 82 * k, 172 * k, 72 * k, BLUE);

  // Yellow face
  const yR = 80 * k;
  drawDot(arr, sz, sz, 100 * k - 0.30 * yR, 95 * k - 0.15 * yR, 2.5 * k);
  drawDot(arr, sz, sz, 100 * k + 0.28 * yR, 95 * k - 0.25 * yR, 2.2 * k);
  drawSmile(arr, sz, sz, 100 * k, 95 * k + 0.10 * yR, 0.26 * yR, 0.13 * yR);
  drawBlush(arr, sz, sz, 100 * k - 0.38 * yR, 95 * k + 0.15 * yR, 0.18 * yR, 0.10 * yR, BLUSH_Y);
  drawBlush(arr, sz, sz, 100 * k + 0.42 * yR, 95 * k + 0.10 * yR, 0.18 * yR, 0.10 * yR, BLUSH_Y);

  // Pink face
  const pR = 67 * k;
  drawDot(arr, sz, sz, 172 * k - 0.28 * pR, 137 * k - 0.18 * pR, 1.8 * k);
  drawDot(arr, sz, sz, 172 * k + 0.32 * pR, 137 * k - 0.28 * pR, 1.5 * k);
  drawSmile(arr, sz, sz, 172 * k, 137 * k + 0.05 * pR, 0.22 * pR, 0.10 * pR);
  drawBlush(arr, sz, sz, 172 * k - 0.40 * pR, 137 * k + 0.12 * pR, 0.16 * pR, 0.08 * pR, BLUSH_P);

  // Blue face
  const bR = 72 * k;
  drawDot(arr, sz, sz, 82 * k - 0.24 * bR, 172 * k - 0.15 * bR, 2.0 * k);
  drawDot(arr, sz, sz, 82 * k + 0.24 * bR, 172 * k - 0.15 * bR, 2.0 * k);
  drawSmile(arr, sz, sz, 82 * k, 172 * k + 0.08 * bR, 0.24 * bR, 0.12 * bR);
  drawBlush(arr, sz, sz, 82 * k - 0.34 * bR, 172 * k + 0.08 * bR, 0.15 * bR, 0.08 * bR, BLUSH_B);
  drawBlush(arr, sz, sz, 82 * k + 0.36 * bR, 172 * k + 0.08 * bR, 0.15 * bR, 0.08 * bR, BLUSH_B);

  const dir = `G:/Program Files/predict_fate/shiguangjia/timehouse/android/app/src/main/res/mipmap-${density}`;
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, {recursive: true});
  fs.writeFileSync(`${dir}/ic_launcher.png`, encodePNG(sz, sz, arr));
  console.log(`${density} ${sz}x${sz}`);
}
console.log('Done');
