import { isDupeId } from '../data/dupeCatalog';
import type { AnalyzeRequest, AnalyzeResponse } from '../schemas/analyze';
import { env } from '../config/env';
import { lookupBarcode } from './beautyFacts';
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
  return {
    readable: true,
    productName: req.barcode ? `Barcode ${req.barcode}` : 'Label sample (mock vision)',
    compatibilityScore: oily ? 41 : 78,
    statusBadge: oily ? 'NOT_IDEAL' : 'CAUTION',
    headline: oily ? 'Potentially occlusive for oily skin' : 'Mostly compatible hydrating formula',
    occlusionAlert: oily ? 'high' : 'low',
    flaggedIngredients: [
      {
        name: 'Isopropyl Myristate',
        kind: 'warning',
        note: 'Often flagged as potentially occlusive on oily skin',
      },
      {
        name: 'Glycerin',
        kind: 'good',
        note: 'Humectant commonly used for hydration',
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
          whyThis: 'Mock swap for oily / pores.',
        }
      : {
          id: 'to-ha-2',
          brand: 'The Ordinary',
          name: 'Hyaluronic Acid 2% + B5',
          estimatedPrice: '~$8',
          blurb: 'Simple hydrating serum',
          whyThis: 'Mock swap for hydration.',
        },
    whyForYou: 'Demo score vs the skin profile you picked. Not a public Yuka rating.',
    ingredients: [
      { name: 'Isopropyl Myristate', tag: 'watch', note: 'Often noted as potentially occlusive on oily skin' },
      { name: 'Glycerin', tag: 'fit', note: 'Humectant commonly used for hydration' },
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

  let productName: string | null = null;
  const ingredientBuckets: string[][] = [];
  let barcode = req.barcode?.replace(/\D/g, '') || null;

  if (barcode) {
    const catalog = await lookupBarcode(barcode);
    if (catalog) {
      productName = catalog.brand ? `${catalog.brand} ${catalog.name}` : catalog.name;
      ingredientBuckets.push(catalog.ingredients);
    }
  }

  if (req.imageBase64 && ingredientBuckets.flat().length < 3) {
    const vision = await extractFromPhoto(req.imageBase64);
    if (vision) {
      productName = productName || vision.productName;
      ingredientBuckets.push(vision.ingredients);
      if (!barcode && vision.barcode) {
        barcode = vision.barcode;
        const catalog = await lookupBarcode(vision.barcode);
        if (catalog) {
          productName = productName || (catalog.brand ? `${catalog.brand} ${catalog.name}` : catalog.name);
          ingredientBuckets.push(catalog.ingredients);
        }
      }
    }
  } else if (req.imageBase64 && barcode && !productName) {
    const vision = await extractFromPhoto(req.imageBase64);
    if (vision?.productName) productName = vision.productName;
    if (vision?.ingredients.length) ingredientBuckets.push(vision.ingredients);
  }

  const ingredients = mergeIngredients(ingredientBuckets);
  console.log('analyze result', {
    barcode,
    productName,
    ingredientCount: ingredients.length,
    hasImage: Boolean(req.imageBase64),
  });

  if (ingredients.length >= 1) {
    const scored = scoreFormula({
      productName,
      ingredients,
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
    });
    const dupe = await suggestDupe({
      productName,
      ingredients,
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      spendBand: req.profile.spendBand,
    });
    return {
      ...scored,
      dupe,
      dupeId: dupe?.id ?? (scored.dupeId && isDupeId(scored.dupeId) ? scored.dupeId : null),
    };
  }

  if (productName) {
    const scored = scoreFormula({
      productName,
      ingredients: ['Aqua'],
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
    });
    const dupe = await suggestDupe({
      productName,
      ingredients: [],
      skinType: req.profile.skinType,
      mainGoal: req.profile.mainGoal,
      spendBand: req.profile.spendBand,
    });
    return {
      ...scored,
      headline: 'Product found, limited INCI on the label',
      whyForYou: 'Name matched, but the full ingredient list was not readable. Photograph the INCI block for a complete score.',
      flaggedIngredients: [],
      ingredients: [],
      dupe,
      dupeId: dupe?.id ?? (scored.dupeId && isDupeId(scored.dupeId) ? scored.dupeId : null),
    };
  }

  if (barcode && !req.imageBase64) {
    return empty('UNREADABLE', 'Barcode found, no formula in catalog');
  }
  return empty('UNREADABLE', 'Could not read barcode or INCI');
}
