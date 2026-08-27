import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/controllers/category_controller.dart';
import '../../category/models/category.dart';
import '../../ledger/controllers/ledger_controller.dart';

/// 통계 화면에서 조회 중인 월 (매월 1일 기준으로 정규화)
final selectedStatsMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

bool _isSameMonth(DateTime date, DateTime ref) =>
    date.year == ref.year && date.month == ref.month;

class CategoryAmount {
  final Category category;
  final double amount;
  final double ratio; // 해당 월 총 지출 대비 비율 (0.0 ~ 1.0)

  CategoryAmount({
    required this.category,
    required this.amount,
    required this.ratio,
  });
}

/// 선택된 월의 카테고리별 지출 합계 (내림차순 정렬)
final categoryExpenseBreakdownProvider = Provider<List<CategoryAmount>>((ref) {
  final month = ref.watch(selectedStatsMonthProvider);
  final ledgers = ref.watch(ledgerProvider);
  final categories = ref.watch(categoryProvider);

  final expenses = ledgers.where(
    (l) => l.amount < 0 && _isSameMonth(l.date, month),
  );

  final totalsByCategory = <int, double>{};
  for (final l in expenses) {
    totalsByCategory[l.categoryId] =
        (totalsByCategory[l.categoryId] ?? 0) + l.amount.abs();
  }

  final totalExpense = totalsByCategory.values.fold(0.0, (a, b) => a + b);

  final result = totalsByCategory.entries.map((entry) {
    final category = categories.firstWhere(
      (c) => c.id == entry.key,
      orElse: () => Category(
        id: entry.key,
        name: '미분류',
        type: CategoryType.expense,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    return CategoryAmount(
      category: category,
      amount: entry.value,
      ratio: totalExpense > 0 ? entry.value / totalExpense : 0,
    );
  }).toList();

  result.sort((a, b) => b.amount.compareTo(a.amount));
  return result;
});

class MonthlySummary {
  final DateTime month;
  final double income;
  final double expense;

  MonthlySummary({
    required this.month,
    required this.income,
    required this.expense,
  });
}

/// 선택된 월을 마지막 달로 하는 최근 6개월간 월별 수입/지출 합계 (오래된 달 → 최신 달 순)
final monthlyTrendProvider = Provider<List<MonthlySummary>>((ref) {
  final month = ref.watch(selectedStatsMonthProvider);
  final ledgers = ref.watch(ledgerProvider);

  return List.generate(6, (i) {
    final target = DateTime(month.year, month.month - (5 - i));
    final income = ledgers
        .where((l) => l.amount > 0 && _isSameMonth(l.date, target))
        .fold(0.0, (sum, l) => sum + l.amount);
    final expense = ledgers
        .where((l) => l.amount < 0 && _isSameMonth(l.date, target))
        .fold(0.0, (sum, l) => sum + l.amount.abs());
    return MonthlySummary(month: target, income: income, expense: expense);
  });
});
