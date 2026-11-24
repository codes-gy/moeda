import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/controllers/category_controller.dart';
import '../../category/models/category.dart';
import '../controllers/ledger_controller.dart';
import 'ledger_view.dart';

/// 5. 최근 내역 Card
class RecentTransactionsCard extends ConsumerWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgers = ref.watch(ledgerProvider);
    final categories = ref.watch(categoryProvider);
    String categoryName(int categoryId) => categories
        .firstWhere(
          (c) => c.id == categoryId,
          orElse: () => Category(
            id: -1,
            name: '미분류',
            type: CategoryType.expense,
            displayOrder: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .name;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '최근 내역',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LedgerView()),
                    );
                  },
                  child: const Text('전체보기', style: TextStyle(fontSize: 12)),
                )
              ],
            ),
            if (ledgers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    '등록된 내역이 없습니다.\n+ 버튼을 누르면 내역이 추가됩니다.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ),
              )
            else
              ...ledgers.take(3).map((item) {
                // ✨ 금액 양수/음수에 따른 수입/지출 판단
                final isIncome = item.amount > 0;
                final formattedAmount = item.amount.abs().toInt().toString().replaceAllMapped(
                  RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]},',
                );

                return Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text(
                        '${categoryName(item.categoryId)} · ${item.date.year}-${item.date.month.toString().padLeft(2, '0')}-${item.date.day.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      // ✨ 수입은 파란색 (+₩), 지출은 빨간색 (-₩)으로 출력
                      trailing: Text(
                        '${isIncome ? "+₩" : "-₩"} $formattedAmount',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isIncome ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                        ),
                      ),
                    ),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }
}
