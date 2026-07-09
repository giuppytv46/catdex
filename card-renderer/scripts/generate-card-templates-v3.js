const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');

const width = 1060;
const height = 1484;
const scaleX = width / 1500;
const scaleY = height / 2100;

const rarities = {
  common: {
    bgTop: [48, 111, 75],
    bgBottom: [184, 151, 83],
    frame: [205, 174, 93],
    frameDark: [36, 82, 58],
    header: [36, 92, 62],
    header2: [83, 133, 83],
    glow: [224, 203, 122],
    accent: [115, 181, 113],
  },
  uncommon: {
    bgTop: [35, 117, 133],
    bgBottom: [189, 213, 215],
    frame: [214, 229, 230],
    frameDark: [28, 92, 104],
    header: [27, 103, 124],
    header2: [88, 177, 185],
    glow: [234, 255, 255],
    accent: [126, 223, 231],
  },
  rare: {
    bgTop: [25, 57, 121],
    bgBottom: [27, 96, 158],
    frame: [230, 187, 82],
    frameDark: [16, 41, 99],
    header: [21, 48, 116],
    header2: [42, 101, 171],
    glow: [255, 222, 116],
    accent: [88, 154, 231],
  },
  epic: {
    bgTop: [71, 37, 129],
    bgBottom: [148, 69, 174],
    frame: [233, 183, 92],
    frameDark: [51, 27, 92],
    header: [62, 31, 116],
    header2: [126, 55, 157],
    glow: [255, 203, 118],
    accent: [209, 113, 255],
  },
  legendary: {
    bgTop: [255, 236, 154],
    bgBottom: [255, 255, 250],
    frame: [177, 123, 34],
    frameDark: [116, 72, 22],
    header: [255, 248, 209],
    header2: [244, 205, 96],
    glow: [255, 255, 255],
    accent: [118, 170, 255],
  },
};

function clamp(value) {
  return Math.max(0, Math.min(255, Math.round(value)));
}

function mix(a, b, t) {
  return [
    a[0] + (b[0] - a[0]) * t,
    a[1] + (b[1] - a[1]) * t,
    a[2] + (b[2] - a[2]) * t,
  ];
}

function makeImage() {
  return Buffer.alloc(width * height * 4);
}

function blendPixel(img, x, y, color, alpha = 1) {
  if (x < 0 || y < 0 || x >= width || y >= height || alpha <= 0) return;
  const i = (Math.floor(y) * width + Math.floor(x)) * 4;
  const inv = 1 - alpha;
  img[i] = clamp(color[0] * alpha + img[i] * inv);
  img[i + 1] = clamp(color[1] * alpha + img[i + 1] * inv);
  img[i + 2] = clamp(color[2] * alpha + img[i + 2] * inv);
  img[i + 3] = 255;
}

function fillRect(img, x, y, w, h, color, alpha = 1) {
  const x0 = Math.max(0, Math.floor(x));
  const y0 = Math.max(0, Math.floor(y));
  const x1 = Math.min(width, Math.ceil(x + w));
  const y1 = Math.min(height, Math.ceil(y + h));
  for (let yy = y0; yy < y1; yy += 1) {
    for (let xx = x0; xx < x1; xx += 1) {
      blendPixel(img, xx, yy, color, alpha);
    }
  }
}

function roundedRectMask(px, py, x, y, w, h, r) {
  const rx = Math.min(r, w / 2);
  const ry = Math.min(r, h / 2);
  const cx = px < x + rx ? x + rx : px > x + w - rx ? x + w - rx : px;
  const cy = py < y + ry ? y + ry : py > y + h - ry ? y + h - ry : py;
  const dx = px - cx;
  const dy = py - cy;
  return dx * dx + dy * dy <= rx * rx;
}

function fillRoundedRect(img, x, y, w, h, r, color, alpha = 1) {
  const x0 = Math.max(0, Math.floor(x));
  const y0 = Math.max(0, Math.floor(y));
  const x1 = Math.min(width, Math.ceil(x + w));
  const y1 = Math.min(height, Math.ceil(y + h));
  for (let yy = y0; yy < y1; yy += 1) {
    for (let xx = x0; xx < x1; xx += 1) {
      if (roundedRectMask(xx + 0.5, yy + 0.5, x, y, w, h, r)) {
        blendPixel(img, xx, yy, color, alpha);
      }
    }
  }
}

function strokeRoundedRect(img, x, y, w, h, r, color, thickness = 2, alpha = 1) {
  fillRoundedRect(img, x, y, w, h, r, color, alpha);
  fillRoundedRect(img, x + thickness, y + thickness, w - thickness * 2, h - thickness * 2, Math.max(0, r - thickness), [0, 0, 0], 0);
}

function drawRoundedBorder(img, x, y, w, h, r, color, thickness = 2, alpha = 1) {
  for (let i = 0; i < thickness; i += 1) {
    drawRoundedLine(img, x + i, y + i, w - i * 2, h - i * 2, Math.max(0, r - i), color, alpha);
  }
}

function drawRoundedLine(img, x, y, w, h, r, color, alpha = 1) {
  const x0 = Math.floor(x);
  const y0 = Math.floor(y);
  const x1 = Math.ceil(x + w);
  const y1 = Math.ceil(y + h);
  for (let xx = x0; xx <= x1; xx += 1) {
    if (roundedRectMask(xx, y, x, y, w, h, r)) blendPixel(img, xx, y, color, alpha);
    if (roundedRectMask(xx, y + h, x, y, w, h, r)) blendPixel(img, xx, y + h, color, alpha);
  }
  for (let yy = y0; yy <= y1; yy += 1) {
    if (roundedRectMask(x, yy, x, y, w, h, r)) blendPixel(img, x, yy, color, alpha);
    if (roundedRectMask(x + w, yy, x, y, w, h, r)) blendPixel(img, x + w, yy, color, alpha);
  }
}

function fillEllipse(img, cx, cy, rx, ry, color, alpha = 1) {
  const x0 = Math.max(0, Math.floor(cx - rx));
  const y0 = Math.max(0, Math.floor(cy - ry));
  const x1 = Math.min(width, Math.ceil(cx + rx));
  const y1 = Math.min(height, Math.ceil(cy + ry));
  for (let yy = y0; yy < y1; yy += 1) {
    for (let xx = x0; xx < x1; xx += 1) {
      const dx = (xx + 0.5 - cx) / rx;
      const dy = (yy + 0.5 - cy) / ry;
      if (dx * dx + dy * dy <= 1) {
        blendPixel(img, xx, yy, color, alpha);
      }
    }
  }
}

function drawStar(img, cx, cy, rOuter, rInner, color, alpha = 1) {
  const points = [];
  for (let i = 0; i < 10; i += 1) {
    const angle = -Math.PI / 2 + (Math.PI * 2 * i) / 10;
    const radius = i % 2 === 0 ? rOuter : rInner;
    points.push([cx + Math.cos(angle) * radius, cy + Math.sin(angle) * radius]);
  }
  fillPolygon(img, points, color, alpha);
}

function fillPolygon(img, points, color, alpha = 1) {
  const minY = Math.max(0, Math.floor(Math.min(...points.map((p) => p[1]))));
  const maxY = Math.min(height - 1, Math.ceil(Math.max(...points.map((p) => p[1]))));
  for (let y = minY; y <= maxY; y += 1) {
    const intersections = [];
    for (let i = 0; i < points.length; i += 1) {
      const [x1, y1] = points[i];
      const [x2, y2] = points[(i + 1) % points.length];
      if ((y1 <= y && y2 > y) || (y2 <= y && y1 > y)) {
        intersections.push(x1 + ((y - y1) * (x2 - x1)) / (y2 - y1));
      }
    }
    intersections.sort((a, b) => a - b);
    for (let i = 0; i < intersections.length; i += 2) {
      const x0 = Math.max(0, Math.floor(intersections[i]));
      const x1 = Math.min(width - 1, Math.ceil(intersections[i + 1]));
      for (let x = x0; x <= x1; x += 1) blendPixel(img, x, y, color, alpha);
    }
  }
}

function drawBackground(img, palette) {
  for (let y = 0; y < height; y += 1) {
    const base = mix(palette.bgTop, palette.bgBottom, y / height);
    for (let x = 0; x < width; x += 1) {
      const vignette = 1 - Math.min(0.34, Math.hypot((x - width / 2) / width, (y - height / 2) / height) * 0.42);
      blendPixel(img, x, y, base.map((v) => v * vignette), 1);
    }
  }
}

function drawTemplate(rarity, palette) {
  const img = makeImage();
  drawBackground(img, palette);

  fillRoundedRect(img, 38, 34, width - 76, height - 68, 46, palette.frameDark, 0.92);
  fillRoundedRect(img, 58, 54, width - 116, height - 108, 36, palette.frame, 0.96);
  fillRoundedRect(img, 82, 82, width - 164, height - 164, 28, palette.frameDark, 0.95);

  fillEllipse(img, width / 2, 725, 365, 450, palette.glow, rarity === 'legendary' ? 0.18 : 0.1);
  fillRoundedRect(img, 166, 284, 728, 852, 48, [255, 255, 255], rarity === 'legendary' ? 0.16 : 0.09);
  drawRoundedBorder(img, 166, 284, 728, 852, 48, palette.frame, 5, 0.8);

  const headerX = 118;
  const headerY = 80;
  const headerW = width - 236;
  const nameH = 106;
  const metaY = headerY + nameH + 16;
  fillRoundedRect(img, headerX, headerY, headerW, 178, 26, palette.header, rarity === 'legendary' ? 0.72 : 0.9);
  fillRoundedRect(img, headerX + 16, headerY + 14, headerW - 32, nameH - 12, 22, palette.header2, rarity === 'legendary' ? 0.62 : 0.7);
  drawRoundedBorder(img, headerX, headerY, headerW, 178, 26, palette.frame, 4, 0.9);

  fillRoundedRect(img, 126, metaY, 218, 56, 18, palette.frameDark, rarity === 'legendary' ? 0.66 : 0.86);
  fillRoundedRect(img, 716, metaY, 232, 56, 18, palette.frameDark, rarity === 'legendary' ? 0.66 : 0.86);
  drawRoundedBorder(img, 126, metaY, 218, 56, 18, palette.glow, 2, 0.75);
  drawRoundedBorder(img, 716, metaY, 232, 56, 18, palette.glow, 2, 0.75);

  for (let i = 0; i < 9; i += 1) {
    const x = 160 + i * 92;
    drawStar(img, x, 302 + (i % 2) * 12, 9, 4, palette.accent, 0.32);
  }

  fillRoundedRect(img, 146, 1142, width - 292, 116, 30, palette.header, rarity === 'legendary' ? 0.55 : 0.72);
  drawRoundedBorder(img, 146, 1142, width - 292, 116, 30, palette.frame, 4, 0.85);

  if (rarity === 'epic' || rarity === 'legendary') {
    for (let i = 0; i < 7; i += 1) {
      fillEllipse(img, 170 + i * 120, 430 + (i % 3) * 180, 38, 38, palette.glow, 0.08);
    }
  }

  return img;
}

function crc32(buf) {
  let crc = -1;
  for (const byte of buf) {
    crc ^= byte;
    for (let k = 0; k < 8; k += 1) crc = (crc >>> 1) ^ (0xedb88320 & -(crc & 1));
  }
  return (crc ^ -1) >>> 0;
}

function chunk(type, data) {
  const typeBuf = Buffer.from(type);
  const out = Buffer.alloc(12 + data.length);
  out.writeUInt32BE(data.length, 0);
  typeBuf.copy(out, 4);
  data.copy(out, 8);
  out.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 8 + data.length);
  return out;
}

function writePng(filePath, rgba) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  for (let y = 0; y < height; y += 1) {
    raw[y * (width * 4 + 1)] = 0;
    rgba.copy(raw, y * (width * 4 + 1) + 1, y * width * 4, (y + 1) * width * 4);
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;

  const png = Buffer.concat([
    Buffer.from('89504e470d0a1a0a', 'hex'),
    chunk('IHDR', ihdr),
    chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
    chunk('IEND', Buffer.alloc(0)),
  ]);
  fs.writeFileSync(filePath, png);
}

for (const [rarity, palette] of Object.entries(rarities)) {
  const out = path.join(__dirname, '..', 'assets/cards/templates/default', rarity, 'template.png');
  writePng(out, drawTemplate(rarity, palette));
  console.log(`wrote ${out}`);
}
