import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/budget_controller.dart';
import '../controllers/budget_stats_provider.dart';
import '../models/budget.dart';

// ✨ 이번 달 예산 목표 설정/수정 팝업창
void showSetBudgetDialog(BuildContext context, WidgetRef ref, {Budget? existing}) {
  final amountController = TextEditingController(
    text: existing != null ? existing.amount.toInt().toString() : '',
  );

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('이번 달 예산 설정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: '변동비 예산 (원)',
            hintText: '예: 1000000',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (amount > 0) {
                ref.read(budgetProvider.notifier).setBudget(currentYearMonth(), amount);
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
}
