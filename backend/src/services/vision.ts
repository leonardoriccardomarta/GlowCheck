import { z } from 'zod';
import { env } from '../config/env';
import { extractVisionJson } from './visionJson';

export const visionExtractSchema = z.object({
  productName: z.string().nullable().optional(),
  barcode: z.string().nullable().optional(),
  extractedIngredients: z.array(z.string()).optional(),
  ingredients: z.array(z.string()).optional(),
  category: z.string().nullable().optional(),
  kind: z.string().nullable().optional(),
});

export type VisionExtract = {
  productName: string | null;
  barcode: string | null;
  ingredients: string[];
  category: string | null;
  kind: 'personal_care' | 'food' | 'other' | 'unknown';
};

const USER_INSTRUCTIONS = `GlowCheck is personal-care only: face, hair, body, sun, makeup, perfume, soap, deodorant, toothpaste. Transcribe INCI names if this is a cosmetic/personal-care label.
If the photo is food, drink, a nutrition label, household cleaner, electronics, or anything else, set kind accordingly and leave extractedIngredients empty.
Do not add comments, scores, safety judgments, medical claims, or <think> tags.
Never invent a brand line (Fructis vs Ultra Dolce vs another Garnier range). Copy only words visible on the pack. If the line is unreadable, brand only or null.
Never guess barcode digits. Always set barcode to null.
JSON only, no markdown and no reasoning:
{"kind":"personal_care|food|other|unknown","extractedIngredients":["Aqua","Glycerin"],"category":"serum|cream|cleanser|sunscreen|toner|oil|shampoo|conditioner|body|deodorant|makeup|mask|perfume|soap|toothpaste|null","productName":null,"barcode":null}
- kind: personal_care if this is self-care/cosmetic; food for edible products; other for household/non-care; unknown only if you cannot tell.
- extractedIngredients: readable INCI names in label order. Empty array if none, or if kind is not personal_care.
- category: one of the values above, or null. Hair, body, and hygiene cosmetics are valid. Never guess a dupe or a score.
- productName: visible brand + product line if readable, else null. Do not substitute a sibling product.
- barcode: always null. A separate decoder reads the bars.`;

function stripDataUrl(raw: string) {
  const comma = raw.indexOf(',');
  if (raw.startsWith('data:') && comma !== -1) {
    return raw.slice(comma + 1);
  }
  return raw;
}

function cleanBase64(raw: string) {
  let value = stripDataUrl(raw).replace(/\s/g, '');
  value = value.replace(/-/g, '+').replace(/_/g, '/');
  while (value.length % 4 !== 0) value += '=';
  return value;
}

function looksLikeGroqKey(key?: string) {
  return Boolean(key?.startsWith('gsk_'));
}

function isJpeg(buf: Buffer) {
  return buf.length > 3 && buf[0] === 0xff && buf[1] === 0xd8 && buf[2] === 0xff;
}

function isPng(buf: Buffer) {
  return buf.length > 8 && buf[0] === 0x89 && buf[1] === 0x50 && buf[2] === 0x4e && buf[3] === 0x47;
}

async function prepareImageForVision(raw: string): Promise<{ base64: string; mimeType: 'image/jpeg' }> {
  const b64 = cleanBase64(raw);
  const input = Buffer.from(b64, 'base64');
  if (input.length < 80) {
    throw new Error('empty image');
  }

  const sharp = (await import('sharp')).default;
  const jpeg = await sharp(input, { failOn: 'none' })
    .rotate()
    .resize(1024, 1024, { fit: 'inside', withoutEnlargement: true })
    .flatten({ background: '#ffffff' })
    .jpeg({ quality: 70, mozjpeg: true })
    .toBuffer();

  if (!isJpeg(jpeg) || jpeg.length < 200) {
    throw new Error('jpeg convert produced invalid bytes');
  }

  console.log(`Vision image prepared ${jpeg.length} bytes (source ${input.length}, jpeg=${isJpeg(input)} png=${isPng(input)})`);
  return { base64: jpeg.toString('base64'), mimeType: 'image/jpeg' };
}

async function callChatCompletions(params: {
  endpoint: string;
  apiKey: string;
  model: string;
  imageBase64: string;
  mimeType: string;
  label: string;
  groq?: boolean;
}) {
  const dataUrl = `data:${params.mimeType};base64,${params.imageBase64}`;
  const payload: Record<string, unknown> = {
    model: params.model,
    temperature: 0.1,
    max_completion_tokens: params.label === 'Groq' ? 4096 : 2000,
    messages: [
      {
        role: 'user',
        content: [
          { type: 'text', text: USER_INSTRUCTIONS },
          { type: 'image_url', image_url: { url: dataUrl } },
        ],
      },
    ],
  };
  if (params.groq) {
    payload.reasoning_effort = 'none';
    payload.reasoning_format = 'hidden';
    payload.response_format = { type: 'json_object' };
  }
  const response = await fetch(params.endpoint, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${params.apiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`${params.label} ${response.status}: ${body.slice(0, 400)}`);
  }

  const json = (await response.json()) as {
    choices?: { message?: { content?: string | null } }[];
  };
  return json.choices?.[0]?.message?.content ?? '';
}

async function callGroq(imageBase64: string, mimeType: string) {
  const key = env.GROQ_API_KEY || env.OPENAI_API_KEY;
  if (!key) throw new Error('Missing Groq API key');
  const model =
    env.VISION_MODEL.startsWith('qwen/') || env.VISION_MODEL.includes('llama')
      ? env.VISION_MODEL
      : 'qwen/qwen3.6-27b';
  const base = {
    endpoint: 'https://api.groq.com/openai/v1/chat/completions',
    apiKey: key,
    model,
    imageBase64,
    mimeType,
    label: 'Groq',
  } as const;
  try {
    return await callChatCompletions({ ...base, groq: true });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    if (!message.includes('Groq 400')) throw error;
    console.warn('Groq strict JSON rejected, retrying without reasoning extras', message.slice(0, 200));
    return callChatCompletions({ ...base, groq: false });
  }
}

async function callGemini(imageBase64: string, mimeType: string) {
  const model = env.VISION_MODEL.includes('gemini') ? env.VISION_MODEL : 'gemini-2.0-flash';
  const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${env.GEMINI_API_KEY}`;
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      contents: [
        {
          role: 'user',
          parts: [
            { text: USER_INSTRUCTIONS },
            { inlineData: { mimeType, data: imageBase64 } },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,
        responseMimeType: 'application/json',
      },
    }),
  });

  if (!response.ok) {
    const body = await response.text();
    throw new Error(`Gemini ${response.status}: ${body.slice(0, 400)}`);
  }

  const json = (await response.json()) as {
    candidates?: { content?: { parts?: { text?: string }[] } }[];
  };
  return json.candidates?.[0]?.content?.parts?.map((part) => part.text ?? '').join('') ?? '';
}

async function callOpenAi(imageBase64: string, mimeType: string) {
  if (!env.OPENAI_API_KEY) throw new Error('Missing OpenAI API key');
  return callChatCompletions({
    endpoint: 'https://api.openai.com/v1/chat/completions',
    apiKey: env.OPENAI_API_KEY,
    model: env.VISION_MODEL.includes('gpt') ? env.VISION_MODEL : 'gpt-4o',
    imageBase64,
    mimeType,
    label: 'OpenAI',
  });
}

function sanitizeExtract(parsed: z.infer<typeof visionExtractSchema>): VisionExtract {
  const rawList = parsed.extractedIngredients?.length ? parsed.extractedIngredients : parsed.ingredients ?? [];
  const category = (parsed.category ?? '').toLowerCase().trim();
  const allowed = new Set([
    'serum',
    'cream',
    'cleanser',
    'sunscreen',
    'toner',
    'oil',
    'shampoo',
    'conditioner',
    'body',
    'deodorant',
    'makeup',
    'mask',
    'perfume',
    'soap',
    'toothpaste',
  ]);
  const kindRaw = (parsed.kind ?? '').toLowerCase().trim();
  const kind =
    kindRaw === 'personal_care' || kindRaw === 'food' || kindRaw === 'other' || kindRaw === 'unknown'
      ? kindRaw
      : 'unknown';
  const ingredients =
    kind === 'food' || kind === 'other'
      ? []
      : rawList.map((item) => item.trim()).filter((item) => item.length >= 3).slice(0, 120);
  return {
    productName: parsed.productName?.slice(0, 80) ?? null,
    barcode: null,
    ingredients,
    category: allowed.has(category) ? category : null,
    kind,
  };
}

export async function extractFromPhoto(imageBase64: string): Promise<VisionExtract | null> {
  try {
    const prepared = await prepareImageForVision(imageBase64);
    let raw = '';
    const groqKey = env.GROQ_API_KEY || (looksLikeGroqKey(env.OPENAI_API_KEY) ? env.OPENAI_API_KEY : undefined);
    if (groqKey) {
      raw = await callGroq(prepared.base64, prepared.mimeType);
    } else if (env.GEMINI_API_KEY) {
      raw = await callGemini(prepared.base64, prepared.mimeType);
    } else if (env.OPENAI_API_KEY) {
      raw = await callOpenAi(prepared.base64, prepared.mimeType);
    } else {
      console.error('No GROQ_API_KEY, GEMINI_API_KEY, or OPENAI_API_KEY');
      return null;
    }

    console.log('Vision raw', raw.slice(0, 280));
    const jsonText = extractVisionJson(raw);
    if (!jsonText) {
      console.error('Vision JSON missing', raw.slice(0, 400));
      return null;
    }
    let parsedJson: unknown;
    try {
      parsedJson = JSON.parse(jsonText);
    } catch (error) {
      console.error('Vision JSON parse failed', error, jsonText.slice(0, 400));
      return null;
    }
    const parsed = visionExtractSchema.safeParse(parsedJson);
    if (!parsed.success) {
      console.error('Vision JSON failed Zod', parsed.error.flatten(), raw.slice(0, 300));
      return null;
    }
    const clean = sanitizeExtract(parsed.data);
    console.log('Vision extract', clean);
    return clean;
  } catch (error) {
    console.error('Vision extract failed', error);
    return null;
  }
}
