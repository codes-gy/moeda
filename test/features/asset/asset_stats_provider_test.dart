import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moeda/features/asset/controllers/asset_controller.dart';
import 'package:moeda/features/asset/controllers/asset_stats_provider.dart';
import 'package:moeda/features/asset/models/asset.dart';
import 'package:moeda/features/asset/services/asset_service.dart';

class _StubAssetService extends AssetService {
  _StubAssetService(this.initial);
  final List<Asset> initial;

  @override
  Future<List<Asset>> fetchAssets() async => initial;
}

Asset _asset({required String type, required double amount}) {
  return Asset(
    id: '$type-$amount'.hashCode,
    name: type,
    type: type,
    amount: amount,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

ProviderContainer _containerWith(List<Asset> assets) {
  final container = ProviderContainer(
    overrides: [
      assetProvider.overrideWith((ref) => AssetController(_StubAssetService(assets))),
    ],
  );
  container.read(assetProvider);
  return container;
}

void main() {
  group('totalAssetsProvider / totalLiabilitiesProvider / netAssetLiabilityProvider', () {
    test('자산/부채가 없으면 모두 0을 반환한다', () async {
      final container = _containerWith([]);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(totalAssetsProvider), 0);
      expect(container.read(totalLiabilitiesProvider), 0);
      expect(container.read(netAssetLiabilityProvider), 0);
    });

    test('type별로 합산하고 순자산은 자산-부채로 계산한다', () async {
      final container = _containerWith([
        _asset(type: Asset.typeAsset, amount: 3000000),
        _asset(type: Asset.typeAsset, amount: 1000000),
        _asset(type: Asset.typeLiability, amount: 1500000),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(totalAssetsProvider), 4000000);
      expect(container.read(totalLiabilitiesProvider), 1500000);
      expect(container.read(netAssetLiabilityProvider), 2500000);
    });

    test('부채가 자산보다 크면 순자산은 음수가 된다', () async {
      final container = _containerWith([
        _asset(type: Asset.typeAsset, amount: 1000000),
        _asset(type: Asset.typeLiability, amount: 5000000),
      ]);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(netAssetLiabilityProvider), -4000000);
    });
  });
}
