import sharp from 'sharp';
import { env } from '../config/env';
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
  const local = luma > 205 ? await packshotCover(rotated) : await fullBleed(rotated);
  const flux = await fluxRedux(local);
  if (!flux) return local;
  return sharp(flux).resize(W, H, { fit: 'cover', position: 'centre' }).png().toBuffer();
}

type FalImage = { url?: string };
type FalResponse = {
  images?: FalImage[];
  status?: string;
  request_id?: string;
  status_url?: string;
  response_url?: string;
};

async function falJson(url: string, key: string, init?: RequestInit) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 20000);
  try {
    const response = await fetch(url, {
      ...init,
      signal: controller.signal,
      headers: {
        Authorization: `Key ${key}`,
        'Content-Type': 'application/json',
        ...(init?.headers || {}),
      },
    });
    if (!response.ok) return null;
    return (await response.json()) as FalResponse;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function downloadImage(url: string) {
  if (url.startsWith('data:')) {
    const b64 = url.split(',')[1];
    return b64 ? Buffer.from(b64, 'base64') : null;
  }
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const response = await fetch(url, { signal: controller.signal });
    if (!response.ok) return null;
    return Buffer.from(await response.arrayBuffer());
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

async function fluxRedux(coverPng: Buffer) {
  const key = env.FAL_KEY?.trim();
  if (!key) return null;
  const jpeg = await sharp(coverPng)
    .resize(768, 1344, { fit: 'cover', position: 'centre' })
    .jpeg({ quality: 86 })
    .toBuffer();
  const payload = {
    image_url: `data:image/jpeg;base64,${jpeg.toString('base64')}`,
    image_size: 'portrait_16_9',
    num_inference_steps: 4,
    output_format: 'png',
    sync_mode: true,
    num_images: 1,
  };
  let json = await falJson('https://fal.run/fal-ai/flux/schnell/redux', key, {
    method: 'POST',
    body: JSON.stringify(payload),
  });
  if (!json?.images?.length) {
    json =
      (await falJson('https://queue.fal.run/fal-ai/flux/schnell/redux', key, {
        method: 'POST',
        body: JSON.stringify({ ...payload, sync_mode: false }),
      })) || json;
  }
  if (json?.request_id && !json.images?.length) {
    const statusUrl =
      json.status_url || `https://queue.fal.run/fal-ai/flux/schnell/redux/requests/${json.request_id}/status`;
    const resultUrl =
      json.response_url || `https://queue.fal.run/fal-ai/flux/schnell/redux/requests/${json.request_id}`;
    for (let i = 0; i < 16; i++) {
      await new Promise((resolve) => setTimeout(resolve, 900));
      const status = await falJson(statusUrl, key);
      if (status?.status === 'COMPLETED') {
        json = (await falJson(resultUrl, key)) || json;
        break;
      }
      if (status?.status === 'FAILED') return null;
    }
  }
  const url = json?.images?.[0]?.url;
  if (!url) return null;
  return downloadImage(url);
}
