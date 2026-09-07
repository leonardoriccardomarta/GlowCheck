export type DupeGoal = 'pores' | 'hydration' | 'budget';

export type DupeEntry = {
  id: string;
  brand: string;
  name: string;
  estimatedPrice: string;
  matchesGoals: readonly DupeGoal[];
  actives: readonly string[];
  kinds: readonly string[];
  blurb: string;
};

export const DUPE_CATALOG: DupeEntry[] = [
  {
    id: 'to-niacinamide-10',
    brand: 'The Ordinary',
    name: 'Niacinamide 10% + Zinc 1%',
    estimatedPrice: '~$7',
    matchesGoals: ['pores', 'budget'],
    actives: ['niacinamide', 'zinc'],
    kinds: ['serum'],
    blurb: 'Drugstore niacinamide serum',
  },
  {
    id: 'to-ha-2',
    brand: 'The Ordinary',
    name: 'Hyaluronic Acid 2% + B5',
    estimatedPrice: '~$8',
    matchesGoals: ['hydration', 'budget'],
    actives: ['hyaluron', 'panthenol'],
    kinds: ['serum'],
    blurb: 'Simple hydrating serum',
  },
  {
    id: 'to-squalane',
    brand: 'The Ordinary',
    name: '100% Plant-Derived Squalane',
    estimatedPrice: '~$8',
    matchesGoals: ['hydration', 'budget'],
    actives: ['squalane'],
    kinds: ['oil', 'serum'],
    blurb: 'Light oil alternative to heavy butters',
  },
  {
    id: 'inkey-niacinamide',
    brand: 'The Inkey List',
    name: 'Niacinamide Serum',
    estimatedPrice: '~$8',
    matchesGoals: ['pores', 'budget'],
    actives: ['niacinamide'],
    kinds: ['serum'],
    blurb: 'Drugstore niacinamide option',
  },
  {
    id: 'inkey-ha',
    brand: 'The Inkey List',
    name: 'Hyaluronic Acid Serum',
    estimatedPrice: '~$8',
    matchesGoals: ['hydration', 'budget'],
    actives: ['hyaluron'],
    kinds: ['serum'],
    blurb: 'Budget hyaluronic serum',
  },
  {
    id: 'cerave-moisturizing-cream',
    brand: 'CeraVe',
    name: 'Moisturizing Cream',
    estimatedPrice: '~$16',
    matchesGoals: ['hydration'],
    actives: ['ceramide', 'glycerin', 'hyaluron'],
    kinds: ['cream'],
    blurb: 'Ceramide cream widely sold in drugstores',
  },
  {
    id: 'cerave-pm',
    brand: 'CeraVe',
    name: 'PM Facial Moisturizing Lotion',
    estimatedPrice: '~$15',
    matchesGoals: ['hydration', 'pores'],
    actives: ['niacinamide', 'ceramide'],
    kinds: ['cream'],
    blurb: 'Night lotion with niacinamide',
  },
  {
    id: 'cerave-foaming',
    brand: 'CeraVe',
    name: 'Foaming Facial Cleanser',
    estimatedPrice: '~$14',
    matchesGoals: ['pores', 'budget'],
    actives: ['ceramide', 'niacinamide'],
    kinds: ['cleanser'],
    blurb: 'Gentle drugstore cleanser',
  },
  {
    id: 'cerave-hydrating-cleanser',
    brand: 'CeraVe',
    name: 'Hydrating Facial Cleanser',
    estimatedPrice: '~$14',
    matchesGoals: ['hydration'],
    actives: ['ceramide', 'glycerin'],
    kinds: ['cleanser'],
    blurb: 'Non-foaming cleanser for dry skin',
  },
  {
    id: 'lrp-toleriane',
    brand: 'La Roche-Posay',
    name: 'Toleriane Sensitive',
    estimatedPrice: '~$20',
    matchesGoals: ['hydration'],
    actives: ['glycerin', 'ceramide'],
    kinds: ['cream'],
    blurb: 'Fragrance-light moisturizer for easily reactive skin',
  },
  {
    id: 'lrp-effaclar-gel',
    brand: 'La Roche-Posay',
    name: 'Effaclar Foaming Gel',
    estimatedPrice: '~$16',
    matchesGoals: ['pores'],
    actives: ['zinc'],
    kinds: ['cleanser'],
    blurb: 'Foaming gel often used on oily skin',
  },
  {
    id: 'gag-niacinamide',
    brand: 'Geek & Gorgeous',
    name: '10% Niacinamide',
    estimatedPrice: '~$12',
    matchesGoals: ['pores', 'budget'],
    actives: ['niacinamide'],
    kinds: ['serum'],
    blurb: 'Affordable niacinamide serum',
  },
  {
    id: 'cetaphil-gentle',
    brand: 'Cetaphil',
    name: 'Gentle Skin Cleanser',
    estimatedPrice: '~$12',
    matchesGoals: ['hydration', 'budget'],
    actives: ['glycerin'],
    kinds: ['cleanser'],
    blurb: 'Basic drugstore cleanser',
  },
  {
    id: 'simple-micellar',
    brand: 'Simple',
    name: 'Kind to Skin Micellar Water',
    estimatedPrice: '~$7',
    matchesGoals: ['budget', 'hydration'],
    actives: ['glycerin'],
    kinds: ['cleanser'],
    blurb: 'Fragrance-light micellar water',
  },
  {
    id: 'neutrogena-hydroboost',
    brand: 'Neutrogena',
    name: 'Hydro Boost Water Gel',
    estimatedPrice: '~$18',
    matchesGoals: ['hydration'],
    actives: ['hyaluron', 'glycerin'],
    kinds: ['cream'],
    blurb: 'Drugstore water gel moisturizer',
  },
  {
    id: 'to-salicylic',
    brand: 'The Ordinary',
    name: 'Salicylic Acid 2% Solution',
    estimatedPrice: '~$7',
    matchesGoals: ['pores', 'budget'],
    actives: ['salicylic'],
    kinds: ['serum'],
    blurb: 'Budget BHA for a cleaner feel',
  },
  {
    id: 'cosrx-snail',
    brand: 'COSRX',
    name: 'Advanced Snail 96 Mucin Power Essence',
    estimatedPrice: '~$19',
    matchesGoals: ['hydration'],
    actives: ['hyaluron', 'glycerin'],
    kinds: ['serum'],
    blurb: 'Widely sold hydrating essence',
  },
  {
    id: 'hada-labo-gokujyun',
    brand: 'Hada Labo',
    name: 'Gokujyun Hyaluronic Lotion',
    estimatedPrice: '~$15',
    matchesGoals: ['hydration', 'budget'],
    actives: ['hyaluron', 'glycerin'],
    kinds: ['serum', 'toner'],
    blurb: 'Pharmacy HA lotion',
  },
  {
    id: 'isntree-ha',
    brand: 'Isntree',
    name: 'Hyaluronic Acid Water Essence',
    estimatedPrice: '~$18',
    matchesGoals: ['hydration'],
    actives: ['hyaluron'],
    kinds: ['serum'],
    blurb: 'Light HA essence',
  },
  {
    id: 'purito-centella',
    brand: 'Purito',
    name: 'Centella Unscented Serum',
    estimatedPrice: '~$16',
    matchesGoals: ['hydration'],
    actives: ['centella', 'panthenol'],
    kinds: ['serum'],
    blurb: 'Fragrance-light cica serum',
  },
  {
    id: 'bioderma-sensibio',
    brand: 'Bioderma',
    name: 'Sensibio H2O',
    estimatedPrice: '~$12',
    matchesGoals: ['budget', 'hydration'],
    actives: ['glycerin'],
    kinds: ['cleanser'],
    blurb: 'Pharmacy micellar water',
  },
  {
    id: 'avene-tolerance',
    brand: 'Avène',
    name: 'Tolerance Control Soothing Cream',
    estimatedPrice: '~$22',
    matchesGoals: ['hydration'],
    actives: ['glycerin'],
    kinds: ['cream'],
    blurb: 'Minimal pharmacy cream for reactive skin',
  },
  {
    id: 'eucerin-urea',
    brand: 'Eucerin',
    name: 'UreaRepair Plus 5%',
    estimatedPrice: '~$16',
    matchesGoals: ['hydration'],
    actives: ['urea', 'ceramide'],
    kinds: ['cream'],
    blurb: 'Pharmacy urea cream for dry skin',
  },
  {
    id: 'boj-relief-sun',
    brand: 'Beauty of Joseon',
    name: 'Relief Sun : Rice + Probiotics',
    estimatedPrice: '~$16',
    matchesGoals: ['hydration', 'budget'],
    actives: ['niacinamide'],
    kinds: ['sunscreen'],
    blurb: 'Widely sold daily sunscreen',
  },
];

export type DupeId = (typeof DUPE_CATALOG)[number]['id'];

export function isDupeId(value: string): value is DupeId {
  return DUPE_CATALOG.some((item) => item.id === value);
}

export function getDupeById(id: string) {
  return DUPE_CATALOG.find((item) => item.id === id) ?? null;
}

export function catalogPromptBlock() {
  return DUPE_CATALOG.map((item) => `- ${item.brand} ${item.name} (${item.estimatedPrice})`).join('\n');
}
