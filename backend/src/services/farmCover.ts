import sharp from 'sharp';
import { allowedFarmImage } from './farmHero';

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

const W = 1080;
const H = 1920;

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

async function fullBleed(src: Buffer) {
  return sharp(src)
    .resize(W, H, { fit: 'cover', position: 'centre' })
    .modulate({ saturation: 1.16, brightness: 1.03 })
    .sharpen()
    .png()
    .toBuffer();
}

async function packshotCover(src: Buffer) {
  let product = src;
  try {
    product = await sharp(src).trim({ threshold: 24, background: '#ffffff' }).toBuffer();
  } catch {
    product = src;
  }
  const wash = await sharp(product)
    .resize(W, H, { fit: 'cover' })
    .modulate({ saturation: 1.42, brightness: 0.84 })
    .blur(42)
    .toBuffer();
  const fitted = await sharp(product)
    .resize(Math.round(W * 0.9), Math.round(H * 0.78), { fit: 'inside' })
    .sharpen()
    .png()
    .toBuffer();
  const meta = await sharp(fitted).metadata();
  const left = Math.round((W - (meta.width || W)) / 2);
  const top = Math.round((H - (meta.height || H)) / 2);
  return sharp(wash)
    .composite([{ input: fitted, left, top }])
    .png()
    .toBuffer();
}

export async function farmCoverImage(imageUrl: string, _name?: string): Promise<Buffer | null> {
  const src = await fetchBytes(imageUrl);
  if (!src) return null;
  const rotated = await sharp(src).rotate().toBuffer();
  const luma = await cornerLuma(rotated);
  if (luma > 205) return packshotCover(rotated);
  return fullBleed(rotated);
}
