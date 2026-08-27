import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import 'budget_controller.dart';

String currentYearMonth() {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
}

/// 이번 달 예산 (없으면 null → 대시보드에서 "설정하기" 안내 노출)
final currentMonthBudgetProvider = Provider<Budget?>((ref) {
  final budgets = ref.watch(budgetProvider);
  final yearMonth = currentYearMonth();
  for (final b in budgets) {
    if (b.yearMonth == yearMonth) return b;
  }
  return null;
});
