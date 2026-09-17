export type FarmIdea = {
  id: string;
  query: string;
  label: string;
  angle: string;
};

export const FARM_IDEAS: FarmIdea[] = [
  { id: 'to-nia', query: 'The Ordinary Niacinamide 10 Zinc', label: 'The Ordinary Niacinamide 10% + Zinc', angle: 'oil-control serum everyone duplicates' },
  { id: 'to-aha', query: 'The Ordinary AHA 30 BHA 2', label: 'The Ordinary AHA 30% + BHA 2%', angle: 'peeling solution drama' },
  { id: 'to-squalane', query: 'The Ordinary Squalane Cleanser', label: 'The Ordinary Squalane Cleanser', angle: 'balm cleanser vs oily' },
  { id: 'lrp-cica', query: 'La Roche Posay Cicaplast Baume B5', label: 'LRP Cicaplast Baume B5', angle: 'repair balm on oily T-zone' },
  { id: 'lrp-duo', query: 'La Roche Posay Effaclar Duo', label: 'LRP Effaclar Duo+', angle: 'acne cream vs dry skin' },
  { id: 'lrp-anthelios', query: 'La Roche Posay Anthelios', label: 'LRP Anthelios SPF', angle: 'pharmacy SPF everyone wears' },
  { id: 'cosrx-snail', query: 'COSRX Advanced Snail 96 Mucin', label: 'COSRX Snail 96 Mucin', angle: 'snail essence Skintok staple' },
  { id: 'boj-sun', query: 'Beauty of Joseon Relief Sun', label: 'Beauty of Joseon Relief Sun', angle: 'glass-skin sunscreen' },
  { id: 'boj-dynasty', query: 'Beauty of Joseon Dynasty Cream', label: 'BOJ Dynasty Cream', angle: 'rice cream vs pores' },
  { id: 'anua-heartleaf', query: 'Anua Heartleaf 77 Toner', label: 'Anua Heartleaf 77%', angle: '77 toner viral bottle' },
  { id: 'medicube-pads', query: 'Medicube Zero Pore Pad', label: 'Medicube Zero Pore Pads', angle: 'pore pad hype' },
  { id: 'roundlab-dokdo', query: 'Round Lab Dokdo Toner', label: 'Round Lab Dokdo Toner', angle: 'dokdo toner vs dry' },
  { id: 'skin1004', query: 'Skin1004 Madagascar Centella', label: 'Skin1004 Centella', angle: 'centella ampoule' },
  { id: 'hada-labo', query: 'Hada Labo Gokujyun', label: 'Hada Labo Gokujyun', angle: 'HA lotion cheap hero' },
  { id: 'paula-bha', query: 'Paula\'s Choice 2% BHA', label: "Paula's Choice 2% BHA", angle: 'the liquid exfoliant' },
  { id: 'hydroboost', query: 'Neutrogena Hydro Boost Water Gel', label: 'Neutrogena Hydro Boost', angle: 'water gel vs dry' },
  { id: 'cetaphil', query: 'Cetaphil Gentle Skin Cleanser', label: 'Cetaphil Gentle Cleanser', angle: 'derm-recommended basic' },
  { id: 'bioderma', query: 'Bioderma Sensibio H2O', label: 'Bioderma Sensibio H2O', angle: 'micellar water queen' },
  { id: 'vanicream', query: 'Vanicream Moisturizing Cream', label: 'Vanicream Cream', angle: 'sensitive holy grail' },
  { id: 'nivea-tin', query: 'Nivea Creme', label: 'Nivea Creme tin', angle: 'blue tin slugging' },
  { id: 'vaseline', query: 'Vaseline Original Petroleum Jelly', label: 'Vaseline', angle: 'slugging debate' },
  { id: 'aquaphor', query: 'Aquaphor Healing Ointment', label: 'Aquaphor', angle: 'ointment vs pores' },
  { id: 'laneige-lip', query: 'Laneige Lip Sleeping Mask', label: 'Laneige Lip Sleeping Mask', angle: 'lip mask every GRWM' },
  { id: 'solde-janeiro', query: 'Sol de Janeiro Bum Bum Cream', label: 'Bum Bum Cream', angle: 'body cream smell vs skin' },
  { id: 'rhode-glaze', query: 'Rhode Peptide Glazing Fluid', label: 'Rhode Peptide Glazing Fluid', angle: 'Hailey Bieber glaze' },
  { id: 'bubble-slam', query: 'Bubble Slam Dunk', label: 'Bubble Slam Dunk', angle: 'TikTok teen moisturizer' },
  { id: 'byoma-serum', query: 'Byoma Hydrating Serum', label: 'Byoma Hydrating Serum', angle: 'barrier serum hype' },
  { id: 'good-mol-nia', query: 'Good Molecules Niacinamide', label: 'Good Molecules Niacinamide', angle: 'budget nia' },
  { id: 'inkey-nia', query: 'The Inkey List Niacinamide', label: 'Inkey List Niacinamide', angle: 'drugstore nia' },
  { id: 'glow-recipe', query: 'Glow Recipe Watermelon Pink Juice', label: 'Glow Recipe Watermelon', angle: 'pink juice toner' },
  { id: 'tatcha-dewy', query: 'Tatcha The Dewy Skin Cream', label: 'Tatcha Dewy Skin Cream', angle: 'expensive dewy cream' },
  { id: 'eucerin-urea', query: 'Eucerin UreaRepair 5', label: 'Eucerin UreaRepair 5%', angle: 'pharmacy urea' },
  { id: 'avene-cicalfate', query: 'Avene Cicalfate', label: 'Avène Cicalfate', angle: 'repair cream vs oily' },
  { id: 'cerave-pm', query: 'CeraVe PM Facial Moisturizing Lotion', label: 'CeraVe PM Lotion', angle: 'the lighter CeraVe' },
  { id: 'cerave-foam', query: 'CeraVe Foaming Facial Cleanser', label: 'CeraVe Foaming Cleanser', angle: 'foaming cleanser on dry' },
  { id: 'simple-micellar', query: 'Simple Kind to Skin Micellar', label: 'Simple Micellar', angle: '£3 micellar' },
  { id: 'garnier-micellar', query: 'Garnier Micellar Water', label: 'Garnier Micellar', angle: 'pink cap vs skin' },
  { id: 'axisy-spot', query: 'Axis-Y Dark Spot Correcting Glow', label: 'Axis-Y Dark Spot Serum', angle: 'K-beauty glow serum' },
  { id: 'purito-centella', query: 'Purito Centella Unscented Serum', label: 'Purito Centella Unscented', angle: 'fragrance-free cica' },
  { id: 'mixsoon-bean', query: 'Mixsoon Bean Essence', label: 'Mixsoon Bean Essence', angle: 'bean essence trend' },
  { id: 'to-ha', query: 'The Ordinary Hyaluronic Acid 2 B5', label: 'The Ordinary HA 2% + B5', angle: 'HA serum everyone owns' },
  { id: 'cerave-sa', query: 'CeraVe SA Smoothing Cream', label: 'CeraVe SA Cream', angle: 'SA cream vs dry barrier' },
  { id: 'lrp-toleriane', query: 'La Roche Posay Toleriane Sensitive', label: 'LRP Toleriane Sensitive', angle: 'pharmacy sensitive cream' },
  { id: 'isntree-ha', query: 'Isntree Hyaluronic Acid Toner', label: 'Isntree HA Toner', angle: 'HA toner vs oily' },
  { id: 'tirtir-mask', query: 'TIRTIR Red Cushion', label: 'TIRTIR Red Cushion', angle: 'viral cushion INCI' },
  { id: 'summer-fridays', query: 'Summer Fridays Lip Butter Balm', label: 'Summer Fridays Lip Butter', angle: 'lip balm every GRWM' },
  { id: 'fenty-oil', query: 'Fenty Skin Fat Water', label: 'Fenty Fat Water', angle: 'celeb toner' },
  { id: 'rhode-barrier', query: 'Rhode Barrier Restore Cream', label: 'Rhode Barrier Cream', angle: 'Hailey barrier cream' },
];

export const DEFAULT_USED_IDEAS = ['cerave-cream', 'cerave-moisturizing'];

export function ideaKey(query: string) {
  return query.trim().toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
}
