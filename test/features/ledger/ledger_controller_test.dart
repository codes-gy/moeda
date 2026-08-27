import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/ledger/controllers/ledger_controller.dart';
import 'package:moeda/features/ledger/models/ledger.dart';
import 'package:moeda/features/ledger/services/ledger_service.dart';

/// 실제 SQLite 대신 메모리 리스트로 동작하는 Stub. DB 접근 없이 컨트롤러 로직만 검증한다.
class _StubLedgerService extends LedgerService {
  _StubLedgerService([List<Ledger>? initial]) : store = List.of(initial ?? const []);

  final List<Ledger> store;

  @override
  Future<List<Ledger>> fetchLedgers() async => List.of(store);

  @override
  Future<void> addLedger(Ledger item) async => store.add(item);

  @override
  Future<void> updateLedger(Ledger item) async {
    final index = store.indexWhere((e) => e.id == item.id);
    if (index != -1) store[index] = item;
  }

  @override
  Future<void> deleteLedger(String id) async =>
      store.removeWhere((e) => e.id == id);
}

Ledger _ledger({required String id, double amount = 1000, int categoryId = 1}) {
  return Ledger(
    id: id,
    amount: amount,
    title: 'title-$id',
    date: DateTime(2026, 8, 1),
    categoryId: categoryId,
  );
}

void main() {
  group('LedgerController', () {
    test('생성 시 서비스에서 목록을 불러와 state에 반영한다', () async {
      final service = _StubLedgerService([_ledger(id: '1'), _ledger(id: '2')]);
      final controller = LedgerController(service);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.map((e) => e.id), ['1', '2']);
    });

    test('addLedger는 서비스에 저장하고 새 항목을 맨 앞에 추가한다', () async {
      final service = _StubLedgerService([_ledger(id: '1')]);
      final controller = LedgerController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.addLedger(_ledger(id: '2'));

      expect(controller.state.map((e) => e.id), ['2', '1']);
      expect(service.store.map((e) => e.id), ['1', '2']);
    });

    test('updateLedger는 같은 id의 항목만 교체한다', () async {
      final service = _StubLedgerService([_ledger(id: '1', amount: 1000)]);
      final controller = LedgerController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.updateLedger(_ledger(id: '1', amount: 5000));

      expect(controller.state.single.amount, 5000);
      expect(service.store.single.amount, 5000);
    });

    test('deleteLedger는 서비스와 state에서 해당 id를 제거한다', () async {
      final service = _StubLedgerService([_ledger(id: '1'), _ledger(id: '2')]);
      final controller = LedgerController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.deleteLedger('1');

      expect(controller.state.map((e) => e.id), ['2']);
      expect(service.store.map((e) => e.id), ['2']);
    });
  });
}
