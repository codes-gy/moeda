import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/budget/controllers/budget_controller.dart';
import 'package:moeda/features/budget/models/budget.dart';
import 'package:moeda/features/budget/services/budget_service.dart';

/// 실제 SQLite 대신 메모리 리스트로 동작하는 Stub.
class _StubBudgetService extends BudgetService {
  _StubBudgetService([List<Budget>? initial]) : store = List.of(initial ?? const []);

  final List<Budget> store;

  @override
  Future<List<Budget>> fetchBudgets() async => List.of(store);

  @override
  Future<Budget> setBudget(String yearMonth, double amount, {Budget? existing}) async {
    if (existing != null) {
      final updated = existing.copyWith(amount: amount, updatedAt: DateTime(2026, 8, 27));
      final index = store.indexWhere((b) => b.id == existing.id);
      store[index] = updated;
      return updated;
    }
    final created = Budget(
      id: 999,
      yearMonth: yearMonth,
      amount: amount,
      createdAt: DateTime(2026, 8, 27),
      updatedAt: DateTime(2026, 8, 27),
    );
    store.add(created);
    return created;
  }
}

Budget _budget({required int id, required String yearMonth, required double amount}) {
  return Budget(
    id: id,
    yearMonth: yearMonth,
    amount: amount,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('BudgetController', () {
    test('생성 시 서비스에서 목록을 불러와 state에 반영한다', () async {
      final service = _StubBudgetService([_budget(id: 1, yearMonth: '2026-08', amount: 500000)]);
      final controller = BudgetController(service);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.single.yearMonth, '2026-08');
    });

    test('setBudget: 해당 월 예산이 없으면 새로 추가한다', () async {
      final service = _StubBudgetService();
      final controller = BudgetController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.setBudget('2026-08', 700000);

      expect(controller.state.single.yearMonth, '2026-08');
      expect(controller.state.single.amount, 700000);
    });

    test('setBudget: 해당 월 예산이 있으면 금액만 갱신하고 중복 추가하지 않는다', () async {
      final service = _StubBudgetService([_budget(id: 1, yearMonth: '2026-08', amount: 500000)]);
      final controller = BudgetController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.setBudget('2026-08', 900000);

      expect(controller.state.length, 1);
      expect(controller.state.single.amount, 900000);
    });

    test('setBudget: 다른 월 예산은 서로 영향을 주지 않는다', () async {
      final service = _StubBudgetService([_budget(id: 1, yearMonth: '2026-07', amount: 300000)]);
      final controller = BudgetController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.setBudget('2026-08', 400000);

      expect(controller.state.length, 2);
      final july = controller.state.firstWhere((b) => b.yearMonth == '2026-07');
      final august = controller.state.firstWhere((b) => b.yearMonth == '2026-08');
      expect(july.amount, 300000);
      expect(august.amount, 400000);
    });
  });
}
