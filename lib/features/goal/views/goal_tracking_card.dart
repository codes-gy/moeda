import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/currency_format.dart';
import '../controllers/goal_controller.dart';
import '../models/goal.dart';
import 'goal_dialogs.dart';

/// 3. 저축 목표 트래킹 Card (F4.2)
class GoalTrackingCard extends ConsumerWidget {
  const GoalTrackingCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalProvider);
    const goalColors = [Colors.blue, Colors.green, Colors.orange, Colors.purple];

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
                  '목적별 저축 목표',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF2563EB)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => showAddGoalDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (goals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '등록된 저축 목표가 없습니다.\n+ 버튼을 눌러 목표를 추가해보세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else
              for (int i = 0; i < goals.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildGoalItem(context, ref, goals[i], goalColors[i % goalColors.length]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(BuildContext context, WidgetRef ref, Goal goal, Color color) {
    return InkWell(
      onTap: () => showEditGoalDialog(context, ref, goal),
      borderRadius: BorderRadius.circular(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(goal.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text('${(goal.progress * 100).toInt()}% 달성',
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: goal.progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₩ ${formatWon(goal.currentAmount)} / ${formatWon(goal.targetAmount)}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
