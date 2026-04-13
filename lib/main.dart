import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:green_app/core/theme/app_theme.dart';

import 'features/tasks/views/task_list_screen.dart';
void main() {
  runApp(
    // Dùng Riverpod
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Greenstep',
      theme: AppTheme.lightTheme,
      home: const TaskListScreen(),
    );
  }
}