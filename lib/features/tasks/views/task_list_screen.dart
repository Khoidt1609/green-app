import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = <Map<String, dynamic>>[
      {'title': 'Mang bình nước cá nhân', 'points': 10, 'done': true},
      {'title': 'Đi xe đạp hoặc đi bộ', 'points': 20, 'done': false},
      {'title': 'Phân loại rác đúng cách', 'points': 15, 'done': false},
      {'title': 'Tắt thiết bị khi không dùng', 'points': 8, 'done': true},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách nhiệm vụ')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final task = tasks[index];
          final done = task['done'] as bool;

          return Card(
            child: ListTile(
              leading: Icon(
                done ? Icons.check_circle : Icons.radio_button_unchecked,
                color: done ? Colors.green : Colors.grey,
              ),
              title: Text(task['title'] as String),
              subtitle: Text('+${task['points']} điểm'),
              trailing: done
                  ? const Chip(label: Text('Hoàn thành'))
                  : const Chip(label: Text('Đang chờ')),
            ),
          );
        },
      ),
    );
  }
}
