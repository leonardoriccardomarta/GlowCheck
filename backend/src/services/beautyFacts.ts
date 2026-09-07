import { parseIngredientText } from './score';

export type CatalogProduct = {
  barcode: string;
  name: string;
  brand: string | null;
  ingredients: string[];
};

type OffProduct = {
  product_name?: string;
  product_name_en?: string;
  brands?: string;
  ingredients_text?: string;
  ingredients_text_en?: string;
  ingredients?: { text?: string; id?: string }[];
};

function digitsOnly(raw: string) {
  return raw.replace(/\D/g, '');
}

export function normalizeBarcode(raw: string) {
  let value = digitsOnly(raw);
  if (value.length === 12) value = `0${value}`;
  return value;
}

async function fetchOff(host: string, barcode: string) {
  const url = `https://${host}/api/v2/product/${barcode}.json?fields=product_name,product_name_en,brands,ingredients_text,ingredients_text_en,ingredients`;
  const response = await fetch(url, {
    headers: {
      'User-Agent': 'GlowCheck/1.0 (cosmetic compatibility; local-dev)',
      Accept: 'application/json',
    },
  });
  if (!response.ok) return null;
  const json = (await response.json()) as { status?: number; product?: OffProduct };
  if (json.status !== 1 || !json.product) return null;
  return json.product;
}

function toCatalog(barcode: string, product: OffProduct): CatalogProduct | null {
  const name = product.product_name_en || product.product_name || null;
  const fromArray = (product.ingredients ?? [])
    .map((item) => item.text || item.id?.replace(/^en:/, '').replace(/-/g, ' ') || '')
    .filter(Boolean);
  const ingredients = fromArray.length
    ? fromArray
    : parseIngredientText(product.ingredients_text_en || product.ingredients_text);

  if (!name && ingredients.length < 2) return null;

  return {
    barcode,
    name: name ?? 'Scanned product',
    brand: product.brands?.split(',')[0]?.trim() ?? null,
    ingredients: ingredients.slice(0, 80),
  };
}

export async function lookupBarcode(raw: string): Promise<CatalogProduct | null> {
  const barcode = normalizeBarcode(raw);
  if (barcode.length < 8 || barcode.length > 14) return null;

  try {
    const beauty = await fetchOff('world.openbeautyfacts.org', barcode);
    if (beauty) {
      const mapped = toCatalog(barcode, beauty);
      if (mapped && mapped.ingredients.length >= 2) return mapped;
      if (mapped) {
        const food = await fetchOff('world.openfoodfacts.org', barcode);
        if (food) {
          const foodMapped = toCatalog(barcode, food);
          if (foodMapped && foodMapped.ingredients.length >= 2) {
            return {
              ...mapped,
              ingredients: foodMapped.ingredients,
              name: mapped.name || foodMapped.name,
            };
          }
        }
        return mapped;
      }
    }

    const food = await fetchOff('world.openfoodfacts.org', barcode);
    if (food) return toCatalog(barcode, food);
  } catch (error) {
    console.warn('Barcode lookup failed', error);
  }

  return null;
}
