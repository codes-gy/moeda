import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/dashboard/views/main_dashboard_screen.dart';

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
