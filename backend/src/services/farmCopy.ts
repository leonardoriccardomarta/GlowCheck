import type { FarmHit } from './farmCatalog';

export type FarmScoreRow = {
  id: string;
  label: string;
  score: number;
  punch: string;
  punchSub: string;
  watch: number;
  fit: number;
  listed: number;
  occlusionAlert: 'low' | 'medium' | 'high';
  watches: string[];
  fits?: string[];
};

const FILLER =
  /^(dermo-?pediatrics|moisturizer|moisturiser|lotion|cream|gel|serum|sunscreen|exfoliant|cleanser|toner|essence|fluid|milk|daily|gentle|advanced|original|the|new)$/i;

function viralName(product: { name: string; brand?: string | null }) {
  const brand = (product.brand || '').split(',')[0].trim();
  let name = (product.name || '').replace(/\s+/g, ' ').trim();
  name = name.replace(/\s*\([^)]*\)/g, '').replace(/\s+\d+(\.\d+)?\s*(ml|fl\.?\s*oz)\b.*/i, '');
  if (brand && name.toLowerCase().startsWith(brand.toLowerCase())) {
    name = name.slice(brand.length).trim().replace(/^[-–—]\s*/, '');
  }
  const act = name.match(/\d+\s*%\s*[A-Za-z][A-Za-z0-9\s-]{0,18}/);
  if (act) {
    const hook = act[0].replace(/\s+/g, ' ').trim();
    const shortBrand = brand.split(' ').slice(0, 2).join(' ');
    return shortBrand ? `${shortBrand} ${hook}` : hook;
  }
  const words = name.split(/\s+/).filter(Boolean);
  const kept = words.filter((word, i) => i === 0 || !FILLER.test(word));
  let core = kept.slice(0, 2).join(' ');
  if (!core) core = words.slice(0, 2).join(' ');
  if (core.length > 22) core = kept[0] || words[0] || '';
  if (brand && (!core || /^(moisturis?ing|hydrating|foaming|facial|body)\b/i.test(core))) {
    const shortBrand = brand.split(' ').slice(0, 2).join(' ');
    core = `${shortBrand} ${core}`.trim();
  }
  return core || brand || 'this formula';
}

function tag(brand: string | null) {
  const slug = (brand || 'skincare').toLowerCase().replace(/[^a-z0-9]+/g, '');
  return slug.slice(0, 18) || 'skincare';
}

function productHash(name: string, brand: string | null) {
  const fromName = name.toLowerCase().replace(/[^a-z0-9]+/g, '');
  if (fromName.length >= 4 && fromName.length <= 16) return fromName;
  return tag(brand);
}

function titleSkin(row: FarmScoreRow) {
  if (row.id === 'combination') return 'Combo';
  if (row.id === 'oily') return 'Oily';
  if (row.id === 'dry') return 'Dry';
  return 'Sensitive';
}

function hashSkin(row: FarmScoreRow) {
  if (row.id === 'combination') return 'combinationskin';
  if (row.id === 'oily') return 'oilyskin';
  if (row.id === 'dry') return 'dryskin';
  return 'sensitiveskin';
}

function skinType(row: FarmScoreRow) {
  if (row.id === 'oily') return 'Oily / Acne-Prone';
  return `${row.label} Skin`;
}

function wordCount(text: string) {
  return text.replace(/[🚩👀✅⚠️💀]/g, '').trim().split(/\s+/).filter(Boolean).length;
}

function firstWord(name: string) {
  return name.split(/\s+/)[0] || name;
}

function verdict(row: FarmScoreRow) {
  const blob = (row.watches || []).join(' ').toLowerCase();
  if (row.score >= 80 && row.watch === 0 && row.occlusionAlert !== 'high') {
    if (row.id === 'oily' || row.id === 'combination') return 'Clean formula, zero pore-cloggers';
    if (row.id === 'dry') return 'Clean barrier, zero flags';
    return 'Clean match, zero flags';
  }
  if (row.occlusionAlert === 'high' && (row.id === 'oily' || row.id === 'combination')) {
    return 'Heavy, pore-clogging risk';
  }
  if (row.watch > 0) {
    if (/fragrance|parfum|linalool|limonene|citronellol|geraniol/.test(blob)) {
      return `${row.watch} fragrance flags`;
    }
    if (/alcohol/.test(blob)) return `${row.watch} alcohol flags`;
    return `${row.watch} watch flags`;
  }
  if (row.score < 60) return 'Not a match here';
  return 'Not a perfect match';
}

function mark(score: number) {
  if (score >= 80) return '✅';
  if (score >= 60) return '⚠️';
  return '💀';
}

function scoreLine(row: FarmScoreRow) {
  return `${row.label}: ${row.score}/100 ${mark(row.score)} ${verdict(row)}`;
}

function postTitle(name: string, best: FarmScoreRow, worst: FarmScoreRow) {
  const a = titleSkin(best);
  const b = titleSkin(worst);
  const n = wordCount(`${name}: ${a} vs ${b} Skin`) > 7 ? firstWord(name) : name;
  return `${n}: ${a} vs ${b} Skin 🚩`;
}

function coverLine(name: string, _best: FarmScoreRow, _worst: FarmScoreRow) {
  return `Why your skin is still breaking out using ${name} 🚩`;
}

export function pickFarmFlag(scores: FarmScoreRow[], ingredients: string[] = []) {
  const watches = scores.flatMap((row) => row.watches || []);
  const prefer = watches.find((item) =>
    /alcohol|fragrance|parfum|linalool|limonene|citronellol|geraniol|essential/i.test(item),
  );
  if (prefer) return prefer;
  if (watches[0]) return watches[0];
  return (
    ingredients.find((item) => /alcohol|parfum|fragrance|linalool|limonene/i.test(item)) ||
    ingredients[0] ||
    'this ingredient'
  );
}

export function flagWhy(flag: string) {
  const low = flag.toLowerCase();
  if (/alcohol/.test(low)) {
    return 'It can strip the barrier and inflame sensitive or acne-prone skin.';
  }
  if (/fragrance|parfum|linalool|limonene|citronellol|geraniol/.test(low)) {
    return 'Fragrance allergens sit on the INCI and are a top irritation trigger.';
  }
  if (/dimethicone|isopropyl|myristate|palmitate/.test(low)) {
    return 'Occlusive / comedogenic risk if you clog easily.';
  }
  return 'Flagged on this INCI for irritation or pore-clogging risk.';
}

const SWIPE = {
  DEEP_DIVE: 'INCI Score on next slide ➡️',
  TIER_LIST_SWIPE: 'Worst to best inside ➡️',
  RED_FLAG_INCI: 'Full formula breakdown ➡️',
} as const;

function bulletWhy(row: FarmScoreRow) {
  const names = [...(row.watches || []), ...(row.fits || [])];
  const hit = names.find((item) =>
    /ceramide|niacinamide|salicylic|fragrance|dimethicone|alcohol|retin/i.test(item),
  );
  if (row.occlusionAlert === 'high') {
    return hit ? `${hit}: pore-clogging risk.` : 'Occlusive, comedogenic risk.';
  }
  if (row.watches?.length) {
    return `${hit || row.watches[0]} flagged for this skin.`;
  }
  if (row.score >= 80) {
    return hit ? `${hit} supports this profile.` : 'Barrier-friendly, low comedogenicity.';
  }
  return hit ? `${hit} on the INCI.` : 'Check comedogenicity vs your skin.';
}

function caption(product: Pick<FarmHit, 'name' | 'brand'>, best: FarmScoreRow, worst: FarmScoreRow) {
  let exact = (product.name || '').replace(/\s+/g, ' ').trim();
  exact = exact.replace(/\s*\([^)]*\)/g, '').replace(/\s+\d+(\.\d+)?\s*(ml|fl\.?\s*oz)\b.*/i, '');
  if (exact.length > 52) exact = viralName(product);
  const name = viralName(product);
  const hook = 'Breaking out or saving your barrier? We analyzed the full INCI formula.';
  const intro = `${hook} ${exact}.`;
  const bullets = [
    `• ${best.label}: ${best.score}/100. ${bulletWhy(best)}`,
    `• ${worst.label}: ${worst.score}/100. ${bulletWhy(worst)}`,
  ];
  const cta = 'Which product should we scan next? Drop it in the comments 👇';
  const hashes = [
    '#skintok',
    `#${productHash(name, product.brand)}`,
    '#poreclogging',
    `#${hashSkin(best)}`,
    `#${hashSkin(worst)}`,
    '#skincareingredients',
    `#${tag(product.brand)}`,
    '#glowcheck',
  ];
  const unique = [...new Set(hashes)].slice(0, 8);
  return [intro, '', ...bullets, '', cta, '', unique.join(' ')].join('\n');
}

export function farmWhy(row: FarmScoreRow) {
  if (row.watch === 0 && row.score >= 80) {
    return `No avoid flags vs ${row.label.toLowerCase()} skin.`;
  }
  if (row.occlusionAlert === 'high') {
    return `Heavier / occlusive feel vs ${row.label.toLowerCase()} skin.`;
  }
  if (row.watch > 0) {
    return `${row.watch} avoid flag${row.watch === 1 ? '' : 's'} vs ${row.label.toLowerCase()} skin.`;
  }
  return `Mostly compatible with ${row.label.toLowerCase()} skin.`;
}

export function farmPairs(scores: FarmScoreRow[]) {
  const ranked = [...scores].sort((a, b) => b.score - a.score);
  const v1: [FarmScoreRow, FarmScoreRow] = [ranked[0], ranked[ranked.length - 1]];
  const rest = ranked.slice(1, -1);
  const v2: [FarmScoreRow, FarmScoreRow] =
    rest.length >= 2 ? [rest[0], rest[1]] : [ranked[0], ranked[Math.min(1, ranked.length - 1)]];
  return { v1, v2 };
}

export function farmScript(
  product: Pick<FarmHit, 'name' | 'brand'>,
  scores: FarmScoreRow[],
  pair?: [FarmScoreRow, FarmScoreRow],
  _version: 1 | 2 = 1,
) {
  const ranked = pair ? [...pair].sort((a, b) => b.score - a.score) : [...scores].sort((a, b) => b.score - a.score);
  const best = ranked[0];
  const worst = ranked[ranked.length - 1];
  const name = viralName(product);
  const slide1 = coverLine(name, best, worst);
  const overlayBest = scoreLine(best);
  const overlayWorst = scoreLine(worst);

  return {
    format: 'DEEP_DIVE' as const,
    post_title: postTitle(name, best, worst),
    tiktok_caption: caption(product, best, worst),
    swipe_trigger: SWIPE.DEEP_DIVE,
    next_2: 'Next: ' + worst.label + ' Skin score ➡️',
    next_3: 'Next: Verdict & scan ➡️',
    slide_1_cover: slide1,
    slide_2_first_skin_type: {
      skin_type: skinType(best),
      score: best.score,
      overlay_text: overlayBest,
    },
    slide_3_second_skin_type: {
      skin_type: skinType(worst),
      score: worst.score,
      overlay_text: overlayWorst,
    },
    slide_4_cta: '',
    slide_copy: ['1. ' + slide1, '2. ' + overlayBest, '3. ' + overlayWorst].join('\n'),
    all_skins: scores.map((row) => ({
      skin_type: skinType(row),
      score: row.score,
      overlay_text: scoreLine(row),
    })),
  };
}

function shortPeer(product: Pick<FarmHit, 'name' | 'brand'>) {
  return viralName(product);
}

export function farmStory(input: {
  format?: 'DEEP_DIVE' | 'TIER_LIST_SWIPE' | 'RED_FLAG_INCI';
  product: Pick<FarmHit, 'name' | 'brand'>;
  products?: Pick<FarmHit, 'name' | 'brand'>[];
  scores: FarmScoreRow[];
  bestScores?: FarmScoreRow[];
  worstScores?: FarmScoreRow[];
  flag?: string;
  ingredients?: string[];
  version?: 1 | 2;
}) {
  const format = input.format || 'DEEP_DIVE';
  if (format === 'TIER_LIST_SWIPE') {
    const peers = (input.products || [input.product]).slice(0, 3);
    const names = peers.map(shortPeer);
    const bestScores = input.bestScores || input.scores;
    const worstScores = input.worstScores || input.scores;
    const best = [...bestScores].sort((a, b) => b.score - a.score)[0];
    const worst = [...worstScores].sort((a, b) => a.score - b.score)[0];
    const worstName = shortPeer(peers[peers.length - 1] || input.product);
    const bestName = shortPeer(peers[0] || input.product);
    const hook = 'One of these secretly clogs your pores 👀';
    const overlayWorst = `${worstName}: ${worst.score}/100 ${mark(worst.score)} ${verdict(worst)}`;
    const overlayBest = `${bestName}: ${best.score}/100 ${mark(best.score)} ${verdict(best)}`;
    const title = '3 Formulas: Safe or Breakout? 🚩';
    const intro = `Which of these 3 viral formulas clogs pores? We ranked the full INCI. ${names.join(' vs ')}.`;
    const bullets = [
      `• Worst: ${worstName} ${worst.score}/100. ${bulletWhy(worst)}`,
      `• Best: ${bestName} ${best.score}/100. ${bulletWhy(best)}`,
    ];
    const hashes = [
      '#skintok',
      '#poreclogging',
      '#skincareingredients',
      '#glowcheck',
      ...peers.map((item) => `#${tag(item.brand)}`),
    ];
    const caption = [
      intro,
      '',
      ...bullets,
      '',
      'Which product should we scan next? Drop it in the comments 👇',
      '',
      [...new Set(hashes)].slice(0, 8).join(' '),
    ].join('\n');
    return {
      format,
      post_title: title,
      tiktok_caption: caption,
      swipe_trigger: SWIPE.TIER_LIST_SWIPE,
      next_2: 'Next: Best formula ➡️',
      next_3: 'Next: Verdict & scan ➡️',
      slide_1_cover: hook,
      slide_2_first_skin_type: {
        skin_type: skinType(worst),
        score: worst.score,
        overlay_text: overlayWorst,
      },
      slide_3_second_skin_type: {
        skin_type: skinType(best),
        score: best.score,
        overlay_text: overlayBest,
      },
      slide_4_cta: '',
      slide_copy: ['1. ' + hook, '2. ' + overlayWorst, '3. ' + overlayBest].join('\n'),
      all_skins: [],
    };
  }
  if (format === 'RED_FLAG_INCI') {
    const flag = input.flag || pickFarmFlag(input.scores, input.ingredients || []);
    const pair = farmPairs(input.scores);
    const use = input.version === 2 ? pair.v2 : pair.v1;
    const ranked = [...use].sort((a, b) => b.score - a.score);
    const best = ranked[0];
    const worst = ranked[ranked.length - 1];
    const name = viralName(input.product);
    const hook = 'Stop using this if you see this ingredient 🛑';
    const overlayFlag = `${flag}: ${flagWhy(flag)}`;
    const overlayVerdict = scoreLine(worst);
    const titleBase = `Stop If You See ${flag}`;
    const title = wordCount(titleBase) > 7 ? `Stop If You See This 🛑` : `${titleBase} 🛑`;
    const intro = `This INCI flag sits in ${name}. Here's why it can inflame skin.`;
    const bullets = [
      `• Flag: ${flag}. ${flagWhy(flag)}`,
      `• Verdict: ${worst.label} ${worst.score}/100. ${bulletWhy(worst)}`,
    ];
    const hashes = [
      '#skintok',
      `#${productHash(name, input.product.brand)}`,
      '#poreclogging',
      '#skincareingredients',
      `#${tag(input.product.brand)}`,
      '#glowcheck',
    ];
    const caption = [
      intro,
      '',
      ...bullets,
      '',
      'Which product should we scan next? Drop it in the comments 👇',
      '',
      [...new Set(hashes)].slice(0, 8).join(' '),
    ].join('\n');
    return {
      format,
      post_title: title,
      tiktok_caption: caption,
      swipe_trigger: SWIPE.RED_FLAG_INCI,
      next_2: 'Next: Final score ➡️',
      next_3: 'Next: Verdict & scan ➡️',
      slide_1_cover: hook,
      slide_2_first_skin_type: {
        skin_type: flag,
        score: worst.score,
        overlay_text: overlayFlag,
      },
      slide_3_second_skin_type: {
        skin_type: skinType(worst),
        score: worst.score,
        overlay_text: overlayVerdict,
      },
      slide_4_cta: '',
      slide_copy: ['1. ' + hook, '2. ' + overlayFlag, '3. ' + overlayVerdict].join('\n'),
      all_skins: input.scores.map((row) => ({
        skin_type: skinType(row),
        score: row.score,
        overlay_text: scoreLine(row),
      })),
    };
  }
  return farmScript(input.product, input.scores, input.version === 2 ? farmPairs(input.scores).v2 : farmPairs(input.scores).v1, input.version || 1);
}
