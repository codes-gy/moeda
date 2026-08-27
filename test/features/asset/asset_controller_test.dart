import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/asset/controllers/asset_controller.dart';
import 'package:moeda/features/asset/models/asset.dart';
import 'package:moeda/features/asset/services/asset_service.dart';

/// 실제 SQLite 대신 메모리 리스트로 동작하는 Stub.
class _StubAssetService extends AssetService {
  _StubAssetService([List<Asset>? initial]) : store = List.of(initial ?? const []);

  final List<Asset> store;

  @override
  Future<List<Asset>> fetchAssets() async => List.of(store);

  @override
  Future<Asset> addAsset(String name, String type, double amount) async {
    final created = Asset(
      id: store.length + 1,
      name: name,
      type: type,
      amount: amount,
      createdAt: DateTime(2026, 8, 27),
      updatedAt: DateTime(2026, 8, 27),
    );
    store.add(created);
    return created;
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    final index = store.indexWhere((a) => a.id == asset.id);
    if (index != -1) store[index] = asset;
  }

  @override
  Future<void> deleteAsset(int id) async => store.removeWhere((a) => a.id == id);
}

Asset _asset({
  required int id,
  String name = 'asset',
  String type = Asset.typeAsset,
  double amount = 100000,
}) {
  return Asset(
    id: id,
    name: name,
    type: type,
    amount: amount,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );
}

void main() {
  group('AssetController', () {
    test('생성 시 서비스에서 목록을 불러와 state에 반영한다', () async {
      final service = _StubAssetService([_asset(id: 1, name: '입출금 통장')]);
      final controller = AssetController(service);

      await Future<void>.delayed(Duration.zero);

      expect(controller.state.single.name, '입출금 통장');
    });

    test('addAsset은 지정한 type/amount로 새 항목을 추가한다', () async {
      final service = _StubAssetService();
      final controller = AssetController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.addAsset('학자금 대출', Asset.typeLiability, 3000000);

      expect(controller.state.single.name, '학자금 대출');
      expect(controller.state.single.type, Asset.typeLiability);
      expect(controller.state.single.amount, 3000000);
    });

    test('updateAsset은 같은 id 항목만 교체하고 updatedAt을 갱신한다', () async {
      final service = _StubAssetService([_asset(id: 1, amount: 100000)]);
      final controller = AssetController(service);
      await Future<void>.delayed(Duration.zero);

      final target = controller.state.single;
      await controller.updateAsset(target.copyWith(amount: 200000));

      expect(controller.state.single.amount, 200000);
      expect(controller.state.single.updatedAt.isAfter(DateTime(2026, 8, 1)), isTrue);
    });

    test('deleteAsset은 서비스와 state에서 해당 id를 제거한다', () async {
      final service = _StubAssetService([_asset(id: 1), _asset(id: 2)]);
      final controller = AssetController(service);
      await Future<void>.delayed(Duration.zero);

      await controller.deleteAsset(1);

      expect(controller.state.map((a) => a.id), [2]);
      expect(service.store.map((a) => a.id), [2]);
    });
  });

  group('Asset.isAsset / isLiability', () {
    test('type에 따라 올바른 getter를 반환한다', () {
      expect(_asset(id: 1, type: Asset.typeAsset).isAsset, isTrue);
      expect(_asset(id: 1, type: Asset.typeAsset).isLiability, isFalse);
      expect(_asset(id: 1, type: Asset.typeLiability).isLiability, isTrue);
      expect(_asset(id: 1, type: Asset.typeLiability).isAsset, isFalse);
    });
  });
}
