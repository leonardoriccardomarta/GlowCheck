import { parseIngredientText, scoreFormula, type MainGoal, type SkinType } from './score';
import { lookupBarcode, isValidGtin } from './beautyFacts';

export type FarmHit = {
  name: string;
  brand: string | null;
  imageUrl: string | null;
  ingredients: string[];
  barcode: string | null;
};

export const FARM_PROFILES = [
  { id: 'dry', skinType: 'dry' as SkinType, mainGoal: 'hydration' as MainGoal, label: 'Dry' },
  { id: 'oily', skinType: 'oily' as SkinType, mainGoal: 'pores' as MainGoal, label: 'Oily' },
  { id: 'combination', skinType: 'combination' as SkinType, mainGoal: 'pores' as MainGoal, label: 'Combination' },
  { id: 'sensitive', skinType: 'sensitive' as SkinType, mainGoal: 'hydration' as MainGoal, label: 'Sensitive' },
] as const;

const UA = 'GlowCheck/1.0 (tiktok farm; https://www.glow-check.com)';

function pickImage(product: { image_front_url?: string; image_url?: string; image_front_small_url?: string }) {
  return product.image_front_url || product.image_url || product.image_front_small_url || null;
}

function ingredientsOf(product: {
  ingredients_text?: string;
  ingredients_text_en?: string;
  ingredients?: { text?: string; id?: string }[];
}) {
  const fromArray = (product.ingredients ?? [])
    .map((item) => item.text || item.id?.replace(/^en:/, '').replace(/-/g, ' ') || '')
    .filter(Boolean);
  if (fromArray.length) return fromArray.slice(0, 80);
  return parseIngredientText(product.ingredients_text_en || product.ingredients_text || '').slice(0, 80);
}

async function searchHost(host: string, terms: string): Promise<FarmHit[]> {
  const url =
    `https://${host}/cgi/search.pl?action=process&search_simple=1&json=1&page_size=8&sort_by=unique_scans_n` +
    `&search_terms=${encodeURIComponent(terms)}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 4000);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      headers: { 'User-Agent': UA, Accept: 'application/json' },
    });
    if (!response.ok) return [];
    const json = (await response.json()) as {
      products?: {
        code?: string;
        product_name?: string;
        product_name_en?: string;
        brands?: string;
        image_front_url?: string;
        image_url?: string;
        image_front_small_url?: string;
        ingredients_text?: string;
        ingredients_text_en?: string;
        ingredients?: { text?: string; id?: string }[];
      }[];
    };
    return (json.products ?? [])
      .map((product) => {
        const name = product.product_name_en || product.product_name || '';
        const ingredients = ingredientsOf(product);
        if (!name && ingredients.length < 2) return null;
        return {
          name: name || 'Scanned product',
          brand: product.brands?.split(',')[0]?.trim() || null,
          imageUrl: pickImage(product),
          ingredients,
          barcode: product.code || null,
        } satisfies FarmHit;
      })
      .filter((item): item is FarmHit => Boolean(item));
  } catch {
    return [];
  } finally {
    clearTimeout(timer);
  }
}

async function lookupWithImage(barcode: string): Promise<FarmHit | null> {
  const base = await lookupBarcode(barcode, 'en');
  if (!base) return null;
  const hosts = ['world.openbeautyfacts.org', 'world.openfoodfacts.org', 'it.openbeautyfacts.org'];
  let imageUrl: string | null = null;
  for (const host of hosts) {
    const url = `https://${host}/api/v2/product/${barcode}.json?fields=image_front_url,image_url,image_front_small_url`;
    try {
      const response = await fetch(url, { headers: { 'User-Agent': UA, Accept: 'application/json' } });
      if (!response.ok) continue;
      const json = (await response.json()) as { product?: { image_front_url?: string; image_url?: string; image_front_small_url?: string } };
      imageUrl = json.product ? pickImage(json.product) : null;
      if (imageUrl) break;
    } catch {
      /* next host */
    }
  }
  return {
    name: base.name,
    brand: base.brand,
    imageUrl,
    ingredients: base.ingredients,
    barcode: base.barcode,
  };
}

export async function farmLookup(query: string): Promise<FarmHit[]> {
  const q = query.trim();
  if (q.length < 2) return [];
  if (isValidGtin(q)) {
    const hit = await lookupWithImage(q);
    return hit ? [hit] : [];
  }
  const [beauty, food] = await Promise.all([
    searchHost('world.openbeautyfacts.org', q),
    searchHost('world.openfoodfacts.org', q),
  ]);
  const seen = new Set<string>();
  const out: FarmHit[] = [];
  for (const hit of [...beauty, ...food]) {
    const key = `${hit.barcode ?? ''}::${hit.name.toLowerCase()}`;
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(hit);
  }
  return out.slice(0, 10);
}

export function farmScores(input: { name: string; ingredients: string[] }) {
  return FARM_PROFILES.map((profile) => {
    const scored = scoreFormula({
      productName: input.name,
      ingredients: input.ingredients,
      skinType: profile.skinType,
      mainGoal: profile.mainGoal,
      locale: 'en',
    });
    const watch = scored.ingredients.filter((item) => item.tag === 'watch').length;
    const fit = scored.ingredients.filter((item) => item.tag === 'fit').length;
    const listed = scored.ingredients.filter((item) => item.tag === 'listed').length;
    return {
      id: profile.id,
      label: profile.label,
      score: scored.compatibilityScore,
      headline: scored.headline,
      punch:
        scored.compatibilityScore >= 80
          ? `GREAT MATCH (${scored.compatibilityScore}%)`
          : scored.compatibilityScore >= 60
            ? `GOOD MATCH (${scored.compatibilityScore}%)`
            : `REPLACE IT (${scored.compatibilityScore}%)`,
      punchSub:
        scored.compatibilityScore >= 60
          ? `Compatible with ${profile.label} skin`
          : `A poor fit for ${profile.label} skin`,
      watch,
      fit,
      listed,
      occlusionAlert: scored.occlusionAlert,
    };
  });
}

const IMAGE_HOSTS = [
  'images.openfoodfacts.org',
  'images.openbeautyfacts.org',
  'static.openfoodfacts.org',
  'static.openbeautyfacts.org',
  'world.openfoodfacts.org',
  'world.openbeautyfacts.org',
  'it.openbeautyfacts.org',
];

export function allowedFarmImage(raw: string) {
  try {
    const parsed = new URL(raw);
    if (parsed.protocol !== 'https:') return false;
    const host = parsed.hostname.toLowerCase();
    return IMAGE_HOSTS.some((allowed) => host === allowed || host.endsWith(`.${allowed}`));
  } catch {
    return false;
  }
}
