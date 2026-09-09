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
};

function digitsOnly(raw: string) {
  return raw.replace(/\D/g, '');
}

export function normalizeBarcode(raw: string) {
  let value = digitsOnly(raw);
  if (value.length === 12) value = `0${value}`;
  return value;
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

async function fetchOff(host: string, barcode: string) {
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
  ].join(',');
  const url = `https://${host}/api/v2/product/${barcode}.json?fields=${fields}`;
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'GlowCheck/1.0 (cosmetic compatibility; https://glow-check-rose.vercel.app)',
      Accept: 'application/json',
    },
  });
  if (!response.ok) return null;
  const json = (await response.json()) as { status?: number; product?: OffProduct };
  if (json.status !== 1 || !json.product) return null;
  return json.product;
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

export async function lookupBarcode(raw: string, locale?: string): Promise<CatalogProduct | null> {
  const barcode = normalizeBarcode(raw);
  if (barcode.length < 8 || barcode.length > 14) return null;

  try {
    const beauty = await fetchOff('world.openbeautyfacts.org', barcode);
    if (beauty) {
      const mapped = toCatalog(barcode, beauty, locale, 'beauty');
      if (mapped) return mapped;
    }

    const food = await fetchOff('world.openfoodfacts.org', barcode);
    if (!food) return null;
    const blob = `${food.categories ?? ''} ${(food.categories_tags ?? []).join(' ')} ${pickName(food, locale) ?? ''}`;
    const kind = classifyCatalogBlob(blob);
    const mapped = toCatalog(barcode, food, locale, kind === 'personal_care' ? 'beauty' : 'food');
    if (kind === 'personal_care' && mapped) {
      return { ...mapped, source: 'beauty' };
    }
    if (mapped) return { ...mapped, source: 'food' };
  } catch (error) {
    console.warn('Barcode lookup failed', error);
  }

  return null;
}
