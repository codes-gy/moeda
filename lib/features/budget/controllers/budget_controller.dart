import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../services/budget_service.dart';

final budgetServiceProvider = Provider((ref) => BudgetService());

class BudgetController extends StateNotifier<List<Budget>> {
  final BudgetService _service;

  BudgetController(this._service) : super([]) {
    loadBudgets();
  }

  Future<void> loadBudgets() async {
    final budgets = await _service.fetchBudgets();
    state = budgets;
  }

  /// 특정 월(yearMonth)의 예산 금액을 설정 (없으면 생성, 있으면 갱신)
  Future<void> setBudget(String yearMonth, double amount) async {
    Budget? existing;
    for (final b in state) {
      if (b.yearMonth == yearMonth) {
        existing = b;
        break;
      }
    }

    final saved = await _service.setBudget(yearMonth, amount, existing: existing);
    if (existing != null) {
      state = state.map((b) => b.id == saved.id ? saved : b).toList();
    } else {
      state = [...state, saved];
    }
  }
}

final budgetProvider = StateNotifierProvider<BudgetController, List<Budget>>((ref) {
  final service = ref.watch(budgetServiceProvider);
  return BudgetController(service);
});
