import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/asset_controller.dart';
import '../models/asset.dart';

// ✨ 자산/부채 항목 추가 팝업창
void showAddAssetDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  final amountController = TextEditingController();
  String selectedType = Asset.typeAsset;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('자산/부채 추가', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: Asset.typeAsset, label: Text('자산')),
                    ButtonSegment(value: Asset.typeLiability, label: Text('부채')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) {
                    setState(() => selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '항목 이름',
                    hintText: '예: 입출금 통장, 학자금 대출',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '금액 (원)',
                    hintText: '예: 3000000',
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
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (name.isNotEmpty && amount > 0) {
                    ref.read(assetProvider.notifier).addAsset(name, selectedType, amount);
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
    },
  );
}

// ✨ 자산/부채 항목 수정/삭제 팝업창
void showEditAssetDialog(BuildContext context, WidgetRef ref, Asset asset) {
  final nameController = TextEditingController(text: asset.name);
  final amountController = TextEditingController(text: asset.amount.toInt().toString());
  String selectedType = asset.type;

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('자산/부채 수정', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: Asset.typeAsset, label: Text('자산')),
                    ButtonSegment(value: Asset.typeLiability, label: Text('부채')),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (selection) {
                    setState(() => selectedType = selection.first);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: '항목 이름'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '금액 (원)'),
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
                      title: const Text('항목을 삭제할까요?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(confirmContext),
                          child: const Text('취소'),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(assetProvider.notifier).deleteAsset(asset.id);
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
                  final name = nameController.text.trim();
                  final amount = double.tryParse(amountController.text.trim()) ?? 0;
                  if (name.isNotEmpty && amount > 0) {
                    ref.read(assetProvider.notifier).updateAsset(
                          asset.copyWith(name: name, type: selectedType, amount: amount),
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
    },
  );
}
