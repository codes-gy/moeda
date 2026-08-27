import '../../../core/database/app_database.dart';
import '../models/ledger.dart';

class LedgerService {
  Ledger _fromMap(Map<String, Object?> map) {
    return Ledger(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      categoryId: map['categoryId'] as int,
    );
  }

  Map<String, Object?> _toMap(Ledger ledger) {
    return {
      'id': ledger.id,
      'amount': ledger.amount,
      'title': ledger.title,
      'date': ledger.date.toIso8601String(),
      'categoryId': ledger.categoryId,
    };
  }

  /// 내역 전체 목록 조회 (LedgerController의 loadLedgers에서 호출)
  Future<List<Ledger>> fetchLedgers() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('ledgers', orderBy: 'date DESC');
    return rows.map(_fromMap).toList();
  }

  /// 내역 추가 (LedgerController의 addLedger에서 호출)
  Future<void> addLedger(Ledger item) async {
    final db = await AppDatabase.instance.database;
    await db.insert('ledgers', _toMap(item));
  }

  /// 내역 수정 (LedgerController의 updateLedger에서 호출)
  Future<void> updateLedger(Ledger item) async {
    final db = await AppDatabase.instance.database;
    await db.update(
      'ledgers',
      _toMap(item),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  /// 내역 삭제 (LedgerController의 deleteLedger에서 호출)
  Future<void> deleteLedger(String id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('ledgers', where: 'id = ?', whereArgs: [id]);
  }
}
