class GlowInci {
  GlowInci._();

  static const names = {
    'parfum',
    'fragrance',
    'aroma',
    'limonene',
    'linalool',
    'citronellol',
    'geraniol',
    'citral',
    'eugenol',
    'isoeugenol',
    'coumarin',
    'farnesol',
    'cinnamal',
    'cinnamyl alcohol',
    'benzyl alcohol',
    'benzyl benzoate',
    'benzyl salicylate',
    'benzyl cinnamate',
    'hexyl cinnamal',
    'hydroxycitronellal',
    'butylphenyl methylpropional',
    'alpha-isomethyl ionone',
    'amyl cinnamal',
    'anise alcohol',
    'methyl 2-octynoate',
    'evernia prunastri',
    'evernia furfuracea',
    'oakmoss',
  };

  static String _key(String name) =>
      name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9+]+'), ' ').trim();

  static bool isFragrance(String name, [String? note]) {
    final key = _key(name);
    if (key == 'parfum' || key == 'fragrance' || key == 'aroma') return true;
    if (names.any((item) => key == item || key.startsWith('$item ') || key.endsWith(' $item'))) {
      return true;
    }
    final text = (note ?? '').toLowerCase();
    return text.contains('profum') ||
        text.contains('fragrance') ||
        text.contains('parfum') ||
        text.contains('perfum') ||
        text.contains('scented');
  }
}
