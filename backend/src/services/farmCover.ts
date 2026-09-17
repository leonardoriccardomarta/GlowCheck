import sharp from 'sharp';
import { env } from '../config/env';
import { allowedFarmImage } from './farmHero';

const UA =
  'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

const COVER_PROMPT = `Restyle this exact skincare product into a vertical 9:16 magazine cover photograph.

Keep the real packaging identical: same bottle or tube or jar, same label, logo, typography, colors and shape. Do not invent, rewrite, or hallucinate any text on the pack.

Full-bleed editorial beauty cover. The product is large, centered, and fills most of the frame. No empty black bars, no small postage-stamp photo, no collage, no watermark, no hands, no people, no extra products, no slogans, no UI.

Luxury studio lighting, soft diffused light, rich atmospheric background sampled from the product colors, photorealistic high-end Sephora campaign still, ultra sharp focus on the label.`;

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

type GeminiPart = { text?: string; inlineData?: { mimeType?: string; data?: string } };

async function geminiCover(jpeg: Buffer, name: string) {
  const key = env.GEMINI_API_KEY?.trim();
  if (!key) return null;
  const models = ['gemini-2.5-flash-image', 'gemini-3.1-flash-image'];
  for (const model of models) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), 22000);
    try {
      const response = await fetch(
        `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${key}`,
        {
          method: 'POST',
          signal: controller.signal,
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            contents: [
              {
                role: 'user',
                parts: [
                  { inlineData: { mimeType: 'image/jpeg', data: jpeg.toString('base64') } },
                  { text: `${COVER_PROMPT}\nProduct: ${name}` },
                ],
              },
            ],
            generationConfig: {
              responseModalities: ['TEXT', 'IMAGE'],
              imageConfig: { aspectRatio: '9:16' },
            },
          }),
        },
      );
      if (!response.ok) continue;
      const json = (await response.json()) as { candidates?: { content?: { parts?: GeminiPart[] } }[] };
      const data = json.candidates?.[0]?.content?.parts?.find((part) => part.inlineData?.data)?.inlineData?.data;
      if (data) return Buffer.from(data, 'base64');
    } catch {
      continue;
    } finally {
      clearTimeout(timer);
    }
  }
  return null;
}

export async function farmCoverImage(imageUrl: string, name: string): Promise<Buffer | null> {
  const src = await fetchBytes(imageUrl);
  if (!src) return null;
  const jpeg = await sharp(src)
    .rotate()
    .resize(1024, 1024, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 88 })
    .toBuffer();
  const generated = await geminiCover(jpeg, name);
  if (!generated) return null;
  return sharp(generated).resize(1080, 1920, { fit: 'cover', position: 'centre' }).png().toBuffer();
}
