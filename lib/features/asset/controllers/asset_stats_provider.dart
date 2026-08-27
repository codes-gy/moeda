import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/asset.dart';
import 'asset_controller.dart';

double _sum(Iterable<Asset> items) =>
    items.fold(0.0, (sum, item) => sum + item.amount);

/// 총자산 (type == asset 인 항목의 amount 합)
final totalAssetsProvider = Provider<double>((ref) {
  final assets = ref.watch(assetProvider);
  return _sum(assets.where((a) => a.isAsset));
});

/// 총부채 (type == liability 인 항목의 amount 합)
final totalLiabilitiesProvider = Provider<double>((ref) {
  final assets = ref.watch(assetProvider);
  return _sum(assets.where((a) => a.isLiability));
});

/// 순자산 (총자산 - 총부채)
final netAssetLiabilityProvider = Provider<double>((ref) {
  return ref.watch(totalAssetsProvider) - ref.watch(totalLiabilitiesProvider);
});
