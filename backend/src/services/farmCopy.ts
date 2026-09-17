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
  const brand = (product.brand || '').trim();
  const name = product.name.trim();
  if (brand && name.toLowerCase().startsWith(brand.toLowerCase())) return name;
  if (brand && name.length > 28) return `${brand} ${name.split(' ').slice(0, 3).join(' ')}`;
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
  let why = 'clean match, no watch flags';
  if (row.score >= 80 && row.watch === 0 && row.occlusionAlert === 'low') {
    why = row.id === 'dry' ? 'Pure barrier hydration, zero flags' : 'pure match, zero flags';
  } else if (row.id === 'oily' && (row.occlusionAlert !== 'low' || row.watch > 0 || row.score < 80)) {
    why = 'Heavy occlusives, risk of clogged pores';
  } else if (row.watch > 0) {
    why = `${row.watch} watch ingredients on this profile`;
  } else if (row.occlusionAlert === 'high') {
    why = 'heavy / occlusive feel vs this profile';
  }
  return `${row.label} Skin: ${row.score}/100 ${mark} ${why}`;
}

export function farmScript(product: Pick<FarmHit, 'name' | 'brand'>, scores: FarmScoreRow[]) {
  const ranked = [...scores].sort((a, b) => b.score - a.score);
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
  } else if (best.score >= 80 && worst.score >= 70) {
    post_title = `${name} actually scored ${best.score} 👀`;
    slide_1_cover = `${name}: ${best.score} on ${best.label.toLowerCase()} skin`;
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
    slide_4_cta: 'Check your shelf for free on glow-check.com 🧴',
    all_skins: scores.map((row) => ({
      skin_type: skinType(row),
      score: row.score,
      overlay_text: overlay(row),
    })),
  };
}
