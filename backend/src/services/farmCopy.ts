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
  const gap = best.score - worst.score;
  const breakout = (worst.id === 'oily' || worst.id === 'combination') && worst.score < 65;
  const make = (n: string) => {
    if (breakout) return `Is ${n} breaking you out? 👀`;
    if (gap >= 12) return `${n}: ${best.score} vs ${worst.score} depending on skin`;
    return `${n} on ${a} vs ${b} Skin 🚩`;
  };
  let title = make(name);
  if (wordCount(title) > 7) title = make(firstWord(name));
  return title;
}

function coverLine(name: string, best: FarmScoreRow, worst: FarmScoreRow) {
  const a = titleSkin(best);
  const b = titleSkin(worst);
  const shock = worst.score < 70 || best.score - worst.score >= 12;
  const make = (n: string) =>
    shock ? `Is ${n} actually safe for ${b}? 🚩` : `${n}: ${a} vs ${b} 👀`;
  let line = make(name);
  if (wordCount(line) > 8) line = make(firstWord(name));
  return line;
}

function caption(product: Pick<FarmHit, 'name' | 'brand'>, best: FarmScoreRow, worst: FarmScoreRow) {
  const a = titleSkin(best);
  const b = titleSkin(worst);
  const brandTag = productHash(viralName(product), product.brand);
  const skinTag = hashSkin(worst);
  const tail = ` on ${a} vs ${b} Skin 🚩 #${brandTag} #skintok #${skinTag}`;
  let name = viralName(product).replace(/\s+/g, ' ').trim();
  const len = (value: string) => [...value].length;
  while (name && len(name + tail) > 80) {
    const parts = name.split(' ');
    if (parts.length > 1) name = parts.slice(0, -1).join(' ');
    else {
      const room = Math.max(2, 80 - len(tail));
      name = [...name].slice(0, room).join('').trim();
      break;
    }
  }
  return `${name}${tail}`.replace(/\s+/g, ' ').trim();
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
    post_title: postTitle(name, best, worst),
    tiktok_caption: caption(product, best, worst),
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
