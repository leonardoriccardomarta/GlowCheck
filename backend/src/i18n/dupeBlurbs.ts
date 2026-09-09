import type { AppLocale } from './scoreCopy';

const it: Record<string, string> = {
  'to-niacinamide-10': 'Siero alla niacinamide da drugstore',
  'to-ha-2': 'Siero idratante semplice',
  'to-squalane': 'Olio leggero al posto di burri pesanti',
  'inkey-niacinamide': 'Alternativa drugstore alla niacinamide',
  'inkey-ha': 'Siero all’acido ialuronico economico',
  'cerave-moisturizing-cream': 'Crema alle ceramidi, facile da trovare in farmacia',
  'cerave-pm': 'Crema notte con niacinamide',
  'cerave-foaming': 'Detergente drugstore delicato',
  'cerave-hydrating-cleanser': 'Detergente non schiumogeno per pelle secca',
  'lrp-toleriane': 'Idratante poco profumato, spesso in farmacia',
  'lrp-effaclar-gel': 'Gel detergente spesso usato su pelle grassa',
  'gag-niacinamide': 'Siero alla niacinamide accessibile',
  'cetaphil-gentle': 'Detergente drugstore basico',
  'simple-micellar': 'Acqua micellare poco profumata',
  'neutrogena-hydroboost': 'Gel idratante da drugstore',
  'to-salicylic': 'BHA economico per una pelle più pulita',
  'cosrx-snail': 'Essenza idratante molto diffusa',
  'hada-labo-gokujyun': 'Lozione HA da farmacia',
  'isntree-ha': 'Essenza HA leggera',
  'purito-centella': 'Siero cica poco profumato',
  'bioderma-sensibio': 'Acqua micellare da farmacia',
  'avene-tolerance': 'Crema minima da farmacia per pelle reattiva',
  'eucerin-urea': 'Crema alla urea da farmacia per pelle secca',
  'boj-relief-sun': 'Solare quotidiano molto diffuso',
  'loreal-elseve-hyaluron': 'Shampoo idratante da supermercato',
  'ducray-extra-doux': 'Shampoo delicato da farmacia',
  'vichy-dercos-oil-control': 'Shampoo sebo-regolatore da farmacia',
};

const en: Record<string, string> = {
  'to-niacinamide-10': 'Drugstore niacinamide serum',
  'to-ha-2': 'Simple hydrating serum',
  'to-squalane': 'Light oil instead of heavy butters',
  'inkey-niacinamide': 'Drugstore niacinamide option',
  'inkey-ha': 'Budget hyaluronic serum',
  'cerave-moisturizing-cream': 'Ceramide cream, easy to find in pharmacies',
  'cerave-pm': 'Night lotion with niacinamide',
  'cerave-foaming': 'Gentle drugstore cleanser',
  'cerave-hydrating-cleanser': 'Non-foaming cleanser for dry skin',
  'lrp-toleriane': 'Lightly scented moisturizer, often in pharmacies',
  'lrp-effaclar-gel': 'Foaming gel often used on oily skin',
  'gag-niacinamide': 'Affordable niacinamide serum',
  'cetaphil-gentle': 'Basic drugstore cleanser',
  'simple-micellar': 'Lightly scented micellar water',
  'neutrogena-hydroboost': 'Drugstore water-gel moisturizer',
  'to-salicylic': 'Budget BHA for a cleaner feel',
  'cosrx-snail': 'Widely sold hydrating essence',
  'hada-labo-gokujyun': 'Pharmacy HA lotion',
  'isntree-ha': 'Light HA essence',
  'purito-centella': 'Lightly scented cica serum',
  'bioderma-sensibio': 'Pharmacy micellar water',
  'avene-tolerance': 'Minimal pharmacy cream for reactive skin',
  'eucerin-urea': 'Pharmacy urea cream for dry skin',
  'boj-relief-sun': 'Widely sold daily sunscreen',
  'loreal-elseve-hyaluron': 'Drugstore hydrating shampoo',
  'ducray-extra-doux': 'Pharmacy gentle shampoo',
  'vichy-dercos-oil-control': 'Pharmacy clarifying shampoo',
};

const es: Record<string, string> = {
  'to-niacinamide-10': 'Sérum de niacinamida de drugstore',
  'to-ha-2': 'Sérum hidratante simple',
  'to-squalane': 'Aceite ligero en lugar de mantecas pesadas',
  'inkey-niacinamide': 'Alternativa drugstore a la niacinamida',
  'inkey-ha': 'Sérum de ácido hialurónico económico',
  'cerave-moisturizing-cream': 'Crema de ceramidas, fácil de encontrar en farmacia',
  'cerave-pm': 'Crema de noche con niacinamida',
  'cerave-foaming': 'Limpiador drugstore suave',
  'cerave-hydrating-cleanser': 'Limpiador sin espuma para piel seca',
  'lrp-toleriane': 'Hidratante poco perfumado, a menudo en farmacia',
  'lrp-effaclar-gel': 'Gel limpiador usado a menudo en piel grasa',
  'gag-niacinamide': 'Sérum de niacinamida asequible',
  'cetaphil-gentle': 'Limpiador drugstore básico',
  'simple-micellar': 'Agua micelar poco perfumada',
  'neutrogena-hydroboost': 'Gel hidratante de drugstore',
  'to-salicylic': 'BHA económico para una piel más limpia',
  'cosrx-snail': 'Esencia hidratante muy extendida',
  'hada-labo-gokujyun': 'Loción HA de farmacia',
  'isntree-ha': 'Esencia HA ligera',
  'purito-centella': 'Sérum cica poco perfumado',
  'bioderma-sensibio': 'Agua micelar de farmacia',
  'avene-tolerance': 'Crema mínima de farmacia para piel reactiva',
  'eucerin-urea': 'Crema de urea de farmacia para piel seca',
  'boj-relief-sun': 'Protector diario muy extendido',
  'loreal-elseve-hyaluron': 'Champú hidratante de supermercado',
  'ducray-extra-doux': 'Champú suave de farmacia',
  'vichy-dercos-oil-control': 'Champú seborregulador de farmacia',
};

const fr: Record<string, string> = {
  'to-niacinamide-10': 'Sérum niacinamide de drugstore',
  'to-ha-2': 'Sérum hydratant simple',
  'to-squalane': 'Huile légère à la place des beurres lourds',
  'inkey-niacinamide': 'Alternative drugstore à la niacinamide',
  'inkey-ha': 'Sérum acide hyaluronique abordable',
  'cerave-moisturizing-cream': 'Crème aux céramides, facile à trouver en pharmacie',
  'cerave-pm': 'Crème de nuit à la niacinamide',
  'cerave-foaming': 'Nettoyant drugstore doux',
  'cerave-hydrating-cleanser': 'Nettoyant non moussant pour peau sèche',
  'lrp-toleriane': 'Hydratant peu parfumé, souvent en pharmacie',
  'lrp-effaclar-gel': 'Gel nettoyant souvent utilisé sur peau grasse',
  'gag-niacinamide': 'Sérum niacinamide accessible',
  'cetaphil-gentle': 'Nettoyant drugstore basique',
  'simple-micellar': 'Eau micellaire peu parfumée',
  'neutrogena-hydroboost': 'Gel hydratant de drugstore',
  'to-salicylic': 'BHA abordable pour une peau plus nette',
  'cosrx-snail': 'Essence hydratante très répandue',
  'hada-labo-gokujyun': 'Lotion HA de pharmacie',
  'isntree-ha': 'Essence HA légère',
  'purito-centella': 'Sérum cica peu parfumé',
  'bioderma-sensibio': 'Eau micellaire de pharmacie',
  'avene-tolerance': 'Crème minimale de pharmacie pour peau réactive',
  'eucerin-urea': 'Crème urée de pharmacie pour peau sèche',
  'boj-relief-sun': 'Solaire quotidien très répandu',
  'loreal-elseve-hyaluron': 'Shampoing hydratant de supermarché',
  'ducray-extra-doux': 'Shampoing doux de pharmacie',
  'vichy-dercos-oil-control': 'Shampoing sébo-régulateur de pharmacie',
};

const de: Record<string, string> = {
  'to-niacinamide-10': 'Niacinamid-Serum aus der Drogerie',
  'to-ha-2': 'Einfaches Feuchtigkeitsserum',
  'to-squalane': 'Leichtes Öl statt schwerer Butter',
  'inkey-niacinamide': 'Günstige Niacinamid-Alternative',
  'inkey-ha': 'Günstiges Hyaluron-Serum',
  'cerave-moisturizing-cream': 'Creme mit Ceramiden, leicht in der Apotheke zu finden',
  'cerave-pm': 'Nachtcreme mit Niacinamid',
  'cerave-foaming': 'Sanfter Drogerie-Reiniger',
  'cerave-hydrating-cleanser': 'Nicht-schäumender Reiniger für trockene Haut',
  'lrp-toleriane': 'Wenig parfümierte Pflege, oft in der Apotheke',
  'lrp-effaclar-gel': 'Reinigungsgel, oft bei fettiger Haut',
  'gag-niacinamide': 'Preiswertes Niacinamid-Serum',
  'cetaphil-gentle': 'Einfacher Drogerie-Reiniger',
  'simple-micellar': 'Wenig parfümiertes Mizellenwasser',
  'neutrogena-hydroboost': 'Feuchtigkeitsgel aus der Drogerie',
  'to-salicylic': 'Günstige BHA für ein reineres Hautgefühl',
  'cosrx-snail': 'Weit verbreitete Feuchtigkeitsessenz',
  'hada-labo-gokujyun': 'HA-Lotion aus der Apotheke',
  'isntree-ha': 'Leichte HA-Essenz',
  'purito-centella': 'Wenig parfümiertes Cica-Serum',
  'bioderma-sensibio': 'Mizellenwasser aus der Apotheke',
  'avene-tolerance': 'Minimale Apotheken-Creme für reaktive Haut',
  'eucerin-urea': 'Harnstoffcreme aus der Apotheke für trockene Haut',
  'boj-relief-sun': 'Weit verbreiteter Alltagssonnenchutz',
  'loreal-elseve-hyaluron': 'Feuchtigkeitsshampoo aus dem Supermarkt',
  'ducray-extra-doux': 'Sanftes Apotheken-Shampoo',
  'vichy-dercos-oil-control': 'Klärendes Apotheken-Shampoo',
};

const tables: Record<AppLocale, Record<string, string>> = { it, en, es, fr, de };

function localeOf(code?: string): AppLocale {
  const value = (code ?? 'it').toLowerCase();
  return value in tables ? (value as AppLocale) : 'it';
}

export function dupeBlurb(locale: string | undefined, id: string, fallback: string) {
  const table = tables[localeOf(locale)];
  return table[id] ?? tables.en[id] ?? fallback;
}

export function dupePrice(raw: string, locale?: string) {
  const n = String(raw).replace(/[^\d]/g, '');
  if (!n) return raw;
  return localeOf(locale) === 'en' ? `~$${n}` : `~${n} €`;
}
