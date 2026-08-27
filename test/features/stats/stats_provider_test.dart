import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/category/controllers/category_controller.dart';
import 'package:moeda/features/category/models/category.dart';
import 'package:moeda/features/category/services/category_service.dart';
import 'package:moeda/features/ledger/controllers/ledger_controller.dart';
import 'package:moeda/features/ledger/models/ledger.dart';
import 'package:moeda/features/ledger/services/ledger_service.dart';
import 'package:moeda/features/stats/controllers/stats_provider.dart';

class _StubLedgerService extends LedgerService {
  _StubLedgerService(this.initial);
  final List<Ledger> initial;

  @override
  Future<List<Ledger>> fetchLedgers() async => initial;
}

class _StubCategoryService extends CategoryService {
  _StubCategoryService(this.initial);
  final List<Category> initial;

  @override
  Future<List<Category>> fetchCategories() async => initial;
}

Ledger _ledger({
  required String id,
  required double amount,
  required DateTime date,
  required int categoryId,
}) {
  return Ledger(id: id, amount: amount, title: id, date: date, categoryId: categoryId);
}

Category _category({required int id, required String name, CategoryType type = CategoryType.expense}) {
  return Category(
    id: id,
    name: name,
    type: type,
    displayOrder: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  final month = DateTime(2026, 8);

  Future<ProviderContainer> buildContainer({
    required List<Ledger> ledgers,
    List<Category> categories = const [],
  }) async {
    final c = ProviderContainer(
      overrides: [
        ledgerProvider.overrideWith((ref) => LedgerController(_StubLedgerService(ledgers))),
        categoryProvider.overrideWith((ref) => CategoryController(_StubCategoryService(categories))),
        selectedStatsMonthProvider.overrideWith((ref) => month),
      ],
    );
    addTearDown(c.dispose);
    // overrideWith는 lazy이므로 먼저 read로 컨트롤러들을 실제로 생성시킨 뒤,
    // 생성자의 load*()가 완료되도록 마이크로태스크를 한 번 흘려보낸다.
    c.read(ledgerProvider);
    c.read(categoryProvider);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  group('categoryExpenseBreakdownProvider', () {
    test('선택 월의 지출만 카테고리별로 합산하고 금액 내림차순으로 정렬한다', () async {
      final container = await buildContainer(
        ledgers: [
          _ledger(id: '1', amount: -3000, date: month, categoryId: 1), // 식비
          _ledger(id: '2', amount: -1000, date: month, categoryId: 1), // 식비
          _ledger(id: '3', amount: -6000, date: month, categoryId: 2), // 교통비
          _ledger(id: '4', amount: 50000, date: month, categoryId: 1), // 수입 (제외)
          _ledger(id: '5', amount: -9999, date: DateTime(2026, 7), categoryId: 2), // 다른 달 (제외)
        ],
        categories: [
          _category(id: 1, name: '식비'),
          _category(id: 2, name: '교통비'),
        ],
      );

      final result = container.read(categoryExpenseBreakdownProvider);

      expect(result.map((e) => e.category.name), ['교통비', '식비']);
      expect(result[0].amount, 6000);
      expect(result[1].amount, 4000);
      expect(result[0].ratio + result[1].ratio, closeTo(1.0, 0.0001));
    });

    test('알 수 없는 카테고리는 "미분류"로 표시된다', () async {
      final container = await buildContainer(
        ledgers: [_ledger(id: '1', amount: -1000, date: month, categoryId: 999)],
        categories: const [],
      );

      final result = container.read(categoryExpenseBreakdownProvider);

      expect(result.single.category.name, '미분류');
    });

    test('지출이 없으면 빈 목록을 반환한다', () async {
      final container = await buildContainer(ledgers: []);

      expect(container.read(categoryExpenseBreakdownProvider), isEmpty);
    });
  });

  group('monthlyTrendProvider', () {
    test('선택 월을 마지막으로 최근 6개월치를 오래된 순으로 반환한다', () async {
      final container = await buildContainer(
        ledgers: [
          _ledger(id: '1', amount: 10000, date: month, categoryId: 1), // 8월(마지막 달)
          _ledger(id: '2', amount: -4000, date: month, categoryId: 1), // 8월(마지막 달)
          _ledger(id: '3', amount: 7000, date: DateTime(2026, 3), categoryId: 1), // 3월 = 범위 시작(월-5), 포함
          _ledger(id: '4', amount: 9999, date: DateTime(2026, 2), categoryId: 1), // 2월 = 범위 밖(월-6), 제외
        ],
      );

      final trend = container.read(monthlyTrendProvider);

      expect(trend.length, 6);
      expect(trend.first.month, DateTime(2026, 3)); // month - 5
      expect(trend.last.month, DateTime(2026, 8)); // 선택 월 자신
      expect(trend.last.income, 10000);
      expect(trend.last.expense, 4000);
      expect(trend.first.income, 7000); // 범위 시작 달도 포함됨을 확인
      expect(trend.first.expense, 0);
      // 범위 밖(2월) 데이터가 어느 달에도 합산되지 않았는지 전체 합으로 확인
      final totalIncome = trend.fold(0.0, (sum, m) => sum + m.income);
      expect(totalIncome, 17000); // 10000 + 7000, 9999는 제외
    });
  });
}
