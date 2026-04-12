import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
      theme: ThemeData(primarySwatch: Colors.green),
      home: const TaskListScreen(),
    );
  }
}