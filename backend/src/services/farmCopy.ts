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
  if (core.length > 24) core = kept[0] || words[0] || '';
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

function skinHook(row: FarmScoreRow) {
  if (row.id === 'combination') return 'combo';
  if (row.id === 'oily') return 'oily';
  if (row.id === 'dry') return 'dry';
  return 'sensitive';
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

function coverLine(name: string, best: FarmScoreRow, worst: FarmScoreRow, version: 1 | 2) {
  if (version === 2) return `${name}. ${best.label} vs ${worst.label}. Same INCI.`;
  if (best.score - worst.score >= 12) return `${name}. Four skins. The scores split.`;
  return `${name}. I scanned it on 4 skin types.`;
}

function winLine(row: FarmScoreRow) {
  if (row.score >= 88) return `${row.label}: ${row.score}. This is who it loves.`;
  if (row.score >= 80) return `${row.label}: ${row.score}. Green — keep swiping.`;
  if (row.score >= 70) return `${row.label}: ${row.score}. Fine. Not a holy grail.`;
  return `${row.label}: ${row.score}. Best of the four. Still mid.`;
}

function lossLine(row: FarmScoreRow, best: FarmScoreRow) {
  const drop = best.score - row.score;
  if (row.score < 55) return `${row.label}: ${row.score}. Same bottle. I'd skip it.`;
  if (drop >= 12) return `${row.label}: ${row.score}. That's the drop.`;
  if (row.watch > 0) {
    return `${row.label}: ${row.score}. ${row.watch} flag${row.watch === 1 ? '' : 's'} on this skin.`;
  }
  return `${row.label}: ${row.score}. If this is your skin, pause.`;
}

function postTitle(name: string, best: FarmScoreRow, worst: FarmScoreRow, version: 1 | 2) {
  const gap = best.score - worst.score;
  const a = skinHook(best);
  const b = skinHook(worst);
  if (version === 2) {
    if (gap >= 10) return `${name} part 2: ${a} ${best.score} vs ${b} ${worst.score}`;
    return `${name} on ${a} vs ${b} skin. Same bottle`;
  }
  if (gap >= 12) return `${name}: ${best.score} on ${a} skin, ${worst.score} on ${b}`;
  if (worst.score < 60) return `${name} on ${b} skin? I scanned it`;
  if (best.score >= 80) return `${name} scored ${best.score} — then I changed skin type`;
  return `I scanned ${name} on 4 skins. Nobody got a 90`;
}

function caption(name: string, best: FarmScoreRow, worst: FarmScoreRow, version: 1 | 2, ht: string) {
  const gap = best.score - worst.score;
  const a = skinHook(best);
  const b = skinHook(worst);
  const lines: string[] = [];
  if (version === 1) {
    if (gap >= 12) {
      lines.push(`Same ${name}. ${best.score} on ${a} skin. ${worst.score} on ${b}.`);
      lines.push('One INCI. Two completely different matches.');
    } else if (best.score >= 80 && worst.score >= 70) {
      lines.push(`${name} looks like a holy grail in the comments.`);
      lines.push(`I scanned it anyway. ${best.score} vs ${worst.score} depending on your skin.`);
    } else if (worst.score < 60) {
      lines.push(`I wouldn't call ${name} a match for ${b} skin.`);
      lines.push(`${best.score} on ${a}. ${worst.score} on ${b}. Same bottle.`);
    } else {
      lines.push(`I scanned ${name} on 4 skin types. Nobody got a free 90.`);
      lines.push(`${a} ${best.score}. ${b} ${worst.score}.`);
    }
    lines.push("It's not a ranking. It's vs YOUR skin.");
    lines.push('Comment the bottle you want next — I scan the INCI.');
    lines.push('glow-check.com');
  } else {
    lines.push(`Part 2: ${name} on ${a} vs ${b} skin.`);
    lines.push(`${best.score} vs ${worst.score}. Same formula. Different match.`);
    if (gap >= 10) lines.push(`If you're ${b}, this is the slide people skip.`);
    else lines.push(`Save this if your skin is ${a} or ${b}.`);
    lines.push('Not sponsored. Just the INCI vs 4 skins.');
    lines.push('glow-check.com — drop yours in the comments.');
  }
  lines.push(`#skintok #skincare #${ht} #${hashSkin(worst)}`);
  return lines.join('\n\n');
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
  version: 1 | 2 = 1,
) {
  const ranked = pair ? [...pair].sort((a, b) => b.score - a.score) : [...scores].sort((a, b) => b.score - a.score);
  const best = ranked[0];
  const worst = ranked[ranked.length - 1];
  const name = viralName(product);
  const ht = tag(product.brand);
  const slide_1_cover = coverLine(name, best, worst, version);
  const overlayBest = winLine(best);
  const overlayWorst = lossLine(worst, best);

  return {
    post_title: postTitle(name, best, worst, version),
    tiktok_caption: caption(name, best, worst, version, ht),
    slide_1_cover,
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
    slide_copy: ['1. ' + slide_1_cover, '2. ' + overlayBest, '3. ' + overlayWorst].join('\n'),
    all_skins: scores.map((row) => ({
      skin_type: skinType(row),
      score: row.score,
      overlay_text: row.score >= (best.score + worst.score) / 2 ? winLine(row) : lossLine(row, best),
    })),
  };
}
