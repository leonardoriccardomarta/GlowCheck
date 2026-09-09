import { parseIngredientText } from './score';
import { classifyCatalogBlob } from './personalCare';

export type CatalogProduct = {
  barcode: string;
  name: string;
  brand: string | null;
  ingredients: string[];
  category: string | null;
  source: 'beauty' | 'food';
};

export function barcodeVariants(raw: string): string[] {
  const barcode = normalizeBarcode(raw);
  const out = new Set<string>();
  if (barcode) out.add(barcode);
  if (barcode.length === 13) out.add(`0${barcode}`);
  if (barcode.length === 14 && barcode.startsWith('0')) out.add(barcode.slice(1));
  return [...out];
}

async function fetchOff(host: string, barcode: string, allTypes = false) {
  const fields = [
    'product_name',
    'product_name_en',
    'product_name_it',
    'product_name_fr',
    'product_name_es',
    'product_name_de',
    'brands',
    'ingredients_text',
    'ingredients_text_en',
    'ingredients_text_it',
    'ingredients_text_fr',
    'ingredients_text_es',
    'ingredients_text_de',
    'ingredients',
    'categories',
    'categories_tags',
    'product_type',
  ].join(',');
  const all = allTypes ? '&product_type=all' : '';
  const url = `https://${host}/api/v2/product/${barcode}.json?fields=${fields}${all}`;
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 2500);
  try {
    const response = await fetch(url, {
      signal: controller.signal,
      redirect: 'follow',
      headers: {
        'User-Agent': 'GlowCheck/1.0 (cosmetic compatibility; https://glow-check-rose.vercel.app)',
        Accept: 'application/json',
      },
    });
    if (!response.ok) return null;
    const json = (await response.json()) as { status?: number; product?: OffProduct };
    if (json.status !== 1 || !json.product) return null;
    return json.product;
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}

type OffProduct = {
  product_name?: string;
  product_name_en?: string;
  product_name_it?: string;
  product_name_fr?: string;
  product_name_es?: string;
  product_name_de?: string;
  brands?: string;
  ingredients_text?: string;
  ingredients_text_en?: string;
  ingredients_text_it?: string;
  ingredients_text_fr?: string;
  ingredients_text_es?: string;
  ingredients_text_de?: string;
  ingredients?: { text?: string; id?: string }[];
  categories?: string;
  categories_tags?: string[];
  product_type?: string;
};

function digitsOnly(raw: string) {
  return raw.replace(/\D/g, '');
}

export function normalizeBarcode(raw: string) {
  let value = digitsOnly(raw);
  // Code 128 / GS1 often prefixes AI 01 + GTIN-14 (0 + EAN-13).
  if (value.length === 16 && value.startsWith('01')) value = value.slice(2);
  if (value.length === 14 && value.startsWith('0')) value = value.slice(1);
  if (value.length === 12) value = `0${value}`;
  return value;
}

/** GS1 check digit for EAN-8 / UPC-A / EAN-13 / GTIN-14. */
export function isValidGtin(raw: string) {
  const value = normalizeBarcode(raw);
  if (![8, 12, 13, 14].includes(value.length)) return false;
  const body = value.slice(0, -1);
  const check = Number(value.slice(-1));
  let sum = 0;
  for (let i = 0; i < body.length; i += 1) {
    const digit = Number(body[body.length - 1 - i]);
    sum += i % 2 === 0 ? digit * 3 : digit;
  }
  return (10 - (sum % 10)) % 10 === check;
}

export function categoryFromOff(product: { categories?: string; categories_tags?: string[] } | null | undefined): string | null {
  const blob = `${product?.categories ?? ''} ${(product?.categories_tags ?? []).join(' ')}`.toLowerCase();
  if (!blob.trim()) return null;
  if (/(sunscreen|sun-protection|spf|uv-protection)/.test(blob)) return 'sunscreen';
  if (/(serum|serums|ampoule|concentrate)/.test(blob)) return 'serum';
  if (/(toner|essence|lotion-tonique)/.test(blob)) return 'toner';
  if (/(cleanser|cleansers|face-wash|micellar|syndet|facial-cleans)/.test(blob)) return 'cleanser';
  if (/(face-oil|facial-oil|body-oil)/.test(blob)) return 'oil';
  if (/(shampoo|shampoos|hair-wash)/.test(blob)) return 'shampoo';
  if (/(conditioner|conditioners|hair-conditioner|balsamo)/.test(blob)) return 'conditioner';
  if (/(deodorant|deodorants|antiperspirant)/.test(blob)) return 'deodorant';
  if (/(makeup|make-up|mascara|lipstick|foundation|concealer)/.test(blob)) return 'makeup';
  if (/(mask|masks|masque|peel-off)/.test(blob)) return 'mask';
  if (/(perfume|perfumes|eau-de-toilette|eau-de-parfum)/.test(blob)) return 'perfume';
  if (/(toothpaste|toothpastes|mouthwash)/.test(blob)) return 'toothpaste';
  if (/(body-wash|shower-gel|shower-gels|hand-wash|soap|soaps)/.test(blob)) return 'soap';
  if (/(body-care|body-lotion|body-cream|body-butter)/.test(blob)) return 'body';
  if (/(moistur|cream|creams|baume|balm|lotion|idratant)/.test(blob)) return 'cream';
  return null;
}

function pickName(product: OffProduct, locale?: string) {
  const map: Record<string, string | undefined> = {
    it: product.product_name_it,
    fr: product.product_name_fr,
    es: product.product_name_es,
    de: product.product_name_de,
    en: product.product_name_en,
  };
  return map[locale ?? ''] || product.product_name_en || product.product_name || null;
}

function pickIngredientsText(product: OffProduct, locale?: string) {
  const map: Record<string, string | undefined> = {
    it: product.ingredients_text_it,
    fr: product.ingredients_text_fr,
    es: product.ingredients_text_es,
    de: product.ingredients_text_de,
    en: product.ingredients_text_en,
  };
  return map[locale ?? ''] || product.ingredients_text_en || product.ingredients_text || '';
}

function toCatalog(barcode: string, product: OffProduct, locale: string | undefined, source: 'beauty' | 'food'): CatalogProduct | null {
  const name = pickName(product, locale);
  const fromArray = (product.ingredients ?? [])
    .map((item) => item.text || item.id?.replace(/^en:/, '').replace(/-/g, ' ') || '')
    .filter(Boolean);
  const ingredients = fromArray.length ? fromArray : parseIngredientText(pickIngredientsText(product, locale));

  if (!name && ingredients.length < 2) return null;

  return {
    barcode,
    name: name ?? 'Scanned product',
    brand: product.brands?.split(',')[0]?.trim() ?? null,
    ingredients: ingredients.slice(0, 80),
    category: categoryFromOff(product),
    source,
  };
}

function mapFetched(barcode: string, product: OffProduct, locale?: string): CatalogProduct | null {
  const type = (product.product_type ?? '').toLowerCase();
  const blob = `${product.categories ?? ''} ${(product.categories_tags ?? []).join(' ')} ${pickName(product, locale) ?? ''} ${type}`;
  if (type === 'food' || type === 'petfood') {
    const mapped = toCatalog(barcode, product, locale, 'food');
    return mapped ? { ...mapped, source: 'food' } : null;
  }
  if (type === 'beauty' || type === 'personal_care') {
    const mapped = toCatalog(barcode, product, locale, 'beauty');
    return mapped ? { ...mapped, source: 'beauty' } : null;
  }
  const kind = classifyCatalogBlob(blob);
  if (kind === 'food') return toCatalog(barcode, product, locale, 'food');
  if (kind === 'other') return null;
  const mapped = toCatalog(barcode, product, locale, 'beauty');
  return mapped ? { ...mapped, source: 'beauty' } : null;
}

export async function lookupBarcode(raw: string, locale?: string): Promise<CatalogProduct | null> {
  if (!isValidGtin(raw)) return null;
  const queries: { host: string; code: string; all: boolean }[] = [];
  for (const code of barcodeVariants(raw)) {
    queries.push({ host: 'world.openfoodfacts.org', code, all: true });
    queries.push({ host: 'world.openbeautyfacts.org', code, all: false });
    queries.push({ host: 'it.openbeautyfacts.org', code, all: false });
    queries.push({ host: 'world.openproductsfacts.org', code, all: false });
  }

  let named: CatalogProduct | null = null;
  try {
    for (const query of queries) {
      const product = await fetchOff(query.host, query.code, query.all);
      if (!product) continue;
      const mapped = mapFetched(query.code, product, locale);
      if (!mapped) continue;
      if (mapped.source === 'food') {
        if (!named) named = mapped;
        continue;
      }
      console.log('Catalog hit', query.host, query.code, mapped.ingredients.length, mapped.name);
      if (mapped.ingredients.length >= 2) return mapped;
      if (!named) named = mapped;
    }
  } catch (error) {
    console.warn('Barcode lookup failed', error);
  }

  return named;
}
