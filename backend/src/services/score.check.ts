import { scoreFormula } from './score';
import { catalogFallback } from './suggestDupe';

function assert(cond: unknown, message: string) {
  if (!cond) throw new Error(message);
}

const heavy = ['Aqua', 'Isopropyl Myristate', 'Cocos Nucifera Oil', 'Glycerin'];

const oilyPores = scoreFormula({
  productName: 'Rich cream',
  ingredients: heavy,
  skinType: 'oily',
  mainGoal: 'pores',
});
assert(oilyPores.compatibilityScore < 55, `oily+pores should drop on occlusives, got ${oilyPores.compatibilityScore}`);
assert(
  oilyPores.ingredients.find((item) => item.name.toLowerCase().includes('myristate'))?.tag === 'watch',
  'IPM must be watch on oily'
);
assert(oilyPores.headline.toLowerCase().includes('oily') || oilyPores.headline.toLowerCase().includes('occlusive'), oilyPores.headline);

const dryHydration = scoreFormula({
  productName: 'Rich cream',
  ingredients: heavy,
  skinType: 'dry',
  mainGoal: 'hydration',
});
assert(
  dryHydration.compatibilityScore > oilyPores.compatibilityScore + 10,
  `dry+hydration must score well above oily on the same cream (${dryHydration.compatibilityScore} vs ${oilyPores.compatibilityScore})`
);

const oilyHydration = scoreFormula({
  productName: 'Rich cream',
  ingredients: heavy,
  skinType: 'oily',
  mainGoal: 'hydration',
});
assert(
  oilyHydration.compatibilityScore < dryHydration.compatibilityScore - 8,
  `oily+hydration must still penalize heavy cream (${oilyHydration.compatibilityScore} vs dry ${dryHydration.compatibilityScore})`
);
assert(oilyHydration.whyForYou.toLowerCase().includes('heavy'), oilyHydration.whyForYou);

const combo = scoreFormula({
  productName: 'HA serum',
  ingredients: ['Aqua', 'Glycerin', 'Sodium Hyaluronate'],
  skinType: 'combination',
  mainGoal: 'hydration',
});
assert(combo.compatibilityScore >= 70, `combo+HA should be compatible, got ${combo.compatibilityScore}`);
assert(combo.ingredients.every((item) => item.tag !== 'watch'), 'light HA serum should have no watch on combo');

const sensitive = scoreFormula({
  productName: 'Scented lotion',
  ingredients: ['Aqua', 'Parfum', 'Glycerin'],
  skinType: 'sensitive',
  mainGoal: 'hydration',
});
assert(sensitive.ingredients.find((item) => item.name === 'Parfum')?.tag === 'watch', 'Parfum watch on sensitive');

const oilyFragrance = scoreFormula({
  productName: 'Scented lotion',
  ingredients: ['Aqua', 'Parfum', 'Niacinamide'],
  skinType: 'oily',
  mainGoal: 'pores',
});
assert(oilyFragrance.ingredients.find((item) => item.name === 'Parfum')?.tag === 'listed', 'Parfum listed on oily');
assert(oilyFragrance.ingredients.find((item) => item.name === 'Niacinamide')?.tag === 'fit', 'Niacinamide fit on oily');

const dryAlcohol = scoreFormula({
  productName: 'Toner',
  ingredients: ['Aqua', 'Alcohol Denat'],
  skinType: 'dry',
  mainGoal: 'hydration',
});
assert(dryAlcohol.ingredients.find((item) => item.name.includes('Alcohol'))?.tag === 'watch', 'alcohol watch on dry');

const oilyDupe = catalogFallback({
  productName: 'Luxury Pore Serum',
  ingredients: ['Aqua', 'Niacinamide', 'Zinc PCA', 'Glycerin'],
  skinType: 'oily',
  mainGoal: 'pores',
  spendBand: 'low',
});
assert(oilyDupe, 'oily dupe missing');
assert(
  oilyDupe && /niacinamide/i.test(`${oilyDupe.brand} ${oilyDupe.name} ${oilyDupe.whyThis}`) && !/moisturizing cream/i.test(oilyDupe.name),
  `oily+pores should get niacinamide, not a heavy cream (${oilyDupe?.brand} ${oilyDupe?.name})`
);

const dryDupe = catalogFallback({
  productName: 'Night Cream',
  ingredients: ['Aqua', 'Ceramide NP', 'Glycerin', 'Sodium Hyaluronate'],
  skinType: 'dry',
  mainGoal: 'hydration',
  spendBand: 'mid',
});
assert(dryDupe, 'dry dupe missing');
assert(
  dryDupe && !/foaming|effaclar/i.test(`${dryDupe.brand} ${dryDupe.name}`),
  `dry+hydration should not get a foaming cleanser (${dryDupe?.brand} ${dryDupe?.name})`
);
assert(
  dryDupe && /cerave|eucerin|av[eè]ne|hada labo|moistur|urea|hyaluron/i.test(`${dryDupe.brand} ${dryDupe.name}`),
  `dry night cream should stay a cream/HA swap (${dryDupe?.brand} ${dryDupe?.name})`
);

const unknownBrand = scoreFormula({
  productName: 'No-name 수분 세럼',
  ingredients: ['Aqua', 'Glycerin', 'Niacinamide', 'Centella Asiatica Extract', 'Parfum'],
  skinType: 'sensitive',
  mainGoal: 'hydration',
});
assert(unknownBrand.ingredients.find((item) => item.name === 'Parfum')?.tag === 'watch', 'unknown brand still flags fragrance on sensitive');
assert(unknownBrand.ingredients.find((item) => item.name.includes('Centella'))?.tag === 'fit', 'cica is fit even if the brand is unknown');
assert(unknownBrand.whyForYou.toLowerCase().includes('any brand'), unknownBrand.whyForYou);

const oilyAcid = scoreFormula({
  productName: 'Random BHA toner',
  ingredients: ['Aqua', 'Salicylic Acid', 'Niacinamide'],
  skinType: 'oily',
  mainGoal: 'pores',
});
assert(oilyAcid.ingredients.find((item) => item.name.includes('Salicylic'))?.tag === 'fit', 'BHA fit on oily');
assert(oilyAcid.compatibilityScore >= 70, `oily+BHA should be compatible, got ${oilyAcid.compatibilityScore}`);

console.log('score + dupe checks passed', {
  oilyPores: oilyPores.compatibilityScore,
  oilyHydration: oilyHydration.compatibilityScore,
  dryHydration: dryHydration.compatibilityScore,
  combo: combo.compatibilityScore,
  oilyDupe: `${oilyDupe?.brand} ${oilyDupe?.name}`,
  dryDupe: `${dryDupe?.brand} ${dryDupe?.name}`,
  unknown: unknownBrand.compatibilityScore,
  oilyAcid: oilyAcid.compatibilityScore,
});
