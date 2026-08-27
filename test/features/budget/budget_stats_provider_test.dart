import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/budget/controllers/budget_controller.dart';
import 'package:moeda/features/budget/controllers/budget_stats_provider.dart';
import 'package:moeda/features/budget/models/budget.dart';
import 'package:moeda/features/budget/services/budget_service.dart';

class _StubBudgetService extends BudgetService {
  _StubBudgetService(this.initial);
  final List<Budget> initial;

  @override
  Future<List<Budget>> fetchBudgets() async => initial;
}

Budget _budget({required String yearMonth, required double amount}) {
  return Budget(
    id: yearMonth.hashCode,
    yearMonth: yearMonth,
    amount: amount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('currentYearMonth', () {
    test('yyyy-MM 형식(월 두 자리)으로 반환한다', () {
      final result = currentYearMonth();
      expect(RegExp(r'^\d{4}-\d{2}$').hasMatch(result), isTrue);
    });
  });

  group('currentMonthBudgetProvider', () {
    test('이번 달 예산이 없으면 null을 반환한다', () async {
      final container = ProviderContainer(
        overrides: [
          budgetProvider.overrideWith(
            (ref) => BudgetController(_StubBudgetService([_budget(yearMonth: '2000-01', amount: 100)])),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(budgetProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentMonthBudgetProvider), isNull);
    });

    test('이번 달 예산이 있으면 해당 예산을 반환한다', () async {
      final thisMonth = currentYearMonth();
      final container = ProviderContainer(
        overrides: [
          budgetProvider.overrideWith(
            (ref) => BudgetController(_StubBudgetService([_budget(yearMonth: thisMonth, amount: 555000)])),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(budgetProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(currentMonthBudgetProvider)?.amount, 555000);
    });
  });
}
