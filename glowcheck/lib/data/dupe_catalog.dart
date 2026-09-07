class DupeProduct {
  const DupeProduct({
    required this.id,
    required this.brand,
    required this.name,
    required this.estimatedPrice,
    required this.blurb,
  });

  final String id;
  final String brand;
  final String name;
  final String estimatedPrice;
  final String blurb;
}

const dupeCatalog = [
  DupeProduct(
    id: 'to-niacinamide-10',
    brand: 'The Ordinary',
    name: 'Niacinamide 10% + Zinc 1%',
    estimatedPrice: '~\$7',
    blurb: 'Widely used drugstore niacinamide serum',
  ),
  DupeProduct(
    id: 'to-ha-2',
    brand: 'The Ordinary',
    name: 'Hyaluronic Acid 2% + B5',
    estimatedPrice: '~\$8',
    blurb: 'Simple hydrating serum',
  ),
  DupeProduct(
    id: 'cerave-moisturizing-cream',
    brand: 'CeraVe',
    name: 'Moisturizing Cream',
    estimatedPrice: '~\$16',
    blurb: 'Ceramide cream widely sold in drugstores',
  ),
  DupeProduct(
    id: 'cerave-foaming',
    brand: 'CeraVe',
    name: 'Foaming Facial Cleanser',
    estimatedPrice: '~\$14',
    blurb: 'Gentle drugstore cleanser',
  ),
  DupeProduct(
    id: 'cerave-pm',
    brand: 'CeraVe',
    name: 'PM Facial Moisturizing Lotion',
    estimatedPrice: '~\$15',
    blurb: 'Night lotion with niacinamide',
  ),
  DupeProduct(
    id: 'inkey-niacinamide',
    brand: 'The Inkey List',
    name: 'Niacinamide Serum',
    estimatedPrice: '~\$8',
    blurb: 'Drugstore niacinamide option',
  ),
  DupeProduct(
    id: 'lrp-toleriane',
    brand: 'La Roche-Posay',
    name: 'Toleriane Sensitive',
    estimatedPrice: '~\$20',
    blurb: 'Fragrance-light moisturizer often chosen for easily reactive skin',
  ),
  DupeProduct(
    id: 'gag-niacinamide',
    brand: 'Geek & Gorgeous',
    name: '10% Niacinamide',
    estimatedPrice: '~\$12',
    blurb: 'Affordable niacinamide serum',
  ),
];

DupeProduct? getDupeById(String? id) {
  if (id == null || id.isEmpty) return null;
  for (final item in dupeCatalog) {
    if (item.id == id) return item;
  }
  return null;
}
