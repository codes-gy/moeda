import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/category_controller.dart';
import '../models/category.dart';

/// ConsumerWidget을 상속받아 build 메서드에서 WidgetRef ref 파라미터를 받아옵니다.
class CategoryView extends ConsumerWidget {
  const CategoryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch(categoryProvider): categoryProvider의 상태(List<Category>) 변화를 실시간 감시합니다.
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카테고리 관리'),
        centerTitle: true,
      ),
      body: categories.isEmpty
          ? const Center(
        child: Text(
          '등록된 카테고리가 없습니다.\n+ 버튼을 눌러 추가해보세요!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      )
          : ListView.builder(
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];

          return ListTile(
            title: Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(_getTypeLabel(category.type)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () {
                ref
                    .read(categoryProvider.notifier)
                    .deleteCategory(category.id);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// CategoryType enum 값을 한글 텍스트로 변환해주는 헬퍼 메서드
  static String _getTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.income:
        return '수입';
      case CategoryType.expense:
        return '지출';
      case CategoryType.transfer:
        return '이체';
    }
  }

  /// 카테고리 이름과 유형을 입력받는 다이얼로그 팝업
  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    CategoryType selectedType = CategoryType.expense; // 기본값: 지출

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('카테고리 추가'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(
                      hintText: '카테고리 이름을 입력하세요 (예: 식비)',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<CategoryType>(
                    initialValue: selectedType,
                    decoration: const InputDecoration(
                      labelText: '카테고리 유형',
                      border: OutlineInputBorder(),
                    ),
                    items: CategoryType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(_getTypeLabel(type)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedType = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = textController.text.trim();
                    if (name.isNotEmpty) {
                      // name과 selectedType 2개의 인자를 전달
                      ref
                          .read(categoryProvider.notifier)
                          .addCategory(name, selectedType);
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}