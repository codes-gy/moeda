import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../services/category_service.dart';

final categoryServiceProvider = Provider((ref) => CategoryService());

class CategoryController extends StateNotifier<List<Category>> {
  final CategoryService _service;

  CategoryController(this._service) : super([]) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    final categories = await _service.fetchCategories();
    state = categories;
  }

  // CategoryType 파라미터 추가
  Future<void> addCategory(String name, CategoryType type) async {
    final newCategory = await _service.addCategory(name, type: type);
    state = [...state, newCategory];
  }

  Future<void> deleteCategory(int id) async {
    await _service.deleteCategory(id);
    state = state.where((item) => item.id != id).toList();
  }
}

final categoryProvider = StateNotifierProvider<CategoryController, List<Category>>((ref) {
  final service = ref.watch(categoryServiceProvider);
  return CategoryController(service);
});