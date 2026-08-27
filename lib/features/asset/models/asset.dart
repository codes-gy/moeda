/// 자산(예: 예금, 부동산) 또는 부채(예: 대출, 카드값) 항목.
/// [amount]는 항상 0 이상이며, [type]으로 자산/부채를 구분한다.
class Asset {
  static const typeAsset = 'asset';
  static const typeLiability = 'liability';

  final int id;
  final String name;
  final String type; // Asset.typeAsset | Asset.typeLiability
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAsset => type == typeAsset;
  bool get isLiability => type == typeLiability;

  Asset copyWith({
    String? name,
    String? type,
    double? amount,
    DateTime? updatedAt,
  }) {
    return Asset(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
