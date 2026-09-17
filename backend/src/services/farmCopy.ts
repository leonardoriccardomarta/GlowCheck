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

function shortName(product: { name: string; brand?: string | null }) {
  let name = product.name.replace(/\s+/g, ' ').trim();
  name = name.replace(/\s*\([^)]*\)/g, '').replace(/\s+\d+\s*ml\b.*/i, '');
  const brand = (product.brand || '').split(',')[0].trim();
  if (brand && !name.toLowerCase().includes(brand.toLowerCase().split(' ')[0].toLowerCase()) && name.length > 28) {
    name = `${brand} ${name}`;
  }
  const words = name.split(' ');
  if (words.length > 5) name = words.slice(0, 5).join(' ');
  return name.length > 36 ? `${name.slice(0, 34)}…` : name;
}

function tag(brand: string | null) {
  const slug = (brand || 'skincare').toLowerCase().replace(/[^a-z0-9]+/g, '');
  return slug.slice(0, 18) || 'skincare';
}

function skinType(row: FarmScoreRow) {
  if (row.id === 'oily') return 'Oily / Acne-Prone';
  return `${row.label} Skin`;
}

function overlay(row: FarmScoreRow) {
  const mark = row.score >= 80 ? '✅' : row.score >= 60 ? '⚠️' : '💀';
  let why = 'Clean match, zero flags';
  if (row.score >= 80 && row.watch === 0 && row.occlusionAlert === 'low') {
    why = row.id === 'dry' ? 'Pure barrier hydration, zero flags' : 'Clean match, zero flags';
  } else if (row.occlusionAlert === 'high' && (row.id === 'oily' || row.id === 'combination')) {
    why = 'Heavy occlusives, risk of clogged pores';
  } else if (row.watch > 0) {
    why = `${row.watch} watch ingredient${row.watch === 1 ? '' : 's'} on this profile`;
  } else if (row.score < 80) {
    why = `Not a perfect match for ${row.label.toLowerCase()} skin`;
  }
  return `${row.label} Skin: ${row.score}/100 ${mark} ${why}`;
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
) {
  const ranked = pair ? [...pair].sort((a, b) => b.score - a.score) : [...scores].sort((a, b) => b.score - a.score);
  const best = ranked[0];
  const worst = ranked[ranked.length - 1];
  const name = shortName(product);
  const ht = tag(product.brand);
  const gap = best.score - worst.score;

  let post_title = `I scanned ${name}`;
  let slide_1_cover = `Same formula. Four skins. 👀`;
  if (gap >= 12) {
    post_title = `${name} on ${worst.label} Skin? 🚩`;
    slide_1_cover = `Is ${name} actually a match for ${worst.label.toLowerCase()} skin? 🚩👀`;
  } else if (best.score >= 80) {
    post_title = `${name} scored ${best.score} 👀`;
    slide_1_cover = `Same ${name}. ${best.score} vs ${worst.score} depending on your skin.`;
  } else if (worst.score < 60) {
    post_title = `${name} is not a universal 90`;
    slide_1_cover = `I scanned ${name}. It wasn’t a 90 on every skin.`;
  }

  const tiktok_caption = [
    gap >= 12
      ? `Same ${name}. ${best.score} on ${best.label.toLowerCase()} skin. ${worst.score} on ${worst.label.toLowerCase()}.`
      : `I scanned the exact INCI of ${name} across 4 skin types.`,
    'Not a ranking. It’s vs YOUR skin.',
    'Drop yours, I’ll test it next 👇',
    'glow-check.com',
    `#skintok #${ht} #oilyskin #dryskin #skincarecheck #inci`,
  ].join(' ');

  return {
    post_title,
    tiktok_caption,
    slide_1_cover,
    slide_2_first_skin_type: {
      skin_type: skinType(best),
      score: best.score,
      overlay_text: overlay(best),
    },
    slide_3_second_skin_type: {
      skin_type: skinType(worst),
      score: worst.score,
      overlay_text: overlay(worst),
    },
    slide_4_cta: '',
    all_skins: scores.map((row) => ({
      skin_type: skinType(row),
      score: row.score,
      overlay_text: overlay(row),
    })),
  };
}
