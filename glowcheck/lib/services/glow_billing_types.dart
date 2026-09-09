class BillingPackage {
  const BillingPackage({
    required this.id,
    required this.label,
    required this.priceString,
    required this.bestValue,
    required this.productId,
  });

  final String id;
  final String label;
  final String priceString;
  final bool bestValue;
  final String productId;
}

enum PurchaseOutcome { unlocked, needsStore, nothingToRestore, cancelled }
