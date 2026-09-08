import 'glow_l10n.dart';

const _blurbs = <String, Map<String, String>>{
  'it': {
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
  },
  'en': {
    'cerave-moisturizing-cream': 'Ceramide cream, easy to find in pharmacies',
    'to-niacinamide-10': 'Drugstore niacinamide serum',
    'to-ha-2': 'Simple hydrating serum',
    'cerave-foaming': 'Gentle drugstore cleanser',
    'cerave-pm': 'Night lotion with niacinamide',
    'inkey-niacinamide': 'Drugstore niacinamide option',
    'lrp-toleriane': 'Lightly scented moisturizer, often in pharmacies',
    'gag-niacinamide': 'Affordable niacinamide serum',
  },
  'es': {
    'cerave-moisturizing-cream': 'Crema de ceramidas, fácil de encontrar en farmacia',
    'to-niacinamide-10': 'Sérum de niacinamida de drugstore',
    'to-ha-2': 'Sérum hidratante simple',
    'cerave-foaming': 'Limpiador drugstore suave',
    'cerave-pm': 'Crema de noche con niacinamida',
    'inkey-niacinamide': 'Alternativa drugstore a la niacinamida',
    'lrp-toleriane': 'Hidratante poco perfumado, a menudo en farmacia',
    'gag-niacinamide': 'Sérum de niacinamida asequible',
  },
  'fr': {
    'cerave-moisturizing-cream': 'Crème aux céramides, facile à trouver en pharmacie',
    'to-niacinamide-10': 'Sérum niacinamide de drugstore',
    'to-ha-2': 'Sérum hydratant simple',
    'cerave-foaming': 'Nettoyant drugstore doux',
    'cerave-pm': 'Crème de nuit à la niacinamide',
    'inkey-niacinamide': 'Alternative drugstore à la niacinamide',
    'lrp-toleriane': 'Hydratant peu parfumé, souvent en pharmacie',
    'gag-niacinamide': 'Sérum niacinamide accessible',
  },
  'de': {
    'cerave-moisturizing-cream': 'Creme mit Ceramiden, leicht in der Apotheke zu finden',
    'to-niacinamide-10': 'Niacinamid-Serum aus der Drogerie',
    'to-ha-2': 'Einfaches Feuchtigkeitsserum',
    'cerave-foaming': 'Sanfter Drogerie-Reiniger',
    'cerave-pm': 'Nachtcreme mit Niacinamid',
    'inkey-niacinamide': 'Günstige Niacinamid-Alternative',
    'lrp-toleriane': 'Wenig parfümierte Pflege, oft in der Apotheke',
    'gag-niacinamide': 'Preiswertes Niacinamid-Serum',
  },
};

String localizedDupeBlurb(String? id, String fallback) {
  final locale = GlowL10n.normalize(GlowL10n.currentCode);
  if (id != null && id.isNotEmpty) {
    final text = _blurbs[locale]?[id] ?? _blurbs['it']?[id];
    if (text != null) return text;
  }
  return fallback;
}

String localizedDupePrice(String raw) {
  final n = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (n.isEmpty) return raw;
  if (GlowL10n.normalize(GlowL10n.currentCode) == 'en') return '~\$$n';
  return '~$n €';
}
