import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../category/controllers/category_controller.dart';
import '../../category/models/category.dart';
import '../controllers/ledger_controller.dart';
import '../models/ledger.dart';

// ✨ [신규 추가] 지출/수입 직접 입력 팝업창
// ✨ [수정] 수입/지출 선택 토글이 포함된 입력 팝업창
void showAddLedgerDialog(BuildContext context, WidgetRef ref) {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  bool isIncome = false; // 기본값: 지출

  final categories = ref.read(categoryProvider);
  List<Category> categoriesFor(bool income) => categories
      .where((c) => c.type == (income ? CategoryType.income : CategoryType.expense))
      .toList();

  int? selectedCategoryId =
      categoriesFor(isIncome).isNotEmpty ? categoriesFor(isIncome).first.id : null;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          final availableCategories = categoriesFor(isIncome);

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('수입/지출 내역 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ✨ 수입 / 지출 구분 토글 버튼
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
                    // 수입이면 양수(+), 지출이면 음수(-) 처리
                    final finalAmount = isIncome ? amountRaw : -amountRaw;

                    final newItem = Ledger(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      amount: finalAmount,
                      date: DateTime.now(),
                      categoryId: selectedCategoryId!,
                    );
                    ref.read(ledgerProvider.notifier).addLedger(newItem);
                    Navigator.pop(dialogContext);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isIncome ? const Color(0xFF2563EB) : const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                ),
                child: const Text('등록'),
              ),
            ],
          );
        },
      );
    },
  );
}
