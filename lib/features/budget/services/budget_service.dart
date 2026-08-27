import '../../../core/database/app_database.dart';
import '../models/budget.dart';

class BudgetService {
  Budget _fromMap(Map<String, Object?> map) {
    return Budget(
      id: map['id'] as int,
      yearMonth: map['yearMonth'] as String,
      amount: map['amount'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> _toMap(Budget budget) {
    return {
      'id': budget.id,
      'yearMonth': budget.yearMonth,
      'amount': budget.amount,
      'createdAt': budget.createdAt.toIso8601String(),
      'updatedAt': budget.updatedAt.toIso8601String(),
    };
  }

  /// 예산 전체 목록 조회 (BudgetController의 loadBudgets에서 호출)
  Future<List<Budget>> fetchBudgets() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('budgets', orderBy: 'yearMonth DESC');
    return rows.map(_fromMap).toList();
  }

  /// 특정 월의 예산을 설정. 이미 있으면 금액만 갱신, 없으면 새로 생성.
  Future<Budget> setBudget(String yearMonth, double amount, {Budget? existing}) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    if (existing != null) {
      final updated = existing.copyWith(amount: amount, updatedAt: now);
      await db.update('budgets', _toMap(updated), where: 'id = ?', whereArgs: [updated.id]);
      return updated;
    }

    final newBudget = Budget(
      id: DateTime.now().millisecondsSinceEpoch,
      yearMonth: yearMonth,
      amount: amount,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('budgets', _toMap(newBudget));
    return newBudget;
  }
}
