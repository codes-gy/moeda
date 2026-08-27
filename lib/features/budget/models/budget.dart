/// 특정 월의 변동비 예산 목표.
class Budget {
  final int id;

  /// "yyyy-MM" 형식 (예: "2026-08"). 월별로 유일해야 함.
  final String yearMonth;

  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Budget({
    required this.id,
    required this.yearMonth,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget copyWith({
    double? amount,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      yearMonth: yearMonth,
      amount: amount ?? this.amount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
