import { isDupeId } from '../data/dupeCatalog';
import { copy } from '../i18n/scoreCopy';
import type { AnalyzeRequest, AnalyzeResponse } from '../schemas/analyze';
import { env } from '../config/env';
import { lookupBarcode } from './beautyFacts';
import { decodeBarcodeFromImage } from './decodeBarcode';
import { canonicalizeIngredients } from './matchIngredients';
import { isOutOfCategory } from './personalCare';
import { scoreFormula } from './score';
import { suggestDupe } from './suggestDupe';
import { extractFromPhoto } from './vision';

function empty(errorCode: AnalyzeResponse['errorCode'], headline: string): AnalyzeResponse {
  return {
    readable: false,
    productName: null,
    compatibilityScore: 0,
    statusBadge: 'CAUTION',
    headline,
    whyForYou: '',
    occlusionAlert: 'low',
    flaggedIngredients: [],
    ingredients: [],
    dupeId: null,
    dupe: null,
    errorCode,
  };
}

function mockResponse(req: AnalyzeRequest): AnalyzeResponse {
  const oily = req.profile.skinType === 'oily';
  const locale = req.profile.locale;
  return {
    readable: true,
    productName: req.barcode ? `Barcode ${req.barcode}` : 'Label sample (mock vision)',
    compatibilityScore: oily ? 41 : 78,
    statusBadge: oily ? 'NOT_IDEAL' : 'CAUTION',
    headline: oily ? copy(locale, 'mock_oily') : copy(locale, 'mock_hydrating'),
    occlusionAlert: oily ? 'high' : 'low',
    flaggedIngredients: [
      {
        name: 'Isopropyl Myristate',
        kind: 'warning',
        note: copy(locale, 'mock_occ'),
      },
      {
        name: 'Glycerin',
        kind: 'good',
        note: copy(locale, 'mock_glyc'),
      },
    ],
    dupeId: oily ? 'to-niacinamide-10' : 'to-ha-2',
    dupe: oily
      ? {
          id: 'to-niacinamide-10',
          brand: 'The Ordinary',
          name: 'Niacinamide 10% + Zinc 1%',
          estimatedPrice: '~$7',
          blurb: 'Drugstore niacinamide serum',
          whyThis: copy(locale, 'mock_why_oily'),
        }
      : {
          id: 'to-ha-2',
          brand: 'The Ordinary',
          name: 'Hyaluronic Acid 2% + B5',
          estimatedPrice: '~$8',
          blurb: 'Simple hydrating serum',
          whyThis: copy(locale, 'mock_why_hydration'),
        },
    whyForYou: copy(locale, 'mock_why'),
    ingredients: [
      { name: 'Isopropyl Myristate', tag: 'watch', note: copy(locale, 'note_occ_oily') },
      { name: 'Glycerin', tag: 'fit', note: copy(locale, 'note_humectant') },
    ],
    errorCode: null,
  };
}

function mergeIngredients(parts: string[][]) {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const list of parts) {
    for (const item of list) {
      const key = item.toLowerCase();
      if (seen.has(key) || item.length < 3) continue;
      seen.add(key);
      out.push(item);
    }
  }
  return out;
}

export async function analyzeProduct(req: AnalyzeRequest): Promise<AnalyzeResponse> {
  if (env.MOCK_VISION) {
    return mockResponse(req);
  }

  const locale = req.profile.locale;
  let productName: string | null = null;
  let format: string | null = null;
  let catalogSource: 'beauty' | 'food' | null = null;
  let visionKind: 'personal_care' | 'food' | 'other' | 'unknown' | null = null;
  const ingredientBuckets: string[][] = [];
  let barcode = req.barcode?.replace(/\D/g, '') || null;
  let source: 'barcode' | 'ocr' | 'barcode+ocr' = 'ocr';

  const reject = () => empty('NOT_COSMETIC', copy(locale, 'not_cosmetic'));

  if (!barcode && req.imageBase64) {
    barcode = await decodeBarcodeFromImage(req.imageBase64);
  }

  if (barcode) {
    const catalog = await lookupBarcode(barcode, locale);
    if (catalog?.source === 'food') {
      return reject();
    }
    if (catalog?.source === 'beauty') {
      catalogSource = 'beauty';
      productName = catalog.brand ? `${catalog.brand} ${catalog.name}` : catalog.name;
      format = catalog.category;
      if (catalog.ingredients.length >= 2) {
        ingredientBuckets.push(catalog.ingredients);
        source = 'barcode';
      }
    }
  }

  const catalogHit = ingredientBuckets.flat().length >= 2;

  if (req.imageBase64 && !catalogHit) {
    const vision = await extractFromPhoto(req.imageBase64);
    if (vision) {
      visionKind = vision.kind;
      if (vision.kind === 'food' || vision.kind === 'other') {
        return reject();
      }
      productName = productName || vision.productName;
      format = format || vision.category;
      if (vision.ingredients.length) ingredientBuckets.push(vision.ingredients);
      if (barcode) source = 'barcode+ocr';
    }
  }

  const ingredients = canonicalizeIngredients(mergeIngredients(ingredientBuckets));
  console.log('analyze result', {
    barcode,
    productName,
    format,
    source,
    catalogSource,
    visionKind,
    ingredientCount: ingredients.length,
    hasImage: Boolean(req.imageBase64),
  });

  if (
    isOutOfCategory({
      kind: visionKind,
      catalogSource,
      productName,
      ingredients,
    })
  ) {
    return reject();
  }

  if (ingredients.length >= 1) {
    const scored = scoreFormula({
      productName,
      ingredients,
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      locale,
    });
    const dupe = await suggestDupe({
      productName,
      ingredients,
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      spendBand: req.profile.spendBand,
      locale,
      format,
    });
    return {
      ...scored,
      dupe,
      dupeId: dupe?.id ?? (scored.dupeId && isDupeId(scored.dupeId) ? scored.dupeId : null),
    };
  }

  if (productName) {
    if (catalogSource !== 'beauty' && visionKind !== 'personal_care') {
      return reject();
    }
    const scored = scoreFormula({
      productName,
      ingredients: ['Aqua'],
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      locale,
    });
    const dupe = await suggestDupe({
      productName,
      ingredients: [],
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      spendBand: req.profile.spendBand,
      locale,
      format,
    });
    return {
      ...scored,
      headline: copy(locale, 'limited_headline'),
      whyForYou: copy(locale, 'limited_why'),
      flaggedIngredients: [],
      ingredients: [],
      dupe,
      dupeId: dupe?.id ?? (scored.dupeId && isDupeId(scored.dupeId) ? scored.dupeId : null),
    };
  }

  if (barcode && !req.imageBase64) {
    return empty('UNREADABLE', copy(locale, 'barcode_none'));
  }
  return empty('UNREADABLE', copy(locale, 'unreadable'));
}
