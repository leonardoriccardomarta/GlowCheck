class IngredientLine {
  const IngredientLine({
    required this.name,
    required this.tag,
    this.note,
  });

  final String name;
  final String tag;
  final String? note;

  Map<String, dynamic> toJson() => {
        'name': name,
        'tag': tag,
        'note': note,
      };

  factory IngredientLine.fromJson(Map<String, dynamic> json) {
    return IngredientLine(
      name: json['name'] as String? ?? '',
      tag: json['tag'] as String? ?? 'listed',
      note: json['note'] as String?,
    );
  }
}

class FlaggedIngredient {
  const FlaggedIngredient({
    required this.name,
    required this.kind,
    required this.note,
  });

  final String name;
  final String kind;
  final String note;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind,
        'note': note,
      };

  factory FlaggedIngredient.fromJson(Map<String, dynamic> json) {
    return FlaggedIngredient(
      name: json['name'] as String? ?? '',
      kind: json['kind'] as String? ?? 'warning',
      note: json['note'] as String? ?? '',
    );
  }
}

class DupeSuggestion {
  const DupeSuggestion({
    required this.brand,
    required this.name,
    required this.estimatedPrice,
    required this.blurb,
    this.whyThis = '',
    this.id,
  });

  final String brand;
  final String name;
  final String estimatedPrice;
  final String blurb;
  final String whyThis;
  final String? id;

  Map<String, dynamic> toJson() => {
        'brand': brand,
        'name': name,
        'estimatedPrice': estimatedPrice,
        'blurb': blurb,
        'whyThis': whyThis,
        'id': id,
      };

  factory DupeSuggestion.fromJson(Map<String, dynamic> json) {
    return DupeSuggestion(
      brand: json['brand'] as String? ?? '',
      name: json['name'] as String? ?? '',
      estimatedPrice: json['estimatedPrice'] as String? ?? '',
      blurb: json['blurb'] as String? ?? '',
      whyThis: json['whyThis'] as String? ?? '',
      id: json['id'] as String?,
    );
  }
}

class ScanResult {
  const ScanResult({
    required this.productName,
    required this.score,
    required this.badge,
    required this.headline,
    required this.why,
    required this.at,
    this.occlusionAlert = 'low',
    this.dupeId,
    this.dupe,
    this.ingredients = const [],
    this.flagged = const [],
  });

  final String productName;
  final int score;
  final String badge;
  final String headline;
  final String why;
  final int at;
  final String occlusionAlert;
  final String? dupeId;
  final DupeSuggestion? dupe;
  final List<IngredientLine> ingredients;
  final List<FlaggedIngredient> flagged;

  List<IngredientLine> get lines {
    if (ingredients.isNotEmpty) return ingredients;
    return [
      for (final item in flagged)
        IngredientLine(
          name: item.name,
          tag: item.kind == 'warning' ? 'watch' : 'fit',
          note: item.note,
        ),
    ];
  }

  int get watchCount => lines.where((item) => item.tag == 'watch').length;
  int get fitCount => lines.where((item) => item.tag == 'fit').length;
  int get listedCount => lines.where((item) => item.tag == 'listed').length;

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'score': score,
        'badge': badge,
        'headline': headline,
        'why': why,
        'at': at,
        'occlusionAlert': occlusionAlert,
        'dupeId': dupeId,
        'dupe': dupe?.toJson(),
        'ingredients': ingredients.map((item) => item.toJson()).toList(),
        'flagged': flagged.map((item) => item.toJson()).toList(),
      };

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      productName: json['productName'] as String? ?? 'INCI scan',
      score: (json['score'] as num?)?.toInt() ?? 0,
      badge: json['badge'] as String? ?? 'CAUTION',
      headline: json['headline'] as String? ?? '',
      why: json['why'] as String? ?? '',
      at: (json['at'] as num?)?.toInt() ?? 0,
      occlusionAlert: json['occlusionAlert'] as String? ?? 'low',
      dupeId: json['dupeId'] as String?,
      dupe: json['dupe'] is Map
          ? DupeSuggestion.fromJson(Map<String, dynamic>.from(json['dupe'] as Map))
          : null,
      ingredients: ((json['ingredients'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => IngredientLine.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      flagged: ((json['flagged'] as List?) ?? [])
          .whereType<Map>()
          .map((item) => FlaggedIngredient.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
