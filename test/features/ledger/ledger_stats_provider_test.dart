import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/ledger/controllers/ledger_controller.dart';
import 'package:moeda/features/ledger/controllers/ledger_stats_provider.dart';
import 'package:moeda/features/ledger/models/ledger.dart';
import 'package:moeda/features/ledger/services/ledger_service.dart';

class _StubLedgerService extends LedgerService {
  _StubLedgerService(this.initial);
  final List<Ledger> initial;

  @override
  Future<List<Ledger>> fetchLedgers() async => initial;
}

Ledger _ledger({
  required String id,
  required double amount,
  required DateTime date,
}) {
  return Ledger(id: id, amount: amount, title: id, date: date, categoryId: 1);
}

void main() {
  final now = DateTime.now();
  final thisMonth = DateTime(now.year, now.month, 10);
  final lastMonth = DateTime(now.year, now.month - 1, 10);
  final twoMonthsAgo = DateTime(now.year, now.month - 2, 10);

  late ProviderContainer container;

  Future<ProviderContainer> buildContainer(List<Ledger> ledgers) async {
    final c = ProviderContainer(
      overrides: [
        ledgerProvider.overrideWith(
          (ref) => LedgerController(_StubLedgerService(ledgers)),
        ),
      ],
    );
    addTearDown(c.dispose);
    // overrideWith는 lazy이므로 먼저 read로 LedgerController를 실제로 생성시킨 뒤,
    // 생성자의 loadLedgers()가 완료되도록 마이크로태스크를 한 번 흘려보낸다.
    c.read(ledgerProvider);
    await Future<void>.delayed(Duration.zero);
    return c;
  }

  group('ledger 파생 Provider', () {
    setUp(() {});

    test('netWorthProvider는 전체 기간 금액의 합이다', () async {
      container = await buildContainer([
        _ledger(id: '1', amount: 10000, date: thisMonth),
        _ledger(id: '2', amount: -3000, date: lastMonth),
        _ledger(id: '3', amount: 2000, date: twoMonthsAgo),
      ]);

      expect(container.read(netWorthProvider), 9000);
    });

    test('monthlyIncome/Expense/Net는 이번 달 데이터만 집계한다', () async {
      container = await buildContainer([
        _ledger(id: '1', amount: 10000, date: thisMonth), // 이번 달 수입
        _ledger(id: '2', amount: -4000, date: thisMonth), // 이번 달 지출
        _ledger(id: '3', amount: 5000, date: lastMonth), // 전월 (제외)
      ]);

      expect(container.read(monthlyIncomeProvider), 10000);
      expect(container.read(monthlyExpenseProvider), 4000);
      expect(container.read(monthlyNetProvider), 6000);
    });

    test('lastMonthNetProvider는 전월 데이터만 집계한다', () async {
      container = await buildContainer([
        _ledger(id: '1', amount: 8000, date: lastMonth),
        _ledger(id: '2', amount: -2000, date: lastMonth),
        _ledger(id: '3', amount: 100000, date: thisMonth), // 이번 달 (제외)
      ]);

      expect(container.read(lastMonthNetProvider), 6000);
    });

    test('데이터가 없으면 모든 파생 값은 0이다', () async {
      container = await buildContainer([]);

      expect(container.read(netWorthProvider), 0);
      expect(container.read(monthlyIncomeProvider), 0);
      expect(container.read(monthlyExpenseProvider), 0);
      expect(container.read(monthlyNetProvider), 0);
      expect(container.read(lastMonthNetProvider), 0);
    });
  });
}
