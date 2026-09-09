import { isValidGtin, normalizeBarcode } from './beautyFacts';

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
type Band = 'full' | 'center' | 'bottom' | 'top';

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

function cropGray(buf: Buffer, width: number, height: number, top: number, bandH: number) {
  const y = Math.max(0, Math.min(height - 8, top));
  const h = Math.max(8, Math.min(height - y, bandH));
  const out = Buffer.alloc(width * h);
  for (let row = 0; row < h; row += 1) {
    buf.copy(out, row * width, (y + row) * width, (y + row) * width + width);
  }
  return { data: out, width, height: h };
}

function invertGray(buf: Buffer) {
  const out = Buffer.from(buf);
  for (let i = 0; i < out.length; i += 1) out[i] = 255 - out[i];
  return out;
}

async function raster(input: Buffer, rotate: number, maxEdge: number, band: Band, invert: boolean) {
  const sharp = (await import('sharp')).default;
  const { data, info } = await sharp(input, { failOn: 'none' })
    .rotate(rotate || undefined)
    .greyscale()
    .extend({
      top: 24,
      bottom: 24,
      left: 48,
      right: 48,
      background: '#ffffff',
    })
    .resize(maxEdge, maxEdge, { fit: 'inside', withoutEnlargement: false })
    .raw()
    .toBuffer({ resolveWithObject: true });

  let pixels = data;
  let { width, height } = info;
  if (band === 'center') {
    const cropped = cropGray(pixels, width, height, Math.floor(height * 0.28), Math.floor(height * 0.44));
    pixels = cropped.data;
    height = cropped.height;
  } else if (band === 'bottom') {
    const cropped = cropGray(pixels, width, height, Math.floor(height * 0.5), Math.ceil(height * 0.5));
    pixels = cropped.data;
    height = cropped.height;
  } else if (band === 'top') {
    const cropped = cropGray(pixels, width, height, 0, Math.floor(height * 0.5));
    pixels = cropped.data;
    height = cropped.height;
  }
  if (invert) pixels = invertGray(pixels);
  return { data: pixels, width, height };
}

function decodeBuffer(
  zxing: Zxing,
  pixels: Buffer,
  width: number,
  height: number,
  opts: { tryHarder: boolean; pure: boolean }
) {
  const hints = new Map();
  hints.set(zxing.DecodeHintType.POSSIBLE_FORMATS, [
    zxing.BarcodeFormat.EAN_13,
    zxing.BarcodeFormat.EAN_8,
    zxing.BarcodeFormat.UPC_A,
    zxing.BarcodeFormat.UPC_E,
    zxing.BarcodeFormat.CODE_128,
  ]);
  if (opts.tryHarder) hints.set(zxing.DecodeHintType.TRY_HARDER, true);
  if (opts.pure) hints.set(zxing.DecodeHintType.PURE_BARCODE, true);
  const source = new zxing.RGBLuminanceSource(Uint8ClampedArray.from(pixels), width, height);
  const reader = new zxing.MultiFormatReader();
  reader.setHints(hints);
  try {
    return reader.decode(new zxing.BinaryBitmap(new zxing.HybridBinarizer(source))).getText();
  } catch {
    return reader.decode(new zxing.BinaryBitmap(new zxing.GlobalHistogramBinarizer(source))).getText();
  }
}

export async function decodeBarcodeFromImage(imageBase64: string): Promise<string | null> {
  const work = decodeBarcodeInner(imageBase64);
  const timeout = new Promise<null>((resolve) => {
    setTimeout(() => resolve(null), 5000);
  });
  return Promise.race([work, timeout]);
}

async function decodeBarcodeInner(imageBase64: string): Promise<string | null> {
  const zxing = await loadZxing();
  if (!zxing) return null;
  try {
    const input = Buffer.from(cleanBase64(imageBase64), 'base64');
    if (input.length < 80) return null;
    const attempts: {
      rotate: number;
      maxEdge: number;
      band: Band;
      invert: boolean;
      tryHarder: boolean;
      pure: boolean;
    }[] = [
      { rotate: 0, maxEdge: 1600, band: 'full', invert: false, tryHarder: false, pure: true },
      { rotate: 0, maxEdge: 1600, band: 'full', invert: false, tryHarder: true, pure: false },
      { rotate: 0, maxEdge: 2000, band: 'full', invert: false, tryHarder: true, pure: true },
      { rotate: 90, maxEdge: 1600, band: 'full', invert: false, tryHarder: true, pure: true },
      { rotate: 270, maxEdge: 1600, band: 'full', invert: false, tryHarder: true, pure: true },
      { rotate: 0, maxEdge: 1600, band: 'center', invert: false, tryHarder: true, pure: true },
      { rotate: 0, maxEdge: 1600, band: 'center', invert: false, tryHarder: true, pure: false },
      { rotate: 180, maxEdge: 1400, band: 'full', invert: false, tryHarder: true, pure: true },
      { rotate: 0, maxEdge: 1600, band: 'full', invert: true, tryHarder: true, pure: true },
    ];
    for (const attempt of attempts) {
      try {
        const { data, width, height } = await raster(
          input,
          attempt.rotate,
          attempt.maxEdge,
          attempt.band,
          attempt.invert
        );
        const raw = decodeBuffer(zxing, data, width, height, {
          tryHarder: attempt.tryHarder,
          pure: attempt.pure,
        });
        const barcode = normalizeBarcode(raw);
        if (isValidGtin(barcode)) {
          console.log('Barcode decoded', barcode, attempt);
          return barcode;
        }
        if (barcode.length >= 8) {
          console.log('Barcode checksum rejected', barcode);
        }
      } catch {
        // next crop / rotation
      }
    }
    console.log('Barcode not found in photo');
  } catch (error) {
    console.warn('Barcode decode failed', error);
  }
  return null;
}
