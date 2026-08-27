import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ledger.dart';
import '../services/ledger_service.dart';

final ledgerServiceProvider = Provider((ref) => LedgerService());

class LedgerController extends StateNotifier<List<Ledger>> {
  final LedgerService _service;

  LedgerController(this._service) : super([]) {
    loadLedgers();
  }

  Future<void> loadLedgers() async {
    final ledgers = await _service.fetchLedgers();
    state = ledgers;
  }

  Future<void> addLedger(Ledger item) async {
    await _service.addLedger(item);
    state = [item, ...state];
  }

  Future<void> updateLedger(Ledger item) async {
    await _service.updateLedger(item);
    state = state.map((e) => e.id == item.id ? item : e).toList();
  }

  Future<void> deleteLedger(String id) async {
    await _service.deleteLedger(id);
    state = state.where((item) => item.id != id).toList();
  }
}

final ledgerProvider =
StateNotifierProvider<LedgerController, List<Ledger>>((ref) {
  final service = ref.watch(ledgerServiceProvider);
  return LedgerController(service);
});