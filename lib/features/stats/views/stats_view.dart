import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/stats_provider.dart';

String _formatWon(num amount) {
  final rounded = amount.abs().toInt();
  return rounded.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

const _categoryColors = [
  Color(0xFF2563EB),
  Color(0xFFDC2626),
  Color(0xFFF59E0B),
  Color(0xFF16A34A),
  Color(0xFF9333EA),
  Color(0xFF0891B2),
];

class StatsView extends ConsumerWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedStatsMonthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMonthSelector(ref, selectedMonth),
            const SizedBox(height: 16),
            _buildCategoryBreakdownCard(ref),
            const SizedBox(height: 16),
            _buildMonthlyTrendCard(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector(WidgetRef ref, DateTime month) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(selectedStatsMonthProvider.notifier).state =
                DateTime(month.year, month.month - 1);
          },
        ),
        Text(
          '${month.year}년 ${month.month}월',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref.read(selectedStatsMonthProvider.notifier).state =
                DateTime(month.year, month.month + 1);
          },
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdownCard(WidgetRef ref) {
    final breakdown = ref.watch(categoryExpenseBreakdownProvider);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '카테고리별 지출',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (breakdown.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '이번 달 지출 내역이 없습니다.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              for (int i = 0; i < breakdown.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                _buildCategoryRow(breakdown[i], _categoryColors[i % _categoryColors.length]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(CategoryAmount item, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.category.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              '₩ ${_formatWon(item.amount)} (${(item.ratio * 100).toStringAsFixed(0)}%)',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: item.ratio,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendCard(WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final maxValue = trend.fold<double>(
      0,
      (max, m) => [max, m.income, m.expense].reduce((a, b) => a > b ? a : b),
    );

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '최근 6개월 추이',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                _LegendDot(color: Color(0xFF2563EB), label: '수입'),
                SizedBox(width: 12),
                _LegendDot(color: Color(0xFFDC2626), label: '지출'),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final m in trend)
                    Expanded(child: _buildMonthBar(m, maxValue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthBar(MonthlySummary m, double maxValue) {
    const maxBarHeight = 100.0;
    final incomeHeight = maxValue > 0 ? (m.income / maxValue) * maxBarHeight : 0.0;
    final expenseHeight = maxValue > 0 ? (m.expense / maxValue) * maxBarHeight : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: maxBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 8,
                height: incomeHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFF2563EB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                width: 8,
                height: expenseHeight,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text('${m.month.month}월', style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}
