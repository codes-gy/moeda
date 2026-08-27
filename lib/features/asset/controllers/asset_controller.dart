import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset.dart';
import '../services/asset_service.dart';

final assetServiceProvider = Provider((ref) => AssetService());

class AssetController extends StateNotifier<List<Asset>> {
  final AssetService _service;

  AssetController(this._service) : super([]) {
    loadAssets();
  }

  Future<void> loadAssets() async {
    final assets = await _service.fetchAssets();
    state = assets;
  }

  Future<void> addAsset(String name, String type, double amount) async {
    final newAsset = await _service.addAsset(name, type, amount);
    state = [...state, newAsset];
  }

  Future<void> updateAsset(Asset asset) async {
    final updated = asset.copyWith(updatedAt: DateTime.now());
    await _service.updateAsset(updated);
    state = state.map((item) => item.id == updated.id ? updated : item).toList();
  }

  Future<void> deleteAsset(int id) async {
    await _service.deleteAsset(id);
    state = state.where((item) => item.id != id).toList();
  }
}

final assetProvider = StateNotifierProvider<AssetController, List<Asset>>((ref) {
  final service = ref.watch(assetServiceProvider);
  return AssetController(service);
});
