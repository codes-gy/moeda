import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/goal.dart';
import '../services/goal_service.dart';

final goalServiceProvider = Provider((ref) => GoalService());

class GoalController extends StateNotifier<List<Goal>> {
  final GoalService _service;

  GoalController(this._service) : super([]) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    final goals = await _service.fetchGoals();
    state = goals;
  }

  Future<void> addGoal(String title, double targetAmount) async {
    final newGoal = await _service.addGoal(title, targetAmount);
    state = [...state, newGoal];
  }

  Future<void> updateGoal(Goal goal) async {
    final updated = goal.copyWith(updatedAt: DateTime.now());
    await _service.updateGoal(updated);
    state = state.map((item) => item.id == updated.id ? updated : item).toList();
  }

  Future<void> deleteGoal(int id) async {
    await _service.deleteGoal(id);
    state = state.where((item) => item.id != id).toList();
  }
}

final goalProvider = StateNotifierProvider<GoalController, List<Goal>>((ref) {
  final service = ref.watch(goalServiceProvider);
  return GoalController(service);
});
