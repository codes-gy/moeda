class Ledger {
  final String id;
  final double amount;
  final String title;
  final DateTime date;
  final int categoryId;

  Ledger({
    required this.id,
    required this.amount,
    required this.title,
    required this.date,
    required this.categoryId,
  });

  Ledger copyWith({
    String? id,
    double? amount,
    String? title,
    DateTime? date,
    int? categoryId,
  }) {
    return Ledger(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
    );
  }
}