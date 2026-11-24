import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/goal_controller.dart';
import '../models/goal.dart';

// ✨ 저축 목표 추가 팝업창
void showAddGoalDialog(BuildContext context, WidgetRef ref) {
  final titleController = TextEditingController();
  final targetController = TextEditingController();

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('저축 목표 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: '목표 이름',
                hintText: '예: 비상금 모으기',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '목표 금액 (원)',
                hintText: '예: 5000000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text.trim()) ?? 0;
              if (title.isNotEmpty && target > 0) {
                ref.read(goalProvider.notifier).addGoal(title, target);
                Navigator.pop(dialogContext);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            child: const Text('추가'),
          ),
        ],
      );
    },
  );
}

// ✨ 저축 목표 수정/삭제 팝업창
void showEditGoalDialog(BuildContext context, WidgetRef ref, Goal goal) {
  final titleController = TextEditingController(text: goal.title);
  final targetController = TextEditingController(text: goal.targetAmount.toInt().toString());
  final currentController = TextEditingController(text: goal.currentAmount.toInt().toString());

  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('저축 목표 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: '목표 이름'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: currentController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '현재까지 모은 금액 (원)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: '목표 금액 (원)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showDialog(
                context: context,
                builder: (confirmContext) => AlertDialog(
                  title: const Text('목표를 삭제할까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(confirmContext),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(goalProvider.notifier).deleteGoal(goal.id);
                        Navigator.pop(confirmContext);
                      },
                      child: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              final target = double.tryParse(targetController.text.trim()) ?? 0;
              final current = double.tryParse(currentController.text.trim()) ?? 0;
              if (title.isNotEmpty && target > 0) {
                ref.read(goalProvider.notifier).updateGoal(
                      goal.copyWith(title: title, targetAmount: target, currentAmount: current),
                    );
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
