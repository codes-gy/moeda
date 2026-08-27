import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ledger.dart';
import 'ledger_controller.dart';

double _sum(Iterable<Ledger> items) =>
    items.fold(0.0, (sum, item) => sum + item.amount);

bool _isSameMonth(DateTime date, DateTime ref) =>
    date.year == ref.year && date.month == ref.month;

/// 전체 기간 누적 순자산 (모든 Ledger 금액의 합, 수입 +/지출 -)
final netWorthProvider = Provider<double>((ref) {
  final ledgers = ref.watch(ledgerProvider);
  return _sum(ledgers);
});

/// 이번 달 수입 합계
final monthlyIncomeProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final ledgers = ref.watch(ledgerProvider);
  return _sum(
    ledgers.where((l) => l.amount > 0 && _isSameMonth(l.date, now)),
  );
});

/// 이번 달 지출 합계 (양수로 반환)
final monthlyExpenseProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final ledgers = ref.watch(ledgerProvider);
  return _sum(
    ledgers.where((l) => l.amount < 0 && _isSameMonth(l.date, now)),
  ).abs();
});

/// 이번 달 순증감 (수입 - 지출)
final monthlyNetProvider = Provider<double>((ref) {
  return ref.watch(monthlyIncomeProvider) - ref.watch(monthlyExpenseProvider);
});

/// 전월 순증감 (전월 대비 계산용)
final lastMonthNetProvider = Provider<double>((ref) {
  final now = DateTime.now();
  final lastMonth = DateTime(now.year, now.month - 1);
  final ledgers = ref.watch(ledgerProvider);
  final income = _sum(
    ledgers.where((l) => l.amount > 0 && _isSameMonth(l.date, lastMonth)),
  );
  final expense = _sum(
    ledgers.where((l) => l.amount < 0 && _isSameMonth(l.date, lastMonth)),
  ).abs();
  return income - expense;
});
