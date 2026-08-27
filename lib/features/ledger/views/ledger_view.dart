import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/controllers/category_controller.dart';
import '../../category/models/category.dart';
import '../controllers/ledger_controller.dart';
import '../models/ledger.dart';

class LedgerView extends ConsumerWidget {
  const LedgerView({super.key});

  Category _findCategory(List<Category> categories, int categoryId) {
    return categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: -1,
        name: '미분류',
        type: CategoryType.expense,
        displayOrder: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _showEditLedgerDialog(
    BuildContext context,
    WidgetRef ref,
    Ledger item,
    List<Category> categories,
  ) {
    final titleController = TextEditingController(text: item.title);
    final amountController =
        TextEditingController(text: item.amount.abs().toInt().toString());
    bool isIncome = item.amount > 0;

    List<Category> categoriesFor(bool income) => categories
        .where((c) =>
            c.type == (income ? CategoryType.income : CategoryType.expense))
        .toList();

    int? selectedCategoryId = item.categoryId;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final availableCategories = categoriesFor(isIncome);
            if (!availableCategories.any((c) => c.id == selectedCategoryId)) {
              selectedCategoryId =
                  availableCategories.isNotEmpty ? availableCategories.first.id : null;
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('내역 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: false,
                        label: Text('지출'),
                        icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                      ),
                      ButtonSegment(
                        value: true,
                        label: Text('수입'),
                        icon: Icon(Icons.add_circle_outline, color: Colors.blue),
                      ),
                    ],
                    selected: {isIncome},
                    onSelectionChanged: (newSelection) {
                      setState(() {
                        isIncome = newSelection.first;
                        final next = categoriesFor(isIncome);
                        selectedCategoryId = next.isNotEmpty ? next.first.id : null;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: '카테고리',
                      border: OutlineInputBorder(),
                    ),
                    items: availableCategories
                        .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: '내역명',
                      hintText: '예: 점심식사, 월급',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '금액 (원)',
                      hintText: '예: 10000',
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
                    final amountRaw = double.tryParse(amountController.text.trim()) ?? 0;

                    if (title.isNotEmpty && amountRaw > 0 && selectedCategoryId != null) {
                      final finalAmount = isIncome ? amountRaw : -amountRaw;

                      final updatedItem = item.copyWith(
                        title: title,
                        amount: finalAmount,
                        categoryId: selectedCategoryId,
                      );
                      ref.read(ledgerProvider.notifier).updateLedger(updatedItem);
                      Navigator.pop(dialogContext);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isIncome ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('저장'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgers = ref.watch(ledgerProvider);
    final categories = ref.watch(categoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('장부 내역')),
      body: ListView.builder(
        itemCount: ledgers.length,
        itemBuilder: (context, index) {
          final item = ledgers[index];
          return Dismissible(
            key: ValueKey(item.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              color: const Color(0xFFDC2626),
              child: const Icon(Icons.delete_outline, color: Colors.white),
            ),
            confirmDismiss: (direction) {
              return showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('내역 삭제'),
                  content: Text('"${item.title}" 내역을 삭제할까요?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, false),
                      child: const Text('취소'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext, true),
                      child: const Text('삭제', style: TextStyle(color: Color(0xFFDC2626))),
                    ),
                  ],
                ),
              ).then((confirmed) => confirmed ?? false);
            },
            onDismissed: (direction) {
              ref.read(ledgerProvider.notifier).deleteLedger(item.id);
            },
            child: ListTile(
              title: Text(item.title),
              subtitle: Text(_findCategory(categories, item.categoryId).name),
              trailing: Text('₩${item.amount.toInt()}'),
              onTap: () => _showEditLedgerDialog(context, ref, item, categories),
            ),
          );
        },
      ),
    );
  }
}
