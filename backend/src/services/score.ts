export type SkinType = 'oily' | 'dry' | 'combination' | 'sensitive';
export type MainGoal = 'pores' | 'hydration' | 'budget';
export type StatusBadge = 'COMPATIBLE' | 'CAUTION' | 'NOT_IDEAL';
export type OcclusionAlert = 'low' | 'medium' | 'high';

export type FlaggedIngredient = {
  name: string;
  kind: 'warning' | 'good';
  note: string;
};

export type ScoreInput = {
  productName: string | null;
  ingredients: string[];
  skinType: SkinType;
  mainGoal: MainGoal;
};

export type IngredientLine = {
  name: string;
  tag: 'watch' | 'fit' | 'listed';
  note: string | null;
};

export type ScoreResult = {
  readable: true;
  productName: string | null;
  compatibilityScore: number;
  statusBadge: StatusBadge;
  headline: string;
  whyForYou: string;
  occlusionAlert: OcclusionAlert;
  flaggedIngredients: FlaggedIngredient[];
  ingredients: IngredientLine[];
  dupeId: string | null;
  errorCode: null;
};

const OCCLUSIVE = [
  'isopropyl myristate',
  'isopropyl palmitate',
  'isopropyl isostearate',
  'myristyl myristate',
  'myristyl lactate',
  'butyl stearate',
  'isopropyl lanolate',
  'octyl palmitate',
  'ethylhexyl palmitate',
  'decyl oleate',
  'hexyl laurate',
  'oleyl alcohol',
  'cocos nucifera',
  'coconut oil',
  'coconut alkanes',
  'cocoa butter',
  'theobroma cacao',
  'butyrospermum',
  'shea butter',
  'lanolin',
  'petrolatum',
  'mineral oil',
  'paraffinum liquidum',
  'wheat germ oil',
  'algae extract',
  'orbignya',
  'babassu',
];

const HUMECTANTS = [
  'glycerin',
  'glycerol',
  'hyaluronic',
  'sodium hyaluronate',
  'panthenol',
  'urea',
  'sodium pca',
  'butylene glycol',
  'propanediol',
  'pentylene glycol',
  'betaine',
  'trehalose',
  'polyglutamic',
  'aloe barbadensis',
  'honey',
];

const LIGHT_EMOLLIENTS = ['squalane', 'ceramide', 'cholesterol', 'phytosphingosine'];

const PORE_ACTIVES = ['niacinamide', 'zinc pca'];

const ACIDS = ['salicylic', 'glycolic', 'lactic acid', 'mandelic', 'azelaic', 'gluconolactone'];

const RETINOIDS = ['retinol', 'retinal', 'retinyl', 'adapalene', 'tretinoin'];

const CICA = ['centella', 'madecassoside', 'asiaticoside', 'madecassic'];

const FRAGRANCE = [
  'parfum',
  'fragrance',
  'limonene',
  'linalool',
  'citronellol',
  'geraniol',
  'eugenol',
  'cinnamal',
  'benzyl alcohol',
  'hexyl cinnamal',
  'lavandula',
  'citrus aurantium',
  'mentha piperita',
  'eucalyptus',
  'melaleuca',
  'essential oil',
];

const HARSH_ALCOHOL = ['alcohol denat', 'alcohol denatured', 'sd alcohol', 'isopropyl alcohol'];

const GOAL_LABEL: Record<MainGoal, string> = {
  pores: 'less clogging feel',
  hydration: 'hydration',
  budget: 'drugstore swaps',
};

const SKIN_LABEL: Record<SkinType, string> = {
  oily: 'oily',
  dry: 'dry',
  combination: 'combination',
  sensitive: 'sensitive',
};

function normalizeList(ingredients: string[]) {
  const seen = new Set<string>();
  const out: string[] = [];
  for (const raw of ingredients) {
    const name = raw
      .replace(/\s+/g, ' ')
      .replace(/^[\d.\s%-]+/, '')
      .trim();
    if (name.length < 3) continue;
    const key = name.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(name);
  }
  return out.slice(0, 120);
}

function includesAny(haystack: string, needles: string[]) {
  return needles.filter((item) => haystack.includes(item));
}

export function parseIngredientText(text: string | null | undefined) {
  if (!text) return [];
  return normalizeList(
    text
      .replace(/\n/g, ',')
      .split(/[,;•|/]+/)
      .map((item) => item.trim())
  );
}

function occlusiveWeight(skin: SkinType, goal: MainGoal) {
  let weight = 5;
  if (skin === 'oily') weight = 12;
  else if (skin === 'combination') weight = 8;
  else if (skin === 'sensitive') weight = 5;
  else if (skin === 'dry') weight = 3;

  if (goal === 'pores' && skin !== 'dry') weight += 2;
  return weight;
}

function humectantCredit(skin: SkinType, goal: MainGoal) {
  if (skin === 'dry') return { per: 6, cap: 18 };
  if (skin === 'sensitive') return { per: 4, cap: 12 };
  if (skin === 'combination') return { per: 4, cap: 12 };
  if (skin === 'oily' && goal === 'hydration') return { per: 3, cap: 10 };
  return { per: 2, cap: 8 };
}

function hitsName(name: string, list: string[]) {
  return list.some((item) => name.includes(item));
}

export function scoreFormula(input: ScoreInput): ScoreResult {
  const ingredients = normalizeList(input.ingredients);
  const blob = ingredients.join(' | ').toLowerCase();
  const skin = input.skinType;
  const goal = input.mainGoal;

  const occlusiveHits = includesAny(blob, OCCLUSIVE);
  const humectantHits = includesAny(blob, HUMECTANTS);
  const fragranceHits = includesAny(blob, FRAGRANCE);
  const alcoholHits = includesAny(blob, HARSH_ALCOHOL);
  const poreActiveHits = includesAny(blob, PORE_ACTIVES);
  const emollientHits = includesAny(blob, LIGHT_EMOLLIENTS);
  const acidHits = includesAny(blob, ACIDS);
  const retinoidHits = includesAny(blob, RETINOIDS);
  const cicaHits = includesAny(blob, CICA);

  const occW = occlusiveWeight(skin, goal);
  const hum = humectantCredit(skin, goal);

  let score = 72;
  score -= occlusiveHits.length * occW;
  score += Math.min(hum.cap, humectantHits.length * hum.per);
  if (skin === 'oily' || (skin === 'combination' && goal === 'pores')) {
    score += Math.min(6, poreActiveHits.length * 3);
    score += Math.min(6, acidHits.length * 3);
  }
  if (skin === 'dry' || skin === 'sensitive') {
    score += Math.min(6, emollientHits.length * 3);
    score += Math.min(4, cicaHits.length * 2);
  }
  if (skin === 'sensitive') {
    score -= fragranceHits.length * 6;
    score -= acidHits.length * 3;
    score -= retinoidHits.length * 4;
  }
  if (skin === 'dry' || skin === 'sensitive') score -= alcoholHits.length * 8;
  else if (skin === 'combination' && goal === 'hydration') score -= alcoholHits.length * 3;
  score = Math.max(8, Math.min(96, Math.round(score)));

  const oilyLike = skin === 'oily' || (skin === 'combination' && goal === 'pores');
  const occlusionAlert: OcclusionAlert =
    occlusiveHits.length >= 3 || (oilyLike && occlusiveHits.length >= 2)
      ? 'high'
      : occlusiveHits.length >= 1
        ? 'medium'
        : 'low';

  const statusBadge: StatusBadge = score >= 70 ? 'COMPATIBLE' : score >= 48 ? 'CAUTION' : 'NOT_IDEAL';

  const flagged: FlaggedIngredient[] = [];
  const lines: IngredientLine[] = ingredients.map((name) => {
    const n = name.toLowerCase();

    if (hitsName(n, OCCLUSIVE)) {
      const note =
        skin === 'oily'
          ? 'Often noted as potentially occlusive on oily, congestion-prone skin'
          : skin === 'combination'
            ? 'Richer texture. Can feel heavy on an oily T-zone'
            : skin === 'dry'
              ? 'Richer texture. Usually acceptable on dry skin unless it feels greasy'
              : 'Richer texture. Watch if the skin is easily reactive';
      flagged.push({ name, kind: 'warning', note });
      return { name, tag: 'watch' as const, note };
    }

    if (hitsName(n, HARSH_ALCOHOL) && (skin === 'dry' || skin === 'sensitive')) {
      const note = 'Drying alcohol on the label. Often a miss for dry or easily reactive skin';
      flagged.push({ name, kind: 'warning', note });
      return { name, tag: 'watch' as const, note };
    }

    if (hitsName(n, FRAGRANCE)) {
      if (skin === 'sensitive') {
        const note = 'Fragrance or essential-oil related INCI. Often noted on easily reactive skin';
        flagged.push({ name, kind: 'warning', note });
        return { name, tag: 'watch' as const, note };
      }
      return { name, tag: 'listed' as const, note: 'Fragrance material. Watched only on a sensitive profile' };
    }

    if (hitsName(n, RETINOIDS)) {
      if (skin === 'sensitive') {
        const note = 'Retinoid on the label. Often a lot for easily reactive skin';
        flagged.push({ name, kind: 'warning', note });
        return { name, tag: 'watch' as const, note };
      }
      const note = 'Retinoid on the label. Cosmetic use only, not a prescription read';
      flagged.push({ name, kind: 'good', note });
      return { name, tag: 'fit' as const, note };
    }

    if (hitsName(n, ACIDS)) {
      if (skin === 'sensitive') {
        const note = 'Exfoliating acid. Can feel sharp on easily reactive skin';
        flagged.push({ name, kind: 'warning', note });
        return { name, tag: 'watch' as const, note };
      }
      if (skin === 'oily' || goal === 'pores') {
        const note = 'Exfoliating acid on the label. Often used for a cleaner feel on oily skin';
        flagged.push({ name, kind: 'good', note });
        return { name, tag: 'fit' as const, note };
      }
      return { name, tag: 'listed' as const, note: 'Exfoliating acid. Fine if the skin already tolerates acids' };
    }

    if (hitsName(n, CICA)) {
      const note = 'Centella / cica on the label. Often used to support easily reactive skin';
      flagged.push({ name, kind: 'good', note });
      return { name, tag: 'fit' as const, note };
    }

    if (hitsName(n, PORE_ACTIVES) || n.includes('niacinamide')) {
      const note =
        skin === 'oily' || goal === 'pores'
          ? 'Niacinamide on the label. Often used for oil-control feel'
          : 'Niacinamide on the label. Common supporting active';
      flagged.push({ name, kind: 'good', note });
      return { name, tag: 'fit' as const, note };
    }

    if (hitsName(n, LIGHT_EMOLLIENTS)) {
      if (skin === 'oily' && goal !== 'hydration') {
        return {
          name,
          tag: 'listed' as const,
          note: 'Light emollient. Fine in a lotion, not a reason to pick a heavy cream',
        };
      }
      const note = 'Barrier / slip ingredient that usually supports dry or easily reactive skin';
      flagged.push({ name, kind: 'good', note });
      return { name, tag: 'fit' as const, note };
    }

    if (hitsName(n, HUMECTANTS)) {
      const note =
        skin === 'oily'
          ? 'Light hydrator on the label. Still useful on oily skin'
          : 'Functional hydrating ingredient on the label';
      flagged.push({ name, kind: 'good', note });
      return { name, tag: 'fit' as const, note };
    }

    return { name, tag: 'listed' as const, note: null };
  });

  const whyForYou = `This is not a public Yuka score. It reads the INCI vs your ${SKIN_LABEL[skin]} skin and ${GOAL_LABEL[goal]}, any brand.${
    skin === 'oily' && goal === 'hydration'
      ? ' Heavy creams stay flagged first, even if you asked for hydration.'
      : skin === 'dry' && goal === 'pores'
        ? ' Occlusives are lighter flags here than on oily skin.'
        : ''
  }`;

  let headline = 'Mostly compatible with your profile';
  if (statusBadge === 'COMPATIBLE') {
    if (skin === 'dry' || goal === 'hydration') headline = 'Looks aligned with hydration on your skin';
    else if (skin === 'oily' || goal === 'pores') headline = 'Looks aligned with an oily profile';
    else headline = 'Mostly compatible with your profile';
  } else if (statusBadge === 'CAUTION') {
    if (skin === 'oily' && occlusiveHits.length > 0) headline = 'Potentially occlusive for oily skin';
    else if (skin === 'sensitive' && (fragranceHits.length > 0 || acidHits.length > 0)) {
      headline = 'Mixed match vs a sensitive profile';
    } else headline = 'Mixed match vs your profile';
  } else if (skin === 'oily' && occlusiveHits.length > 0) {
    headline = 'Heavy feel vs oily skin profile';
  } else if (skin === 'sensitive') {
    headline = 'Not the closest match for sensitive skin';
  } else {
    headline = 'Not the closest match for you';
  }

  return {
    readable: true,
    productName: input.productName,
    compatibilityScore: score,
    statusBadge,
    headline,
    whyForYou,
    occlusionAlert,
    flaggedIngredients: flagged.slice(0, 10),
    ingredients: lines,
    dupeId: null,
    errorCode: null,
  };
}
