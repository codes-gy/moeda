import '../../../core/database/app_database.dart';
import '../models/asset.dart';

class AssetService {
  Asset _fromMap(Map<String, Object?> map) {
    return Asset(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      amount: map['amount'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> _toMap(Asset asset) {
    return {
      'id': asset.id,
      'name': asset.name,
      'type': asset.type,
      'amount': asset.amount,
      'createdAt': asset.createdAt.toIso8601String(),
      'updatedAt': asset.updatedAt.toIso8601String(),
    };
  }

  /// 자산/부채 전체 목록 조회 (AssetController의 loadAssets에서 호출)
  Future<List<Asset>> fetchAssets() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('assets', orderBy: 'createdAt ASC');
    return rows.map(_fromMap).toList();
  }

  /// 자산/부채 항목 추가 (AssetController의 addAsset에서 호출)
  Future<Asset> addAsset(String name, String type, double amount) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final newAsset = Asset(
      id: DateTime.now().millisecondsSinceEpoch,
      name: name,
      type: type,
      amount: amount,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('assets', _toMap(newAsset));
    return newAsset;
  }

  /// 자산/부채 항목 수정 (AssetController의 updateAsset에서 호출)
  Future<void> updateAsset(Asset asset) async {
    final db = await AppDatabase.instance.database;
    await db.update('assets', _toMap(asset), where: 'id = ?', whereArgs: [asset.id]);
  }

  /// 자산/부채 항목 삭제 (AssetController의 deleteAsset에서 호출)
  Future<void> deleteAsset(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('assets', where: 'id = ?', whereArgs: [id]);
  }
}
