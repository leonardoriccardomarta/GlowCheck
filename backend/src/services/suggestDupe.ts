import { catalogPromptBlock, DUPE_CATALOG, type DupeEntry } from '../data/dupeCatalog';
import { dupeBlurb, dupePrice } from '../i18n/dupeBlurbs';
import { copy, normalizeLocale } from '../i18n/scoreCopy';
import { env } from '../config/env';
import type { MainGoal, SkinType } from './score';

export type SpendBand = 'low' | 'mid' | 'high';

export type DupeSuggestion = {
  id: string | null;
  brand: string;
  name: string;
  estimatedPrice: string;
  blurb: string;
  whyThis: string;
};

type SuggestInput = {
  productName: string | null;
  ingredients: string[];
  skinType: SkinType;
  mainGoal: MainGoal;
  spendBand?: SpendBand;
  locale?: string;
};

function priceOf(item: DupeEntry) {
  const n = Number(String(item.estimatedPrice).replace(/[^\d]/g, ''));
  return Number.isFinite(n) ? n : 15;
}

function extractJson(text: string) {
  const trimmed = text.trim();
  const fenced = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/);
  const body = fenced ? fenced[1].trim() : trimmed;
  const start = body.indexOf('{');
  const end = body.lastIndexOf('}');
  if (start !== -1 && end > start) return body.slice(start, end + 1);
  return body;
}

function blobOf(ingredients: string[], productName: string | null) {
  return `${productName ?? ''} ${ingredients.join(' ')}`.toLowerCase();
}

function detectKind(blob: string): string | null {
  if (
    /(gilette|gillette|schick|wilkinson|nivea men shave|shave|shaving|aftershave|after-shave|rasoi|rasatur|schiuma da barba|gel à raser|gel da barba|foam for (men|shave)|shaving foam|shaving gel|shaving cream)/.test(
      blob
    )
  ) {
    return 'shave';
  }
  if (/(shampoo|conditioner|hair mask|balsamo capelli)/.test(blob)) return 'hair';
  if (/(mascara|foundation|lipstick|concealer|eyeshadow|fondotinta)/.test(blob)) return 'makeup';
  if (/(spf|sunscreen|uvinul|tinosorb|zinc oxide|titanium dioxide|octinoxate|avobenzone)/.test(blob)) {
    return 'sunscreen';
  }
  if (
    /(cleans|face wash|micellar|syndet|gel nettoy|detergente viso|cleansing foam)/.test(blob) ||
    blob.includes('sodium laureth') ||
    blob.includes('coco-glucoside')
  ) {
    return 'cleanser';
  }
  if (/(cream|moistur|baume|balm|butter|crema|idratante viso|night cream|barrier)/.test(blob)) return 'cream';
  if (/(serum|ampoule|concentrate|siero)/.test(blob)) return 'serum';
  if (/(toner|essence)/.test(blob)) return 'toner';
  if (/(oil|huile|olio viso|squalane)/.test(blob)) return 'oil';
  if (ingredientsLookLikeSerum(blob)) return 'serum';
  return null;
}

function sameKindFamily(scanned: string | null, suggested: string | null) {
  if (!scanned || !suggested) return false;
  if (scanned === suggested) return true;
  if ((scanned === 'toner' && suggested === 'serum') || (scanned === 'serum' && suggested === 'toner')) return true;
  return false;
}

function ingredientsLookLikeSerum(blob: string) {
  const actives = ['niacinamide', 'hyaluron', 'retinol', 'ascorbic', 'azelaic', 'salicylic'];
  return actives.filter((item) => blob.includes(item)).length >= 1 && !blob.includes('cera alba');
}

function detectActives(blob: string) {
  const keys = [
    'niacinamide',
    'hyaluron',
    'ceramide',
    'squalane',
    'panthenol',
    'zinc',
    'glycerin',
    'salicylic',
    'retinol',
    'centella',
    'azelaic',
    'ascorbic',
    'urea',
    'snail',
  ];
  return keys.filter((item) => blob.includes(item));
}

export function catalogFallback(input: SuggestInput): DupeSuggestion | null {
  const blob = blobOf(input.ingredients, input.productName);
  const kind = detectKind(blob);
  if (!kind || kind === 'shave' || kind === 'hair' || kind === 'makeup') return null;
  const actives = detectActives(blob);

  const ranked = DUPE_CATALOG.map((item) => {
    if (!item.kinds.includes(kind) && !(kind === 'toner' && item.kinds.includes('serum'))) {
      return { item, score: -99 };
    }
    let score = 0;
    if (item.kinds.includes(kind)) score += 5;
    if (kind === 'toner' && item.kinds.includes('serum')) score += 3;
    if (item.matchesGoals.includes(input.mainGoal)) score += 3;
    for (const active of actives) {
      if (item.actives.some((entry) => active.includes(entry) || entry.includes(active))) score += 4;
    }
    if (input.skinType === 'oily') {
      if (item.actives.includes('niacinamide') || item.actives.includes('zinc')) score += 3;
      if (item.id === 'cerave-moisturizing-cream' || item.id === 'lrp-toleriane') score -= 6;
      if (kind !== 'cream' && item.kinds.includes('cream') && !item.actives.includes('niacinamide')) score -= 3;
    }
    if (input.skinType === 'dry') {
      if (item.id === 'cerave-foaming' || item.id === 'lrp-effaclar-gel') score -= 8;
      if (item.actives.includes('ceramide') || item.actives.includes('hyaluron')) score += 3;
    }
    if (input.skinType === 'sensitive') {
      if (item.id === 'lrp-toleriane' || item.id === 'simple-micellar' || item.id === 'cetaphil-gentle') score += 3;
    }
    const price = priceOf(item);
    if (input.spendBand === 'low' && price <= 12) score += 2;
    if (input.spendBand === 'low' && price >= 18) score -= 2;
    if (input.spendBand === 'high' && price >= 16) score += 1;
    const sameName = `${item.brand} ${item.name}`.toLowerCase();
    if (input.productName && sameName.includes(input.productName.toLowerCase().slice(0, 12))) score -= 8;
    return { item, score };
  })
    .filter((row) => row.score > 0)
    .sort((a, b) => b.score - a.score);

  const best = ranked[0]?.item;
  if (!best) return null;
  return toSuggestion(best, actives, input);
}

function toSuggestion(item: DupeEntry, actives: string[], input: SuggestInput): DupeSuggestion {
  const hit = actives.filter((active) => item.actives.some((entry) => active.includes(entry) || entry.includes(active)));
  const why =
    hit.length > 0
      ? copy(input.locale, 'dupe_same', {
          hit: hit.join(', '),
          skin: copy(input.locale, `skin_${input.skinType}`),
          goal: copy(input.locale, `goal_${input.mainGoal}`),
        })
      : copy(input.locale, 'dupe_generic', {
          skin: copy(input.locale, `skin_${input.skinType}`),
          goal: copy(input.locale, `goal_${input.mainGoal}`),
        });
  return {
    id: item.id,
    brand: item.brand,
    name: item.name,
    estimatedPrice: dupePrice(item.estimatedPrice, input.locale),
    blurb: dupeBlurb(input.locale, item.id, item.blurb),
    whyThis: why,
  };
}

async function askModel(input: SuggestInput): Promise<DupeSuggestion | null> {
  const key = env.GROQ_API_KEY || env.OPENAI_API_KEY;
  if (!key) return null;

  const scannedKind = detectKind(blobOf(input.ingredients, input.productName));
  if (!scannedKind || scannedKind === 'shave' || scannedKind === 'hair' || scannedKind === 'makeup') {
    return null;
  }

  const ingredients = input.ingredients.slice(0, 50).join(', ');
  const lang = ({ it: 'Italian', en: 'English', es: 'Spanish', fr: 'French', de: 'German' } as const)[normalizeLocale(input.locale)];
  const priceHint = normalizeLocale(input.locale) === 'en' ? '~$12' : '~12 €';
  const system = `You recommend one cheaper drugstore dupe for a scanned cosmetic.
Stay inside the same format only: serum vs serum, face cream vs moisturizer, cleanser vs cleanser, sunscreen vs sunscreen, toner vs toner or serum.
Never swap a razor, shaving foam, aftershave, shampoo, hair product, or makeup against a face cream or serum.
Gillette, Schick, Wilkinson and similar shave brands are not daily face moisturizers.
If the scanned item is not comparable skincare, or the category does not match, return {"skip":true}.
JSON only, no markdown.`;
  const prompt = `Suggest ONE cheaper, widely sold alternative for this scanned cosmetic.
Write blurb and whyThis in ${lang}. Use prices like ${priceHint}.
The scanned item can be any brand: Korean, pharmacy, supermarket, indie, luxury, or unknown. Fame does not matter.
Scanned product: ${input.productName ?? 'unknown brand'}
Skin: ${input.skinType}
Goal: ${input.mainGoal}
Spend band: ${input.spendBand ?? 'mid'}
INCI (readable): ${ingredients || 'none'}
Detected format: ${scannedKind}

Rules:
- Same format only. Serum vs serum. Face cream vs face moisturizer. Cleanser vs cleanser. Sunscreen vs sunscreen.
- Never swap a razor, shaving foam, aftershave, shampoo, or makeup against a face cream or serum.
- Gillette, Schick, Wilkinson and similar shave brands are not daily face moisturizers. If the scan is shave or not comparable skincare, return {"skip":true}.
- Pick a real cheaper product sold in drugstores / pharmacies / Olive Young / Stylevana / ordinary EU or US shops
- Match useful INCI jobs (niacinamide, hyaluronic, ceramide, BHA, cica, urea, etc.)
- Skin first, then goal. Oily: no heavy cream. Dry: no foaming cleanser. Sensitive: fragrance-light.
- Low spend: cheaper option
- Do not repeat the scanned product
- If a swap is pointless or the category does not match, return {"skip":true}
- JSON only, no markdown: {"brand":"","name":"","estimatedPrice":"${priceHint}","blurb":"","whyThis":"one sentence on which INCI this swaps"}

Known examples:
${catalogPromptBlock()}`;

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 8000);
  try {
    const response = await fetch('https://api.groq.com/openai/v1/chat/completions', {
      method: 'POST',
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${key}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'llama-3.1-8b-instant',
        temperature: 0.2,
        max_completion_tokens: 220,
        messages: [
          { role: 'system', content: system },
          { role: 'user', content: prompt },
        ],
      }),
    });
    if (!response.ok) {
      console.warn('Dupe model HTTP', response.status);
      return null;
    }
    const json = (await response.json()) as { choices?: { message?: { content?: string } }[] };
    const raw = json.choices?.[0]?.message?.content ?? '';
    const parsed = JSON.parse(extractJson(raw)) as {
      skip?: boolean;
      brand?: string;
      name?: string;
      estimatedPrice?: string;
      blurb?: string;
      whyThis?: string;
    };
    if (parsed.skip || !parsed.brand || !parsed.name) return null;
    const brand = String(parsed.brand).slice(0, 40);
    const name = String(parsed.name).slice(0, 80);
    const suggestedKind = detectKind(`${brand} ${name} ${parsed.blurb ?? ''}`);
    if (suggestedKind === 'shave' || suggestedKind === 'hair' || suggestedKind === 'makeup') return null;
    if (suggestedKind && !sameKindFamily(scannedKind, suggestedKind)) return null;
    const known = DUPE_CATALOG.find(
      (item) =>
        `${item.brand} ${item.name}`.toLowerCase() === `${brand} ${name}`.toLowerCase() ||
        item.name.toLowerCase() === name.toLowerCase()
    );
    if (known) {
      if (!known.kinds.includes(scannedKind) && !(scannedKind === 'toner' && known.kinds.includes('serum'))) {
        return null;
      }
      return toSuggestion(known, detectActives(blobOf(input.ingredients, input.productName)), input);
    }
    return {
      id: null,
      brand,
      name,
      estimatedPrice: dupePrice(String(parsed.estimatedPrice || '12'), input.locale),
      blurb: String(parsed.blurb || copy(input.locale, 'dupe_generic', {
        skin: copy(input.locale, `skin_${input.skinType}`),
        goal: copy(input.locale, `goal_${input.mainGoal}`),
      })).slice(0, 140),
      whyThis: String(parsed.whyThis || copy(input.locale, 'dupe_generic', {
        skin: copy(input.locale, `skin_${input.skinType}`),
        goal: copy(input.locale, `goal_${input.mainGoal}`),
      })).slice(0, 180),
    };
  } catch (error) {
    console.warn('Dupe model failed', error);
    return null;
  } finally {
    clearTimeout(timer);
  }
}

export async function suggestDupe(input: SuggestInput): Promise<DupeSuggestion | null> {
  if (input.ingredients.length < 1 && !input.productName) return null;
  const kind = detectKind(blobOf(input.ingredients, input.productName));
  if (!kind || kind === 'shave' || kind === 'hair' || kind === 'makeup') return null;
  const fromModel = await askModel(input);
  if (fromModel) return fromModel;
  return catalogFallback(input);
}
