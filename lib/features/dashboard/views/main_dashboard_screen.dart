import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../asset/views/asset_liability_card.dart';
import '../../budget/views/budget_summary_card.dart';
import '../../goal/views/goal_tracking_card.dart';
import '../../ledger/views/add_ledger_dialog.dart';
import '../../ledger/views/recent_transactions_card.dart';
import '../../stats/views/stats_view.dart';
import 'net_worth_card.dart';

/// 메인 대시보드. 각 카드는 해당 feature의 views/ 아래에 분리되어 있다.
class MainDashboardScreen extends ConsumerWidget {
  const MainDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'moeda 가계부',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 실시간 순자산 현황판
            NetWorthCard(),
            SizedBox(height: 16),

            // 예산 잔액 및 일일 권장 지출액 + 지출 속도 경고
            BudgetSummaryCard(),
            SizedBox(height: 16),

            // 목적별 저축 목표 트래킹
            GoalTrackingCard(),
            SizedBox(height: 16),

            // 자산/부채 현황
            AssetLiabilityCard(),
            SizedBox(height: 16),

            RecentTransactionsCard(),
          ],
        ),
      ),

      // FAB 클릭 시 테스트 데이터를 ledgerProvider에 추가하도록 연동
      // 🔄 [코드 수정] FAB 클릭 시 직접 입력 팝업창(Dialog) 띄우기
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAddLedgerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('지출/수입 기록'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

    );
  }
}
