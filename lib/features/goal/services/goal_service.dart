import '../../../core/database/app_database.dart';
import '../models/goal.dart';

class GoalService {
  Goal _fromMap(Map<String, Object?> map) {
    return Goal(
      id: map['id'] as int,
      title: map['title'] as String,
      targetAmount: map['targetAmount'] as double,
      currentAmount: map['currentAmount'] as double,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Map<String, Object?> _toMap(Goal goal) {
    return {
      'id': goal.id,
      'title': goal.title,
      'targetAmount': goal.targetAmount,
      'currentAmount': goal.currentAmount,
      'createdAt': goal.createdAt.toIso8601String(),
      'updatedAt': goal.updatedAt.toIso8601String(),
    };
  }

  /// 목표 전체 목록 조회 (GoalController의 loadGoals에서 호출)
  Future<List<Goal>> fetchGoals() async {
    final db = await AppDatabase.instance.database;
    final rows = await db.query('goals', orderBy: 'createdAt ASC');
    return rows.map(_fromMap).toList();
  }

  /// 목표 추가 (GoalController의 addGoal에서 호출)
  Future<Goal> addGoal(String title, double targetAmount) async {
    final db = await AppDatabase.instance.database;
    final now = DateTime.now();

    final newGoal = Goal(
      id: DateTime.now().millisecondsSinceEpoch,
      title: title,
      targetAmount: targetAmount,
      currentAmount: 0,
      createdAt: now,
      updatedAt: now,
    );

    await db.insert('goals', _toMap(newGoal));
    return newGoal;
  }

  /// 목표 수정 (GoalController의 updateGoal에서 호출)
  Future<void> updateGoal(Goal goal) async {
    final db = await AppDatabase.instance.database;
    await db.update('goals', _toMap(goal), where: 'id = ?', whereArgs: [goal.id]);
  }

  /// 목표 삭제 (GoalController의 deleteGoal에서 호출)
  Future<void> deleteGoal(int id) async {
    final db = await AppDatabase.instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }
}
