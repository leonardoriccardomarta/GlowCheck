import { knownInciCount } from './matchIngredients';

export type CareKind = 'personal_care' | 'food' | 'other' | 'unknown';

const PERSONAL_CARE =
  /(cosmetic|skincare|skin-care|haircare|hair-care|shampoo|conditioner|shower-gel|body-wash|body-care|face-care|soap|soaps|deodorant|antiperspirant|perfume|fragrance|makeup|make-up|mascara|lipstick|sunscreen|sun-care|toothpaste|mouthwash|shaving|aftershave|after-shave|intimate|cleanser|serum|toner|moisturizer|moisturiser|lotion|cream|balm|oil-care|bath-oil|hand-wash|hand-soap|nail-polish|hair-dye|hair-color)/i;

const FOOD =
  /(en:foods|en:beverages|en:snacks|en:dairies|en:meals|en:chocolates|en:pastas|en:breads|en:cereals|en:spreads|en:cheeses|en:yogurts|en:meats|en:seafoods|en:frozen-foods|en:plant-based-foods|en:sweetened-beverages|valori nutrizionali|nutrition facts|kcal|ingredienti:\s*(zucchero|farina)|sugar,|wheat flour|skimmed milk|latte scremato|cocoa mass|pasta di semola|tomato puree|pomodoro)/i;

const HOUSEHOLD =
  /(en:cleaning|en:detergents|laundry|dish-soap|dishwasher|bleach|candeggina|detersivo|hypochlorite|all-purpose-cleaner|fabric-softener|ammorbidente)/i;

const FOOD_WORDS = [
  'zucchero',
  'sucrose',
  'sugar',
  'farina',
  'wheat flour',
  'wheat',
  'latte scremato',
  'skimmed milk',
  'cocoa mass',
  'pasta',
  'semola',
  'pomodoro',
  'tomato puree',
  'kcal',
  'valori nutrizionali',
  'nutrition facts',
  'carboidrati',
  'carbohydrate',
  'proteine',
  'sale iodato',
  'olio extravergine di oliva',
  'extra virgin olive oil',
];

export function classifyCatalogBlob(blob: string): CareKind {
  const text = blob.toLowerCase();
  if (!text.trim()) return 'unknown';
  if (PERSONAL_CARE.test(text)) return 'personal_care';
  if (HOUSEHOLD.test(text)) return 'other';
  if (FOOD.test(text)) return 'food';
  return 'unknown';
}

export function foodSignalCount(text: string): number {
  const hay = text.toLowerCase();
  let count = 0;
  for (const word of FOOD_WORDS) {
    if (hay.includes(word)) count += 1;
  }
  return count;
}

export function isOutOfCategory(input: {
  kind?: CareKind | null;
  catalogSource?: 'beauty' | 'food' | null;
  productName?: string | null;
  ingredients?: string[];
}): boolean {
  if (input.kind === 'food' || input.kind === 'other') return true;
  if (input.catalogSource === 'food') return true;
  if (input.catalogSource === 'beauty' || input.kind === 'personal_care') return false;

  const ingredients = input.ingredients ?? [];
  const inciHits = knownInciCount(ingredients);
  const blob = `${input.productName ?? ''} ${ingredients.join(' ')}`;
  const foodHits = foodSignalCount(blob);

  if (inciHits >= 3) return false;
  if (foodHits >= 3 && inciHits < 4) return true;
  if (foodHits >= 1 && inciHits === 0) return true;
  if (HOUSEHOLD.test(blob) && inciHits < 3) return true;
  return false;
}
