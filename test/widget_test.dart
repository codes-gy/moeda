// 대시보드(AssetManagerApp)가 실제 SQLite 없이도 크래시 없이 렌더링되는지 확인하는 스모크 테스트.
// 각 Service를 인메모리 Stub으로 override해 DB 접근 없이 위젯 트리만 검증한다.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moeda/features/asset/controllers/asset_controller.dart';
import 'package:moeda/features/asset/models/asset.dart';
import 'package:moeda/features/asset/services/asset_service.dart';
import 'package:moeda/features/budget/controllers/budget_controller.dart';
import 'package:moeda/features/budget/models/budget.dart';
import 'package:moeda/features/budget/services/budget_service.dart';
import 'package:moeda/features/category/controllers/category_controller.dart';
import 'package:moeda/features/category/models/category.dart';
import 'package:moeda/features/category/services/category_service.dart';
import 'package:moeda/features/goal/controllers/goal_controller.dart';
import 'package:moeda/features/goal/models/goal.dart';
import 'package:moeda/features/goal/services/goal_service.dart';
import 'package:moeda/features/ledger/controllers/ledger_controller.dart';
import 'package:moeda/features/ledger/models/ledger.dart';
import 'package:moeda/features/ledger/services/ledger_service.dart';
import 'package:moeda/main.dart';

class _StubCategoryService extends CategoryService {
  @override
  Future<List<Category>> fetchCategories() async => [];
}

class _StubLedgerService extends LedgerService {
  @override
  Future<List<Ledger>> fetchLedgers() async => [];
}

class _StubBudgetService extends BudgetService {
  @override
  Future<List<Budget>> fetchBudgets() async => [];
}

class _StubGoalService extends GoalService {
  @override
  Future<List<Goal>> fetchGoals() async => [];
}

class _StubAssetService extends AssetService {
  @override
  Future<List<Asset>> fetchAssets() async => [];
}

void main() {
  testWidgets('대시보드가 크래시 없이 렌더링되고 핵심 카드가 노출된다', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          categoryServiceProvider.overrideWithValue(_StubCategoryService()),
          ledgerServiceProvider.overrideWithValue(_StubLedgerService()),
          budgetServiceProvider.overrideWithValue(_StubBudgetService()),
          goalServiceProvider.overrideWithValue(_StubGoalService()),
          assetServiceProvider.overrideWithValue(_StubAssetService()),
        ],
        child: const AssetManagerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('총 순자산 (Net Asset)'), findsOneWidget);
    expect(find.text('목적별 저축 목표'), findsOneWidget);
    expect(find.text('자산 · 부채 현황'), findsOneWidget);
    expect(find.text('이번 달 변동비 예산이 설정되지 않았어요. 탭하여 설정하세요.'), findsOneWidget);
  });
}
