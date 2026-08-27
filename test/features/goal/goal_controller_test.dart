import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/goal/controllers/goal_controller.dart';
import 'package:moeda/features/goal/models/goal.dart';
import 'package:moeda/features/goal/services/goal_service.dart';

/// 실제 SQLite 대신 메모리 리스트로 동작하는 Stub.
class _StubGoalService extends GoalService {
  _StubGoalService([List<Goal>? initial]) : store = List.of(initial ?? const []);

  final List<Goal> store;

  @override
  Future<List<Goal>> fetchGoals() async => List.of(store);

  @override
  Future<Goal> addGoal(String title, double targetAmount) async {
    final created = Goal(
      id: store.length + 1,
      title: title,
      targetAmount: targetAmount,
      currentAmount: 0,
      createdAt: DateTime(2026, 8, 27),
      updatedAt: DateTime(2026, 8, 27),
    );
    store.add(created);
    return created;
  }

  @override
  Future<void> updateGoal(Goal goal) async {
    final index = store.indexWhere((g) => g.id == goal.id);
    if (index != -1) store[index] = goal;
  }

  @override
  Future<void> deleteGoal(int id) async => store.removeWhere((g) => g.id == id);
}

Goal _goal({required int id, String title = 'goal', double target = 100000, double current = 0}) {
  return Goal(
    id: id,
    title: title,
    targetAmount: target,
    currentAmount: current,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('GoalController', () {
    test('생성 시 서비스에서 목록을 불러와 state에 반영한다', () async {
      final service = _StubGoalService([_goal(id: 1, title: '비상금')]);
      final controller = GoalController(service);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.single.title, '비상금');
    });

    test('addGoal은 currentAmount 0으로 새 목표를 추가한다', () async {
      final service = _StubGoalService();
      final controller = GoalController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.addGoal('여름 휴가', 500000);

      expect(controller.state.single.title, '여름 휴가');
      expect(controller.state.single.currentAmount, 0);
      expect(controller.state.single.targetAmount, 500000);
    });

    test('updateGoal은 같은 id 항목만 교체하고 updatedAt을 갱신한다', () async {
      final service = _StubGoalService([_goal(id: 1, current: 0)]);
      final controller = GoalController(service);
      await Future<void>.delayed(Duration.zero);

      final target = controller.state.single;
      await controller.updateGoal(target.copyWith(currentAmount: 30000));

      expect(controller.state.single.currentAmount, 30000);
      expect(controller.state.single.updatedAt.isAfter(DateTime(2026, 8, 1)), isTrue);
    });

    test('deleteGoal은 서비스와 state에서 해당 id를 제거한다', () async {
      final service = _StubGoalService([_goal(id: 1), _goal(id: 2)]);
      final controller = GoalController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.deleteGoal(1);

      expect(controller.state.map((g) => g.id), [2]);
      expect(service.store.map((g) => g.id), [2]);
    });
  });

  group('Goal.progress', () {
    test('targetAmount가 0 이하이면 0을 반환한다', () {
      expect(_goal(id: 1, target: 0, current: 100).progress, 0);
    });

    test('0.0 ~ 1.0 범위로 clamp된다', () {
      expect(_goal(id: 1, target: 1000, current: 2000).progress, 1.0);
      expect(_goal(id: 1, target: 1000, current: 500).progress, 0.5);
    });
  });
}
