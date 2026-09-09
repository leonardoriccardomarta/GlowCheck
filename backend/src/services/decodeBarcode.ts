import { normalizeBarcode } from './beautyFacts';

function stripDataUrl(raw: string) {
  const comma = raw.indexOf(',');
  if (raw.startsWith('data:') && comma !== -1) return raw.slice(comma + 1);
  return raw;
}

function cleanBase64(raw: string) {
  let value = stripDataUrl(raw).replace(/\s/g, '');
  value = value.replace(/-/g, '+').replace(/_/g, '/');
  while (value.length % 4 !== 0) value += '=';
  return value;
}

type Zxing = typeof import('@zxing/library');

let cached: Zxing | null = null;

async function loadZxing(): Promise<Zxing | null> {
  if (cached) return cached;
  try {
    cached = await import('@zxing/library');
    return cached;
  } catch (error) {
    console.warn('Barcode decoder unavailable', error);
    return null;
  }
}

async function decodeBuffer(zxing: Zxing, pixels: Buffer, width: number, height: number) {
  const hints = new Map();
  hints.set(zxing.DecodeHintType.POSSIBLE_FORMATS, [
    zxing.BarcodeFormat.EAN_13,
    zxing.BarcodeFormat.EAN_8,
    zxing.BarcodeFormat.UPC_A,
    zxing.BarcodeFormat.UPC_E,
    zxing.BarcodeFormat.CODE_128,
    zxing.BarcodeFormat.ITF,
  ]);
  hints.set(zxing.DecodeHintType.TRY_HARDER, true);
  const reader = new zxing.MultiFormatReader();
  reader.setHints(hints);
  const source = new zxing.RGBLuminanceSource(Uint8ClampedArray.from(pixels), width, height);
  const bitmap = new zxing.BinaryBitmap(new zxing.HybridBinarizer(source));
  const result = reader.decode(bitmap);
  return result.getText();
}

async function raster(input: Buffer, rotate: number, maxEdge: number) {
  const sharp = (await import('sharp')).default;
  const { data, info } = await sharp(input, { failOn: 'none' })
    .rotate(rotate || undefined)
    .resize(maxEdge, maxEdge, { fit: 'inside', withoutEnlargement: false })
    .ensureAlpha()
    .raw()
    .toBuffer({ resolveWithObject: true });
  return { data, width: info.width, height: info.height };
}

export async function decodeBarcodeFromImage(imageBase64: string): Promise<string | null> {
  const work = decodeBarcodeInner(imageBase64);
  const timeout = new Promise<null>((resolve) => {
    setTimeout(() => resolve(null), 1200);
  });
  return Promise.race([work, timeout]);
}

async function decodeBarcodeInner(imageBase64: string): Promise<string | null> {
  const zxing = await loadZxing();
  if (!zxing) return null;
  try {
    const input = Buffer.from(cleanBase64(imageBase64), 'base64');
    if (input.length < 80) return null;
    const attempts = [
      { rotate: 0, maxEdge: 1400 },
      { rotate: 0, maxEdge: 900 },
      { rotate: 90, maxEdge: 1200 },
      { rotate: 270, maxEdge: 1200 },
    ];
    for (const attempt of attempts) {
      try {
        const { data, width, height } = await raster(input, attempt.rotate, attempt.maxEdge);
        const raw = await decodeBuffer(zxing, data, width, height);
        const barcode = normalizeBarcode(raw);
        if (barcode.length >= 8 && barcode.length <= 14) return barcode;
      } catch {
        // try next crop / rotation
      }
    }
  } catch (error) {
    console.warn('Barcode decode failed', error);
  }
  return null;
}
