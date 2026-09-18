import sharp from 'sharp';
import { allowedFarmImage } from './farmHero';

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

async function fetchBytes(url: string) {
  if (!allowedFarmImage(url)) return null;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      redirect: 'follow',
      headers: {
        'User-Agent': UA,
        Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        Referer: new URL(url).origin + '/',
      },
    });
    if (!response.ok) return null;
    const buf = Buffer.from(await response.arrayBuffer());
    if (buf.length < 80 || buf.length > 6_000_000) return null;
    return buf;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function cornerLuma(buf: Buffer) {
  const { width = 32, height = 32 } = await sharp(buf).metadata();
  const s = Math.max(8, Math.min(28, Math.floor(Math.min(width, height) * 0.08)));
  const spots = [
    { left: 0, top: 0 },
    { left: Math.max(0, width - s), top: 0 },
    { left: 0, top: Math.max(0, height - s) },
    { left: Math.max(0, width - s), top: Math.max(0, height - s) },
  ];
  let lum = 0;
  for (const box of spots) {
    const { dominant } = await sharp(buf).extract({ ...box, width: s, height: s }).stats();
    lum += 0.299 * dominant.r + 0.587 * dominant.g + 0.114 * dominant.b;
  }
  return lum / spots.length;
}

async function knockWhite(src: Buffer) {
  const { data, info } = await sharp(src).ensureAlpha().raw().toBuffer({ resolveWithObject: true });
  const px = Buffer.from(data);
  for (let i = 0; i < px.length; i += 4) {
    if (px[i] > 242 && px[i + 1] > 242 && px[i + 2] > 242) px[i + 3] = 0;
  }
  return sharp(px, { raw: { width: info.width, height: info.height, channels: 4 } }).png().toBuffer();
}

export async function farmCoverImage(imageUrl: string, _name?: string): Promise<Buffer | null> {
  const src = await fetchBytes(imageUrl);
  if (!src) return null;
  let bottle = await sharp(src).rotate().ensureAlpha().toBuffer();
  try {
    bottle = await sharp(bottle).trim({ threshold: 20, background: '#ffffff' }).toBuffer();
  } catch {
    /* keep */
  }
  if ((await cornerLuma(bottle)) > 200) {
    bottle = await knockWhite(bottle);
    try {
      bottle = await sharp(bottle).trim().toBuffer();
    } catch {
      /* keep */
    }
  }
  return sharp(bottle)
    .resize(720, 900, { fit: 'inside', withoutEnlargement: true })
    .png()
    .toBuffer();
}
