import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/asset/controllers/asset_controller.dart';
import 'features/asset/controllers/asset_stats_provider.dart';
import 'features/asset/models/asset.dart';
import 'features/budget/controllers/budget_controller.dart';
import 'features/budget/controllers/budget_stats_provider.dart';
import 'features/budget/models/budget.dart';
import 'features/category/controllers/category_controller.dart';
import 'features/category/models/category.dart';
import 'features/goal/controllers/goal_controller.dart';
import 'features/goal/models/goal.dart';
import 'features/ledger/controllers/ledger_controller.dart';
import 'features/ledger/controllers/ledger_stats_provider.dart';
import 'features/ledger/models/ledger.dart';
import 'features/ledger/views/ledger_view.dart';
import 'features/stats/views/stats_view.dart';

String _formatWon(num amount) {
  final rounded = amount.abs().toInt();
  return rounded.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
}

void main() {
  // 전역 상태 관리를 가능하게 하기 위해 ProviderScope 적용
  runApp(
    const ProviderScope(
      child: AssetManagerApp(),
    ),
  );
}

class AssetManagerApp extends StatelessWidget {
  const AssetManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI 자산관리 비서',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          surface: const Color(0xFFF8FAFC),
        ),
        fontFamily: 'Pretendard',
      ),
      home: const MainDashboardScreen(),
    );
  }
}

class MainDashboardScreen extends ConsumerWidget {
  const MainDashboardScreen({super.key});


  // ✨ [신규 추가] 지출/수입 직접 입력 팝업창
  // ✨ [수정] 수입/지출 선택 토글이 포함된 입력 팝업창
  void _showAddLedgerDialog(BuildContext context, WidgetRef ref) {
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

  // ✨ 이번 달 예산 목표 설정/수정 팝업창
  void _showSetBudgetDialog(BuildContext context, WidgetRef ref, {Budget? existing}) {
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

  // ✨ 저축 목표 추가 팝업창
  void _showAddGoalDialog(BuildContext context, WidgetRef ref) {
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
  void _showEditGoalDialog(BuildContext context, WidgetRef ref, Goal goal) {
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

  // ✨ 자산/부채 항목 추가 팝업창
  void _showAddAssetDialog(BuildContext context, WidgetRef ref) {
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
  void _showEditAssetDialog(BuildContext context, WidgetRef ref, Asset asset) {
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '자산관리 AI 비서',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StatsView()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 실시간 순자산 현황판
            _buildNetWorthCard(ref),
            const SizedBox(height: 16),

            // 예산 잔액 및 일일 권장 지출액 + 지출 속도 경고
            _buildBudgetAndSpeedCard(context, ref),
            const SizedBox(height: 16),

            // 목적별 저축 목표 트래킹
            _buildGoalTrackingCard(context, ref),
            const SizedBox(height: 16),

            // 자산/부채 현황
            _buildAssetLiabilityCard(context, ref),
            const SizedBox(height: 16),

            _buildRecentTransactionsCard(context, ref),
          ],
        ),
      ),

      // FAB 클릭 시 테스트 데이터를 ledgerProvider에 추가하도록 연동
      // 🔄 [코드 수정] FAB 클릭 시 직접 입력 팝업창(Dialog) 띄우기
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLedgerDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('지출/수입 기록'),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
      ),

    );
  }

  // 1. 실시간 순자산 Card (F4.1)
  Widget _buildNetWorthCard(WidgetRef ref) {
    final netWorth = ref.watch(netWorthProvider);
    final monthlyIncome = ref.watch(monthlyIncomeProvider);
    final monthlyExpense = ref.watch(monthlyExpenseProvider);
    final monthlyNet = ref.watch(monthlyNetProvider);
    final lastMonthNet = ref.watch(lastMonthNetProvider);

    final double? changePercent =
        lastMonthNet != 0 ? (monthlyNet - lastMonthNet) / lastMonthNet.abs() * 100 : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '총 순자산 (Net Asset)',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              if (changePercent != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '전월 대비 ${changePercent >= 0 ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${netWorth >= 0 ? '₩' : '-₩'} ${_formatWon(netWorth)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이번 달 수입', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('₩ ${_formatWon(monthlyIncome)}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('이번 달 지출', style: TextStyle(color: Colors.white60, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('₩ ${_formatWon(monthlyExpense)}',
                      style: const TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. 예산 잔액 및 일일 권장 지출액 (F2.1, F2.3)
  Widget _buildBudgetAndSpeedCard(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(currentMonthBudgetProvider);
    final spent = ref.watch(monthlyExpenseProvider);

    if (budget == null) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSetBudgetDialog(context, ref),
          child: const Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '이번 달 변동비 예산이 설정되지 않았어요. 탭하여 설정하세요.',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final budgetGoal = budget.amount;
    final remaining = budgetGoal - spent;
    final progress = (spent / budgetGoal).clamp(0.0, 1.0);

    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysRemaining = daysInMonth - now.day + 1;
    final dailyRecommended = remaining > 0 ? remaining / daysRemaining : 0;

    // 경과일 대비 예산 소진 속도가 빠른지 판단
    final dayFraction = now.day / daysInMonth;
    final isSpendingFast = progress > dayFraction + 0.1;

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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '이번 달 변동비 예산',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showSetBudgetDialog(context, ref, existing: budget),
                    ),
                  ],
                ),
                if (isSpendingFast)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          '지출 속도 빨라요',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₩ ${_formatWon(remaining)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  ' / ${_formatWon(budgetGoal)}원 남음',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(
                  isSpendingFast ? Colors.orangeAccent : const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('오늘의 권장 지출액', style: TextStyle(color: Colors.black87, fontSize: 13)),
                  Text(
                    '₩ ${_formatWon(dailyRecommended)} / 일',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. 저축 목표 트래킹 Card (F4.2)
  Widget _buildGoalTrackingCard(BuildContext context, WidgetRef ref) {
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
                  onPressed: () => _showAddGoalDialog(context, ref),
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
      onTap: () => _showEditGoalDialog(context, ref, goal),
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
            '₩ ${_formatWon(goal.currentAmount)} / ${_formatWon(goal.targetAmount)}',
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // 4. 자산/부채 현황 Card
  Widget _buildAssetLiabilityCard(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(assetProvider);
    final totalAssets = ref.watch(totalAssetsProvider);
    final totalLiabilities = ref.watch(totalLiabilitiesProvider);
    final net = ref.watch(netAssetLiabilityProvider);

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
                  '자산 · 부채 현황',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, size: 20, color: Color(0xFF2563EB)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _showAddAssetDialog(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('총자산', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('₩ ${_formatWon(totalAssets)}',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('총부채', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('₩ ${_formatWon(totalLiabilities)}',
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('순자산', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text('${net >= 0 ? '₩' : '-₩'} ${_formatWon(net)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (assets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '등록된 자산/부채 항목이 없습니다.\n+ 버튼을 눌러 항목을 추가해보세요.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
            else ...[
              const Divider(height: 24),
              for (int i = 0; i < assets.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                _buildAssetItem(context, ref, assets[i]),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAssetItem(BuildContext context, WidgetRef ref, Asset asset) {
    final color = asset.isAsset ? Colors.blue : Colors.redAccent;
    return InkWell(
      onTap: () => _showEditAssetDialog(context, ref, asset),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  asset.isAsset ? '자산' : '부채',
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              Text(asset.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            ],
          ),
          Text(
            '${asset.isAsset ? '' : '-'}₩ ${_formatWon(asset.amount)}',
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsCard(BuildContext context, WidgetRef ref) {
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
                      MaterialPageRoute(builder: (context) => LedgerView()),
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

class AppColors {
  static const redBackground = Color(0xFFFEE2E2);
  static const redText = Color(0xFFDC2626);
  static const blueBackground = Color(0xFFDBEAFE);
  static const blueText = Color(0xFF2563EB);
}